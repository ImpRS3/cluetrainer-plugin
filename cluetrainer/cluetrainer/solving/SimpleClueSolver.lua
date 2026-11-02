local clue_detector          = require "cluetrainer/clue_detector"
local coordinate_adaptor     = require "cluetrainer/model/shared/coordinate_adaptor"
local PathMesh               = require "cluetrainer/model/PathMesh"
local TileArea               = require "cluetrainer/model/shared/TileArea"
local OverlayConstants       = require "cluetrainer/model/OverlayConstants"
local map                    = require "cluetrainer/interfaces/map/map"
local TalkSolutionNpcEntity  = require "cluetrainer/interfaces/map/elements/TalkSolutionNpcEntity"
local SearchSolutionEntity   = require "cluetrainer/interfaces/map/elements/SearchSolutionEntity"
local DigSolutionEntity      = require "cluetrainer/interfaces/map/elements/DigSolutionEntity"
local InteractionMarker      = require "cluetrainer/interfaces/map/elements/InteractionMarker"
local Bounds                 = require "cluetrainer/util/Bounds"
local methods                = require "cluetrainer/solving/methods"
local Navigator              = require "cluetrainer/solving/common/navigator"
local Path                   = require "cluetrainer/model/shared/path"
local MapSectionControl      = require "cluetrainer/solving/map_navigator/MapSectionControl"
local luaflet                = require "prettymap/luaflet"
local cluestate              = require "cluetrainer/interfaces/cluestate/cluestate"
local RichText               = require "cluetrainer/util/RichText"
local PathStepEntity         = require "cluetrainer/solving/map_navigator/PathStepEntity"
local zyklib                 = require "zyklib"
local MutableMesh            = require "zyklib/MutableMesh"
local ClueStateAction        = require "cluetrainer/interfaces/cluestate/ClueStateAction"

local SimpleClueSolver       = {}
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
---@return prettymap.luaflet.Twig
local function create_step_map_layer(step)
  local layer = luaflet.twigs.Twig.new()

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

  if step.type == "skilling" then
    InteractionMarker.new({
      coordinate = require("cluetrainer/interfaces/map/elements/geometry").coord(TileArea.ensure_mutable(step.areas[0])
        :center()),
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

  if step.type == "skilling" then
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

---@class ct.SimpleClueActions
---@field talk? ct.interfaces.cluestate.ClueStateAction
---@field dig? ct.interfaces.cluestate.ClueStateAction
---@field obtain_key? ct.interfaces.cluestate.ClueStateAction
---@field search? ct.interfaces.cluestate.ClueStateAction
---@field defeat_wizard? ct.interfaces.cluestate.ClueStateAction
---@field enter_challenge_scroll_answer? ct.interfaces.cluestate.ClueStateAction
---@field solve_slider? ct.interfaces.cluestate.ClueStateAction
---@field solve_celtic_knot? ct.interfaces.cluestate.ClueStateAction
---@field solve_lockbox? ct.interfaces.cluestate.ClueStateAction
---@field solve_towers? ct.interfaces.cluestate.ClueStateAction



--- An ActiveSimpleClue is the instance that manages everything about a single simple clue currently in progress.
---@class ActiveSimpleClue : zyklib.disposable.IDisposable
---@field private navigator Navigator?
---@field private map_navigator ct.MapSectionControl?
---@field private path_twig prettymap.luaflet.Twig?
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
  self.disposable_group:add(create_step_map_layer(clue):AddTo(map.ensure_open().map.twigs))

  ---@type Method.GenericPath?
  local method = methods.resolve({ clue = clue.id })

  self:setMethod(method)

  -- TODO: Hook up to some sort of method selector

  if not method then
    local bounds = clue_map_bounds(clue)
    --- Only fit to the basic clue target bounds if there is no method available initially
    map.ensure_open():fitBounds(bounds)
  end

  -- Claim ownership of the clue state panel and show relevant actions to the player

  ---@type ct.SimpleClueActions
  self.actions = {}

  local state_panel = cluestate.get()

  state_panel:clearActions()

  state_panel:setVisible(true)

  local sol = inferSolution(clue)

  if sol then
    if sol.type == "talkto" then
      self.actions.talk = state_panel:addAction(ClueStateAction.Text.new("Talk to " .. RichText.npc(sol.npc)))
    elseif sol.type == "dig" then
      self.actions.dig = state_panel:addAction(ClueStateAction.Text.new("Dig  " .. (sol.description or "at target")))
    elseif sol.type == "search" then
      if sol.key then
        self.actions.obtain_key = state_panel:addAction(ClueStateAction.Text.new("Obtain key"))
      end

      self.actions.search = state_panel:addAction(ClueStateAction.Text.new("Search " .. RichText.loc(sol.entity)))
    end
  end

  local challenges = clue.challenge

  if challenges ~= nil and #challenges > 0 then
    for _, challenge in ipairs(challenges) do
      if challenge.type == "wizard" then
        self.actions.defeat_wizard = state_panel:addAction(ClueStateAction.Text.new("Defeat wizard "))

        self.actions.defeat_wizard:setState("complete")
      elseif challenge.type == "slider" then
        self.actions.solve_slider = state_panel:addAction(ClueStateAction.Text.new("Complete slider challenge"))
      elseif challenge.type == "celticknot" then
        self.actions.solve_celtic_knot = state_panel:addAction(ClueStateAction.Text.new("Solve Celtic knot challenge"))
      elseif challenge.type == "lockbox" then
        self.actions.solve_lockbox = state_panel:addAction(ClueStateAction.Text.new("Solve lockbox challenge"))
      elseif challenge.type == "towers" then
        self.actions.solve_towers = state_panel:addAction(ClueStateAction.Text.new("Solve towers challenge"))
      elseif challenge.type == "challengescroll" then
        self.actions.enter_challenge_scroll_answer = state_panel:addAction(ClueStateAction.Text.new("Enter answer " ..
        challenge.answers[1]
          .answer)) -- TODO: Automatically determine correct answer
      end
    end
  end

  return self
end

---@param method Method.GenericPath?
function ActiveSimpleClue:setMethod(method)
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
    local path = stitch_path(method)
    self.navigator = Navigator.new()
    self.navigator:set(path)

    local sectioned_path = Path.split_into_sections(path)

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
    local COMPATIBLE_CLUE_TYPES = { "simple", "anagram", "cryptic", "map", "skilling", "coordinates" }

    if clue ~= nil and active_clue == nil and zyklib.array.includes(COMPATIBLE_CLUE_TYPES, clue.type) then
      active_clue = ActiveSimpleClue.new(clue)
    end
  end)
end

return SimpleClueSolver
