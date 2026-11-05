-- ScanTreeSolver.lua
-- Guides the player through a scan clue with the clue's scan tree. The player walks, scans and digs; the solver shows
-- the route to the next scan spot and moves on through the tree from what the scan panel shows, or from Shift+1/2.
-- Every pulse also rules out spots on its own, from the panel and the player's tile; once the spots left all lie under
-- one child, the tree moves on to it.
local coordinate_adaptor = require "cluetrainer/model/shared/coordinate_adaptor"
local TileArea           = require "cluetrainer/model/shared/TileArea"
local Path               = require "cluetrainer/model/shared/path"
local Navigator          = require "cluetrainer/solving/common/navigator"
local ActiveClueSolver   = require "cluetrainer/solving/common/ActiveClueSolver"
local ClueStateAction    = require "cluetrainer/interfaces/cluestate/ClueStateAction"
local MethodAction       = require "cluetrainer/solving/common/MethodAction"
local scan_panel         = require "cluetrainer/solving/scan/scan_panel"
local scan_tree          = require "cluetrainer/solving/scan/scan_tree"
local scan_display       = require "cluetrainer/solving/scan/scan_display"
local ScanMap            = require "cluetrainer/solving/scan/ScanMap"
local ScanGround         = require "cluetrainer/solving/scan/ScanGround"
local LiveNarrowing      = require "cluetrainer/solving/scan/LiveNarrowing"
local tiles              = require "cluetrainer/model/shared/tiles"
local array              = require "zyklib/array"
local zyklib             = require "zyklib"

-- Read the panel 10 times per second (logic ticks run at 50 per second), enough for a text that changes once per pulse.
local POLL_EVERY_TICKS   = 5
-- Use a reading at the scan spot once the player stood there for a whole pulse or the panel changed meanwhile, so the
-- pulse was taken there.
local ARRIVAL_WAIT_TICKS = scan_panel.PULSE_TICKS + POLL_EVERY_TICKS
-- End the clue one poll after the panel closed, to skip a one-tick gap.
local PANEL_CLOSED_TIMEOUT_TICKS = POLL_EVERY_TICKS
-- End the clue once "Scanning..." shows without the area this long: destroyed. After "Start scanning" again the area
-- shows within a pulse, so the clue keeps going.
local DESTROYED_TIMEOUT_TICKS = 2 * scan_panel.PULSE_TICKS

---@alias ct.ScanStatus
---| "travel" # On the way to the scan spot
---| "wait" # At the scan spot, waiting for a pulse taken there
---| "choose" # The panel can't tell the pulses apart (single or double, or a different level), the player presses a key
---| "manual" # The player went back, the panel is ignored until they press a key
---| "triple" # Triple with several spots left
---| "off_route" # A triple's paces point to spots the route doesn't lead to, e.g. after a wrong Shift+1/2
---| "mismatch" # The panel shows a pulse the tree doesn't have here
---| "dig" # One spot left, follow the route and dig
---| "dig_here" # The panel says the player stands on the dig spot

--- One scan clue in progress.
---@class ct.ActiveScanClue : ct.ActiveClueSolver
---@field clue Scan
---@field method_action ct.solving.MethodAction
---@field tree ScanTree.ScanTree? Nil while there is no scan tree method
---@field node ScanTree.ScanTreeNode
---@field area TileArea? Where the player scans for the current node
---@field history {node: ScanTree.ScanTreeNode, area: TileArea?, press: integer?, press_only: boolean?}[] For Shift+0
---@field private tick integer The current logic tick
---@field private candidates table<ScanTree.ScanTreeNode, TileCoordinates[]> The dig spots still possible per node
---@field private live ct.LiveNarrowing
---@field private remaining TileCoordinates[] The node's spots that fit every pulse so far
---@field private clue_state ct.ClueStateInterface
---@field private navigator Navigator
---@field private map ct.ScanMap
---@field private ground ct.ScanGround
---@field private preview_signature string?
---@field private gone_since integer? Logic tick since when the panel shows the clue is gone
---@field private panel_seen boolean
---@field private area_seen boolean
---@field private arrived_at integer?
---@field private text_at_arrival string?
---@field private different_level boolean Whether the last reading was "different level", for Shift+1/2
---@field private status ct.ScanStatus
---@field private status_children ScanTree.Child[]
---@field private notice string?
---@field private rendered_signature string?
local ScanClueSolver = setmetatable({}, { __index = ActiveClueSolver })
ScanClueSolver.__index = ScanClueSolver

