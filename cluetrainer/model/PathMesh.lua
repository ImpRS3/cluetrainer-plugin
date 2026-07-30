local MutableMesh = require("model/MutableMesh")
-- Dynamic mesh creation for paths


local PathMesh = {}

local ARROW_HEAD_LENGTH = 0.3
local FLOOR_OVERLAY_VERTICAL_OFFSET = 0.12
local TILE_MARKER_VERTICAL_OFFSET = 0.15
local TILE_MARKER_BORDER = 0.08

---@class AbilityColors
---@field [any] ColorRGBA
local ABILITY_COLORS = {
    surge = { r = 0, g = 100, b = 255, a = 255 },
    escape = { r = 33, g = 110, b = 4, a = 255 },
    dive = { r = 255, g = 220, b = 0, a = 255 },
    barge = { r = 150, g = 0, b = 255, a = 255 },
}

---@class COLORS
---@field [any] ColorRGBA
local COLORS = {
    run = { r=255, g=255, b=255, a=255 },
    redclicked_run = { r=255, g=0, b=0, a=255 },
    teleport = { r=255, g=0, b=255, a=255 },
    transport = { r=0, g=255, b=200, a=255 },
    powerburst = { r=255, g=215, b=0, a=255 },
    redclick = { r=255, g=50, b=50, a=255 },
    ability = { r=255, g=255, b=255, a=255 },
    cheat = { r=0, g=255, b=200, a=255 },
    cosmetic = { r=0, g=0, b=0, a=0 },
    orientation = { r=0, g=0, b=0, a=0 },
}

-- Replace this with the actual terrain lookup.
-- It receives world/tile coordinates and must return the base terrain height.
local function queryTerrainHeight(x, z, level)
    return 0
end

PathMesh.queryTerrainHeight = queryTerrainHeight

local function resolveTerrain(point, verticalOffset)
    return {
        x = point.x,
        y = queryTerrainHeight(point.x, point.y, point.level) + (verticalOffset or 0),
        z = point.y,
    }
end

local CORNER_OFFSETS = {
    sw = { x = 0, y = 0 },
    nw = { x = 0, y = 1 },
    ne = { x = 1, y = 1 },
    se = { x = 1, y = 0 },
}

local function resolveTileCorner(tile, corner, verticalOffset)
    local offset = assert(CORNER_OFFSETS[corner], "unknown tile corner: " .. tostring(corner))
    return resolveTerrain({
        x = tile.x + offset.x,
        y = tile.y + offset.y,
        level = tile.level,
    }, verticalOffset)
end

local function vector2Add(...)
    local result = { x = 0, y = 0 }
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        result.x = result.x + value.x
        result.y = result.y + value.y
    end
    return result
end

local function vector2Sub(a, b)
    return { x = a.x - b.x, y = a.y - b.y }
end

local function vector2Scale(scale, value)
    return { x = scale * value.x, y = scale * value.y }
end

local function vector2Length(value)
    return math.sqrt(value.x * value.x + value.y * value.y)
end

local function vector2Normalize(value)
    local length = vector2Length(value)
    if length == 0 then
        return { x = 0, y = 0 }
    end
    return { x = value.x / length, y = value.y / length }
end

local function vector3Add(a, b)
    return { x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }
end

local function vector3Scale(scale, value)
    return { x = scale * value.x, y = scale * value.y, z = scale * value.z }
end

local function lift(point, level)
    return { x = point.x, y = point.y, level = level }
end

function PathMesh.squareCrossSectionVector(dir)
    local magnitude = math.max(math.abs(dir.x), math.abs(dir.y))
    if magnitude == 0 then
        return { x = 0, y = 0 }
    end

    return {
        x = dir.x / magnitude,
        y = dir.y / magnitude,
    }
end

