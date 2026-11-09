---@class ct.lib.math.Rectangle
---@field topleft ct.lib.math.Vector2
---@field botright ct.lib.math.Vector2

---@class TileRectangle : ct.lib.math.Rectangle
---@field level floor_t

local rectangle = {}

---@param rect ct.lib.math.Rectangle
---@param point ct.lib.math.Vector2
---@return boolean
function rectangle.contains(rect, point)
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
function rectangle.rayExit(rect, origin, direction)
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

return rectangle
