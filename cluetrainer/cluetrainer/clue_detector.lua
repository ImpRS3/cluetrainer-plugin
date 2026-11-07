-- clue_detector.lua
local clues                 = require "cluetrainer/data/clues"
local zyklib                = require "zyklib"
local clue_items            = require "cluetrainer/data/clue_items"
local util                  = require "cluetrainer/util"

-- TODO: Implement detection of master clues via ObjVar once they are available

---@class cluetrainer.ClueDetector
---@field clue_detected_event zyklib.reactive.Event<Step, nil>
local clue_detector         = {}

-- The list of relevant master clues that need to be read from the TRAIL_CLUELONG interface
local relevant_master_clues = zyklib.array.filter(clues,
  function(clue) return clue.tier == "master" and clue.type ~= "compass" and clue.type ~= "scan" end)

---Reads the clue text from the TRAIL_CLUELONG interface
---@return string
local function readClueLongText()
  local text = ""

  for i = 1, 8 do
    local line = ui.Interfaces:GetComponent(id.Component["TRAIL_CLUELONG__TRAIL_CLUELONG_LINE" .. i]) --[[@as ui.Text]]
    if line ~= nil and line.content ~= "" then
      text = text .. " " .. line.content
    end
  end

  return text
end

-- How long the clue text is read again after the window opens, in client logic ticks (50 per second).
local READ_TIMEOUT_TICKS          = 100

---The master clue whose text matches, or nil.
---@param text string
---@return Step?
local function matchMasterClue(text)
  local scored = zyklib.array.map(relevant_master_clues, function(clue)
    return { clue = clue, score = util.stringSimilarity(text, clue.text[1]) }
  end)

  local best = zyklib.array.maxBy(scored, function(entry) return entry.score end)

  return best ~= nil and best.score > 0.97 and best.clue or nil
end

---@type zyklib.reactive.EventHandler?
local pending_read                = nil

local function stopReading()
  if pending_read then pending_read:cancel() end
  pending_read = nil
end

---Reads the clue text on every logic tick until it matches a master clue, the window closes or the timeout passes, so
---the clue is found however many ticks the game takes to replace its placeholder text. Only a changed text is scored.
local function readUntilMatched()
  stopReading()

  local deadline = nil
  local last_text = nil

  pending_read = zyklib.game_events.native.Logic:subscribe(function(payload)
    deadline = deadline or payload.logicTick + READ_TIMEOUT_TICKS

    local text = readClueLongText()
    if text ~= "" and text ~= last_text then
      last_text = text
      local clue = matchMasterClue(text)
      if clue ~= nil then
        stopReading()
        clue_detector.clue_detected_event:trigger(clue)
        return
      end
    end

    if payload.logicTick >= deadline then stopReading() end
  end)
end

local interface_handler           = zyklib.game_events.derived.component(id.Component
  ["TRAIL_CLUELONG__MAINMODAL_WINDOW"]):subscribeSuspended(function(event)
  if event ~= nil then
    readUntilMatched()
  else
    stopReading()
  end
end)

local mini_menu_handler           = zyklib.game_events.native.MiniMenuEntrySelected:subscribeSuspended(
  function(event)
    if not event.entry.componentData then return end
    if not event.entry.componentData.objConfig then return end

    if event.entry.verbText ~= "Read" and event.entry.verbText ~= "Start scanning" then return end

    -- Find corresponding clue id
    local clue_id = clue_items[event.entry.componentData.objConfig.configName]
    if (not clue_id) then return end

    local clue = zyklib.array.find(clues, function(clue) return clue.id == clue_id end)

    -- Report clue to orchestrator
    if (clue) then
      -- Delay emit by a single tick to emulate waiting for the interface to open.
      zyklib.game_events.native.ServerLogic:once(function()
        clue_detector.clue_detected_event:trigger(clue)
      end)
    end
  end)

clue_detector.clue_detected_event = zyklib.reactive.Event.new(function(hasActiveListeners)
  interface_handler:setActive(hasActiveListeners)
  mini_menu_handler:setActive(hasActiveListeners)
  if not hasActiveListeners then stopReading() end
end)

return clue_detector