---@param clue Scan
---@param clue_state ct.ClueStateInterface
---@return ct.ActiveScanClue
function ScanClueSolver.new(clue, clue_state)
  local self = setmetatable(ActiveClueSolver.new(clue), ScanClueSolver)
  ---@cast self ct.ActiveScanClue

  self.tick = 0
  self.clue_state = clue_state
  self.panel_seen = false
  self.area_seen = false

  self.method_action = MethodAction.new({ clue = clue.id }, {
    onMethodSelected = function(selected)
      self:setMethod(selected and selected.method --[[@as Method.GenericPath?]])
    end,
  })

  self.disposable_group:add({ dispose = function() self:disposeTree() end })

  self.disposable_group:add(zyklib.game_events.native.Logic:subscribe(function(payload)
    if self.tree == nil then return end

    local tick, tile = payload.logicTick, coordinate_adaptor.playerTile()
    local capture, reading = self:ownPanel()
    self.tick = tick
    -- Every tick, so the tile is the one of the pulse.
    if self.live:sample(tick, tile, capture) then self:refresh() end
    if tick % POLL_EVERY_TICKS == 0 then self:poll(tick, capture, reading, tile) end
  end))

  -- On key down, to read Shift while it is still held.
  self.disposable_group:add(zyklib.game_events.native.KeyDown:subscribe(function(event)
    if self.tree == nil then return end
    if event.isRepeat or event.modifiers & ModifierKey.SHIFT == 0 then return end

    if event.gameKey == GameKey._1 then
      self:press(1)
    elseif event.gameKey == GameKey._2 then
      self:press(2)
    elseif event.gameKey == GameKey._3 then
      self:press(3)
    elseif event.gameKey == GameKey._0 then
      self:back()
    end
  end))

  local preferred = self.method_action.method
  self:setMethod(preferred and preferred.method --[[@as Method.GenericPath?]])

  return self
end

---Releases everything that belongs to the current scan tree.
---@private
function ScanClueSolver:disposeTree()
  for _, resource in ipairs({ self.navigator, self.map, self.ground }) do
    if resource ~= nil then resource:dispose() end
  end

  self.navigator, self.map, self.ground, self.live = nil, nil, nil, nil
  self.tree, self.node, self.area = nil, nil, nil
end

---Switches to the scan tree of the method, restarting the clue from its root. Without a scan tree method, there is
---nothing to follow.
---@param method Method.GenericPath?
function ScanClueSolver:setMethod(method)
  self:disposeTree()

  self.history = {}
  self.remaining = {}
  self.notice = nil
  self.preview_signature = nil
  self.rendered_signature = nil
  self.arrived_at = nil
  self.different_level = false
  self.status = "travel"
  self.status_children = {}

  if method == nil or method.type ~= "scantree" then return self:render() end

  ---@cast method Method.ScanTree
  self.tree = method.tree
  self.candidates = scan_tree.candidates(method.tree)
  self.navigator = Navigator.new()
  self.map = ScanMap.new(method.tree)
  self.ground = ScanGround.new()
  self.live = LiveNarrowing.new(method.tree.ordered_spots, self.clue.range)

  self:enter(self.tree.root, scan_tree.scanArea(self.tree.root, nil))
end

