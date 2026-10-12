---@alias cluetrainer.sliders.Move integer

local Move = {}

Move.all = {
  -20, -15, -10, -5, -4, -3, -2, -1,
  1, 2, 3, 4, 5, 10, 15, 20
}

Move.singletile_moves = { -5, -1, 1, 5 }
Move.multitile_moves = Move.all

Move.horizontal_mtm = { -4, -3, -2, -1, 1, 2, 3, 4 }
Move.vertical_mtm = { -20, -15, -10, -5, 5, 10, 15, 20 }

--- Splits a move into its constituent single steps.
---@param move cluetrainer.sliders.Move
---@return cluetrainer.sliders.Move[]
function Move.split(move)
  local step = move > 0 and 1 or -1
  if math.abs(move) >= 5 then
    step = step * 5
  end

  local n = move // step
  local result = {}

  for i = 1, n do
    result[i] = step
  end

  return result
end

---@param move cluetrainer.sliders.Move
---@return boolean
function Move.isSmallStep(move)
  return move == 1 or move == -1
      or move == 5 or move == -5
end

---@param move cluetrainer.sliders.Move
---@return boolean
function Move.isValid(move)
  local m = math.abs(move)
  return (m >= 1 and m <= 5)
      or m == 10 or m == 15 or m == 20
end

---@param move cluetrainer.sliders.Move
---@return boolean
function Move.isVertical(move)
  return move % 5 == 0
end

return Move
