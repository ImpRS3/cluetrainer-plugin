-- methods.lua

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

---@class ScanTree.ScanTree
---@field ordered_spots TileCoordinates[]
---@field assumed_range integer
---@field root ScanTree.ScanTreeNode

---@class ScanTree.ScanTreeNode
---@field path Path.Raw
---@field region ScanTree.ScanRegion?
---@field children {key: PulseInformation, value: ScanTree.ScanTreeNode}[]

---@class ScanTree.ScanRegion
---@field name string
---@field area TileArea

---@class PulseInformation
---@field pulse 1 | 2 | 3
---@field spot TileCoordinates?

---@alias ClueAssumptions any

---@alias Method.Kind
---| "scantree"
---| "general_path"

---@class Method.Meta
---@field name string
---@field description string
---@field assumptions ClueAssumptions

---@class Method.Base : Method.Meta
---@field type Method.Kind
---@field id string
---@field timestamp number
---@field for ClueSpot.Id
---@field expected_time? number
---@field is_default_override? boolean


---@class Method.ScanTree : Method.Base
---@field type "scantree"
---@field tree ScanTree.ScanTree


---@class Method.GenericPath : Method.Base
---@field type "general_path"
---@field pre_path? Path.Raw
---@field main_path Path.Raw
---@field post_path? Path.Raw


---@alias Method
---| Method.ScanTree
---| Method.GenericPath


local methods = {}

---Returns the first teleport of a method's main path, if it has one.
---@param method Method.GenericPath
---@return cluetrainer.TeleportSpot?
function methods.primaryTeleport(method)
  local TeleportSpot = require "cluetrainer/model/shared/TeleportSpot"

  for _, step in ipairs(method.main_path or {}) do
    if step.type == "teleport" then
      return TeleportSpot.resolve(step.id)
    end
  end

  return nil
end

return methods
