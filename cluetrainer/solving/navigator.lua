local api_util = require "util/api_util"
local PathMesh = require "model/PathMesh"
local lua_util = require "util/lua_util"


---@class PathStepEntity
---@field step Path.Step
---@field geometry WorldDependentValue<ShapeInstance>

---@class Navigator
---@field path PathStepEntity[]
---@field logic_handler Handler
local Navigator = {}
Navigator.__index = Navigator

---comment
---@param path Path
function findProgress(path)
  ---@type CoordGrid
  local true_tile = Player.GetEntity().routeEnd

  for i = #path, 1, -1 do
    local step = path[i]

    if step.type == "ability" then
      step.to = step.from
    end
  end
end

---@return Navigator
function Navigator.new()
  ---@type Navigator
  local self = setmetatable({}, Navigator)

  self.path = {}

  self.logic_handler = api_util.subscribe_managed(Event.ServerLogic, function(event)
    --- If changed, check if new components can be rendered.

    for _, value in ipairs(self.path) do
      value.geometry:maybeTap(function(instance)
        --- TODO: Find progress along path and fade completed steps.
        ---
      end)
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
      }):map(
        function(
        ---@param mesh MutableMesh
            mesh)
          if mesh:triangle_count() == 0 and mesh:line_count() == 0 then
            return nil
          end

          return api_util.unique_shape_instance(mesh:shapeData())
        end)
    }
  end)
end

function Navigator:clear()
  for _, value in ipairs(self.path) do
    if value ~= nil and value.geometry ~= nil then
      value.geometry:maybeTap(function(instance)
        if instance ~= nil then
          instance:Destroy()
        end
      end)
    end
  end

  self.path = {}
end

Navigator.instance = Navigator.new()

return Navigator
