--- CompassSolver.lua

local ctmath             = require("cluetrainer/ctlib/math")
local luaflet            = require("prettymap/luaflet")
local map                = require("cluetrainer/interfaces/map/map")
local coordinate_adaptor = require("cluetrainer/model/shared/coordinate_adaptor")
local Bounds             = require("cluetrainer/util/Bounds")
local Path               = require("cluetrainer/model/shared/path")
local ActiveClueSolver   = require("cluetrainer/solving/common/ActiveClueSolver")
local Navigator          = require("cluetrainer/solving/common/navigator")
local MapSectionControl  = require("cluetrainer/solving/map_navigator/MapSectionControl")
local PathStepEntity     = require("cluetrainer/solving/map_navigator/PathStepEntity")
local PathMesh           = require("cluetrainer/model/PathMesh")
local ClueStateAction    = require("cluetrainer/interfaces/cluestate/ClueStateAction")
local TeleportAction     = require("cluetrainer/solving/common/TeleportAction")
local tiles              = require("cluetrainer/model/shared/tiles")
local schema             = require("cluetrainer/util/schema")

---@class ct.compasslogic
local compasslogic       = {}

---@class ct.Compass.TriangulationPoint
---@field origin TileCoordinates
---@field angle_radians number
---@field uncertainty_radians number

---@param player_position TileCoordinates
---@param compass_spot TileCoordinates
---@return number # The angle in radians
function compasslogic.getExpectedAngle(player_position, compass_spot)
  local REFERENCE_VECTOR = { x = 1, y = 0 }
  local actual_vector = {
    x = compass_spot.x - player_position.x,
    y = compass_spot.y - player_position.y
  }

  return ctmath.angles.normalize(math.atan(ctmath.vector2.det(REFERENCE_VECTOR, actual_vector),
    ctmath.vector2.dot(REFERENCE_VECTOR, actual_vector)))
end

---@param information ct.Compass.TriangulationPoint[]
---@param spot TileCoordinates
---@return boolean
function compasslogic.isPossible(information, spot)
  return zyklib.array.forAll(information, function(point)
    local expected_angle = compasslogic.getExpectedAngle(point.origin, spot)
    local difference = ctmath.angles.angleDifference(expected_angle, point.angle_radians)

    return difference < point.uncertainty_radians
  end)
end

local SpotMarker = require "cluetrainer/interfaces/map/elements/SpotMarker"

---@param clue Compass
---@param info ct.Compass.TriangulationPoint
---@param color integer
local function drawArrowArc(clue, info, color)
  -- Implementation for drawing an arrow arc on the map

  local origin = info.origin
  local angle_radians = info.angle_radians
  local uncertainty_radians = info.uncertainty_radians


  local function beam(angle)
    local direction = { x = math.cos(angle), y = math.sin(angle) }
    return ctmath.vector2.scale(ctmath.rectangle.rayExit(clue.valid_area, origin, direction), direction)
  end

  local beam_left = beam(angle_radians + uncertainty_radians)
  local beam_right = beam(angle_radians - uncertainty_radians)

  local twig = luaflet.twigs.PolygonTwig.new()

  local l = ctmath.vector2.add(origin, beam_left)
  local r = ctmath.vector2.add(origin, beam_right)

  twig:AddTriangle(origin, r, l, color)

  return twig
end

---@class ct.ActiveCompassSolver : ct.ActiveClueSolver
---@field triangulation_points {info: ct.Compass.TriangulationPoint, twig: prettymap.luaflet.Twig}[]
---@field clue Compass
---@field private REDACTED_target TileCoordinates? The compass target the triangulation points were read towards. Hidden information, must not be exposed to the player
---@field candidates {spot: TileCoordinates, marker: ct.SpotMarker, possible: boolean}[]
---@field private navigator Navigator?
---@field private map_navigator ct.MapSectionControl?
---@field private path_twig prettymap.luaflet.Twig?
---@field private dig_spot TileCoordinates? The spot the dig highlight is on
---@field private dig_highlight zyklib.Highlight?
---@field private clue_state ct.ClueStateInterface
---@field private method ct.AugmentedMethod<Method.GenericPath>?
local CompassSolver = setmetatable({}, { __index = ActiveClueSolver })
CompassSolver.__index = CompassSolver

CompassSolver.settings = {
  beam_color = ctGlobal.persistence:profileVariable("compasses/beam_color", schema.colour({ default = 0x3388ff50 })),
}

