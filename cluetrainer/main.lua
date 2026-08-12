local clue_detector  = require("clue_detector")
local towers_solver  = require("puzzles/towers/TowerSolver")
local lockbox_solver = require("puzzles/lockbox/LockboxSolver")
local knot_solver    = require("puzzles/knots/KnotSolver")
local api_util       = require("util/api_util")
local lua_util       = require("util/lua_util")
local NpcHighlight   = require("util/NpcHighlight")
local MutableMesh    = require("util/MutableMesh")


clue_detector:init()
towers_solver:init()
lockbox_solver:init()
knot_solver:init()
local shape = MutableMesh.cube():shapeData()

NpcHighlight.new(function(npc)
        return true
    end,
    function(npc)
        return {
            shapeData = shape,
            translation = npc.aabb:GetCorner(BoxCornerType.LEFT_BOTTOM_NEAR),
            scale = npc.aabb.dimensions,
            colour = 0xFFFF0080
        }
    end)

log("clue trainer loaded")
