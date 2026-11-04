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

local interface_handler           = zyklib.game_events.derived.component(id.Component
  ["TRAIL_CLUELONG__MAINMODAL_WINDOW"]):subscribeSuspended(function(event)
  -- Handle the modal window being suspended if needed

  if event ~= nil then
    -- The actual clue text is not readable until the next client logic tick, so we wait for it.
    zyklib.game_events.native.Logic:once(function(payload)
      local text = readClueLongText()

      -- Score
      local scored = zyklib.array.map(relevant_master_clues, function(clue)
        return { clue = clue, score = util.stringSimilarity(text, clue.text[1]) }
      end)

      local best = zyklib.array.maxBy(scored, function(entry) return entry.score end)

      if best.score > 0.97 then
        clue_detector.clue_detected_event:trigger(best.clue)
      end
    end)
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
end)

return clue_detector
