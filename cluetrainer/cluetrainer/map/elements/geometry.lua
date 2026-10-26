local coordinate_adaptor = require("cluetrainer/model/shared/coordinate_adaptor")
local luaflet = require("prettymap/luaflet")

--- Conversions from the clue data model (tile coordinates, areas, rectangles) to luaflet coordinates.
local geometry = {}

---@param tile TileCoordinates
---@return CoordGrid
function geometry.grid(tile)
  return coordinate_adaptor.tile_coordinates_to_coord_grid(tile)
end

--- The centre of a tile.
---@param tile TileCoordinates
---@return prettymap.luaflet.Coord
function geometry.coord(tile)
  return luaflet.coord(geometry.grid(tile))
end

--- The south-west corner of a tile.
---@param tile TileCoordinates
---@return prettymap.luaflet.Coord
function geometry.corner(tile)
  return luaflet.coordinates_helper.new(tile.x - 0.5, tile.y - 0.5, tile.level)
end

--- A point given in the clue model's fractional tile space, where integer coordinates are tile centres.
---@param x number
---@param y number
---@param level integer
---@return prettymap.luaflet.Coord
function geometry.point(x, y, level)
  return luaflet.coordinates_helper.new(x, y, level)
end

---@param area TileArea
---@return TileCoordinates origin
---@return TileCoordinates opposite First tile outside the area on both axes.
local function area_extent(area)
  local size = area.size or { x = 1, y = 1 }
  return area.origin, { x = area.origin.x + size.x, y = area.origin.y + size.y, level = area.origin.level }
end

--- Opposite corners spanning every tile of the area. Areas with a tile mask are covered by their bounding box.
---@param area TileArea
---@return prettymap.luaflet.Coord a
---@return prettymap.luaflet.Coord b
function geometry.area_corners(area)
  local origin, opposite = area_extent(area)
  return geometry.corner(origin), geometry.corner(opposite)
end

---@param area TileArea
---@return prettymap.luaflet.Coord
function geometry.area_center(area)
  local size = area.size or { x = 1, y = 1 }
  return geometry.coord({
    x = area.origin.x + math.floor(size.x / 2),
    y = area.origin.y + math.floor(size.y / 2),
    level = area.origin.level,
  })
end

--- Rectangles are inclusive on both corner tiles.
---@param rect TileRectangle
---@return TileCoordinates min
---@return TileCoordinates opposite First tile outside the rectangle on both axes.
local function rect_extent(rect)
  local min_x, max_x = math.min(rect.topleft.x, rect.botright.x), math.max(rect.topleft.x, rect.botright.x)
  local min_y, max_y = math.min(rect.topleft.y, rect.botright.y), math.max(rect.topleft.y, rect.botright.y)
  return { x = min_x, y = min_y, level = rect.level }, { x = max_x + 1, y = max_y + 1, level = rect.level }
end

---@param rect TileRectangle
---@return prettymap.luaflet.Coord a
---@return prettymap.luaflet.Coord b
function geometry.rect_corners(rect)
  local min, opposite = rect_extent(rect)
  return geometry.corner(min), geometry.corner(opposite)
end

---@param rect TileRectangle
---@return prettymap.luaflet.Coord
function geometry.rect_center(rect)
  local min, opposite = rect_extent(rect)
  return geometry.coord({
    x = math.floor((min.x + opposite.x - 1) / 2),
    y = math.floor((min.y + opposite.y - 1) / 2),
    level = rect.level,
  })
end

return geometry
