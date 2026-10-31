-- clue_detector.lua
local clues                                        = require "cluetrainer/data/clues"
local zyklib                                       = require "zyklib"
local clue_items                                   = require "cluetrainer/data/clue_items"

-- TODO: Implement detection of master clues via ObjVar once they are available

---@class cluetrainer.ClueDetector
---@field clue_detected_event zyklib.reactive.Event<Step, nil>
local clue_detector                                = {}

clue_detector.clue_detected_event                  = zyklib.game_events.native.MiniMenuEntrySelected:derive(
--- @param emit fun(step: Step)
  function(event, emit)
    if not event.entry.componentData then return end
    if not event.entry.componentData.objConfig then return end

    if event.entry.verbText ~= "Read" and event.entry.verbText ~= "Start scanning" then return end

    -- Find corresponding clue id
    local clue_id = clue_items[event.entry.componentData.objConfig.configName]
    if (not clue_id) then return end

    local clue = zyklib.array.find(clues, function(clue) return clue.id == clue_id end)

    -- Report clue to orchestrator
    if (clue) then emit(clue) end
  end)

return clue_detector
