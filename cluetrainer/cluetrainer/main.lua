local function main()
  local orchestrator   = require("cluetrainer/solving/orchestrator")
  local towers_solver  = require("cluetrainer/puzzles/towers/TowerSolver")
  local lockbox_solver = require("cluetrainer/puzzles/lockbox/LockboxSolver")
  local knot_solver    = require("cluetrainer/puzzles/knots/KnotSolver")

  towers_solver:init()
  lockbox_solver:init()
  knot_solver:init()
  orchestrator.init()

  log("clue trainer started")
end

return {
  main = main
}
