local elements = require("prettymap/elements")
local geometry = require("cluetrainer/map/elements/geometry")

--- Outlined and tinted areas as polygon elements, in the style of the original map's area polygons.
local AreaGraphics = {}

---@class cluetrainer.AreaStyle
---@field colour integer RGB colour, e.g. 0xFFFF00.
---@field weight number? Outline width in pixels. Default 2.
---@field opacity number? Outline opacity from 0 to 1. Default 0.5.
---@field fillOpacity number? Fill opacity from 0 to 1. Default 0.1.

---@param rgb integer
---@param opacity number
---@return integer rgba
local function rgba(rgb, opacity)
  return rgb * 256 + math.floor(opacity * 255 + 0.5)
end

---@param a CoordFine
---@param b CoordFine
---@param style cluetrainer.AreaStyle
---@return prettymap.PolygonElement
local function box(a, b, style)
  local polygon = elements.PolygonElement.new()
  local fill = style.fillOpacity or 0.1
  if fill > 0 then polygon:AddRectangle(a, b, rgba(style.colour, fill)) end
  local opacity = style.opacity or 0.5
  if opacity > 0 then polygon:AddOutline(a, b, style.weight or 2, rgba(style.colour, opacity)) end
  return polygon
end

---@param area TileArea
---@param style cluetrainer.AreaStyle
---@return prettymap.PolygonElement
function AreaGraphics.area(area, style)
  local a, b = geometry.area_corners(area)
  return box(a, b, style)
end

---@param rect TileRectangle
---@param style cluetrainer.AreaStyle
---@return prettymap.PolygonElement
function AreaGraphics.rect(rect, style)
  local a, b = geometry.rect_corners(rect)
  return box(a, b, style)
end

return AreaGraphics
