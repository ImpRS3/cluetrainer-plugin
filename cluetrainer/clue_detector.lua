-- Copyright (c) 2024 ClueTrainer Contributors
-- See LICENSE file in the project root for full license information.

local abstraction   = require "abstraction"
local clue_map      = require "clue_mapping"
local clues         = require "data/clues"
local util          = require "util"
local orchestrator  = require "orchestrator"

---@class ClueDetector
---@field initialized boolean
---@field mini_menu_handler Handler
local clue_detector = {
  initialized = false,
}

function clue_detector:init()
  self.mini_menu_handler = abstraction.subscribe(Event.MiniMenuEntrySelected, function(event)
    -- TODO: Check if a clue was opened, select method and render

    -- Only react on relevant clicks on clues
    if not event.entry.componentData then return end
    if not event.entry.componentData.objConfig then return end
    if event.entry.verbText ~= "Read" and event.entry.verbText ~= "Start scanning" then return end

    log(event.entry.componentData.objConfig.configName)

    -- Find corresponding clue id
    local clue_id = clue_map[event.entry.componentData.objConfig.configName]
    if (not clue_id) then return end

    local clue = util.find(clues, function(clue) return clue.id == clue_id end)

    -- Report clue to orchestrator
    if (clue) then orchestrator:setStep(clue) end
  end)

  self.initialized = true
end

return clue_detector
