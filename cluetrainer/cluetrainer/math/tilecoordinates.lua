-- tilecoordinates.lua
-- Tile comparisons and distances. A missing level counts as the ground floor.
---@alias floor_t 0|1|2|3

---@class TileCoordinates : ct.lib.math.Vector2
---@field level floor_t

local tilecoordinates = {}

---@param tile TileCoordinates
---@return CoordGrid
function tilecoordinates.toCoordGrid(tile)
  return CoordGrid.new(
    tile.level,
    math.floor(tile.x / 64),
    math.floor(tile.y / 64),
    tile.x % 64,
    tile.y % 64
  )
end

---@param coord_grid CoordGrid
---@return TileCoordinates
function tilecoordinates.fromCoordGrid(coord_grid)
  return {
    level = coord_grid.level,
    x = coord_grid.x,
    y = coord_grid.z
  }
end

--- The tile the local player stands on, nil while there is no player.
---@return TileCoordinates?
function tilecoordinates.player()
  local player = PlayerList.Self()
  return player and tilecoordinates.fromCoordGrid(player.coordGrid)
end

---@param a TileCoordinates
---@param b TileCoordinates
---@return boolean
function tilecoordinates.same(a, b)
  return a.x == b.x and a.y == b.y and (a.level or 0) == (b.level or 0)
end

--- A string that identifies the tile, to use as a table key.
---@param tile TileCoordinates
---@return string
function tilecoordinates.key(tile)
  return tile.x .. "," .. tile.y .. "," .. (tile.level or 0)
end

--- The distance in tiles as the game counts it: the larger of the x and y distance. Ignores the level.
---@param a TileCoordinates
---@param b TileCoordinates
---@return integer
function tilecoordinates.distance(a, b)
  return math.max(math.abs(a.x - b.x), math.abs(a.y - b.y))
end

return tilecoordinates
