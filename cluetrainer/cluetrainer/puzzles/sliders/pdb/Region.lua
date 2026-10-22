-- Region.lua
local zyklib = require "zyklib"
local SliderState = require "cluetrainer/puzzles/sliders/SliderState"

--- @alias ct.sliders.pdb.Region (0 | 1 | 2)[]

--- @class (exact) ct.sliders.pdb.RegionDescription
--- @field region ct.sliders.pdb.Region
--- @field multitile boolean

local Region = {}

Region.Tile = {}

Region.Tile.FREE = 0
Region.Tile.CURRENT = 1
Region.Tile.FIXED = 2

---Reflects the given region.
---@param region ct.sliders.pdb.Region
---@return ct.sliders.pdb.Region
function Region.reflect(region)
  return zyklib.array.map(SliderState.tile_reflection_table, function(i) return region[i] end)
end

---Checks if the two given regions are equal.
---@param region1 ct.sliders.pdb.Region
---@param region2 ct.sliders.pdb.Region
---@return boolean
function Region.equals(region1, region2)
  return zyklib.objects.deepEquals(region1, region2)
end

---@param region ct.sliders.pdb.Region
---@return boolean
function Region.isFirst(region)
  for i = 1, #region do
    if region[i] == Region.Tile.FIXED then
      return false
    end
  end
  return true
end

---@param parent ct.sliders.pdb.Region
---@param child ct.sliders.pdb.Region
---@return boolean
function Region.isChild(parent, child)
  return zyklib.array.forAll(child, function(child_tile, i)
    local parent_tile = parent[i]

    if child_tile == Region.Tile.FREE or child_tile == Region.Tile.CURRENT then
      return parent_tile == Region.Tile.FREE
    elseif child_tile == Region.Tile.FIXED then
      return parent_tile == Region.Tile.FIXED or parent_tile == Region.Tile.CURRENT
    end

    return true
  end)
end

return Region
