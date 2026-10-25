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

return coordinate_adaptor
