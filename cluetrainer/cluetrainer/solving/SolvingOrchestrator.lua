local clue_detector          = require "cluetrainer/clue_detector"
local CompassSolver          = require "cluetrainer/solving/CompassSolver"
local EmoteClueSolver        = require "cluetrainer/solving/EmoteClueSolver"
local SimpleClueSolver       = require "cluetrainer/solving/SimpleClueSolver"
local ScanTreeSolver         = require "cluetrainer/solving/ScanClueSolver"
local ClueStateInterface     = require "cluetrainer/interfaces/cluestate/cluestate"
local ClueStateAction        = require "cluetrainer/interfaces/cluestate/ClueStateAction"
local map                    = require "cluetrainer/interfaces/map/map"
local schema                 = require "cluetrainer/util/schema"
local storage                = require "cluetrainer/util/storage"
local clue_items             = require "cluetrainer/data/clue_items"

-- The items of the master clues that are recognised by their text, which `clue_items` has no entry for. All clues of
-- one type share the item.
local MASTER_TYPE_ITEMS      = {
  anagram = "TRAIL_CLUE_MASTER_ANAGRAM",
  emote = "TRAIL_CLUE_MASTER_EMOTE",
  skilling = "TRAIL_CLUE_MASTER_SKILL_RIDDLE",
}

---@class ct.solving.SolvingOrchestrator : zyklib.disposable.IDisposable
---@field private clue_state ct.ClueStateInterface
---@field private active_solver ct.ActiveClueSolver?
---@field private clue_detection_handler zyklib.reactive.EventHandler
---@field private inventory_handler zyklib.reactive.EventHandler
---@field private active_items string[] The items that hold the active clue
---@field private active_item_seen boolean Whether an item of the active clue was in the backpack since it became active
---@field private map_hidden boolean? Whether the cross hid the map, which the next clue shows again
local SolvingOrchestrator    = {}
SolvingOrchestrator.__index  = SolvingOrchestrator

---The items that hold a clue, such as `TRAIL_CLUE_ELITE_COMPASS` for every elite compass.
---@param clue Step
---@return string[]
local function itemsOf(clue)
  local names = {}
  for name, clue_id in pairs(clue_items) do
    if clue_id == clue.id then table.insert(names, name) end
  end
  if #names == 0 and clue.tier == "master" and MASTER_TYPE_ITEMS[clue.type] then
    table.insert(names, MASTER_TYPE_ITEMS[clue.type])
  end
  return names
end

SolvingOrchestrator.settings = {
  enabled = ctGlobal.persistence:profileVariable("solving/enabled", schema.bool({ default = true })),
}

---@type ct.solving.SolvingOrchestrator?
local instance               = nil

---@private
---@return ct.solving.SolvingOrchestrator
function SolvingOrchestrator.new()
  local self = setmetatable({}, SolvingOrchestrator)

  self.clue_state = ClueStateInterface.new()

  self.clue_state.reset_event:subscribe(function()
    self:reset()
  end)

  self.active_solver = nil
  self.active_items = {}
  self.active_item_seen = false

  self:showIntroduction()

  self.clue_detection_handler = clue_detector.clue_detected_event:subscribe(function(clue)
    self:setClue(clue)
  end)

  self.inventory_handler = zyklib.game_events.native.InventoryUpdated:subscribe(function(payload)
    if payload.inv.id == config.Inv.INV.id then self:endIfClueItemGone() end
  end)

  return self
end

---Ends the active solver once its clue item has left the backpack: destroyed, dropped, banked, or done and turned
---into the next clue, a scroll box or a casket. That way the next clue starts clean, also one that shares the item,
---such as the next elite compass. Only after the item was seen, to keep the solver while the backpack is not loaded.
function SolvingOrchestrator:endIfClueItemGone()
  local active = self.active_solver
  if active == nil or active.ended or #self.active_items == 0 then return end

  -- The proxy has no `valid` field, so only nil means the backpack is unavailable.
  local backpack = Inventory.Find(config.Inv.INV) --[[@as Inv?]]
  if backpack == nil then return end

  local count = 0
  for _, name in ipairs(self.active_items) do
    local obj = id.Obj[name]
    if obj ~= nil then count = count + backpack:GetTotal(obj) end
  end

  if count > 0 then
    self.active_item_seen = true
  elseif self.active_item_seen then
    active:finish(self.clue_state)
  end
end

---Fills the empty clue state panel with introductory text, until the first clue replaces it.
---@private
function SolvingOrchestrator:showIntroduction()
  self.clue_state:addAction(ClueStateAction.Text.new("Clue Trainer ready!"))
  self.clue_state:addAction(ClueStateAction.Text.new("Click any active Clue scroll or<br>tetracompass to start solving."))
  self.clue_state:addAction(ClueStateAction.Text.new(
    "To move this panel or the map,<br>unlock your interface, hold the<br>Alt key, and drag them around"))
end

function SolvingOrchestrator:reset()
  if self.active_solver ~= nil then
    self.active_solver:dispose()
    self.active_solver = nil
  end

  self.clue_state:setClue(nil)
  self.clue_state:clearActions()

  -- Hidden until the next clue, so the cross closes both windows. The main panel's toggles stay as they are.
  self.clue_state:setVisible(false)
  local game_map = map.current()
  if game_map ~= nil and game_map:isVisible() then
    game_map:setVisible(false)
    self.map_hidden = true
  end
end

---@param clue Step?
function SolvingOrchestrator:setClue(clue)
  -- Keep the running solver when the same clue is read again (a scan clue is read on every "Start scanning"), so its
  -- progress stays. Rebuild it once it ended, or once the map with its elements is gone.
  local active = self.active_solver
  if clue ~= nil and active ~= nil and active.clue == clue and not active.ended then return end

  self.clue_state:clearActions()

  if active ~= nil then
    active:dispose()
    self.active_solver = nil
  end

  if clue ~= nil then
    self.clue_state:setClue(clue)
    -- Shown again after the cross hid them.
    self.clue_state:setVisible(true)
    if self.map_hidden then
      self.map_hidden = false
      map.get():setVisible(true)
    end
  end

  self.active_solver = (function()
    if clue == nil then
      return nil
    elseif clue.type == "compass" then
      return CompassSolver.new(clue, self.clue_state)
    elseif clue.type == "emote" then
      return EmoteClueSolver.new(clue, self.clue_state)
    elseif clue.type == "scan" then
      return ScanTreeSolver.new(clue, self.clue_state)
    else
      return SimpleClueSolver.new(clue, self.clue_state)
    end
  end)()

  self.active_items = clue and itemsOf(clue) or {}
  self.active_item_seen = false
  self:endIfClueItemGone()
end

function SolvingOrchestrator:dispose()
  self.clue_detection_handler:dispose()
  self.inventory_handler:dispose()

  if self.active_solver ~= nil then
    self.active_solver:dispose()
    self.active_solver = nil
  end

  self.clue_state:dispose()
end

---Constructs the singleton instance if active, or disposes it otherwise.
---@param active boolean
function SolvingOrchestrator.setActive(active)
  if active then
    if instance == nil then instance = SolvingOrchestrator.new() end
  elseif instance ~= nil then
    instance:dispose()
    instance = nil
  end
end

-- Dispose the clue state window and the highlights on shutdown, so a plugin restart starts without leftovers.
zyklib.lifecycle.shutdown_event:subscribe(function() SolvingOrchestrator.setActive(false) end)

return SolvingOrchestrator
