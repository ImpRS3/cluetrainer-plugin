local UniqueNameGenerator = require "zyklib/UniqueNameGenerator"
local api_util = {}

---@class zyklib.ApiEventHandler
---@field id string
---@field cancel fun(): nil


local handler_name_generator = UniqueNameGenerator.new("api_util_handler_")

---@generic T, RetT
---@param event EventSubscription<T, RetT>
---@param handler fun(event: T): RetT
---@return zyklib.ApiEventHandler
function api_util.subscribe_managed(event, handler)
  while true do
    local handler_name = handler_name_generator:next()

    local success = event.Subscribe(handler_name, handler)

    if (success) then
      return {
        id = handler_name,
        cancel = function()
          event.Unsubscribe(handler_name)
        end
      }
    end
  end
end

local shape_instance_name_generator = UniqueNameGenerator.new("shape_instance_")

---
---@param shape_data ShapeData?
---@return ShapeInstance
function api_util.unique_shape_instance(shape_data)
  local instance = ShapeList.CreateInstance(shape_instance_name_generator:next())
  ---@cast instance ShapeInstance

  if shape_data ~= nil then
    instance:SetShapeData(shape_data)
  end

  return instance
end

---Creates a color value from red, green, blue, and alpha components
---@param r integer
---@param g integer
---@param b integer
---@param a integer
---@return integer
function api_util.color_rgba(r, g, b, a)
  return (r & 0xFF) << 24 | (g & 0xFF) << 16 | (b & 0xFF) << 8 | (a & 0xFF)
end

---@param loc LocEntity
---@return integer
function api_util.loc_identity(loc)
  return ((loc.configID * 12800 + loc.coordGrid.x) * 12800 + loc.coordGrid.z) * 4 + loc.coordGrid.level
end

---Takes any value and turns it into a plain lua value.
---Particularly, this handles userdata values by calling all getter functions on the metatable and returning a table of the results.
---@param value userdata | table | boolean | number | string | nil
---@return table | boolean | number | string | nil
function api_util.to_plain_table(value)
  local value_type = type(value)

  -- Values directly supported by most serializers.
  if value_type == "nil"
      or value_type == "boolean"
      or value_type == "number"
      or value_type == "string"
  then
    return value
  end

  if value_type == "table" then
    local result = {}

    for key, child in pairs(value) do
      local plain_value = api_util.to_plain_table(child)

      result[key] = plain_value
    end

    return result
  end

  if value_type == "userdata" then
    local result = {}
    local metatable = getmetatable(value)

    for name, getter in pairs(metatable) do
      if type(name) == "string"
          and name:sub(1, 2) ~= "__"
          and type(getter) == "function"
      then
        -- Assumes getter functions are methods: getter(value).
        local ok, field_value = pcall(function()
          return value[name]
        end)

        if ok then
          result[name] = api_util.to_plain_table(field_value)
        end
      end
    end

    return result
  end

  return nil
end

---Resolves the ground height at a given coordinate, returning a Vector3 with the original x and z coordinates and the resolved y coordinate.
---@param coords CoordFine
---@param kind HeightOffsetType?
---@return Vector3
function api_util.resolve_ground_height(coords, kind)
  kind = kind or HeightOffsetType.GROUND_DECOR

  local height, success = World.GetGroundHeight(coords.level, coords.x, coords.z, kind)

  if not success then
    return Vector3.new(coords.x, coords.y, coords.z)
  end

  return Vector3.new(coords.x, height, coords.z)
end

return api_util
