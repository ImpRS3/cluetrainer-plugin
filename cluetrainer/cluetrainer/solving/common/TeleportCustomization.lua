-- TeleportCustomization.lua
-- Keeps `teleport_customization.current` in sync with the stored teleport settings and the fairy ring favourites in
-- the game, and tells the teleport displays when the shown codes may have changed.
local zyklib        = require "zyklib"
local customization = require "cluetrainer/model/shared/teleport_customization"

local TeleportCustomization = {}

local variable = ctGlobal.persistence:profileVariable("teleports/customization", customization.normalize)

--- Triggered when the settings or the favourites change, so displays can redraw their codes and icons.
---@type zyklib.reactive.Event<nil, nil>
TeleportCustomization.changed = zyklib.reactive.Event.new()

local FAVOURITE_NAMES = {}
for i = 1, customization.FAVOURITE_COUNT do FAVOURITE_NAMES[i] = "FAIRYRINGS_FAVOURITE_" .. i end

---@param name string
---@return VarType?
local function favouriteVar(name)
  local ok, result = pcall(function() return var.VarPlayer[name] end)
  return ok and result or nil
end

--- The FAIRYRINGS_FAVOURITE_1..10 values, false for one that can't be read.
---@return (integer|false)[]
function TeleportCustomization.favouriteValues()
  local values = {}
  for i, name in ipairs(FAVOURITE_NAMES) do
    local favourite = favouriteVar(name)
    local ok, value = pcall(function() return favourite and favourite.value end)
    values[i] = ok and type(value) == "number" and value or false
  end
  return values
end

local function sameKeys(a, b)
  for key, value in pairs(a) do
    if b[key] ~= value then return false end
  end
  for key in pairs(b) do
    if a[key] == nil then return false end
  end
  return true
end

--- Reads the favourites again and triggers `changed` if they differ.
function TeleportCustomization.refreshFavourites()
  local keys = customization.favouriteKeys(TeleportCustomization.favouriteValues())
  if sameKeys(keys, customization.current.favourite_keys) then return end
  customization.current.favourite_keys = keys
  TeleportCustomization.changed:trigger(nil)
end

-- The ids of the favourite varbits and of the vars that hold them, since a transmit may name either.
local watched_ids = {}
for _, name in ipairs(FAVOURITE_NAMES) do
  local favourite = favouriteVar(name)
  pcall(function()
    watched_ids[favourite.id] = true
    if favourite.baseVar then watched_ids[favourite.baseVar.id] = true end
  end)
end

local var_handler = zyklib.game_events.native.VarTransmit:subscribe(function(payload)
  local ok, id = pcall(function() return payload.var.id end)
  if ok and watched_ids[id] then TeleportCustomization.refreshFavourites() end
end)

local settings_handler = variable:observable():subscribe(function(settings)
  customization.current.settings = settings
  TeleportCustomization.changed:trigger(nil)
end, true)

TeleportCustomization.refreshFavourites()

zyklib.lifecycle.shutdown_event:subscribe(function()
  var_handler:cancel()
  settings_handler:cancel()
end)

--- A copy of the stored settings, to change and pass to `set`.
---@return ct.TeleportCustomization
function TeleportCustomization.get()
  return customization.copy(variable:get())
end

---@param settings ct.TeleportCustomization
function TeleportCustomization.set(settings)
  variable:set(customization.normalize(customization.copy(settings)))
end

--- Changes the settings in place and stores them.
---@param change fun(settings: ct.TeleportCustomization)
function TeleportCustomization.update(change)
  local settings = TeleportCustomization.get()
  change(settings)
  TeleportCustomization.set(settings)
end

return TeleportCustomization
