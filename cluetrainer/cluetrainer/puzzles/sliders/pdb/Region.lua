-- Region.lua
local zyklib = require "zyklib"
local SliderState = require "cluetrainer/puzzles/sliders/SliderState"

--- @alias cluetrainer.sliders.pdb.Region (0 | 1 | 2)[]

--- @class (exact) cluetrainer.sliders.pdb.RegionDescription
--- @field region cluetrainer.sliders.pdb.Region
--- @field multitile boolean

local Region = {}

Region.Tile = {}

Region.Tile.FREE = 0
Region.Tile.CURRENT = 1
Region.Tile.FIXED = 2

---Reflects the given region.
---@param region cluetrainer.sliders.pdb.Region
---@return cluetrainer.sliders.pdb.Region
function Region.reflect(region)
  return zyklib.array.map(SliderState.tile_reflection_table, function(i) return region[i] end)
end

---Checks if the two given regions are equal.
---@param region1 cluetrainer.sliders.pdb.Region
---@param region2 cluetrainer.sliders.pdb.Region
---@return boolean
function Region.equals(region1, region2)
  return zyklib.objects.deepEquals(region1, region2)
end

---@param region cluetrainer.sliders.pdb.Region
---@return boolean
function Region.isFirst(region)
  for i = 1, #region do
    if region[i] == Region.Tile.FIXED then
      return false
    end
  end
  return true
end

---@param parent cluetrainer.sliders.pdb.Region
---@param child cluetrainer.sliders.pdb.Region
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
