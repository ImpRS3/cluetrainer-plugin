local clue_map = require("clue_mapping")
local clues = require("data/clues")
local util = require("util")
local abstraction = require("abstraction")
local methods = require("data/hard_methods")
local PathMesh = require("model/PathMesh")
local clue_detector = require("clue_detector")

clue_detector:init()


--- @type Method?
local active_method = nil

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

        active_method = method
    end
end)

-- A basic tile shape
local tileShape = ShapeData.new()
tileShape.positions = { Vector3.new(-250, 0, -250), Vector3.new(250, 0, -250), Vector3.new(250, 0, 250), Vector3.new(
    -250, 0, 250) }
tileShape.rgba = { 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF }
tileShape.lines = { 0, 1, 1, 2, 2, 3, 3, 0 }

Event.EntityDraw.Subscribe("myEvent", function(entityEvent)
    if entityEvent.entityType == EntityType.NPC then
        -- log("Drawing entity: " .. entityEvent.npcEntity.displayName)

        if entityEvent.npcEntity.displayName == "" then
            return true
        end

        ShapeList.Draw({
            shapeData = tileShape,
            -- Draw at the entity feet position, with a small vertical offset to avoid clipping
            translation = entityEvent.npcEntity.position + Vector3.new(0, 30, 0),
            ignoreDepth = false,
            -- Draw thicker lines
            lineWidth = 2,
            -- Orange
            colour = 0xFF880080
        })
    end
    -- Remember to return true to make sure the entity keeps drawing
    return true
end)

---@type Shape?
local shape = nil

Event.Draw.Subscribe("draw_handler", function(event)
    if active_method then
        if active_method.type == "general_path" then
            local path = active_method.main_path

            if not shape then
                local builder = PathMesh.buildPathMesh(path)
                local a = builder:finalize()

                shape = a:shapeData()

                log(shape)
                log(#shape.positions)
                log(#shape.colors)
                log(#shape.triangleIndices)
                log(#shape.lineIndices)
            end

            if shape then
                ShapeList.Draw({
                    shapePositions = shape.positions,
                    shapeRGBA = shape.colors,
                    shapeTris = shape.triangleIndices,
                    shapeLines = shape.lineIndices,
                    lineWidth = 4,
                    ignoreDepth = false
                })
            end
        end
    end
end)

local keys_with_minus_one = {}
for key, value in pairs(clue_map) do
    if value == -1 then
        table.insert(keys_with_minus_one, key)
    end
end
table.sort(keys_with_minus_one)

local counter = 1

Event.MiniMenuEntrySelected.Subscribe("test", function(event)
    if event.entry.verbText == "Walk here" then
        -- Find 20 keys from clue_map whose value is 0
        if counter < #keys_with_minus_one then
            ExecuteConsoleCommand("!give " .. keys_with_minus_one[counter])
            counter = counter + 1
        end
    end
end)


log("clue trainer loaded")
