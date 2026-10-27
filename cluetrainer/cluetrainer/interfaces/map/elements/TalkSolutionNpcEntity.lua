local NpcEntity = require("cluetrainer/interfaces/map/elements/NpcEntity")
local PropertiesTooltip = require("cluetrainer/interfaces/map/elements/PropertiesTooltip")

--- The NPC to talk to for a clue solution, with an explanatory tooltip.
---@class cluetrainer.TalkSolutionNpcEntity : cluetrainer.NpcEntity
local TalkSolutionNpcEntity = setmetatable({}, { __index = NpcEntity })
TalkSolutionNpcEntity.__index = TalkSolutionNpcEntity

---@param name string
---@param spot Solution.TalkToSpot
---@return cluetrainer.TalkSolutionNpcEntity
function TalkSolutionNpcEntity.new(name, spot)
  local self = setmetatable(NpcEntity.new(name, spot.range), TalkSolutionNpcEntity)
  ---@cast self cluetrainer.TalkSolutionNpcEntity

  local tooltip = PropertiesTooltip.new():Header("Talk to " .. name .. " to solve the clue")
  if spot.note then tooltip:Row("Note", spot.note) end
  self.marker:SetTooltip(tooltip)
  return self
end

return TalkSolutionNpcEntity
