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

-- The game puts this line above every master skilling clue; the clue data holds only the text below it. Skilling
-- clues exist only in the master tier.
local MASTER_SKILLING_PREFIX      = "Complete the action to solve the clue:"

---The clue text as the data holds it: without the skilling prefix, without leading or trailing spaces, and with
---single spaces only, so the window's line layout does not lower the score.
---@param text string
---@return string
local function normaliseMasterClueText(text)
  text = text:gsub("%s+", " "):match("^ ?(.-) ?$")
  if text:sub(1, #MASTER_SKILLING_PREFIX) == MASTER_SKILLING_PREFIX then
    text = text:sub(#MASTER_SKILLING_PREFIX + 1):match("^ ?(.*)$")
  end
  return text
end

---The best matching master clue and its score, also when the score is too low to count as a match.
---@param text string Already passed through `normaliseMasterClueText`
---@return Step?, number
local function bestMasterClue(text)
  local scored = zyklib.array.map(relevant_master_clues, function(clue)
    return { clue = clue, score = util.stringSimilarity(text, clue.text[1]) }
  end)

  local best = zyklib.array.maxBy(scored, function(entry) return entry.score end)
  if best == nil then return nil, 0 end
  return best.clue, best.score
end

---@type zyklib.reactive.EventHandler?
local pending_read                = nil

---The last text read in the pending read and how close it came, for the log when nothing matched.
---@type { text: string, clue: Step?, score: number }?
local last_attempt                = nil

---@param report_miss boolean? Whether to log the last text read when no clue matched, so a miss shows in the console
local function stopReading(report_miss)
  if pending_read then
    pending_read:cancel()
    if report_miss and last_attempt ~= nil then
      log(string.format("No master clue matched (best %.2f, clue %s): %s", last_attempt.score,
        last_attempt.clue and tostring(last_attempt.clue.id) or "-", last_attempt.text))
    end
  end
  pending_read = nil
  last_attempt = nil
end

---Reads the clue text on every logic tick until it matches a master clue, the window closes or the timeout passes, so
---the clue is found however many ticks the game takes to replace its placeholder text. Only a changed text is scored.
local function readUntilMatched()
  stopReading()

  local deadline = nil
  local last_text = nil

  pending_read = zyklib.game_events.native.Logic:subscribe(function(payload)
    deadline = deadline or payload.logicTick + READ_TIMEOUT_TICKS

    local text = normaliseMasterClueText(readClueLongText())
    if text ~= "" and text ~= last_text then
      last_text = text
      local clue, score = bestMasterClue(text)
      if clue ~= nil and score > 0.97 then
        stopReading()
        clue_detector.clue_detected_event:trigger(clue)
        return
      end
      last_attempt = { text = text, clue = clue, score = score }
    end

    if payload.logicTick >= deadline then stopReading(true) end
  end)
end

local interface_handler           = zyklib.game_events.derived.component(id.Component
  ["TRAIL_CLUELONG__MAINMODAL_WINDOW"]):subscribeSuspended(function(event)
  if event ~= nil then
    readUntilMatched()
  else
    stopReading(true)
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

-- The compass item and its arrow panel per compass clue, so a compass also starts when its panel opens without the
-- "Read" option: by a keybind, or after the scroll box while the panel stays open.
local COMPASS_PANELS              = zyklib.array.map({
  { item = "TRAIL_CLUE_ELITE_COMPASS", component = "TRAIL_COMPASSCLUE_SIDE__TRAIL_LINE" },
  { item = "TRAIL_CLUE_MASTER_COMPASS_EASTERNLANDS", component = "TRAIL_COMPASSCLUE_EASTERNLANDS_SIDE__TRAIL_LINE" },
}, function(panel)
  panel.clue = zyklib.array.find(clues, function(clue) return clue.id == clue_items[panel.item] end)
  panel.shown = false
  return panel
end)

---Whether the compass's arrow panel is visible while the compass is in the backpack. The backpack check keeps a dug
---compass, whose panel can stay open, from starting again.
local function compassShown(panel)
  local component = ui.Interfaces:GetComponent(id.Component[panel.component])
  if component == nil or not component.visibleGlobal or component.parent == nil then return false end

  -- The proxy has no `valid` field, so only nil means the backpack is unavailable.
  local backpack = Inventory.Find(config.Inv.INV) --[[@as Inv?]]
  local obj = id.Obj[panel.item]
  return backpack ~= nil and obj ~= nil and backpack:GetTotal(obj) > 0
end

-- Reports the compass only when it becomes shown, not on every tick, so reading another clue while the panel stays
-- open is not switched back to the compass.
local compass_panel_handler       = zyklib.game_events.native.ServerLogic:subscribeSuspended(function()
  for _, panel in ipairs(COMPASS_PANELS) do
    local shown = compassShown(panel)
    if shown and not panel.shown and panel.clue ~= nil then clue_detector.clue_detected_event:trigger(panel.clue) end
    panel.shown = shown
  end
end)

clue_detector.clue_detected_event = zyklib.reactive.Event.new(function(hasActiveListeners)
  interface_handler:setActive(hasActiveListeners)
  mini_menu_handler:setActive(hasActiveListeners)
  compass_panel_handler:setActive(hasActiveListeners)
  -- Forgotten while inactive, so a compass that is open when solving is switched on starts right away.
  for _, panel in ipairs(COMPASS_PANELS) do panel.shown = false end
  if not hasActiveListeners then stopReading() end
end)

return clue_detector
