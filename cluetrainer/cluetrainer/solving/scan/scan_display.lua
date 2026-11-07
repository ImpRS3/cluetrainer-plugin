-- scan_display.lua
-- How the scan is shown to the player: the pulse names and colours, and the rows of the clue state window.
local Path                   = require "cluetrainer/model/shared/path"
local RichText               = require "cluetrainer/util/RichText"
local ClueStateAction        = require "cluetrainer/interfaces/cluestate/ClueStateAction"
local scan_panel             = require "cluetrainer/solving/scan/scan_panel"
local tiles                  = require "cluetrainer/model/shared/tiles"
local array                  = require "zyklib/array"

local scan_display           = {}

-- Alt1's pulse colours (RGBA) for single, double and triple, so a row reads like the rings around the player.
scan_display.PULSE_COLOURS   = { 0x0F91D3FF, 0xE1A53FFF, 0xD51918FF }
local DIFFERENT_LEVEL_COLOUR = 0x8ADC13FF
-- Rows that need the player's attention, such as a range warning.
local WARNING_COLOUR         = 0xFF6A4DFF

---@class ct.ScanRow
---@field text string
---@field state ct.interfaces.cluestate.ActionState
---@field colour integer? RGBA

---@class ct.ScanDisplay.State
---@field status ct.ScanStatus
---@field tree ScanTree.ScanTree
---@field node ScanTree.ScanTreeNode
---@field children ScanTree.Child[] The children the player chooses between
---@field remaining TileCoordinates[] The node's spots that fit every pulse so far
---@field range integer? The scan range as the panel showed it
---@field notice string? How the last step was told
---@field can_go_back boolean

---@param key PulseInformation
---@return integer RGBA
function scan_display.pulseColour(key)
  return key.different_level and DIFFERENT_LEVEL_COLOUR or scan_display.PULSE_COLOURS[key.pulse]
end

---@param key PulseInformation
---@return string
function scan_display.pulseName(key)
  local name = ({ "Single", "Double", "Triple" })[key.pulse]
  return key.different_level and ("Different level (" .. name:lower() .. ")") or name
end

--- The spot numbers as in the map tooltips and in Alt1 (the position in `ordered_spots`), e.g. "3, 7".
---@param tree ScanTree.ScanTree
---@param spots TileCoordinates[]
---@return string
local function spotNumbers(tree, spots)
  return table.concat(array.map(spots, function(spot)
    local _, index = array.find(tree.ordered_spots, function(candidate) return tiles.same(candidate, spot) end)
    return index > 0 and tostring(index) or "?"
  end), ", ")
end

--- The rows that tell the player how to follow a route: the teleport, then the line on the ground.
---@param path Path.Raw
---@param target string What the route leads to, e.g. "Scan in the green area"
---@return ct.ScanRow[]
local function routeRows(path, target)
  return {}
end

--- Where a child's route goes, in a few words: "tele Falador", "walk", "walk and dig".
---@param child ScanTree.Child
---@return string
local function childRoute(child)
  local teleport = Path.firstTeleport(child.value.path)
  if teleport then return "tele " .. teleport.spot.name end
  if #child.value.children == 0 then return "walk and dig" end
  return Path.hasMovement(child.value.path) and "walk" or "scan here"
end

