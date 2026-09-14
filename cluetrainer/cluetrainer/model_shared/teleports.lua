---@class TeleportGroup : TeleportProps
---@field type "teleport"
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
---@field menu_ticks integer?
---@field animation_ticks integer?
---@field code string?
---@field hidden boolean?

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
