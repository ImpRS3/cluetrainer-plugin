local zyklib = require("zyklib")

---@class cluetrainer.FontFamily
---@field private by_weight table<string, cluetrainer.SizedFont[]> Per weight, sorted by ascending size.
local FontFamily = {}
FontFamily.__index = FontFamily

---@class cluetrainer.SizedFont
---@field size integer
---@field weight string Lowercase weight, e.g. "bold".
---@field name string The font's config name.
---@field font FontType

--- Extracts font properties from a font's configName. Return nil (or a non-numeric size) to skip the font.
--- A nil or empty weight is indexed as "regular".
---@alias cluetrainer.FontNameParser fun(config_name: string): {size: number, weight: string}?

--- Builds a family from all of `config.Font`, indexed by weight and size. `parse` decides which
--- fonts belong to the family and what their size and weight are.
---
--- Example: `FontFamily.create(function(name)
---   local size, weight = name:match("^MUSEO_SANS_(%d+)PT_(%a+)$")
---   return tonumber(size), weight
--- end)` indexes `MUSEO_SANS_13PT_BOLD` as size 13, weight "bold".
---@param parse cluetrainer.FontNameParser
---@return cluetrainer.FontFamily
function FontFamily.create(parse)
  local by_weight = {}
  -- config.Font maps font names to ids and also holds helper functions such as FromID.

  for name, f in pairs(config.Font) do
    if f.configName ~= nil then
      local match = parse(f.configName)
      if match ~= nil then
        local list = by_weight[match.weight:lower()]
        if not list then
          list = {}
          by_weight[match.weight:lower()] = list
        end
        list[#list + 1] = { size = match.size, weight = match.weight, name = name, font = f }
      end
    end
  end
  for _, list in pairs(by_weight) do
    -- The name breaks ties so the order is deterministic.
    table.sort(list, function(a, b)
      if a.size ~= b.size then return a.size < b.size end
      return a.name < b.name
    end)
  end

  ---@class cluetrainer.FontFamily
  return setmetatable({ by_weight = by_weight }, FontFamily)
end

--- Returns the largest font of the given weight whose size is at most `size`.
---@param size number
---@param weight string? Default "regular".
---@return FontType?
function FontFamily:Get(size, weight)
  local best = zyklib.array.findLast(self.by_weight[(weight or "regular"):lower()] or {},
    function(sized) return sized.size <= size end)
  return best and best.font or nil
end

FontFamily.NOTOSANS = FontFamily.create(function(name)
  local weight, size = name:match("^NOTOSANS_(%a*)_?(%d+)$")
  if not size then return nil end
  return { size = tonumber(size), weight = weight or "regular" }
end)

-- MUSEO_SANS_13PT_BOLD -> bold 13. `%a+` stops at the underscore, so the MULTILINE and
-- HEAVY_ITALIC variants do not match and are ignored.
FontFamily.MUSEO_SANS = FontFamily.create(function(name)
  local size, weight = name:match("^MUSEO_SANS_(%d+)PT_(%a+)$")
  if not size then return nil end
  return { size = tonumber(size), weight = weight or "regular" }
end)

return FontFamily
