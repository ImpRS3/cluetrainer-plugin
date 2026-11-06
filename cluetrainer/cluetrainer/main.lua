-- main.lua

--- Global for zyklib. This is a universally used library, so we save ourself some annoyance by making it a global.
---@type zyklib
zyklib = require("zyklib")

-- If we do not depend dynamically on PrettyUI, use the statically included version to initialize the global
if not prettyui then
  prettyui = require("prettyui")

  zyklib.lifecycle.shutdown_event:subscribe(prettyui.PluginShutdown)
end

---@class ct.global
ctGlobal = {
  persistence = require("cluetrainer/util/storage").new("cluetrainer", "default")
}

local function main()
  zyklib.lifecycle.setupGlobals()

  local settings_dialog = require("cluetrainer/ui/SettingsDialog")
  local MainPanel = require("cluetrainer/ui/MainPanel")
  local SolvingOrchestrator = require("cluetrainer/solving/SolvingOrchestrator")
  local Map = require("cluetrainer/interfaces/map/map")

  -- Load and initialize the individual puzzle solver modules
  require("cluetrainer/puzzles/towers/TowerSolver").init()
  require("cluetrainer/puzzles/lockbox/LockboxSolver").init()
  require("cluetrainer/puzzles/knot/KnotSolver").init()
  require("cluetrainer/puzzles/sliders/SliderSolver").init()

  SolvingOrchestrator.setActive(SolvingOrchestrator.settings.enabled:get())
  if Map.settings.visible:get() then
    Map.get():setVisible(true)
  end

  zyklib.game_events.native.SettingsLayerReady:subscribe(function(payload)
    settings_dialog.mount(payload.component)
  end)

  zyklib.game_events.native.ContentLayerReady:subscribe(function(payload)
    MainPanel.mount(payload.component, {
      solving_enabled = SolvingOrchestrator.settings.enabled:get(),
      map_visible = Map.settings.visible:get(),
      onOpenSettings = function()
        settings_dialog.open()
      end,
      onSolvingChanged = function(enabled)
        SolvingOrchestrator.settings.enabled:set(enabled)
        SolvingOrchestrator.setActive(enabled)
      end,
      onMapChanged = function(visible)
        Map.settings.visible:set(visible)
        Map.get():setVisible(visible)
      end
    })
  end)
end

return {
  main = main
}
