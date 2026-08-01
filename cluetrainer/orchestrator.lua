---@class State
---@field step Step
---@field progressIndex integer


---@class Orchestrator
---@field state State
local orchestrator = {

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

---
---@param step Step
function orchestrator:setStep(step)
  self.step = step
  self.progressIndex = 1

  self.state = {
    step = step,
    progressIndex = getProgress(step.tier)
  }
end

return orchestrator
