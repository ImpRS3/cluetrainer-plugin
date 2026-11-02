local ClueIndex = require "cluetrainer/util/ClueIndex"

---@type ct.ClueIndex<ct.AugmentedMethod<Method>>
local method_index = ClueIndex.new(function() return {} end)

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
---@return ct.AugmentedMethod<Method>?
function method_management.getPreferred(spot)
  local candidates = method_index:get(spot)

  --- TODO: Implement a proper selection strategy that respects the users preferences
  return candidates[1]
end

return method_management
