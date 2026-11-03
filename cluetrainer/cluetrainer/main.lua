-- main.lua

--- Global for zyklib. This is a universally used library, so we save ourself some annoyance by making it a global.
---@type zyklib
zyklib = require("zyklib")

if not prettyui then
  prettyui = require("prettyui")
end

local function main()
  zyklib.lifecycle.shutdown_event:subscribe(function()
    prettyui.PluginShutdown()
  end)

  zyklib.lifecycle.setupGlobals()

  local settings_dialog = require("cluetrainer/ui/SettingsDialog")

  -- Load and initialize the individual puzzle solver modules
  require("cluetrainer/puzzles/towers/TowerSolver").init()
  require("cluetrainer/puzzles/lockbox/LockboxSolver").init()
  require("cluetrainer/puzzles/knot/KnotSolver").init()
  require("cluetrainer/puzzles/sliders/SliderSolver").init()
  require("cluetrainer/solving/SolvingOrchestrator").setActive(true)

  --map.show()

  zyklib.game_events.native.SettingsLayerReady:subscribe(function(payload)
    settings_dialog.mount(payload.component)
  end)

  -- task:start()
  log("clue trainer started")
end

return {
  main = main
}
