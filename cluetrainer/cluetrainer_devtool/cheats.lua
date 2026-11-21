-- cheats.lua
-- The dev server cheats the devtool runs, with the item and variable names they need. Cheats only work on dev servers.
-- Names come from the client's "pan Obj" and "pan VarPlayer" console commands.
local entries = require "cluetrainer_devtool/catalog"
local puzzles = require "cluetrainer_devtool/puzzles"

local cheats = {}

-- Tiles along each side of a map square.
local MAP_SQUARE_SIZE = 64
-- TRAIL_OUTFIT_FULL_OWNED has one bit per globetrotter piece, this sets all five (0b11111).
local ALL_PIECES_OWNED = 31
-- Charges the jacket, backpack and boots hold with the full outfit, 3 without it.
local MAX_OUTFIT_CHARGES = 4
-- Teleport scrolls the arm guards hold per destination.
local MAX_SCROLL_CHARGES = 1000

-- Config names of the sealed clue scrolls (items 42006 to 42010), by tier. They are not in Clue Trainer's data.
cheats.SEALED_CLUES = {
  Easy = "TRAIL17_TRAIL_START_EASY",
  Medium = "TRAIL17_TRAIL_START_MEDIUM",
  Hard = "TRAIL17_TRAIL_START_HARD",
  Elite = "TRAIL17_TRAIL_START_ELITE",
  Master = "TRAIL17_TRAIL_START_MASTER",
}

