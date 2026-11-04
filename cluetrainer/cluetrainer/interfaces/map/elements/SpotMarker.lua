local luaflet = require("prettymap/luaflet")
local geometry = require("cluetrainer/interfaces/map/elements/geometry")
local DigSolutionEntity = require("cluetrainer/interfaces/map/elements/DigSolutionEntity")
local PropertiesTooltip = require("cluetrainer/interfaces/map/elements/PropertiesTooltip")

local ACTIVE_SIZE = 24 -- pixels
local INACTIVE_FACTOR = 0.5
local HOVER_FACTOR = 1.5
local IMPOSSIBLE_ALPHA = 0x20

---@class ct.SpotMarkerOptions
---@field spot TileCoordinates
---@field spot_id integer? Zero-based index of the spot; shown one-based in the tooltip.
---@field single_tile boolean? Whether the dig area of the active spot is just its tile.
---@field title string? Tooltip header, followed by the spot number. Default "Spot".
---@field hint string? Tooltip text below the header.

--- A possible dig spot of a compass or scan clue, with a fixed pixel size. It is shrunk while inactive, dimmed while
--- impossible. The active spot additionally shows its dig area.
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
    size = ACTIVE_SIZE * INACTIVE_FACTOR,
    zoomScale = false,
    hoverSize = ACTIVE_SIZE * INACTIVE_FACTOR * HOVER_FACTOR,
    zLayer = "marker",
  }), SpotMarker)
  ---@cast self ct.SpotMarker

  self.spot = options.spot
  self.single_tile = options.single_tile or false
  self.possible = true
  self.active = false

  local title = options.title or "Spot"
  local tooltip = PropertiesTooltip.new():Header(options.spot_id and (title .. " " .. (options.spot_id + 1)) or title)
  if options.hint then tooltip:Paragraph(options.hint) end
  self:SetTooltip(tooltip)

  return self
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

  local size = ACTIVE_SIZE * (active and 1 or INACTIVE_FACTOR)
  self.baseWidth, self.baseHeight = size, size
  self.hoverSize = size * HOVER_FACTOR
  self.zoomFactor = 1
  -- Reset the cached size, so `_UpdateSize` always applies the new one.
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
function SpotMarker:CreateComponent(layer)
  local sprite = ui.Sprite.new(layer)
  sprite:SetSize(11, 15)
  sprite.sprite = Plugin.resources["marker_red"]
  sprite.clickthrough = true
  self.sprite = sprite

  self:_ApplyAppearance()
  return true
end

return SpotMarker
