-- LiveNarrowing.lua
-- Narrows the dig spots down on every pulse from what the player sees: the scan panel and their own tile, wherever
-- they stand, plus the single or double the player tells with Shift+1/2. A spot is only ruled out when it fits none
-- of the tiles the player stood on around the pulse, so the right spot is never dropped. A triple's paces judge every
-- spot again, so a wrong key press before it can't hide the dig spot.
local scan_panel       = require "cluetrainer/solving/scan/scan_panel"
local scan_tree        = require "cluetrainer/solving/scan/scan_tree"
local tiles            = require "cluetrainer/model/shared/tiles"
local array            = require "zyklib/array"

local PULSE_TICKS      = scan_panel.PULSE_TICKS
-- Check a reading against the tiles from a few ticks before to one server tick (30 logic ticks) after the text
-- changed, to cover the client showing a running player up to a tile behind.
local TILES_BEFORE     = 10
local TILES_AFTER      = 30
-- A key press is about one of the last two pulses: the player may have walked on or teleported since the last one.
local PRESS_PULSES     = 2
-- The longest look back when a reading is applied: a key press, applied TILES_AFTER after it was pressed.
local KEEP_SAMPLE_TICKS = PRESS_PULSES * PULSE_TICKS + TILES_BEFORE + TILES_AFTER

---@class ct.LiveNarrowing.Reading
---@field state ct.ScanPanel.State
---@field ranges integer[] The scan ranges the reading may have been taken with; a spot fits when it fits one
---@field paces integer?
---@field pulse (1 | 2)? Single or double as the player told it

---@class ct.LiveNarrowing.Pending
---@field from integer First logic tick of the tiles to check against
---@field to integer Last logic tick, the reading is applied once it has passed
---@field reading ct.LiveNarrowing.Reading
---@field source "panel" | integer The panel, or the number of the key press that told it

---@class ct.LiveNarrowing
---@field private spots TileCoordinates[]
---@field private clue_range integer The clue's range without meerkats
---@field private ruled_out table<string, "panel" | integer> What ruled the spot out: the panel or a key press
---@field private presses integer
---@field private samples {tick: integer, tile: TileCoordinates}[] Every tile change, oldest first
---@field private pending ct.LiveNarrowing.Pending[]
---@field private text string? The panel text as last seen, nil while the panel is hidden
---@field private found boolean
---@field private reading ct.LiveNarrowing.Reading? The reading of the current text
---@field private next_pulse integer? When the next pulse is due while the text stays the same
---@field private known_range integer?
---@field private paced boolean Whether a triple's paces narrowed the spots
local LiveNarrowing = {}
LiveNarrowing.__index = LiveNarrowing

---@param spots TileCoordinates[]
---@param clue_range integer
---@return ct.LiveNarrowing
function LiveNarrowing.new(spots, clue_range)
  return setmetatable({
    spots = spots,
    clue_range = clue_range,
    ruled_out = {},
    presses = 0,
    samples = {},
    pending = {},
    found = false,
    paced = false,
  }, LiveNarrowing)
end

--- The scan range as the panel showed it, including meerkats.
---@return integer?
function LiveNarrowing:range()
  return self.known_range
end

--- Whether a triple's paces narrowed the spots: those left then hold wherever the route went.
---@return boolean
function LiveNarrowing:hasPaces()
  return self.paced
end

--- The given spots without the ones the readings ruled out.
---@param spots TileCoordinates[]
---@return TileCoordinates[]
function LiveNarrowing:filter(spots)
  return array.filter(spots, function(spot) return not self.ruled_out[tiles.key(spot)] end)
end

--- The scan range as the panel showed it; until then the clue's range both without and with meerkats.
---@private
---@return integer[]
function LiveNarrowing:possibleRanges()
  if self.known_range then return { self.known_range } end
  return { self.clue_range, self.clue_range + scan_panel.MEERKATS_RANGE }
end

--- What a panel reading tells about the dig spot, nil when nothing. Remembers the range when the panel shows it.
---@private
---@param panel ct.ScanPanel.Reading
---@return ct.LiveNarrowing.Reading?
function LiveNarrowing:interpret(panel)
  local state = panel.state
  self.known_range = scan_panel.range(panel, self.clue_range) or self.known_range

  if state == "too_far" and panel.range then
    return { state = state, ranges = { panel.range } }
  elseif state == "triple" and panel.paces then
    return { state = state, ranges = self:possibleRanges(), paces = panel.paces }
  elseif state == "different_level" or state == "found" then
    return { state = state, ranges = self:possibleRanges() }
  end

  return nil
