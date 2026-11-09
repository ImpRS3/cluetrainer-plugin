---@class ct.lib.math.angles
local angles = {}

---@param angle number Angle in radians
---@return number
function angles.radiansToDegrees(angle)
  return angle * (180 / math.pi)
end

---@param angle_degrees number
---@return number Angle in radians
function angles.degreesToRadians(angle_degrees)
  return angle_degrees * (math.pi / 180)
end

---Signed shortest difference from angle a to angle b in radians, in the range [-pi, pi).
---@param a number
---@param b number
---@return number
function angles.angleDifferenceSigned(a, b)
  return ((b - a + math.pi) % (2 * math.pi)) - math.pi
end

---Absolute shortest difference between two angles in radians.
---@param a number
---@param b number
---@return number
function angles.angleDifference(a, b)
  return math.abs(angles.angleDifferenceSigned(a, b))
end

function angles.normalize(radians)
  return (radians % (2 * math.pi))
end

return angles
