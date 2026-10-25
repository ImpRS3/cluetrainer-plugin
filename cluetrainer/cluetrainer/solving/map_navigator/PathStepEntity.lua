local elements = require("prettymap/elements")
local Path = require("cluetrainer/model/shared/path")
local TeleportSpot = require("cluetrainer/model/shared/TeleportSpot")
local geometry = require("cluetrainer/map/elements/geometry")
local AreaGraphics = require("cluetrainer/map/elements/AreaGraphics")
local PathGraphics = require("cluetrainer/map/elements/PathGraphics")
local InteractionMarker = require("cluetrainer/map/elements/InteractionMarker")
local ItemMarker = require("cluetrainer/map/elements/ItemMarker")
local PropertiesTooltip = require("cluetrainer/map/elements/PropertiesTooltip")
local TeleportElement = require("cluetrainer/map/elements/TeleportElement")

local WEIGHT = 3
local TRANSPORT_COLOUR = 0x069334
local RUN_COLOUR = 0xB4B4B4
local RUN_END_COLOUR = 0xB0E019
local REDCLICK_COLOUR = 0xFF0000
local FAR_ARROW_THRESHOLD = 16

-- TODO: verify against the original ability colours.
---@type table<string, integer>
local ABILITY_COLOURS = {
  surge = 0x00BFFF,
  escape = 0x32CD32,
  dive = 0xFFA500,
  barge = 0xFF6347,
}
local DEFAULT_ABILITY_COLOUR = 0xFFFFFF
local RUN_AREA_COLOUR = 0xFFFF00
local COSMETIC_AREA_COLOUR = 0x808080 -- TODO: Path.COSMETIC_DEFAULT_COLORS.area
local COSMETIC_ARROW_COLOUR = 0x808080 -- TODO: Path.COSMETIC_DEFAULT_COLORS.arrow

-- TODO: map more CTR icon ids to Obj ids; steps with an unknown icon get no marker.
---@type table<string, integer>
local ICON_OBJECTS = {
  ["item/rotten-potato"] = id.Obj["ROTTEN_POTATO"],
}

---@param hex string? Colour like "#ff8800".
---@param default integer
---@return integer
local function parse_colour(hex, default)
  local digits = hex and hex:match("^#?(%x%x%x%x%x%x)$")
  return digits and tonumber(digits, 16) or default
end

---@param tile TileCoordinates
---@return TileCoordinates
local function rounded_tile(tile)
  return { x = math.floor(tile.x + 0.5), y = math.floor(tile.y + 0.5), level = tile.level }
end

---@param step Path.Step
---@return string
local function step_header(step)
  return step.description or (step.type:sub(1, 1):upper() .. step.type:sub(2))
end

---@param step Path.Step
---@return cluetrainer.PropertiesTooltip
local function step_tooltip(step)
  return PropertiesTooltip.new():Header(step_header(step))
end

--- A step of a path rendered as map elements: arrows, markers and areas, with a tooltip on its markers.
---@class cluetrainer.PathStepEntity : prettymap.Element
---@field step Path.Step
local PathStepEntity = setmetatable({}, { __index = elements.Element })
PathStepEntity.__index = PathStepEntity

---@param tile TileCoordinates
---@return CoordGrid
local grid = geometry.grid

---@param self cluetrainer.PathStepEntity
---@param marker prettymap.Element
local function add_marker(self, marker)
  marker:SetTooltip(step_tooltip(self.step))
  self:Add(marker)
end

---@param self cluetrainer.PathStepEntity
---@param step Path.Step.Ability
local function build_ability(self, step)
  local colour = ABILITY_COLOURS[step.ability] or DEFAULT_ABILITY_COLOUR

  if step.target_area then
    self:Add(AreaGraphics.area(step.target_area, { colour = colour, weight = 1, opacity = 0.3, fillOpacity = 0.2 }))
  end

  local head = (step.is_far_dive or step.ability ~= "dive") and { head = "tip", arm_length = 0.5 }
      or { head = "x", arm_length = 0.25 }

  self:Add(PathGraphics.arrow(PathGraphics.offset_towards(step.from, step.to, 0.2), step.to, {
    colour = PathGraphics.rgba(colour, 1), weight = WEIGHT, head = head.head, arm_length = head.arm_length,
  }))
end

