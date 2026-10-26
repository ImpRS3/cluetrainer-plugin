local StaticTwig = require("prettymap/luaflet/twigs/StaticTwig")
local common = require("prettymap/luaflet/twigs/prefab/controls_common")

local WIDTH = 180
local HEIGHT = 31
local BUTTON_SIZE = 23
local BORDER = 4

-- TODO: use dedicated previous/next section sprites; these are the zoom button sprites.
local PREVIOUS_SPRITES = common.SPRITES.zoomOut
local NEXT_SPRITES = common.SPRITES.zoomIn

--- A viewport-anchored panel to step through the sections of a path: previous and next buttons
--- around the name of the active section. A button is disabled when there is no section in its direction.
---@class ct.SectionControl : prettymap.StaticElement
---@field private names string[]
---@field private index integer Active section, 1-based.
---@field section_changed zyklib.reactive.Event<integer, nil> Triggered with the new index when a button changes the active section.
---@field private text ui.Text?
---@field private previous prettymap.luaflet.ControlButton?
---@field private next prettymap.luaflet.ControlButton?
local SectionControl = setmetatable({}, { __index = StaticTwig })
SectionControl.__index = SectionControl

---@class ct.SectionControlOptions
---@field names string[] Section names in order.
---@field index integer? Initially active section. Default is the last one.
---@field anchor prettymap.Anchor? Default "bottom".
---@field offsetX number?
---@field offsetY number? Default 8.

---@param options ct.SectionControlOptions
---@return ct.SectionControl
function SectionControl.new(options)
  local self = setmetatable(StaticTwig.new({
    anchor = options.anchor or "top",
    offsetX = options.offsetX or 0,
    offsetY = options.offsetY or 8,
    width = WIDTH,
    height = HEIGHT,
  }), SectionControl)
  ---@cast self ct.SectionControl
  self.names = options.names
  self.index = options.index or #options.names
  self.section_changed = zyklib.reactive.Event.new()
  return self
end

--- Updates the name and the enabled state of the buttons.
---@private
function SectionControl:Refresh()
  if not self.text then return end
  self.text.content = self.names[self.index] or ""
  self.previous:SetDisabled(self.index <= 1)
  self.next:SetDisabled(self.index >= #self.names)
end

--- Makes `index` the active section, clamped to the existing sections, without triggering `section_changed`.
---@param index integer
function SectionControl:SetIndex(index)
  self.index = math.max(1, math.min(#self.names, index))
  self:Refresh()
end

---@param names string[]
---@param index integer? Default is the last section.
function SectionControl:SetSections(names, index)
  self.names = names
  self:SetIndex(index or #names)
end

---@private
---@param delta integer
function SectionControl:_Step(delta)
  local target = self.index + delta
  if target < 1 or target > #self.names then return end
  self:SetIndex(target)
  self.section_changed:trigger(self.index)
end

---@param layer ui.Layer
---@return boolean added
function SectionControl:CreateComponent(layer)
  local container = common.panel(layer)
  local inner_width = WIDTH - BORDER * 2

  self.previous = common.button(container, PREVIOUS_SPRITES, function() self:_Step(-1) end, 0, BUTTON_SIZE)
  self.text = common.label(container, BUTTON_SIZE, inner_width - BUTTON_SIZE * 2, BUTTON_SIZE)
  self.next = common.button(container, NEXT_SPRITES, function() self:_Step(1) end, inner_width - BUTTON_SIZE, BUTTON_SIZE)

  self:Refresh()
  return true
end

return SectionControl