--- One row per possible pulse with its key and where it leads, in the pulse's colour. Several triples share one row:
--- they differ in the spot, which the game tells.
---@param tree ScanTree.ScanTree
---@param children ScanTree.Child[]
---@return ct.ScanRow[]
local function optionRows(tree, children)
  local rows = {}
  local triples = array.filter(children, function(c) return c.key.pulse == 3 and not c.key.different_level end)

  for _, child in ipairs(children) do
    local key = child.key

    if key.different_level or key.pulse < 3 or #triples == 1 then
      local label = (key.pulse < 3 or #triples == 1) and ("Shift+" .. key.pulse) or "Triple"
      if key.different_level then label = label .. " DL" end

      rows[#rows + 1] = {
        text = label .. ": " .. childRoute(child),
        state = "incomplete",
        colour = scan_display.pulseColour(key),
      }
    end
  end

  if #triples > 1 then
    local spots = array.map(triples, function(child) return child.key.spot end)
    rows[#rows + 1] = {
      text = "Triple: spot " .. spotNumbers(tree, spots),
      state = "incomplete",
      colour = scan_display.PULSE_COLOURS[3],
    }
  end

  return rows
end

--- What the player does now: the route to follow, or the pulses to tell apart with where each one leads.
---@param state ct.ScanDisplay.State
---@return ct.ScanRow[]
local function instruction(state)
  local status, node = state.status, state.node

  ---@param text string
  ---@param options ScanTree.Child[]?
  ---@return ct.ScanRow[]
  local function rows(text, options)
    local result = { { text = text, state = "incomplete" } }
    for _, row in ipairs(options and optionRows(state.tree, options) or {}) do result[#result + 1] = row end
    return result
  end

  if status == "travel" then
    return {}
  elseif status == "wait" then
    return rows("Wait for the pulse", node.children)
  elseif status == "choose" then
    return rows("Which pulse?", state.children)
  elseif status == "manual" then
    return rows("Choose the pulse", state.children)
  elseif status == "triple" then
    return {
      { text = "Triple: one of spots " .. spotNumbers(state.tree, state.remaining),                       state = "incomplete" },
      { text = #state.remaining > 1 and "Walk towards one, the next pulse tells" or "Walk there and dig", state = "incomplete" },
    }
  elseif status == "off_route" then
    local spots = spotNumbers(state.tree, state.remaining)
    return {
      { text = "Triple points off the route", state = "incomplete", colour = WARNING_COLOUR },
      #state.remaining > 1
      and { text = "One of spots " .. spots .. ": walk towards one", state = "incomplete" }
      or {
        text = "Spot " .. spots .. ": walk there and dig",
        state = "incomplete",
        colour = scan_display.PULSE_COLOURS
            [3]
      },
    }
  elseif status == "mismatch" then
    return {
      { text = "Pulse doesn't fit the route", state = "incomplete", colour = WARNING_COLOUR },
      { text = "Check position and range",    state = "incomplete", colour = WARNING_COLOUR },
    }
  elseif status == "dig" then
    return {}
  elseif status == "dig_here" then
    return rows("Dig here")
  end

  return {}
end

--- A warning when the player's scan range differs from the one the route was made for.
---@param range integer? As the panel showed it
---@param assumed integer
---@return string?
local function rangeWarning(range, assumed)
  if range == nil or range == assumed then return nil end
  if range + scan_panel.MEERKATS_RANGE == assumed then
    return string.format("Route assumes meerkats (%d paces), you have %d", assumed, range)
  end
  return string.format("Route assumes %d paces, you have %d", assumed, range)
end

--- All rows of the clue state window: a range warning, the spot when only one fits, the instruction, the last step
--- and how to go back.
---@param state ct.ScanDisplay.State
---@return ct.ScanRow[]
function scan_display.rows(state)
  local rows = {}

  local warning = rangeWarning(state.range, state.tree.assumed_range)
  if warning then rows[#rows + 1] = { text = warning, state = "incomplete", colour = WARNING_COLOUR } end
  if #state.node.children > 0 and #state.remaining == 1 and state.status ~= "off_route" then
    rows[#rows + 1] = {
      text = "Only spot " .. spotNumbers(state.tree, state.remaining) .. " fits: dig there",
      state = "incomplete",
      colour = scan_display.PULSE_COLOURS[3],
    }
  end
  for _, row in ipairs(instruction(state)) do rows[#rows + 1] = row end

  return rows
end

--- The clue state action for a row.
---@param row ct.ScanRow
---@return ct.interfaces.cluestate.TextClueStateAction
function scan_display.action(row)
  local text = row.colour and RichText.coloured(row.text, string.format("%06X", row.colour >> 8)) or row.text

  local action = ClueStateAction.Text.new(text)
  action:setState(row.state)
  return action
end

return scan_display
