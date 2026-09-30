local zyklib = require "zyklib"

local SliderState = {}

---@alias cluetrainer.SliderState integer[]

---Gets the current state of all sliders.
---@return cluetrainer.SliderState
function SliderState.getSliderState()
  return zyklib.lua_util.concat(
    zyklib.bit.getAll(5, var.VarClient.SLIDE_PUZZLE_CLIENT0.value),
    zyklib.bit.getAll(5, var.VarClient.SLIDE_PUZZLE_CLIENT1.value),
    zyklib.bit.getAll(5, var.VarClient.SLIDE_PUZZLE_CLIENT2.value),
    zyklib.bit.getAll(5, var.VarClient.SLIDE_PUZZLE_CLIENT3.value),
    zyklib.bit.getAll(5, var.VarClient.SLIDE_PUZZLE_CLIENT4.value, 1)
  )
end

SliderState.LAST_MOVE_INDEX = 26
SliderState.BLANK_TILE_INDEX = 27

function SliderState.getLastMove(state)
  return state[SliderState.LAST_MOVE_INDEX]
end

function SliderState.getBlankPosition(state)
  return state[SliderState.BLANK_TILE_INDEX]
end

return SliderState
