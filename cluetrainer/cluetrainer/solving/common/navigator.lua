-- navigator.lua
local path_shapes     = require "cluetrainer/solving/common/path_shapes"
local Path            = require "cluetrainer/model/path"
local TileArea        = require("cluetrainer/math/math").tilearea
local TeleportSpot    = require "cluetrainer/model/TeleportSpot"
local tilecoordinates = require("cluetrainer/math/math").tilecoordinates
local array           = require "zyklib/array"
local zyklib          = require "zyklib"

-- How far the player got along a path. A step is reached when the player arrives at its end: walks into it after being
-- outside it. Being somewhere when it becomes a candidate is not an arrival, so a route that comes back past an earlier
-- spot or ends near where the player stands doesn't fade early. Progress only moves forward, so steps already walked stay
-- done when the route turns back past them.
---Tiles around a drawn end point (run, ability, cheat) that still count: players stop next to a waypoint, not on it.
local MARGIN          = 2
---Teleport and transport ends are areas the game puts the player in, so they count as they are.
local EXACT           = { teleport = true, transport = true }
---Steps with an end checked past the last reached one: enough to skip a missed step or two, few enough that a far
---step that happens to end where the player is can't be reached.
local LOOKAHEAD       = 3

---@class ct.PathProgress
---@field done integer Steps reached so far; steps up to this index are done
---@field private ends (TileArea|false)[] Where each step ends; false for steps without an end of their own
---@field private teleports integer[] Indices of the teleport steps
---@field private teleport_at table<integer, true> The same, as a set
---@field private armed table<integer, true> Candidates the player was outside of since the last progress
local PathProgress    = {}
PathProgress.__index  = PathProgress

---@param path Path.Step[]
---@return ct.PathProgress
function PathProgress.new(path)
  local self = setmetatable({ done = 0, ends = {}, teleports = {}, teleport_at = {}, armed = {} }, PathProgress)

  for i, step in ipairs(path) do
    local area = Path.endsUpArea({ step })
    if area and not EXACT[step.type] then area = TileArea.grow(area, MARGIN) end
    self.ends[i] = area or false
    if step.type == "teleport" then
      self.teleports[#self.teleports + 1] = i
      self.teleport_at[i] = true
    end
  end

  return self
end

---The first teleport step that isn't done yet.
---@return integer?
function PathProgress:nextTeleport()
  for _, i in ipairs(self.teleports) do
    if i > self.done then return i end
  end
  return nil
end

---@private
---The steps that can be reached next, in path order: the next LOOKAHEAD steps with an end, and the next teleport
---wherever it is, because landing in a teleport's area means the player took it.
---@return integer[]
function PathProgress:_candidates()
  local list = {}
  for i = self.done + 1, #self.ends do
    if self.ends[i] then
      list[#list + 1] = i
      if #list == LOOKAHEAD then break end
    end
  end

  local teleport = self:nextTeleport()
  if teleport and self.ends[teleport] and teleport > (list[#list] or self.done) then list[#list + 1] = teleport end

  return list
end

---@private
---@param tile TileCoordinates
function PathProgress:_arm(tile)
  for _, i in ipairs(self:_candidates()) do
    if not TileArea.contains(self.ends[i], tile) then self.armed[i] = true end
  end
end

---@private
---The nearest candidate reached at `tile`. The next step counts as soon as the player stands at its end; a step further
---ahead, or a teleport, only when the player arrived at it.
---@param tile TileCoordinates
---@return integer?
function PathProgress:_reached(tile)
  for n, i in ipairs(self:_candidates()) do
    if TileArea.contains(self.ends[i], tile) then
      local next_step = n == 1 and not self.teleport_at[i]
      if next_step or self.armed[i] then return i end
    end
  end
  return nil
end

---Moves `done` to the nearest step reached, repeating for short steps that end where the player stands. Steps without
---an end of their own (orientation, redclick, powerburst, cosmetic) are done once a later step is reached.
---@param tile TileCoordinates? The player's tile
---@return boolean changed
function PathProgress:update(tile)
  if tile == nil then return false end

  local changed = false
  local reached = self:_reached(tile)
  while reached do
    self.done, changed = reached, true
    -- Arrivals count from here: a step further ahead that ends where the player stands needs a new arrival.
    self.armed = {}
    reached = self:_reached(tile)
  end

  self:_arm(tile)
  return changed
end

---@class PathStepEntity
---@field step Path.Step
---@field geometry zyklib.Highlight

---@class Navigator : zyklib.disposable.IDisposable
---@field path PathStepEntity[]
---@field logic_handler zyklib.reactive.EventHandler
---@field private progress ct.PathProgress?
---@field private onNextTeleportChanged fun(teleport: cluetrainer.TeleportSpot?)?
---@field private next_teleport_index integer?
local Navigator   = {}
Navigator.__index = Navigator

---@param onNextTeleportChanged (fun(teleport: cluetrainer.TeleportSpot?))?
---@return Navigator
function Navigator.new(onNextTeleportChanged)
  ---@type Navigator
  local self = setmetatable({}, Navigator)

  self.path = {}
  self.onNextTeleportChanged = onNextTeleportChanged

  self.logic_handler = zyklib.game_events.native.ServerLogic:subscribe(function(event)
    self:update_progress()
  end)

  return self
end

---@private
---Draws the steps up to the progress faded and behind the scenery, the rest bright and on top.
function Navigator:_paint()
  local done = self.progress and self.progress.done or 0
  for i, value in ipairs(self.path) do
    local completed = i <= done

    value.geometry:setColour(completed and 0x80808080 or 0xFFFFFFFF)
    value.geometry:setIgnoreDepth(not completed)
  end
end

function Navigator:update_progress()
  if self.progress and self.progress:update(tilecoordinates.player()) then
    self:_paint()
    self:_announceTeleport(false)
  end
end

---@private
---Reports the first teleport after the progress, so the teleport row and the faded steps always agree.
---@param force boolean Report even if it didn't change (a new path)
function Navigator:_announceTeleport(force)
  if not self.onNextTeleportChanged then return end

  local index = self.progress and self.progress:nextTeleport()
  if index == self.next_teleport_index and not force then return end
  self.next_teleport_index = index

  local teleport = nil
  if index then
    local id = self.path[index].step.id
    teleport = TeleportSpot.resolve(id)
    assert(teleport, "Cannot resolve teleport " .. tostring(id.group) .. "/" .. tostring(id.spot))
  end
  self.onNextTeleportChanged(teleport)
end

--- Set the current path to the given path segments.
---@param path Path.Step[]
function Navigator:set(path)
  self:clear()

  self.path = array.map(path, function(step, index)
    return {
      step = step,
      geometry = path_shapes.buildStepMesh(step, {
            context_path = path,
            i = index
          })
          :setIgnoreDepth(true) -- TODO: Only ignore depth if on the same level as the player and is not completed, otherwise it looks weird
          :activate()
    }
  end)
  self.progress = PathProgress.new(path)
  self.progress:update(tilecoordinates.player())
  self:_paint()
  self:_announceTeleport(true)
end

function Navigator:clear()
  for _, value in ipairs(self.path) do
    value.geometry:deactivate()
  end

  self.path = {}
  self.progress = nil
  local had_teleport = self.next_teleport_index ~= nil
  self.next_teleport_index = nil
  if had_teleport and self.onNextTeleportChanged then self.onNextTeleportChanged(nil) end
end

function Navigator:dispose()
  self:clear()
  if self.logic_handler then
    self.logic_handler:cancel()
    self.logic_handler = nil
  end
end

return Navigator
