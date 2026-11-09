-- SliderSolvingTask.lua

local zyklib = require("zyklib")

---@class ct.sliders.SliderSolvingTask : zyklib.async.Task
---@field start_state ct.sliders.SliderState
---@field best_solution integer[]?
local SliderSolvingTask = setmetatable({}, { __index = zyklib.async.Task })
SliderSolvingTask.__index = SliderSolvingTask

---@param start_state ct.sliders.SliderState
---@return ct.sliders.SliderSolvingTask
function SliderSolvingTask.new(start_state)
  ---@type ct.sliders.SliderSolvingTask
  local self
  -- Resolved lazily, so overrides in subclasses are picked up once they re-set the metatable.
  self = zyklib.async.Task.new(function()
    return self:implementation()
  end)
  setmetatable(self, SliderSolvingTask)
  ---@cast self ct.sliders.SliderSolvingTask

  self.start_state = start_state
  return self
end

---@protected
---@param solution integer[]
function SliderSolvingTask:registerSolution(solution)
  if self.best_solution == nil or #solution < #self.best_solution then
    self.best_solution = { table.unpack(solution) }
  end
end

function SliderSolvingTask:implementation()
  error("SliderSolvingTask.implementation must be overridden")
end

return SliderSolvingTask
