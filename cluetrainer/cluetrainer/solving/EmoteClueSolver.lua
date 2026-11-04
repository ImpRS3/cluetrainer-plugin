local PathMesh              = require "cluetrainer/model/PathMesh"
local map                   = require "cluetrainer/interfaces/map/map"
local EmoteAreaEntity       = require "cluetrainer/interfaces/map/elements/EmoteAreaEntity"
local HideyHoleEntity       = require "cluetrainer/interfaces/map/elements/HideyHoleEntity"
local Bounds                = require "cluetrainer/util/Bounds"
local methods               = require "cluetrainer/methods/method_management"
local Path                  = require "cluetrainer/model/shared/path"
local ActiveClueSolver      = require "cluetrainer/solving/common/ActiveClueSolver"
local Navigator             = require "cluetrainer/solving/common/navigator"
local MapSectionControl     = require "cluetrainer/solving/map_navigator/MapSectionControl"
local luaflet               = require "prettymap/luaflet"
local PathStepEntity        = require "cluetrainer/solving/map_navigator/PathStepEntity"
local RichText              = require "cluetrainer/util/RichText"
local ClueStateAction       = require("cluetrainer/interfaces/cluestate/ClueStateAction")
local MethodAction          = require "cluetrainer/solving/common/MethodAction"
local zyklib                = require "zyklib"

---@param step Emote
local function create_step_highlights(step)
  return zyklib.highlights.HighlightGroup.new({
    PathMesh.areaHighlight(step.area, 0x914183FF, 0x91418380)
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
---@field method? ct.solving.MethodAction
---@field emote_get_hideyhole? ct.interfaces.cluestate.ClueStateAction
---@field equip_items? ct.interfaces.cluestate.ClueStateAction
---@field emote_summon? ct.interfaces.cluestate.ClueStateAction
---@field emote_double_agent? ct.interfaces.cluestate.ClueStateAction
---@field emote_uri? ct.interfaces.cluestate.ClueStateAction
---@field emote_return_hideyhole? ct.interfaces.cluestate.ClueStateAction

--- An ActiveEmoteClue manages a single emote clue currently in progress.
---@class ct.ActiveEmoteClue : ct.ActiveClueSolver
---@field private navigator Navigator?
---@field private map_navigator ct.MapSectionControl?
---@field private path_twig prettymap.luaflet.Twig?
---@field actions ct.EmoteClueActions
local EmoteClueSolver = setmetatable({}, { __index = ActiveClueSolver })
EmoteClueSolver.__index = EmoteClueSolver

---@param clue Emote
---@param clue_state ct.ClueStateInterface
---@return ct.ActiveEmoteClue
function EmoteClueSolver.new(clue, clue_state)
  ---@type ct.ActiveEmoteClue
  local self = setmetatable(ActiveClueSolver.new(clue), EmoteClueSolver)

  self.disposable_group:add(create_step_highlights(clue):activate())
  self.disposable_group:add(create_step_map_layer(clue):AddTo(map.ensure_open().map.twigs))

  local preferred = methods.getPreferred({ clue = clue.id })
  local method = preferred and preferred.method --[[@as Method.GenericPath?]]

  self:setMethod(method)

  if not method then
    local bounds = Bounds.new()
    bounds:addArea(clue.area)
    map.ensure_open():fitBounds(bounds)
  end

  ---@type ct.EmoteClueActions
  self.actions = {}

  local state_panel = clue_state

  state_panel:clearActions()

  self.actions.method = state_panel:addAction(MethodAction.new({ clue = clue.id }, {
    onMethodSelected = function(selected)
      self:setMethod(selected and selected.method --[[@as Method.GenericPath?]])
    end,
  }))

  self.actions.emote_get_hideyhole = state_panel:addAction(ClueStateAction.Text.new("Get hidey-hole"))
  self.actions.equip_items = state_panel:addAction(ClueStateAction.Text.new("Equip items"))

  if clue.double_agent then
    self.actions.emote_summon = state_panel:addAction(ClueStateAction.Text.new("Summon " .. RichText.npc("Double Agent")))
    self.actions.emote_double_agent = state_panel:addAction(ClueStateAction.Text.new("Kill " .. RichText.npc("Double Agent")))
  else
    self.actions.emote_summon = state_panel:addAction(ClueStateAction.Text.new("Summon " .. RichText.npc("Uri")))
  end

  self.actions.emote_uri = state_panel:addAction(ClueStateAction.Text.new("Speak to Uri"))
  self.actions.emote_return_hideyhole = state_panel:addAction(ClueStateAction.Text.new("Return hidey-hole"))

  return self
end

---@param method Method.GenericPath?
function EmoteClueSolver:setMethod(method)
  if method then
    self:setPath(stitch_path(method))
  else
    self:setPath(nil)
  end
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
    self.navigator = Navigator.new()
    self.navigator:set(path)

    local sectioned_path = Path.split_into_sections(path)
    local steps = zyklib.array.flatMap(sectioned_path, function(section) return section.steps end)
    self.path_twig = PathStepEntity.route(steps):AddTo(map.ensure_open().map.twigs)

    self.map_navigator = MapSectionControl.new(map.ensure_open(),
      zyklib.array.map(sectioned_path, function(sec) return { name = sec.name, bounds = Path.bounds(sec.steps) } end))
  end
end

function EmoteClueSolver:dispose()
  self:setPath(nil)
  ActiveClueSolver.dispose(self)
end

return EmoteClueSolver
