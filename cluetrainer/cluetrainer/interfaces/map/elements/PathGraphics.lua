local luaflet = require("prettymap/luaflet")
local geometry = require("cluetrainer/interfaces/map/elements/geometry")

--- Arrows, nd marks for rendering paths, as polygon elements.
--- Points are tile coordinates; integer coordinates are tile centres.
local PathGraphics = {}

local DASH_LENGTH = 0.25 -- tiles
local HEAD_ANGLE = math.rad(30)

---@class cluetrainer.ArrowStyle
---@field colour integer RGBA colour.
---@field weight number? Stroke width in pixels. Default 3.
---@field dashed boolean?
---@field head ("tip"|"x")? Default "tip".
---@field arm_length number? Length of the head's arms in tiles. Default 0.5 for "tip", 0.25 for "x".

---@param rgb integer
---@param opacity number
---@return integer rgba
function PathGraphics.rgba(rgb, opacity)
  return rgb * 256 + math.floor(opacity * 255 + 0.5)
end

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

---@param polygon prettymap.luaflet.PolygonTwig
---@param ax number
---@param ay number
---@param bx number
---@param by number
---@param level integer
---@param weight number
---@param colour integer
local function dashed_line(polygon, ax, ay, bx, by, level, weight, colour)
  local dx, dy = bx - ax, by - ay
  local length = math.sqrt(dx * dx + dy * dy)
  local segments = math.max(1, math.floor(length / DASH_LENGTH / 2))
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
    dashed_line(polygon, from.x, from.y, to.x, to.y, level, weight, style.colour)
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

--- A circle outline, approximated by a polygon.
---@param at TileCoordinates
---@param radius number In tiles.
---@param colour integer RGBA colour.
---@param weight number
---@return prettymap.luaflet.PolygonTwig
function PathGraphics.circle(at, radius, colour, weight)
  local polygon = luaflet.twigs.PolygonTwig.new()
  local segments = 12
  for i = 0, segments - 1 do
    local a0, a1 = i / segments * 2 * math.pi, (i + 1) / segments * 2 * math.pi
    line(polygon,
      at.x + math.cos(a0) * radius, at.y + math.sin(a0) * radius,
      at.x + math.cos(a1) * radius, at.y + math.sin(a1) * radius,
      at.level, weight, colour)
  end
  return polygon
end

return PathGraphics
