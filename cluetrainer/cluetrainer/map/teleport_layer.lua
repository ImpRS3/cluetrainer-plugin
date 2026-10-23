local teleports = require("cluetrainer/data/teleports")
local coordinate_adaptor = require("cluetrainer/model_shared/coordinate_adaptor")

local TeleportLayer = {}
TeleportLayer.__index = {}

---@param map ct.GameMap
function TeleportLayer.new(map)
  local self = setmetatable({}, TeleportLayer)

  for _, teleport in ipairs(teleports) do
    -- Initialize teleport on the map

    for _, spot in ipairs(teleport.spots) do
      -- Initialize each spot on the map
      local sprite_id = (spot.cache_data and spot.cache_data.sprite) or
      (teleport.cache_data and teleport.cache_data.sprite)
      if sprite_id then
        -- Use sprite_id to initialize the spot on the map
        map.map.overlays:CreateSprite({
          coordinate = coordinate_adaptor.tile_coordinates_to_coord_grid(spot.target.origin),
          sprite = id.Sprite[sprite_id],
          width = 28,
          height = 28
        })
      end
    end
  end

  return self
end

return TeleportLayer
