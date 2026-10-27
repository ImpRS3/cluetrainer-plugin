-- navigator.lua
local PathMesh    = require "cluetrainer/model/PathMesh"
local array       = require "zyklib/array"
local zyklib      = require "zyklib"

---@class PathStepEntity
---@field step Path.Step
---@field geometry zyklib.Highlight

---@class Navigator : zyklib.disposable.IDisposable
---@field path PathStepEntity[]
---@field logic_handler zyklib.reactive.EventHandler
local Navigator   = {}
Navigator.__index = Navigator

local function isCompleted(step)
  ---@type CoordGrid
  local true_tile = Player.GetEntity().routeEnd

  ---@type TileCoordinates
  local tile = { x = true_tile.x, y = true_tile.z, level = true_tile.level }

  local function distance(a, b)
    return math.abs(a.x - b.x) + math.abs(a.y - b.y)
  end

  if step.type == "ability" then
    return distance(step.from, tile) > distance(step.to, tile)
  elseif step.type == "run" then
    local start = step.waypoints[1]
    local finish = step.waypoints[#step.waypoints]

    return distance(start, tile) >= distance(start, finish) and distance(start, tile) > distance(finish, tile)
  end

  return false
end

---@return Navigator
function Navigator.new()
  ---@type Navigator
  local self = setmetatable({}, Navigator)

  self.path = {}

  self.logic_handler = zyklib.game_events.native.ServerLogic:subscribe(function(event)
    self:update_progress()
  end)

  return self
end

function Navigator:update_progress()
  for _, value in ipairs(self.path) do
    local completed = isCompleted(value.step)

    value.geometry:setColour(completed and 0x80808080 or 0xFFFFFFFF)
    value.geometry:setIgnoreDepth(not completed)
  end
end

--- Set the current path to the given path segments.
---@param path Path.Step[]
function Navigator:set(path)
  self:clear()

  self.path = array.map(path, function(step, index)
    return {
      step = step,
      geometry = PathMesh.buildStepMesh(step, {
            context_path = path,
            i = index
          })
          :setIgnoreDepth(true) -- TODO: Only ignore depth if on the same level as the player and is not completed, otherwise it looks weird
          :activate()
    }
  end)

  self:update_progress()
end

function Navigator:clear()
  for _, value in ipairs(self.path) do
    value.geometry:deactivate()
  end

  self.path = {}
end

function Navigator:dispose()
  self:clear()
  if self.logic_handler then
    self.logic_handler:cancel()
    self.logic_handler = nil
  end
end

return Navigator
