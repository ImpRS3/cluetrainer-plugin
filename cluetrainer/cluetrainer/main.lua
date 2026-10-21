-- main.lua
local zyklib = require("zyklib")

local function main()
  local zyklib = require("zyklib")
  zyklib.lifecycle.setupGlobals()

  local orchestrator   = require("cluetrainer/solving/orchestrator")
  local towers_solver  = require("cluetrainer/puzzles/towers/TowerSolver")
  local lockbox_solver = require("cluetrainer/puzzles/lockbox/LockboxSolver")
  local knot_solver    = require("cluetrainer/puzzles/knot/KnotSolver")
  local slider_solver  = require("cluetrainer/puzzles/sliders/SliderSolver")

  towers_solver.setActive(true)
  lockbox_solver.setActive(true)
  knot_solver.setActive(true)
  slider_solver.setActive(true)
  orchestrator.init()

  -- local data = require("cluetrainer/puzzles/sliders/pdb/data/mtm_pdb_data")

  -- local task = zyklib.base64.decodeLargeAsync(data.base64)

  -- task.finished_event:subscribe(function(res)
  --   log("finished")
  --   log(res)
  -- end)

  -- task:start()
  log("clue trainer started")
end

return {
  main = main
}
