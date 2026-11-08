-- navigator.lua
local PathMesh           = require "cluetrainer/model/PathMesh"
local TeleportSpot       = require "cluetrainer/model/shared/TeleportSpot"
local coordinate_adaptor = require "cluetrainer/model/shared/coordinate_adaptor"
local PathProgress       = require "cluetrainer/solving/common/path_progress"
local array              = require "zyklib/array"
local zyklib             = require "zyklib"

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
  if self.progress and self.progress:update(coordinate_adaptor.playerTile()) then
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
      geometry = PathMesh.buildStepMesh(step, {
            context_path = path,
            i = index
          })
          :setIgnoreDepth(true) -- TODO: Only ignore depth if on the same level as the player and is not completed, otherwise it looks weird
          :activate()
    }
  end)
  self.progress = PathProgress.new(path)
  self.progress:update(coordinate_adaptor.playerTile())
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
