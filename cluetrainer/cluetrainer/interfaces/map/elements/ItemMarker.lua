local luaflet = require("prettymap/luaflet")
local item_icon = require("cluetrainer/util/item_icon")

local MARKER_SIZE = 24 -- pixels
local HOVER_FACTOR = 1.5

--- A fixed-size icon of an item. Grows on hover; attach a tooltip with `SetTooltip`.
---@class cluetrainer.ItemMarker : prettymap.luaflet.Twig
---@field obj integer Obj id of the item.
local ItemMarker = setmetatable({}, { __index = luaflet.twigs.Twig })
ItemMarker.__index = ItemMarker

---@param coordinate prettymap.luaflet.Coord
---@param obj integer
---@return cluetrainer.ItemMarker
function ItemMarker.new(coordinate, obj)
  local self = setmetatable(luaflet.twigs.Twig.new({
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
  item_icon.fill(sprite)
  sprite:SetAssociatedObject(self.obj)
  sprite.clickthrough = true
  return true
end

return ItemMarker
