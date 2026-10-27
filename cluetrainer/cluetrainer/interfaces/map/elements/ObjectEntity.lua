local luaflet = require("prettymap/luaflet")
local geometry = require("cluetrainer/interfaces/map/elements/geometry")
local AreaGraphics = require("cluetrainer/interfaces/map/elements/AreaGraphics")
local InteractionMarker = require("cluetrainer/interfaces/map/elements/InteractionMarker")

--- A static object: a cyan box around it, plus an interaction marker in its centre if it has a cursor.
--- Only the marker reacts to hovering, so tooltips are attached to it and need a cursor.
---@class cluetrainer.ObjectEntity : prettymap.luaflet.Twig
---@field marker cluetrainer.InteractionMarker? Nil without a cursor.
local ObjectEntity = setmetatable({}, { __index = luaflet.twigs.Twig })
ObjectEntity.__index = ObjectEntity

---@param name string
---@param box TileRectangle
---@param cursor string? Cursor sprite key of the marker; no marker if nil.
---@return cluetrainer.ObjectEntity
function ObjectEntity.new(name, box, cursor)
  local self = setmetatable(luaflet.twigs.Twig.new(), ObjectEntity)
  ---@cast self cluetrainer.ObjectEntity

  self:Add(AreaGraphics.rect(box, {
    colour = 0x00FFFF,
    weight = 3,
    opacity = 1,
    fillOpacity = 0.1,
  }))
  if cursor then
    self.marker = InteractionMarker.new({
      coordinate = geometry.rect_center(box),
      cursor = cursor,
    })
    self:Add(self.marker)
  end
  return self
end

return ObjectEntity
