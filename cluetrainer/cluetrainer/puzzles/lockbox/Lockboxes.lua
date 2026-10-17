-- Lockboxes.lua
--- Copyright (c) 2026, Lukas Gail
--- All rights reserved.

---@class Lockboxes
local Lockboxes = {}

---@alias Tile 0|1|2
---@alias TileRow {[1]: Tile, [2]: Tile, [3]: Tile, [4]: Tile, [5]: Tile}
---@alias MoveMap {[1]: TileRow, [2]: TileRow, [3]: TileRow, [4]: TileRow, [5]: TileRow}
---@alias MoveMapScorer fun(map: MoveMap): number

---@class LockboxState
---@field tile_rows {[1]: TileRow, [2]: TileRow, [3]: TileRow, [4]: TileRow, [5]: TileRow}

---@class LockboxSolution
---@field moves MoveMap
---@field target LockboxState

---@class LockboxSolveOptions
---@field target_override? LockboxState
---@field modulo_targets_allowed? boolean
---@field minimize? boolean
---@field minimize_by? MoveMapScorer

Lockboxes.SIZE = 5

Lockboxes.Tile = {}

---@param tile Tile
---@return Tile
function Lockboxes.Tile.advance(tile)
    return (tile + 1) % 3
end

Lockboxes.MoveMap = {}

---@return MoveMap
local function empty_move_map()
    return {
        { 0, 0, 0, 0, 0 },
        { 0, 0, 0, 0, 0 },
        { 0, 0, 0, 0, 0 },
        { 0, 0, 0, 0, 0 },
        { 0, 0, 0, 0, 0 },
    }
end

---@type MoveMap
Lockboxes.MoveMap.None = empty_move_map()

---@type MoveMap[]
Lockboxes.MoveMap.BASIC_QUIET_PATTERNS = {
    {
        { 1, 0, 0, 0, 2 },
        { 2, 2, 0, 1, 1 },
        { 1, 2, 0, 1, 2 },
        { 1, 1, 0, 2, 2 },
        { 0, 2, 0, 1, 0 },
    },
    {
        { 0, 1, 0, 2, 0 },
        { 2, 2, 0, 1, 1 },
        { 2, 1, 0, 2, 1 },
        { 1, 1, 0, 2, 2 },
        { 2, 0, 0, 0, 1 },
    },
    {
        { 0, 0, 1, 0, 1 },
        { 0, 2, 2, 1, 2 },
        { 1, 2, 0, 1, 2 },
        { 0, 1, 1, 2, 1 },
        { 1, 2, 2, 1, 1 },
    },
}

---@param moves MoveMap
---@param repetition integer
---@return MoveMap
function Lockboxes.MoveMap.repeatMoves(moves, repetition)
    ---@type MoveMap
    local result = empty_move_map()

    for row = 1, Lockboxes.SIZE do
        for col = 1, Lockboxes.SIZE do
            result[row][col] = (moves[row][col] * repetition) % 3
        end
    end

    return result
end

---@param moves MoveMap
---@param row integer Zero-based row index
---@param col integer Zero-based column index
---@return Tile
function Lockboxes.MoveMap.get(moves, row, col)
    if row < 0
        or row >= Lockboxes.SIZE
        or col < 0
        or col >= Lockboxes.SIZE
    then
        return 0
    end

    return moves[row + 1][col + 1]
end

---@param ... MoveMap
---@return MoveMap
function Lockboxes.MoveMap.chain(...)
    local maps = { ... }

    ---@type MoveMap
    local result = empty_move_map()

    for row = 1, Lockboxes.SIZE do
        for col = 1, Lockboxes.SIZE do
            local sum = 0

            for _, map in ipairs(maps) do
                sum = sum + map[row][col]
            end

            result[row][col] = sum % 3
        end
    end

    return result
end

