local api_util = require "zyklib/api_util"

---@class zyklib.LocHighlight
---@field filter LocListFilterSettings
---@field render fun(npc: LocEntity): ShapeListDrawSettings
---@field instances table<LocEntity, {shape_instance: ShapeInstance}>
---@field active boolean

local LocHighlight = {}
LocHighlight.__index = LocHighlight

---@type table<zyklib.LocHighlight, boolean>
local instances = {}
local instanceCount = 0

---@type zyklib.ApiEventHandler?
local draw_handler = nil

local function update_handler()
  if instanceCount > 0 and draw_handler == nil then
    -- Handler does not exist, but there are active instances, so we create it.
    draw_handler = api_util.subscribe_managed(Event.ServerLogic, function(event)
      for instance, _ in pairs(instances) do
        local locs = LocList.Filter(instance.filter)

        local active_locs = {}

        local create_count = 0

        for _, loc in ipairs(locs) do
          active_locs[api_util.loc_identity(loc)] = true

          if instance.instances[api_util.loc_identity(loc)] == nil then
            create_count = create_count + 1
            local settings = instance.render(loc)

            local shape_instance = api_util.unique_shape_instance(settings.shapeData)

            shape_instance:SetShapeData(settings.shapeData)

            if settings.translation ~= nil then
              shape_instance.translation = settings.translation
            end
            if settings.scale ~= nil then
              shape_instance.scale = settings.scale
            end
            if settings.colour ~= nil then
              shape_instance.colour = settings.colour
            end

            instance.instances[api_util.loc_identity(loc)] = {
              shape_instance = shape_instance,
            }
          end
        end

        local destroy_count = 0
        for loc_id, entry in pairs(instance.instances) do
          if not active_locs[loc_id] then
            entry.shape_instance:Destroy()
            instance.instances[loc_id] = nil
            destroy_count = destroy_count + 1
          end
        end
      end
    end)
  elseif instanceCount == 0 and draw_handler ~= nil then
    -- Handler does exist, but there are no active instances, so we remove it.
    draw_handler.cancel()
    draw_handler = nil
  end
end

---@param filter LocListFilterSettings
---@param render fun(npc: LocEntity): ShapeListDrawSettings
---@return zyklib.LocHighlight
function LocHighlight.new(filter, render)
  ---@type zyklib.LocHighlight
  local self = setmetatable({}, LocHighlight)
  self.filter = filter
  self.render = render
  self.instances = {}
  self.active = false

  return self
end

---Deactivates this LocHighlight and removes it from the list of active highlights. This will stop it from being drawn.
---@return self
function LocHighlight:deactivate()
  if self.active then
    self.active = false
    instances[self] = nil
    instanceCount = instanceCount - 1

    update_handler()
  end

  return self
end

---Activates this LocHighlight and adds it to the list of active highlights. This will cause it to be drawn.
---@return self
function LocHighlight:activate()
  if not self.active then
    self.active = true
    instances[self] = true
    instanceCount = instanceCount + 1

    update_handler()
  end

  return self
end

return LocHighlight
