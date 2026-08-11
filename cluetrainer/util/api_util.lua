local UniqueNameGenerator = require "util/UniqueNameGenerator"
local api_util = {}

---@class Handler
---@field id string
---@field cancel fun(): nil

---@type integer
local handler_counter = 0

---@generic T, RetT
---@param event EventSubscription<T, RetT>
---@param handler fun(event: T): RetT
---@return Handler
function api_util.subscribe_managed(event, handler)
  while true do
    handler_counter = handler_counter + 1
    local handler_name = "handler_" .. handler_counter

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

return api_util
