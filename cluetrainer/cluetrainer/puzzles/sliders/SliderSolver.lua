-- SliderSolver.lua
local zyklib                 = require("zyklib")
local RegionGraph            = require("cluetrainer/puzzles/sliders/pdb/RegionChain")
local SliderState            = require("cluetrainer/puzzles/sliders/SliderState")
local PdbSolver              = require("cluetrainer/puzzles/sliders/pdb/PdbSolver")

---@class cluetrainer.ActiveSliderSolver
local active_slider_solver   = {}
active_slider_solver.__index = active_slider_solver


--- Downloads a pattern database from cluetrainer.app
---@return zyklib.async.Promise<string>
local function downloadFiles()
  -- FIXME: Cache disabled due to a bug in PersistentDB regarding embedded nulls
  -- local cached = PersistentDB:Get("workaround_sliderpdb_mtm_huge_v0")

  -- if cached ~= nil and cached.value ~= nil and cached.value ~= "" then
  --   log("Retrieved from cache")
  --   return zyklib.async.Promise.resolved(cached.value)
  -- end

  local cached = ""

  local promise = zyklib.async.Promise.new()

  --- We cannot use an async-await pattern here because it triggers a client crash, so we use recursion with a delayed call instead.
  local function recur(chunks)
    if #chunks == 9 then
      log("All chunks downloaded")
      local final_value = table.concat(chunks)

      -- Cache pdb for next time. FIXME: Disabled for now
      -- PersistentDB:Set("workaround_sliderpdb_mtm_huge_v0", { value = final_value })

      promise:resolve(final_value)
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

---@type cluetrainer.sliders.SliderSolvingTask?
local task = nil

local handler = interface_observable:subscribeSuspended(function(payload)
  if payload.new ~= nil then
    log("Interface opened")

    if graph:isSettled() then
      log("Graph is settled, solving...")
      task = PdbSolver.new(SliderState.getSliderState(), graph:get()):start()
    else
      log("Graph is not settled yet")
    end
  else
    if task ~= nil then
      task:cancel()
      task = nil
    end
  end
end)


local slider_solver = {}

function slider_solver.setActive(active)
  handler:setActive(active)
end

return slider_solver
