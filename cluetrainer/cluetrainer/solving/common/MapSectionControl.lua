local StaticTwig = require("prettymap/luaflet/twigs/StaticTwig")
local common = require("prettymap/luaflet/twigs/prefab/controls_common")

local WIDTH = 180
local HEIGHT = 31
local BUTTON_SIZE = 23
local BORDER = 4
local INSET_MARGIN = 8

-- TODO: use dedicated previous/next section sprites; these are the zoom button sprites.
local PREVIOUS_SPRITES = common.SPRITES.ARROW_LEFT
local NEXT_SPRITES = common.SPRITES.ARROW_RIGHT

--- A viewport-anchored panel to step through named map bounds: previous and next buttons around
--- the name of the active one. Stepping zooms the map to fit the active bounds. A button is
--- disabled when there is no entry in its direction.
---@class ct.MapSectionControl : prettymap.StaticElement
---@field map ct.GameMap
---@field private sections {name: string, bounds: ct.Bounds}[]
---@field private index integer Active entry, 1-based.
---@field section_changed zyklib.reactive.Event<integer, nil> Triggered with the new index when a button changes the active entry.
---@field private text ui.Text?
---@field private previous prettymap.luaflet.ControlButton?
---@field private next prettymap.luaflet.ControlButton?
local MapSectionControl = setmetatable({}, { __index = StaticTwig })
MapSectionControl.__index = MapSectionControl

---@class ct.MapSectionControlOptions
---@field anchor prettymap.Anchor? Default "top".
---@field offsetX number?
---@field offsetY number? Default 8.
---@field index integer? Initially active entry. Default is the last one.

---@param map ct.GameMap
---@param sections {name: string, bounds: ct.Bounds}[]
---@param options ct.MapSectionControlOptions?
---@return ct.MapSectionControl
function MapSectionControl.new(map, sections, options)
  options = options or {}
  local self = setmetatable(StaticTwig.new({
    anchor = options.anchor or "top",
    offsetX = options.offsetX or 0,
    offsetY = options.offsetY or 8,
    width = WIDTH,
    height = HEIGHT,
  }), MapSectionControl)
  ---@cast self ct.MapSectionControl
  self.map = map
  self.sections = sections
  self.index = options.index or #sections
  self.section_changed = zyklib.reactive.Event.new()

  self:AddTo(map.map.twigs)
  self:setSection(self.index)

  return self
end

--- Updates the name and the enabled state of the buttons.
---@private
function MapSectionControl:Refresh()
  if not self.text then return end
  local section = self.sections[self.index]
  self.text.content = section and section.name or ""
  self.previous:SetDisabled(self.index <= 1)
  self.next:SetDisabled(self.index >= #self.sections)
end

--- Zooms the map to fit the given entry and makes it the active one, without triggering `section_changed`.
---@param index integer
function MapSectionControl:setSection(index)
  local section = self.sections[index]
  if not section then return end

  self.index = index
  self:Refresh()

  -- Keep the bounds clear of the navigator ui.
  self.map:fitBounds(section.bounds:copy():extend(0.05), self.offsetY + HEIGHT + INSET_MARGIN)
end

---@private
---@param delta integer
function MapSectionControl:_Step(delta)
  local target = self.index + delta
  if target < 1 or target > #self.sections then return end
  self:setSection(target)
  self.section_changed:trigger(target)
end

---@param layer ui.Layer
---@return boolean added
function MapSectionControl:CreateComponent(layer)
  local container = common.panel(layer)
  local inner_width = WIDTH - BORDER * 2

  self.previous = common.button(container, PREVIOUS_SPRITES, function() self:_Step(-1) end, 0, BUTTON_SIZE)
  self.text = common.label(container, BUTTON_SIZE, inner_width - BUTTON_SIZE * 2, BUTTON_SIZE)
  self.text.clickthrough = false
  local cursor = config.Cursor.CURSOR_SEARCH
  self.text.cursorConfig.mouseOverCursor = cursor.id
  self.text.opConfig:SetOpCursor(0, cursor.id)
  self.text:Subscribe(ui.Hook.ONCLICK, function()
    self:setSection(self.index)
    return false
  end)
  self.next = common.button(container, NEXT_SPRITES, function() self:_Step(1) end, inner_width - BUTTON_SIZE, BUTTON_SIZE)

  self:Refresh()
  return true
end

--- Removes the navigator from the map.
function MapSectionControl:dispose()
  self:Detach()
end

return MapSectionControl
