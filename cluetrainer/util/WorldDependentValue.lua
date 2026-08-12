local api_util              = require "util/api_util"
local lua_util              = require "util/lua_util"

---A WorldDependentValue is a value that depends on a certain part of the world being loaded.
---@generic T
---@class WorldDependentValue
---@field value T?
---@field created boolean
---@field bounds Rect Bounds in map square coordinate.
---@field generator fun(): T
local WorldDependentValue   = {}
WorldDependentValue.__index = WorldDependentValue

local instances             = {}

---@param bounds Rect
---@return boolean
local function boundsAvailable(bounds)
  if bounds == nil then return false end

  local _, a = World.GetGroundHeight(0, bounds.x * 64 * 512 + 256, bounds.y * 64 * 512 + 256)
  local _, b = World.GetGroundHeight(0, ((bounds.x + bounds.width) * 64 - 1) * 512 + 256,
    ((bounds.y + bounds.height) * 64 - 1) * 512 + 256)

  return a and b
end

---@generic T
---@param self WorldDependentValue<T>
local function update(self)
  if not self.created and boundsAvailable(self.bounds) then
    self.value = self.generator()
    self.created = true
    self.generator = nil
  end
end

---@generic T
---@param bounds Rect
---@param generator fun(): T
---@return WorldDependentValue<T>
function WorldDependentValue.new(bounds, generator)
  ---@type WorldDependentValue
  local instance = setmetatable({
    value = nil,
    bounds = bounds,
    created = false,
    generator = generator
  }, WorldDependentValue)

  update(instance)

  table.insert(instances, instance)

  return instance
end

---@generic T
---@param value T
---@return WorldDependentValue<T>
function WorldDependentValue.filled(value)
  ---@type WorldDependentValue
  local instance = setmetatable({
    value = value,
    bounds = nil,
    created = false,
    generator = nil
  }, WorldDependentValue)

  return instance
end

---@generic T
---@param self WorldDependentValue<T>
---@param f fun(shape: T)
function WorldDependentValue:maybeTap(f)
  update(self)

  if self.value ~= nil then
    f(self.value)
  end
end

function WorldDependentValue:map(f)
  update(self)

  if self.created then
    return WorldDependentValue.filled(f(self.value))
  else
    local base = self.generator

    return WorldDependentValue.new(self.bounds, function()
      return f(base())
    end)
  end
end

local listener = api_util.subscribe_managed(Event.ServerLogic, function(event)
  for i = #instances, 1, -1 do
    local value = instances[i]
    update(value)

    if value.created then
      -- Remove completed instance to avoid unnecessary updates.
      table.remove(instances, i)
    end
  end
end)

return WorldDependentValue
