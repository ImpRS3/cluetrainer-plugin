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

  for _, last_move in ipairs({ 0, table.unpack(Move.all) }) do
    local move_entry = {}
    self.move_table[last_move + 21] = move_entry

    local moves

    if region.multitile then
      moves = last_move == 0 and Move.multitile_moves
          or Move.isVertical(last_move) and Move.horizontal_mtm
          or Move.vertical_mtm
    else
      moves = zyklib.array.filter(Move.singletile_moves, function(m)
        return m ~= -last_move
      end)
    end

    for blank = 1, 25 do
      local x = (blank - 1) % 5
      local y = (blank - 1) // 5

      move_entry[blank] = zyklib.array.filter(moves, function(move)
        local dx = move % 5 == 0 and 0 or move
        local dy = move % 5 == 0 and move // 5 or 0

        local tx = x + dx
        local ty = y + dy

        return tx >= 0 and tx < 5
            and ty >= 0 and ty < 5
            and region[blank + move] ~= Region.Tile.FIXED
      end)
    end
  end

  return self
end

---
---@param state ct.sliders.SliderState
---@return ct.sliders.Move[]
function MoveTable:get(state)
  return self.move_table[state[SliderState.LAST_MOVE_INDEX] + 1][state[SliderState.BLANK_TILE_INDEX]]
end

return MoveTable
