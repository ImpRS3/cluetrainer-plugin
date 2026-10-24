local NpcEntity = require("cluetrainer/map/elements/NpcEntity")
local PropertiesTooltip = require("cluetrainer/map/elements/PropertiesTooltip")

--- The NPC to talk to for a clue solution, with an explanatory tooltip.
---@class cluetrainer.TalkSolutionNpcEntity : cluetrainer.NpcEntity
---@field spot Solution.TalkToSpot
local TalkSolutionNpcEntity = setmetatable({}, { __index = NpcEntity })
TalkSolutionNpcEntity.__index = TalkSolutionNpcEntity

---@param name string
---@param spot Solution.TalkToSpot
---@param options cluetrainer.EntityOptions?
---@return cluetrainer.TalkSolutionNpcEntity
function TalkSolutionNpcEntity.new(name, spot, options)
  local self = setmetatable(NpcEntity.new(name, spot.range, options), TalkSolutionNpcEntity)
  ---@cast self cluetrainer.TalkSolutionNpcEntity
  self.spot = spot

  local tooltip = PropertiesTooltip.new():Header("Talk to " .. name .. " to solve the clue")
  if spot.note then tooltip:Row("Note", spot.note) end
  self.marker:SetTooltip(tooltip)
  return self
end

return TalkSolutionNpcEntity
