local elements = require("prettymap/elements")
local coordinate_adaptor = require("cluetrainer/model_shared/coordinate_adaptor")
local FontFamily = require("cluetrainer/util/FontFamily")

local HOVER_SCALE = 1.5

-- Pixel size per map zoom step: icons are small while the map is crowded and
-- stop growing once they are readable. `minScale` is the map's pixels per tile.
local ZOOM_STEPS = {
  { minScale = 0,   size = 24 },
  { minScale = 1.5, size = 36 },
  { minScale = 4,   size = 48 },
}
-- The text uses BASE_FONT_SIZE when the icon is BASE_ICON_HEIGHT pixels tall and scales with the icon.
local BASE_ICON_HEIGHT = 15
local BASE_FONT_SIZE = 7

---@param mapScale number
---@return number pixels
local function zoom_size(mapScale)
  local size = ZOOM_STEPS[1].size
  for _, step in ipairs(ZOOM_STEPS) do
    if mapScale >= step.minScale then size = step.size end
  end
  return size
end

---@class cluetrainer.TeleportElement: prettymap.ComponentElement
---@field overlay_text ui.Text?
local TeleportElement = setmetatable({}, { __index = elements.ComponentElement })
TeleportElement.__index = TeleportElement

function TeleportElement:_UpdateSize()
  elements.ComponentElement._UpdateSize(self)
  -- Spots without a sprite have no text.
  local text = self.overlay_text
  if not text then return end
  local scale = self.height / BASE_ICON_HEIGHT -- active zoom and hover scale
  -- The largest bold font not exceeding the scaled size; hidden if none is small enough.
  local font = FontFamily.NOTOSANS:Get(BASE_FONT_SIZE * scale, "bold")

  log("Selected font:", font and font.configName or "nil")

  text.hidden = font == nil
  if font then text.font = font.id end
end

---@param layer ui.Layer
---@return boolean added
function TeleportElement:CreateComponent(layer)
  local element = self

  local sprite_name = (element.spot.cache_data and element.spot.cache_data.sprite)
      or (element.group.cache_data and element.group.cache_data.sprite)
  -- Without a sprite nothing is added and the layer is discarded.
  if not sprite_name then return false end

  local sprite = ui.Sprite.new(layer)
  sprite:SetSize(0, 0, 1.0, 1.0)
  sprite.sprite = id.Sprite[sprite_name]
  sprite.clickthrough = true

  -- Spots without a code only show the sprite.
  if element.spot.code then
    local overlay_text = ui.Text.new(layer)
    overlay_text:SetSize(0, 0, 1.0, 1.0)
    overlay_text.content = element.spot.code
    overlay_text.rgba = 0xFFFFFFFF
    overlay_text.isShadowed = true
    overlay_text.alignHorizontal = ui.AlignMode.CENTRE
    overlay_text.alignVertical = ui.AlignMode.CENTRE
    overlay_text.clickthrough = true

    element.overlay_text = overlay_text
    element:_UpdateSize()
  end

  return true
end

---@param group TeleportGroup
---@param spot TeleportSpot
---@return cluetrainer.TeleportElement
function TeleportElement.new(group, spot)
  ---@class cluetrainer.TeleportElement
  local self = elements.ComponentElement.new({
    coordinate = coordinate_adaptor.tile_coordinates_to_coord_grid(spot.target.origin),
    size = 1, -- scaled to `zoom_size` pixels by the zoom step
    zoomScale = zoom_size,
    hoverScale = HOVER_SCALE,
  })
  self.group = group
  self.spot = spot
  return setmetatable(self, TeleportElement)
end

return TeleportElement
