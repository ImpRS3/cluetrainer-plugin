-- scan_panel.lua
-- Reads the scan clue side panel (TRAIL_SCANCLUE_SIDE). Only visible text is used.

---@alias ct.ScanPanel.State
---| "scanning" # No pulse yet, or the clue was destroyed
---| "different_level"
---| "too_far" # Single or double, the panel doesn't tell them apart
---| "triple"
---| "found" # The player stands on the dig spot
---| "unknown"

---@class ct.ScanPanel.Reading
---@field area string? The scan area as shown in the panel
---@field state ct.ScanPanel.State
---@field range integer? The scan range including meerkats, only shown with "too far"
---@field paces integer? Distance to the dig spot, only shown with a triple
---@field meerkats boolean

---@class ct.ScanPanel.Capture
---@field text string The raw panel text
---@field found boolean Whether the "standing at the right coordinate" text is shown

local scan_panel = {}

-- The game takes a pulse every 60 logic ticks (1.2 seconds); the text changes only then.
scan_panel.PULSE_TICKS = 60
-- Meerkats add 5 paces to the clue's scan range.
scan_panel.MEERKATS_RANGE = 5

---@param text string
---@return ct.ScanPanel.Reading
function scan_panel.parse(text)
  local area, body = text:match("^(.-)<br><br>(.*)$")
  body = (body or text):gsub("<br>", " "):gsub("<[^>]*>", "")

  ---@type ct.ScanPanel.Reading
  local reading = {
    area = area,
    state = "unknown",
    meerkats = body:find("Your meerkats increase", 1, true) ~= nil,
  }

  if body:find("You are standing at the right coordinate", 1, true) then
    reading.state = "found"
  elseif body:find("Try scanning a different level", 1, true) then
    reading.state = "different_level"
  elseif body:find("The orb glows as you scan", 1, true) or body:find("The orb glows then flickers", 1, true) then
    reading.state = "triple"
    reading.paces = tonumber(body:match("(%d+) paces? away"))
  elseif body:find("You are too far away", 1, true) then
    reading.state = "too_far"
    reading.range = tonumber(body:match("scan range of this orb is (%d+) paces?"))
  elseif body:find("Scanning...", 1, true) then
    reading.state = "scanning"
  end

  return reading
end

--- The scan range including meerkats, when the reading tells it: "too far" shows it, a triple shows whether meerkats
--- are on, so it is the clue's range plus theirs.
---@param reading ct.ScanPanel.Reading
---@param clue_range integer The clue's range without meerkats
---@return integer?
function scan_panel.range(reading, clue_range)
  if reading.range ~= nil then return reading.range end
  if reading.state == "triple" then return clue_range + (reading.meerkats and scan_panel.MEERKATS_RANGE or 0) end
  return nil
end

--- Whether the panel shows the given scan area. Ignores case, to match clue data with other capitalisation.
---@param reading ct.ScanPanel.Reading
---@param scantext string
---@return boolean
function scan_panel.showsArea(reading, scantext)
  return reading.area ~= nil and reading.area:lower() == scantext:lower()
end

--- Whether the panel is open, also while its text is hidden.
---@return boolean
function scan_panel.isOpen()
  return ui.Interfaces:GetInterface(id.Interface.TRAIL_SCANCLUE_SIDE) ~= nil
end

--- Captures the panel as the player sees it.
---@return ct.ScanPanel.Capture? # nil when the panel is closed or hidden
function scan_panel.capture()
  if not scan_panel.isOpen() then return nil end

  -- FOUND_TEXT first: on the dig spot the game shows it instead of SCAN_DATA.
  local found = ui.Interfaces:GetComponent(id.Component.TRAIL_SCANCLUE_SIDE__FOUND_TEXT) --[[@as ui.Text?]]
  if found ~= nil and found.visibleGlobal then
    return { text = found.content, found = true }
  end

  local data = ui.Interfaces:GetComponent(id.Component.TRAIL_SCANCLUE_SIDE__SCAN_DATA) --[[@as ui.Text?]]
  if data ~= nil and data.visibleGlobal then
    return { text = data.content, found = false }
  end

  return nil
end

return scan_panel
