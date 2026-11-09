local ClueStateAction = require("cluetrainer/solving/cluestateinterface/ClueStateAction")
local scan_display = require("cluetrainer/solving/scan/scan_display")

local STATE_ALPHA = { incomplete = 1.0, complete = 0.5 }
local TEXT_ROW_HEIGHT = 28
local BUTTON_ROW_HEIGHT = 22
local INFO_SIZE = 20
local INFO_GAP = 4
local PULSE_BUTTON_COUNT = 3
local PULSE_BUTTON_GAP = 4

---Tint each background sprite, including both surfaces of a paired panel button.
---@param button PrettyUI.SimpleButton
---@param colour integer
local function tintButton(button, colour)
  local function tint(surface)
    for _, part in pairs(surface.parts) do part.rgba = colour end
  end

  if button.dock then
    tint(button.dock)
    tint(button.overlay)
  else
    tint(button)
  end
end

---A text row with an info tooltip and buttons for entering a single or double scan pulse.
---@class ct.interfaces.cluestate.ScanPulseClueStateAction : ct.interfaces.cluestate.ClueStateAction
---@field content string
---@field tooltip string
---@field enabled boolean
---@field private on_pulse fun(pulse: 1|2|"undo")
---@field undo_enabled boolean
---@field private text ui.Text?
---@field private info PrettyUI.SpriteButton?
---@field private single PrettyUI.SimpleButton?
---@field private double PrettyUI.SimpleButton?
---@field private undo PrettyUI.SimpleButton?
local ScanPulse = setmetatable({}, { __index = ClueStateAction })
ScanPulse.__index = ScanPulse

---Creates an enabled scan-pulse action.
---@param content string
---@param tooltip string
---@param on_pulse fun(pulse: 1|2|"undo") Called with 1, 2, or "undo".
---@return ct.interfaces.cluestate.ScanPulseClueStateAction
function ScanPulse.new(content, tooltip, on_pulse)
  local self = setmetatable({}, ScanPulse)
  self:_init()
  self.content = content
  self.tooltip = tooltip
  self.enabled = true
  self.undo_enabled = false
  self.on_pulse = on_pulse
  return self
end

---@param content string
---@return ct.interfaces.cluestate.ScanPulseClueStateAction
function ScanPulse:setText(content)
  self.content = content
  if self.constructed then self:_apply() end
  return self
end

---@param tooltip string
---@return ct.interfaces.cluestate.ScanPulseClueStateAction
function ScanPulse:setTooltip(tooltip)
  self.tooltip = tooltip
  if self.constructed then self:_apply() end
  return self
end

---@param enabled boolean
---@return ct.interfaces.cluestate.ScanPulseClueStateAction
function ScanPulse:setEnabled(enabled)
  self.enabled = enabled
  if self.constructed then self:_apply() end
  return self
end

---@param enabled boolean
---@return ct.interfaces.cluestate.ScanPulseClueStateAction
function ScanPulse:setUndoEnabled(enabled)
  self.undo_enabled = enabled
  if self.constructed then self:_apply() end
  return self
end

---@protected
---@param view PrettyUI.View
function ScanPulse:_construct(view)
  local single_width = math.floor((view.contentWidth - (PULSE_BUTTON_COUNT - 1) * PULSE_BUTTON_GAP)
      / PULSE_BUTTON_COUNT)
  local double_width = single_width
  local undo_width = view.contentWidth - 2 * PULSE_BUTTON_GAP - single_width - double_width
  self.text = view:AddText({
    text = self.content,
    x = 0,
    width = -(INFO_SIZE + INFO_GAP),
    widthAnchor = 1.0,
    height = TEXT_ROW_HEIGHT,
    maxLines = 1,
    marginBottom = 0,
    rowBackgroundGroup = self,
  })
  self.text.clickthrough = true
  self.info = view:AddSpriteButton("INFO", nil, {
    inline = true,
    x = -INFO_SIZE,
    xAnchor = 1.0,
    offsetY = TEXT_ROW_HEIGHT - INFO_SIZE,
    size = INFO_SIZE,
    marginBottom = 0,
    tooltip = self.tooltip,
    rowBackgroundGroup = self,
  })
  self.single = view:AddSimpleButton("Single", function()
    if self.enabled then self.on_pulse(1) end
  end, {
    x = 0,
    width = single_width,
    height = BUTTON_ROW_HEIGHT,
    marginBottom = 0,
    rowBackgroundGroup = self,
  })
  self.double = view:AddSimpleButton("Double", function()
    if self.enabled then self.on_pulse(2) end
  end, {
    inline = true,
    x = -double_width / 2,
    xAnchor = 0.5,
    width = double_width,
    height = BUTTON_ROW_HEIGHT,
    marginBottom = 0,
    rowBackgroundGroup = self,
  })
  self.undo = view:AddSimpleButton("Undo", function()
    if self.undo_enabled then self.on_pulse("undo") end
  end, {
    inline = true,
    x = -undo_width,
    xAnchor = 1.0,
    width = undo_width,
    height = BUTTON_ROW_HEIGHT,
    marginBottom = 0,
    rowBackgroundGroup = self,
  })
end

---@protected
function ScanPulse:_apply()
  self.text.content = self.content
  self.text.alpha = STATE_ALPHA[self.state]
  self.info:SetTooltip(self.tooltip)
  self.single:SetDisabled(not self.enabled)
  self.double:SetDisabled(not self.enabled)
  self.undo:SetDisabled(not self.undo_enabled)
  tintButton(self.single, self.enabled and scan_display.PULSE_COLOURS[1] or 0xFFFFFFFF)
  tintButton(self.double, self.enabled and scan_display.PULSE_COLOURS[2] or 0xFFFFFFFF)
  tintButton(self.undo, 0xFFFFFFFF)
end

function ScanPulse:destroy()
  for _, component in ipairs({ self.undo, self.double, self.single, self.info, self.text }) do
    component:Destroy()
  end
  self.undo, self.double, self.single, self.info, self.text = nil, nil, nil, nil, nil
  self.constructed = false
end

return ScanPulse
