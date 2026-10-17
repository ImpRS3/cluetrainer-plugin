-- coordinates.lua
---@alias floor_t 0|1|2|3

---@class TileCoordinates : MyVector2
---@field level floor_t

---@class TileRectangle : Rectangle
---@field level floor_t

---@class GieliCoordinates
---@field latitude { degrees: number, minutes: number, direction: "north"|"south" }
---@field longitude { degrees: number, minutes: number, direction: "east"|"west" }