---@private
---@param node ScanTree.ScanTreeNode
---@param area TileArea?
---@param manual boolean? The player went back to this node and picks its pulse by hand
function ScanClueSolver:enter(node, area, manual)
  self.node = node
  self.area = area
  self.arrived_at = nil

  self.navigator:set(node.path)

  -- A leaf's route ends at the dig spot; highlight that instead of where the parent scanned.
  local leaf = #node.children == 0
  local target = area
  if leaf then target = Path.endsUpArea(node.path) end
  self.ground:setScanArea(target)
  self.map:setStep(node.path, target, not leaf and self:range() or nil, leaf and self.candidates[node] or nil)

  if leaf then
    self:setStatus("dig")
  elseif manual then
    self:setStatus("manual", node.children)
  else
    self:setStatus("travel")
  end
  -- Last, as it may move on to a child.
  self:refresh()
end

--- The scan range as the panel showed it, until then the one the tree was made for.
---@private
---@return integer
function ScanClueSolver:range()
  return self.live:range() or self.tree.assumed_range
end

--- The node's spots that fit every pulse so far; with several triples only theirs. Should no spot fit, the pulses
--- disagree with the tree (other range, other route) and the tree's spots stay; after a triple's paces, the clue's
--- spots that fit them, as those tell the dig spot wherever the route went.
---@private
---@return TileCoordinates[]
---@return boolean off_route Whether the spots lie off the route
function ScanClueSolver:remainingSpots()
  local spots = self.candidates[self.node]
  if self.status == "triple" then
    spots = array.map(self.status_children, function(child) return child.key.spot end)
  end

  local narrowed = self.live:filter(spots)
  if #narrowed > 0 then return narrowed, false end

  if self.live:hasPaces() then
    local anywhere = self.live:filter(self.tree.ordered_spots)
    if #anywhere > 0 then return anywhere, true end
  end
  return spots, false
end

--- Shows the remaining spots on the map and the ground. Once they all lie under one child, the scan here can only
--- pick that child, so its route follows; not after going back, as the player picks then.
---@private
function ScanClueSolver:refresh()
  local off_route
  self.remaining, off_route = self:remainingSpots()
  self.map:setRemaining(self.remaining)
  self.ground:setSpots(self.remaining)

  if off_route then return self:leaveRoute() end
  -- Back on the route, e.g. Shift+0 to before the wrong key press.
  if self.status == "off_route" then return self:enter(self.node, self.area) end

  if self.status ~= "manual" then
    local children = self.status == "triple" and self.status_children or self.node.children
    local child = scan_tree.onlyChildWith(children, self.remaining, self.candidates)
    if child then return self:step(child, "spots left") end
  end

  self:updatePreview()
  self:render()
end

--- Drops the route, which leads elsewhere, and shows just the spots the triple points to: the player stands within
--- range of them.
---@private
function ScanClueSolver:leaveRoute()
  if self.status ~= "off_route" then
    self.navigator:clear()
    self.ground:setScanArea(nil)
  end
  self.map:setStep({}, nil, nil, self.remaining)
  self:setStatus("off_route")
end

--- The routes the player chooses between with Shift, faded on the ground and the map. Not while waiting for the
--- pulse: that decides within a second, and the routes would only flash up.
---@private
function ScanClueSolver:updatePreview()
  local status, children = self.status, {}
  if status == "mismatch" then
    -- The panel doesn't pick a child, so the player may pick any.
    children = self.node.children
  elseif status == "choose" or status == "manual" then
    children = self.status_children
  elseif status == "triple" then
    -- Only the triples the paces leave, so no route leads to a spot they ruled out.
    children = array.filter(self.status_children, function(child)
      return array.exists(self.remaining, function(spot) return tiles.same(spot, child.key.spot) end)
    end)
  end

  local previews = {}
  for _, child in ipairs(children) do
    local node = child.value
    -- A child without a route scans again where the player stands.
    if #node.path > 0 then
      previews[#previews + 1] = {
        path = node.path,
        area = #node.children > 0 and scan_tree.scanArea(node, self.area) or Path.endsUpArea(node.path),
        colour = scan_display.pulseColour(child.key),
      }
    end
  end

  local signature = table.concat(array.map(children, tostring), ",")
  if signature == self.preview_signature then return end
  self.preview_signature = signature

  self.ground:setPreview(previews)
  self.map:setPreview(previews)