---@param profile {[1]: number, [2]: number, [3]: number}
---@return MoveMapScorer
function Lockboxes.MoveMap.scoring(profile)
    return function(map)
        local score = 0

        for row = 1, Lockboxes.SIZE do
            for col = 1, Lockboxes.SIZE do
                score = score + profile[map[row][col] + 1]
            end
        end

        return score
    end
end

---@type MoveMapScorer
Lockboxes.MoveMap.clickScore =
    Lockboxes.MoveMap.scoring({ 0, 1, 2 })

---@type MoveMapScorer
Lockboxes.MoveMap.tileScore =
    Lockboxes.MoveMap.scoring({ 0, 1, 1 })

---@type MoveMapScorer
Lockboxes.MoveMap.hybridScore =
    Lockboxes.MoveMap.scoring({ 0, 1, 1.3 })

Lockboxes.State = {}

---@type LockboxState
Lockboxes.State.SOLVED = {
    tile_rows = {
        { 0, 0, 0, 0, 0 },
        { 0, 0, 0, 0, 0 },
        { 0, 0, 0, 0, 0 },
        { 0, 0, 0, 0, 0 },
        { 0, 0, 0, 0, 0 },
    },
}

---@type LockboxState
Lockboxes.State.SOLVED_1 = {
    tile_rows = {
        { 1, 1, 1, 1, 1 },
        { 1, 1, 1, 1, 1 },
        { 1, 1, 1, 1, 1 },
        { 1, 1, 1, 1, 1 },
        { 1, 1, 1, 1, 1 },
    },
}

---@type LockboxState
Lockboxes.State.SOLVED_2 = {
    tile_rows = {
        { 2, 2, 2, 2, 2 },
        { 2, 2, 2, 2, 2 },
        { 2, 2, 2, 2, 2 },
        { 2, 2, 2, 2, 2 },
        { 2, 2, 2, 2, 2 },
    },
}

---A lockbox is solved when all tiles have the same value.
---@param state LockboxState
---@return boolean
function Lockboxes.State.isSolved(state)
    local reference = state.tile_rows[1][1]

    for row = 1, Lockboxes.SIZE do
        for col = 1, Lockboxes.SIZE do
            if state.tile_rows[row][col] ~= reference then
                return false
            end
        end
    end

    return true
end

---@param a LockboxState
---@param b LockboxState
---@return boolean
function Lockboxes.State.equals(a, b)
    for row = 1, Lockboxes.SIZE do
        for col = 1, Lockboxes.SIZE do
            if a.tile_rows[row][col] ~= b.tile_rows[row][col] then
                return false
            end
        end
    end

    return true
end

---@param state LockboxState
---@param move MoveMap
---@return LockboxState
function Lockboxes.State.applyMoves(state, move)
    ---@type LockboxState
    local result = {
        tile_rows = empty_move_map(),
    }

    for row = 0, Lockboxes.SIZE - 1 do
        for col = 0, Lockboxes.SIZE - 1 do
            local tile = state.tile_rows[row + 1][col + 1]

            result.tile_rows[row + 1][col + 1] = (
                tile
                + Lockboxes.MoveMap.get(move, row, col)
                + Lockboxes.MoveMap.get(move, row + 1, col)
                + Lockboxes.MoveMap.get(move, row - 1, col)
                + Lockboxes.MoveMap.get(move, row, col + 1)
                + Lockboxes.MoveMap.get(move, row, col - 1)
            ) % 3
        end
    end

    return result
end

---@param state LockboxState
---@return string
function Lockboxes.State.toString(state)
    local rows = {}

    for row = 1, Lockboxes.SIZE do
        local values = {}

        for col = 1, Lockboxes.SIZE do
            values[col] = tostring(state.tile_rows[row][col])
        end

        rows[row] = table.concat(values, "  ")
    end

    return table.concat(rows, "\n")
end

---@return LockboxState
function Lockboxes.State.generate()
    ---@type LockboxState
    local result = {
        tile_rows = empty_move_map(),
    }

    for row = 1, Lockboxes.SIZE do
        for col = 1, Lockboxes.SIZE do
            result.tile_rows[row][col] = math.random(0, 2)
        end
    end

    return result
