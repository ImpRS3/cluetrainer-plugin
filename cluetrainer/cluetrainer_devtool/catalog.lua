-- catalog.lua
-- Every clue scroll the devtool can give, with where to teleport to for its method and its solution. Built once from
-- Clue Trainer's own data when first required.
local clue_items = require "cluetrainer/data/clue_items"
local clues = require "cluetrainer/data/clues"
local method_packs = require "cluetrainer/data/method_packs"

---@alias devtool.Spot {x: integer, y: integer, level: integer}

---@class devtool.CatalogEntry
---@field config_name string Item config name of the clue scroll
---@field tier string Capitalised, e.g. "Easy"
---@field type string Capitalised, e.g. "Scan"
---@field label string Short enough for the bar of the clue box
---@field method_spot devtool.Spot? Where the first teleport of the method Clue Trainer recommends lands
---@field clue_spot devtool.Spot? A tile at or near the solution
---@field disabled boolean? Listed, but greyed out and not given, see RANDOM_MASTER_SCROLLS
---@field puzzle_box string? Item config name of the clue's slider puzzle box, hard clues only

-- Sort position of each tier, from easiest to hardest. Sandy clues have no scroll items in the catalog.
local TIER_ORDER = { Easy = 1, Medium = 2, Hard = 3, Elite = 4, Master = 5, Sandy = 6, Tetracompass = 7 }

-- Clue scroll items that Clue Trainer's clue items leave out, with their clue id in Clue Trainer's clue data.
local EXTRA_CLUE_ITEMS = { ARCH_TETRACOMPASS_POWERED = 470 }

-- Master anagram, emote and skilling scrolls are one item per type. The server picks the clue and keeps it on the item,
-- so these have no clue in the data and nothing to teleport to.
local RANDOM_MASTER_SCROLLS = {
  { config_name = "TRAIL_CLUE_MASTER_ANAGRAM", type = "Anagram" },
  { config_name = "TRAIL_CLUE_MASTER_EMOTE", type = "Emote" },
  -- Disabled: from !give it gets no clue, its text stops at "Complete this action:", even after !allinone. The server
  -- probably only picks a skilling clue during a real trail, which Give sealed (master) can lead to. Listed so it is
  -- clear the type exists.
  { config_name = "TRAIL_CLUE_MASTER_SKILL_RIDDLE", type = "Skilling", disabled = true },
}

-- Characters of clue text in a label, ellipsis included.
local MAX_TEXT_LENGTH = 45
local ELLIPSIS = "..."

-- The tile of 0°0', the observatory south of Ardougne, which coordinate clues are measured from. Same values as
-- SimpleClueSolver's inferSolution.
local OBSERVATORY = { x = 2440, y = 3161 }
local MINUTES_PER_DEGREE = 60
local TILES_PER_DEGREE = 32
local MINUTES_PER_TILE = MINUTES_PER_DEGREE / TILES_PER_DEGREE
-- Coordinate clues are all dug up on the ground floor.
local GROUND_LEVEL = 0

--- The value with its first letter in upper case, e.g. "easy" becomes "Easy". The data has tiers and types in lower
--- case.
---@param value string
---@return string
local function capitalise(value)
  return (value:gsub("^%l", string.upper))
end

--- Where the first teleport step of a path lands.
---@param steps Path.Raw? A path is optional in a method, so nil is allowed
---@return devtool.Spot? nil when the path has no teleport
local function firstTeleport(steps)
  for _, step in ipairs(steps or {}) do
    if step.type == "teleport" then return step.spot end
  end
end

--- The method Clue Trainer recommends, by the same rule as methods.resolve: the first one in pack order.
---@param clue_id integer
---@return Method? nil when no pack has a method for the clue
local function recommendedMethod(clue_id)
  for _, pack in ipairs(method_packs) do
    for _, method in ipairs(pack.methods) do
      if method["for"].clue == clue_id then return method end
    end
  end
end

--- The first teleport of a scan tree. A tree can start without a path, e.g. "Start anywhere", then it is in the
--- first child.
---@param node table A node of the scan tree, its path is walked before its children
---@return devtool.Spot? nil when neither the node nor its first descendants teleport
local function scanTreeSpot(node)
  return firstTeleport(node.path) or (node.children and node.children[1] and scanTreeSpot(node.children[1].value))
end

--- Where the first teleport of a method lands, so the devtool can start where the method starts. By method type:
--- - Scan trees: the first teleport in the tree, see scanTreeSpot.
--- - Paths: the first teleport in the pre path, else in the main path. The pre path comes first in the method.
--- nil when the method has no teleport, e.g. when it starts by running from wherever the player is.
---@param method Method
---@return devtool.Spot?
local function methodSpot(method)
  if method.type == "scantree" then return scanTreeSpot(method.tree.root) end

  return firstTeleport(method.pre_path) or firstTeleport(method.main_path)
end

