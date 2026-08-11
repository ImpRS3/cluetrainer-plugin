local clue_detector = require("clue_detector")
local towers_solver = require("puzzles/towers/TowerSolver")
local lockbox_solver = require("puzzles/lockbox/LockboxSolver")
local knot_solver = require("puzzles/knots/KnotSolver")
local api_util = require("util/api_util")
local lua_util = require("util/lua_util")


clue_detector:init()
towers_solver:init()
lockbox_solver:init()
knot_solver:init()

-- A basic tile shape
local tileShape = ShapeData.new()
tileShape.positions = { Vector3.new(-250, 0, -250), Vector3.new(250, 0, -250), Vector3.new(250, 0, 250), Vector3.new(
    -250, 0, 250) }
tileShape.rgba = { 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF }
tileShape.lines = { 0, 1, 1, 2, 2, 3, 3, 0 }

--- The following is just a carnary overlay so I can easily see if the mod is loaded and running. It draws a tile on top of every NPC in the world.
api_util.subscribe_managed(Event.EntityDraw, function(entityEvent)
    if entityEvent.entityType == EntityType.NPC then
        ShapeList.Draw({
            shapeData = tileShape,
            -- Draw at the entity feet position, with a small vertical offset to avoid clipping
            translation = entityEvent.npcEntity.position + Vector3.new(0, 30, 0),
            ignoreDepth = false,
            lineWidth = 2,
            colour = 0xFF8800FF
        })
    end
    -- Remember to return true to make sure the entity keeps drawing
    return true
end)


log("clue trainer loaded")
