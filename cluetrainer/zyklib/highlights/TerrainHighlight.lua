local api_util = require("zyklib/api_util")

---@type zyklib.TerrainHighlight[]
local pending_instances = {}

---@param bounds Rect
---@return boolean
local function boundsAvailable(bounds)
  if bounds == nil then return false end

  local _, a = World.GetGroundHeight(0, bounds.x * 64 * 512 + 256, bounds.y * 64 * 512 + 256)
  local _, b = World.GetGroundHeight(0, ((bounds.x + bounds.width) * 64 - 1) * 512 + 256,
    ((bounds.y + bounds.height) * 64 - 1) * 512 + 256)

  return a and b
end

---@generic T
---@param self zyklib.TerrainHighlight
local function update(self)
  if not self.shape_created and boundsAvailable(self.bounds) then
    local shape = self.generator()
    self.instance:SetShapeData(shape)
    self.shape_created = true
  end
end

---@class zyklib.TerrainHighlight
---@field bounds Rect Bounds in map square coordinate.
---@field generator fun(): ShapeData
---@field instance ShapeInstance
---@field shape_created boolean

local TerrainHighlight = {}
TerrainHighlight.__index = TerrainHighlight

---@param bounds Rect
---@param generator fun(): ShapeData
---@return zyklib.TerrainHighlight
function TerrainHighlight.new(
    bounds,
    generator
)
  ---@type zyklib.TerrainHighlight
  local self = setmetatable({}, TerrainHighlight)
  self.bounds = bounds
  self.generator = generator
  self.instance = api_util.unique_shape_instance()
  self.shape_created = false

  update(self)

  if not self.shape_created then
    table.insert(pending_instances, self)
  end

  return self
end

local listener = api_util.subscribe_managed(Event.ServerLogic, function(event)
  for i = #pending_instances, 1, -1 do
    local value = pending_instances[i]
    update(value)

    if value then
      -- Remove completed instance to avoid unnecessary updates.
      table.remove(pending_instances, i)
    end
  end
end)

return TerrainHighlight
