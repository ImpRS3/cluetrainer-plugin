--- CompassSolver.lua

local ctmath             = require("cluetrainer/ctlib/math")
local luaflet            = require("prettymap/luaflet")
local map                = require("cluetrainer/interfaces/map/map")
local coordinate_adaptor = require("cluetrainer/model/shared/coordinate_adaptor")
local Bounds             = require("cluetrainer/util/Bounds")
local method_management  = require("cluetrainer/methods/method_management")
local Path               = require("cluetrainer/model/shared/path")
local ActiveClueSolver   = require("cluetrainer/solving/common/ActiveClueSolver")
local Navigator          = require("cluetrainer/solving/common/navigator")
local MapSectionControl  = require("cluetrainer/solving/map_navigator/MapSectionControl")
local PathStepEntity     = require("cluetrainer/solving/map_navigator/PathStepEntity")
local ClueStateAction    = require("cluetrainer/interfaces/cluestate/ClueStateAction")
local MethodAction       = require("cluetrainer/solving/common/MethodAction")
local MethodSelectDialog = require("cluetrainer/methods/MethodSelectDialog")

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


local trail_status = zyklib.game_events.derived.forPlayerVariable(var.VarPlayer["TRAIL_STATUS"], function()
  return {
    --done_emote_or_killed_double_agent_medium = var.VarPlayer
    --   ["TRAIL_STATUS_DONE_CODE_EMOTE_OR_KILLED_DOUBLE_AGENT_MEDIUM"].value,
    --current_clue_needs_sextant_hard = var.VarPlayer["TRAIL_STATUS_CURRENT_CLUE_NEEDS_SEXTANT_HARD"].value,
    --done_emote_or_killed_double_agent_hard = var.VarPlayer["TRAIL_STATUS_DONE_CODE_EMOTE_OR_KILLED_DOUBLE_AGENT_HARD"]
    --    .value,
    --has_killed_monster_hard = var.VarPlayer["TRAIL_STATUS_HAS_KILLED_MONSTER_HARD"].value,
    has_killed_monster_elite = var.VarPlayer["TRAIL_STATUS_HAS_KILLED_MONSTER_ELITE"].value,
    solved_puzzle_elite = var.VarPlayer["TRAIL_STATUS_SOLVED_PUZZLE_ELITE"].value,
    solved_puzzle_master = var.VarPlayer["TRAIL_STATUS_SOLVED_PUZZLE_MASTER"].value,
    has_killed_monster_master = var.VarPlayer["TRAIL_STATUS_HAS_KILLED_MONSTER_MASTER"].value,
  }
end)

trail_status:subscribe(function(status)
  log("Trail status updated")
  log(status)
end, true)

---@class ct.ActiveCompassSolver : ct.ActiveClueSolver
---@field triangulation_points {info: ct.Compass.TriangulationPoint}[]
---@field candidates {spot: TileCoordinates, marker: ct.CompassSpotMarker, possible: boolean}[]
---@field private navigator Navigator?
---@field private map_navigator ct.MapSectionControl?
---@field private path_twig prettymap.luaflet.Twig?
local CompassSolver = setmetatable({}, { __index = ActiveClueSolver })
CompassSolver.__index = CompassSolver

---@param clue Compass
---@param state_window ct.ClueStateInterface
---@return ct.ActiveCompassSolver
function CompassSolver.new(clue, state_window)
  ---@class ct.ActiveCompassSolver
  local self = setmetatable(ActiveClueSolver.new(clue), CompassSolver)
  self.map_layer = luaflet.twigs.Twig.new():AddTo(map.ensure_open().map.twigs)
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
      marker = CompassSpotMarker.new({ spot = spot, spot_id = i - 1 }):AddTo(self.map_layer),
      possible = true
    }
  end)
  
  state_window:clearActions()

  self.actions = {}
  self.actions.identify = state_window:addAction(ClueStateAction.Text.new("Identify Spot"))
  self.actions.method = state_window:addAction(MethodAction.new(nil, {
    onSelectRequested = function(action)
      if self.identified_spot == nil then return end

      MethodSelectDialog.open({
        methods = method_management.getAllForClue({ clue = self.clue.id, spot = self.identified_spot }),
        selected = action.method,
        onSelect = function(method)
          self:setMethod(method)
        end,
      })
    end,
  }))

  self.actions.dig_at = state_window:addAction(ClueStateAction.Text.new("Dig At"))
  --There is no reasonable way to track completion of the following three
  --self.actions.defeat_wizard = state_window:addAction(ClueStateAction.Text.new("Defeat Wizard"))
  --self.actions.complete_puzzle = state_window:addAction(ClueStateAction.Text.new("Complete Puzzle"))
  --self.actions.dig_again = state_window:addAction(ClueStateAction.Text.new("Dig again"))

  self:fitRemainingCandidates()

  return self
