local ClueIndex = require "cluetrainer/util/ClueIndex"
local methods = {}

local method_index = ClueIndex.new(function()
  return {}
end)

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
      table.insert(method_index:get(method["for"]), method)
    end
  end
end

refreshIndex()

---@param spot ClueSpot.Id
---@return Method.GenericPath?
function methods.resolve(spot)
  local candidates = method_index:get(spot)

  --- TODO: Implement a proper selection strategy that respects the users preferences
  return candidates[1]
end

return methods
