-- SliderSolver.lua
local zyklib                 = require("zyklib")
local RegionGraph            = require("cluetrainer/puzzles/sliders/pdb/RegionChain")
local pdb_data               = require("cluetrainer/puzzles/sliders/pdb/data/Pdb")
local SliderState            = require("cluetrainer/puzzles/sliders/SliderState")
local PdbSolver              = require("cluetrainer/puzzles/sliders/pdb/PdbSolver")

---@class cluetrainer.ActiveSliderSolver
local active_slider_solver   = {}
active_slider_solver.__index = active_slider_solver


--- Downloads a pattern database from cluetrainer.app
---@return zyklib.async.Promise<string>
local function downloadFiles()
  local promise = zyklib.async.Promise.new()

  --- We cannot use an async-await pattern here because it triggers a client crash, so we use recursion with a delayed call instead.
  local function recur(chunks)
    if #chunks == 9 then
      promise:resolve(table.concat(chunks))
    else
      zyklib.http.get(Plugin.urls["cluetrainer"], "/data/sliderpdb/mtm_huge/v0chunk0" .. #chunks .. ".bin")
          :onCompletion(function(result, data)
            log("Downloaded chunk " .. #chunks)
            table.insert(chunks, data)

            --- The following is a bug workaround. Recursing directly triggers a client crash
            zyklib.game_events.native.Logic:once(function()
              recur(chunks)
            end)
          end)
    end
  end

  recur({})

  return promise
end

local pdb_data = downloadFiles()

local graph = pdb_data:map(function(data)
  return RegionGraph.new(RegionGraph.parseTables(data), true)
end)

---@param interface ui.Interface
local function start(interface)

end

local function endActive()

end

local process = zyklib.game_events.native.ServerLogic
    :subscribeSuspended(function()
      log(SliderState.getSliderState())

      if graph:isSettled() then
        log("Graph is settled, solving...")
        PdbSolver.solve(SliderState.getSliderState(), graph:get())
      else
        log("Graph is not settled yet")
      end

      --local state = SliderState.getSliderState()

      -- log(PdbSolver.solve(state, graph))
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
  if payload.new ~= nil then
    log("Interface opened")
    if graph:isSettled() then
      log("Graph is settled, solving...")
      PdbSolver.solve(SliderState.getSliderState(), graph:get())
    else
      log("Graph is not settled yet")
    end
  else
    --process:setActive(false)
  end
end)


local slider_solver = {}

function slider_solver.setActive(active)
  handler:setActive(active)
end

return slider_solver
