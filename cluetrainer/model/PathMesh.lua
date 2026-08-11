local MutableMesh         = require("model/MutableMesh")
local WorldDependentValue = require("util/WorldDependentValue")
local api_util            = require("util/api_util")

local PathMesh = {}

local ARROW_HEAD_LENGTH = 150
local FLOOR_OVERLAY_VERTICAL_OFFSET = 60
local TILE_MARKER_VERTICAL_OFFSET = 80
local TILE_MARKER_BORDER = 40

---@class AbilityColors
---@field [any] ColorRGBA
local ABILITY_COLORS = {
    surge = api_util.color_rgba(0, 0x91, 0xf2, 255),
    escape = api_util.color_rgba(0x56, 0xba, 0x0f, 255),
    barge = api_util.color_rgba(0xa9, 0x71, 0x04, 255),
    dive = api_util.color_rgba(0xe7, 0xd8, 0x2c, 255),
}

---@class COLORS
---@field [any] ColorRGBA
local COLORS = {
    run = api_util.color_rgba(180, 180, 180, 255),
    redclicked_run = api_util.color_rgba(255, 0, 0, 255),
    teleport = api_util.color_rgba(255, 0, 255, 255),
    transport = api_util.color_rgba(0, 255, 200, 255),
    powerburst = api_util.color_rgba(255, 215, 0, 255),
    redclick = api_util.color_rgba(255, 50, 50, 255),
    ability = api_util.color_rgba(255, 255, 255, 255),
    cheat = api_util.color_rgba(0, 255, 200, 255),
    cosmetic = api_util.color_rgba(0, 0, 0, 0),
    orientation = api_util.color_rgba(0, 0, 0, 0),
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
    local height, success = World.GetGroundHeight(coords.level, coords.x, coords.z, HeightOffsetType.GROUND_DECOR)

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

---Compute a convex upper hull of a set of given points across terrain.
---@param points Vector3[]
---@return table
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

        local v0 = builder:createVertex(resolve(vector_as_coord(base1, to_tile.level)) +
            Vector3.new(0, FLOOR_OVERLAY_VERTICAL_OFFSET, 0))
        local v1 = builder:createVertex(resolve(vector_as_coord(base2, to_tile.level)) +
            Vector3.new(0, FLOOR_OVERLAY_VERTICAL_OFFSET, 0))
        local v2 = builder:createVertex(resolve(vector_as_coord(tip, to_tile.level)) +
            Vector3.new(0, FLOOR_OVERLAY_VERTICAL_OFFSET, 0))

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

---@alias PathMesh.StepContext {i: integer, context_path: Path}

local StepContext = {}

---@param context PathMesh.StepContext
function StepContext.previous(context)
    if context.i > 1 then
        return context.context_path[context.i - 1]
    else
        return nil
    end
end

---
---@param step Path.Step
---@return TileCoordinates[]
local function marker_bounds(step)
    if step.type == "ability" then
        return { step.from, step.to }
    elseif step.type == "run" then
        return step.waypoints
    elseif step.type == "teleport" then
        return { step.spot }
    elseif step.type == "transport" then
        return { step.assumed_start }
    elseif step.type == "powerburst" then
        return { step.where }
    elseif step.type == "redclick" then
        return { step.where }
    elseif step.type == "orientation"
        or step.type == "cheat"
        or step.type == "cosmetic"
    then
        -- No geometry.
    end

    return {}
end

local function tilesToMapSquareRect(tiles)
    if (#tiles == 0) then
        return Rect.new(0, 0, 1, 1)
    end

    local minX = math.huge
    local minY = math.huge
    local maxX = -math.huge
    local maxY = -math.huge

    for _, tile in ipairs(tiles) do
        minX = math.min(minX, tile.x)
        minY = math.min(minY, tile.y)
        maxX = math.max(maxX, tile.x)
        maxY = math.max(maxY, tile.y)
    end

    minX = math.floor(minX / 64)
    minY = math.floor(minY / 64)
    maxX = math.floor(maxX / 64)
    maxY = math.floor(maxY / 64)

    return Rect.new(minX, minY, maxX - minX + 1, maxY - minY + 1)
end

---
---@param step Path.Step
---@param context PathMesh.StepContext
---@return WorldDependentValue<MutableMesh>
function PathMesh.buildStepMesh(step, context)
    return WorldDependentValue.new(
        tilesToMapSquareRect(marker_bounds(step)),
        function()
            local builder = MutableMesh.new()

            local LINE_THICKNESS = 30
            local MARKER_INSET = 20
            local MARKER_SIZE = 512 - 2 * MARKER_INSET
            local currentTileMarkerSize = 0

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
                    local previous = StepContext.previous(context)
                    local previousIsRedClick = previous ~= nil and previous.type == "redclick"
                    local previousTargetsNpc = previous ~= nil
                        and previous.type == "redclick"
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

            return builder
        end
    )
end

return PathMesh
