local SliderSolver = require("cluetrainer/puzzles/sliders/SliderSolver")
local KnotSolver = require("cluetrainer/puzzles/knot/KnotSolver")
local LockboxSolver = require("cluetrainer/puzzles/lockbox/LockboxSolver")
local TowerSolver = require("cluetrainer/puzzles/towers/TowerSolver")

--- Collects the settings that each puzzle module owns and persists.
local settings = {
  sliders = SliderSolver.settings,
  knots = KnotSolver.settings,
  lockboxes = LockboxSolver.settings,
  towers = TowerSolver.settings,
}

return settings
