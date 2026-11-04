-- scan_tree.lua
-- Scan tree logic without game state: the game's pulse formula, and which spots and children fit a pulse.
local Path = require "cluetrainer/model/shared/path"
local TileArea = require "cluetrainer/model/shared/TileArea"
local tiles = require "cluetrainer/model/shared/tiles"
local array = require "zyklib/array"

local scan_tree = {}

-- Underground areas sit 6400 tiles north of their surface; the game says "different level" within range + 15 of it.
local COMPLEMENT_OFFSET = 6400
local COMPLEMENT_EXTRA_RANGE = 15

---@alias ScanTree.Child {key: PulseInformation, value: ScanTree.ScanTreeNode}

---@param key PulseInformation
---@return boolean
local function isDifferentLevel(key)
  return key.different_level == true
end

--- The area where the player scans for this node's decision. Like Alt1, a node without a region uses the end of its
--- path, and a node with an empty path scans where its parent scanned.
---@param node ScanTree.ScanTreeNode
---@param parent_area TileArea?
---@return TileArea?
function scan_tree.scanArea(node, parent_area)
  return (node.region and node.region.area) or Path.endsUpArea(node.path) or parent_area
end

--- The children that fit what the panel shows.
---@param node ScanTree.ScanTreeNode
---@param reading ct.ScanPanel.Reading
---@param tile TileCoordinates? The player's tile, narrows "found" down to the triple spot the player stands on
---@return ScanTree.Child[]
function scan_tree.childrenForReading(node, reading, tile)
  local state = reading.state

  if state == "found" and tile ~= nil then
    local here = array.filter(node.children, function(child)
      return child.key.pulse == 3 and child.key.spot ~= nil and tiles.same(child.key.spot, tile)
    end)
    if #here > 0 then return here end
  end

  return array.filter(node.children, function(child)
    local key = child.key

    if state == "different_level" then
      return isDifferentLevel(key)
    elseif state == "triple" or state == "found" then
      return key.pulse == 3 and not isDifferentLevel(key)
    elseif state == "too_far" then
      return key.pulse ~= 3 and not isDifferentLevel(key)
    end

    return false
  end)
end

--- The child for a pulse the player entered. Prefers the given level; falls back to the other level when the node
--- has only one child with this pulse.
---@param node ScanTree.ScanTreeNode
---@param pulse 1 | 2 | 3
---@param different_level boolean
---@return ScanTree.Child?
function scan_tree.childForPulse(node, pulse, different_level)
  local function unique(predicate)
    local matches = array.filter(node.children, predicate)
    return #matches == 1 and matches[1] or nil
  end

  return unique(function(child)
    return child.key.pulse == pulse and isDifferentLevel(child.key) == different_level
  end) or unique(function(child)
    return child.key.pulse == pulse
  end)
end

--- The only child that still has any of the spots, nil when none or several do. A scan can then only pick that child.
---@param children ScanTree.Child[]
---@param spots TileCoordinates[]
---@param candidates table<ScanTree.ScanTreeNode, TileCoordinates[]> From `scan_tree.candidates`
---@return ScanTree.Child?
function scan_tree.onlyChildWith(children, spots, candidates)
  local function holds(child, spot)
    return array.exists(candidates[child.value], function(candidate) return tiles.same(candidate, spot) end)
  end

  local found = nil
  for _, child in ipairs(children) do
    if array.exists(spots, function(spot) return holds(child, spot) end) then
      if found ~= nil then return nil end
      found = child
    end
  end
  return found
end

