-- TeleportSpot.lua
local array = require "zyklib/array"

---@class cluetrainer.TeleportSpot
---@field group TeleportGroup
---@field spot TeleportSpot
---@field access TeleportAccess?
---@field props TeleportProps
local TeleportSpot = {}
TeleportSpot.__index = TeleportSpot

local PROP_KEYS = { "menu_ticks", "animation_ticks", "code", "hidden", "cache_data" }

local DEFAULT_PROPS = {
  animation_ticks = 0,
  menu_ticks = 0,
  code = "",
}

---@param access TeleportAccess
local function teleport_access_is_anywhere(access)
  return access.type == "spellbook" or (access.type == "item" and access.area_restriction == nil)
end

---Combines props, where earlier entries have higher priority. Nil entries are skipped.
---@param props (TeleportProps|nil)[]
---@param count integer
---@return TeleportProps
local function combine_props(props, count)
  local result = {}

  for _, key in ipairs(PROP_KEYS) do
    for i = 1, count do
      local p = props[i]
      if p ~= nil and p[key] ~= nil then
        result[key] = p[key]
        break
      end
    end
  end

  return result
end

---@param group TeleportGroup
---@param spot TeleportSpot
---@param access TeleportAccess?
---@return cluetrainer.TeleportSpot
function TeleportSpot.new(group, spot, access)
  local self = setmetatable({}, TeleportSpot)

  self.group = group
  self.spot = spot
  self.access = access

  local visual_access = access or array.find(group.access, function(value)
    return teleport_access_is_anywhere(value)
  end)

  -- Priority: access x spot props, per-access props, per-spot props, per-group props, defaults.
  self.props = combine_props({
    access and access.per_spot_props and access.per_spot_props[spot.id] or nil,
    visual_access,
    spot,
    group,
    DEFAULT_PROPS,
  }, 5)

  return self
end

---@return string
function TeleportSpot:hover()
  local group_name, spot_name = self.group.name, self.spot.name
  local has_group = group_name ~= nil and group_name ~= ""
  local has_spot = spot_name ~= nil and spot_name ~= ""

  if has_group and has_spot then
    return group_name .. " - " .. spot_name
  elseif has_group then
    return group_name
  else
    return spot_name or ""
  end
end

---@return string
function TeleportSpot:code()
  return self.props.code or ""
end

---@return TileArea
function TeleportSpot:target_area()
  return self.spot.target
end

---@return TileCoordinates
function TeleportSpot:center_of_target()
  local area = self.spot.target
  local size = area.size or { x = 1, y = 1 }

  return {
    x = area.origin.x + math.floor(size.x / 2),
    y = area.origin.y + math.floor(size.y / 2),
    level = area.origin.level,
  }
end

---@return Transportation.TeleportGroup.SpotId
function TeleportSpot:id()
  return {
    group = self.group.id,
    spot = self.spot.id,
    access = self.access and self.access.id or nil,
  }
end

---Resolves a spot id to a TeleportSpot, or nil if the group, spot or access cannot be found.
---@param id Transportation.TeleportGroup.SpotId
---@return cluetrainer.TeleportSpot?
function TeleportSpot.resolve(id)
  local teleports = require("cluetrainer/data/teleports")

  local group = array.find(teleports, function(value)
    return value.id == id.group
  end)
  if group == nil then return nil end

  local spot = array.find(group.spots, function(value)
    return value.id == id.spot
  end)
  if spot == nil then return nil end

  local access
  if id.access ~= nil then
    access = array.find(group.access, function(value)
      return value.id == id.access
    end)
    if access == nil then return nil end
  end

  return TeleportSpot.new(group, spot, access)
end

return TeleportSpot
