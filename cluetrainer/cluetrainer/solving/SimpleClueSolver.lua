local clue_detector          = require "cluetrainer/clue_detector"
local coordinate_adaptor     = require "cluetrainer/model/shared/coordinate_adaptor"
local PathMesh               = require "cluetrainer/model/PathMesh"
local TileArea               = require "cluetrainer/model/shared/TileArea"
local OverlayConstants       = require "cluetrainer/model/OverlayConstants"
local map                    = require "cluetrainer/map/map"
local Element                = require "prettymap/elements/Element"
local TalkSolutionNpcEntity  = require "cluetrainer/map/elements/TalkSolutionNpcEntity"
local SearchSolutionEntity   = require "cluetrainer/map/elements/SearchSolutionEntity"
local DigSolutionEntity      = require "cluetrainer/map/elements/DigSolutionEntity"
local EmoteAreaEntity        = require "cluetrainer/map/elements/EmoteAreaEntity"
local HideyHoleEntity        = require "cluetrainer/map/elements/HideyHoleEntity"
local InteractionMarker      = require "cluetrainer/map/elements/InteractionMarker"
local Bounds                 = require "cluetrainer/util/Bounds"
local methods                = require "cluetrainer/solving/methods"
local Navigator              = require "cluetrainer/solving/navigator"
local SimpleClueSolver       = {}
local zyklib                 = require "zyklib"
local MutableMesh            = require "zyklib/MutableMesh"

SimpleClueSolver.initialized = false

---@param step Step
---@return Solution?
local function inferSolution(step)
  if step.solution ~= nil then return step.solution end

  if step.type == "coordinates" then
    local sextant = {
      offsetx = 2440,
      offsetz = 3161,
      minutespertile = 1.875
    }

    return {
      type = "dig",
      spot = {
        x = sextant.offsetx +
            math.floor((60 * step.coordinates.longitude.degrees + step.coordinates.longitude.minutes) *
              (step.coordinates.longitude.direction == "west" and -1 or 1) / sextant.minutespertile + 0.5),
        y = sextant.offsetz +
            math.floor((60 * step.coordinates.latitude.degrees + step.coordinates.latitude.minutes) *
              (step.coordinates.latitude.direction == "south" and -1 or 1) / sextant.minutespertile + 0.5),
        level = 0
      }
    }
  end

  return nil
end

---comment
---@param step Step
local function create_step_highlights(step)
  local cube = MutableMesh.new()
      :add(MutableMesh.cube():faces_only():recolor(0xFFFFFF80))
      :add(MutableMesh.cube():lines_only():recolor(0xFFFFFFFF))
      :shapeData()


  ---@type zyklib.TerrainHighlight[]
  local highlights = {}

  if step.type == "emote" then
    table.insert(highlights, zyklib.highlights.TerrainHighlight.new(
      zyklib.api_util.map_square_rect_from_tiles({ coordinate_adaptor.tile_coordinates_to_coord_grid(step.area.origin) }),
      function()
        return PathMesh.drawTileArea(step.area, 0x914183FF, 0x91418380)
            :translate(Vector3.new(0, OverlayConstants.AREA_OVERLAY_HEIGHT, 0))
            :shapeData()
      end
    ))
  end

  local solution = inferSolution(step)

  if solution ~= nil then
    if solution.type == "dig" then
      local spot = solution
          .spot --[[@as TileCoordinates]] -- LuaCats does not narrow the type of step.solution to DigSolution, so we need to cast this

      table.insert(highlights, zyklib.highlights.TerrainHighlight.new(
        zyklib.api_util.map_square_rect_from_tiles({ coordinate_adaptor.tile_coordinates_to_coord_grid(spot) }),
        function()
          return PathMesh.drawTileArea(TileArea.centered_on(spot, { x = 3, y = 3 }), 0xFFFFFFFF, 0xFFFFFF80)
              :translate(Vector3.new(0, OverlayConstants.AREA_OVERLAY_HEIGHT, 0))
              :shapeData()
        end
      ))
    elseif solution.type == "talkto" then
      table.insert(highlights, zyklib.highlights.NpcHighlight.new(function(npc)
          return npc.displayName == solution.npc
        end,
        function(npc)
          return {
            shapeData = cube,
            translation = npc.aabb:GetCorner(BoxCornerType.LEFT_BOTTOM_NEAR) - Vector3.new(0.1) * npc.aabb.dimensions,
            scale = Vector3.new(1.2) * npc.aabb.dimensions,
            colour = 0xFFFF00A0
          }
        end
      ))
    elseif solution.type == "search" then
      local spot = solution
          .spot --[[@as TileRectangle]] -- LuaCats does not narrow the type of step.solution to SearchSolution, so we need to cast this

      local LOC_SCALE = 2

      table.insert(highlights, zyklib.highlights.LocHighlight.new({
          name = solution.entity,
          coordGrid = coordinate_adaptor.tile_coordinates_to_coord_grid({
            x = spot.topleft.x,
            y = spot.botright.y,
            level =
                spot.level
          }),
          range = 2
        },
        function(loc)
          return {
            shapeData = cube,
            translation = loc.aabb:GetCorner(BoxCornerType.LEFT_BOTTOM_NEAR) -
                Vector3.new((LOC_SCALE - 1) / 2) * loc.aabb.dimensions,
            scale = Vector3.new(LOC_SCALE) * loc.aabb.dimensions,
            colour = 0x00FFFFA0
          }
        end
      ))
    end
  end

  return zyklib.highlights.HighlightGroup.new(highlights)
