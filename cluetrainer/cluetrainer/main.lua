local function main()
  local zyklib = require("zyklib")
  zyklib.lifecycle.setupGlobals()

  local orchestrator   = require("cluetrainer/solving/orchestrator")
  local towers_solver  = require("cluetrainer/puzzles/towers/TowerSolver")
  local lockbox_solver = require("cluetrainer/puzzles/lockbox/LockboxSolver")
  local knot_solver    = require("cluetrainer/puzzles/knots/KnotSolver")
  local slider_solver  = require("cluetrainer/puzzles/sliders/SliderSolver")

  towers_solver:init()
  lockbox_solver:init()
  knot_solver:init()
  slider_solver.setActive(true)
  orchestrator.init()

  log("clue trainer started")
end

return {
  main = main
}
