-- coordinates.lua
---@alias floor_t 0|1|2|3

---@class TileCoordinates : ct.lib.math.Vector2
---@field level floor_t

---@class TileRectangle : ct.Rectangle
---@field level floor_t

---@class GieliCoordinates
---@field latitude { degrees: number, minutes: number, direction: "north"|"south" }
---@field longitude { degrees: number, minutes: number, direction: "east"|"west" }

