-- Unknown types

---@alias ScanTree.ScanTree any
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