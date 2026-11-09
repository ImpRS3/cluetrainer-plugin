---@class ct.lib.math.Vector2
---@field x number
---@field y number

---@class ct.lib.math.Vector2.module
local vector2 = {}

function vector2.det(a, b)
  return a.x * b.y - a.y * b.x
end

function vector2.dot(a, b)
  return a.x * b.x + a.y * b.y
end

---@param ... ct.lib.math.Vector2
---@return ct.lib.math.Vector2
function vector2.add(...)
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
function vector2.scale(factor, vector)
  return { x = vector.x * factor, y = vector.y * factor }
end

return vector2
