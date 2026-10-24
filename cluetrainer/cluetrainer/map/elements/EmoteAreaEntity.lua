local elements = require("prettymap/elements")
local geometry = require("cluetrainer/map/elements/geometry")
local AreaGraphics = require("cluetrainer/map/elements/AreaGraphics")
local InteractionMarker = require("cluetrainer/map/elements/InteractionMarker")
local PropertiesTooltip = require("cluetrainer/map/elements/PropertiesTooltip")

--- "a, b, and c" / "a, then b, then c" style lists.
---@param values string[]
---@param last_separator string Used before the last value, e.g. ", and ".
---@return string
local function join(values, last_separator)
  if #values <= 1 then return values[1] or "" end
  return table.concat(values, ", ", 1, #values - 1) .. last_separator .. values[#values]
end

--- The area of an emote clue: an outline with an emote marker in the centre and a tooltip.
---@class cluetrainer.EmoteAreaEntity : prettymap.Element
---@field clue Emote
---@field marker cluetrainer.InteractionMarker
local EmoteAreaEntity = setmetatable({}, { __index = elements.Element })
EmoteAreaEntity.__index = EmoteAreaEntity

---@param clue Emote
---@param options cluetrainer.EntityOptions?
---@return cluetrainer.EmoteAreaEntity
function EmoteAreaEntity.new(clue, options)
  local highlight = options ~= nil and options.highlight == true
  local self = setmetatable(elements.Element.new(), EmoteAreaEntity)
  ---@cast self cluetrainer.EmoteAreaEntity
  self.clue = clue

  self:Add(AreaGraphics.area(clue.area, {
    colour = 0x914183,
    weight = highlight and 4 or 2,
    opacity = 1,
    fillOpacity = 0.2,
  }))
  -- The area itself cannot be hovered, so the tooltip hangs on a marker in its centre.
  self.marker = InteractionMarker.new({
    coordinate = geometry.area_center(clue.area),
    cursor = "emote",
    highlight = highlight,
  })
  self:Add(self.marker)

  local multiple = #clue.emotes > 1
  local action = (multiple and "emotes" or "emote")
  local tooltip = PropertiesTooltip.new():Header("Emote area")
  if clue.double_agent then
    tooltip:Paragraph(("Perform the %s here. Kill the double agent to summon and talk to Uri."):format(action))
  else
    tooltip:Paragraph(("Perform the %s here to summon and talk to Uri."):format(action))
  end
  tooltip:Row("Items", join(clue.items, ", and "))
  tooltip:Row(#clue.emotes ~= 1 and "Emotes" or "Emote", join(clue.emotes, ", then "))
  if clue.double_agent then tooltip:Subheader("Spawns double agent") end
  self.marker:SetTooltip(tooltip)
  return self
end

return EmoteAreaEntity
