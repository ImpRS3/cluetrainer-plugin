-- teleports.lua
---@class TeleportGroup : TeleportProps
---@field type "teleports"
---@field id string
---@field name string
---@field spots TeleportSpot[]
---@field access TeleportAccess[]

---@class TeleportSpot : TeleportProps
---@field id string
---@field target TileArea
---@field facing Direction
---@field name string

---@class TeleportProps
---@field id string?
---@field per_spot_props table<string, TeleportProps>?
---@field menu_ticks integer?
---@field animation_ticks integer?
---@field code string?
---@field hidden boolean?
---@field cache_data { sprite?: string, obj?: string }?

---@alias TeleportAccess TeleportAccess.item|TeleportAccess.entity|TeleportAccess.spellbook

---@class TeleportAccess.item : TeleportProps
---@field type "item"
---@field name EntityName
---@field action_name string
---@field can_be_in_pota boolean?
---@field area_restriction TileArea?
---@field cursor CursorType?

---@class TeleportAccess.entity : TeleportProps
---@field type "entity"
---@field name EntityName
---@field clickable_area TileArea
---@field interaction_area TileArea?
---@field action_name string
---@field cursor CursorType?
---@field orientation Direction?

---@class TeleportAccess.spellbook : TeleportProps
---@field type "spellbook"
---@field name string

---@class ct.model.teleports
local teleports = {}

--- Determines whether a teleport access can be used from anywhere.
---@param access TeleportAccess
---@return boolean
function teleports.teleport_access_is_anywhere(access)
  return access.type == "spellbook" or (access.type == "item" and access.area_restriction == nil)
end

---@class ct.model.teleports.props
teleports.props = {}

local PROP_KEYS = { "menu_ticks", "animation_ticks", "code", "hidden", "cache_data" }

---@type TeleportProps
teleports.props.DEFAULT_PROPS = {
  animation_ticks = 0,
  menu_ticks = 0,
  code = "",
}

---Combines props, where earlier entries have higher priority. Nil entries are skipped.
---@param props (TeleportProps|nil)[]
---@return TeleportProps
function teleports.props.combineInOrder(props)
  local result = {}

  for _, key in ipairs(PROP_KEYS) do
    for _, prop_i in ipairs(props) do
      if prop_i ~= nil and prop_i[key] ~= nil then
        result[key] = prop_i[key]
        break
      end
    end
  end

  return result
end

return teleports
