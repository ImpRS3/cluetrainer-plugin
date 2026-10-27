local luaflet = require("prettymap/luaflet")
local coordinate_adaptor = require("cluetrainer/model/shared/coordinate_adaptor")
local FontFamily = require("cluetrainer/util/FontFamily")
local TeleportTooltip = require("cluetrainer/interfaces/map/elements/TeleportTooltip")

local HOVER_FACTOR = 1.5 -- of the largest zoom step
-- Pixel size per map zoom step: icons are small while the map is crowded and
-- stop growing once they are readable. `minScale` is the map's pixels per tile.
local ZOOM_STEPS = {
  { minScale = 0,   size = 24 },
  { minScale = 1.5, size = 30 },
  { minScale = 4,   size = 36 },
}
-- The text uses BASE_FONT_SIZE when the icon is BASE_ICON_HEIGHT pixels tall and scales with the icon.
local BASE_ICON_HEIGHT = 15
local BASE_FONT_SIZE = 7
-- Tint (RGBA) approximating a slight grayscale filter for spots on other planes.
local OFF_PLANE_TINT = 0xA0A0A0B4

---@param mapScale number
---@return number pixels
local function zoom_size(mapScale)
  local size = ZOOM_STEPS[1].size
  for _, step in ipairs(ZOOM_STEPS) do
    if mapScale >= step.minScale then size = step.size end
  end
  return size
end

---@class cluetrainer.TeleportElement: prettymap.luaflet.Twig
---@field teleport cluetrainer.TeleportSpot
---@field overlay_text ui.Text?
---@field sprite ui.Sprite?
---@field home_level integer The plane the teleport is on.
local TeleportElement = setmetatable({}, { __index = luaflet.twigs.Twig })
TeleportElement.__index = TeleportElement

function TeleportElement:_UpdateSize()
  luaflet.twigs.Twig._UpdateSize(self)
  -- Spots without a sprite have no text.
  local text = self.overlay_text
  if not text then return end
  local scale = self.height / BASE_ICON_HEIGHT -- active zoom and hover scale
  -- The largest bold font not exceeding the scaled size; hidden if none is small enough.
  local font = FontFamily.NOTOSANS:Get(BASE_FONT_SIZE * scale, "bold")

  text.hidden = font == nil
  if font then text.font = font.id end
end

---@param plane integer
function TeleportElement:_OnPlaneChanged(plane)
  -- Spots on other planes are still drawn at their x/z position, but dimmed.
  local tint = self.home_level == plane and 0xFFFFFFFF or OFF_PLANE_TINT
  self.sprite.rgba = tint
  if self.overlay_text then self.overlay_text.rgba = tint end
end

---@param layer ui.Layer
---@return boolean added
function TeleportElement:CreateComponent(layer)
  local teleport = self.teleport

  -- Without a sprite nothing is added and the layer is discarded.
  if not teleport.props.cache_data then return false end

  local sprite = ui.Sprite.new(layer)
  self.sprite = sprite
  sprite:SetSize(0, 0, 1.0, 1.0)

  if teleport.props.cache_data.sprite then
    sprite.sprite = id.Sprite[teleport.props.cache_data.sprite]
  elseif teleport.props.cache_data.obj then
    sprite:SetAssociatedObject(id.Obj[teleport.props.cache_data.obj])
  end

  sprite.clickthrough = true

  -- Spots without a code only show the sprite.
  if teleport:code() ~= "" then
    local overlay_text = ui.Text.new(layer)
    overlay_text:SetSize(0, 0, 1.0, 1.0)
    overlay_text.content = teleport:code()
    overlay_text.rgba = 0xFFFFFFFF
    overlay_text.isShadowed = true
    overlay_text.alignHorizontal = ui.AlignMode.CENTRE
    overlay_text.alignVertical = ui.AlignMode.CENTRE
    overlay_text.clickthrough = true

    self.overlay_text = overlay_text
    self:_UpdateSize()
  end

  return true
end

---@param teleport cluetrainer.TeleportSpot
---@return cluetrainer.TeleportElement
function TeleportElement.new(teleport)
  ---@class cluetrainer.TeleportElement
  local self = luaflet.twigs.Twig.new({
    coordinate = luaflet.coord(coordinate_adaptor.tile_coordinates_to_coord_grid(teleport:center_of_target())),
    size = 1, -- scaled to `zoom_size` pixels by the zoom step
    zoomScale = zoom_size,
    hoverSize = ZOOM_STEPS[#ZOOM_STEPS].size * HOVER_FACTOR,
    zLayer = "marker",
    allPlanes = true,
  })
  self.teleport = teleport
  self.home_level = self.coordinate.level
  setmetatable(self, TeleportElement)
  self:SetTooltip(TeleportTooltip.new(teleport))
  return self
end

return TeleportElement
