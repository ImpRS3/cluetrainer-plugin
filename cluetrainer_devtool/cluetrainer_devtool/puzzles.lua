-- puzzles.lua
-- Random but solvable puzzle states, as VarPlayer values. A given puzzle item opens with whatever state the account
-- holds, the server only writes a new one when a real trail step creates the puzzle. The layouts are the ones Clue
-- Trainer's solvers read.
local puzzles = {}

-- All puzzles are 5 by 5 squares, numbered row by row from 0 in the top left.
local SIZE = 5
local SQUARES = SIZE * SIZE

-- Slider: each square holds the number of the tile on it. Solved, tile n is on square n, and the last one is empty.
local EMPTY_TILE = SQUARES - 1
-- Random moves of the empty square away from the solved puzzle. Any state reached by moves is solvable.
local SLIDER_MOVES = 200
-- SLIDE_PUZZLE_HARD_STARTED at 1 marks the slider as under way. At 0, opening the box makes the server write its own
-- scramble over ours, and always the same one.
local SLIDER_STARTED = 1

-- Lockbox: each square shows one of three icons. Clicking a square turns it and its four neighbours one icon on,
-- solved means all squares show the same icon. Any state reached by clicks is solvable.
local LOCKBOX_ICONS = 3
-- Random clicks away from the solved puzzle.
local LOCKBOX_CLICKS = 15

---@alias devtool.VarValues {[1]: string, [2]: integer}[] VarPlayer names with their values

--- The squares above, below, left and right of a square that are on the board.
---@param square integer
---@return integer[]
local function neighbours(square)
  local row, column = square // SIZE, square % SIZE
  local result = {}
  if row > 0 then result[#result + 1] = square - SIZE end
  if row < SIZE - 1 then result[#result + 1] = square + SIZE end
  if column > 0 then result[#result + 1] = square - 1 end
  if column < SIZE - 1 then result[#result + 1] = square + 1 end
  return result
end

--- The numbers from 1 to n in random order.
---@param n integer
---@return integer[]
local function shuffled(n)
  local result = {}
  for i = 1, n do result[i] = i end
  for i = n, 2, -1 do
    local j = math.random(i)
    result[i], result[j] = result[j], result[i]
  end
  return result
end

--- A scrambled hard slider.
---@return devtool.VarValues
function puzzles.slider()
  local tiles = {}
  for square = 0, SQUARES - 1 do tiles[square] = square end

  local empty = EMPTY_TILE
  for _ = 1, SLIDER_MOVES do
    local options = neighbours(empty)
    local target = options[math.random(#options)]
    tiles[empty], tiles[target] = tiles[target], tiles[empty]
    empty = target
  end

  local vars = { { "SLIDE_PUZZLE_HARD_STARTED", SLIDER_STARTED } }
  for square = 0, SQUARES - 1 do vars[#vars + 1] = { "SLIDE_PUZZLE_HARD_PIECE" .. square, tiles[square] } end
  return vars
end

--- A scrambled lockbox.
---@return devtool.VarValues
function puzzles.lockbox()
  local icons = {}
  for square = 0, SQUARES - 1 do icons[square] = 0 end

  for _ = 1, LOCKBOX_CLICKS do
    local clicked = math.random(0, SQUARES - 1)
    for _, square in ipairs({ clicked, table.unpack(neighbours(clicked)) }) do
      icons[square] = (icons[square] + 1) % LOCKBOX_ICONS
    end
  end

  local vars = {}
  for square = 0, SQUARES - 1 do vars[#vars + 1] = { "TRAIL_LIGHTSOUT_POS_" .. square, icons[square] } end
  return vars
end

--- How many towers you see along a line of heights, taller towers hide the shorter ones behind them.
---@param heights integer[] From the edge you look from
---@return integer
local function visibleTowers(heights)
  local seen, tallest = 0, 0
  for _, height in ipairs(heights) do
    if height > tallest then seen, tallest = seen + 1, height end
  end
  return seen
end

--- The same values in opposite order.
---@param values integer[]
---@return integer[]
local function reversed(values)
  local result = {}
  for i = #values, 1, -1 do result[#result + 1] = values[i] end
  return result
end

--- A new towers puzzle: random heights 1 to 5, each once per row and column, with the hints that go with them. The
--- player's towers are cleared.
---@return devtool.VarValues
function puzzles.towers()
  -- A Latin square with its rows, columns and heights shuffled is still one.
  local rows, columns, heights = shuffled(SIZE), shuffled(SIZE), shuffled(SIZE)
  local function height(x, y) return heights[(rows[y] + columns[x]) % SIZE + 1] end

  local vars = {}
  for i = 1, SIZE do
    local column, row = {}, {}
    for j = 1, SIZE do column[j], row[j] = height(i, j), height(j, i) end
    local hint = "TRAIL17_SKYSCRAPERS_HINT_SLOT_" .. (i - 1)
    vars[#vars + 1] = { hint .. "_TOP_PLAYER", visibleTowers(column) }
    vars[#vars + 1] = { hint .. "_BOTTOM_PLAYER", visibleTowers(reversed(column)) }
    vars[#vars + 1] = { hint .. "_LEFT_PLAYER", visibleTowers(row) }
    vars[#vars + 1] = { hint .. "_RIGHT_PLAYER", visibleTowers(reversed(row)) }
  end

  for x = 0, SIZE - 1 do
    for y = 0, SIZE - 1 do vars[#vars + 1] = { "TRAIL17_SKYSCRAPERS_SLOT_" .. x .. "_" .. y, 0 } end
  end
  return vars
end

return puzzles
