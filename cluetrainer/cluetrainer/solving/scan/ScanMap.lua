-- ScanMap.lua
-- The scan on the Clue Trainer map: every dig spot (ruled-out ones dimmed), the route and scan area of the current
-- step, the range squares, the faded routes of the next step, the player and a counter of the spots left.
local luaflet           = require("prettymap/luaflet")
local map               = require("cluetrainer/interfaces/map/map")
local AreaGraphics      = require("cluetrainer/interfaces/map/elements/AreaGraphics")
local SpotMarker        = require("cluetrainer/interfaces/map/elements/SpotMarker")
local PathStepEntity    = require("cluetrainer/solving/map_navigator/PathStepEntity")
local PathGraphics      = require("cluetrainer/interfaces/map/elements/PathGraphics")
local MapLabel          = require("cluetrainer/interfaces/map/elements/MapLabel")
local PlayerMarker      = require("cluetrainer/interfaces/map/elements/PlayerMarker")
local colours           = require("cluetrainer/util/colours")
local Path              = require("cluetrainer/model/shared/path")
local Bounds            = require("cluetrainer/util/Bounds")
local TileArea          = require("cluetrainer/model/shared/TileArea")
local scan_display      = require("cluetrainer/solving/scan/scan_display")
local tiles             = require("cluetrainer/model/shared/tiles")
local array             = require("zyklib/array")

local COUNTER_WIDTH     = 120
local COUNTER_HEIGHT    = 31
-- The counter sits this many pixels below the top of the map, with as much room below it when fitting.
local COUNTER_OFFSET    = 8
local SCAN_AREA_COLOUR  = 0x00FF00
-- Room around the fitted bounds as a fraction of their size, for some overview around the route.
local FIT_MARGIN        = 0.25
-- The smallest view in tiles (one map square), so a short walk to the dig spot doesn't zoom in all the way.
local MIN_VIEW_TILES    = 64
-- Tiles further than this from the route are left out of the fit.
local FIT_DISTANCE_LIMIT = 320
-- Alt1's range squares in the pulse colours (RGB): within range a triple, within twice the range a double.
local RANGE_COLOURS     = { scan_display.PULSE_COLOURS[3] >> 8, scan_display.PULSE_COLOURS[2] >> 8 }
local RANGE_OPACITY     = 0.9
local RANGE_WEIGHT      = 2 -- pixels
local RANGE_DASH        = 1 -- tiles
local AREA_STYLE_OPACITY = 0.8
local AREA_STYLE_FILL   = 0.2
local PREVIEW_OPACITY   = 0.5

---@class ct.ScanMap : zyklib.disposable.IDisposable
---@field private layer prettymap.luaflet.Twig
---@field private route prettymap.luaflet.Twig?
---@field private range_squares prettymap.luaflet.Twig?
---@field private range_signature string?
---@field private preview prettymap.luaflet.Twig?
---@field private player ct.PlayerMarker
---@field private markers ct.SpotMarker[] In the order of `ordered_spots`
---@field private spots TileCoordinates[]
---@field private region TileArea The box around every dig spot
local ScanMap = {}
ScanMap.__index = ScanMap

---@param area TileArea
---@param colour integer RGB
---@return prettymap.luaflet.Twig
local function areaGraphics(area, colour)
  return AreaGraphics.area(area, { colour = colour, opacity = AREA_STYLE_OPACITY, fillOpacity = AREA_STYLE_FILL })
end

---@param tree ScanTree.ScanTree
---@return ct.ScanMap
function ScanMap.new(tree)
  local game_map = map.get()

  local self = setmetatable({
    -- On every plane, so steps whose tiles have another level than the map shows (dungeons) stay visible.
    layer = luaflet.twigs.Twig.new({ allPlanes = true }):AddTo(game_map.map.twigs),
    spots = tree.ordered_spots,
    region = TileArea.around(tree.ordered_spots),
  }, ScanMap)

  self.markers = {}
  for i, spot in ipairs(tree.ordered_spots) do
    self.markers[i] = SpotMarker.new({ spot = spot, spot_id = i - 1, title = "Scan spot" }):AddTo(self.layer)
  end
  self.player = PlayerMarker.new():AddTo(self.layer)

  return self
end

--- Shows the spots that are still possible large, the others small and dimmed.
---@param remaining TileCoordinates[]
function ScanMap:setRemaining(remaining)
  for i, spot in ipairs(self.spots) do
    local possible = array.exists(remaining, function(candidate) return tiles.same(candidate, spot) end)
    self.markers[i]:setPossible(possible):setActive(possible)
  end
end

