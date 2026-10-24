local ObjectEntity = require("cluetrainer/map/elements/ObjectEntity")
local PropertiesTooltip = require("cluetrainer/map/elements/PropertiesTooltip")

--- The object to search for a clue solution, with an explanatory tooltip.
---@class cluetrainer.SearchSolutionEntity : cluetrainer.ObjectEntity
---@field solution Solution.Search
local SearchSolutionEntity = setmetatable({}, { __index = ObjectEntity })
SearchSolutionEntity.__index = SearchSolutionEntity

---@param solution Solution.Search
---@param options cluetrainer.EntityOptions?
---@return cluetrainer.SearchSolutionEntity
function SearchSolutionEntity.new(solution, options)
  local self = setmetatable(ObjectEntity.new(solution.entity, solution.spot, "search", options), SearchSolutionEntity)
  ---@cast self cluetrainer.SearchSolutionEntity
  self.solution = solution

  local tooltip = PropertiesTooltip.new():Header("Search " .. solution.entity .. " to solve the clue")
  if solution.key then
    tooltip:Row("Key", "If you do not have 'way of the footshaped key' unlocked, you will need to get a key.")
    tooltip:Row("Instructions", solution.key.instructions)
    tooltip:Row("Solution", solution.key.answer)
  end
  self.marker:SetTooltip(tooltip)
  return self
end

return SearchSolutionEntity
