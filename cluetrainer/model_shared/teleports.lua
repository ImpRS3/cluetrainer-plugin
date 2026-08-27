---@class TeleportGroup
---@field type "teleport"
---@field id string
---@field name string
---@field spots TeleportSpot[]
---@field access TeleportAccess[]

---@class TeleportSpot : TeleportProps
---@field id string
---@field target TileArea
---@field facing direction
---@field name string

---@class TeleportProps
---@field menu_ticks integer?
---@field animation_ticks integer?
---@field code string?
---@field hidden boolean?

---@class TeleportAccess : TeleportProps
---@field id string
