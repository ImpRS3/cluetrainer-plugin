local elements = require("prettymap/elements")
local geometry = require("cluetrainer/map/elements/geometry")
local InteractionMarker = require("cluetrainer/map/elements/InteractionMarker")

--- An NPC with a roaming range: a talk marker in the centre of the range.
---@class cluetrainer.NpcEntity : prettymap.Element
---@field marker cluetrainer.InteractionMarker
local NpcEntity = setmetatable({}, { __index = elements.Element })
NpcEntity.__index = NpcEntity

---@param name string
---@param range TileArea
---@return cluetrainer.NpcEntity
function NpcEntity.new(name, range)
  local self = setmetatable(elements.Element.new(), NpcEntity)
  ---@cast self cluetrainer.NpcEntity

  self.marker = InteractionMarker.new({
    coordinate = geometry.area_center(range),
    cursor = "talk",
  })
  self:Add(self.marker)
  return self
end

return NpcEntity
