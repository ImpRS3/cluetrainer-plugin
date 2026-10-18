-- RegionIndexing.lua
--- Precomputed table for small factorials
local factorial_table = { 1 }
for n = 2, 25 do
  factorial_table[n] = factorial_table[n - 1] * n
end

-- Precomputed table for binomial coefficients (n choose k)
-- n_choose_k_table[n + 1][k + 1] = C(n, k)
local n_choose_k_table = {}

for n = 0, 25 do
  local row = {}
  n_choose_k_table[n + 1] = row

  for k = 0, 25 do
    if k > n then
      row[k + 1] = 0
    elseif k == 0 or k == n then
      row[k + 1] = 1
    else
      row[k + 1] =
          n_choose_k_table[n][k]
          + n_choose_k_table[n][k + 1]
    end
  end
end

--- Compute the factorial of n down to the lower bound (inclusive).
--- @param n integer
--- @param lower? integer
--- @return integer
local function factorial(n, lower)
  lower = lower or 1
  if n <= lower then return 1 end
  return n * factorial(n - 1, lower)
end

--- This class provides efficient indexing to find slider states within a region by utilizing precomputed tables.
--- @class cluetrainer.sliders.pdb.RegionIndexing
--- @field region cluetrainer.sliders.pdb.RegionDescription
--- @field current integer
--- @field freedom integer
--- @field solves_puzzle boolean
--- @field number_of_permutations integer
--- @field size integer
--- @field permutation_array integer[]
--- @field combination_relevant_indices integer[]
--- @field relevant_tile_numbers boolean[]
--- @field solution_relevant_indices integer[]
local Indexing = {}
Indexing.__index = Indexing

---@param region integer[]
---@return cluetrainer.sliders.pdb.RegionIndexing
function Indexing.new(region)
  local self = setmetatable({}, Indexing)

  log("indexing region "..table.concat(region, ", "))

  local zyklib = require("zyklib")
  local Tile = require("cluetrainer/puzzles/sliders/pdb/Region").Tile
  local SliderState = require "cluetrainer/puzzles/sliders/SliderState"

  self.region = region
  self.solves_puzzle = zyklib.array.forAll(region, function(tile, i) return tile ~= Tile.FREE or i == 24 or i == 20 end)
  self.current = zyklib.array.count(region, function(tile) return tile == Tile.CURRENT end)
  self.freedom = zyklib.array.count(region, function(tile) return tile ~= Tile.FIXED end)

  log("current: "..self.current..", freedom: "..self.freedom)

  if not self.solves_puzzle then self.current = self.current + 1 end

  self.number_of_permutations = factorial_table[self.current]
  self.size = factorial(
    self.freedom,
    math.max(2, self.freedom - self.current)
  )

  log("number_of_permutations: "..self.number_of_permutations..", size: "..self.size)

  --- Pre-allocate a reusable array for storing permutations
  self.permutation_array = {}
  for i = 1, self.current do
    self.permutation_array[i] = 0
  end

  self.combination_relevant_indices = {}
  self.relevant_tile_numbers = {}
  self.solution_relevant_indices = {}

  -- CURRENT tiles precede FREE tiles.
  -- Equivalent to descending sort by region tile value.
  local entries = {}

  for i = 1, 25 do
    local tile = region[i]

    if tile ~= Tile.FIXED then
      entries[#entries + 1] = { tile, i }
    end

    self.relevant_tile_numbers[i] =
        tile == Tile.CURRENT or i == SliderState.BLANK_TILE + 1

    if tile == Tile.CURRENT or tile == Tile.FIXED then
      self.solution_relevant_indices[#self.solution_relevant_indices + 1] = i
    end
  end

  log("entries before sorting: "..table.concat(zyklib.array.map(entries, function(entry) return entry[1].."@"..entry[2] end), ", "))

  table.sort(entries, function(a, b)
    if a[1] == b[1] then
      return a[2] < b[2]
    end

    return a[1] > b[1]
  end)

  for i = 1, #entries do
    self.combination_relevant_indices[i] = entries[i][2]
  end

  return self
end

--- Compute the index for a given state within the region.
---@param state cluetrainer.sliders.SliderState
---@return integer A 0-based index representing the position of the state within the binary data for the distance table of this region
function Indexing:stateIndex(state)
  -- Buckle in, because things are about to get combinatorial.

  -- https://en.wikipedia.org/wiki/Combinatorial_number_system
  -- https://www.jaapsch.net/puzzles/compindx.htm

  -- TLDR: An index of a slider state for a given region consists of two componente:
  -- 1. A combination index representing the positions of the relevant tiles (CURRENT) in the puzzle (CURRENT + FREE)
  --    ranges from 0 to ((CURRENT + FREE) choose CURRENT)
  -- 2. A permutation index representing the order of the relevant tiles (CURRENT) within the combination
  --    ranges from 0 to (CURRENT!)

  -- First, we compute the combination index
  local combination_index = 0
  local counter = 1

  -- Iterate over the combination relevant indices to find the positions of all relevant tiles
  for i = 1, #self.combination_relevant_indices do
    local tile = state[self.combination_relevant_indices[i]]

    if self.relevant_tile_numbers[tile + 1] then
      self.permutation_array[counter] = tile -- Store the tile in the permutation array for later use

      combination_index = combination_index + n_choose_k_table[i][counter + 1]

      counter = counter + 1
      if counter > self.current then break end -- Early exit if we have already found all current tiles
    end
  end

  -- Next, the permutation index
  local permutation_index = 0

  for i = 2, self.current do
    local value = factorial_table[i - 1]

    for j = 1, i - 1 do
      if self.permutation_array[j] > self.permutation_array[i] then
        permutation_index = permutation_index + value
      end
    end
  end

  return combination_index * self.number_of_permutations + permutation_index
end

---@param state integer[]
---@return boolean
function Indexing:satisfied(state)
  local indices = self.solution_relevant_indices

  for i = 1, #indices do
    local index = indices[i]

    if state[index] ~= index - 1 then
      return false
    end
  end

  return true
end

return Indexing
