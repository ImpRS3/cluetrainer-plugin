local luaflet = require("prettymap/luaflet")
local geometry = require("cluetrainer/map/elements/geometry")
local colours = require("cluetrainer/util/colours")

--- Outlined and tinted areas as polygon elements, in the style of the original map's area polygons.
local AreaGraphics = {}

---@class cluetrainer.AreaStyle
---@field colour integer RGB colour, e.g. 0xFFFF00.
---@field weight number? Outline width in pixels. Default 2.
---@field opacity number? Outline opacity from 0 to 1. Default 0.5.
---@field fillOpacity number? Fill opacity from 0 to 1. Default 0.1.

---@param a prettymap.luaflet.Coord
---@param b prettymap.luaflet.Coord
---@param style cluetrainer.AreaStyle
---@return prettymap.luaflet.PolygonTwig
local function box(a, b, style)
  local polygon = luaflet.twigs.PolygonTwig.new()
  local fill = style.fillOpacity or 0.1
  if fill > 0 then polygon:AddRectangle(a, b, colours.rgba(style.colour, fill)) end
  local opacity = style.opacity or 0.5
  if opacity > 0 then polygon:AddOutline(a, b, style.weight or 2, colours.rgba(style.colour, opacity)) end
  return polygon
end

---@param area TileArea
---@param style cluetrainer.AreaStyle
---@return prettymap.luaflet.PolygonTwig
function AreaGraphics.area(area, style)
  local a, b = geometry.area_corners(area)
  return box(a, b, style)
end

---@param rect TileRectangle
---@param style cluetrainer.AreaStyle
---@return prettymap.luaflet.PolygonTwig
function AreaGraphics.rect(rect, style)
  local a, b = geometry.rect_corners(rect)
  return box(a, b, style)
end

return AreaGraphics
