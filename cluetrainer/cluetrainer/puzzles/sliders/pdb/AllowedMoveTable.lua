-- AllowedMoveTable.lua
local Move = require("cluetrainer/puzzles/sliders/Move")
local Region = require("cluetrainer/puzzles/sliders/pdb/Region")
local SliderState = require("cluetrainer/puzzles/sliders/SliderState")
local zyklib = require("zyklib")

---@class ct.sliders.pdb.AllowedMoveTable
---@field region ct.sliders.pdb.RegionDescription
---@field multitile boolean
---@field allow_undoing_moves boolean
---@field move_table ct.sliders.Move[][][]
local MoveTable = {}
MoveTable.__index = MoveTable

---
---@param region ct.sliders.pdb.RegionDescription
---@return ct.sliders.pdb.AllowedMoveTable
function MoveTable.new(region)
  local self = setmetatable({}, MoveTable)
  self.move_table = {}

  -- We precompute the allowed moves as a lookup table indexed by the last move and the blank tile position

  for _, last_move in ipairs({ 0, table.unpack(Move.all) }) do
    local move_entry = {}
    self.move_table[last_move + 21] = move_entry

    local viable_moves = (function()
      if region.multitile then
        -- For multi tile moves, vertical and horizontal moves must alternate.
        if last_move == 0 then
          -- Special case for the first move, all multitile moves are allowed
          return Move.multitile_moves
        elseif Move.isVertical(last_move) then
          return Move.horizontal_mtm
        else
          return Move.vertical_mtm
        end
      else
        -- For single tile moves, all moves that do not undo the last move are viable
        return zyklib.array.filter(Move.singletile_moves, function(m) return m ~= -last_move end)
      end
    end)()

    for blank = 1, 25 do
      local x = (blank - 1) % 5
      local y = (blank - 1) // 5

      move_entry[blank] = zyklib.array.filter(viable_moves, function(move)
        local dx = move % 5 == 0 and 0 or move
        local dy = move % 5 == 0 and move // 5 or 0

        local tx = x + dx
        local ty = y + dy

        -- A move is possible if
        -- 1. It stays inside the bounds of the 5x5 grid AND
        -- 2. It does not move the blank tile outside of the current region
        return tx >= 0 and tx < 5
            and ty >= 0 and ty < 5
            and region.region[blank + move] ~= Region.Tile.FIXED
      end)
    end
  end

  return self
end

---
---@param state ct.sliders.SliderState
---@return ct.sliders.Move[]
function MoveTable:get(state)
  return self.move_table[state[SliderState.LAST_MOVE_INDEX] + 21][state[SliderState.BLANK_TILE_INDEX]]
end

return MoveTable
