local lua_util = require "util/lua_util"
local easy_methods = require "data/easy_methods"
local medium_methods = require "data/medium_methods"
local hard_methods = require "data/hard_methods"
local compass_methods = require "data/compass_methods"
local scan_methods = require "data/scan_methods"
local master_methods = require "data/master_methods"
local tetracompass_methods = require "data/tetracompass_methods"
local Navigator = require "solving/navigator"

local packs = {
  easy_methods,
  medium_methods,
  hard_methods,
  compass_methods,
  scan_methods,
  master_methods,
  tetracompass_methods
}

---@class State
---@field step Step
---@field progressIndex integer


---@class Orchestrator
---@field state State?
---@field history State[]
local orchestrator = {
  state = nil,
  history = {},
}

---@param tier ClueTier
---@return integer
local function getProgress(tier)
  ---@type {[ClueTier]: string}
  local map = {
    easy = "TRAIL_STEPS_EASY",
    medium = "TRAIL_STEPS_MEDIUM",
    hard = "TRAIL_STEPS_HARD",
    elite = "TRAIL_STEPS_ELITE",
    master = "TRAIL_STEPS_MASTER"
  }

  return var.VarPlayer[map[tier]].value
end

---@param step Step
---@return Method?
local function resolveMethod(step)
  for _, pack in ipairs(packs) do
    for _, method in ipairs(pack.methods) do
      if method["for"].clue == step.id then
        return method
      end
    end
  end

  return nil
end

---
---@param step Step
function orchestrator:setStep(step)
  local progress = getProgress(step.tier)

  -- Discard duplicate
  if self.state and self.state.step == step and self.state.progressIndex == progress then
    return
  end

  self.state = {
    step = step,
    progressIndex = getProgress(step.tier)
  }

  table.insert(self.history, self.state)

  log(self.state)

  local method = resolveMethod(step)

  if method ~= nil then
    if method.type == "general_path" then
      Navigator.instance:set(method.main_path)
    elseif method.type == "scantree" then

    end
  end
end

return orchestrator
