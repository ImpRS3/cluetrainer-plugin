-- path.lua
local TileArea = require "cluetrainer/model/shared/TileArea"
local TeleportSpot = require "cluetrainer/model/shared/TeleportSpot"
local array = require "zyklib/array"
local Bounds = require("cluetrainer/util/Bounds")
local tiles = require "cluetrainer/model/shared/tiles"

---@alias Direction any
---@alias MovementAbility any
---@alias Transportation.TeleportGroup.SpotId {group: string, spot: string, access: string?}
---@alias EntityTransportation any
---@alias CTRIcon.ID any
---@alias MyCursorType string


---@class Path.Step.Base
---@field type string
---@field description? string
---@field is_arrival_only? boolean


---@class Path.Step.Orientation : Path.Step.Base
---@field type "orientation"
---@field direction Direction


---@class Path.Step.Ability : Path.Step.Base
---@field type "ability"
---@field ability MovementAbility
---@field target? EntityName
---@field target_text? string
---@field target_area? TileArea
---@field is_far_dive? boolean
---@field from TileCoordinates
---@field to TileCoordinates


---@class Path.Step.Run : Path.Step.Base
---@field type "run"
---@field target_area? TileArea
---@field to_text? string
---@field waypoints TileCoordinates[]


---@class Path.Step.Teleport : Path.Step.Base
---@field type "teleport"
---@field id Transportation.TeleportGroup.SpotId
---@field spot TileCoordinates


---@class Path.Step.Transport : Path.Step.Base
---@field type "transport"
---@field assumed_start TileCoordinates?
---@field internal EntityTransportation


---@class Path.Step.RedClick : Path.Step.Base
---@field type "redclick"
---@field target EntityName
---@field where TileCoordinates
---@field how MyCursorType


---@class Path.Step.Powerburst : Path.Step.Base
---@field type "powerburst"
---@field where TileCoordinates


---@class Path.Step.Cheat : Path.Step.Base
---@field type "cheat"
---@field assumed_start TileCoordinates?
---@field target TileCoordinates
---@field orientation? Direction
---@field ticks number


---@class Path.Step.Cosmetic : Path.Step.Base
---@field type "cosmetic"
---@field icon CTRIcon.ID
---@field position TileCoordinates
---@field hide_when_not_hovered? boolean
---@field area? TileArea
---@field area_color? string
---@field arrow? [TileCoordinates, TileCoordinates]
---@field arrow_color? string

---@alias Path.Step
---| Path.Step.Orientation
---| Path.Step.Ability
---| Path.Step.Run
---| Path.Step.Teleport
---| Path.Step.Transport
---| Path.Step.RedClick
---| Path.Step.Powerburst
---| Path.Step.Cheat
---| Path.Step.Cosmetic

---@alias Path.Raw Path.Step[]
---@alias Path Path.Raw

---@alias EntityName.Kind
---| "npc"
---| "static"
---| "item"

---@class EntityName
---@field name string
---@field kind EntityName.Kind

local Path = {}

---@param id Transportation.TeleportGroup.SpotId
---@return TileArea?
local function resolve_teleport(id)
  local teleports = require("cluetrainer/data/teleports")

  local group = array.find(teleports, function(value, index)
    return value.id == id.group
  end)

  if group == nil then return nil end

  local spot = array.find(group.spots, function(value, index)
    return value.id == id.spot
  end)

  if spot == nil then return nil end

  return spot.target
end

