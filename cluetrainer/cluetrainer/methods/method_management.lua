local ClueIndex         = require "cluetrainer/util/ClueIndex"
local storage           = require "cluetrainer/util/storage"
local schema            = require "cluetrainer/util/schema"

---@type ct.ClueIndex<ct.AugmentedMethod<Method>>
local method_index      = ClueIndex.new(function() return {} end)

---@class ct.methods.method_management
local method_management = {}

---@class ct.AugmentedMethod
---@field method Method
---@field pack MethodPack
---@field clue ClueSpot

---@class ct.AugmentedMethod.Generic
---@field method Method.GenericPath
---@field pack MethodPack
---@field clue ClueSpot

---@class ct.AugmentedMethod.Scan
---@field method Method.ScanTree
---@field pack MethodPack
---@field clue ClueSpot

local function refreshIndex()
  local packs = {
    require "cluetrainer/data/methods/easy_methods",
    require "cluetrainer/data/methods/medium_methods",
    require "cluetrainer/data/methods/hard_methods",
    require "cluetrainer/data/methods/compass_methods",
    require "cluetrainer/data/methods/scan_methods",
    require "cluetrainer/data/methods/tetracompass_methods",
    require "cluetrainer/data/methods/master_methods",
  }

  for _, pack in ipairs(packs) do
    for _, method in ipairs(pack.methods) do
      table.insert(method_index:get(method["for"]), { method = method, pack = pack, clue = method["for"] })
    end
  end
end

refreshIndex()

---Returns all known methods for the given clue spot.
---@param spot ClueSpot.Id
---@return ct.AugmentedMethod<Method>[]
function method_management.getAllForClue(spot)
  return method_index:get(spot)
end

---@param spot ClueSpot.Id
local function hash_clue_spot(spot)
  local x = spot.spot and spot.spot.x or 0
  local y = spot.spot and spot.spot.y or 0
  local level = spot.spot and spot.spot.level or 0
  return spot.clue .. "|" .. x .. "," .. y .. "," .. level
end

local favorites = ctGlobal.persistence:profileVariable("method_preferences", schema.any({}))

---@param methods ct.AugmentedMethod<Method>[]
---@return ct.AugmentedMethod<Method>?
local function find_fastest_method(methods)
  return zyklib.array.minBy(methods, function(method) return method.method.expected_time end)
end

---@param spot ClueSpot.Id
---@param fallback (fun(methods: ct.AugmentedMethod<Method>[]): ct.AugmentedMethod<Method>)?
---@return ct.AugmentedMethod<Method>?
function method_management.getPreferred(spot, fallback)
  fallback = fallback or find_fastest_method

  local saved_preference_id = favorites:get()[hash_clue_spot(spot)]

  if saved_preference_id == "none" then
    return nil
  else
    local candidates = method_index:get(spot)

    local found = zyklib.array.find(candidates, function(candidate)
      return candidate.method.id == saved_preference_id
    end)

    if found ~= nil then
      return found
    else
      return fallback(candidates)
    end
  end
end

---Sets the preferred method for the given clue spot.
---@param spot ClueSpot.Id
---@param method Method?
function method_management.setPreferred(spot, method)
  local table = favorites:get()

  -- On nil values, we explicitly write the string "none" to distinguish from no preference set
  local value = method and method.id or "none"

  table[hash_clue_spot(spot)] = value

  -- Reset favorites to trigger persistence
  favorites:set(table)
end

return method_management
