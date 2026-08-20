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

---@type zyklib.TerrainHighlight?
local emote_highlight = nil

---
---@param step Step
function orchestrator:setStep(step)
  if emote_highlight ~= nil then
    emote_highlight:deactivate()
    emote_highlight = nil
  end

  local progress = getProgress(step.tier)

  -- Discard duplicate
  if self.state and self.state.step == step and self.state.progressIndex == progress then
    return
  end

  self.state = {
    step = step,
    progressIndex = getProgress(step.tier)
  }

  table.insert(self.history, self.state)

  log(self.state)

  if step.type == "emote" then
    if emote_highlight == nil then
      log("Creating emote highlight for step " .. step.id)
      emote_highlight = TerrainHighlight.new(
        TerrainHighlight.bounds_from_samples({coordinate_adaptor.tile_coordinates_to_coord_grid(step.area.origin)}),
        function()
          local shape = MutableMesh.cube()
              :scale3(Vector3.new(512 * step.area.size.x, 1, 512 * step.area.size.y))
              :recolor(0x91418380)
              :translate(Vector3.new(0, 128, 0) + api_util.resolve_ground_height(coordinate_adaptor.tile_coordinates_to_coord_grid(step.area.origin):ToCoordFine(false)))
          log(shape)

          return shape:shapeData()
        end
      ):activate()
    end
  end

  local method = resolveMethod(step)

  if method ~= nil then
    if method.type == "general_path" then
      Navigator.instance:set(method.main_path)
    elseif method.type == "scantree" then

    end
  end
end

return orchestrator