--- Draws the route and the scan area of the current step, and zooms to what the player does next: the route, and
--- the scan area with both range squares around it, or the dig spots. The other remaining spots stay drawn but are
--- not fitted, so some may lie outside the view.
---@param path Path.Raw
---@param area TileArea?
---@param range integer? Fits the range squares around the scan area; nil for the route to the dig spot
---@param dig_spots TileCoordinates[]? The spots of the last step
function ScanMap:setStep(path, area, range, dig_spots)
  if self.route then self.route:Detach() end
  self.route = PathStepEntity.route(path):AddTo(self.layer)
  if area then areaGraphics(area, SCAN_AREA_COLOUR):AddTo(self.route) end

  -- Fits only the last section, the part of the route that leads to the scan area, and ignores anything further than
  -- Alt1's 320 tiles from it, so a route that starts with a teleport elsewhere doesn't zoom out to both places.
  local sections = Path.split_into_sections(path)
  local bounds = #sections > 0 and Path.bounds(sections[#sections].steps) or Bounds.new()
  bounds:setDistanceLimit(FIT_DISTANCE_LIMIT)
  bounds:addArea(area)
  for _, spot in ipairs(dig_spots or {}) do bounds:addTile(spot) end
  if area and range then bounds:addArea(TileArea.grow(area, #RANGE_COLOURS * range)) end
  self:fit(bounds)
end

--- Zooms to the bounds with some room around them, below the counter.
---@private
---@param bounds ct.Bounds
function ScanMap:fit(bounds)
  local view = bounds:copy():ensureSize(MIN_VIEW_TILES):extend(FIT_MARGIN)
  map.get():fitBounds(view, 2 * COUNTER_OFFSET + COUNTER_HEIGHT)
end

--- Dashed squares where a pulse gives a triple, and where a double. Around the player while they are where a pulse can
--- give a triple or double for some spot, to show what a pulse where they stand tells, also when they walk their own
--- way; otherwise around the scan area to go to. The map follows the player when the squares leave the view.
---@param area TileArea? nil hides them
---@param range integer
---@param player TileCoordinates?
function ScanMap:setRange(area, range, player)
  local centre = area
  if area and player then
    local reach = TileArea.ensure_mutable(TileArea.grow(self.region, #RANGE_COLOURS * range))
    -- Ignores the level, as the scan is drawn on every plane.
    if reach:query(player) then centre = TileArea.tile(player) end
  end

  local outer = centre and TileArea.grow(centre, #RANGE_COLOURS * range)
  local signature = outer and tiles.key(outer.origin) .. "," .. outer.size.x .. "," .. outer.size.y
  if signature == self.range_signature then return end
  self.range_signature = signature

  if self.range_squares then self.range_squares:Detach() end
  self.range_squares = nil
  if centre == nil then return end

  self.range_squares = luaflet.twigs.Twig.new():AddTo(self.layer)
  local level = centre.origin.level or 0

  for i, colour in ipairs(RANGE_COLOURS) do
    -- The outer tile edges (half a tile beyond the centres) of every tile within i * range of the centre.
    local square = TileArea.grow(centre, i * range)
    local x1, y1 = square.origin.x - 0.5, square.origin.y - 0.5
    local x2, y2 = x1 + square.size.x, y1 + square.size.y
    local polygon = luaflet.twigs.PolygonTwig.new()
    local rgba = colours.rgba(colour, RANGE_OPACITY)
    PathGraphics.dashed_line(polygon, x1, y1, x2, y1, level, RANGE_WEIGHT, rgba, RANGE_DASH)
    PathGraphics.dashed_line(polygon, x2, y1, x2, y2, level, RANGE_WEIGHT, rgba, RANGE_DASH)
    PathGraphics.dashed_line(polygon, x2, y2, x1, y2, level, RANGE_WEIGHT, rgba, RANGE_DASH)
    PathGraphics.dashed_line(polygon, x1, y2, x1, y1, level, RANGE_WEIGHT, rgba, RANGE_DASH)
    polygon:AddTo(self.range_squares)
  end

  if centre ~= area then self:keepInView(outer --[[@as TileArea]], area) end
end

--- Zooms to the squares around the player and the scan area once the squares leave the view.
---@private
---@param squares TileArea
---@param area TileArea?
function ScanMap:keepInView(squares, area)
  local game_map = map.get()
  local corners = TileArea.toRect(squares)
  if game_map:shows(corners.topleft) and game_map:shows(corners.botright) then return end

  local bounds = Bounds.new()
  bounds:addArea(squares)
  bounds:addArea(area)
  self:fit(bounds)
end

--- Draws the routes of the next step faded, each with where it leads in the colour of the pulse that picks it.
---@param previews ct.ScanRoutePreview[]
function ScanMap:setPreview(previews)
  if self.preview then self.preview:Detach() end
  self.preview = luaflet.twigs.Twig.new({ opacity = PREVIEW_OPACITY }):AddTo(self.layer)

  for _, preview in ipairs(previews) do
    PathStepEntity.route(preview.path):AddTo(self.preview)
    if preview.area then
      -- Drop the alpha, as the area takes RGB.
      areaGraphics(preview.area, preview.colour >> 8):AddTo(self.preview)
    end
  end
end

--- Marks the player's tile.
---@param tile TileCoordinates?
function ScanMap:setPlayer(tile)
  self.player:setTile(tile)
end

function ScanMap:dispose()
  self.layer:Detach()
end

return ScanMap
