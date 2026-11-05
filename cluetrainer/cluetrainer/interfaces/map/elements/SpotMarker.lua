local luaflet = require("prettymap/luaflet")
local geometry = require("cluetrainer/interfaces/map/elements/geometry")
local DigSolutionEntity = require("cluetrainer/interfaces/map/elements/DigSolutionEntity")
local PropertiesTooltip = require("cluetrainer/interfaces/map/elements/PropertiesTooltip")

-- Alt1's pin size in pixels while active. The tip is the bottom centre of the image.
local PIN_WIDTH = 18
local PIN_HEIGHT = 24
local INACTIVE_FACTOR = 0.5
local HOVER_FACTOR = 1.5
local IMPOSSIBLE_ALPHA = 0x20

---@class ct.SpotMarkerOptions
---@field spot TileCoordinates
---@field spot_id integer? Zero-based index of the spot; shown one-based in the tooltip.
---@field single_tile boolean? Whether the dig area of the active spot is just its tile.
---@field title string? Tooltip header, followed by the spot number. Default "Spot".
---@field hint string? Tooltip text below the header.

--- A pin whose tip marks a possible dig spot of a compass or scan clue, with a fixed pixel size. It is shrunk while
--- inactive, dimmed while impossible. The active spot additionally shows its dig area.
---@class ct.SpotMarker : prettymap.luaflet.Twig
---@field spot TileCoordinates
---@field single_tile boolean
---@field possible boolean
---@field active boolean
---@field sprite ui.Sprite?
---@field area prettymap.luaflet.Twig?
local SpotMarker = setmetatable({}, { __index = luaflet.twigs.Twig })
SpotMarker.__index = SpotMarker

---@param options ct.SpotMarkerOptions
---@return ct.SpotMarker
function SpotMarker.new(options)
  local self = setmetatable(luaflet.twigs.Twig.new({
    coordinate = geometry.coord(options.spot),
    zoomScale = false,
    -- Makes the marker hoverable; `_ComputeSize` gives the size while hovered.
    hoverSize = PIN_HEIGHT * HOVER_FACTOR,
    -- The tip on the spot, so the pin grows upwards.
    pivotX = 0.5,
    pivotY = 1.0,
    zLayer = "marker",
  }), SpotMarker)
  ---@cast self ct.SpotMarker

  self.spot = options.spot
  self.single_tile = options.single_tile or false
  self.possible = true
  self.active = false
  -- Here, as the map only resizes elements without zoom scaling on hover.
  self:_UpdateSize()

  local title = options.title or "Spot"
  local tooltip = PropertiesTooltip.new():Header(options.spot_id and (title .. " " .. (options.spot_id + 1)) or title)
  if options.hint then tooltip:Paragraph(options.hint) end
  self:SetTooltip(tooltip)

  return self
end

--- Alt1's pin size: half while inactive, larger while hovered.
---@return number width
---@return number height
function SpotMarker:_ComputeSize()
  local factor = (self.active and 1 or INACTIVE_FACTOR) * (self.hovered and HOVER_FACTOR or 1)
  return math.floor(PIN_WIDTH * factor + 0.5), math.floor(PIN_HEIGHT * factor + 0.5)
end

---@private
function SpotMarker:_ApplyAppearance()
  local alpha = self.possible and 0xFF or IMPOSSIBLE_ALPHA
  local tint = 0xFFFFFF00 + alpha

  if self.sprite then self.sprite.rgba = tint end
end

---@param possible boolean
---@return ct.SpotMarker self
function SpotMarker:setPossible(possible)
  if self.possible ~= possible then
    self.possible = possible
    self:_ApplyAppearance()
  end
  return self
end

---@param active boolean
---@return ct.SpotMarker self
function SpotMarker:setActive(active)
  if self.active == active then return self end
  self.active = active
  self:_UpdateSize()

  if active and not self.area then
    self.area = DigSolutionEntity.area_graphics(self.spot, self.single_tile)
    self:Add(self.area)
  elseif not active and self.area then
    self:Remove(self.area)
    self.area = nil
  end

  return self
end

---@param layer ui.Layer
---@return boolean added
function SpotMarker:CreateComponent(layer)
  local sprite = ui.Sprite.new(layer)
  -- Fills the layer, which has the pin's size.
  sprite:SetSize(0, 0, 1.0, 1.0)
  sprite.sprite = Plugin.resources["marker_red"]
  sprite.clickthrough = true
  self.sprite = sprite

  self:_ApplyAppearance()
  return true
end

return SpotMarker
