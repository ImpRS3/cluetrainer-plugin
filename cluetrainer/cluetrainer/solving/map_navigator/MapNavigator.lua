local luaflet = require("prettymap/luaflet")
local Bounds = require("cluetrainer/util/Bounds")
local Path = require("cluetrainer/model/shared/path")
local PathStepEntity = require("cluetrainer/solving/map_navigator/PathStepEntity")
local SectionControl = require("cluetrainer/solving/map_navigator/SectionControl")

---@param bounds ct.Bounds
---@param step Path.Step
local function extend_bounds(bounds, step)
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

---@class ct.MapNavigator
---@field map ct.GameMap
---@field sections {name: string, steps: Path.Step[]}[]
---@field twig prettymap.luaflet.Twig Group element holding one entity per step.
---@field section_control ct.SectionControl?
local MapNavigator = {}
MapNavigator.__index = MapNavigator


---@param map ct.GameMap
---@param sections {name: string, steps: Path.Step[]}[]
---@return ct.MapNavigator
function MapNavigator.new(map, sections)
  ---@class ct.MapNavigator
  local self = setmetatable({}, MapNavigator)
  self.map = map
  self.sections = sections

  self.twig = luaflet.twigs.Twig.new()
      :AddTo(map.map.twigs)

  for _, section in ipairs(sections) do
    for _, step in ipairs(section.steps) do
      self.twig:Add(PathStepEntity.new(step))
    end
  end

  self.section_control = SectionControl.new({
    names = zyklib.array.map(sections, function(section) return section.name end)
  }):AddTo(self.twig)

  self.section_control.section_changed:subscribe(function(index) self:fitSection(index) end)

  self:fitSection(#self.sections)

  return self
end

--- @param index integer The index of the section to fit. Defaults to the last section.
function MapNavigator:fitSection(index)
  local section = self.sections[index]
  if not section then return end

  local bounds = Bounds.new()
  for _, step in ipairs(section.steps) do extend_bounds(bounds, step) end
  self.map:fitBounds(bounds)
end

--- Removes the path from the map.
function MapNavigator:dispose()
  self.twig:Detach()
end

return MapNavigator
