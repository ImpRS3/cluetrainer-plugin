-- TileArea.lua
local base64 = require "zyklib/base64"

---@class TileArea
---@field origin TileCoordinates
---@field size MyVector2?
---@field data string?

---@class TileArea.module
local TileArea = {}

---@class TileArea.Active : TileArea
---@field mutable_data string
local ActiveTileArea = {}
ActiveTileArea.__index = ActiveTileArea

---@param origin TileCoordinates
---@param size MyVector2
---@return TileArea
function TileArea.centered_on(origin, size)
  local half_size = { x = math.floor(size.x / 2), y = math.floor(size.y / 2) }
  return {
    origin = { x = origin.x - half_size.x, y = origin.y - half_size.y, level = origin.level },
    size = size
  }
end

function TileArea.tile(origin)
  return {
    origin = origin
  }
end

---@param self TileArea
---@return ct.Rectangle
function TileArea.toRect(self)
  local origin = self.origin
  local size = self.size or { x = 1, y = 1 }
  return {
    topleft = { x = origin.x, y = origin.y },
    botright = { x = origin.x + size.x - 1, y = origin.y + size.y - 1 },
    level = origin.level
  }
end

---@param tile_area TileArea
---@return TileArea.Active
function TileArea.ensure_mutable(tile_area)
  if getmetatable(tile_area) == nil then
    setmetatable(tile_area, ActiveTileArea)
    ---@cast tile_area TileArea.Active

    if tile_area.data ~= nil then
      tile_area.mutable_data = base64.decode(tile_area.data)
    end
  end

  return tile_area --[[@as TileArea.Active]]
end

---@return TileCoordinates
function ActiveTileArea:center(tile_area)
  local sz = TileArea.ensure_mutable(tile_area):getSize()
  local origin = tile_area.origin
  return {
    x = origin.x + math.floor(sz.x / 2),
    y = origin.y + math.floor(sz.y / 2),
    level = origin.level
  }
end

---Queries whether a given coordinate is within the area
---@param coord TileCoordinates
---@return boolean
function ActiveTileArea:query(coord)
  local sz = self:getSize()
  local origin = self.origin

  if coord.x < origin.x
      or coord.y < origin.y
      or coord.x >= origin.x + sz.x
      or coord.y >= origin.y + sz.y
  then
    return false
  end

  if self.mutable_data ~= nil then
    local index = self:index(coord)
    local element = math.floor(index / 8) + 1
    local shift = index % 8

    local byte = string.byte(self.mutable_data, element)

    return ((byte >> shift) & 1) ~= 0
  end

  return true
end

---@param coord TileCoordinates
---@return integer
function ActiveTileArea:index(coord)
  local offX = coord.x - self.origin.x
  local offY = coord.y - self.origin.y

  -- Assumes the input is valid and within bounds!
  return offX + offY * self.size.x
end

---@return MyVector2
function ActiveTileArea:getSize()
  if self.size == nil then
    return { x = 1, y = 1 }
  else
    return self.size
  end
end

return TileArea
