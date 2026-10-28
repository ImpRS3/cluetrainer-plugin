--- CompassSolver.lua

local ctmath             = require("cluetrainer/ctlib/math")
local luaflet            = require("prettymap/luaflet")
local map                = require("cluetrainer/interfaces/map/map")
local coordinate_adaptor = require("cluetrainer/model/shared/coordinate_adaptor")
local Bounds             = require("cluetrainer/util/Bounds")
local methods            = require("cluetrainer/solving/methods")
local Path               = require("cluetrainer/model/shared/path")
local Navigator          = require("cluetrainer/solving/common/navigator")
local PathStepEntity     = require("cluetrainer/solving/map_navigator/PathStepEntity")
local MapSectionControl  = require("cluetrainer/solving/map_navigator/MapSectionControl")

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

local clue_detector = require "cluetrainer/clue_detector"
local CompassSpotMarker = require "cluetrainer/solving/compass/CompassSpotMarker"

---@param clue Compass
---@param info ct.Compass.TriangulationPoint
local function drawArrowArc(clue, info)
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

  twig:AddTriangle(origin, r, l, 0x3388ff80)

  return twig
end

---@class ct.ActiveCompassSolver : zyklib.disposable.IDisposable
---@field triangulation_points {info: ct.Compass.TriangulationPoint}[]
---@field candidates {spot: TileCoordinates, marker: ct.CompassSpotMarker, possible: boolean}[]
---@field private navigator Navigator?
---@field private map_navigator ct.MapSectionControl?
---@field private path_twig prettymap.luaflet.Twig?
local ActiveCompassSolver = {}
ActiveCompassSolver.__index = ActiveCompassSolver

---@param clue Compass
function ActiveCompassSolver.new(clue)
  ---@class ct.ActiveCompassSolver
  local self = setmetatable({
    disposables = zyklib.disposable.DisposableGroup.new(),
    clue = clue,
    map_layer = luaflet.twigs.Twig.new():AddTo(map.ensure_open().map.twigs),
    triangulation_points = {}
  }, ActiveCompassSolver)
  self.clue = clue

  self.disposables:add(zyklib.game_events.native.ServerLogic:subscribe(function()
    local info = self:getCurrentInformation()
    if info ~= nil then
      self:maybePushInformation(info)
    end
  end))

  self.candidates = zyklib.array.map(clue.spots, function(spot, i)
    return {
      spot = spot,
      marker = CompassSpotMarker.new({ spot = spot, spot_id = i - 1 }):AddTo(self.map_layer),
      possible = true
    }
  end)

  self:fitRemainingCandidates()

  return self
end

---@param info ct.Compass.TriangulationPoint
function ActiveCompassSolver:maybePushInformation(info)
  local is_new = zyklib.array.exists(self.candidates, function(candidate)
    return candidate.possible and not (compasslogic.isPossible({ info }, candidate.spot))
  end)

  -- Discard redundant information
  if not is_new then
    log("discarding: redundant information")
    return
  end

  log("accepting new information")

  table.insert(self.triangulation_points, { info = info, twig = drawArrowArc(self.clue, info):AddTo(self.map_layer) })

  self:update()
end

function ActiveCompassSolver:update()
  local remaining_candidates = 0

  -- Update state of all candidates
  for _, candidate in ipairs(self.candidates) do
    candidate.possible = zyklib.array.forAll(self.triangulation_points, function(tp)
      return compasslogic.isPossible({ tp.info }, candidate.spot)
    end)

    if candidate.possible then
      remaining_candidates = remaining_candidates + 1
    end

    candidate.marker:setPossible(candidate.possible)
  end

  -- TODO: Render shapes for candidates

  log("Remaining candidates: " .. remaining_candidates)

  if remaining_candidates == 1 then
    -- If there is one remaining candidate, the spot has been identified and we can show a method
    local method = methods.resolve({
      clue = self.clue.id,
      spot = zyklib.array.find(self.candidates, function(candidate)
        return candidate.possible
      end).spot
    })

    if method ~= nil then
      log("Method found")
      self:setMethod(method)

      -- TODO: Hook up to method selector somewhere
    else
      -- TODO: What do we do for identified spots without a selected method?
      log("No method found")
    end
  else
    self:setMethod(nil)

    if remaining_candidates > 1 then
      self:fitRemainingCandidates()
    end
  end
end

---@param method Method.GenericPath?
function ActiveCompassSolver:setMethod(method)
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

  if method then
    self.navigator = Navigator.new()
    self.navigator:set(method.main_path)

    local sectioned_path = Path.split_into_sections(method.main_path)

    self.path_twig = luaflet.twigs.Twig.new()
        :AddTo(map.ensure_open().map.twigs)

    for _, section in ipairs(sectioned_path) do
      for _, step in ipairs(section.steps) do
        PathStepEntity.new(step):AddTo(self.path_twig)
      end
    end

    self.map_navigator = MapSectionControl.new(map.ensure_open(),
      zyklib.array.map(sectioned_path, function(sec) return { name = sec.name, bounds = Path.bounds(sec.steps) } end))
  end
end

function ActiveCompassSolver:dispose()
  self.disposables:dispose()
  self.map_layer:Detach()
end

---@return ct.Compass.TriangulationPoint? # The current degree of the compass arrow, or nil if unavailable.
function ActiveCompassSolver:getCurrentInformation()
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
    log("discarding: compass not visible")
    return nil
  end

  local player_position = coordinate_adaptor.coord_grid_to_tile_coordinates(PlayerList.Self().coordGrid)

  -- Hidden value, we obscure it to emulate the uncertainty of visual observation.
  local target_spot = coordinate_adaptor.coord_grid_to_tile_coordinates(var.VarClient["TRAIL_DESTCOORD"]
    .value --[[@as CoordGrid]])

  -- If the player and the target are on different levels, the compass would be spinning, so the reading must be discarded
  if player_position.level ~= target_spot.level then
    log("discarding: wrong level")
    return
  end

  -- If the player is not within the valid area, we must discard the angle reading
  if not ctmath.rectangle.contains(self.clue.valid_area, player_position) then
    log("discarding: out of area")
    return nil
  end

  local expected_precise_angle = compasslogic.getExpectedAngle(player_position, target_spot)
  local uncertain_angle = ctmath.round(expected_precise_angle / UNCERTAINTY_RADIANS) * UNCERTAINTY_RADIANS

  return { origin = player_position, angle_radians = uncertain_angle, uncertainty_radians = UNCERTAINTY_RADIANS }
end

function ActiveCompassSolver:fitRemainingCandidates()
  local bounds = Bounds.new()

  for _, candidate in ipairs(self.candidates) do
    if candidate.possible then
      bounds:addTile(candidate.spot)
    end
  end

  bounds:extend(0.1)

  map.ensure_open():fitBounds(bounds)
end

local CompassSolver = {}

CompassSolver.initialized = false

function CompassSolver.init()
  if CompassSolver.initialized then return end
  CompassSolver.initialized = true

  ---@type ct.ActiveCompassSolver?
  local active_clue = nil

  clue_detector.clue_detected_event:subscribe(function(clue)
    if active_clue ~= nil and (clue == nil or active_clue.clue ~= clue) then
      active_clue:dispose()
      active_clue = nil
    end

    ---@type ClueType[]
    if clue ~= nil and active_clue == nil and clue.type == "compass" then
      active_clue = ActiveCompassSolver.new(clue)
    end
  end)
end

return CompassSolver
