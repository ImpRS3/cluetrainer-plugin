local luaflet = require("prettymap/luaflet")
local geometry = require("cluetrainer/interfaces/map/elements/geometry")

--- Arrows, nd marks for rendering paths, as polygon elements.
--- Points are tile coordinates; integer coordinates are tile centres.
local PathGraphics = {}

local DASH_LENGTH = 0.25 -- tiles
local HEAD_ANGLE = math.rad(30)
-- Corners of the polygon a circle is drawn as.
local CIRCLE_SEGMENTS = 12

---@class cluetrainer.ArrowStyle
---@field colour integer RGBA colour.
---@field weight number? Stroke width in pixels. Default 3.
---@field dashed boolean?
---@field head ("tip"|"x")? Default "tip".
---@field arm_length number? Length of the head's arms in tiles. Default 0.5 for "tip", 0.25 for "x".

--- Moves `from` towards `to` by `distance` tiles.
---@param from TileCoordinates
---@param to TileCoordinates
---@param distance number
---@return TileCoordinates
function PathGraphics.offset_towards(from, to, distance)
  local dx, dy = to.x - from.x, to.y - from.y
  local length = math.sqrt(dx * dx + dy * dy)
  if length == 0 then return from end
  return { x = from.x + dx / length * distance, y = from.y + dy / length * distance, level = from.level }
end

---@param polygon prettymap.luaflet.PolygonTwig
---@param ax number
---@param ay number
---@param bx number
---@param by number
---@param level integer
---@param weight number
---@param colour integer
local function line(polygon, ax, ay, bx, by, level, weight, colour)
  polygon:AddLine(geometry.point(ax, ay, level), geometry.point(bx, by, level), weight, colour)
end

--- A dashed line, starting and ending with a dash.
---@param polygon prettymap.luaflet.PolygonTwig
---@param ax number
---@param ay number
---@param bx number
---@param by number
---@param level integer
---@param weight number
---@param colour integer
---@param dash_length number? In tiles. Default 0.25.
function PathGraphics.dashed_line(polygon, ax, ay, bx, by, level, weight, colour, dash_length)
  local dx, dy = bx - ax, by - ay
  local length = math.sqrt(dx * dx + dy * dy)
  local segments = math.max(1, math.floor(length / (dash_length or DASH_LENGTH) / 2))
  local step = length / (segments * 2 - 1)
  for i = 0, segments - 1 do
    local t0, t1 = (i * 2) * step / length, (i * 2 + 1) * step / length
    line(polygon, ax + dx * t0, ay + dy * t0, ax + dx * t1, ay + dy * t1, level, weight, colour)
  end
end

--- An arrow from `from` to `to`, optionally dashed, with a tip or an x as its head.
---@param from TileCoordinates
---@param to TileCoordinates
---@param style cluetrainer.ArrowStyle
---@return prettymap.luaflet.PolygonTwig
function PathGraphics.arrow(from, to, style)
  local polygon = luaflet.twigs.PolygonTwig.new()
  local weight, level = style.weight or 3, to.level
  local head = style.head or "tip"
  local arm = style.arm_length or (head == "x" and 0.25 or 0.5)

  if style.dashed then
    PathGraphics.dashed_line(polygon, from.x, from.y, to.x, to.y, level, weight, style.colour)
  else
    line(polygon, from.x, from.y, to.x, to.y, level, weight, style.colour)
  end

  if head == "x" then
    line(polygon, to.x - arm, to.y - arm, to.x + arm, to.y + arm, level, weight, style.colour)
    line(polygon, to.x - arm, to.y + arm, to.x + arm, to.y - arm, level, weight, style.colour)
  else
    -- local angle = math.atan2(from.y - to.y, from.x - to.x)
    -- for _, sign in ipairs({ -1, 1 }) do
    --   local a = angle + sign * HEAD_ANGLE
    --   line(polygon, to.x, to.y, to.x + math.cos(a) * arm, to.y + math.sin(a) * arm, level, weight, style.colour)
    -- end
  end

  return polygon
end

--- A cross centred on `at`, `half_size` tiles in each direction.
---@param at TileCoordinates
---@param half_size number
---@param colour integer RGBA colour.
---@param weight number
---@return prettymap.luaflet.PolygonTwig
function PathGraphics.cross(at, half_size, colour, weight)
  local polygon = luaflet.twigs.PolygonTwig.new()
  line(polygon, at.x - half_size, at.y - half_size, at.x + half_size, at.y + half_size, at.level, weight, colour)
  line(polygon, at.x - half_size, at.y + half_size, at.x + half_size, at.y - half_size, at.level, weight, colour)
  return polygon
end

---@param at TileCoordinates
---@param radius number
---@param i integer Corner number, 0 to CIRCLE_SEGMENTS
---@return prettymap.luaflet.Coord
local function circle_point(at, radius, i)
  local angle = i / CIRCLE_SEGMENTS * 2 * math.pi
  return geometry.point(at.x + math.cos(angle) * radius, at.y + math.sin(angle) * radius, at.level)
end

--- A circle outline, approximated by a polygon.
---@param at TileCoordinates
---@param radius number In tiles.
---@param colour integer RGBA colour.
---@param weight number
---@return prettymap.luaflet.PolygonTwig
function PathGraphics.circle(at, radius, colour, weight)
  local polygon = luaflet.twigs.PolygonTwig.new()
  for i = 0, CIRCLE_SEGMENTS - 1 do
    polygon:AddLine(circle_point(at, radius, i), circle_point(at, radius, i + 1), weight, colour)
  end
  return polygon
end

--- A filled circle with an outline, approximated by a polygon.
---@param at TileCoordinates
---@param radius number In tiles.
---@param fill integer RGBA colour.
---@param outline integer RGBA colour.
---@param weight number Outline width in pixels.
---@return prettymap.luaflet.PolygonTwig
function PathGraphics.dot(at, radius, fill, outline, weight)
  local polygon = PathGraphics.circle(at, radius, outline, weight)
  local centre = geometry.point(at.x, at.y, at.level)
  for i = 0, CIRCLE_SEGMENTS - 1 do
    polygon:AddTriangle(centre, circle_point(at, radius, i), circle_point(at, radius, i + 1), fill)
  end
  return polygon
end

return PathGraphics