end

--- Whether the game shows `reading` at `tile` with scan range `range` when `spot` is the dig spot.
---@param reading ct.LiveNarrowing.Reading
---@param range integer
---@param spot TileCoordinates
---@param tile TileCoordinates
---@return boolean
local function fitsRange(reading, range, spot, tile)
  local pulse, different_level = scan_tree.pulseAt(spot, tile, range)

  if reading.pulse ~= nil and pulse ~= reading.pulse then return false end

  if reading.state == "different_level" then
    return different_level
  elseif reading.state == "triple" then
    return not different_level and tiles.distance(spot, tile) == reading.paces
  end
  return not different_level and pulse < 3
end

--- Whether the game shows `reading` at `tile` when `spot` is the dig spot, with any of the reading's ranges.
---@param reading ct.LiveNarrowing.Reading
---@param spot TileCoordinates
---@param tile TileCoordinates
---@return boolean
local function fits(reading, spot, tile)
  if reading.state == "found" then return tiles.same(spot, tile) end
  return array.exists(reading.ranges, function(range) return fitsRange(reading, range, spot, tile) end)
end

--- The tiles the player stood on between two logic ticks, including the one at `from`.
---@private
---@param from integer
---@param to integer
---@return TileCoordinates[]
function LiveNarrowing:tilesBetween(from, to)
  local stood_on = {}
  for i, sample in ipairs(self.samples) do
    local next_sample = self.samples[i + 1]
    if sample.tick <= to and (next_sample == nil or next_sample.tick > from) then
      stood_on[#stood_on + 1] = sample.tile
    end
  end
  return stood_on
end

--- A triple's paces tell the dig spot whatever was read before: the spots at that distance stay, the others go. It
--- brings back spots a key press ruled out, as that press may have been wrong. Spots an earlier reading ruled out stay
--- out, unless that leaves none: then this triple wins, so a reading at a wrong tile can't hide the spot either.
---@private
---@param reading ct.LiveNarrowing.Reading
---@param stood_on TileCoordinates[]
---@return boolean changed
function LiveNarrowing:applyPaces(reading, stood_on)
  local fit, agrees = {}, false
  for _, spot in ipairs(self.spots) do
    local id = tiles.key(spot)
    if array.exists(stood_on, function(tile) return fits(reading, spot, tile) end) then
      fit[id] = true
      agrees = agrees or self.ruled_out[id] ~= "panel"
    end
  end

  -- Ignore paces no spot fits, so off data never loses the right spot.
  if next(fit) == nil then return false end
  self.paced = true

  local changed = false
  for _, spot in ipairs(self.spots) do
    local id = tiles.key(spot)
    local by = self.ruled_out[id]
    local keep = fit[id] and (by ~= "panel" or not agrees)
    -- The panel, not a key press, so undoing that press doesn't bring the spot back.
    local now = (not keep) and "panel" or nil
    changed = changed or (by == nil) ~= (now == nil)
    self.ruled_out[id] = now
  end
  return changed
end

---@private
---@param pending ct.LiveNarrowing.Pending
---@return boolean changed
function LiveNarrowing:apply(pending)
  local stood_on = self:tilesBetween(pending.from, pending.to)
  if #stood_on == 0 then return false end
  if pending.reading.state == "triple" then return self:applyPaces(pending.reading, stood_on) end

  -- The panel also judges spots a key press ruled out, so they stay out when that press is undone.
  local dropped, kept = {}, 0
  for _, spot in ipairs(self.spots) do
    local id = tiles.key(spot)
    local by = self.ruled_out[id]
    if by ~= "panel" and (pending.source == "panel" or by == nil) then
      if array.exists(stood_on, function(tile) return fits(pending.reading, spot, tile) end) then
        if by == nil then kept = kept + 1 end
      else
        dropped[#dropped + 1] = id
      end
    end
  end

  -- Ignore a reading no spot fits, so an off range, data or key press never loses the right spot.
  if kept == 0 then return false end

  local changed = false
  for _, id in ipairs(dropped) do
    changed = changed or self.ruled_out[id] == nil
    self.ruled_out[id] = pending.source
  end
  return changed
end

--- The player tells single or double, which the panel shows alike. Checked against the tiles of the last two pulses,
--- so a press after walking on or teleporting doesn't lose the right spot.
---@param tick integer
---@param pulse 1 | 2
---@return integer? press To undo it with, nil when the panel doesn't show single or double now
function LiveNarrowing:press(tick, pulse)
  local reading = self.reading
  if reading == nil or (reading.state ~= "too_far" and reading.state ~= "different_level") then return nil end

  self.presses = self.presses + 1
  table.insert(self.pending, {
    from = tick - PRESS_PULSES * PULSE_TICKS - TILES_BEFORE,
    to = tick + TILES_AFTER,
    reading = { state = reading.state, ranges = reading.ranges, pulse = pulse },
    source = self.presses,
  })
  return self.presses
end

--- Takes back what a key press ruled out.
---@param press integer
---@return boolean changed
function LiveNarrowing:undo(press)
  local changed = false
  for i = #self.pending, 1, -1 do
    if self.pending[i].source == press then table.remove(self.pending, i) end
  end
  for id, by in pairs(self.ruled_out) do
    if by == press then
      self.ruled_out[id] = nil
      changed = true
    end
  end
  return changed
end

--- Remembers the player's tile when it changed, and forgets tiles no reading can look back to.
---@private
---@param tick integer
---@param tile TileCoordinates?
function LiveNarrowing:trackTile(tick, tile)
  local last = self.samples[#self.samples]
  if tile ~= nil and (last == nil or not tiles.same(last.tile, tile)) then
    self.samples[#self.samples + 1] = { tick = tick, tile = tile }
  end
  while #self.samples > 1 and self.samples[2].tick < tick - KEEP_SAMPLE_TICKS do table.remove(self.samples, 1) end
end

--- Queues a reading for every pulse the panel shows: when its text changes, and when it stays the same over a pulse.
---@private
---@param tick integer
---@param capture ct.ScanPanel.Capture?
function LiveNarrowing:trackPanel(tick, capture)
  local text = capture and capture.text
  if text ~= self.text then
    -- Count a change as a pulse taken now, except when the panel just appeared or switched back from the dig spot
    -- text, to avoid judging a text from an earlier pulse at an unseen tile. That text counts from the next pulse.
    local fresh = self.text ~= nil and capture ~= nil and not (self.found and not capture.found)

    self.text, self.found = text, capture ~= nil and capture.found
    self.reading, self.next_pulse = nil, nil

    if capture ~= nil then
      self.reading = self:interpret(scan_panel.parse(text --[[@as string]]))
      if self.reading then
        if fresh then
          table.insert(self.pending,
            { from = tick - TILES_BEFORE, to = tick + TILES_AFTER, reading = self.reading, source = "panel" })
        end
        self.next_pulse = tick + PULSE_TICKS
      end
    end
  elseif self.next_pulse ~= nil and tick >= self.next_pulse + TILES_AFTER then
    -- Same text over another pulse: check against all tiles of the last pulse, so a first change off the pulse
    -- rhythm (after a loading screen) still fits.
    table.insert(self.pending, {
      from = self.next_pulse - PULSE_TICKS - TILES_BEFORE,
      to = tick,
      reading = self.reading,
      source = "panel",
    })
    self.next_pulse = self.next_pulse + PULSE_TICKS
  end
end

--- Applies the queued readings whose tiles are all known by now.
---@private
---@param tick integer
---@return boolean changed
function LiveNarrowing:applyDue(tick)
  local changed = false
  local i = 1
  while i <= #self.pending do
    if self.pending[i].to <= tick then
      changed = self:apply(table.remove(self.pending, i)) or changed
    else
      i = i + 1
    end
  end
  return changed
end

--- Takes in one logic tick: the player's tile and the panel.
---@param tick integer
---@param tile TileCoordinates?
---@param capture ct.ScanPanel.Capture?
---@return boolean changed Whether spots were ruled out
function LiveNarrowing:sample(tick, tile, capture)
  self:trackTile(tick, tile)
  self:trackPanel(tick, capture)
  return self:applyDue(tick)
end

return LiveNarrowing
