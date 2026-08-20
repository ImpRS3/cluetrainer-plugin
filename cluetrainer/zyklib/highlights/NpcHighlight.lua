local api_util = require "zyklib/api_util"

---@class zyklib.NpcHighlight
---@field filter fun(npc: NPCEntity): boolean
---@field render fun(npc: NPCEntity): ShapeListDrawSettings
---@field active boolean

local NpcHighlight = {}
NpcHighlight.__index = NpcHighlight

---@type table<zyklib.NpcHighlight, boolean>
local instances = {}
local instanceCount = 0

---@type zyklib.ApiEventHandler?
local draw_handler = nil

local function update_draw_handler()
  if instanceCount > 0 and draw_handler == nil then
    -- Handler does not exist, but there are active instances, so we create it.
    draw_handler = api_util.subscribe_managed(Event.EntityDraw, function(event)
      if (event.entityType ~= EntityType.NPC) then return true end
      local npc = event.npcEntity

      -- Ignore all NPCs without a display name. TODO: Is this sensible as a default?
      if npc.displayName == "" then return true end

      for instance in pairs(instances) do
        if instance.filter(npc) then
          ShapeList.Draw(instance.render(npc))
        end
      end
      return true
    end)
  elseif instanceCount == 0 and draw_handler ~= nil then
    -- Handler does exist, but there are no active instances, so we remove it.
    draw_handler.cancel()
    draw_handler = nil
  end
end

---@param filter fun(npc: NPCEntity): boolean
---@param render fun(npc: NPCEntity): ShapeListDrawSettings
---@return zyklib.NpcHighlight
function NpcHighlight.new(filter, render)
  ---@type zyklib.NpcHighlight
  local self = setmetatable({}, NpcHighlight)
  self.filter = filter
  self.render = render
  self.active = false

  return self
end

---Deactivates this NPC highlight and removes it from the list of active highlights. This will stop it from being drawn.
---@return self
function NpcHighlight:deactivate()
  if self.active then
    self.active = false
    instances[self] = nil
    instanceCount = instanceCount - 1

    update_draw_handler()
  end

  return self
end

---Activates this NPC hightlight and adds it to the list of active highlights. This will cause it to be drawn.
---@return self
function NpcHighlight:activate()
  if not self.active then
    self.active = true
    instances[self] = true
    instanceCount = instanceCount + 1

    update_draw_handler()
  end

  return self
end

return NpcHighlight