---@param self cluetrainer.PathStepEntity
---@param step Path.Step.Run
local function build_run(self, step)
  local waypoints = step.waypoints
  local last = waypoints[#waypoints]

  if step.target_area then
    self:Add(AreaGraphics.area(step.target_area,
      { colour = RUN_AREA_COLOUR, weight = 1, opacity = 0.6, fillOpacity = 0.2 }))
  end

  local points = {}
  for i, waypoint in ipairs(waypoints) do
    points[i] = (i == 1 and #waypoints >= 2) and PathGraphics.offset_towards(waypoint, waypoints[2], 0.2) or waypoint
  end
  self:Add(PathGraphics.polyline(points, PathGraphics.rgba(RUN_COLOUR, 1), WEIGHT))
  self:Add(PathGraphics.cross(last, 0.1, PathGraphics.rgba(RUN_END_COLOUR, 1), 5))
end

---@param self cluetrainer.PathStepEntity
---@param step Path.Step.Teleport
local function build_teleport(self, step)
  local teleport = TeleportSpot.resolve(step.id)
  if not teleport then return end

  local marker = TeleportElement.new(teleport)
  if step.spot then marker:SetCoordinate(grid(step.spot)) end
  self:Add(marker)
end

---@param self cluetrainer.PathStepEntity
---@param step Path.Step.RedClick
local function build_redclick(self, step)
  self:Add(PathGraphics.cross(step.where, 0.3, PathGraphics.rgba(REDCLICK_COLOUR, 1), WEIGHT))
  add_marker(self, InteractionMarker.new({ coordinate = grid(step.where), cursor = step.how }))
end

---@param self cluetrainer.PathStepEntity
---@param step Path.Step.Powerburst
local function build_powerburst(self, step)
  -- TODO: no Obj id known for the powerburst of acceleration yet.
  local obj = ICON_OBJECTS["item/powerburst-of-acceleration"]
  if obj then add_marker(self, ItemMarker.new(grid(step.where), obj)) end
end

---@param self cluetrainer.PathStepEntity
---@param step Path.Step.Transport
local function build_transport(self, step)
  local entity = step.internal
  local action = entity.actions[1]
  local movement = Path.find_applicable_movement(action, step.assumed_start)

  local is_remote = movement and movement.fixed_target and not movement.fixed_target.relative
  local ends_up = Path.endsUp({ step })
  local colour = PathGraphics.rgba(TRANSPORT_COLOUR, 1)

  if ends_up then
    local too_far = is_remote or Path.isFar(step, nil, FAR_ARROW_THRESHOLD)
    local start = step.assumed_start

    if step.is_arrival_only or not start or (start.x == ends_up.x and start.y == ends_up.y) or too_far then
      self:Add(PathGraphics.circle(ends_up, 0.1, colour, WEIGHT))
    else
      self:Add(PathGraphics.arrow(PathGraphics.offset_towards(start, ends_up, 0.2), ends_up,
        { colour = colour, weight = WEIGHT, dashed = true }))
    end
  end

  local area = entity.clickable_area
  local centre = area and rounded_tile({
    x = (area.topleft.x + area.botright.x) / 2,
    y = (area.topleft.y + area.botright.y) / 2,
    level = area.level,
  }) or step.assumed_start
  if centre then
    add_marker(self, InteractionMarker.new({ coordinate = grid(centre), cursor = action.cursor }))
  end
end

---@param self cluetrainer.PathStepEntity
---@param step Path.Step.Cheat
local function build_cheat(self, step)
  local start = step.assumed_start
  local colour = PathGraphics.rgba(TRANSPORT_COLOUR, 1)

  if start and not Path.isFar(step, nil, FAR_ARROW_THRESHOLD) then
    self:Add(PathGraphics.arrow(PathGraphics.offset_towards(start, step.target, 0.2), step.target,
      { colour = colour, weight = WEIGHT, dashed = true }))
  else
    self:Add(PathGraphics.circle(step.target, 0.1, colour, WEIGHT))
  end

  local marker_pos = start and rounded_tile({
    x = (start.x + step.target.x) / 2,
    y = (start.y + step.target.y) / 2,
    level = step.target.level,
  }) or step.target
  add_marker(self, ItemMarker.new(grid(marker_pos), ICON_OBJECTS["item/rotten-potato"]))
end

---@param self cluetrainer.PathStepEntity
---@param step Path.Step.Cosmetic
local function build_cosmetic(self, step)
  local obj = ICON_OBJECTS[step.icon]
  if obj then add_marker(self, ItemMarker.new(grid(step.position), obj)) end

  -- Without hover support on groups, hidden-until-hovered extras stay hidden.
  if step.hide_when_not_hovered then return end

  if step.area then
    self:Add(AreaGraphics.area(step.area, {
      colour = parse_colour(step.area_color, COSMETIC_AREA_COLOUR), weight = 1, opacity = 0.3, fillOpacity = 0.2,
    }))
  end

  if step.arrow then
    self:Add(PathGraphics.arrow(step.arrow[1], step.arrow[2], {
      colour = PathGraphics.rgba(parse_colour(step.arrow_color, COSMETIC_ARROW_COLOUR), 0.6), weight = WEIGHT,
    }))
  end
end

---@type table<string, fun(self: cluetrainer.PathStepEntity, step: Path.Step)>
local BUILDERS = {
  ability = build_ability,
  run = build_run,
  teleport = build_teleport,
  redclick = build_redclick,
  powerburst = build_powerburst,
  transport = build_transport,
  cheat = build_cheat,
  cosmetic = build_cosmetic,
}

---@param step Path.Step
---@return cluetrainer.PathStepEntity
function PathStepEntity.new(step)
  local self = setmetatable(elements.Element.new(), PathStepEntity)
  ---@cast self cluetrainer.PathStepEntity
  self.step = step

  -- Orientation steps have no graphics.
  local build = BUILDERS[step.type]
  if build then build(self, step) end

  return self
end

return PathStepEntity
