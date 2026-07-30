---@alias Direction any
---@alias MovementAbility any
---@alias Transportation.TeleportGroup.SpotId any
---@alias EntityTransportation any
---@alias CTRIcon.ID any
---@alias MyCursorType string


---@class Path.Step.Base
---@field type string
---@field description? string
---@field is_arrival_only? boolean


---@class Path.Step.Orientation : Path.Step.Base
---@field type "orientation"
---@field direction Direction


---@class Path.Step.Ability : Path.Step.Base
---@field type "ability"
---@field ability MovementAbility
---@field target? EntityName
---@field target_text? string
---@field target_area? TileArea
---@field is_far_dive? boolean
---@field from TileCoordinates
---@field to TileCoordinates


---@class Path.Step.Run : Path.Step.Base
---@field type "run"
---@field target_area? TileArea
---@field to_text? string
---@field waypoints TileCoordinates[]


---@class Path.Step.Teleport : Path.Step.Base
---@field type "teleport"
---@field id Transportation.TeleportGroup.SpotId
---@field spot TileCoordinates


---@class Path.Step.Transport : Path.Step.Base
---@field type "transport"
---@field assumed_start TileCoordinates
---@field internal EntityTransportation


---@class Path.Step.RedClick : Path.Step.Base
---@field type "redclick"
---@field target EntityName
---@field where TileCoordinates
---@field how MyCursorType


---@class Path.Step.Powerburst : Path.Step.Base
---@field type "powerburst"
---@field where TileCoordinates


---@class Path.Step.Cheat : Path.Step.Base
---@field type "cheat"
---@field assumed_start TileCoordinates
---@field target TileCoordinates
---@field orientation? Direction
---@field ticks number


---@class Path.Step.Cosmetic : Path.Step.Base
---@field type "cosmetic"
---@field icon CTRIcon.ID
---@field position TileCoordinates
---@field hide_when_not_hovered? boolean
---@field area? TileArea
---@field area_color? string
---@field arrow? [TileCoordinates, TileCoordinates]
---@field arrow_color? string


---@alias Path.Step
---| Path.Step.Orientation
---| Path.Step.Ability
---| Path.Step.Run
---| Path.Step.Teleport
---| Path.Step.Transport
---| Path.Step.RedClick
---| Path.Step.Powerburst
---| Path.Step.Cheat
---| Path.Step.Cosmetic

---@alias Path.Raw Path.Step[]
---@alias Path Path.Raw

---@alias EntityName.Kind
---| "npc"
---| "static"
---| "item"

---@class EntityName
---@field name string
---@field kind EntityName.Kind

local path = {}

return path