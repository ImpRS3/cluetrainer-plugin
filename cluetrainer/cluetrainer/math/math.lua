local numbers = require "cluetrainer/math/numbers"

---@class ct.lib.math
local ctmath = {
  angles = require "cluetrainer/math/angles",
  vector2 = require "cluetrainer/math/vector2",
  rectangle = require "cluetrainer/math/rectangle",
  tilecoordinates = require "cluetrainer/math/tilecoordinates",
  gielicoordinates = require "cluetrainer/math/gielicoordinates",
  tilearea = require "cluetrainer/math/tilearea",
  numbers = numbers,
  round = numbers.round,
}

return ctmath
