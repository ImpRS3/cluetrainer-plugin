-- main.lua
local zyklib = require("zyklib")
local map    = require("cluetrainer/map/map")

local function main()
  zyklib.lifecycle.setupGlobals()

  local orchestrator    = require("cluetrainer/solving/orchestrator")
  local towers_solver   = require("cluetrainer/puzzles/towers/TowerSolver")
  local lockbox_solver  = require("cluetrainer/puzzles/lockbox/LockboxSolver")
  local knot_solver     = require("cluetrainer/puzzles/knot/KnotSolver")
  local slider_solver   = require("cluetrainer/puzzles/sliders/SliderSolver")
  local settings_dialog = require("cluetrainer/ui/SettingsDialog")

  towers_solver.init()
  lockbox_solver.init()
  knot_solver.init()
  slider_solver.init()
  orchestrator.init()

  map.show()
  --settings_dialog.open()

  zyklib.game_events.native.SettingsLayerReady:subscribe(function(payload)
    settings_dialog.mount(payload.component)
  end)

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
