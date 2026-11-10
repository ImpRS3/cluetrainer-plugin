local clues = require("cluetrainer/data/clues")
local zyklib = require("zyklib")
local util = require("cluetrainer/util")

---@generic T
---@class ct.ClueIndex<T>
---@field default fun(): T
---@field private index { [ClueSpot.Id]: {value: T, spot_index: { [integer]: { value: T } }} }
local ClueIndex = {}
ClueIndex.__index = ClueIndex

---@generic T
---@param default fun(): T
---@return ct.ClueIndex<T>
function ClueIndex.new(default)
  local self = setmetatable({}, ClueIndex)

  self.index = {}
  self.default = default or function() return nil end

  return self
end

---@param spot TileCoordinates
---@return integer
local function hash_spot(spot)
  return (spot.y * (100 * 64) + spot.x) * 4 + spot.level
end

---Retrieves the entry for a given spot, creating it if it doesn't exist.
---@param spot ClueSpot.Id
---@return { value: T }
function ClueIndex:_get(spot)
  local entry = zyklib.objects.getOrElseUpdate(self.index, spot.clue, function()
    return { value = self.default(), spot_index = {} }
  end)

  if spot.spot ~= nil then
    return zyklib.objects.getOrElseUpdate(entry.spot_index,
      hash_spot(spot.spot), function()
        return { value = self.default() }
      end)
  else
    return entry
  end
end

---@param spot ClueSpot.Id
---@return {clue: ClueSpot, spot: TileCoordinates?}
function ClueIndex:get(spot)
  return self:_get(spot).value
end

---@param spot ClueSpot.Id
function ClueIndex:set(spot, value)
  self:_get(spot).value = value
end

---Clears all entries in the clue index.
function ClueIndex:clear()
  self.index = {}
end

---@type fun(): ct.ClueIndex<ClueSpot>
ClueIndex.spots = zyklib.util.lazy(function()
  ---@type ct.ClueIndex<ClueSpot>
  local index = ClueIndex.new(function() return nil end)

  for _, clue in ipairs(clues) do
    index:set({ clue = clue.id }, { clue = clue })

    if clue.type == "compass" then
      for _, spot in ipairs(clue.spots) do
        index:set({ clue = clue.id, spot = spot }, { clue = clue, spot = spot })
      end
    end
  end

  return index
end)

return ClueIndex
