local api_util = require "zyklib/api_util"
local PathMesh = require "model/PathMesh"
local lua_util = require "zyklib/lua_util"


---@class PathStepEntity
---@field step Path.Step
---@field geometry zyklib.TerrainHighlight

---@class Navigator
---@field path PathStepEntity[]
---@field logic_handler zyklib.ApiEventHandler
local Navigator = {}
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

  self.logic_handler = api_util.subscribe_managed(Event.ServerLogic, function(event)
    --- If changed, check if new components can be rendered.

    for _, value in ipairs(self.path) do
      value.geometry.instance.colour = isCompleted(value.step) and 0x80808080 or 0xFFFFFFFF
    end
  end)

  return self
end

--- Set the current path to the given path segments.
---@param path Path.Step[]
function Navigator:set(path)
  self:clear()

  --- TODO: Only include steps that actually have a visual representation
  self.path = lua_util.map(path, function(step, index)
    return {
      step = step,
      geometry = PathMesh.buildStepMesh(step, {
        context_path = path,
        i = index
      })
    }
  end)
end

function Navigator:clear()
  for _, value in ipairs(self.path) do
    if value ~= nil then
      value.geometry.instance:Destroy()
    end
  end

  self.path = {}
end

Navigator.instance = Navigator.new()

return Navigator