local function upperHull(points)
    if #points <= 2 then
        local copy = {}
        for i, point in ipairs(points) do
            copy[i] = point
        end
        return copy
    end

    local hull = {}

    local function slope(i, j)
        return (points[j].y - points[i].y) / (j - i)
    end

    for i = 1, #points do
        hull[#hull + 1] = i

        while #hull >= 3 do
            local n = #hull
            local a = hull[n - 2]
            local b = hull[n - 1]
            local c = hull[n]

            if slope(a, b) < slope(b, c) then
                table.remove(hull, n - 1)
            else
                break
            end
        end
    end

    local result = {}
    for _, index in ipairs(hull) do
        result[#result + 1] = points[index]
    end
    return result
end


function PathMesh.drawLine(from, to, thickness, showArrow, startTileSize, endTileSize, useUpperHull)
    local builder = MutableMesh.new()

    local direction = vector2Normalize(vector2Sub(to, from))
    local crossSection = PathMesh.squareCrossSectionVector(direction)

    local modifiedStart = vector2Add(
        from,
        vector2Scale(0.5 * startTileSize, crossSection)
    )

    local modifiedEnd = vector2Add(
        to,
        vector2Scale(-0.5 * endTileSize, crossSection),
        showArrow and vector2Scale(-ARROW_HEAD_LENGTH, direction) or { x = 0, y = 0 }
    )

    local length = vector2Length(vector2Sub(modifiedEnd, modifiedStart))
    if length < 0.001 then
        return builder
    end

    local perpendicular = {
        x = -direction.y,
        y = direction.x,
    }

    local segmentCount = math.max(1, math.ceil(4 * length))
    local controlPoints = {}

    for segment = 0, segmentCount do
        local t = segment / segmentCount
        local point = vector2Add(
            vector2Scale(1 - t, modifiedStart),
            vector2Scale(t, modifiedEnd)
        )

        controlPoints[#controlPoints + 1] = resolveTerrain(
            lift(point, from.level),
            FLOOR_OVERLAY_VERTICAL_OFFSET
        )
    end

    if useUpperHull then
        controlPoints = upperHull(controlPoints)
    end

    local vertexPairs = {}
    for _, point in ipairs(controlPoints) do
        local v1 = builder:createVertex(vector3Add(
            point,
            vector3Scale(thickness, {
                x = -perpendicular.x,
                y = 0,
                z = -perpendicular.y,
            })
        ))

        local v2 = builder:createVertex(vector3Add(
            point,
            vector3Scale(thickness, {
                x = perpendicular.x,
                y = 0,
                z = perpendicular.y,
            })
        ))

        vertexPairs[#vertexPairs + 1] = { v1, v2 }
    end

    for i = 2, #vertexPairs do
        local previous = vertexPairs[i - 1]
        local current = vertexPairs[i]
        builder:quad(previous[1], current[1], current[2], previous[2])
    end

    if showArrow then
        local arrowWidth = thickness * 3
        local base1 = vector2Add(modifiedEnd, vector2Scale(arrowWidth, perpendicular))
        local base2 = vector2Add(modifiedEnd, vector2Scale(-arrowWidth, perpendicular))
        local tip = vector2Add(modifiedEnd, vector2Scale(ARROW_HEAD_LENGTH, direction))

        local v0 = builder:createVertex(resolveTerrain(lift(base1, to.level), FLOOR_OVERLAY_VERTICAL_OFFSET))
        local v1 = builder:createVertex(resolveTerrain(lift(base2, to.level), FLOOR_OVERLAY_VERTICAL_OFFSET))
        local v2 = builder:createVertex(resolveTerrain(lift(tip, to.level), FLOOR_OVERLAY_VERTICAL_OFFSET))

        builder:triangle(v0, v1, v2)
    end

    return builder
end

local function drawTileMarker(tile, inset)
    inset = inset or 0
    local mesh = MutableMesh.new()

    local outer00 = mesh:createVertex(vector3Add(resolveTileCorner(tile, "sw", TILE_MARKER_VERTICAL_OFFSET), { x = inset, y = 0, z = inset }))
    local outer01 = mesh:createVertex(vector3Add(resolveTileCorner(tile, "nw", TILE_MARKER_VERTICAL_OFFSET), { x = inset, y = 0, z = -inset }))
    local outer11 = mesh:createVertex(vector3Add(resolveTileCorner(tile, "ne", TILE_MARKER_VERTICAL_OFFSET), { x = -inset, y = 0, z = -inset }))
    local outer10 = mesh:createVertex(vector3Add(resolveTileCorner(tile, "se", TILE_MARKER_VERTICAL_OFFSET), { x = -inset, y = 0, z = inset }))

    local inner00 = mesh:createVertex(vector3Add(outer00.vertex.pos, { x = TILE_MARKER_BORDER, y = 0, z = TILE_MARKER_BORDER }))
    local inner01 = mesh:createVertex(vector3Add(outer01.vertex.pos, { x = TILE_MARKER_BORDER, y = 0, z = -TILE_MARKER_BORDER }))
    local inner11 = mesh:createVertex(vector3Add(outer11.vertex.pos, { x = -TILE_MARKER_BORDER, y = 0, z = -TILE_MARKER_BORDER }))
    local inner10 = mesh:createVertex(vector3Add(outer10.vertex.pos, { x = -TILE_MARKER_BORDER, y = 0, z = TILE_MARKER_BORDER }))

    mesh:quad(outer00, outer01, inner01, inner00)
    mesh:quad(outer01, outer11, inner11, inner01)
    mesh:quad(outer11, outer10, inner10, inner11)
    mesh:quad(outer10, outer00, inner00, inner10)

    return mesh
end

local function drawRedClickMarker(builder, tile, color, markerHeightOffset)
    markerHeightOffset = markerHeightOffset or 5

    local cx = tile.x + 0.5
    local cz = tile.y + 0.5

    local shaftRadius = 0.12
    local headRadius = 0.30
    local totalHeight = 0.9
    local headHeight = 0.35

    local baseOffsetY = TILE_MARKER_VERTICAL_OFFSET + markerHeightOffset
    local tipY = baseOffsetY
    local junctionY = baseOffsetY + headHeight
    local topY = baseOffsetY + totalHeight

    local cBright = { 255, 0, 0, 255 }
    local cMid = { 140, 0, 0, 255 }
    local cDark = { 60, 0, 0, 255 }
    local cDeep = { 20, 0, 0, 255 }

    local cos8 = { 1.0, 0.7071, 0.0, -0.7071, -1.0, -0.7071, 0.0, 0.7071 }
    local sin8 = { 0.0, 0.7071, 1.0, 0.7071, 0.0, -0.7071, -1.0, -0.7071 }
    local sideColors = { cMid, cBright, cBright, cMid, cMid, cDark, cDark, cDeep }

    local tip = builder:createVertex(resolveTerrain({ x = cx, y = cz, level = tile.level }, tipY), cBright)

    local headBaseVertices = {}
    local shaftBottomVertices = {}
    local shaftTopVertices = {}

    for i = 1, 8 do
        local cosine = cos8[i]
        local sine = sin8[i]
        local sideColor = sideColors[i]

        headBaseVertices[i] = builder:createVertex(resolveTerrain({
            x = cx + headRadius * cosine,
            y = cz + headRadius * sine,
            level = tile.level,
        }, junctionY), sideColor)

        shaftBottomVertices[i] = builder:createVertex(resolveTerrain({
            x = cx + shaftRadius * cosine,
            y = cz + shaftRadius * sine,
            level = tile.level,
        }, junctionY), cDeep)

        shaftTopVertices[i] = builder:createVertex(resolveTerrain({
            x = cx + shaftRadius * cosine,
            y = cz + shaftRadius * sine,
            level = tile.level,
        }, topY), sideColor)
    end

    for i = 1, 8 do
        local nextIndex = (i % 8) + 1

        builder:triangle(tip, headBaseVertices[nextIndex], headBaseVertices[i])
        builder:triangle(headBaseVertices[i], shaftBottomVertices[i], headBaseVertices[nextIndex])
        builder:triangle(shaftBottomVertices[i], shaftBottomVertices[nextIndex], headBaseVertices[nextIndex])
        builder:triangle(shaftBottomVertices[i], shaftTopVertices[i], shaftTopVertices[nextIndex])
        builder:triangle(shaftBottomVertices[i], shaftTopVertices[nextIndex], shaftBottomVertices[nextIndex])
    end

    for i = 2, 7 do
        builder:triangle(shaftTopVertices[1], shaftTopVertices[i], shaftTopVertices[i + 1])
    end
end

function PathMesh.drawTileArea(area)
    local builder = MutableMesh.new()
    local polygons = TileArea.activate(area):asMultipolygon()

    for _, polygon in ipairs(polygons) do
        local line = polygon.outer
        for i = 2, #line do
            builder:add(PathMesh.drawLine(
                lift(line[i - 1], area.origin.level),
                lift(line[i], area.origin.level),
                0.02,
                false,
                -0.01,
                -0.01,
                false
            ))
        end
    end

    return builder
end


---Build the mesh for a given path
---@param path Path
---@return MutableMesh
function PathMesh.buildPathMesh(path)
    local builder = MutableMesh.new()

    local MARKER_INSET = 0.1
    local MARKER_SIZE = 1 - 2 * MARKER_INSET
    local currentTileMarkerSize = 0

    for i, step in ipairs(path) do
        if step.type == "ability" then
            local color = ABILITY_COLORS[step.ability]
            local drawTargetTile = step.ability == "dive" and not step.is_far_dive

            builder:add(PathMesh.drawLine(
                step.from,
                step.to,
                0.05,
                true,
                currentTileMarkerSize,
                drawTargetTile and MARKER_SIZE or 0,
                true
            ):recolor(color))

            if drawTargetTile then
                builder:add(drawTileMarker(step.to, MARKER_INSET):recolor(color))
            end

            currentTileMarkerSize = drawTargetTile and MARKER_SIZE or 0

        elseif step.type == "run" then
            -- if #step.waypoints >= 2 then
            --     local previous = path[i - 1]
            --     local previousIsRedClick = previous ~= nil and previous.type == "redclick"
            --     local previousTargetsNpc = previousIsRedClick
            --         and previous.target ~= nil
            --         and previous.target.kind == "npc"

            --     local lineColor = previousTargetsNpc and COLORS.redclicked_run or COLORS.run
            --     local tileColor = previousIsRedClick and COLORS.redclicked_run or COLORS.run

            --     for j = 1, #step.waypoints - 1 do
            --         local isLast = j == #step.waypoints - 1
            --         builder:add(drawLine(
            --             step.waypoints[j],
            --             step.waypoints[j + 1],
            --             0.04,
            --             isLast,
            --             j == 1 and currentTileMarkerSize or 0,
            --             isLast and MARKER_SIZE or 0,
            --             false
            --         ):recolor(lineColor))
            --     end

            --     builder:add(drawTileMarker(step.waypoints[#step.waypoints], MARKER_INSET):recolor(tileColor))
            --     currentTileMarkerSize = MARKER_SIZE
            -- end

        elseif step.type == "teleport" then
            currentTileMarkerSize = 0
        elseif step.type == "transport" then
        elseif step.type == "powerburst" then
        elseif step.type == "redclick" then
        elseif step.type == "orientation"
            or step.type == "cheat"
            or step.type == "cosmetic"
        then
            -- No geometry.
        end
    end

    return builder
end

function PathMesh.buildPathsMesh(paths)
    local builder = MutableMesh.new()

    for _, path in ipairs(paths) do
        builder:add(PathMesh.buildPathMesh(path))
    end

    return builder
end

return PathMesh