---@param clue Compass
---@param state_window ct.ClueStateInterface
---@return ct.ActiveCompassSolver
function CompassSolver.new(clue, state_window)
  ---@class ct.ActiveCompassSolver
  local self = setmetatable(ActiveClueSolver.new(clue), CompassSolver)
  self.clue_state = state_window
  self.map_layer = luaflet.twigs.Twig.new():AddTo(map.get().map.twigs)
  self.disposable_group:add(zyklib.disposable.wrap(function()
    self.map_layer:Detach()
  end))
  self.triangulation_points = {}

  self.disposable_group:add(
    zyklib.game_events.native.ServerLogic:subscribe(function()
      local info = self:getCurrentInformation()
      if info ~= nil then
        self:maybePushInformation(info)
      end
    end)
  )

  self.candidates = zyklib.array.map(clue.spots, function(spot, i)
    return {
      spot = spot,
      marker = SpotMarker.new({
        spot = spot,
        spot_id = i - 1,
        single_tile = clue.single_tile_target,
        title = "Compass spot",
        hint = "",
      }):AddTo(self.map_layer),
      possible = true
    }
  end)

  self.actions = {}
  self.actions.identify = ClueStateAction.Text.new("")
  self.actions.teleport = TeleportAction.new(nil)
  self.disposable_group:add(state_window.method_selected:subscribe(function(method)
    self:setMethod(method)
  end))

  --There is no reasonable way to track completion of the following three
  --self.actions.defeat_wizard = state_window:addAction(ClueStateAction.Text.new("Defeat Wizard"))
  --self.actions.complete_puzzle = state_window:addAction(ClueStateAction.Text.new("Complete Puzzle"))
  --self.actions.dig_again = state_window:addAction(ClueStateAction.Text.new("Dig again"))

  state_window:setClueSpot({ clue = clue })
  self:update()

  return self
end

---@param info ct.Compass.TriangulationPoint
function CompassSolver:maybePushInformation(info)
  local is_new = zyklib.array.exists(self.candidates, function(candidate)
    return candidate.possible and not (compasslogic.isPossible({ info }, candidate.spot))
  end)

  -- Discard redundant information
  if not is_new then return end

  table.insert(self.triangulation_points,
  { info = info, twig = drawArrowArc(self.clue, info, CompassSolver.settings.beam_color:get()):AddTo(self.map_layer) })

  self:update()
end

function CompassSolver:update()
  local remaining_candidates = 0
  local identified_solution = nil

  -- Update state of all candidates
  for _, candidate in ipairs(self.candidates) do
    candidate.possible = zyklib.array.forAll(self.triangulation_points, function(tp)
      return compasslogic.isPossible({ tp.info }, candidate.spot)
    end)

    if candidate.possible then
      remaining_candidates = remaining_candidates + 1

      if remaining_candidates == 1 then
        identified_solution = candidate.spot
      else
        identified_solution = nil
      end
    end

    candidate.marker:setPossible(candidate.possible)
  end

  self.actions.identify
      :setText(identified_solution and ("Dig at " .. (identified_solution.x .. "|" .. identified_solution.y)) or
        (remaining_candidates .. " candidates"))
  -- :setState(identified_solution and "complete" or "incomplete")

  -- TODO: Render shapes for candidates

  local previous_spot = self.identified_spot
  self.identified_spot = remaining_candidates == 1 and identified_solution or nil

  -- The identified spot gets the large pin with its dig area on the map, and the dig highlight in the world.
  for _, candidate in ipairs(self.candidates) do
    candidate.marker:setActive(self.identified_spot ~= nil and candidate.possible)
  end
  self:setDigHighlight(self.identified_spot)

  if previous_spot ~= self.identified_spot then
    self.clue_state:setClueSpot({ clue = self.clue, spot = self.identified_spot })
  end

  if remaining_candidates > 1 then
    self:fitRemainingCandidates()
  end
end

function CompassSolver:buildActions()
  self.clue_state:clearActions()
  self.clue_state:addAction(self.actions.identify)
  if self.method then self.clue_state:addAction(self.actions.teleport) end
end

---@param method ct.AugmentedMethod<Method.GenericPath>?
function CompassSolver:setMethod(method)
  self.method = method
  self:setPath(method and method.method.main_path or nil)
  self:buildActions()
end

---@param path Path.Raw?
function CompassSolver:setPath(path)
  if self.navigator ~= nil then
    self.navigator:dispose()
    self.navigator = nil
  end

  if self.map_navigator ~= nil then
    self.map_navigator:dispose()
    self.map_navigator = nil
  end

  if self.path_twig ~= nil then
    self.path_twig:Detach()
    self.path_twig = nil
  end

  if path ~= nil then
    self.navigator = Navigator.new(function(teleport)
      self.actions.teleport:setTeleport(teleport)
    end)
    self.navigator:set(path)

    local sectioned_path = Path.split_into_sections(path)
    local steps = zyklib.array.flatMap(sectioned_path, function(section) return section.steps end)
    self.path_twig = PathStepEntity.route(steps):AddTo(map.get().map.twigs)

    self.map_navigator = MapSectionControl.new(map.get(),
      zyklib.array.map(sectioned_path, function(sec) return { name = sec.name, bounds = Path.bounds(sec.steps) } end))
  end