end

---Construct the map elements that are relevant for the given step
---@param step Step
---@return prettymap.Element
local function create_step_map_layer(step)
  local layer = Element.new()

  local solution = inferSolution(step)

  if solution ~= nil then
    if solution.type == "talkto" then
      TalkSolutionNpcEntity.new(solution.npc, solution.spots[1]):AddTo(layer)
    elseif solution.type == "search" then
      SearchSolutionEntity.new(solution --[[@as Solution.Search]]):AddTo(layer)
    elseif solution.type == "dig" then
      DigSolutionEntity.new(solution --[[@as Solution.Dig]]):AddTo(layer)
    end
  end

  if step.type == "emote" then
    EmoteAreaEntity.new(step --[[@as Emote]]):AddTo(layer)

    if step.hidey_hole ~= nil then
      HideyHoleEntity.new(step --[[@as Emote]]):AddTo(layer)
    end
  end

  if step.type == "skilling" then
    InteractionMarker.new({
      coordinate = coordinate_adaptor.tile_coordinates_to_coord_grid(TileArea.ensure_mutable(step.areas[0]):center()),
      cursor = step.cursor
    })
  end

  return layer

  -- Implementation for creating a map layer for the given step
end

---@param step Step
---@return ct.Bounds
local function clue_map_bounds(step)
  local bounds = Bounds.new()

  local sol = inferSolution(step)

  if sol.type == "talkto" then
    local spot = sol.spots[1]

    bounds:addArea(spot.range)
  elseif sol.type == "dig" then
    bounds:addTile(sol.spot)
  elseif sol.type == "search" then
    bounds:addRectangle(sol.spot)
  end

  if step.type == "emote" then
    bounds:addArea(step.area)
  elseif step.type == "skilling" then
    bounds:addRectangle(TileArea.toRect(step.areas[0]))
  end

  return bounds
end

---@param method Method.GenericPath
---@return Path.Step[]
local function stitch_path(method)
  local all = zyklib.array.filter({ method.pre_path, method.main_path }, function(step) return step ~= nil end)
  return zyklib.array.flatten(all)
end

--- An ActiveSimpleClue is the instance that manages everything about a single simple clue currently in progress.
---@class ActiveSimpleClue : zyklib.disposable.IDisposable
---@field private navigator Navigator?
local ActiveSimpleClue = {}

---@param clue Step
---@return ActiveSimpleClue
function ActiveSimpleClue.new(clue)
  ---@class ActiveSimpleClue
  local self = setmetatable({
    clue = clue,
    disposable_group = zyklib.disposable.DisposableGroup.new()
  }, { __index = ActiveSimpleClue })

  self.disposable_group:add(create_step_highlights(clue):activate())
  self.disposable_group:add(create_step_map_layer(clue):AddTo(map.ensure_open().map.elements))

  ---@type Method.GenericPath?
  local method = methods.resolve({ clue = clue.id })

  self:setMethod(method)

  -- TODO: Hook up to some sort of method selector

  local bounds = clue_map_bounds(clue)

  if not method then
    --- Only fit to the basic clue target bounds if there is no method available initially
    map.ensure_open():fitBounds(bounds)
  end

  return self
end

---@param method Method.GenericPath?
function ActiveSimpleClue:setMethod(method)
  if self.navigator ~= nil then
    self.navigator:dispose()
    self.navigator = nil
  end

  if method then
    self.navigator = Navigator.new()
    self.navigator:set(stitch_path(method))
  end
end

function ActiveSimpleClue.dispose(self)
  self:setMethod(nil)
  self.disposable_group:dispose()
end

function SimpleClueSolver.init()
  if SimpleClueSolver.initialized then return end
  SimpleClueSolver.initialized = true

  ---@type ActiveSimpleClue?
  local active_clue = nil

  clue_detector.clue_detected_event:subscribe(function(clue)
    -- Handle the detected clue here

    if active_clue ~= nil and (clue == nil or active_clue.clue ~= clue) then
      active_clue:dispose()
      active_clue = nil
    end

    ---@type ClueType[]
    local COMPATIBLE_CLUE_TYPES = { "simple", "anagram", "cryptic", "emote", "map", "skilling", "coordinates" }

    if clue ~= nil and active_clue == nil and zyklib.array.includes(COMPATIBLE_CLUE_TYPES, clue.type) then
      active_clue = ActiveSimpleClue.new(clue)
    end
  end)
end

return SimpleClueSolver
