local api_util = require "util/api_util"
---@class zyklib.NpcHighlight
---@field filter fun(npc: NPCEntity): boolean
---@field render fun(npc: NPCEntity): ShapeListDrawSettings
---@field active boolean

local NpcHighlight = {}
NpcHighlight.__index = NpcHighlight

---@type table<zyklib.NpcHighlight, boolean>
local instances = setmetatable({}, { __mode = "k" })
local instanceCount = 0

---@type zyklip.ApiEventHandler?
local draw_handler = nil

local function update()
  if instanceCount > 0 and draw_handler == nil then
    draw_handler = api_util.subscribe_managed(Event.EntityDraw, function(event)
      if (event.entityType ~= EntityType.NPC) then return true end
      local npc = event.npcEntity

      if npc.displayName == "" then return true end

      for instance in pairs(instances) do
        if instance.filter(npc) then
          ShapeList.Draw(instance.render(npc))
        end
      end
      return true
    end)
  elseif instanceCount == 0 and draw_handler ~= nil then
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
  self.active = true

  instances[self] = true
  instanceCount = instanceCount + 1

  update()

  return self
end

function NpcHighlight:destroy()
  self.active = false
  instances[self] = nil
  instanceCount = instanceCount - 1

  update()
end

return NpcHighlight
