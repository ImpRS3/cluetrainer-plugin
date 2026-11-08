-- Towers.lua
---@class ct.towers.Towers
local Towers = {}

local zyklib = require("zyklib")

---@alias ct.towers.Tower 1|2|3|4|5
---@alias ct.towers.Street [ct.towers.Tower?, ct.towers.Tower?, ct.towers.Tower?, ct.towers.Tower?, ct.towers.Tower?]
---@alias ct.towers.StreetLabel ct.towers.Tower
---@alias ct.towers.LabelPair [ct.towers.StreetLabel, ct.towers.StreetLabel]

---@class ct.towers.LabelledStreet
---@field street ct.towers.Street
---@field label ct.towers.LabelPair

---@class ct.towers.Hints
---@field top [ct.towers.StreetLabel, ct.towers.StreetLabel, ct.towers.StreetLabel, ct.towers.StreetLabel, ct.towers.StreetLabel]
---@field bottom [ct.towers.StreetLabel, ct.towers.StreetLabel, ct.towers.StreetLabel, ct.towers.StreetLabel, ct.towers.StreetLabel]
---@field left [ct.towers.StreetLabel, ct.towers.StreetLabel, ct.towers.StreetLabel, ct.towers.StreetLabel, ct.towers.StreetLabel]
---@field right [ct.towers.StreetLabel, ct.towers.StreetLabel, ct.towers.StreetLabel, ct.towers.StreetLabel, ct.towers.StreetLabel]

---@class ct.towers.HintPairs
---@field rows [ct.towers.LabelPair, ct.towers.LabelPair, ct.towers.LabelPair, ct.towers.LabelPair, ct.towers.LabelPair]
---@field columns [ct.towers.LabelPair, ct.towers.LabelPair, ct.towers.LabelPair, ct.towers.LabelPair, ct.towers.LabelPair]

---@class ct.towers.Blocks
---@field rows [ct.towers.Street, ct.towers.Street, ct.towers.Street, ct.towers.Street, ct.towers.Street]

---@class ct.towers.PuzzleState
---@field hints ct.towers.Hints
---@field blocks ct.towers.Blocks

---@type ct.towers.Tower[]
Towers.all_towers = { 1, 2, 3, 4, 5 }

Towers.Street = {}

---@type ct.towers.Street[]?
local all_streets = nil

---@return ct.towers.Street
function Towers.Street.empty()
    return { 0, 0, 0, 0, 0 }
end