---@param path Path.Raw
---@return TileArea?
function Path.endsUpArea(path)
  for i = #path, 1, -1 do
    local step = path[i]

    if step.type == "ability" then
      return TileArea.tile(step.to)
    elseif step.type == "run" then
      return TileArea.tile(step.waypoints[#step.waypoints])
    elseif step.type == "cheat" then
      return TileArea.tile(step.target)
    elseif step.type == "teleport" then
      return resolve_teleport(step.id)
    elseif step.type == "transport" then
      -- Where the transport puts the player: its fixed destination area, otherwise the tile it ends on.
      local movement = Path.find_applicable_movement(step.internal.actions[1], step.assumed_start)
      if movement and movement.fixed_target then return movement.fixed_target.target end

      local tile = Path.endsUp({ step })
      if tile then return TileArea.tile(tile) end
    end
  end

  return nil
end

--- The first teleport of a path, if it has one.
---@param path Path.Raw
---@return cluetrainer.TeleportSpot?
function Path.firstTeleport(path)
  local step = array.find(path, function(step) return step.type == "teleport" end)
  return step and TeleportSpot.resolve(step.id)
end

-- Steps that move the player over the ground, drawn as a line to follow.
local MOVEMENT_STEPS = { run = true, ability = true, redclick = true, transport = true, cheat = true }

--- Whether the path moves the player over the ground besides teleporting, i.e. has a line to follow.
---@param path Path.Raw
---@return boolean
function Path.hasMovement(path)
  return array.exists(path, function(step) return MOVEMENT_STEPS[step.type] == true end)
end

--- Finds the movement of `action` that applies at `tile`: the first whose `valid_from` area contains it.
---@param action table
---@param tile TileCoordinates?
---@return table? movement
function Path.find_applicable_movement(action, tile)
  if tile then
    for _, movement in ipairs(action.movement) do
      if movement.valid_from and TileArea.ensure_mutable(movement.valid_from):query(tile) then
        return movement
      end
    end
  end

  return action.movement[1]
end

--- The tile a path ends up on, scanning backwards for the last step that moves the player.
---@param path Path.Raw
---@return TileCoordinates?
function Path.endsUp(path)
  for i = #path, 1, -1 do
    local step = path[i]

    if step.type == "cheat" then
      return step.target
    elseif step.type == "ability" then
      return step.to
    elseif step.type == "run" then
      return step.waypoints[#step.waypoints]
    elseif step.type == "teleport" then
      if step.spot then return step.spot end

      local spot = TeleportSpot.resolve(step.id)
      return spot and spot:center_of_target() or nil
    elseif step.type == "transport" then
      local start_tile = step.assumed_start
      local action = step.internal.actions[1]
      local movement = Path.find_applicable_movement(action, start_tile)

      if movement and movement.offset and start_tile then
        return {
          x = start_tile.x + movement.offset.x,
          y = start_tile.y + movement.offset.y,
          level = start_tile.level + movement.offset.level,
        }
      elseif movement and movement.fixed_target then
        local target = movement.fixed_target.target
        return TileArea.ensure_mutable(target):center(target)
      end
    end
  end

  return nil
end

local FAR_TRANSPORT_THRESHOLD = 16

--- Whether a step moves far enough to start a new section.
---@param step Path.Step
---@param context {path: Path.Raw, position: integer}? Position is 0-based, as in `split_into_sections`.
---@param threshold number?
---@return boolean
function Path.isFar(step, context, threshold)
  threshold = threshold or FAR_TRANSPORT_THRESHOLD

  if step.type == "transport" or step.type == "cheat" then
    local new_pos = Path.endsUp({ step })
    local start = step.assumed_start
    if not new_pos or not start then return false end

    return tiles.distance(start, new_pos) > threshold
  elseif step.type == "teleport" then
    if context then
      return context.position > 0 and context.path[context.position].type == "orientation"
    end
    return false
  end

  return false
end

--- Splits a path into sections. A far transport or cheat arrives in the section it ends and is repeated
--- as an arrival-only step at the start of the next one.
---@param path Path.Raw
---@param far_threshold number?
---@return {name: string, steps: Path.Step[]}[] sections
function Path.split_into_sections(path, far_threshold)
  -- Section ends as 0-based exclusive indices into the path, as in the original.
  local dividers = {}

  local function division(i)
    if i > 0 and (#dividers == 0 or dividers[#dividers] ~= i) then
      dividers[#dividers + 1] = i
    end
  end

  local pos = nil

  for i = 0, #path - 1 do
    local step = path[i + 1]
    local new_pos = Path.endsUp({ step })

    if step.type == "teleport" then
      if i >= 1 and path[i].type == "orientation" then
        division(i - 1)
      else
        division(i)
      end
    elseif (step.type == "transport" or step.type == "cheat") and pos then
      if (new_pos and new_pos.level ~= pos.level) or Path.isFar(step) then
        division(i + 1)
      end
    end

    if new_pos then pos = new_pos end
  end

  division(#path)

  ---@type {name: string, steps: Path.Step[]}[]
  local sections = {}
  local bleeding_arrival = nil

  for i, finish in ipairs(dividers) do
    local begin = i == 1 and 0 or dividers[i - 1]

    local section = {}
    if bleeding_arrival then section[1] = bleeding_arrival end
    for j = begin + 1, finish do section[#section + 1] = path[j] end
    sections[#sections + 1] = { name = "Section " .. #sections + 1, steps = section }

    bleeding_arrival = nil

    local last = section[#section]
    if last and Path.isFar(last, { path = path, position = finish - 1 }, far_threshold) then
      bleeding_arrival = {}
      for key, value in pairs(last) do bleeding_arrival[key] = value end
      bleeding_arrival.is_arrival_only = true
    end
  end

  if bleeding_arrival then sections[#sections + 1] = { name = "Section " .. #sections + 1, steps = { bleeding_arrival } } end

  return sections
end

function Path.bounds(path)
  local bounds = Bounds.new()

  for _, step in ipairs(path) do
    local type = step.type

    if type == "ability" then
      bounds:addTile(step.from, step.to)
      bounds:addArea(step.target_area)
    elseif type == "run" then
      for _, waypoint in ipairs(step.waypoints) do bounds:addTile(waypoint) end
      bounds:addArea(step.target_area)
    elseif type == "redclick" or type == "powerburst" then
      bounds:addTile(step.where)
    elseif type == "cosmetic" then
      bounds:addTile(step.position)
      bounds:addArea(step.area)
      if step.arrow then bounds:addTile(step.arrow[1], step.arrow[2]) end
    elseif type == "transport" or type == "cheat" then
      -- An arrival-only step only matters at its destination.
      if not step.is_arrival_only then bounds:addTile(step.assumed_start) end
      bounds:addTile(Path.endsUp({ step }))
    elseif type == "teleport" then
      bounds:addTile(Path.endsUp({ step }))
    end
  end

  return bounds
end

return Path
