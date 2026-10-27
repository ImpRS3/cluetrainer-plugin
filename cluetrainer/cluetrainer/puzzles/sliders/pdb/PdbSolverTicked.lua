local SliderState = require "cluetrainer/puzzles/sliders/SliderState"

local move_translation_identity = {
  [21 - 20] = -20,
  [21 - 15] = -15,
  [21 - 10] = -10,
  [21 - 5] = -5,
  [21 - 4] = -4,
  [21 - 3] = -3,
  [21 - 2] = -2,
  [21 - 1] = -1,
  [21 - 0] = 0,
  [21 + 1] = 1,
  [21 + 2] = 2,
  [21 + 3] = 3,
  [21 + 4] = 4,
  [21 + 5] = 5,
  [21 + 10] = 10,
  [21 + 15] = 15,
  [21 + 20] = 20,
}

--- Number of state expansions per call of `tick` unless specified otherwise.
local DEFAULT_BUDGET = 2048

---@alias ct.sliders.pdb.Frame ct.sliders.pdb.RootFrame | ct.sliders.pdb.RegionFrame | ct.sliders.pdb.StateFrame

---@class ct.sliders.pdb.RootFrame
---@field kind "root"
---@field entry_points ct.sliders.pdb.RegionGraph.Node[]
---@field index integer

---@class ct.sliders.pdb.RegionFrame
---@field kind "region"
---@field phase "enter" | "exit"
---@field region ct.sliders.pdb.RegionGraph.Node
---@field coming_from_reflected boolean
---@field needs_reflection boolean?

---@class ct.sliders.pdb.StateFrame
---@field kind "state"
---@field phase "enter" | "moves" | "end" | "children"
---@field region ct.sliders.pdb.RegionGraph.Node
---@field known_distance integer
---@field previous_move integer?
---@field moves integer[]?
---@field i integer Index of the move being tried.
---@field move integer? The move currently applied to the state.
---@field awaiting_child boolean Whether a child state frame is running for `move`.
---@field found boolean Whether an optimal move was found.
---@field child_i integer Index of the child region being visited.

--- The pattern database solver without coroutines. It has the interface of `PdbSolver`
--- (`start_state`, `best_solution`, `registerSolution`), but instead of being run as a task, `tick` has to be called
--- repeatedly until it returns true. The recursion of `PdbSolver` is replaced by an explicit stack of frames, so
--- every call of `tick` continues exactly where the previous one stopped.
---@class ct.sliders.pdb.PdbSolverTicked
---@field start_state ct.sliders.SliderState
---@field chain ct.sliders.pdb.RegionGraph
---@field best_solution integer[]?
---@field private stack ct.sliders.pdb.Frame[]
---@field private state ct.sliders.SliderState
---@field private move_list integer[]
---@field private budget integer
---@field private finished boolean
---@field private tick_handler zyklib.disposable.IDisposable?
---@field private started boolean
local PdbSolverTicked = {}
PdbSolverTicked.__index = PdbSolverTicked

---@param start_state ct.sliders.SliderState
---@param chain ct.sliders.pdb.RegionGraph
---@return ct.sliders.pdb.PdbSolverTicked
function PdbSolverTicked.new(start_state, chain)
  ---@class ct.sliders.pdb.PdbSolverTicked
  local self = setmetatable({}, PdbSolverTicked)

  self.start_state = start_state
  self.chain = chain
  self.move_list = {}
  self.budget = 0
  self.finished = false
  self.started = false
  self.stack = {}

  return self
end

--- Prepares the search. Has to be called once before `tick`; calling it again has no effect.
function PdbSolverTicked:start()
  if self.started or self.finished then return end

  self.started = true
  self.stack = { { kind = "root", entry_points = self.chain:getEntryPoints(), index = 0 } }
end

---@protected
---@param solution integer[]
function PdbSolverTicked:registerSolution(solution)
  log("Found solution")
  log(solution)

  if self.best_solution == nil or #solution < #self.best_solution then
    self.best_solution = { table.unpack(solution) }
  end
end

---@return boolean
function PdbSolverTicked:isDone()
  return self.finished
end

--- Abandons the search. `best_solution` keeps what was found so far.
function PdbSolverTicked:cancel()
  self.stack = {}
  self.state = nil
  self.move_list = {}
  self.finished = true
end

function PdbSolverTicked:dispose()
  self:cancel()
  if self.tick_handler then
    self.tick_handler:dispose()
    self.tick_handler = nil
  end
end

---@private
---@param region ct.sliders.pdb.RegionGraph.Node
---@param known_distance integer
function PdbSolverTicked:pushState(region, known_distance)
  self.stack[#self.stack + 1] = {
    kind = "state",
    phase = "enter",
    region = region,
    known_distance = known_distance,
    i = 0,
    awaiting_child = false,
    found = false,
    child_i = 0,
  }