-- The hard puzzle boxes, one per hard clue with a slider. The box decides the picture of the slider.
local HARD_PUZZLE_BOXES = {}
for _, entry in ipairs(entries) do
  if entry.puzzle_box then HARD_PUZZLE_BOXES[#HARD_PUZZLE_BOXES + 1] = entry.puzzle_box end
end

-- The puzzles of each tier: the items to pick one from at random, and what scrambles it. Easy and medium trails have
-- no puzzles.
cheats.PUZZLES = {
  Hard = { { items = HARD_PUZZLE_BOXES, scramble = puzzles.slider } },
  -- The server picks a slider or a knot when it is opened. No item holds only a knot.
  -- TODO: a given elite scroll box does not open, without a message, whether an elite trail runs or not. Find out what
  -- it needs. Until then it has no scramble either.
  Elite = { { items = { "TRAIL_ELITE_SCROLLBOX_PUZZLE" } } },
  Master = {
    { items = { "TRAIL17_LIGHTSOUT" }, scramble = puzzles.lockbox },
    { items = { "TRAIL17_SKYSCRAPERS" }, scramble = puzzles.towers },
  },
}

-- The five globetrotter pieces, as item config names without their version suffix. Each piece has versions _TIER0 to
-- _TIER3, for a Defence requirement of 0, 25, 50 and 75.
local GLOBETROTTER_PIECES = { "TRAIL17_TORSO", "TRAIL17_CAPE", "TRAIL17_LEGS", "TRAIL17_GLOVES", "TRAIL17_BOOTS" }
local LAST_PIECE_VERSION = 3
-- The version given for a piece you do not have, without a Defence requirement.
local GIVEN_PIECE_VERSION = 0

-- VarPlayers that fill the globetrotter outfit, as { name, value }. The charges belong to the account, not to the
-- items. The outfit vars are named after the slot: torso is the jacket, cape the backpack.
local GLOBETROTTER_VARS = {
  { "TRAIL_OUTFIT_FULL_OWNED", ALL_PIECES_OWNED },
  { "TRAIL_OUTFIT_TORSO_CHARGES", MAX_OUTFIT_CHARGES }, -- Teleport to the clue
  { "TRAIL_OUTFIT_CAPE_CHARGES", MAX_OUTFIT_CHARGES },  -- Exchange the clue for another one
  { "TRAIL_OUTFIT_BOOTS_CHARGES", MAX_OUTFIT_CHARGES }, -- Unlimited run
  -- The arm guards, one var per teleport scroll.
  { "TRAIL17_TELEPORT_CHARGE_GRAND_EXCHANGE", MAX_SCROLL_CHARGES },
  { "TRAIL17_TELEPORT_CHARGE_BANDIT_CAMP", MAX_SCROLL_CHARGES },
  { "TRAIL17_TELEPORT_CHARGE_CLOCKTOWER", MAX_SCROLL_CHARGES },
  { "TRAIL17_TELEPORT_CHARGE_GUTANOTH", MAX_SCROLL_CHARGES },
  { "TRAIL17_TELEPORT_CHARGE_LIGHTHOUSE", MAX_SCROLL_CHARGES },
  { "TRAIL17_TELEPORT_CHARGE_FORT_FORINTHRY", MAX_SCROLL_CHARGES },
  { "TRAIL17_TELEPORT_CHARGE_MISCELLANIA", MAX_SCROLL_CHARGES },
  { "TRAIL17_TELEPORT_CHARGE_PHOENIX_LAIR", MAX_SCROLL_CHARGES },
  { "TRAIL17_TELEPORT_CHARGE_POLLNIVNEACH", MAX_SCROLL_CHARGES },
  { "TRAIL17_TELEPORT_CHARGE_TAI_BWO_WANNAI", MAX_SCROLL_CHARGES },
}

-- VarPlayers holding the progress of the current step of each trail. At 0 the step is unfinished again. All but the
-- slider flags are bits of TRAIL_STATUS (varp 1581).
--
-- Left out on purpose:
-- - TRAIL_STATUS_CURRENT_CLUE_NEEDS_SEXTANT_*: describe the clue, not progress.
-- - TRAIL_STATUS_SPOKEN_TO_PROFESSOR, _TAUGHT_HOW_TO_USE_SEXTANT, _GOT_SEXTANT_FROM_MURPHY and
--   _GOT_WATCH_FROM_BROTHER_KOJO: the one-time sextant setup of the account.
-- - TRAIL_STEPS_<TIER>, TRAIL_<TIER>_CLUE_GIVEN: progress of the whole trail.
-- - Knot (TRAIL_SHUFFLE*), lockbox (TRAIL_LIGHTSOUT_*) and towers (TRAIL17_SKYSCRAPERS_*) state: a new puzzle may
--   start fresh anyway. Add them if a reset puzzle turns out to stay solved.
local STEP_PROGRESS_VARS = {
  -- The puzzle is solved: a slider or knot on elite, a lockbox or towers on master.
  "TRAIL_STATUS_SOLVED_PUZZLE_ELITE",
  "TRAIL_STATUS_SOLVED_PUZZLE_MASTER",
  -- The monster that attacks when digging is killed: a wizard on hard and elite, the cabbagemancer on master.
  "TRAIL_STATUS_HAS_KILLED_MONSTER_HARD",
  "TRAIL_STATUS_HAS_KILLED_MONSTER_ELITE",
  "TRAIL_STATUS_HAS_KILLED_MONSTER_MASTER",
  -- The emote is done, or the double agent of an emote clue is killed.
  "TRAIL_STATUS_DONE_CODE_EMOTE_OR_KILLED_DOUBLE_AGENT_MEDIUM",
  "TRAIL_STATUS_DONE_CODE_EMOTE_OR_KILLED_DOUBLE_AGENT_HARD",
  -- A slider is under way. Off, the next slider gets a new scramble.
  "SLIDE_PUZZLE_HARD_STARTED",
  "SLIDE_PUZZLE_ELITE_STARTED",
}

--- Sets a VarPlayer, or a VarBit based on one.
---@param name string
---@param value integer
local function setvar(name, value)
  ExecuteConsoleCommand(string.format("!setvar %s %d", name, value))
end

--- Puts an item in your inventory. Does nothing without a config name, so a button without a target is harmless.
--- !give does not recognise numeric ids, only config names.
---@param config_name string?
function cheats.give(config_name)
  if config_name then ExecuteConsoleCommand("!give " .. config_name) end
end

--- Teleports you to a tile. Does nothing without a spot.
---@param spot devtool.Spot?
function cheats.tele(spot)
  if not spot then return end
  -- !tele takes "level,mapsquareX,mapsquareY,localX,localY": the map square and the tile within it.
  ExecuteConsoleCommand(string.format("!tele %d,%d,%d,%d,%d", spot.level,
    spot.x // MAP_SQUARE_SIZE, spot.y // MAP_SQUARE_SIZE, spot.x % MAP_SQUARE_SIZE, spot.y % MAP_SQUARE_SIZE))
end

--- Gives the puzzles of a tier, each a random item of its list with a new scramble. Does nothing for a tier without
--- puzzles.
---@param tier string
function cheats.givePuzzles(tier)
  for _, puzzle in ipairs(cheats.PUZZLES[tier] or {}) do
    if puzzle.scramble then
      for _, var in ipairs(puzzle.scramble()) do setvar(var[1], var[2]) end
    end
    cheats.give(puzzle.items[math.random(#puzzle.items)])
  end
end

--- Whether you wear or carry any version of a globetrotter piece. The bank is not checked, the client only knows its
--- contents while it is open.
---@param piece string A name from GLOBETROTTER_PIECES
---@return boolean
local function hasPiece(piece)
  for _, inv_type in ipairs({ config.Inv.INV, config.Inv.WORN }) do
    local inv = Inventory.Find(inv_type)
    for version = 0, LAST_PIECE_VERSION do
      if inv and inv:GetTotal(config.Obj[piece .. "_TIER" .. version]) > 0 then return true end
    end
  end
  return false
end

--- Gives the globetrotter pieces you do not wear or carry yet, and fills all charges of the outfit.
function cheats.fillGlobetrotter()
  for _, piece in ipairs(GLOBETROTTER_PIECES) do
    if not hasPiece(piece) then cheats.give(piece .. "_TIER" .. GIVEN_PIECE_VERSION) end
  end
  for _, var in ipairs(GLOBETROTTER_VARS) do setvar(var[1], var[2]) end
end

--- Makes the current step of each trail unfinished again, see STEP_PROGRESS_VARS.
function cheats.resetStep()
  for _, name in ipairs(STEP_PROGRESS_VARS) do setvar(name, 0) end
end

return cheats
