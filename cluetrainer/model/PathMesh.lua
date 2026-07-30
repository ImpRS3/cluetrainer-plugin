local MutableMesh = require("model/MutableMesh")
-- Dynamic mesh creation for paths


local PathMesh = {}

local ARROW_HEAD_LENGTH = 150
local FLOOR_OVERLAY_VERTICAL_OFFSET = 60
local TILE_MARKER_VERTICAL_OFFSET = 80
local TILE_MARKER_BORDER = 40

---@class AbilityColors
---@field [any] ColorRGBA
local ABILITY_COLORS = {
    surge = { r = 0, g = 0x91, b = 0xf2, a = 255 },
    escape = { r = 0x56, g = 0xba, b = 0x0f, a = 255 },
    barge = { r = 0xa9, g = 0x71, b = 0x04, a = 255 },
    dive = { r = 0xe7, g = 0xd8, b = 0x2c, a = 255 },
}

---@class COLORS
---@field [any] ColorRGBA
local COLORS = {
    run = { r = 0xb4, g = 0xb4, b = 0xb4, a = 255 },
    redclicked_run = { r = 255, g = 0, b = 0, a = 255 },
    teleport = { r = 255, g = 0, b = 255, a = 255 },
    transport = { r = 0, g = 255, b = 200, a = 255 },
    powerburst = { r = 255, g = 215, b = 0, a = 255 },
    redclick = { r = 255, g = 50, b = 50, a = 255 },
    ability = { r = 255, g = 255, b = 255, a = 255 },
    cheat = { r = 0, g = 255, b = 200, a = 255 },
    cosmetic = { r = 0, g = 0, b = 0, a = 0 },
    orientation = { r = 0, g = 0, b = 0, a = 0 },
}


---
---@param tile_coordinates TileCoordinates#
---@param sample ("sw"|"nw"|"ne"|"se"|"center")?
---@return CoordFine
local function convert(tile_coordinates, sample, inset)
    sample = sample or "center"
    inset = inset or 0

    local FINE_CORNER_OFFSETS = {
        sw = { x = 1 + inset, z = 1 + inset },
        nw = { x = 1 + inset, z = 510 - inset },
        ne = { x = 510 - inset, z = 510 - inset },
        se = { x = 510 - inset, z = 1 + inset },
        center = { x = 255, z = 255 },
    }

    local offset = FINE_CORNER_OFFSETS[sample]

    return CoordFine.new(
        tile_coordinates.level,
        tile_coordinates.x * 512 + offset.x,
        tile_coordinates.y * 512 + offset.z
    )
end


---Resolves the terrain height for a given CoordFine
---@param coords CoordFine
---@return Vector3
local function resolve(coords)
    local height, success = World.GetGroundHeight(coords.level, coords.x, coords.z)

    if not success then
        return Vector3.new(coords.x, coords.y, coords.z)
    end

    return Vector3.new(coords.x, height, coords.z)
end

local function lift(point, level)
    return { x = point.x, y = point.y, level = level }
end

---
---@param dir Vector2
---@return Vector2
function PathMesh.squareCrossSectionVector(dir)
    local magnitude = math.max(math.abs(dir.x), math.abs(dir.y))
    if magnitude == 0 then
        return { x = 0, y = 0 }
    end

    return Vector2.new(
        dir.x / magnitude,
        dir.y / magnitude
    )
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

---@param factor number
---@param v Vector3
---@return Vector3
local function scale3(factor, v)
    return Vector3.new(v.x * factor, v.y * factor, v.z * factor)
end

---@param factor number
---@param v Vector2
---@return Vector2
local function scale2(factor, v)
    return Vector2.new(v.x * factor, v.y * factor)
end

---@param coords CoordFine
---@return Vector2
local function coords_as_vector(coords)
    return Vector2.new(coords.x, coords.z)
end

---@param vector Vector2
---@param level 0|1|2|3
---@return CoordFine
local function vector_as_coord(vector, level)
    return CoordFine.new(level, vector.x, vector.y)
end

