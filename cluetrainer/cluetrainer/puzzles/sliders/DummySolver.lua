-- DummySolver.lua
-- Placeholder solver that produces a random walk of moves. Used while the real solvers are disabled.

local zyklib = require("zyklib")

local Move        = require("cluetrainer/puzzles/sliders/Move")
local SliderState = require("cluetrainer/puzzles/sliders/SliderState")
local AllowedMoveTable = require("cluetrainer/puzzles/sliders/pdb/AllowedMoveTable")

local MOVE_COUNT  = 20

local DummySolver = {}

--- Generates a random walk of the blank tile, so every move is valid and no move directly undoes the previous one.
---@param start_state ct.sliders.SliderState
---@return ct.sliders.Move[]
function DummySolver.solve(start_state)
  ---@type ct.sliders.Move[]
  local moves = {}

  local move_table = AllowedMoveTable.new({
    region = {1, 1, 1, 1, 1,
              1, 1, 1, 1, 1,
              1, 1, 1, 1, 1,
              1, 1, 1, 1, 1,
              1, 1, 1, 1, 1},
    multitile = true
  })

  log(move_table.move_table)

  move_table:get(start_state)

  local state = zyklib.objects.clone(start_state)
  for i = 1, MOVE_COUNT do
    local candidates = move_table:get(state)
    log(candidates)
    
    local move = candidates[math.random(#candidates)]
    SliderState.doMove(state, move)
    
    moves[i] = move
  end

  return moves
end

return DummySolver
