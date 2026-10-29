local clue_detector         = require "cluetrainer/clue_detector"
local coordinate_adaptor    = require "cluetrainer/model/shared/coordinate_adaptor"
local PathMesh              = require "cluetrainer/model/PathMesh"
local OverlayConstants      = require "cluetrainer/model/OverlayConstants"
local map                   = require "cluetrainer/interfaces/map/map"
local EmoteAreaEntity       = require "cluetrainer/interfaces/map/elements/EmoteAreaEntity"
local HideyHoleEntity       = require "cluetrainer/interfaces/map/elements/HideyHoleEntity"
local Bounds                = require "cluetrainer/util/Bounds"
local methods               = require "cluetrainer/solving/methods"
local Navigator             = require "cluetrainer/solving/common/navigator"
local Path                  = require "cluetrainer/model/shared/path"
local MapSectionControl     = require "cluetrainer/solving/map_navigator/MapSectionControl"
local PathStepEntity        = require "cluetrainer/solving/map_navigator/PathStepEntity"
local luaflet               = require "prettymap/luaflet"
local cluestate             = require "cluetrainer/interfaces/cluestate/cluestate"
local RichText              = require "cluetrainer/util/RichText"
local zyklib                = require "zyklib"

local EmoteClueSolver       = {}

EmoteClueSolver.initialized = false

---@param step Emote
local function create_step_highlights(step)
  return zyklib.highlights.HighlightGroup.new({
    zyklib.highlights.TerrainHighlight.new(
      zyklib.api_util.map_square_rect_from_tiles({ coordinate_adaptor.tile_coordinates_to_coord_grid(step.area.origin) }),
      function()
        return PathMesh.drawTileArea(step.area, 0x914183FF, 0x91418380)
            :translate(Vector3.new(0, OverlayConstants.AREA_OVERLAY_HEIGHT, 0))
            :shapeData()
      end
    )
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
---@field emote_get_hideyhole? ct.interfaces.cluestate.ClueStateAction
---@field equip_items? ct.interfaces.cluestate.ClueStateAction
---@field emote_summon? ct.interfaces.cluestate.ClueStateAction
---@field emote_double_agent? ct.interfaces.cluestate.ClueStateAction
---@field emote_uri? ct.interfaces.cluestate.ClueStateAction
---@field emote_return_hideyhole? ct.interfaces.cluestate.ClueStateAction

--- An ActiveEmoteClue is the instance that manages everything about a single emote clue currently in progress.
---@class ActiveEmoteClue : zyklib.disposable.IDisposable
---@field private navigator Navigator?
---@field private map_navigator ct.MapSectionControl?
---@field private path_twig prettymap.luaflet.Twig?
local ActiveEmoteClue = {}

---@param clue Emote
---@return ActiveEmoteClue
function ActiveEmoteClue.new(clue)
  ---@class ActiveEmoteClue
  local self = setmetatable({
    clue = clue,
    disposable_group = zyklib.disposable.DisposableGroup.new()
  }, { __index = ActiveEmoteClue })

  self.disposable_group:add(create_step_highlights(clue):activate())
  self.disposable_group:add(create_step_map_layer(clue):AddTo(map.ensure_open().map.twigs))

  ---@type Method.GenericPath?
  local method = methods.resolve({ clue = clue.id })

  self:setMethod(method)

  if not method then
    local bounds = Bounds.new()
    bounds:addArea(clue.area)
    map.ensure_open():fitBounds(bounds)
  end

  ---@type ct.EmoteClueActions
  self.actions = {}

  local state_panel = cluestate.get()

  state_panel:clearActions()
  state_panel:setVisible(true)

  self.actions.emote_get_hideyhole = state_panel:addAction("Get hidey-hole")
  self.actions.equip_items = state_panel:addAction("Equip items")

  if clue.double_agent then
    self.actions.emote_summon = state_panel:addAction("Summon " .. RichText.npc("Double Agent"))
    self.actions.emote_double_agent = state_panel:addAction("Kill " .. RichText.npc("Double Agent"))
  else
    self.actions.emote_summon = state_panel:addAction("Summon " .. RichText.npc("Uri"))
  end

  self.actions.emote_uri = state_panel:addAction("Speak to Uri")
  self.actions.emote_return_hideyhole = state_panel:addAction("Return hidey-hole")

  return self
end

---@param method Method.GenericPath?
function ActiveEmoteClue:setMethod(method)
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

function ActiveEmoteClue.dispose(self)
  self:setMethod(nil)
  self.disposable_group:dispose()
end

function EmoteClueSolver.init()
  if EmoteClueSolver.initialized then return end
  EmoteClueSolver.initialized = true

  ---@type ActiveEmoteClue?
  local active_clue = nil

  clue_detector.clue_detected_event:subscribe(function(clue)
    if active_clue ~= nil and (clue == nil or active_clue.clue ~= clue) then
      active_clue:dispose()
      active_clue = nil
    end

    if clue ~= nil and active_clue == nil and clue.type == "emote" then
      active_clue = ActiveEmoteClue.new(clue)
    end
  end)
end

return EmoteClueSolver