---@param elements integer[]
---@return integer[][]
local function all_permutations(elements)
    if #elements == 0 then
        return { {} }
    end

    ---@type integer[][]
    local result = {}

    for i, next_value in ipairs(elements) do
        ---@type integer[]
        local remaining = {}

        for index, value in ipairs(elements) do
            if index ~= i then
                remaining[#remaining + 1] = value
            end
        end

        for _, permutation in ipairs(all_permutations(remaining)) do
            ---@type integer[]
            local combined = { next_value }

            for _, value in ipairs(permutation) do
                combined[#combined + 1] = value
            end

            result[#result + 1] = combined
        end
    end

    return result
end

---@return ct.towers.Street[]
function Towers.Street.all()
    if not all_streets then
        all_streets = all_permutations({ 1, 2, 3, 4, 5 })
    end

    return all_streets
end

---@param street ct.towers.Street
---@return integer
local function line_of_sight(street)
    local count = 0
    local highest = 0

    for i = 1, 5 do
        local height = street[i]

        if height and height > highest then
            count = count + 1
            highest = height
        end
    end

    return count
end

---@param street ct.towers.Street
---@return ct.towers.Street
function Towers.Street.reverse(street)
    ---@type ct.towers.Street
    local result = {}

    for i = 1, 5 do
        result[i] = street[6 - i]
    end

    return result
end

---@param street ct.towers.Street
---@return ct.towers.LabelPair
function Towers.Street.label(street)
    return {
        line_of_sight(street),
        line_of_sight(Towers.Street.reverse(street)),
    }
end

Towers.LabelledStreet = {}

---@type ct.towers.LabelledStreet[]?
local all_labelled_streets = nil

---@return ct.towers.LabelledStreet[]
function Towers.LabelledStreet.all()
    if not all_labelled_streets then
        all_labelled_streets = {}

        for _, street in ipairs(Towers.Street.all()) do
            all_labelled_streets[#all_labelled_streets + 1] = {
                street = street,
                label = Towers.Street.label(street),
            }
        end
    end

    return all_labelled_streets
end

Towers.LabelPair = {}

---@param a ct.towers.LabelPair
---@param b ct.towers.LabelPair
---@return boolean
function Towers.LabelPair.equals(a, b)
    return a[1] == b[1] and a[2] == b[2]
end

---@alias ct.towers.CandidateMap table<ct.towers.StreetLabel, table<ct.towers.StreetLabel, ct.towers.Street[]>>

---@type ct.towers.CandidateMap?
local candidates = nil

---@return ct.towers.CandidateMap
function Towers.LabelPair.candidateMap()
    ---@type ct.towers.CandidateMap
    local result = {}

    for _, a in ipairs(Towers.all_towers) do
        result[a] = {}

        for _, b in ipairs(Towers.all_towers) do
            result[a][b] = {}

            for _, labelled in ipairs(Towers.LabelledStreet.all()) do
                if Towers.LabelPair.equals({ a, b }, labelled.label) then
                    result[a][b][#result[a][b] + 1] = labelled.street
                end
            end
        end
    end

    return result
end

---@param label ct.towers.LabelPair
---@return ct.towers.Street[]
function Towers.LabelPair.getCandidates(label)
    if not candidates then
        candidates = Towers.LabelPair.candidateMap()
    end

    -- A label outside 1 to 5 has no streets, so the puzzle has no solution instead of raising an error.
    local by_first = candidates[label[1]]
    return by_first and by_first[label[2]] or {}
end

Towers.Hints = {}

Towers.Blocks = {}

---@return ct.towers.Blocks
function Towers.Blocks.empty()
    return {
        rows = {
            Towers.Street.empty(),
            Towers.Street.empty(),
            Towers.Street.empty(),
            Towers.Street.empty(),
            Towers.Street.empty(),
        },
    }
end

Towers.Puzzle = {}

---@param matrix integer[][]
---@param index integer
---@return integer[]
local function column(matrix, index)
    ---@type integer[]
    local result = {}

    for row_index, row in ipairs(matrix) do
        result[row_index] = row[index]
    end

    return result
end

---@param puzzle ct.towers.HintPairs
---@return ct.towers.Blocks?
function Towers.Puzzle.solve(puzzle)
    ---@param rows ct.towers.Street[]
    ---@param column_hints ct.towers.LabelPair[]
    ---@return boolean
    local function valid(rows, column_hints)
        local row_count = #rows

        if row_count > 0 then
            for column_index = 1, 5 do
                for row_index = 1, row_count - 1 do
                    if rows[row_index][column_index]
                        == rows[row_count][column_index]
                    then
                        return false
                    end
                end
            end
        end

        if row_count == 5 then
            for column_index = 1, 5 do
                local actual_label =
                    Towers.Street.label(column(rows, column_index))

                if not Towers.LabelPair.equals(
                        actual_label,
                        column_hints[column_index]
                    ) then
                    return false
                end
            end
        end

        return true
    end

    ---@param hint_index integer
    ---@param streets_so_far ct.towers.Street[]
    ---@return ct.towers.Blocks?
    local function backtrack(hint_index, streets_so_far)
        if not valid(streets_so_far, puzzle.columns) then
            return nil
        end

        if hint_index > #puzzle.rows then
            return { rows = streets_so_far --[[@as [ct.towers.Street, ct.towers.Street, ct.towers.Street, ct.towers.Street, ct.towers.Street] ]] }
        end

        local hint = puzzle.rows[hint_index]

        for _, candidate in ipairs(
            Towers.LabelPair.getCandidates(hint)
        ) do
            ---@type ct.towers.Street[]
            local next_streets = {}

            for i, street in ipairs(streets_so_far) do
                next_streets[i] = street
            end

            next_streets[#next_streets + 1] = candidate

            local result = backtrack(hint_index + 1, next_streets)

            if result then
                return result
            end
        end

        return nil
    end

    return backtrack(1, {})
end

---@param hints ct.towers.Hints
---@return ct.towers.PuzzleState?
function Towers.solve(hints)
    local columns = zyklib.array.zip(hints.top, hints.bottom)
    local rows = zyklib.array.zip(hints.left, hints.right)

    ---@type ct.towers.HintPairs
    local pairs = {
        columns = columns,
        rows = rows,
    }

    local blocks = Towers.Puzzle.solve(pairs)

    if not blocks then
        return nil
    end

    return {
        hints = hints,
        blocks = blocks,
    }
end

return Towers
