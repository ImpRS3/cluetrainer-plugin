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
---@field different_level boolean?
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
---@param method Method
---@return cluetrainer.TeleportSpot?
function methods.primaryTeleport(method)
  local Path = require "cluetrainer/model/shared/path"

  if method.type == "general_path" then 
    return Path.firstTeleport(method.main_path or {})
  else
    return Path.firstTeleport(method.tree.root.path or {})
  end
end

return methods