--- Tiles from the observatory for one axis of a coordinate, e.g. 2°50' north is 91 tiles north.
---@param coordinate {degrees: integer, minutes: integer, direction: string}
---@param positive_direction string "east" or "north", the direction in which tile numbers go up
---@return integer tiles Negative towards the west or south
local function sextantOffset(coordinate, positive_direction)
  local minutes = coordinate.degrees * MINUTES_PER_DEGREE + coordinate.minutes
  -- Adding 0.5 before flooring rounds to the nearest tile.
  local tiles = math.floor(minutes / MINUTES_PER_TILE + 0.5)
  return coordinate.direction == positive_direction and tiles or -tiles
end

--- A tile to teleport to for checking a clue's solution. The first that applies:
--- 1. Coordinate clues: the dig spot, worked out from the coordinates.
--- 2. Search solutions (crates, drawers): the top-left tile of the searched object.
--- 3. Dig solutions: the dig tile.
--- 4. Talk-to solutions: the origin of the first area the NPC walks around in.
--- 5. Emote clues: the origin of the area to emote in.
--- 6. Skilling clues: the origin of the first area to skill in.
--- Scan and compass clues get nil, they only have a set of possible spots.
---@param clue table A clue from Clue Trainer's clue data
---@return devtool.Spot?
local function clueSpot(clue)
  local solution = clue.solution or {}
  local spot = solution.spot

  if clue.coordinates then
    return {
      x = OBSERVATORY.x + sextantOffset(clue.coordinates.longitude, "east"),
      y = OBSERVATORY.y + sextantOffset(clue.coordinates.latitude, "north"),
      level = GROUND_LEVEL,
    }
  end
  if spot and spot.topleft then return { x = spot.topleft.x, y = spot.topleft.y, level = spot.level } end
  if spot then return spot end
  if solution.spots then return solution.spots[1].range.origin end
  if clue.area then return clue.area.origin end
  if clue.areas then return clue.areas[1].origin end
end

--- A label like "Hard Map 001: <clue text>", short enough for the bar of the clue box.
---@param config_name string
---@param tier string
---@param clue_type string
---@param text string
---@return string
local function label(config_name, tier, clue_type, text)
  if #text > MAX_TEXT_LENGTH then text = text:sub(1, MAX_TEXT_LENGTH - #ELLIPSIS) .. ELLIPSIS end
  -- The scroll's number from the end of its config name, e.g. "001" from TRAIL_CLUE_EASY_EMOTE001.
  local number = config_name:match("%d+$")
  return string.format("%s %s%s: %s", tier, clue_type, number and " " .. number or "", text)
end

--- Whether a clue can come with a slider puzzle.
---@param clue table A clue from Clue Trainer's clue data
---@return boolean
local function hasSlider(clue)
  for _, challenge in ipairs(clue.challenge or {}) do
    if challenge.type == "slider" then return true end
  end
  return false
end

--- The catalog entry of a clue scroll item.
---@param config_name string
---@param clue table A clue from Clue Trainer's clue data
---@return devtool.CatalogEntry
local function clueEntry(config_name, clue)
  -- The target of a compass is random per scroll and its methods are written per target, so none of them applies.
  local method = clue.type ~= "compass" and recommendedMethod(clue.id) or nil
  local tier, clue_type = capitalise(clue.tier), capitalise(clue.type)
  -- All anagram texts start the same, the anagram itself tells them apart.
  local text = clue.anagram and clue.anagram[1] or table.concat(clue.text or {}, " ")

  return {
    config_name = config_name,
    tier = tier,
    type = clue_type,
    label = label(config_name, tier, clue_type, text),
    method_spot = method and methodSpot(method),
    clue_spot = clueSpot(clue),
    -- A hard clue with a slider has its own puzzle box item, named after the scroll. Elite sliders come in scroll
    -- boxes instead.
    puzzle_box = clue.tier == "hard" and hasSlider(clue) and config_name .. "_PUZZLEBOX" or nil,
  }
end

-- Clue scroll items refer to clues by id.
local clues_by_id = {}
for _, clue in ipairs(clues) do clues_by_id[clue.id] = clue end

--- Every clue scroll item that belongs to a known clue, and the random master scrolls, sorted by tier, type and item.
---@type devtool.CatalogEntry[]
local entries = {}

for _, items in ipairs({ clue_items, EXTRA_CLUE_ITEMS }) do
  for config_name, clue_id in pairs(items) do
    local clue = clues_by_id[clue_id]
    if clue then entries[#entries + 1] = clueEntry(config_name, clue) end
  end
end

for _, scroll in ipairs(RANDOM_MASTER_SCROLLS) do
  entries[#entries + 1] = {
    config_name = scroll.config_name,
    tier = "Master",
    type = scroll.type,
    label = label(scroll.config_name, "Master", scroll.type, scroll.disabled and "does not work" or "random clue"),
    disabled = scroll.disabled,
  }
end

-- Config names break ties, so the order is the same on every load.
table.sort(entries, function(a, b)
  if a.tier ~= b.tier then return TIER_ORDER[a.tier] < TIER_ORDER[b.tier] end
  if a.type ~= b.type then return a.type < b.type end
  return a.config_name < b.config_name
end)

return entries