end

--- Moves on to a child, remembering where the player came from for Shift+0.
---@private
---@param child ScanTree.Child
---@param how string How the pulse was told, for the "Last:" row
---@param press integer? The key press that also narrowed the spots, undone with Shift+0
function ScanClueSolver:step(child, how, press)
  table.insert(self.history, { node = self.node, area = self.area, press = press })
  self.notice = scan_display.pulseName(child.key) .. " (" .. how .. ")"
  self:enter(child.value, scan_tree.scanArea(child.value, self.area))
end

--- The player tells the pulse. It narrows the spots from where the player stood at the last pulses, wherever that is,
--- and moves the tree on only at the tree's scan area: a key pressed elsewhere is not about that area.
---@private
---@param pulse 1 | 2 | 3
function ScanClueSolver:press(pulse)
  local press = pulse < 3 and self.live:press(self.tick, pulse --[[@as 1 | 2]]) or nil
  local status = self.status
  local at_scan_area = status == "wait" or status == "choose" or status == "manual" or status == "mismatch"
  local child = at_scan_area and scan_tree.childForPulse(self.node, pulse, self.different_level) or nil

  if child ~= nil then return self:step(child, "Shift+" .. pulse, press) end

  if press ~= nil then
    table.insert(self.history, { node = self.node, area = self.area, press = press, press_only = true })
    self.notice = scan_display.pulseName({ pulse = pulse }) .. " (Shift+" .. pulse .. ", spots only)"
  elseif pulse < 3 then
    self.notice = "Shift+" .. pulse .. ": wait for a single or double pulse"
  end
  self:render()
end

--- Shift+0: undoes the last step or key press. Going back to a node lets the player choose its pulse by hand.
---@private
function ScanClueSolver:back()
  local previous = table.remove(self.history)
  if previous == nil then return end

  if previous.press then self.live:undo(previous.press) end
  self.notice = "Went back"
  if previous.press_only then return self:refresh() end

  -- The same pulse would take the same step again, so the player chooses this time.
  self:enter(previous.node, previous.area, true)
end

--- The scan panel and its reading while it shows this clue, nil while it is hidden or shows another scan clue, so the
--- clue is only judged by its own panel: right after "Start scanning" it may still show the previous clue.
---@private
---@return ct.ScanPanel.Capture?
---@return ct.ScanPanel.Reading?
function ScanClueSolver:ownPanel()
  local capture = scan_panel.capture()
  if capture == nil then return nil, nil end

  local reading = scan_panel.parse(capture.text)
  if reading.area ~= nil and not scan_panel.showsArea(reading, self.clue.scantext) then return nil, nil end
  return capture, reading
end

--- Whether the clue is gone: the panel closed after it was open, or shows "Scanning..." without the area after the
--- area showed (destroyed). A hidden panel or one of another clue doesn't count, so opening a bank doesn't end it.
---@private
---@param tick integer
---@param reading ct.ScanPanel.Reading?
---@return boolean
function ScanClueSolver:isGone(tick, reading)
  local closed = self.panel_seen and not scan_panel.isOpen()
  local destroyed = self.area_seen and reading ~= nil and reading.area == nil and reading.state == "scanning"
  if not (closed or destroyed) then
    self.gone_since = nil
    return false
  end

  self.gone_since = self.gone_since or tick
  return tick - self.gone_since >= (closed and PANEL_CLOSED_TIMEOUT_TICKS or DESTROYED_TIMEOUT_TICKS)
end

