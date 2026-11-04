-- coordinate_adaptor.lua
local coordinate_adaptor = {}

---@param tile_coordinates TileCoordinates
---@return CoordGrid
function coordinate_adaptor.tile_coordinates_to_coord_grid(tile_coordinates)
  return CoordGrid.new(
    tile_coordinates.level,
    math.floor(tile_coordinates.x / 64),
    math.floor(tile_coordinates.y / 64),
    tile_coordinates.x % 64,
    tile_coordinates.y % 64
  )
end

---@param coord_grid CoordGrid
---@return TileCoordinates
function coordinate_adaptor.coord_grid_to_tile_coordinates(coord_grid)
  return {
    level = coord_grid.level,
    x = coord_grid.x,
    y = coord_grid.z
  }
end

--- The tile the local player stands on, nil while there is no player.
---@return TileCoordinates?
function coordinate_adaptor.playerTile()
  local player = PlayerList.Self()
  return player and coordinate_adaptor.coord_grid_to_tile_coordinates(player.coordGrid)
end

return coordinate_adaptor
