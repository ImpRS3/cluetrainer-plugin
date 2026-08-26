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
    -- Only react on relevant clicks on clues
    if not event.entry.componentData then return end
    if not event.entry.componentData.objConfig then return end

    log("Clicked " .. event.entry.componentData.objConfig.configName)

    for _, value in pairs(event.entry.componentData.objConfig.params) do
      log(value.configName)
      log(api_util.to_plain_table(event.entry.componentData.objConfig:GetParamValue(value)))
    end


    if event.entry.verbText ~= "Read" and event.entry.verbText ~= "Start scanning" then return end


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
