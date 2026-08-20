local clue_detector  = require("clue_detector")
local towers_solver  = require("puzzles/towers/TowerSolver")
local lockbox_solver = require("puzzles/lockbox/LockboxSolver")
local knot_solver    = require("puzzles/knots/KnotSolver")
local NpcHighlight   = require("zyklib/highlights/NpcHighlight")
local MutableMesh    = require("zyklib/MutableMesh")
local api_util       = require("zyklib/api_util")
local LocHighlight   = require("zyklib/highlights/LocHighlight")

clue_detector:init()
towers_solver:init()
lockbox_solver:init()
knot_solver:init()

local shape = MutableMesh.cube():shapeData()

-- NpcHighlight.new(function(npc)
--         return true
--     end,
--     function(npc)
--         return {
--             shapeData = shape,
--             translation = npc.aabb:GetCorner(BoxCornerType.LEFT_BOTTOM_NEAR),
--             scale = npc.aabb.dimensions,
--             colour = 0xFF00FF80
--         }
--     end):activate()

-- api_util.subscribe_managed(Event.LocAdded, function(event)
--     log(event.config.configName)
-- end)

-- LocHighlight.new({
--         name = "*ree*"
--     },
--     function(loc)
--         return {
--             shapeData = shape,
--             translation = loc.position,
--             scale = Vector3.new(512, 512, 512),
--             colour = 0xFF00FF80
--         }
--     end):activate()

log("clue trainer loaded")
