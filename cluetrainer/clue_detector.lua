-- Copyright (c) 2024 ClueTrainer Contributors
-- See LICENSE file in the project root for full license information.

local clue_map      = require "clue_mapping"
local clues         = require "data/clues"
local orchestrator  = require "solving/orchestrator"
local api_util      = require "zyklib/api_util"
local lua_util      = require "zyklib/lua_util"

---@class ClueDetector
---@field initialized boolean
---@field mini_menu_handler zyklib.ApiEventHandler
local clue_detector = {
  initialized = false,
}

function clue_detector:init()
  self.mini_menu_handler = api_util.subscribe_managed(Event.MiniMenuEntrySelected, function(event)
    -- TODO: Check if a clue was opened, select method and render

    -- Only react on relevant clicks on clues
    if not event.entry.componentData then return end
    if not event.entry.componentData.objConfig then return end
    if event.entry.verbText ~= "Read" and event.entry.verbText ~= "Start scanning" then return end

    log("Clicked "..event.entry.componentData.objConfig.configName)

    -- Find corresponding clue id
    local clue_id = clue_map[event.entry.componentData.objConfig.configName]
    if (not clue_id) then return end

    local clue = lua_util.find(clues, function(clue) return clue.id == clue_id end)

    -- Report clue to orchestrator
    if (clue) then orchestrator:setStep(clue) end
  end)

  self.initialized = true
end

return clue_detector
