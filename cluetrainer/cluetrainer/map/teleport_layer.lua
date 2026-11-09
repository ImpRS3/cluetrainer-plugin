local teleports = require("cluetrainer/data/teleports")
local TeleportSpot = require("cluetrainer/model/TeleportSpot")
local luaflet = require("prettymap/luaflet")
local TeleportElement = require("cluetrainer/map/elements/TeleportElement")
local TeleportCustomization = require("cluetrainer/solving/common/TeleportCustomization")

--- A coordinate-less element without a visual: it only owns the teleport spot elements.
---@class cluetrainer.TeleportLayer: prettymap.luaflet.Twig
---@field private customization_handler zyklib.reactive.EventHandler?
local TeleportLayer = setmetatable({}, { __index = luaflet.twigs.Twig })
TeleportLayer.__index = TeleportLayer

function TeleportLayer:_refresh()
  local children = {}
  for _, child in ipairs(self.children) do children[#children + 1] = child end
  for _, child in ipairs(children) do self:Remove(child) end

  for _, teleport in ipairs(teleports) do
    for _, spot in ipairs(teleport.spots) do
      self:Add(TeleportElement.new(TeleportSpot.new(teleport, spot)))
    end
  end
end

---@return cluetrainer.TeleportLayer
function TeleportLayer.new()
  ---@class cluetrainer.TeleportLayer
  local self = setmetatable(luaflet.twigs.Twig.new(), TeleportLayer)

  self.customization_handler = TeleportCustomization.changed:subscribe(function()
    self:_refresh()
  end)
  self:_refresh()

  return self
end

function TeleportLayer:dispose()
  if self.customization_handler then
    self.customization_handler:cancel()
    self.customization_handler = nil
  end
  self:Detach()
end

return TeleportLayer
