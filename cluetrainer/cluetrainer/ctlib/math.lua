---@class ct.lib.math
local ctmath = {}

-- Rounds a number to the nearest integer.
---@param number number
---@return integer
function ctmath.round(number)
  return math.floor(number + 0.5)
end

---@class ct.lib.math.angles
ctmath.angles = {}

---@param angle number Angle in radians
---@return number
function ctmath.angles.radiansToDegrees(angle)
  return angle * (180 / math.pi)
end

---@param angle_degrees number
---@return number Angle in radians
function ctmath.angles.degreesToRadians(angle_degrees)
  return angle_degrees * (math.pi / 180)
end

---Signed shortest difference from angle a to angle b in radians, in the range [-pi, pi).
---@param a number
---@param b number
---@return number
function ctmath.angles.angleDifferenceSigned(a, b)
  return ((b - a + math.pi) % (2 * math.pi)) - math.pi
end

---Absolute shortest difference between two angles in radians.
---@param a number
---@param b number
---@return number
function ctmath.angles.angleDifference(a, b)
  return math.abs(ctmath.angles.angleDifferenceSigned(a, b))
end

function ctmath.angles.normalize(radians)
  return (radians % (2 * math.pi))
end

---@class ct.lib.math.Vector2
---@field x number
---@field y number

---@class ct.lib.math.Vector2.module
ctmath.vector2 = {}

function ctmath.vector2.det(a, b)
  return a.x * b.y - a.y * b.x
end

function ctmath.vector2.dot(a, b)
  return a.x * b.x + a.y * b.y
end

---@param ... ct.lib.math.Vector2
---@return ct.lib.math.Vector2
function ctmath.vector2.add(...)
  local x, y = 0, 0
  for _, v in ipairs({ ... }) do
    x = x + v.x
    y = y + v.y
  end
  return { x = x, y = y }
end

---@param factor number
---@param vector ct.lib.math.Vector2
---@return ct.lib.math.Vector2
function ctmath.vector2.scale(factor, vector)
  return { x = vector.x * factor, y = vector.y * factor }
end

---@class ct.lib.math.Rectangle
---@field topleft ct.lib.math.Vector2
---@field botright ct.lib.math.Vector2

ctmath.rectangle = {}

---@param rect ct.lib.math.Rectangle
---@param point ct.lib.math.Vector2
---@return boolean
function ctmath.rectangle.contains(rect, point)
  return rect.topleft.x <= point.x
      and rect.topleft.y >= point.y
      and rect.botright.x >= point.x
      and rect.botright.y <= point.y
end

--- Distance along a ray from `origin` to where it leaves the rectangle. Tiles are centred on integers, so the
--- rectangle extends half a tile beyond its bounding tiles.
---@param rect ct.lib.math.Rectangle
---@param origin ct.lib.math.Vector2
---@param direction ct.lib.math.Vector2 Unit vector.
---@return number # 0 if the ray starts outside and points away.
function ctmath.rectangle.rayExit(rect, origin, direction)
  local t = math.huge

  local function axis(o, d, min, max)
    if d > 0 then
      t = math.min(t, (max - o) / d)
    elseif d < 0 then
      t = math.min(t, (min - o) / d)
    end
  end

  axis(origin.x, direction.x, rect.topleft.x - 0.5, rect.botright.x + 0.5)
  axis(origin.y, direction.y, rect.botright.y - 0.5, rect.topleft.y + 0.5)

  return math.max(0, t)
end

return ctmath
