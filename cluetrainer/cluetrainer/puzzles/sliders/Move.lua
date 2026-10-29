-- Move.lua
---@alias ct.sliders.Move integer

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
---@param move ct.sliders.Move
---@return ct.sliders.Move[]
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

---@param move ct.sliders.Move
---@return boolean
function Move.isSmallStep(move)
  return move == 1 or move == -1
      or move == 5 or move == -5
end

---@param move ct.sliders.Move
---@return boolean
function Move.isValid(move)
  local m = math.abs(move)
  return (m >= 1 and m <= 5)
      or m == 10 or m == 15 or m == 20
end

---@param move ct.sliders.Move
---@return boolean
function Move.isVertical(move)
  return move % 5 == 0
end

--- Splits every move into its single steps, e.g. `{2, -5}` becomes `{1, 1, -5}`.
---@param moves ct.sliders.Move[]
---@return ct.sliders.Move[]
function Move.expand(moves)
  local result = {}

  for _, move in ipairs(moves) do
    for _, step in ipairs(Move.split(move)) do
      result[#result + 1] = step
    end
  end

  return result
end

--- Merges consecutive moves in the same direction into one multitile move, e.g. `{1, 1, -5}` becomes `{2, -5}`.
---@param moves ct.sliders.Move[]
---@return ct.sliders.Move[]
function Move.compress(moves)
  local result = {}

  for _, move in ipairs(moves) do
    local last = result[#result]
    local merged

    if last ~= nil and Move.isVertical(last) == Move.isVertical(move) and (last > 0) == (move > 0) then
      -- Horizontal moves span at most 4 tiles, vertical moves at most 20 (4 rows)
      local sum = last + move
      if math.abs(sum) <= (Move.isVertical(move) and 20 or 4) then merged = sum end
    end

    if merged ~= nil then
      result[#result] = merged
    else
      result[#result + 1] = move
    end
  end

  return result
end

return Move
