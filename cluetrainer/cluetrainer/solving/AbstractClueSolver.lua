---An abstract base class for clue solving behaviors for a shared interface and some common functionality.
---@class ct.AbstractClueSolver : zyklib.disposable.IDisposable
---@field clue Step
---@field protected disposable_group zyklib.disposable.DisposableGroup
---@field ended boolean Whether the solver was disposed, also when it stopped on its own
local AbstractClueSolver = {}
AbstractClueSolver.__index = AbstractClueSolver

---@param clue Step
---@return ct.AbstractClueSolver
function AbstractClueSolver.new(clue)
  return setmetatable({
    clue = clue,
    ended = false,
    disposable_group = zyklib.disposable.DisposableGroup.new()
  }, AbstractClueSolver)
end

--- Runs once, so a solver that stopped on its own can be disposed again when the next clue replaces it.
function AbstractClueSolver:dispose()
  if self.ended then return end
  self.ended = true
  self.disposable_group:dispose()
end

return AbstractClueSolver
