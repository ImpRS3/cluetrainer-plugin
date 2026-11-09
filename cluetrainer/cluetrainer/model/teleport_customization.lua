-- teleport_customization.lua
-- The player's teleport setup that changes the shown teleport codes: what each owned passage of the abyss (pota)
-- holds, and the fairy ring favourites from the game.
-- Pure logic without client globals, so it can be tested in plain Lua.

local M = {}

---@alias ct.PotaColour "red"|"green"|"yellow"|"purple"

-- Same order as Alt1, which is also the order in which potas are searched for a teleport.
---@type ct.PotaColour[]
M.POTA_COLOURS = { "red", "green", "yellow", "purple" }

---@type table<ct.PotaColour, string>
M.POTA_OBJ = {
  red = "ALCH_ONYX_TELEPORT",
  green = "ALCH_ONYX_TELEPORT_GREEN",
  yellow = "ALCH_ONYX_TELEPORT_YELLOW",
  purple = "ALCH_ONYX_TELEPORT_PURPLE",
}

M.POTA_SLOTS = 6
M.FAVOURITE_COUNT = 10

---@class ct.PotaSlot
---@field group string Teleport group id, e.g. "amuletofglory"
---@field access string Access id within the group, e.g. "necklace"

---@class ct.PotaSetup
---@field colour ct.PotaColour
---@field slots (ct.PotaSlot|false)[] Always POTA_SLOTS entries, false for an empty slot

---@class ct.TeleportCustomization
---@field potas ct.PotaSetup[] The owned potas, at most one per colour, since only the colour tells them apart

-- Stored numbers may come back as floats, so 1.0 counts as the integer 1.
---@return integer?
local function toInteger(value)
  if type(value) ~= "number" or value ~= math.floor(value) then return nil end
  return math.tointeger(value)
end

local function isColour(value)
  for _, colour in ipairs(M.POTA_COLOURS) do
    if colour == value then return true end
  end
  return false
end

---@param value any
---@return any
function M.copy(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for key, inner in pairs(value) do result[key] = M.copy(inner) end
  return result
end

---@return (ct.PotaSlot|false)[]
function M.emptySlots()
  local slots = {}
  for i = 1, M.POTA_SLOTS do slots[i] = false end
  return slots
end

---@param value any
---@return ct.PotaSlot|false
local function normalizeSlot(value)
  if type(value) == "table" and type(value.group) == "string" and type(value.access) == "string" then
    return { group = value.group, access = value.access }
  end
  return false
end

--- Repairs stored settings: missing or broken parts get their defaults, so the rest of the code can trust the shape.
---@param value any
---@return ct.TeleportCustomization
function M.normalize(value)
  if type(value) ~= "table" then value = {} end

  local potas, seen = {}, {}
  for _, pota in ipairs(type(value.potas) == "table" and value.potas or {}) do
    if type(pota) == "table" and isColour(pota.colour) and not seen[pota.colour] then
      seen[pota.colour] = true
      local slots = M.emptySlots()
      local stored = type(pota.slots) == "table" and pota.slots or {}
      for i = 1, M.POTA_SLOTS do slots[i] = normalizeSlot(stored[i]) end
      potas[#potas + 1] = { colour = pota.colour, slots = slots }
    end
  end

  return { potas = potas }
end

---@return ct.TeleportCustomization
function M.empty()
  return M.normalize(nil)
end

---@param settings ct.TeleportCustomization
---@param colour ct.PotaColour
---@return ct.PotaSetup?
function M.pota(settings, colour)
  for _, pota in ipairs(settings.potas) do
    if pota.colour == colour then return pota end
  end
  return nil
end

--- The pota slot that holds a teleport group, searched in colour order. Like Alt1, the group decides, not the access.
---@param settings ct.TeleportCustomization
---@param group_id string
---@return { colour: ct.PotaColour, slot: integer }?
function M.potaSlotFor(settings, group_id)
  for _, colour in ipairs(M.POTA_COLOURS) do
    local pota = M.pota(settings, colour)
    if pota then
      for i, slot in ipairs(pota.slots) do
        if slot and slot.group == group_id then return { colour = colour, slot = i } end
      end
    end
  end
  return nil
end

-- Fairy ring dials as the game numbers them: the hundreds, tens and units of a ring's number are the positions of
-- the left, middle and right dial. From the fairy ring db table in the cache (table 121), e.g. AIQ = 3, DKS = 121.
local DIALS = { { "A", "D", "C", "B" }, { "I", "L", "K", "J" }, { "P", "S", "R", "Q" } }

-- Rings whose number doesn't follow the dials, mapped to their spot id in data/teleports.lua.
local SPECIAL_RINGS = {
  [444] = "AIP",         -- Zanaris
  [1000] = "resistance", -- Fairy Resistance HQ (AIR DLR DJQ AJS)
  [1001] = "rift",       -- Ork's Rift (BIR DIP CLR ALP)
  [1002] = "kethsi",     -- Kethsi (DIR AKS)
}

--- The fairy ring spot id stored in a FAIRYRINGS_FAVOURITE_n value, or nil for an empty or unknown value.
---@param value integer|false|nil
---@return string?
function M.fairyRingSpot(value)
  value = toInteger(value)
  if value == nil then return nil end
  if SPECIAL_RINGS[value] then return SPECIAL_RINGS[value] end
  if value < 0 or value >= 400 then return nil end

  local left, middle, right = value // 100, value // 10 % 10, value % 10
  if middle > 3 or right > 3 then return nil end
  local code = DIALS[1][left + 1] .. DIALS[2][middle + 1] .. DIALS[3][right + 1]
  -- 0 would be AIP by the dials, but Zanaris has its own number, so 0 is taken as an empty favourite.
  if code == "AIP" then return nil end
  return code
end

--- The key that selects each favourite in the fairy ring interface: 1 to 9, then 0 for the tenth.
---@param values (integer|false)[] The FAIRYRINGS_FAVOURITE_1..10 values, false when unreadable
---@return table<string, string> keys Spot id -> key
function M.favouriteKeys(values)
  local keys = {}
  for i = 1, M.FAVOURITE_COUNT do
    local spot = M.fairyRingSpot(values[i] or nil)
    if spot and keys[spot] == nil then keys[spot] = tostring(i % 10) end
  end
  return keys
end

-- What TeleportSpot shows. Kept up to date by solving/common/TeleportCustomization in the client; plain Lua tests set
-- it directly.
---@class ct.ActiveTeleportCustomization
---@field settings ct.TeleportCustomization
---@field favourite_keys table<string, string>
M.current = {
  settings = M.empty(),
  favourite_keys = {},
}

return M
