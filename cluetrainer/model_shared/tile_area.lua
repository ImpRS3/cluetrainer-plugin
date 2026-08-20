local base64 = require "zyklib/base64"
---@class TileArea
---@field origin TileCoordinates
---@field size MyVector2
---@field data string


local TileArea = {}

---@class TileArea.Active : TileArea
---@field mutable_data string
TileArea.Active = {}
TileArea.Active.__index = TileArea.Active

---@param tile_area TileArea
---@return TileArea.Active
function TileArea.ensure_mutable(tile_area)
  if getmetatable(tile_area) == nil then
    setmetatable(tile_area, TileArea.Active)

    tile_area.mutable_data = base64.decode(tile_area.data)
  end

  return tile_area
end

---Queries whether a given coordinate is within the area
---@param coord TileCoordinates
---@return boolean
function TileArea.Active:query(coord)
    local sz = self.size
    local origin = self.origin

    if coord.x < origin.x
        or coord.y < origin.y
        or coord.x >= origin.x + sz.x
        or coord.y >= origin.y + sz.y
    then
        return false
    end

    local index = self:index(coord)
    local element = math.floor(index / 8) + 1
    local shift = index % 8
    
    local byte = string.byte(self.mutable_data, element)

    return ((byte >> shift) & 1) ~= 0
end

---@param coord TileCoordinates
---@return integer
function TileArea.Active:index(coord)
  local offX = coord.x - self.origin.x
  local offY = coord.y - self.origin.y

  -- Assumes the input is valid and within bounds!
  return offX + offY * self.size.x
end

return TileArea
