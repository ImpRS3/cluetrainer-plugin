-- SliderState.lua
local zyklib = require "zyklib"

---@class cluetrainer.sliders.sliderstate
local SliderState = {}

---@class cluetrainer.sliders.SliderState : integer[]

---Gets the current state of all sliders.
---@return cluetrainer.sliders.SliderState
function SliderState.getSliderState()
  return SliderState.fromPermutation(zyklib.array.flatten({
    zyklib.bits.getAll(5, var.VarClient.SLIDE_PUZZLE_CLIENT0.value),
    zyklib.bits.getAll(5, var.VarClient.SLIDE_PUZZLE_CLIENT1.value),
    zyklib.bits.getAll(5, var.VarClient.SLIDE_PUZZLE_CLIENT2.value),
    zyklib.bits.getAll(5, var.VarClient.SLIDE_PUZZLE_CLIENT3.value),
    zyklib.bits.getAll(5, var.VarClient.SLIDE_PUZZLE_CLIENT4.value, 1)
  }))
end

SliderState.BLANK_TILE = 24
SliderState.BLANK_TILE_INDEX = 26
SliderState.LAST_MOVE_INDEX = 27

--- Maps a tile id (0-24) to its reflected tile id (horizontal <-> vertical), stored at index `tile + 1`.
SliderState.tile_reflection_table = {
  1, 6, 11, 16, 21,
  2, 7, 12, 17, 22,
  3, 8, 13, 18, 23,
  4, 9, 14, 19, 24,
  5, 10, 15, 20, 25
}

--- Partial moves for each possible move, used in `SliderState.doMove`. 
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

--- Applies a move to this slider state in-place.
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

---Checks whether two states have the same tiles. Only indices 1-25 are compared, not the blank index or last move metadata.
---@param a cluetrainer.sliders.SliderState
---@param b cluetrainer.sliders.SliderState
---@return boolean
function SliderState.isEqual(a, b)
  for i = 1, 25 do
    if a[i] ~= b[i] then return false end
  end

  return true
end

---Returns all states reachable from the given state with a single move.
---@param state cluetrainer.sliders.SliderState
---@param multitile_allowed boolean? Whether multitile moves are included. Defaults to true.
---@return cluetrainer.sliders.SliderState[]
function SliderState.neighbours(state, multitile_allowed)
  local blank = state[SliderState.BLANK_TILE_INDEX]
  local x = (blank - 1) % 5
  local y = (blank - 1) // 5

  ---@type cluetrainer.sliders.Move[]
  local moves = {}

  for xi = 0, 4 do
    if xi ~= x then table.insert(moves, xi - x) end
  end

  for yi = 0, 4 do
    if yi ~= y then table.insert(moves, (yi - y) * 5) end
  end

  local result = {}

  for _, move in ipairs(moves) do
    if multitile_allowed ~= false or math.abs(move) == 1 or math.abs(move) == 5 then
      local neighbour = zyklib.objects.clone(state)
      SliderState.doMove(neighbour, move)
      table.insert(result, neighbour)
    end
  end

  return result
end

---@class cluetrainer.sliders.AugmentedMove
---@field move cluetrainer.sliders.Move
---@field pre_states cluetrainer.sliders.SliderState[] States in which this move is the next one to make. The first entry is the exact state before the move, the rest are the neighbours of `post`.
---@field post cluetrainer.sliders.SliderState State after the move

--- Pairs each move with the set of states it applies to and the state after it. Neither the start state nor the moves are modified.
--- Each `post` is the same table as the next entry's `pre_states[1]`, so treat the states as read-only.
---@param start cluetrainer.sliders.SliderState
---@param moves cluetrainer.sliders.Move[]
---@return cluetrainer.sliders.AugmentedMove[]
function SliderState.augmentMoves(start, moves)
  ---@type cluetrainer.sliders.AugmentedMove[]
  local result = {}
  local current = start

  for i, move in ipairs(moves) do
    local post = zyklib.objects.clone(current)
    SliderState.doMove(post, move)

    local pre_states = { current }
    for _, neighbour in ipairs(SliderState.neighbours(post)) do
      table.insert(pre_states, neighbour)
    end

    result[i] = { move = move, pre_states = pre_states, post = post }
    current = post
  end

  return result
end

---Construct an optimized slider state from a given permutation of tiles.
---@param state integer[] Any permutation of the numbers 0 through 24
---@return cluetrainer.sliders.SliderState
function SliderState.fromPermutation(state)
  local result = { table.unpack(state) }
  result[SliderState.LAST_MOVE_INDEX] = 20
  result[SliderState.BLANK_TILE_INDEX] = zyklib.array.indexOf(state, SliderState.BLANK_TILE)

  return result
end

--- Maps a move to its reflected move (horizontal <-> vertical), stored at index `move + 21`.
SliderState.move_translation_reflect = {
  [21 - 20] = -4,
  [21 - 15] = -3,
  [21 - 10] = -2,
  [21 - 5] = -1,
  [21 - 4] = -20,
  [21 - 3] = -15,
  [21 - 2] = -10,
  [21 - 1] = -5,
  [21 - 0] = 0,
  [21 + 1] = 5,
  [21 + 2] = 10,
  [21 + 3] = 15,
  [21 + 4] = 20,
  [21 + 5] = 1,
  [21 + 10] = 2,
  [21 + 15] = 3,
  [21 + 20] = 4,
}

---Reflects the state in place along the main diagonal.
---@param state cluetrainer.sliders.SliderState
function SliderState.reflect(state)
  -- Swap tiles on opposing sides of the main diagonal
  -- The indices are hardcoded here sincce this is reasonably performance critical and avoids the overhead of looping through a table.
  state[2], state[6] = state[6], state[2]
  state[3], state[11] = state[11], state[3]
  state[4], state[16] = state[16], state[4]
  state[5], state[21] = state[21], state[5]
  state[8], state[12] = state[12], state[8]
  state[9], state[17] = state[17], state[9]
  state[10], state[22] = state[22], state[10]
  state[14], state[18] = state[18], state[14]
  state[15], state[23] = state[23], state[15]
  state[20], state[24] = state[24], state[20]

  -- Update tile values to the reflected tile id
  for i = 1, 25 do
    state[i] = SliderState.tile_reflection_table[state[i] + 1]
  end

  state[SliderState.BLANK_TILE_INDEX] = SliderState.tile_reflection_table[state[SliderState.BLANK_TILE_INDEX]]

  local last_move = state[SliderState.LAST_MOVE_INDEX]
  state[SliderState.LAST_MOVE_INDEX] = SliderState.move_translation_reflect[last_move + 1] + 20
end

return SliderState