---comment
---@param from_tile TileCoordinates
---@param to_tile TileCoordinates
---@param thickness integer
---@param showArrow boolean
---@param startTileSize integer
---@param endTileSize integer
---@param useUpperHull boolean
---@return MutableMesh
local function drawLine(from_tile, to_tile, thickness, showArrow, startTileSize, endTileSize, useUpperHull)
    local builder = MutableMesh.new()

    local a = coords_as_vector(convert(from_tile))
    local b = coords_as_vector(convert(to_tile))

    local direction = (b - a)

    direction = scale2(1 / direction.length, direction)

    local crossSection = PathMesh.squareCrossSectionVector(direction)

    local modifiedStart = a + scale2(0.5 * startTileSize, crossSection)
    local modifiedEnd = b - scale2(0.5 * endTileSize, crossSection) +
    (showArrow and scale2(-ARROW_HEAD_LENGTH, direction) or Vector2.new(0, 0))

    local length = (modifiedEnd - modifiedStart).length

    if length < 0.001 then
        return builder
    end

    local perpendicular = Vector2.new(-direction.y, direction.x)

    local segmentCount = math.max(1, math.ceil(length / 128))
    local controlPoints = {}

    for segment = 0, segmentCount do
        local t = segment / segmentCount
        local point = (scale2(1 - t, modifiedStart) + scale2(t, modifiedEnd)):Floor()

        controlPoints[#controlPoints + 1] = resolve(vector_as_coord(point, from_tile.level)) +
            Vector3.new(0, FLOOR_OVERLAY_VERTICAL_OFFSET, 0)
    end

    if useUpperHull then
        controlPoints = upperHull(controlPoints)
    end

    local vertexPairs = {}
    for _, point in ipairs(controlPoints) do
        local v1 = builder:createVertex(point + scale3(thickness, Vector3.new(-perpendicular.x, 0, -perpendicular.y)))

        local v2 = builder:createVertex(point + scale3(thickness, Vector3.new(perpendicular.x, 0, perpendicular.y)))

        vertexPairs[#vertexPairs + 1] = { v1, v2 }
    end

    for i = 2, #vertexPairs do
        local previous = vertexPairs[i - 1]
        local current = vertexPairs[i]
        builder:quad(previous[1], current[1], current[2], previous[2])
    end

    if showArrow then
        local arrowWidth = thickness * 3
        local base1 = modifiedEnd + scale2(arrowWidth, perpendicular)
        local base2 = modifiedEnd + scale2(-arrowWidth, perpendicular)
        local tip = modifiedEnd + scale2(ARROW_HEAD_LENGTH, direction)

        local v0 = builder:createVertex(resolve(vector_as_coord(base1, to_tile.level)) + Vector3.new(0, FLOOR_OVERLAY_VERTICAL_OFFSET, 0))
        local v1 = builder:createVertex(resolve(vector_as_coord(base2, to_tile.level)) + Vector3.new(0, FLOOR_OVERLAY_VERTICAL_OFFSET, 0))
        local v2 = builder:createVertex(resolve(vector_as_coord(tip, to_tile.level)) + Vector3.new(0, FLOOR_OVERLAY_VERTICAL_OFFSET, 0))

        builder:triangle(v0, v1, v2)
    end

    return builder
end

---Draw a tile marker at the given tile
---@param tile TileCoordinates The tile to draw on
---@param inset number Distance of the tile marker from the tile edge in fine coordinates (0-250). Default is 0.
---@return MutableMesh
local function drawTileMarker(tile, inset)
    inset = inset or 0
    local mesh = MutableMesh.new()

    local vertical_offset = Vector3.new(0, TILE_MARKER_VERTICAL_OFFSET, 0)

    local outer00 = mesh:createVertex(resolve(convert(tile, "sw", inset)) + vertical_offset)
    local outer01 = mesh:createVertex(resolve(convert(tile, "nw", inset)) + vertical_offset)
    local outer11 = mesh:createVertex(resolve(convert(tile, "ne", inset)) + vertical_offset)
    local outer10 = mesh:createVertex(resolve(convert(tile, "se", inset)) + vertical_offset)

    local inner00 = mesh:createVertex(resolve(convert(tile, "sw", inset + TILE_MARKER_BORDER)) + vertical_offset)
    local inner01 = mesh:createVertex(resolve(convert(tile, "nw", inset + TILE_MARKER_BORDER)) + vertical_offset)
    local inner11 = mesh:createVertex(resolve(convert(tile, "ne", inset + TILE_MARKER_BORDER)) + vertical_offset)
    local inner10 = mesh:createVertex(resolve(convert(tile, "se", inset + TILE_MARKER_BORDER)) + vertical_offset)

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
            builder:add(drawLine(
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

    local LINE_THICKNESS = 30
    local MARKER_INSET = 20
    local MARKER_SIZE = 512 - 2 * MARKER_INSET
    local currentTileMarkerSize = 0

    for i, step in ipairs(path) do
        if step.type == "ability" then
            local color = ABILITY_COLORS[step.ability]
            local drawTargetTile = step.ability == "dive" and not step.is_far_dive

            builder:add(drawLine(
                step.from,
                step.to,
                LINE_THICKNESS,
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
            if #step.waypoints >= 2 then
                local previous = path[i - 1]
                local previousIsRedClick = previous ~= nil and previous.type == "redclick"
                local previousTargetsNpc = previousIsRedClick
                    and previous.target ~= nil
                    and previous.target.kind == "npc"

                local lineColor = previousTargetsNpc and COLORS.redclicked_run or COLORS.run
                local tileColor = previousIsRedClick and COLORS.redclicked_run or COLORS.run

                for j = 1, #step.waypoints - 1 do
                    local isLast = j == #step.waypoints - 1
                    builder:add(drawLine(
                        step.waypoints[j],
                        step.waypoints[j + 1],
                        LINE_THICKNESS,
                        isLast,
                        j == 1 and currentTileMarkerSize or 0,
                        isLast and MARKER_SIZE or 0,
                        false
                    ):recolor(lineColor))
                end

                builder:add(drawTileMarker(step.waypoints[#step.waypoints], MARKER_INSET):recolor(tileColor))
                currentTileMarkerSize = MARKER_SIZE
            end
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