end

---@param a LockboxState
---@param b LockboxState
---@return LockboxState
function Lockboxes.State.add(a, b)
    ---@type LockboxState
    local result = {
        tile_rows = empty_move_map(),
    }

    for row = 1, Lockboxes.SIZE do
        for col = 1, Lockboxes.SIZE do
            result.tile_rows[row][col] = (
                a.tile_rows[row][col]
                + b.tile_rows[row][col]
            ) % 3
        end
    end

    return result
end

---@param a LockboxState
---@param b LockboxState
---@return LockboxState
function Lockboxes.State.sub(a, b)
    ---@type LockboxState
    local result = {
        tile_rows = empty_move_map(),
    }

    for row = 1, Lockboxes.SIZE do
        for col = 1, Lockboxes.SIZE do
            result.tile_rows[row][col] = (
                a.tile_rows[row][col]
                - b.tile_rows[row][col]
                + 3
            ) % 3
        end
    end

    return result
end

---@param map MoveMap
---@return boolean
function Lockboxes.MoveMap.isQuiet(map)
    return Lockboxes.State.equals(
        Lockboxes.State.applyMoves(Lockboxes.State.SOLVED, map),
        Lockboxes.State.SOLVED
    )
end

---@type MoveMap[]?
local all_quiet_patterns = nil

