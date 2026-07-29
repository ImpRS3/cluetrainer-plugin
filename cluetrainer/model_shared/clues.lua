local clues = {}

---@alias TileArea any
---@alias Challenge any
---@alias CursorType any

---@alias ClueTier
---| "easy"
---| "medium"
---| "hard"
---| "elite"
---| "master"
---| "tetracompass"
---| "sandy"

---@type { values: ClueTier[] }
clues.ClueTier = {
    values = {
        "easy",
        "medium",
        "hard",
        "elite",
        "master",
        "tetracompass",
        "sandy",
    },
}

---@alias ClueType
---| "anagram"
---| "compass"
---| "coordinates"
---| "cryptic"
---| "emote"
---| "map"
---| "scan"
---| "simple"
---| "skilling"

-- Solution

---@alias Solution
---| Solution.TalkTo
---| Solution.Dig
---| Solution.Search


---@class Solution.TalkToSpot
---@field id? string
---@field range TileArea Covers exactly the NPC's roaming range.
---@field note? string Conditions for the NPC to be at this spot.
---@field description string For example, "in City of Um" or "at the Bank".


---@class Solution.TalkTo
---@field type "talkto"
---@field npc string
---@field spots Solution.TalkToSpot[]


---@class Solution.Dig
---@field type "dig"
---@field spot TileCoordinates
---@field description string|nil For example, "on top of the fern".


---@class Solution.SearchKey
---@field instructions string
---@field answer string
---@field area? TileArea


---@class Solution.Search
---@field type "search"
---@field spot TileRectangle
---@field entity string
---@field key? Solution.SearchKey


-- Shared step fields

---@class StepShared
---@field id number
---@field type ClueType
---@field tier ClueTier
---@field text string[]
---@field challenge? Challenge[]
---@field solution? Solution


-- Step variants

---@class Anagram : StepShared
---@field type "anagram"
---@field solution Solution.TalkTo
---@field anagram string[]


---@class Compass : StepShared
---@field type "compass"
---@field spots TileCoordinates[]
---@field valid_area TileRectangle
---@field single_tile_target? boolean


---@class Coordinate : StepShared
---@field type "coordinates"
---@field coordinates GieliCoordinates


---@class Cryptic : StepShared
---@field type "cryptic"
---@field solution Solution


---@class Emote.HideyHole
---@field location TileRectangle
---@field name string


---@class Emote : StepShared
---@field type "emote"
---@field area TileArea
---@field items string[]
---@field emotes string[]
---@field double_agent boolean
---@field hidey_hole Emote.HideyHole|nil


---@class Map : StepShared
---@field type "map"
---@field ocr_data number[]
---@field solution Solution
---@field image_url string


---@class Scan : StepShared
---@field type "scan"
---@field scantext string
---@field range number
---@field spots TileCoordinates[]


---@class Simple : StepShared
---@field type "simple"
---@field solution Solution


---@class Skilling : StepShared
---@field type "skilling"
---@field areas TileArea[]
---@field answer string
---@field cursor CursorType


---@alias Step
---| Anagram
---| Compass
---| Coordinate
---| Cryptic
---| Emote
---| Map
---| Scan
---| Simple
---| Skilling


---@generic T: Step
---@class ClueSpot
---@field clue T
---@field spot? TileCoordinates

---@class ClueSpot.Id
---@field clue number
---@field spot? TileCoordinates

return clues