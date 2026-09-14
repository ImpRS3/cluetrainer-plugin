---@class Towers
local Towers = {}

---@alias Tower 1|2|3|4|5
---@alias Street {[1]: Tower?, [2]: Tower?, [3]: Tower?, [4]: Tower?, [5]: Tower?}
---@alias StreetLabel integer
---@alias LabelPair {[1]: StreetLabel, [2]: StreetLabel}

---@class LabelledStreet
---@field street Street
---@field label LabelPair

---@class Towers.Hints
---@field top StreetLabel[]
---@field bottom StreetLabel[]
---@field left StreetLabel[]
---@field right StreetLabel[]

---@class HintPairs
---@field rows {[1]: LabelPair, [2]: LabelPair, [3]: LabelPair, [4]: LabelPair, [5]: LabelPair}
---@field columns {[1]: LabelPair, [2]: LabelPair, [3]: LabelPair, [4]: LabelPair, [5]: LabelPair}

---@class Towers.Blocks
---@field rows {[1]: Street, [2]: Street, [3]: Street, [4]: Street, [5]: Street}

---@class Towers.PuzzleState
---@field hints Towers.Hints
---@field blocks Towers.Blocks

---@type Tower[]
Towers.towers = { 1, 2, 3, 4, 5 }

Towers.Street = {}

---@type Street[]?
local all_streets = nil

---@return Street
function Towers.Street.empty()
    return {0, 0, 0, 0, 0}
end

---@generic T
---@param elements T[]
---@return T[][]
local function all_permutations(elements)
    if #elements == 0 then
        return { {} }
    end

    ---@type T[][]
    local result = {}

    for i, next_value in ipairs(elements) do
        ---@type T[]
        local remaining = {}

        for index, value in ipairs(elements) do
            if index ~= i then
                remaining[#remaining + 1] = value
            end
        end

        for _, permutation in ipairs(all_permutations(remaining)) do
            ---@type T[]
            local combined = { next_value }

            for _, value in ipairs(permutation) do
                combined[#combined + 1] = value
            end

            result[#result + 1] = combined
        end
    end

    return result
end

---@return Street[]
function Towers.Street.all()
    if not all_streets then
        all_streets = all_permutations({ 1, 2, 3, 4, 5 })
    end

    return all_streets
end

---@param street Street
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

---@param street Street
---@return Street
function Towers.Street.reverse(street)
    ---@type Street
    local result = {}

    for i = 1, 5 do
        result[i] = street[6 - i]
    end

    return result
end

---@param street Street
---@return LabelPair
function Towers.Street.label(street)
    return {
        line_of_sight(street),
        line_of_sight(Towers.Street.reverse(street)),
    }
end

Towers.LabelledStreet = {}

---@type LabelledStreet[]?
local all_labelled_streets = nil

---@return LabelledStreet[]
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

---@param a LabelPair
---@param b LabelPair
---@return boolean
function Towers.LabelPair.equals(a, b)
    return a[1] == b[1] and a[2] == b[2]
end

---@alias CandidateMap table<StreetLabel, table<StreetLabel, Street[]>>

---@type CandidateMap?
local candidates = nil

---@return CandidateMap
function Towers.LabelPair.candidateMap()
    ---@type CandidateMap
    local result = {}

    for _, a in ipairs(Towers.towers) do
        result[a] = {}

        for _, b in ipairs(Towers.towers) do
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

---@param label LabelPair
---@return Street[]
function Towers.LabelPair.getCandidates(label)
    if not candidates then
        candidates = Towers.LabelPair.candidateMap()
    end

    return candidates[label[1]][label[2]]
end

Towers.Hints = {}

---@return Towers.Hints
function Towers.Hints.empty()
    return {
        top = {},
        bottom = {},
        left = {},
        right = {},
    }
end

Towers.Blocks = {}

---@return Towers.Blocks
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

---@param a Towers.Blocks
---@param b Towers.Blocks
---@return Towers.Blocks
function Towers.Blocks.combine(a, b)
    ---@type Street[]
    local rows = {}

    for y = 1, 5 do
        ---@type Street
        rows[y] = {}

        for x = 1, 5 do
            if a.rows[y][x] ~= nil then
                rows[y][x] = a.rows[y][x]
            else
                rows[y][x] = b.rows[y][x]
            end
        end
    end

    ---@cast rows {[1]: Street, [2]: Street, [3]: Street, [4]: Street, [5]: Street}
    return { rows = rows }
end

Towers.Puzzle = {}

---@generic T
---@param matrix T[][]
---@param index integer
---@return T[]
local function column(matrix, index)
    ---@type T[]
    local result = {}

    for row_index, row in ipairs(matrix) do
        result[row_index] = row[index]
    end

    return result
end

---@param puzzle HintPairs
---@return Towers.Blocks?
function Towers.Puzzle.solve(puzzle)
    ---@param rows Street[]
    ---@param column_hints LabelPair[]
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
    ---@param streets_so_far Street[]
    ---@return Towers.Blocks?
    local function backtrack(hint_index, streets_so_far)
        if not valid(streets_so_far, puzzle.columns) then
            return nil
        end

        if hint_index > #puzzle.rows then
            ---@cast streets_so_far {[1]: Street, [2]: Street, [3]: Street, [4]: Street, [5]: Street}
            return { rows = streets_so_far }
        end

        local hint = puzzle.rows[hint_index]

        for _, candidate in ipairs(
            Towers.LabelPair.getCandidates(hint)
        ) do
            ---@type Street[]
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

---@param first StreetLabel[]
---@param second StreetLabel[]
---@return LabelPair[]
local function zip_labels(first, second)
    ---@type LabelPair[]
    local result = {}

    for i = 1, 5 do
        result[i] = { first[i], second[i] }
    end

    return result
end

---@param hints Towers.Hints
---@return Towers.PuzzleState?
function Towers.solve(hints)
    local columns = zip_labels(hints.top, hints.bottom)
    local rows = zip_labels(hints.left, hints.right)

    ---@cast columns {[1]: LabelPair, [2]: LabelPair, [3]: LabelPair, [4]: LabelPair, [5]: LabelPair}
    ---@cast rows {[1]: LabelPair, [2]: LabelPair, [3]: LabelPair, [4]: LabelPair, [5]: LabelPair}

    ---@type HintPairs
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