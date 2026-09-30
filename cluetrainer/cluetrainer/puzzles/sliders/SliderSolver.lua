local zyklib = require("zyklib")

---@class cluetrainer.ActiveSliderSolver
local active_slider_solver = {}
active_slider_solver.__index = active_slider_solver


---@type {canvas: ui.Canvas}?
local active_puzzle = nil

local refresh_handler = zyklib.ewent.Native.Logic:subscribeSuspended(function()
  -- TODO: Update overlay if required etc.
end)


local handler = zyklib.ewent.Native.ServerLogic:subscribe(function(event)
  local interface = ui.Interfaces:GetInterface(id.Interface.SLIDE_PUZZLE)

  refresh_handler:setSuspended(interface == nil)

  if not interface then
    if active_puzzle ~= nil then
      active_puzzle.canvas:Clear()
      active_puzzle = nil
    end

    return
  end

  local content = ui.Interfaces:GetComponent(id.Component.SLIDE_PUZZLE__PUZZLE_WRAPPER)
  ---@cast content ui.ComponentCollection

  if active_puzzle == nil and content ~= nil then

  end
end)

local slider_solver = {}

function slider_solver.setActive(active)
  handler.setSuspended(not active)
end

return slider_solver