--- Alt1's pulse formula: a triple within range, a double within twice the range, a single further away. The game
--- counts one pace beyond each edge as within it, hence the -1.
---@param d integer
---@param range integer
---@return 1 | 2 | 3
local function pulseForDistance(d, range)
  return 3 - math.min(2, math.max(0, d - 1) // range)
end

--- The same spot on the other side: surface for underground, underground for surface.
---@param spot TileCoordinates
---@return TileCoordinates
local function complementOf(spot)
  return { x = spot.x, y = (spot.y + COMPLEMENT_OFFSET) % (2 * COMPLEMENT_OFFSET) }
end

--- The pulse the game gives at `tile` for dig spot `spot` (Alt1's `get_pulse`).
---@param spot TileCoordinates
---@param tile TileCoordinates
---@param range integer
---@return 1 | 2 | 3 pulse
---@return boolean different_level
function scan_tree.pulseAt(spot, tile, range)
  local different_level = (spot.level or 0) ~= (tile.level or 0)
      or tiles.distance(complementOf(spot), tile) <= range + COMPLEMENT_EXTRA_RANGE
  return pulseForDistance(tiles.distance(spot, tile), range), different_level
end

--- Whether some tile of a plain rectangle gives `key` for dig spot `spot`, without visiting every tile; a few scan
--- areas cover thousands of tiles. As Alt1's `area_pulse` for rectangles.
---@param spot TileCoordinates
---@param area TileArea
---@param range integer
---@param key PulseInformation
---@return boolean
local function rectangleGives(spot, area, range, key)
  local size = TileArea.ensure_mutable(area):getSize()
  local x1, y1 = area.origin.x, area.origin.y
  local x2, y2 = x1 + size.x - 1, y1 + size.y - 1

  local function nearest(p)
    return { x = math.min(math.max(p.x, x1), x2), y = math.min(math.max(p.y, y1), y2) }
  end
  local function farthest(p)
    return { x = (p.x - x1 > x2 - p.x) and x1 or x2, y = (p.y - y1 > y2 - p.y) and y1 or y2 }
  end

  -- The distance changes by at most one per tile, so every pulse between the nearest and the farthest tile occurs.
  local strongest = pulseForDistance(tiles.distance(spot, nearest(spot)), range)
  local weakest = pulseForDistance(tiles.distance(spot, farthest(spot)), range)
  if key.pulse < weakest or key.pulse > strongest then return false end

  if (spot.level or 0) ~= (area.origin.level or 0) then return isDifferentLevel(key) end

  -- Near the complement the spot is 6400 tiles away, so those tiles give a single.
  local complement = complementOf(spot)
  if isDifferentLevel(key) then
    return key.pulse == 1 and tiles.distance(complement, nearest(complement)) <= range + COMPLEMENT_EXTRA_RANGE
  end
  return tiles.distance(complement, farthest(complement)) > range + COMPLEMENT_EXTRA_RANGE
end

--- Whether some tile of `area` gives `key` for dig spot `spot`.
---@param spot TileCoordinates
---@param area TileArea
---@param range integer
---@param key PulseInformation
---@return boolean
local function areaGives(spot, area, range, key)
  if area.data == nil then return rectangleGives(spot, area, range, key) end

  local active = TileArea.ensure_mutable(area)
  local size = active:getSize()
  local level = area.origin.level or 0

  for dx = 0, size.x - 1 do
    for dy = 0, size.y - 1 do
      local tile = { x = area.origin.x + dx, y = area.origin.y + dy, level = level }
      if active:query(tile) then
        local pulse, different_level = scan_tree.pulseAt(spot, tile, range)
        if pulse == key.pulse and different_level == isDifferentLevel(key) then return true end
      end
    end
  end

  return false
end

--- The dig spots still possible at every node: the root has all spots, a child keeps the spots that give its pulse
--- somewhere in its parent's scan area, a triple child only its own spot. As Alt1's `basic_augmentation`.
---@param tree ScanTree.ScanTree
---@return table<ScanTree.ScanTreeNode, TileCoordinates[]>
function scan_tree.candidates(tree)
  local result = {}

  local function visit(node, spots, parent_area)
    result[node] = spots
    local area = scan_tree.scanArea(node, parent_area)
    if area == nil then return end

    for _, child in ipairs(node.children) do
      local key = child.key
      local remaining = array.filter(spots, function(spot)
        return (key.spot == nil or tiles.same(key.spot, spot)) and areaGives(spot, area, tree.assumed_range, key)
      end)
      visit(child.value, remaining, area)
    end
  end

  visit(tree.root, tree.ordered_spots, nil)

  return result
end

return scan_tree