--- Reads the panel and the player's tile: ends the clue when it is gone, updates the spot colours and the map, and
--- works out the status; at the scan area a pulse taken there moves the tree on.
---@private
---@param tick integer
---@param capture ct.ScanPanel.Capture?
---@param reading ct.ScanPanel.Reading?
---@param tile TileCoordinates?
function ScanClueSolver:poll(tick, capture, reading, tile)
  if self:isGone(tick, reading) then return self:finish(self.clue_state) end
  -- Hidden, or still the previous clue's panel: wait for this clue's.
  if capture == nil or reading == nil then return end

  self.panel_seen = true
  if reading.area ~= nil then self.area_seen = true end

  local range = self:range()
  self.ground:colourByPulse(tile, range)
  -- While more than one spot is left, so the squares stay for the whole scan.
  self.map:setRange(#self.remaining > 1 and self.area or nil, range, tile)
  self.map:setPlayer(tile)

  -- Before the leaf check, as a leaf's route leads to another spot then.
  if self.status == "off_route" then return self:render() end

  if #self.node.children == 0 then
    return self:setStatus(capture.found and "dig_here" or "dig")
  end

  if self.status == "manual" then return self:render() end
  if tile == nil then return end

  -- With several triple spots the player leaves the scan spot to look for the right one, until the game says they
  -- stand on it.
  if self.status == "triple" then
    if capture.found then self:decide(reading, tile) end
    return self:render()
  end

  if self.area == nil or not TileArea.contains(self.area, tile) then
    self.arrived_at = nil
    return self:setStatus("travel")
  end

  if self.arrived_at == nil then
    self.arrived_at, self.text_at_arrival = tick, capture.text
  end

  if capture.text == self.text_at_arrival and tick - self.arrived_at < ARRIVAL_WAIT_TICKS then
    return self:setStatus("wait")
  end

  self:decide(reading, tile)
end

--- Moves on through the tree from a reading taken at the scan spot.
---@private
---@param reading ct.ScanPanel.Reading
---@param tile TileCoordinates
function ScanClueSolver:decide(reading, tile)
  if reading.state == "scanning" or reading.state == "unknown" then return self:setStatus("wait") end

  self.different_level = reading.state == "different_level"

  local fits = scan_tree.childrenForReading(self.node, reading, tile)

  if #fits == 0 then
    self:setStatus("mismatch")
  elseif #fits == 1 then
    self:step(fits[1], "auto")
  elseif array.forAll(fits, function(child) return child.key.pulse == 3 end) then
    self:setStatus("triple", fits)
    self:refresh()
  else
    self:setStatus("choose", fits)
  end
end

---@private
---@param status ct.ScanStatus
---@param children ScanTree.Child[]? The children the player chooses between, for "choose", "manual" and "triple"
function ScanClueSolver:setStatus(status, children)
  self.status = status
  self.status_children = children or {}
  self:updatePreview()
  self:render()
end

--- Shows the scan state in the clue state window. Only rebuilds the rows when they change.
---@private
function ScanClueSolver:render()
  if self.tree == nil then
    if self.rendered_signature == "none" then return end
    self.rendered_signature = "none"

    self.clue_state:clearActions()
    self.clue_state:addAction(self.method_action)
    self.clue_state:addAction(ClueStateAction.Text.new("No scan route selected"))
    return
  end

  local rows = scan_display.rows({
    status = self.status,
    tree = self.tree,
    node = self.node,
    children = self.status_children,
    remaining = self.remaining,
    range = self.live:range(),
    notice = self.notice,
    can_go_back = #self.history > 0,
  })

  local signature = table.concat(array.map(rows, function(row)
    return row.state .. (row.colour or "") .. row.text
  end), "\n")
  if signature == self.rendered_signature then return end
  self.rendered_signature = signature

  self.clue_state:clearActions()
  self.clue_state:addAction(self.method_action)
  for _, row in ipairs(rows) do self.clue_state:addAction(scan_display.action(row)) end
end

return ScanClueSolver