end

--- Highlights the dig spot in the world; nil removes the highlight.
---@param spot TileCoordinates?
function CompassSolver:setDigHighlight(spot)
  if spot == self.dig_spot then return end
  if self.dig_highlight then self.dig_highlight:deactivate() end

  self.dig_spot = spot
  self.dig_highlight = spot and PathMesh.digHighlight(spot, self.clue.single_tile_target):activate() or nil
end

function CompassSolver:dispose()
  self:setPath(nil)
  self:setDigHighlight(nil)
  ActiveClueSolver.dispose(self)
end

---@return ct.Compass.TriangulationPoint? # The current degree of the compass arrow, or nil if unavailable.
function CompassSolver:getCurrentInformation()
  ---@param clue Compass
  ---@return ComponentId
  function arrowComponentIdForTier(clue)
    if clue.tier == "master" then
      --- masters use a different interface
      return id.Component.TRAIL_COMPASSCLUE_EASTERNLANDS_SIDE__TRAIL_LINE
    else
      -- elite and tetracompass reuse the same interface.
      return id.Component.TRAIL_COMPASSCLUE_SIDE__TRAIL_LINE
    end
  end

  -- ATTENTION: The the following uses hidden information that we can't tell the player directly (TRAIL_DESTCOORD).
  -- However, due to an api bug it is the only way to determine a compass angle for now.
  -- We calculate the expected angle, and round it to a reasonable accuracy to emulate the uncertainty of visual observation.
  -- This value is based on the compass reading accuracy we achieved in Alt1 with screen reading.
  local UNCERTAINTY_RADIANS = ctmath.angles.degreesToRadians(0.5)

  local component = ui.Interfaces:GetComponent(arrowComponentIdForTier(self.clue))

  --- If component is not visible, the player cannot see the compass arrow, so we discard the reading
  if component == nil or not component.visibleGlobal or component.parent == nil then
    return nil
  end

  local player_position = coordinate_adaptor.playerTile()
  if player_position == nil then return nil end

  -- Hidden value, we obscure it to emulate the uncertainty of visual observation.
  local REDACTED_target_spot = coordinate_adaptor.coord_grid_to_tile_coordinates(var.VarClient["TRAIL_DESTCOORD"]
    .value --[[@as CoordGrid]])
  self:followTarget(REDACTED_target_spot)

  return compasslogic.reading(player_position, REDACTED_target_spot, self.clue.valid_area, UNCERTAINTY_RADIANS)
end

--- The reading the compass arrow gives at the player's position, or nil if it gives none: on another level than the
--- target (the arrow spins), outside the clue's valid area, or on the target tile itself, where there is no direction.
---@param player_position TileCoordinates
---@param target_spot TileCoordinates
---@param valid_area table The clue's valid area, a rectangle
---@param uncertainty_radians number The angle is rounded to multiples of this
---@return ct.Compass.TriangulationPoint?
function compasslogic.reading(player_position, target_spot, valid_area, uncertainty_radians)
  -- If the player and the target are on different levels, the compass would be spinning, so the reading must be discarded
  if player_position.level ~= target_spot.level then return nil end
  -- If the player is not within the valid area, the compass would be spinning, so we must discard the angle reading
  if not ctmath.rectangle.contains(valid_area, player_position) then return nil end
  -- If the player is on the target tile itself, there is no direction to point to, so we discard the reading
  if player_position.x == target_spot.x and player_position.y == target_spot.y then return nil end

  local expected_precise_angle = compasslogic.getExpectedAngle(player_position, target_spot)
  local uncertain_angle = ctmath.round(expected_precise_angle / uncertainty_radians) * uncertainty_radians

  return { origin = player_position, angle_radians = uncertain_angle, uncertainty_radians = uncertainty_radians }
end

--- Starts the triangulation over when the compass target changes, so readings towards the previous target (the game
--- may still report the last compass's spot right after a dig) don't rule out the new spot.
---@param target TileCoordinates
function CompassSolver:followTarget(target)
  local previous = self.REDACTED_target
  self.REDACTED_target = target
  if previous == nil or tiles.same(previous, target) or #self.triangulation_points == 0 then return end

  for _, point in ipairs(self.triangulation_points) do point.twig:Detach() end
  self.triangulation_points = {}
  self:update()
end

function CompassSolver:fitRemainingCandidates()
  local bounds = Bounds.new()

  for _, candidate in ipairs(self.candidates) do
    if candidate.possible then
      bounds:addTile(candidate.spot)
    end
  end

  bounds:extend(0.1)

  map.get():fitBounds(bounds)
end

return CompassSolver
