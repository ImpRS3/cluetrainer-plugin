local array = require "zyklib/array"
---@class cluetrainer.TeleportSpot
---@field private group TeleportGroup
---@field private spot TeleportSpot
---@field private access TeleportAccess?
---@field props TeleportProps
local TeleportSpot = {}
TeleportSpot.__index = TeleportSpot

local function teleport_access_is_anywhere(access)
  return access.type == "spellbook" or (access.type == "item" and access.area_restriction == nil)
end

---@param props TeleportProps[]
---@return TeleportProps
local function combine_props(props)
  return props[1]  -- TODO
end

---@param group TeleportGroup
---@param spot TeleportSpot
---@param access TeleportAccess?
function TeleportSpot.new(group, spot, access)
  local self = setmetatable({}, TeleportSpot)

  if access == nil then
    access = array.find(group.access, function (value, index)
      return teleport_access_is_anywhere(value)
    end)
  end

  self.group = group
  self.spot = spot
  self.access = access
  self.props = combine_props({
    self.group,
    self.spot,
    self.access
  })

  return self
end

---comment
---@param id Transportation.TeleportGroup.SpotId
function TeleportSpot.resolve(id)

end

return TeleportSpot
