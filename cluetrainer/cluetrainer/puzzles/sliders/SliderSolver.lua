local zyklib = require("zyklib")

---@class cluetrainer.ActiveSliderSolver
local active_slider_solver = {}
active_slider_solver.__index = active_slider_solver


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

zyklib.game_events.native.ServerLogic
    :subscribe(function()
      -- testComponent("SLIDE_PUZZLE__CHECK_BUTTON_LAYER")
      -- testComponent("SLIDE_PUZZLE__KEYBOARD_CONTROL")
      -- testComponent("SLIDE_PUZZLE__RESET_LAYER")
      -- testComponent("SLIDE_PUZZLE__RESET_GRAPHIC")
      -- testComponent("SLIDE_PUZZLE__PUZZLE_RESET_TEXT")
      -- testComponent("SLIDE_PUZZLE__PUZZLE_COMPLETE_LAYER2")
      -- testComponent("SLIDE_PUZZLE__UP_LAYER")
      -- testComponent("SLIDE_PUZZLE__DOWN_LAYER")
      -- testComponent("SLIDE_PUZZLE__LEFT_LAYER")
      -- testComponent("SLIDE_PUZZLE__RIGHT_LAYER")
      -- testComponent("SLIDE_PUZZLE__ELITE_VARS")
      -- testComponent("SLIDE_PUZZLE__UNIVERSE")
      -- testComponent("SLIDE_PUZZLE__LISTENER_LAYER")
      -- testComponent("SLIDE_PUZZLE__EXTRA_1_VARS")
      -- testComponent("SLIDE_PUZZLE__HARD_VARS")
      -- testComponent("SLIDE_PUZZLE__PUZZLEBACK")
      -- testComponent("SLIDE_PUZZLE__PUZZLETOP")
      -- testComponent("SLIDE_PUZZLE__PUZZLE_CHECK")
      -- testComponent("SLIDE_PUZZLE__PUZZLE_LAYER")
      -- testComponent("SLIDE_PUZZLE__PUZZLE_HINT")
      -- testComponent("SLIDE_PUZZLE__TRAIL_CLOSE")
      -- testComponent("SLIDE_PUZZLE__PUZZLE_WRAPPER")
      -- testComponent("SLIDE_PUZZLE__PUZZLE_HINT_SCROLL")
      -- testComponent("SLIDE_PUZZLE__PUZZLE_HINT_TEXT")
      -- testComponent("SLIDE_PUZZLE__INFO_PANEL")
      -- testComponent("SLIDE_PUZZLE__KEYBOARD_CONTROL_BUILD")
      -- testComponent("SLIDE_PUZZLE__KEYBOARD_CONTROL_CLICK")
      -- testComponent("SLIDE_PUZZLE__INFO_PANEL_BACKGROUND")
      -- testComponent("SLIDE_PUZZLE__INFO_PANEL_CONTENT")
      -- testComponent("SLIDE_PUZZLE__INFO_PANEL_BORDER")
      -- testComponent("SLIDE_PUZZLE__CHECK_BUTTON_ON_LAYER")
      -- testComponent("SLIDE_PUZZLE__CHECK_BUTTON_OVER_LAYER")
      -- testComponent("SLIDE_PUZZLE__CHECK_BUTTON_HIT_LAYER")
      -- testComponent("SLIDE_PUZZLE__CHECK_BUTTON_SELECTED_LAYER")
      -- testComponent("SLIDE_PUZZLE__CHECK_BUTTON_ACTIVE_LAYER")
      -- testComponent("SLIDE_PUZZLE__CHECK_BUTTON_DISABLED_LAYER")
      -- testComponent("SLIDE_PUZZLE__CHECK_BUTTON_TEXT_LAYER")
      -- testComponent("SLIDE_PUZZLE__CHECK_BUTTON_TEXT")
      -- testComponent("SLIDE_PUZZLE__RESET_CONFIRM_POPUP")
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
  log(payload)
end)


local slider_solver = {}

function slider_solver.setActive(active)
  handler:setActive(active)
end

return slider_solver
