local clue_detector         = require "cluetrainer/clue_detector"
local CompassSolver         = require "cluetrainer/solving/CompassSolver"
local EmoteClueSolver       = require "cluetrainer/solving/EmoteClueSolver"
local SimpleClueSolver      = require "cluetrainer/solving/SimpleClueSolver"
local ClueStateInterface    = require "cluetrainer/interfaces/cluestate/cluestate"

---@class ct.solving.SolvingOrchestrator : zyklib.disposable.IDisposable
---@field private clue_state ct.ClueStateInterface
---@field private active_solver ct.ActiveClueSolver?
---@field private clue_detection_handler zyklib.reactive.EventHandler
local SolvingOrchestrator   = {}
SolvingOrchestrator.__index = SolvingOrchestrator

---@type ct.solving.SolvingOrchestrator?
local instance              = nil

---@private
---@return ct.solving.SolvingOrchestrator
function SolvingOrchestrator.new()
  local self = setmetatable({}, SolvingOrchestrator)

  self.clue_state = ClueStateInterface.new()

  self.clue_state.reset_event:subscribe(function()
    self:reset()
  end)

  self.active_solver = nil

  self.clue_detection_handler = clue_detector.clue_detected_event:subscribe(function(clue)
    self:onClueDetected(clue)
  end)

  return self
end

function SolvingOrchestrator:reset()
  if self.active_solver ~= nil then
    self.active_solver:dispose()
    self.active_solver = nil
  end

  self.clue_state:setClue(nil)
  self.clue_state:clearActions()
end

---@param clue Step?
function SolvingOrchestrator:onClueDetected(clue)
  if self.active_solver ~= nil and (clue == nil or self.active_solver.clue ~= clue) then
    self.active_solver:dispose()
    self.active_solver = nil
  end

  if clue ~= nil then
    self.clue_state:setClue(clue)
  end

  self.active_solver = (function()
    if clue == nil then
      return nil
    elseif clue.type == "compass" then
      return CompassSolver.new(clue, self.clue_state)
    elseif clue.type == "emote" then
      return EmoteClueSolver.new(clue, self.clue_state)
    elseif clue.type == "scan" then
      --return ScanClueSolver.new(clue)
    else
      return SimpleClueSolver.new(clue, self.clue_state)
    end
  end)()
end

function SolvingOrchestrator:dispose()
  self.clue_detection_handler:dispose()

  if self.active_solver ~= nil then
    self.active_solver:dispose()
    self.active_solver = nil
  end

  self.clue_state:dispose()
end

---Constructs the singleton instance if active, or disposes it otherwise.
---@param active boolean
function SolvingOrchestrator.setActive(active)
  if active then
    if instance == nil then instance = SolvingOrchestrator.new() end
  elseif instance ~= nil then
    instance:dispose()
    instance = nil
  end
end

return SolvingOrchestrator