end

---@param info ct.Compass.TriangulationPoint
function CompassSolver:maybePushInformation(info)
  local is_new = zyklib.array.exists(self.candidates, function(candidate)
    return candidate.possible and not (compasslogic.isPossible({ info }, candidate.spot))
  end)

  -- Discard redundant information
  if not is_new then return end


  table.insert(self.triangulation_points, { info = info, twig = drawArrowArc(self.clue, info):AddTo(self.map_layer) })

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
      :setText("Identify " .. remaining_candidates .. "/" .. #self.clue.spots)
      :setState(identified_solution and "complete" or "incomplete")

  self.actions.dig_at
      :setText("Dig At " .. (identified_solution and (identified_solution.x .. "|" .. identified_solution.y) or "???"))

  -- TODO: Render shapes for candidates

  self.identified_spot = remaining_candidates == 1 and identified_solution or nil

  if remaining_candidates == 1 then
    -- If there is one remaining candidate, the spot has been identified and we can show a method
    ---@type ct.AugmentedMethod<Method>?
    local method = method_management.getPreferred({
      clue = self.clue.id,
      spot = self.identified_spot
    })

    if method ~= nil then
      log("Method found")
      self:setMethod(method)
    else
      -- TODO: What do we do for identified spots without a selected method?
      log("No method found")
      self:setMethod(nil)
    end
  else
    self:setMethod(nil)

    if remaining_candidates > 1 then
      self:fitRemainingCandidates()
    end
  end
end

---@param method ct.AugmentedMethod<Method.GenericPath>?
function CompassSolver:setMethod(method)
  self.actions.method:setMethod(method)
  self:setPath(method and method.method.main_path or nil)
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
    self.navigator = Navigator.new()
    self.navigator:set(path)

    local sectioned_path = Path.split_into_sections(path)
    self.path_twig = luaflet.twigs.Twig.new():AddTo(map.ensure_open().map.twigs)

    for _, section in ipairs(sectioned_path) do
      for _, step in ipairs(section.steps) do
        PathStepEntity.new(step):AddTo(self.path_twig)
      end
    end

    self.map_navigator = MapSectionControl.new(map.ensure_open(),
      zyklib.array.map(sectioned_path, function(sec) return { name = sec.name, bounds = Path.bounds(sec.steps) } end))
  end
end

function CompassSolver:dispose()
  self:setPath(nil)
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

  local player_position = coordinate_adaptor.coord_grid_to_tile_coordinates(PlayerList.Self().coordGrid)

  -- Hidden value, we obscure it to emulate the uncertainty of visual observation.
  local target_spot = coordinate_adaptor.coord_grid_to_tile_coordinates(var.VarClient["TRAIL_DESTCOORD"]
    .value --[[@as CoordGrid]])

  -- If the player and the target are on different levels, the compass would be spinning, so the reading must be discarded
  if player_position.level ~= target_spot.level then
    return
  end

  -- If the player is not within the valid area, we must discard the angle reading
  if not ctmath.rectangle.contains(self.clue.valid_area, player_position) then
    return nil
  end

  local expected_precise_angle = compasslogic.getExpectedAngle(player_position, target_spot)
  local uncertain_angle = ctmath.round(expected_precise_angle / UNCERTAINTY_RADIANS) * UNCERTAINTY_RADIANS

  return { origin = player_position, angle_radians = uncertain_angle, uncertainty_radians = UNCERTAINTY_RADIANS }
end

function CompassSolver:fitRemainingCandidates()
  local bounds = Bounds.new()

  for _, candidate in ipairs(self.candidates) do
    if candidate.possible then
      bounds:addTile(candidate.spot)
    end
  end

  bounds:extend(0.1)

  map.ensure_open():fitBounds(bounds)
end

return CompassSolver
