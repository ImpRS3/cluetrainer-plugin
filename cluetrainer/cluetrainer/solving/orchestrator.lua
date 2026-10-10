local lua_util             = require "zyklib/lua_util"
local easy_methods         = require "cluetrainer/data/easy_methods"
local medium_methods       = require "cluetrainer/data/medium_methods"
local hard_methods         = require "cluetrainer/data/hard_methods"
local compass_methods      = require "cluetrainer/data/compass_methods"
local scan_methods         = require "cluetrainer/data/scan_methods"
local master_methods       = require "cluetrainer/data/master_methods"
local tetracompass_methods = require "cluetrainer/data/tetracompass_methods"
local Navigator            = require "cluetrainer/solving/navigator"
local TerrainHighlight     = require "zyklib/highlights/TerrainHighlight"
local MutableMesh          = require "zyklib/MutableMesh"
local coordinate_adaptor   = require "cluetrainer/model_shared/coordinate_adaptor"
local api_util             = require "zyklib/api_util"
local HighlightGroup       = require "zyklib/highlights/HighlightGroup"
local LocHighlight         = require "zyklib/highlights/LocHighlight"
local NpcHighlight         = require "zyklib/highlights/NpcHighlight"
local PathMesh             = require "cluetrainer/model/PathMesh"
local TileArea             = require "cluetrainer/model_shared/TileArea"
local OverlayConstants     = require "cluetrainer/model/OverlayConstants"
local ScanTreeSolver       = require "cluetrainer/solving/ScanTreeSolver"
local clue_detector        = require "cluetrainer/clue_detector"

local packs                = {
  easy_methods,
  medium_methods,
  hard_methods,
  compass_methods,
  scan_methods,
  master_methods,
  tetracompass_methods
}

---@class State
---@field step Step
---@field progressIndex integer


---@class Orchestrator
---@field state State?
---@field history State[]
local orchestrator = {
  state = nil,
  history = {},
}

---@param tier ClueTier
---@return integer
local function getProgress(tier)
  ---@type {[ClueTier]: string}
  local map = {
    easy = "TRAIL_STEPS_EASY",
    medium = "TRAIL_STEPS_MEDIUM",
    hard = "TRAIL_STEPS_HARD",
    elite = "TRAIL_STEPS_ELITE",
    master = "TRAIL_STEPS_MASTER"
  }

  return var.VarPlayer[map[tier]].value
end

---@param step Step
---@return Method?
local function resolveMethod(step)
  for _, pack in ipairs(packs) do
    for _, method in ipairs(pack.methods) do
      if method["for"].clue == step.id then
        return method
      end
    end
  end

  return nil
end

---@type zyklib.HighlightGroup?
local clue_related_highlights = nil

---@type ScanTreeSolver?
local scan_tree_solver = nil

local cube = MutableMesh.new()
    :add(MutableMesh.cube():faces_only():recolor(0xFFFFFF80))
    :add(MutableMesh.cube():lines_only():recolor(0xFFFFFFFF))
    :shapeData()

