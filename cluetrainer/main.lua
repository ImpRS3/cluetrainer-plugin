local clue_map = require("clue_mapping")
local clues = require("data/clues")
local util = require("util")
local abstraction = require("abstraction")
local methods = require("data/hard_methods")

Event.MiniMenuEntrySelected.Subscribe("hook", function(event)
    -- TODO: Check if a clue was opened, select method and render

    if not event.entry.componentData then return end
    if not event.entry.componentData.objConfig then return end

    log(event.entry.componentData.objConfig.configName)

    local clue_id = clue_map[event.entry.componentData.objConfig.configName]

    if (not clue_id) then return end

    local clue = util.find(clues, function(clue) return clue.id == clue_id end)

    if (clue) then
        log(clue.text[1])

        local method = util.find(methods.methods, function(method) return method["for"].clue == clue_id end)

        log(method)
    end
end)

local a = Vector3.new(-200, 100, -200)
local b = Vector3.new(200, 100, -200)
local c = Vector3.new(200, 100, 200)
local d = Vector3.new(-200, 100, 200)

local mesh = ShapeData.new()
mesh.positions = { a, b, c, d }
mesh.rgba = { 0xFF0000FF, 0xFF0000FF, 0xFF0000FF, 0xFF0000FF }
mesh.tris = {0, 1, 2, 0, 2, 3}
mesh.lines = {0, 1, 1, 2, 2, 3, 3, 0}

local handler = abstraction.subscribe(Event.Draw, function(
--- @param event DrawEvent
    event)

    log(ShapeList.Draw{
        shapeData = mesh,
        translation = Player.GetEntity().position,
        ignoreDepth = true,
        lineWidth = 10
    })
end)

log("clue trainer loaded")
