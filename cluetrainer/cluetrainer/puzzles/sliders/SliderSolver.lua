local zyklib                 = require("zyklib")
local RegionGraph            = require("cluetrainer/puzzles/sliders/pdb/RegionChain")
local pdb_data               = require("cluetrainer/puzzles/sliders/pdb/data/Pdb")
local SliderState            = require("cluetrainer/puzzles/sliders/SliderState")
local PdbSolver              = require("cluetrainer/puzzles/sliders/pdb/PdbSolver")

---@class cluetrainer.ActiveSliderSolver
local active_slider_solver   = {}
active_slider_solver.__index = active_slider_solver

local graph                  = RegionGraph.new(RegionGraph.parseTables(pdb_data.pdb), true)

---@param interface ui.Interface
local function start(interface)

end

local function endActive()

end

local function testComponent(comp)
  local component = ui.Interfaces:GetComponent(id.Component[comp])
  if component ~= nil then
    log(
      comp,
      { component.visible, component.visibleGlobal, component.clickthrough, component.hidden, component.stylesheetID,
        component.alpha }
    )
  else
    log(comp, nil)
  end
end

local process = zyklib.game_events.native.ServerLogic
    :subscribeSuspended(function()
      local state = SliderState.getSliderState()

      log(PdbSolver.solve(state, graph))
    end)

local interface_observable = zyklib.game_events.native.ServerLogic
    :map(function()
      local comp = ui.Interfaces:GetComponent(id.Component.SLIDE_PUZZLE__UNIVERSE)

      if comp ~= nil and comp.parent ~= nil then
        return comp
      else
        return nil
      end
    end)
    :toObservable(nil)

local handler = interface_observable:subscribeSuspended(function(payload)
  process:setActive(payload.new ~= nil)
end)


local slider_solver = {}

function slider_solver.setActive(active)
  handler:setActive(active)
end

return slider_solver
