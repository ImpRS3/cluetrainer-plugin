local path_shapes        = require "cluetrainer/solving/common/path_shapes"
local map                = require "cluetrainer/map/map"
local EmoteAreaEntity    = require "cluetrainer/map/elements/EmoteAreaEntity"
local HideyHoleEntity    = require "cluetrainer/map/elements/HideyHoleEntity"
local Bounds             = require "cluetrainer/util/Bounds"
local Path               = require "cluetrainer/model/path"
local AbstractClueSolver = require "cluetrainer/solving/AbstractClueSolver"
local Navigator          = require "cluetrainer/solving/common/Navigator"
local MapSectionControl  = require "cluetrainer/solving/common/MapSectionControl"
local luaflet            = require "prettymap/luaflet"
local PathStepEntity     = require "cluetrainer/map/elements/PathStepElement"
local RichText           = require "cluetrainer/util/RichText"
local ClueStateAction    = require("cluetrainer/solving/cluestateinterface/ClueStateAction")
local TeleportAction     = require "cluetrainer/solving/cluestateinterface/TeleportAction"
local zyklib             = require "zyklib"

---@param step Emote
local function create_step_highlights(step)
  return zyklib.highlights.HighlightGroup.new({
    path_shapes.areaHighlight(step.area, 0x914183FF, 0x91418380)
  })
end

---@param step Emote
---@return prettymap.luaflet.Twig
local function create_step_map_layer(step)
  local layer = luaflet.twigs.Twig.new()

  EmoteAreaEntity.new(step):AddTo(layer)

  if step.hidey_hole ~= nil then
    HideyHoleEntity.new(step):AddTo(layer)
  end

  return layer
end

---@param method Method.GenericPath
---@return Path.Step[]
local function stitch_path(method)
  local all = zyklib.array.filter({ method.pre_path, method.main_path }, function(step) return step ~= nil end)
  return zyklib.array.flatten(all)
end

---@class ct.EmoteClueActions
---@field teleport ct.solving.TeleportAction
---@field emote_get_hideyhole? ct.interfaces.cluestate.ClueStateAction
---@field equip_items? ct.interfaces.cluestate.ClueStateAction
---@field summon? ct.interfaces.cluestate.ClueStateAction
---@field uri? ct.interfaces.cluestate.ClueStateAction
---@field emote_return_hideyhole? ct.interfaces.cluestate.ClueStateAction

--- An ActiveEmoteClue manages a single emote clue currently in progress.
---@class ct.ActiveEmoteClue : ct.AbstractClueSolver
---@field private navigator Navigator?
---@field private map_navigator ct.MapSectionControl?
---@field private path_twig prettymap.luaflet.Twig?
---@field private clue_state ct.ClueStateInterface
---@field private method Method.GenericPath?
---@field actions ct.EmoteClueActions
local EmoteClueSolver = setmetatable({}, { __index = AbstractClueSolver })
EmoteClueSolver.__index = EmoteClueSolver

---@param clue Emote
---@param clue_state ct.ClueStateInterface
---@return ct.ActiveEmoteClue
function EmoteClueSolver.new(clue, clue_state)
  return AbstractClueSolver.create(EmoteClueSolver, clue, clue_state)
end

---Builds the solver; see `AbstractClueSolver.create`, which disposes it should this fail.
---@private
---@param clue Emote
---@param clue_state ct.ClueStateInterface
function EmoteClueSolver:init(clue, clue_state)
  ---@cast self ct.ActiveEmoteClue
  self.clue_state = clue_state

  self.disposable_group:add(create_step_highlights(clue):activate())
  self.disposable_group:add(create_step_map_layer(clue):AddTo(map.get().map.twigs))

  ---@type ct.EmoteClueActions
  self.actions = { teleport = TeleportAction.new(nil) }

  self.disposable_group:add(clue_state.method_selected:subscribe(function(selected)
    self:setMethod(selected and selected.method --[[@as Method.GenericPath?]])
  end))
  clue_state:setClueSpot({ clue = clue })

  if not self.method then
    local bounds = Bounds.new()
    bounds:addArea(clue.area)
    map.get():fitBounds(bounds)
  end
end

function EmoteClueSolver:buildActions()
  local globetrotter_owned = var.VarPlayer.TRAIL_OUTFIT_FULL_OWNED.value == 31

  local clue = self.clue
  local state_panel = self.clue_state
  state_panel:clearActions()
  if self.method then state_panel:addAction(self.actions.teleport) end

  if self.clue.hidey_hole ~= nil and not globetrotter_owned then
    self.actions.emote_get_hideyhole = state_panel:addAction(ClueStateAction.Text.new("Get hidey-hole"))
  end

  self.actions.equip_items = state_panel:addAction(ClueStateAction.Text.new("Equip outfit"))

  if clue.double_agent then
    self.actions.summon = state_panel:addAction(ClueStateAction.Text.new("Summon and kill " ..
      RichText.npc("Double Agent")))
  else
    self.actions.summon = state_panel:addAction(ClueStateAction.Text.new("Summon " .. RichText.npc("Uri")))
  end

  self.actions.uri = state_panel:addAction(ClueStateAction.Text.new("Speak to Uri"))

  if self.clue.hidey_hole ~= nil and not globetrotter_owned then
    self.actions.emote_return_hideyhole = state_panel:addAction(ClueStateAction.Text.new("Return hidey-hole"))
  end
end

---@param method Method.GenericPath?
function EmoteClueSolver:setMethod(method)
  self.method = method
  if method then
    self:setPath(stitch_path(method))
  else
    self:setPath(nil)
  end
  self:buildActions()
end

---@param path Path.Raw?
function EmoteClueSolver:setPath(path)
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

function EmoteClueSolver:dispose()
  self:setPath(nil)
  AbstractClueSolver.dispose(self)
end

return EmoteClueSolver
