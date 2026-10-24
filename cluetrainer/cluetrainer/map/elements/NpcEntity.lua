local elements = require("prettymap/elements")
local geometry = require("cluetrainer/map/elements/geometry")
local AreaGraphics = require("cluetrainer/map/elements/AreaGraphics")
local InteractionMarker = require("cluetrainer/map/elements/InteractionMarker")

---@class cluetrainer.EntityOptions
---@field highlight boolean? Draw larger and, for NPCs, show the roaming range.

--- An NPC with a roaming range: a talk marker in the centre of the range. When highlighted, the range is outlined.
---@class cluetrainer.NpcEntity : prettymap.Element
---@field name string
---@field range TileArea
---@field marker cluetrainer.InteractionMarker
local NpcEntity = setmetatable({}, { __index = elements.Element })
NpcEntity.__index = NpcEntity

---@param name string
---@param range TileArea
---@param options cluetrainer.EntityOptions?
---@return cluetrainer.NpcEntity
function NpcEntity.new(name, range, options)
  local highlight = options ~= nil and options.highlight == true
  local self = setmetatable(elements.Element.new(), NpcEntity)
  ---@cast self cluetrainer.NpcEntity
  self.name = name
  self.range = range

  if highlight then
    self:Add(AreaGraphics.area(range, { colour = 0xFFFF00, opacity = 0.5, fillOpacity = 0.1 }))
  end
  self.marker = InteractionMarker.new({
    coordinate = geometry.area_center(range),
    cursor = "talk",
    highlight = highlight,
  })
  self:Add(self.marker)
  return self
end

return NpcEntity