end

---@private
---@param region ct.sliders.pdb.RegionGraph.Node
---@param coming_from_reflected boolean
function PdbSolverTicked:pushRegion(region, coming_from_reflected)
  self.stack[#self.stack + 1] = {
    kind = "region",
    phase = "enter",
    region = region,
    coming_from_reflected = coming_from_reflected,
  }
end

---@private
function PdbSolverTicked:pop()
  self.stack[#self.stack] = nil
end

---@private
---@param frame ct.sliders.pdb.RootFrame
function PdbSolverTicked:stepRoot(frame)
  frame.index = frame.index + 1
  local start = frame.entry_points[frame.index]

  if start == nil then
    self:pop()
    return
  end

  self.state = SliderState.fromPermutation(self.start_state)
  self.move_list = {}

  log("Starting with entry point")

  self:pushRegion(start, false)
end

---@private
---@param frame ct.sliders.pdb.RegionFrame
function PdbSolverTicked:stepRegion(frame)
  local region = frame.region

  if frame.phase == "enter" then
    frame.needs_reflection = region.reflected ~= frame.coming_from_reflected
    if frame.needs_reflection then SliderState.reflect(self.state) end

    local index = region.table.indexing:stateIndex(self.state)

    frame.phase = "exit"
    self:pushState(region, region.table:getDistanceByIndex(index))
  else
    if frame.needs_reflection then SliderState.reflect(self.state) end
    self:pop()
  end
end

--- Undoes the move that is currently applied and decides whether more moves need to be tried.
---@private
---@param frame ct.sliders.pdb.StateFrame
function PdbSolverTicked:finishMove(frame)
  SliderState.doMove(self.state, -frame.move)
  self.state[SliderState.LAST_MOVE_INDEX] = frame.previous_move
  frame.move = nil

  if frame.found and frame.region.table.indexing.solves_puzzle then
    frame.i = #frame.moves
  end
end

---@private
---@param frame ct.sliders.pdb.StateFrame
function PdbSolverTicked:stepState(frame)
  local state = self.state
  local region = frame.region
  local distance_table = region.table
  local indexing = distance_table.indexing

  if frame.phase == "enter" then
    self.budget = self.budget - 1
    frame.previous_move = state[SliderState.LAST_MOVE_INDEX]

    if self.best_solution and #self.move_list > #self.best_solution then
      self:pop()
      return
    end

    frame.moves = distance_table.move_table:get(state)
    frame.phase = "moves"
  elseif frame.phase == "moves" then
    if frame.awaiting_child then
      frame.awaiting_child = false
      self.move_list[#self.move_list] = nil
      self:finishMove(frame)
      return
    end

    frame.i = frame.i + 1
    local move = frame.moves[frame.i]

    if move == nil then
      frame.phase = "end"
      return
    end

    local move_translation = region.reflected
        and SliderState.move_translation_reflect
        or move_translation_identity

    frame.move = move
    SliderState.doMove(state, move)

    local child_index = indexing:stateIndex(state)
    local child_distance = distance_table:getDistanceByIndex(child_index)

    if (child_distance + 1) % 4 == frame.known_distance then
      frame.found = true
      frame.awaiting_child = true
      self.move_list[#self.move_list + 1] = move_translation[move + 21]
      self:pushState(region, child_distance)
    else
      self:finishMove(frame)
    end
  elseif frame.phase == "end" then
    if frame.found or frame.known_distance ~= 0 or not indexing:satisfied(state) then
      self:pop()
    elseif #region.children == 0 then
      if #self.move_list > 0 or indexing.solves_puzzle then
        self:registerSolution(self.move_list)
      else
        error("Unexpected empty solution")
      end
      self:pop()
    else
      frame.phase = "children"
    end
  else
    frame.child_i = frame.child_i + 1
    local child = region.children[frame.child_i]

    if child == nil then
      self:pop()
    else
      self:pushRegion(child, region.reflected)
    end
  end
end

--- Continues the search for a limited amount of work.
---@param budget integer? Number of states to expand at most. Default 2048.
---@return boolean done Whether the search has finished; `best_solution` is final then.
function PdbSolverTicked:tick(budget)
  if self.finished then return true end
  if not self.started then error("PdbSolverTicked:tick called before start") end

  self.budget = budget or DEFAULT_BUDGET
  local stack = self.stack

  while #stack > 0 and self.budget > 0 do
    local frame = stack[#stack]

    if frame.kind == "root" then
      self:stepRoot(frame)
    elseif frame.kind == "region" then
      self:stepRegion(frame)
    else
      self:stepState(frame)
    end
  end

  if #stack == 0 then self.finished = true end

  return self.finished
end

return PdbSolverTicked
