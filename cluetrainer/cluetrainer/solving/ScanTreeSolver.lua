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
local methods            = require "cluetrainer/methods/method_management"
local ClueStateAction    = require "cluetrainer/interfaces/cluestate/ClueStateAction"
local scan_panel         = require "cluetrainer/solving/scan/scan_panel"
local scan_tree          = require "cluetrainer/solving/scan/scan_tree"
local scan_display       = require "cluetrainer/solving/scan/scan_display"
local ScanMap            = require "cluetrainer/solving/scan/ScanMap"
local ScanGround         = require "cluetrainer/solving/scan/ScanGround"
local LiveNarrowing      = require "cluetrainer/solving/scan/LiveNarrowing"
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
---| "mismatch" # The panel shows a pulse the tree doesn't have here
---| "dig" # One spot left, follow the route and dig
---| "dig_here" # The panel says the player stands on the dig spot

--- One scan clue in progress.
---@class ct.ActiveScanClue : ct.ActiveClueSolver
---@field clue Scan
---@field tree ScanTree.ScanTree
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
local ActiveScanClue = setmetatable({}, { __index = ActiveClueSolver })
ActiveScanClue.__index = ActiveScanClue

---@param clue Scan
---@param method Method.ScanTree
---@param clue_state ct.ClueStateInterface
---@return ct.ActiveScanClue
function ActiveScanClue.new(clue, method, clue_state)
  local self = setmetatable(ActiveClueSolver.new(clue), ActiveScanClue)
  ---@cast self ct.ActiveScanClue

  self.tree = method.tree
  self.history = {}
  self.tick = 0
  self.candidates = scan_tree.candidates(method.tree)
  self.clue_state = clue_state
  self.navigator = Navigator.new()
  self.map = ScanMap.new(method.tree)
  self.ground = ScanGround.new()
  self.live = LiveNarrowing.new(method.tree.ordered_spots, clue.range)
  self.remaining = {}
  self.panel_seen = false
  self.area_seen = false
  self.different_level = false
  self.status = "travel"
  self.status_children = {}

  self.disposable_group:add(self.navigator)
  self.disposable_group:add(self.map)
  self.disposable_group:add(self.ground)

  self.disposable_group:add(zyklib.game_events.native.Logic:subscribe(function(payload)
    local tick, tile = payload.logicTick, coordinate_adaptor.playerTile()
    local capture, reading = self:ownPanel()
    self.tick = tick
    -- Every tick, so the tile is the one of the pulse.
    if self.live:sample(tick, tile, capture) then self:refresh() end
    if tick % POLL_EVERY_TICKS == 0 then self:poll(tick, capture, reading, tile) end
  end))

  -- On key down, to read Shift while it is still held.
  self.disposable_group:add(zyklib.game_events.native.KeyDown:subscribe(function(event)
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

  self:enter(self.tree.root, scan_tree.scanArea(self.tree.root, nil))

  return self
end

---@private
---@param node ScanTree.ScanTreeNode
---@param area TileArea?
---@param manual boolean? The player went back to this node and picks its pulse by hand
function ActiveScanClue:enter(node, area, manual)
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
function ActiveScanClue:range()
  return self.live:range() or self.tree.assumed_range
end

--- The node's spots that fit every pulse so far; with several triples only theirs. Should no spot fit, the pulses
--- disagree with the tree (other range, other route) and the tree's spots stay.
---@private
---@return TileCoordinates[]
function ActiveScanClue:remainingSpots()
  local spots = self.candidates[self.node]
  if self.status == "triple" then
    spots = array.map(self.status_children, function(child) return child.key.spot end)
  end

  local narrowed = self.live:filter(spots)
  return #narrowed > 0 and narrowed or spots
end

--- Shows the remaining spots on the map and the ground. Once they all lie under one child, the scan here can only
--- pick that child, so its route follows; not after going back, as the player picks then.
---@private
function ActiveScanClue:refresh()
  self.remaining = self:remainingSpots()
  self.map:setRemaining(self.remaining)
  self.ground:setSpots(self.remaining)

  if self.status ~= "manual" then
    local children = self.status == "triple" and self.status_children or self.node.children
    local child = scan_tree.onlyChildWith(children, self.remaining, self.candidates)
    if child then return self:step(child, "spots left") end
  end

  self:render()
end

--- The routes the player chooses between with Shift, faded on the ground and the map. Not while waiting for the
--- pulse: that decides within a second, and the routes would only flash up.
---@private
function ActiveScanClue:updatePreview()
  local status, children = self.status, {}
  if status == "mismatch" then
    -- The panel doesn't pick a child, so the player may pick any.
    children = self.node.children
  elseif status == "choose" or status == "manual" or status == "triple" then
    children = self.status_children
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
function ActiveScanClue:step(child, how, press)
  table.insert(self.history, { node = self.node, area = self.area, press = press })
  self.notice = scan_display.pulseName(child.key) .. " (" .. how .. ")"
  self:enter(child.value, scan_tree.scanArea(child.value, self.area))
end

--- The player tells the pulse. It narrows the spots from where the player stood at the last pulses, wherever that is,
--- and moves the tree on only at the tree's scan area: a key pressed elsewhere is not about that area.
---@private
---@param pulse 1 | 2 | 3
function ActiveScanClue:press(pulse)
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
function ActiveScanClue:back()
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
function ActiveScanClue:ownPanel()
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
function ActiveScanClue:isGone(tick, reading)
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
function ActiveScanClue:poll(tick, capture, reading, tile)
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
function ActiveScanClue:decide(reading, tile)
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
function ActiveScanClue:setStatus(status, children)
  self.status = status
  self.status_children = children or {}
  self:updatePreview()
  self:render()
end

--- Shows the scan state in the clue state window. Only rebuilds the rows when they change.
---@private
function ActiveScanClue:render()
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
  for _, row in ipairs(rows) do self.clue_state:addAction(scan_display.action(row)) end
end

--- Shows the scan again on the map the player closed.
---@return boolean reopened
function ActiveScanClue:reopenMap()
  self.map:reopen()
  return true
end

local ScanTreeSolver = {}

--- Starts the scan tree of the clue, or tells there is none.
---@param clue Scan
---@param clue_state ct.ClueStateInterface
---@return ct.ActiveClueSolver
function ScanTreeSolver.new(clue, clue_state)
  local method = array.find(methods.getAllForClue({ clue = clue.id }), function(augmented)
    return augmented.method.type == "scantree"
  end)

  if method == nil then
    clue_state:clearActions()
    clue_state:addAction(ClueStateAction.Text.new("No scan route for this clue"))
    return ActiveClueSolver.new(clue)
  end

  return ActiveScanClue.new(clue, method.method --[[@as Method.ScanTree]], clue_state)
end

return ScanTreeSolver
