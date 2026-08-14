local clue_detector  = require("clue_detector")
local towers_solver  = require("puzzles/towers/TowerSolver")
local lockbox_solver = require("puzzles/lockbox/LockboxSolver")
local knot_solver    = require("puzzles/knots/KnotSolver")
local NpcHighlight   = require("zyklib/highlights/NpcHighlight")
local MutableMesh    = require("zyklib/MutableMesh")


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
            colour = 0xFF00FF80
        }
    end):activate()

log("clue trainer loaded")
