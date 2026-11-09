local luaflet = require("prettymap/luaflet")
local PathGraphics = require("cluetrainer/map/elements/PathGraphics")
local colours = require("cluetrainer/util/colours")
local tiles = require("cluetrainer/math/math").tilecoordinates

local FILL = 0xFFFFFF
local OUTLINE = 0x000000
local RADIUS = 1 -- tiles
local OUTLINE_WEIGHT = 1 -- pixels

--- The player's tile as a white dot, with an outline so it shows on light and dark map parts.
---@class ct.PlayerMarker : prettymap.luaflet.Twig
---@field private tile TileCoordinates?
---@field private dot prettymap.luaflet.PolygonTwig?
local PlayerMarker = setmetatable({}, { __index = luaflet.twigs.Twig })
PlayerMarker.__index = PlayerMarker

---@return ct.PlayerMarker
function PlayerMarker.new()
  local self = setmetatable(luaflet.twigs.Twig.new(), PlayerMarker)
  ---@cast self ct.PlayerMarker
  return self
end

--- Moves the dot to the tile. Draws it anew, so it lies on top of what was added to the map since.
---@param tile TileCoordinates?
function PlayerMarker:setTile(tile)
  if tile == nil or (self.tile and tiles.same(self.tile, tile)) then return end
  self.tile = tile

  if self.dot then self.dot:Detach() end
  self.dot = PathGraphics.dot(tile, RADIUS, colours.rgba(FILL, 1), colours.rgba(OUTLINE, 1), OUTLINE_WEIGHT)
  self:Add(self.dot)
end

return PlayerMarker
