local elements = require("prettymap/elements")
local geometry = require("cluetrainer/map/elements/geometry")
local AreaGraphics = require("cluetrainer/map/elements/AreaGraphics")
local InteractionMarker = require("cluetrainer/map/elements/InteractionMarker")

--- A static object: a cyan box around it, plus an interaction marker in its centre if it has a cursor.
--- Only the marker reacts to hovering, so tooltips are attached to it and need a cursor.
---@class cluetrainer.ObjectEntity : prettymap.Element
---@field name string
---@field box TileRectangle
---@field cursor string?
---@field marker cluetrainer.InteractionMarker? Nil without a cursor.
local ObjectEntity = setmetatable({}, { __index = elements.Element })
ObjectEntity.__index = ObjectEntity

---@param name string
---@param box TileRectangle
---@param cursor string? Cursor sprite key of the marker; no marker if nil.
---@param options cluetrainer.EntityOptions?
---@return cluetrainer.ObjectEntity
function ObjectEntity.new(name, box, cursor, options)
  local highlight = options ~= nil and options.highlight == true
  local self = setmetatable(elements.Element.new(), ObjectEntity)
  ---@cast self cluetrainer.ObjectEntity
  self.name = name
  self.box = box
  self.cursor = cursor

  self:Add(AreaGraphics.rect(box, {
    colour = 0x00FFFF,
    weight = highlight and 4.5 or 3,
    opacity = 1,
    fillOpacity = 0.1,
  }))
  if cursor then
    self.marker = InteractionMarker.new({
      coordinate = geometry.rect_center(box),
      cursor = cursor,
      highlight = highlight,
    })
    self:Add(self.marker)
  end
  return self
end

return ObjectEntity
