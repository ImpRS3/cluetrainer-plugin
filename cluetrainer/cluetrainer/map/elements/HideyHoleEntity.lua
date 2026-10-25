local ObjectEntity = require("cluetrainer/map/elements/ObjectEntity")
local PropertiesTooltip = require("cluetrainer/map/elements/PropertiesTooltip")

--- The hidey-hole of an emote clue. The tooltip needs the equip marker, so pass `with_cursor` to see it.
---@class cluetrainer.HideyHoleEntity : cluetrainer.ObjectEntity
local HideyHoleEntity = setmetatable({}, { __index = ObjectEntity })
HideyHoleEntity.__index = HideyHoleEntity

---@param clue Emote Must have a hidey-hole.
---@param with_cursor boolean? Show the equip marker.
---@return cluetrainer.HideyHoleEntity
function HideyHoleEntity.new(clue, with_cursor)
  local hole = assert(clue.hidey_hole, "the emote clue has no hidey-hole")
  ---@class cluetrainer.HideyHoleEntity
  local self = setmetatable(ObjectEntity.new(hole.name, hole.location, nil),
    HideyHoleEntity)

  if self.marker then
    self.marker:SetTooltip(PropertiesTooltip.new()
      :Header(hole.name)
      :Paragraph("Hidey-holes are used to store the items needed for an emote clue."))
  end
  return self
end

return HideyHoleEntity