---@return MoveMap[]
function Lockboxes.MoveMap.allQuietPatterns()
    if not all_quiet_patterns then
        -- Based on the JavaScript implementation described at:
        -- https://www.jaapsch.net/puzzles/lights.htm#java2000

        ---@type MoveMap[]
        local patterns = {}

        for a = 0, 2 do
            for b = 0, 2 do
                for c = 0, 2 do
                    patterns[#patterns + 1] =
                        Lockboxes.MoveMap.chain(
                            Lockboxes.MoveMap.repeatMoves(
                                Lockboxes.MoveMap.BASIC_QUIET_PATTERNS[1],
                                a
                            ),
                            Lockboxes.MoveMap.repeatMoves(
                                Lockboxes.MoveMap.BASIC_QUIET_PATTERNS[2],
                                b
                            ),
                            Lockboxes.MoveMap.repeatMoves(
                                Lockboxes.MoveMap.BASIC_QUIET_PATTERNS[3],
                                c
                            )
                        )
                end
            end
        end

        all_quiet_patterns = patterns
    end

    return all_quiet_patterns
end

---@param map MoveMap
---@return MoveMap[]
function Lockboxes.MoveMap.getEquivalents(map)
    ---@type MoveMap[]
    local result = {}

    for _, quiet in ipairs(Lockboxes.MoveMap.allQuietPatterns()) do
        result[#result + 1] =
            Lockboxes.MoveMap.chain(map, quiet)
    end

    return result
end

---@generic T
---@param values T[]
---@param scorer fun(value: T): number
---@return T
local function min_by(values, scorer)
    assert(#values > 0, "min_by requires at least one value")

    local best = values[1]
    local best_score = scorer(best)

    for i = 2, #values do
        local score = scorer(values[i])

        if score < best_score then
            best = values[i]
            best_score = score
        end
    end

    return best
end

---@param map MoveMap
---@param by? MoveMapScorer
---@return MoveMap
function Lockboxes.MoveMap.minimize(map, by)
    by = by or Lockboxes.MoveMap.clickScore

    return min_by(
        Lockboxes.MoveMap.getEquivalents(map),
        by
    )
end

---@param row integer Zero-based row index
---@param column integer Zero-based column index
---@return MoveMap
function Lockboxes.MoveMap.fromClick(row, column)
    ---@type MoveMap
    local result = empty_move_map()

    if row >= 0
        and row < Lockboxes.SIZE
        and column >= 0
        and column < Lockboxes.SIZE
    then
        result[row + 1][column + 1] = 1
    end

    return result
end

---@param a MoveMap
---@param b MoveMap
---@return integer
function Lockboxes.MoveMap.difference(a, b)
    local difference = 0

    for row = 1, Lockboxes.SIZE do
        for col = 1, Lockboxes.SIZE do
            if a[row][col] ~= b[row][col] then
                difference = difference + 1
            end
        end
    end

    return difference
end

---@param state LockboxState
---@return MoveMap
local function basic_solve(state)
    ---@param initial_state LockboxState
    ---@return MoveMap moves
    ---@return LockboxState final_state
    local function chasing(initial_state)
        local current_state = initial_state
        local moves = empty_move_map()

        for chased_row = 0, 3 do
            local partial = empty_move_map()

            for col = 1, Lockboxes.SIZE do
                local tile =
                    current_state.tile_rows[chased_row + 1][col]

                partial[chased_row + 2][col] = (3 - tile) % 3
            end

            current_state =
                Lockboxes.State.applyMoves(current_state, partial)

            moves = Lockboxes.MoveMap.chain(moves, partial)
        end

        return moves, current_state
    end

    local first_chasing_moves, state_after_first_chasing =
        chasing(state)

    ---If A5 is 1, press B1 twice; if A5 is 2, press B1 once.
    ---@type Tile
    local B1 = ({
        [0] = 0,
        [1] = 2,
        [2] = 1,
    })[state_after_first_chasing.tile_rows[5][1]]

    ---If B5 is 1, press A1 and B1 twice; if B5 is 2, press once.
    ---@type Tile
    local A1B1 = ({
        [0] = 0,
        [1] = 2,
        [2] = 1,
    })[state_after_first_chasing.tile_rows[5][2]]

    ---@type MoveMap
    local magic_solve = {
        { A1B1, (A1B1 + B1) % 3, 0, 0, 0 },
        { 0,    0,               0, 0, 0 },
        { 0,    0,               0, 0, 0 },
        { 0,    0,               0, 0, 0 },
        { 0,    0,               0, 0, 0 },
    }

    local state_after_magic_solve =
        Lockboxes.State.applyMoves(
            state_after_first_chasing,
            magic_solve
        )

    local second_chasing_moves =
        chasing(state_after_magic_solve)

    return Lockboxes.MoveMap.chain(
        first_chasing_moves,
        magic_solve,
        second_chasing_moves
    )
end

---@param state LockboxState
---@param options? LockboxSolveOptions
---@return LockboxSolution
function Lockboxes.solve(state, options)
    options = options or {}

    ---@type LockboxState[]
    local targets

    if options.modulo_targets_allowed then
        targets = {
            Lockboxes.State.SOLVED,
            Lockboxes.State.SOLVED_1,
            Lockboxes.State.SOLVED_2,
        }
    else
        targets = {
            Lockboxes.State.SOLVED,
        }
    end

    if options.target_override then
        for i, target in ipairs(targets) do
            targets[i] =
                Lockboxes.State.add(
                    target,
                    options.target_override
                )
        end
    end

    ---@type LockboxSolution[]
    local candidates = {}

    for _, target in ipairs(targets) do
        candidates[#candidates + 1] = {
            target = target,
            moves = basic_solve(
                Lockboxes.State.sub(state, target)
            ),
        }
    end

    if options.minimize then
        ---@type LockboxSolution[]
        local equivalents = {}

        for _, solution in ipairs(candidates) do
            for _, moves in ipairs(
                Lockboxes.MoveMap.getEquivalents(solution.moves)
            ) do
                equivalents[#equivalents + 1] = {
                    target = solution.target,
                    moves = moves,
                }
            end
        end

        candidates = equivalents
    end

    ---@type fun(solution: LockboxSolution): number
    local cost

    if options.minimize then
        local scorer =
            options.minimize_by
            or Lockboxes.MoveMap.clickScore

        cost = function(solution)
            return scorer(solution.moves)
        end
    else
        cost = function()
            return 0
        end
    end

    return min_by(candidates, cost)
end

return Lockboxes
