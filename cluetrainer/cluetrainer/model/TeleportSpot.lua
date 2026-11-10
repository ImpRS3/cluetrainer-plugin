-- TeleportSpot.lua
local array = require "zyklib/array"
local customization = require "cluetrainer/model/teleport_customization"
local teleports = require "cluetrainer/model/teleports"

---@class cluetrainer.TeleportSpot
---@field group TeleportGroup
---@field spot TeleportSpot
---@field access TeleportAccess?
---@field visual_access TeleportAccess? The access whose props are shown: the given one, or one usable anywhere
---@field props TeleportProps
local TeleportSpot = {}
TeleportSpot.__index = TeleportSpot

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
    return teleports.teleport_access_is_anywhere(value)
  end)
  self.visual_access = visual_access

  -- Priority: access x spot props, per-access props, per-spot props, per-group props, defaults.
  self.props = teleports.props.combineInOrder({
    access and access.per_spot_props and access.per_spot_props[spot.id] or nil,
    visual_access,
    spot,
    group,
    teleports.props.DEFAULT_PROPS,
  })

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

--- The pota slot to take this teleport from, if the active teleport profile has its jewellery in a pota.
---@return { colour: ct.PotaColour, slot: integer }?
function TeleportSpot:potaSlot()
  local access = self.visual_access
  if not (access and access.type == "item" and access.can_be_in_pota) then return nil end
  return customization.potaSlotFor(customization.current.settings, self.group.id)
end

--- The keys to press: the fairy ring favourite key instead of the dial code, and the pota slot in front (e.g. "3,2").
---@return string
function TeleportSpot:code()
  local code = self.props.code or ""

  if self.group.id == "fairyring" then
    code = customization.current.favourite_keys[self.spot.id] or code
  end

  local pota = self:potaSlot()
  if pota then code = pota.slot .. "," .. code end

  return code
end

--- The icon to draw: the pota's own colour when the teleport is taken from a pota, otherwise the teleport's icon.
---@return { sprite?: string, obj?: string }?
function TeleportSpot:cacheData()
  local pota = self:potaSlot()
  if pota then return { obj = customization.POTA_OBJ[pota.colour] } end
  return self.props.cache_data
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
