-- ScanGround.lua
-- The scan drawn in the game world: the green area to scan in, a dig highlight per remaining spot coloured by the
-- pulse it gives where the player stands, and the faded routes the player chooses between.
local path_shapes           = require "cluetrainer/solving/common/path_shapes"
local colours            = require "cluetrainer/util/colours"
local scan_tree          = require "cluetrainer/solving/scan/scan_tree"
local scan_display       = require "cluetrainer/solving/scan/scan_display"
local tiles              = require("cluetrainer/math/math").tilecoordinates
local HighlightGroup     = require "zyklib/highlights/HighlightGroup"

-- Highlight colours are tints of a white mesh, see `zyklib.Highlight:setColour`. All RGBA.
local SCAN_AREA_LINE     = 0x00FF00FF
local SCAN_AREA_FILL     = 0x00FF0080
-- The only spot left keeps the usual dig highlight: white, untinted.
local NO_TINT            = 0xFFFFFFFF
local PREVIEW_FADE       = 0xFFFFFF60
local PREVIEW_AREA_LINE_ALPHA = 0xA0
local PREVIEW_AREA_FILL_ALPHA = 0x30
-- Areas float a little above the ground, below the dig highlights at AREA_OVERLAY_HEIGHT.
local AREA_HEIGHT        = path_shapes.OverlayConstants.AREA_OVERLAY_HEIGHT / 2

---@class ct.ScanRoutePreview
---@field path Path.Raw
---@field area TileArea? Where the route leads
---@field colour integer RGBA colour of the pulse that picks this route

---@class ct.ScanGround : zyklib.disposable.IDisposable
---@field private scan_area zyklib.Highlight?
---@field private spots table<string, {spot: TileCoordinates, highlight: zyklib.Highlight, colour: integer?}>
---@field private count integer
---@field private preview zyklib.HighlightGroup?
local ScanGround = {}
ScanGround.__index = ScanGround

---@return ct.ScanGround
function ScanGround.new()
  return setmetatable({ spots = {}, count = 0 }, ScanGround)
end

--- Highlights the area where the player scans or digs next.
---@param area TileArea? nil removes it
function ScanGround:setScanArea(area)
  if self.scan_area then self.scan_area:deactivate() end
  self.scan_area = area and path_shapes.areaHighlight(area, SCAN_AREA_LINE, SCAN_AREA_FILL, AREA_HEIGHT):activate()
end

--- Highlights the remaining spots; spots that dropped out lose their highlight.
---@param remaining TileCoordinates[]
function ScanGround:setSpots(remaining)
  local wanted = {}
  for _, spot in ipairs(remaining) do wanted[tiles.key(spot)] = spot end

  for id, entry in pairs(self.spots) do
    if wanted[id] == nil then
      entry.highlight:deactivate()
      self.spots[id] = nil
    end
  end

  for id, spot in pairs(wanted) do
    if self.spots[id] == nil then
      local highlight = path_shapes.digHighlight(spot):activate()
      self.spots[id] = { spot = spot, highlight = highlight }
    end
  end

  self.count = #remaining
end

--- Colours every spot by the pulse it gives at the player's tile, in the colours of the rows, so the player sees which
--- spots a pulse there rules out. With one spot left it is the plain dig highlight.
---@param tile TileCoordinates?
---@param range integer
function ScanGround:colourByPulse(tile, range)
  for _, entry in pairs(self.spots) do
    local colour = NO_TINT
    if self.count > 1 and tile ~= nil then
      local pulse, different_level = scan_tree.pulseAt(entry.spot, tile, range)
      colour = scan_display.pulseColour({ pulse = pulse, different_level = different_level })
    end

    if colour ~= entry.colour then
      entry.colour = colour
      entry.highlight:setColour(colour)
    end
  end
end

--- Draws the routes the player chooses between faded, each with where it leads in its pulse colour.
---@param previews ct.ScanRoutePreview[]
function ScanGround:setPreview(previews)
  if self.preview then self.preview:deactivate() end

  local highlights = {}
  for _, preview in ipairs(previews) do
    highlights[#highlights + 1] = path_shapes.pathHighlight(preview.path):setColour(PREVIEW_FADE):setIgnoreDepth(true)

    if preview.area ~= nil then
      highlights[#highlights + 1] = path_shapes.areaHighlight(preview.area,
        colours.withAlpha(preview.colour, PREVIEW_AREA_LINE_ALPHA), colours.withAlpha(preview.colour, PREVIEW_AREA_FILL_ALPHA),
        AREA_HEIGHT)
    end
  end
  self.preview = HighlightGroup.new(highlights):activate()
end

function ScanGround:dispose()
  self:setScanArea(nil)
  self:setSpots({})
  self:setPreview({})
end

return ScanGround
