local lua_util             = require "zyklib/lua_util"
local easy_methods         = require "data/easy_methods"
local medium_methods       = require "data/medium_methods"
local hard_methods         = require "data/hard_methods"
local compass_methods      = require "data/compass_methods"
local scan_methods         = require "data/scan_methods"
local master_methods       = require "data/master_methods"
local tetracompass_methods = require "data/tetracompass_methods"
local Navigator            = require "solving/navigator"
local TerrainHighlight     = require "zyklib/highlights/TerrainHighlight"
local MutableMesh          = require "zyklib/MutableMesh"
local coordinate_adaptor   = require "model_shared/coordinate_adaptor"
local api_util             = require "zyklib/api_util"
local HighlightGroup       = require "zyklib/highlights/HighlightGroup"
local LocHighlight         = require "zyklib/highlights/LocHighlight"
local NpcHighlight         = require "zyklib/highlights/NpcHighlight"
local PathMesh             = require "model/PathMesh"
local TileArea             = require "model_shared/TileArea"
local OverlayConstants     = require "model/OverlayConstants"

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
      local spot = step.solution.spot
      ---@cast spot TileCoordinates LuaCats does not narrow the type of step.solution to DigSolution, so we need to cast this

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
      local spot = step.solution.spot
      ---@cast spot TileRectangle LuaCats does not narrow the type of step.solution to SearchSolution, so we need to cast this

      local LOC_SCALE = 1.05

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

---
---@param step Step
function orchestrator:setStep(step)
  local progress = getProgress(step.tier)

  -- Discard duplicate
  if self.state and self.state.step == step and self.state.progressIndex == progress then
    return
  end

  if clue_related_highlights ~= nil then
    clue_related_highlights:deactivate()
    clue_related_highlights = nil
  end


  self.state = {
    step = step,
    progressIndex = getProgress(step.tier)
  }

  table.insert(self.history, self.state)

  clue_related_highlights = create_step_highlights(step):activate()

  local method = resolveMethod(step)

  if method ~= nil then
    if method.type == "general_path" then
      Navigator.instance:set(method.main_path)
    elseif method.type == "scantree" then

    end
  end
end

return orchestrator
