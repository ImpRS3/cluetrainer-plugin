local teleports = require("cluetrainer/data/teleports")
local TeleportSpot = require("cluetrainer/model/shared/TeleportSpot")
local luaflet = require("prettymap/luaflet")
local TeleportElement = require("cluetrainer/map/elements/TeleportElement")

--- A coordinate-less element without a visual: it only owns the teleport spot elements.
---@class cluetrainer.TeleportLayer: prettymap.luaflet.Twig
local TeleportLayer = setmetatable({}, { __index = luaflet.twigs.Twig })
TeleportLayer.__index = TeleportLayer

---@return cluetrainer.TeleportLayer
function TeleportLayer.new()
  ---@class cluetrainer.TeleportLayer
  local self = setmetatable(luaflet.twigs.Twig.new(), TeleportLayer)

  for _, teleport in ipairs(teleports) do
    for _, spot in ipairs(teleport.spots) do
      self:Add(TeleportElement.new(TeleportSpot.new(teleport, spot)))
    end
  end

  return self
end

return TeleportLayer
