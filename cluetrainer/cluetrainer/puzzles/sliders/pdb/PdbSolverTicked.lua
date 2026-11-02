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

--- The pattern database solver without coroutines. It has the interface of `PdbSolver`
--- (`start_state`, `best_solution`, `registerSolution`), but instead of being run as a task, `tick` has to be called
--- repeatedly until it returns true. The recursion of `PdbSolver` is replaced by an explicit stack of frames, so
--- every call of `tick` continues exactly where the previous one stopped.
---@class ct.sliders.pdb.PdbSolverTicked
---@field start_state ct.sliders.SliderState
---@field chain ct.sliders.pdb.RegionGraph
---@field best_solution integer[]?
---@field private state ct.sliders.SliderState
---@field private finished boolean
---@field private tick_handler zyklib.disposable.IDisposable?
---@field private started boolean
---@field private stack StackItem[]
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
  self.finished = false
  self.started = false
  self.stack = {}

  return self
end

--- Prepares the search. Has to be called once before `tick`; calling it again has no effect.
function PdbSolverTicked:start()
  if self.started or self.finished then return end

  self.started = true

  local state = SliderState.fromPermutation(self.start_state)

  -- Initialize stack with all entry points
  for _, entry in ipairs(self.chain:getEntryPoints()) do
    self:pushState(entry, state, {},
      entry.table:getDistanceByIndex(entry.table.indexing:stateIndex(state))
    )
  end
end

---@protected
---@param solution integer[]
function PdbSolverTicked:registerSolution(solution)
  if self.best_solution == nil or #solution < #self.best_solution then
    -- TODO: Compress/Uncompress if needed!
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
---@param state ct.sliders.SliderState
---@param moves ct.sliders.Move[]
---@param known_distance integer
function PdbSolverTicked:pushState(region, state, moves, known_distance)
  if #self.stack > 512 then
    return -- Discard state when there are too many open ends
  end

  self.stack[#self.stack + 1] = {
    region = region,
    state = { table.unpack(state) },
    moves = moves, -- No copy required here. Caller makes a copy if needed
    known_distance = known_distance,
  }
end

---@private
---@return StackItem
function PdbSolverTicked:pop()
  local top = self.stack[#self.stack]
  self.stack[#self.stack] = nil
  return top
end

---@class StackItem
---@field region ct.sliders.pdb.RegionGraph.Node
---@field state ct.sliders.SliderState
---@field moves ct.sliders.Move[]
---@field known_distance integer

---@return integer # The number of iterations performed in this step
function PdbSolverTicked:step()
  local frame = self:pop()

  local state = frame.state
  local move_list = frame.moves
  local current_region = frame.region
  local indexing = current_region.table.indexing
  local distance_table = current_region.table

  local move_translation = current_region.reflected
      and SliderState.move_translation_reflect
      or move_translation_identity

  local known_distance = frame.known_distance

  local number_of_iterations = 0

  -- Loop through states until end of region is reached
  while true do
    number_of_iterations = number_of_iterations + 1

    if self.best_solution and #move_list > #self.best_solution then
      -- Stop exploring this branch as it cannot yield a better solution
      break
    end

    -- The first optimal move is followed locally, all others are deferred to the stack
    local next_move, next_distance
    local moves = distance_table.move_table:get(state)

    local previous_move = state[SliderState.LAST_MOVE_INDEX]

    for i = 1, #moves do
      local move = moves[i]

      SliderState.doMove(state, move)

      local child_index = indexing:stateIndex(state)

      local child_distance = distance_table:getDistanceByIndex(child_index)

      if (child_distance + 1) % 4 == known_distance then
        if next_move == nil then
          next_move = move
          next_distance = child_distance

          if indexing.solves_puzzle then
            -- If we are in a final region, we do not need to consider further moves
            SliderState.doMove(state, -move)
            state[SliderState.LAST_MOVE_INDEX] = previous_move
            break
          end
        else
          -- If we have already found the first optimal move, any subsequent moves that also satisfy the distance condition are deferred to the stack for later exploration1
          local child_moves = { table.unpack(move_list) }
          child_moves[#child_moves + 1] = move_translation[move + 21]
          self:pushState(current_region, state, child_moves, child_distance)
        end
      end

      SliderState.doMove(state, -move)
      state[SliderState.LAST_MOVE_INDEX] = previous_move
    end

    if next_move == nil then
      if known_distance ~= 0 or not indexing:satisfied(state) then
        -- This is a dead end, there are no optimal moves.
        -- Without slackness (TODO), this can only happen in the first iteration of a region.
        break
      end

      if #current_region.children == 0 then
        -- This is a leaf region, so we either register the solution or report an error if it's empty
        self:registerSolution(move_list)
      else
        -- If this is not a leaf region, we need to explore its child regions recursively. We do so by pushing them to the stack
        for _, child in ipairs(current_region.children) do
          local needs_reflection = child.reflected ~= current_region.reflected

          if needs_reflection then SliderState.reflect(state) end

          self:pushState(
            child,
            state,
            { table.unpack(move_list) },
            child.table:getDistanceByIndex(child.table.indexing:stateIndex(state))
          )

          if needs_reflection then SliderState.reflect(state) end
        end
      end

      break
    end

    SliderState.doMove(state, next_move)

    move_list[#move_list + 1] = move_translation[next_move + 21]
    known_distance = next_distance
  end

  return number_of_iterations
end

--- Continues the search for a limited amount of work.
---@param budget integer Number of states to expand at most.
---@return boolean done Whether the search has finished; `best_solution` is final then.
function PdbSolverTicked:tick(budget)
  if self.finished then return true end
  if not self.started then error("PdbSolverTicked:tick called before start") end

  while #self.stack > 0 and budget > 0 do
    local used_budged = self:step()

    self.total_iterations = (self.total_iterations or 0) + used_budged

    budget = budget - used_budged
  end

  if #self.stack == 0 then self.finished = true end

  return self.finished
end

return PdbSolverTicked