---comment
---@param step Step
local function create_step_highlights(step)
  ---@type zyklib.TerrainHighlight[]
  local highlights = {}

  log(MutableMesh.new()
    :add(MutableMesh.cube():lines_only():recolor(0xFFFFFFFF)))

  if step.type == "emote" then
    table.insert(highlights, TerrainHighlight.new(
      api_util.map_square_rect_from_tiles({ coordinate_adaptor.tile_coordinates_to_coord_grid(step.area.origin) }),
      function()
        return PathMesh.drawTileArea(step.area, 0x914183FF, 0x91418380)
            :translate(Vector3.new(0, OverlayConstants.AREA_OVERLAY_HEIGHT, 0))
            :shapeData()
      end
    ))
  end

  if step.type == "scan" or step.type == "compass" then
    for key, spot in pairs(step.spots) do
      table.insert(highlights, TerrainHighlight.new(
        api_util.map_square_rect_from_tiles({ coordinate_adaptor.tile_coordinates_to_coord_grid(spot) }),
        function()
          return PathMesh.drawTileArea(TileArea.centered_on(spot, { x = 3, y = 3 }), 0xFFFFFFFF, 0xFFFFFF80)
              :translate(Vector3.new(0, OverlayConstants.AREA_OVERLAY_HEIGHT, 0))
              :shapeData()
        end
      ))
    end
  end

  if step.solution ~= nil then
    if step.solution.type == "dig" then
      local spot = step.solution
      .spot --[[@as TileCoordinates]]                           -- LuaCats does not narrow the type of step.solution to DigSolution, so we need to cast this

      table.insert(highlights, TerrainHighlight.new(
        api_util.map_square_rect_from_tiles({ coordinate_adaptor.tile_coordinates_to_coord_grid(spot) }),
        function()
          return PathMesh.drawTileArea(TileArea.centered_on(spot, { x = 3, y = 3 }), 0xFFFFFFFF, 0xFFFFFF80)
              :translate(Vector3.new(0, OverlayConstants.AREA_OVERLAY_HEIGHT, 0))
              :shapeData()
        end
      ))
    elseif step.solution.type == "talkto" then
      table.insert(highlights, NpcHighlight.new(function(npc)
          return npc.displayName == step.solution.npc
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
    elseif step.solution.type == "search" then
      local spot = step.solution
          .spot --[[@as TileRectangle]] -- LuaCats does not narrow the type of step.solution to SearchSolution, so we need to cast this

      local LOC_SCALE = 2

      table.insert(highlights, LocHighlight.new({
          name = step.solution.entity,
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

  return HighlightGroup.new(highlights)
end

---@param path Path
local function teleport_to_start(path)
  local first = path[1]

  if first.type == "teleport" then
    local tele = coordinate_adaptor.tile_coordinates_to_coord_grid(first.spot)

    ExecuteConsoleCommand("!tele " ..
      tele.level .. "," .. tele.mapSquareX .. "," .. tele.mapSquareZ .. "," .. tele.localX .. "," .. tele.localZ)
  end
end

local gameArea = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA)

local window = prettyui.Window.new(gameArea, {
  title = "Clue Trainer",
  x = -210,
  y = -150,
  xAnchor = 0.5,
  yAnchor = 0.5,
  width = 470,
  height = 400,
  minWidth = 320,
  minHeight = 220,
  scrollable = true,
  rowBackgroundColours = {
    0x24211EFF,
    0x2E2825FF,
  }
})

local map = prettymap.Map.new(window.content, {
  x = 0,
  y = 0,
  width = 420,
  height = 300,
  showFloorControls = true,
  showZoomControls = true,
  showPlayerMarker = false,
  trackPlayer = false,
  onError = function(message)
    print("PrettyMap:", message)
  end,
})

map.player:SetTrackPlayer(false)
map.player:ClearPlayerPosition()

window:Show()

---comment
---@param step Step
---@return CoordGrid?
local function spot(step)
  if step.solution ~= nil then
    if step.solution.type == "talkto" then
      return coordinate_adaptor.tile_coordinates_to_coord_grid(step.solution.spots[1].range.origin)
    elseif step.solution.type == "dig" then
      return coordinate_adaptor.tile_coordinates_to_coord_grid(step.solution.spot)
    elseif step.solution.type == "search" then
      return coordinate_adaptor.tile_coordinates_to_coord_grid(step.solution.spot.botright)
    end
  end
end

local marker = nil

---
---@param step Step
function orchestrator:setStep(step)
  local progress = getProgress(step.tier)

  -- Discard duplicate
  if self.state and self.state.step == step and self.state.progressIndex == progress then
    return
  end

  -- Disable existing scan tree solver
  if scan_tree_solver ~= nil then
    scan_tree_solver:stop()
    scan_tree_solver = nil
  end

  if clue_related_highlights ~= nil then
    clue_related_highlights:deactivate()
    clue_related_highlights = nil
  end

  self.state = {
    step = step,
    progressIndex = getProgress(step.tier)
  }

  if marker ~= nil then
    marker:Destroy()
    marker = nil
  end

  local target = spot(step)

  if target ~= nil then
    marker = map.overlays:CreateMarker({
      position = target,
      spriteID = id.Sprite.CLUE_SCROLL_ICON,
      size = 64,
    })

    map:ZoomToMapSquare(target)
  end

  table.insert(self.history, self.state)

  clue_related_highlights = create_step_highlights(step):activate()

  local method = resolveMethod(step)

  if method ~= nil then
    if method.type == "general_path" then
      teleport_to_start(method.main_path)

      Navigator.instance:set(method.main_path)
    elseif method.type == "scantree" then
      scan_tree_solver = ScanTreeSolver.new(method):start()
      teleport_to_start(method.tree.root.path)
    end
  end
end

function orchestrator.init()
  -- Listen for clue detection events
  clue_detector.clue_detected_event:subscribe(function(clue)
    orchestrator:setStep(clue)
  end)
end

return orchestrator
