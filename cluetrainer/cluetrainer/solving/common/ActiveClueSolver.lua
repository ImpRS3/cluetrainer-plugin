---@class ct.ActiveClueSolver : zyklib.disposable.IDisposable
---@field clue Step
---@field protected disposable_group zyklib.disposable.DisposableGroup
---@field ended boolean Whether the solver was disposed, also when it stopped on its own
local ActiveClueSolver = {}
ActiveClueSolver.__index = ActiveClueSolver

---@param clue Step
---@return ct.ActiveClueSolver
function ActiveClueSolver.new(clue)
  return setmetatable({
    clue = clue,
    ended = false,
    disposable_group = zyklib.disposable.DisposableGroup.new()
  }, ActiveClueSolver)
end

--- Runs once, so a solver that stopped on its own can be disposed again when the next clue replaces it.
function ActiveClueSolver:dispose()
  if self.ended then return end
  self.ended = true
  self.disposable_group:dispose()
end

--- Stops the solver once its clue is done or gone, and empties the clue state window to "No clue". The solver stays
--- until the next clue replaces it.
---@param clue_state ct.ClueStateInterface
function ActiveClueSolver:finish(clue_state)
  self:dispose()
  clue_state:clearActions()
  clue_state:setClue(nil)
end

return ActiveClueSolver
