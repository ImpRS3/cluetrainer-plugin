local zyklib = require "zyklib"

local SliderState = {}

---@class cluetrainer.sliders.SliderState : integer[]

---Gets the current state of all sliders.
---@return cluetrainer.sliders.SliderState
function SliderState.getSliderState()
  return SliderState.fromPermutation(zyklib.array.flatten({
    zyklib.bit.getAll(5, var.VarClient.SLIDE_PUZZLE_CLIENT0.value),
    zyklib.bit.getAll(5, var.VarClient.SLIDE_PUZZLE_CLIENT1.value),
    zyklib.bit.getAll(5, var.VarClient.SLIDE_PUZZLE_CLIENT2.value),
    zyklib.bit.getAll(5, var.VarClient.SLIDE_PUZZLE_CLIENT3.value),
    zyklib.bit.getAll(5, var.VarClient.SLIDE_PUZZLE_CLIENT4.value, 1)
  }))
end

SliderState.BLANK_TILE = 24
SliderState.BLANK_TILE_INDEX = 26
SliderState.LAST_MOVE_INDEX = 27

SliderState.index_reflection_table = {
  1, 6, 11, 16, 21,
  2, 7, 12, 17, 22,
  3, 8, 13, 18, 23,
  4, 9, 14, 19, 24,
  5, 10, 15, 20, 25
}

local partial_moves = {
  [-20] = { 0, -5, -10, -15, -20 },
  [-15] = { 0, -5, -10, -15 },
  [-10] = { 0, -5, -10 },
  [-5]  = { 0, -5 },
  [-4]  = { 0, -1, -2, -3, -4 },
  [-3]  = { 0, -1, -2, -3 },
  [-2]  = { 0, -1, -2 },
  [-1]  = { 0, -1 },
  [0]   = {},
  [1]   = { 0, 1 },
  [2]   = { 0, 1, 2 },
  [3]   = { 0, 1, 2, 3 },
  [4]   = { 0, 1, 2, 3, 4 },
  [5]   = { 0, 5 },
  [10]  = { 0, 5, 10 },
  [15]  = { 0, 5, 10, 15 },
  [20]  = { 0, 5, 10, 15, 20 }
}

---@param state cluetrainer.sliders.SliderState
---@param move cluetrainer.sliders.Move
function SliderState.doMove(state, move)
  local partials = partial_moves[move]

  local blank = state[SliderState.BLANK_TILE_INDEX]

  for i = 1, #partials - 1 do
    state[blank + partials[i]] = state[blank + partials[i + 1]]
  end

  state[SliderState.LAST_MOVE_INDEX] = move + 20
  state[SliderState.BLANK_TILE_INDEX] = blank + move
  state[blank + move] = SliderState.BLANK_TILE
end

---Construct an optimized slider state from a given permutation of tiles.
---@param state integer[] Any permutation of the numbers 0 through 24
---@return cluetrainer.sliders.SliderState
function SliderState.fromPermutation(state)
  return {
    table.unpack(state),
    [SliderState.LASTMOVE_INDEX] = 20,
    [SliderState.BLANK_TILE_INDEX] = zyklib.array.indexOf(state, SliderState.BLANK_TILE)
  }
end

return SliderState
