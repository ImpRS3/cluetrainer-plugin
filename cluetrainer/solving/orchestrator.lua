local lua_util = require "util/lua_util"
local methods = require "data/hard_methods"
local Navigator = require "solving/navigator"

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
local function resolveMethod(step)
  local method = lua_util.find(methods.methods, function(method) return method["for"].clue == step.id end)

  return method
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
