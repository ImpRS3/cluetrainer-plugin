local luaflet = require("prettymap/luaflet")
local geometry = require("cluetrainer/map/elements/geometry")
local AreaGraphics = require("cluetrainer/map/elements/AreaGraphics")
local InteractionMarker = require("cluetrainer/map/elements/InteractionMarker")
local PropertiesTooltip = require("cluetrainer/map/elements/PropertiesTooltip")

-- TODO: verify against the original digSpotRect; the dig area is assumed to extend this many tiles around the spot.
local DIG_RADIUS = 1

--- The spot to dig at: a shaded dig area plus a shovel marker, with an explanatory tooltip.
---@class cluetrainer.DigSolutionEntity : prettymap.luaflet.Twig
---@field marker cluetrainer.InteractionMarker
local DigSolutionEntity = setmetatable({}, { __index = luaflet.twigs.Twig })
DigSolutionEntity.__index = DigSolutionEntity

--- The shaded dig area around `spot`.
---@param spot TileCoordinates
---@param single_tile boolean? Shade only the spot's tile instead of the dig area.
---@return prettymap.luaflet.PolygonTwig
function DigSolutionEntity.area_graphics(spot, single_tile)
  local radius = single_tile and 0 or DIG_RADIUS
  return AreaGraphics.rect({
    topleft = { x = spot.x - radius, y = spot.y + radius },
    botright = { x = spot.x + radius, y = spot.y - radius },
    level = spot.level,
  }, { colour = 0x808080, opacity = 0.5, fillOpacity = 0.1 })
end

---@param solution Solution.Dig
---@return cluetrainer.DigSolutionEntity
function DigSolutionEntity.new(solution)
  local self = setmetatable(luaflet.twigs.Twig.new(), DigSolutionEntity)
  ---@cast self cluetrainer.DigSolutionEntity

  self:Add(DigSolutionEntity.area_graphics(solution.spot))
  self.marker = InteractionMarker.new({
    coordinate = geometry.coord(solution.spot),
    cursor = "shovel",
  })
  self:Add(self.marker)

  local spot = solution.spot
  local header = solution.description and ("Dig " .. solution.description .. " to solve the clue")
      or string.format("Dig at %d, %d, %d to solve the clue", spot.x, spot.y, spot.level)
  self.marker:SetTooltip(PropertiesTooltip.new():Header(header))
  return self
end

return DigSolutionEntity
