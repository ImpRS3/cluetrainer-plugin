---@class ct.ActiveClueSolver : zyklib.disposable.IDisposable
---@field clue Step
---@field protected disposable_group zyklib.disposable.DisposableGroup
local ActiveClueSolver = {}
ActiveClueSolver.__index = ActiveClueSolver

---@param clue Step
---@return ct.ActiveClueSolver
function ActiveClueSolver.new(clue)
  return setmetatable({
    clue = clue,
    disposable_group = zyklib.disposable.DisposableGroup.new()
  }, ActiveClueSolver)
end

function ActiveClueSolver:dispose()
  self.disposable_group:dispose()
end

return ActiveClueSolver
