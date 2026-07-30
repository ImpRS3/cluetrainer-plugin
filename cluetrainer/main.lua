local clue_map = require("clue_mapping")
local clues = require("data/clues")
local util = require("util")
local abstraction = require("abstraction")
local methods = require("data/hard_methods")
local PathMesh = require("model/PathMesh")

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

function OnEntityDraw(entityEvent)
    if entityEvent.entityType == EntityType.NPC then
        -- log("Drawing entity: " .. entityEvent.npcEntity.displayName)

        ShapeList.Draw({
            shapeData = tileShape,
            -- Draw at the entity feet position, with a small vertical offset to avoid clipping
            translation = entityEvent.npcEntity.position + Vector3.new(0, 30, 0),
            ignoreDepth = false,
            -- Draw thicker lines
            lineWidth = 4,
            -- Orange
            colour = 0xFF8800FF
        })
    end
    -- Remember to return true to make sure the entity keeps drawing
    return true
end

Event.EntityDraw.Subscribe("myEvent", OnEntityDraw)

---@type Shape?
local shape = nil

Event.Draw.Subscribe("draw_handler", function(event)
    if active_method then
        if active_method.type == "general_path" then
            local path = active_method.main_path

            if not shape then
                local builder = PathMesh.buildPathMesh(path)
                local a = builder:finalize()
                log(a)
                shape = a:shapeData()
            end

            log(shape)
            if shape then
                ShapeList.Draw({
                    shapeData = shape,
                    lineWidth = 4,
                    ignoreDepth = false
                })
            end
        end
    end
end)


log("clue trainer loaded")
