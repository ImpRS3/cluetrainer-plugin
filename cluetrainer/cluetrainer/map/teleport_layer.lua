local teleports = require("cluetrainer/data/teleports")
local elements = require("prettymap/elements")
local TeleportElement = require("cluetrainer/map/elements/TeleportElement")

--- A coordinate-less element without a visual: it only owns the teleport spot elements.
---@class cluetrainer.TeleportLayer: prettymap.Element
local TeleportLayer = setmetatable({}, { __index = elements.Element })
TeleportLayer.__index = TeleportLayer

---@return cluetrainer.TeleportLayer
function TeleportLayer.new()
  local self = setmetatable(elements.Element.new(), TeleportLayer)

  for _, teleport in ipairs(teleports) do
    for _, spot in ipairs(teleport.spots) do
      self:Add(TeleportElement.new(teleport, spot))
    end
  end

  return self
end

return TeleportLayer
