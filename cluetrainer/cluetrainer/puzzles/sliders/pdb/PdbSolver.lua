-- PdbSolver.lua
local SliderState = require "cluetrainer/puzzles/sliders/SliderState"
local SliderSolvingTask = require "cluetrainer/puzzles/sliders/SliderSolvingTask"
local zyklib = require("zyklib")

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

---@class ct.sliders.pdb.PdbSolv : ct.sliders.SliderSolvingTask
---@field chain ct.sliders.pdb.RegionGraph
local PdbSolver = setmetatable({}, { __index = SliderSolvingTask })
PdbSolver.__index = PdbSolver

---@param start_state ct.sliders.SliderState
---@param chain ct.sliders.pdb.RegionGraph
---@return ct.sliders.pdb.PdbSolv
function PdbSolver.new(start_state, chain)
  local self = SliderSolvingTask.new(start_state)
  setmetatable(self, PdbSolver)
  ---@cast self ct.sliders.pdb.PdbSolv

  self.chain = chain
  return self
end

function PdbSolver:implementation()
  local state
  local move_list
  local iterations = 0

  ---@param coming_from_reflected_region boolean
  ---@param current_region ct.sliders.pdb.RegionGraph.Node
  local function doregion(coming_from_reflected_region, current_region)
    local indexing = current_region.table.indexing
    local distance_table = current_region.table

    local move_translation = current_region.reflected
        and SliderState.move_translation_reflect
        or move_translation_identity

    ---@param known_distance integer
    local function dostate(known_distance)
      iterations = iterations + 1
      if iterations % 2048 == 0 then
        zyklib.async.Task.maybeYield()
      end

      local previous_move = state[SliderState.LAST_MOVE_INDEX]

      if self.best_solution and #move_list > #self.best_solution then
        return
      end

      local found_optimal_move = false
      local moves = distance_table.move_table:get(state)

      for i = 1, #moves do
        local move = moves[i]

        SliderState.doMove(state, move)

        local child_index = indexing:stateIndex(state)
        local child_distance = distance_table:getDistanceByIndex(child_index)

        if (child_distance + 1) % 4 == known_distance then
          found_optimal_move = true

          move_list[#move_list + 1] = move_translation[move + 21]
          dostate(child_distance)
          move_list[#move_list] = nil
        end

        SliderState.doMove(state, -move)

        state[SliderState.LAST_MOVE_INDEX] = previous_move

        if found_optimal_move and indexing.solves_puzzle then
          break
        end
      end

      if not found_optimal_move then
        if known_distance ~= 0 or not indexing:satisfied(state) then
          return
        end

        if #current_region.children == 0 then
          if #move_list > 0 or indexing.solves_puzzle then
            self:registerSolution(move_list)
          else
            error("Unexpected empty solution")
          end
        else
          for _, child in ipairs(current_region.children) do
            doregion(current_region.reflected, child)
          end
        end
      end
    end

    local needs_reflection = current_region.reflected ~= coming_from_reflected_region

    if needs_reflection then SliderState.reflect(state) end

    local index = indexing:stateIndex(state)
    dostate(distance_table:getDistanceByIndex(index))

    if needs_reflection then
      SliderState.reflect(state)
    end
  end

  log("Starting iteration")
  for _, start in ipairs(self.chain:getEntryPoints()) do
    state = SliderState.fromPermutation(self.start_state)
    move_list = {}

    log("Starting with entry point")

    doregion(false, start)
  end

  return self.best_solution
end

return PdbSolver
