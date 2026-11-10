---@class GieliCoordinates
---@field latitude { degrees: number, minutes: number, direction: "north"|"south" }
---@field longitude { degrees: number, minutes: number, direction: "east"|"west" }

---@class ct.math.gielicoordinates
local gielicoordinates = {}

---Converts longotude/latitude coordinates into TileCoordinates
---@param coords GieliCoordinates
function gielicoordinates.toTileCoordinates(coords)
  local sextant_coordinate_system = {
    offsetx = 2440,
    offsetz = 3161,
    minutespertile = 1.875
  }

  return {
    x = sextant_coordinate_system.offsetx +
        math.floor((60 * coords.longitude.degrees + coords.longitude.minutes) *
          (coords.longitude.direction == "west" and -1 or 1) / sextant_coordinate_system.minutespertile + 0.5),
    y = sextant_coordinate_system.offsetz +
        math.floor((60 * coords.latitude.degrees + coords.latitude.minutes) *
          (coords.latitude.direction == "south" and -1 or 1) / sextant_coordinate_system.minutespertile + 0.5),
    level = 0
  }
end

return gielicoordinates
