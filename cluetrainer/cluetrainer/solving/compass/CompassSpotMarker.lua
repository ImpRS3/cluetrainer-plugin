local luaflet = require("prettymap/luaflet")
local geometry = require("cluetrainer/interfaces/map/elements/geometry")
local DigSolutionEntity = require("cluetrainer/interfaces/map/elements/DigSolutionEntity")
local PropertiesTooltip = require("cluetrainer/interfaces/map/elements/PropertiesTooltip")
local FontFamily = require("cluetrainer/util/FontFamily")

local ACTIVE_SIZE = 24 -- pixels
local INACTIVE_FACTOR = 0.5
local HOVER_FACTOR = 1.5
local IMPOSSIBLE_ALPHA = 0x20
local BASE_ICON_HEIGHT = 15
local BASE_FONT_SIZE = 7


---@class ct.CompassSpotMarkerOptions
---@field spot TileCoordinates
---@field spot_id integer? Zero-based index of the spot; shown one-based in the tooltip.
---@field single_tile boolean? Whether the dig area of the active spot is just its tile.

--- A compass spot with a fixed pixel size. It is shrunk while inactive, dimmed while impossible and
--- can show a number. The active spot additionally shows its dig area.
---@class ct.CompassSpotMarker : prettymap.luaflet.Twig
---@field spot TileCoordinates
---@field single_tile boolean
---@field possible boolean
---@field number integer?
---@field active boolean
---@field sprite ui.Sprite?
---@field area prettymap.luaflet.Twig?
local CompassSpotMarker = setmetatable({}, { __index = luaflet.twigs.Twig })
CompassSpotMarker.__index = CompassSpotMarker

---@param options ct.CompassSpotMarkerOptions
---@return ct.CompassSpotMarker
function CompassSpotMarker.new(options)
  local self = setmetatable(luaflet.twigs.Twig.new({
    coordinate = geometry.coord(options.spot),
    size = ACTIVE_SIZE * INACTIVE_FACTOR,
    zoomScale = false,
    hoverSize = ACTIVE_SIZE * INACTIVE_FACTOR * HOVER_FACTOR,
    zLayer = "marker",
  }), CompassSpotMarker)
  ---@cast self ct.CompassSpotMarker

  self.spot = options.spot
  self.single_tile = options.single_tile or false
  self.possible = true
  self.active = false

  local header = options.spot_id and ("Compass spot " .. (options.spot_id + 1)) or "Compass spot"
  self:SetTooltip(PropertiesTooltip.new()
    :Header(header)
    :Paragraph("Click to select as solution and view pathing."))

  return self
end

---@private
function CompassSpotMarker:_ApplyAppearance()
  local alpha = self.possible and 0xFF or IMPOSSIBLE_ALPHA
  local tint = 0xFFFFFF00 + alpha

  if self.sprite then self.sprite.rgba = tint end

  local text = self.text
  if text then
    text.rgba = tint
    text.hidden = self.number == nil
    if self.number ~= nil then text.content = tostring(self.number) end

    local font = FontFamily.NOTOSANS:Get(BASE_FONT_SIZE * self.height / BASE_ICON_HEIGHT, "bold")
    if font then
      text.font = font.id
    else
      text.hidden = true
    end
  end
end

function CompassSpotMarker:_UpdateSize()
  luaflet.twigs.Twig._UpdateSize(self)
  self:_ApplyAppearance()
end

---@param possible boolean
---@param number integer?
---@return ct.CompassSpotMarker self
function CompassSpotMarker:setPossible(possible, number)
  if self.possible ~= possible or self.number ~= number then
    self.possible = possible
    self.number = number
    self:_ApplyAppearance()
  end
  return self
end

---@param active boolean
---@return ct.CompassSpotMarker self
function CompassSpotMarker:setActive(active)
  if self.active == active then return self end
  self.active = active

  local size = ACTIVE_SIZE * (active and 1 or INACTIVE_FACTOR)
  self.baseWidth, self.baseHeight = size, size
  self.hoverSize = size * HOVER_FACTOR
  self.zoomFactor = 1
  -- Force the size to be recomputed; the cached size may coincidentally match.
  self.width, self.height = 0, 0
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
function CompassSpotMarker:CreateComponent(layer)
  local sprite = ui.Sprite.new(layer)
  sprite:SetSize(11, 15)
  sprite.sprite = Plugin.resources["marker_red"]
  sprite.clickthrough = true
  self.sprite = sprite

  self:_ApplyAppearance()
  return true
end

return CompassSpotMarker
