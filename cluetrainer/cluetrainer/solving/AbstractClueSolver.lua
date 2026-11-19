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

---Builds a solver of the given class: the base object, then `Class.init(self, clue, ...)`. Should `init` fail, the
---solver is disposed before the error is raised again, so a solver that fails halfway leaves no highlights, map
---elements or event handlers behind. Every solver's `dispose` copes with the parts `init` did not get to.
---@param Class { init: fun(self: any, clue: Step, ...) } The solver class
---@param clue Step
---@param ... any Passed on to `init`
---@return any
function AbstractClueSolver.create(Class, clue, ...)
  local self = setmetatable(AbstractClueSolver.new(clue), Class)

  local ok, err = pcall(Class.init, self, clue, ...)
  if not ok then
    -- Protected as well, so a failing cleanup doesn't replace the original error.
    pcall(self.dispose, self)
    error(err, 0)
  end

  return self
end

--- Runs once, so a solver that stopped on its own can be disposed again when the next clue replaces it.
function AbstractClueSolver:dispose()
  if self.ended then return end
  self.ended = true
  self.disposable_group:dispose()
end

return AbstractClueSolver
