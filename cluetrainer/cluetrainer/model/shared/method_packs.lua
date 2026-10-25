-- method_packs.lua
---@class MethodPack.Meta
---@field author string
---@field name string
---@field description string
---@field default_assumptions ClueAssumptions
---@field default_method_name string


---@alias MethodPack.Type
---| "default"
---| "local"
---| "imported"


---@class MethodPack : MethodPack.Meta
---@field is_real_default? boolean
---@field type MethodPack.Type
---@field local_id string
---@field original_id string
---@field timestamp number
---@field methods Method[]