---@class prettymap.luaflet.Coord The only coordinate type of luaflet.
--- Integers are tile centres; fractional values lie between them (x.5 is the edge between two tiles).
---@field x number East-west position in tiles.
---@field y number North-south position in tiles.
---@field floor integer? Floor (0-3). Without one, the coordinate is valid on every floor.

local coordinates_helper = {}

---@param x number
---@param y number
---@param floor integer?
---@return prettymap.luaflet.Coord
function coordinates_helper.new(x, y, floor)
    return { x = x, y = y, floor = floor }
end

--- Converts a CoordGrid to the centre of its tile.
---@param grid CoordGrid
---@return prettymap.luaflet.Coord
function coordinates_helper.coord(grid)
    return { x = grid.x, y = grid.z, floor = grid.level }
end

--- Converts a CoordFine (512 fine units per tile) keeping its sub-tile precision.
---@param fine CoordFine
---@return prettymap.luaflet.Coord
function coordinates_helper.coordFine(fine)
    return { x = fine.x / 512 - 0.5, y = fine.z / 512 - 0.5, floor = fine.level }
end

--- Whether both coordinates refer to the same tile on the same floor.
---@param a prettymap.luaflet.Coord
---@param b prettymap.luaflet.Coord
---@return boolean
function coordinates_helper.same_tile(a, b)
    if a.floor ~= b.floor then return false end
    return math.floor(a.x + 0.5) == math.floor(b.x + 0.5) and math.floor(a.y + 0.5) == math.floor(b.y + 0.5)
end

return coordinates_helper
