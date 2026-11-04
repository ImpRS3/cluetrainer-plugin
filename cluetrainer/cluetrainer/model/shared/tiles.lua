-- tiles.lua
-- Tile comparisons and distances. A missing level counts as the ground floor.
local tiles = {}

---@param a TileCoordinates
---@param b TileCoordinates
---@return boolean
function tiles.same(a, b)
  return a.x == b.x and a.y == b.y and (a.level or 0) == (b.level or 0)
end

--- A string that identifies the tile, to use as a table key.
---@param tile TileCoordinates
---@return string
function tiles.key(tile)
  return tile.x .. "," .. tile.y .. "," .. (tile.level or 0)
end

--- The distance in tiles as the game counts it: the larger of the x and y distance. Ignores the level.
---@param a TileCoordinates
---@param b TileCoordinates
---@return integer
function tiles.distance(a, b)
  return math.max(math.abs(a.x - b.x), math.abs(a.y - b.y))
end

return tiles
