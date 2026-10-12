local SliderState = require "cluetrainer/puzzles/sliders/SliderState"
local PdbSolver = {}

---@param start_state cluetrainer.sliders.SliderState
---@param chain cluetrainer.sliders.pdb.RegionGraph
function PdbSolver.solve(start_state, chain)
  local state
  local move_list
  local iterations = 0
  local self = {}

  ---@param coming_from_reflected_region boolean
  ---@param current_region RegionGraph.Node
  local function doregion(coming_from_reflected_region, current_region)
    local indexing = current_region.table.indexing
    local distance_table = current_region.table

    local move_translation = current_region.reflected
        and SliderState.move_translation_reflect
        or SliderState.move_translation_identity

    ---@param known_distance integer
    local function dostate(known_distance)
      iterations = iterations + 1

      local previous_move = state[SliderState.LASTMOVE_INDEX]

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
        state[SliderState.LASTMOVE_INDEX] = previous_move

        if self.should_stop then
          break
        end

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
            self:registerSolution({ table.unpack(move_list) })
          else
            error("Unexpected empty solution")
          end
        else
          for _, child in ipairs(current_region.children) do
            if self.should_stop then
              break
            end

            doregion(current_region.reflected, child)
          end
        end
      end
    end

    local needs_reflection =
        current_region.reflected ~= coming_from_reflected_region

    if needs_reflection then
      SliderState.reflect(state)
    end

    local index = indexing:stateIndex(state)
    dostate(distance_table:getDistanceByIndex(index))

    if needs_reflection then
      SliderState.reflect(state)
    end
  end

  for _, start in ipairs(self.chain:getEntryPoints()) do
    state = SliderState.fromPermutation(self.start_state)
    move_list = {}

    doregion(false, start)
    self:checkTime()
  end
end

return PdbSolver
