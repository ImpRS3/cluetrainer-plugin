-- navigator.lua
local PathMesh           = require "cluetrainer/model/PathMesh"
local TileArea           = require "cluetrainer/model/shared/TileArea"
local TeleportSpot       = require "cluetrainer/model/shared/TeleportSpot"
local coordinate_adaptor = require "cluetrainer/model/shared/coordinate_adaptor"
local array              = require "zyklib/array"
local zyklib             = require "zyklib"

---@class PathStepEntity
---@field step Path.Step
---@field geometry zyklib.Highlight

---@class Navigator : zyklib.disposable.IDisposable
---@field path PathStepEntity[]
---@field logic_handler zyklib.reactive.EventHandler
---@field private onNextTeleportChanged fun(teleport: cluetrainer.TeleportSpot?)?
---@field private next_teleport cluetrainer.TeleportSpot?
---@field private next_teleport_index integer?
---@field private inside_teleport_target boolean?
local Navigator   = {}
Navigator.__index = Navigator

local function isCompleted(step)
  ---@type CoordGrid
  local true_tile = Player.GetEntity().routeEnd

  ---@type TileCoordinates
  local tile = { x = true_tile.x, y = true_tile.z, level = true_tile.level }

  local function distance(a, b)
    return math.abs(a.x - b.x) + math.abs(a.y - b.y)
  end

  if step.type == "ability" then
    return distance(step.from, tile) > distance(step.to, tile)
  elseif step.type == "run" then
    local start = step.waypoints[1]
    local finish = step.waypoints[#step.waypoints]

    return distance(start, tile) >= distance(start, finish) and distance(start, tile) > distance(finish, tile)
  end

  return false
end

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

function Navigator:update_progress()
  for _, value in ipairs(self.path) do
    local completed = isCompleted(value.step)

    value.geometry:setColour(completed and 0x80808080 or 0xFFFFFFFF)
    value.geometry:setIgnoreDepth(not completed)
  end

  if self.next_teleport then
    local tile = coordinate_adaptor.playerTile()
    if tile then
      local inside = TileArea.contains(self.next_teleport:target_area(), tile)
      if inside and self.inside_teleport_target == false then
        local index = assert(self.next_teleport_index)
        self:_findNextTeleport(index + 1, tile)
      else
        self.inside_teleport_target = inside
      end
    end
  end
end

---@private
---@param start integer
---@param tile TileCoordinates?
function Navigator:_findNextTeleport(start, tile)
  local teleport, index
  for i = start, #self.path do
    local step = self.path[i].step
    if step.type == "teleport" then
      teleport = TeleportSpot.resolve(step.id)
      assert(teleport, "Cannot resolve teleport " .. tostring(step.id.group) .. "/" .. tostring(step.id.spot))
      index = i
      break
    end
  end

  self.next_teleport, self.next_teleport_index = teleport, index
  -- Starting inside a target is not an arrival; wait for the player to leave and enter it.
  self.inside_teleport_target = nil
  if teleport and tile then
    self.inside_teleport_target = TileArea.contains(teleport:target_area(), tile)
  end
  local callback = assert(self.onNextTeleportChanged)
  callback(teleport)
end

--- Set the current path to the given path segments.
---@param path Path.Step[]
function Navigator:set(path)
  self:clear()

  self.path = array.map(path, function(step, index)
    return {
      step = step,
      geometry = PathMesh.buildStepMesh(step, {
            context_path = path,
            i = index
          })
          :setIgnoreDepth(true) -- TODO: Only ignore depth if on the same level as the player and is not completed, otherwise it looks weird
          :activate()
    }
  end)

  if self.onNextTeleportChanged then
    self:_findNextTeleport(1, coordinate_adaptor.playerTile())
  end
  self:update_progress()
end

function Navigator:clear()
  for _, value in ipairs(self.path) do
    value.geometry:deactivate()
  end

  self.path = {}
  local had_teleport = self.next_teleport ~= nil
  self.next_teleport, self.next_teleport_index, self.inside_teleport_target = nil, nil, nil
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
