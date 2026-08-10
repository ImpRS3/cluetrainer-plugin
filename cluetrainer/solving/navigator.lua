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

---@return Navigator
function Navigator.new()
  ---@type Navigator
  local self = setmetatable({}, Navigator)

  self.path = {}

  self.logic_handler = api_util.subscribe_managed(Event.ServerLogic, function(event)
    --- If changed, check if new components can be rendered.

    for _, value in ipairs(self.path) do
      value.geometry:maybeTap(function(instance)
        instance.colour = 0xFFFFFF80
      end)
    end
  end)

  return self
end

local i = 0

--- Set the current path to the given path segments.
---@param path Path.Step[]
function Navigator:set(path)
  self:clear()

  self.path = lua_util.map(path, function(step, index)
    return {
      step = step,
      geometry = PathMesh.buildStepMesh(step, {
        context_path = path,
        i = index
      }):map(
        function(
        ---@type MutableMesh
            mesh)
          local s = mesh:finalize():shapeData()
          local shape_data = ShapeData.new()

          shape_data.lines = s.lineIndices
          shape_data.positions = s.positions
          shape_data.rgba = s.colors
          shape_data.tris = s.triangleIndices

          local instance = ShapeList.CreateInstance("auniquename" .. i)
          i = i + 1

          if instance ~= nil then
            instance:SetShapeData(shape_data)
          end

          return instance
        end)
    }
  end)
end

function Navigator:clear()
  log(self)
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
