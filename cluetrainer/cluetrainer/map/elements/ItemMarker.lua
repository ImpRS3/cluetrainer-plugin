local elements = require("prettymap/elements")

local MARKER_SIZE = 24 -- pixels
local HOVER_FACTOR = 1.5

--- A fixed-size icon of an item. Grows on hover; attach a tooltip with `SetTooltip`.
---@class cluetrainer.ItemMarker : prettymap.Element
---@field obj integer Obj id of the item.
local ItemMarker = setmetatable({}, { __index = elements.Element })
ItemMarker.__index = ItemMarker

---@param coordinate CoordGrid
---@param obj integer
---@return cluetrainer.ItemMarker
function ItemMarker.new(coordinate, obj)
  local self = setmetatable(elements.Element.new({
    coordinate = coordinate,
    size = MARKER_SIZE,
    zoomScale = false,
    hoverSize = MARKER_SIZE * HOVER_FACTOR,
    zLayer = "marker",
  }), ItemMarker)
  ---@cast self cluetrainer.ItemMarker
  self.obj = obj
  return self
end

---@param layer ui.Layer
---@return boolean added
function ItemMarker:CreateComponent(layer)
  local sprite = ui.Sprite.new(layer)
  sprite:SetSize(0, 0, 1.0, 1.0)
  sprite:SetAssociatedObject(self.obj)
  sprite.clickthrough = true
  return true
end

return ItemMarker
