local api_util = require("zyklib/api_util")

---@type table<zyklib.TerrainHighlight, boolean>
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

---@param bounds Rect Bounds in map square coordinate.
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

  return self
end

---Create a bound rectangle from a set of sample coordinates. The rectangle will be the smallest rectangle that contains all samples.
---@param samples CoordGrid[]
---@return Rect
function TerrainHighlight.bounds_from_samples(samples)
  local min_x = math.huge
  local min_z = math.huge
  local max_x = -math.huge
  local max_z = -math.huge

  for _, sample in ipairs(samples) do
    log("sa")

    if sample.mapSquareX < min_x then min_x = sample.mapSquareX end
    if sample.mapSquareZ < min_z then min_z = sample.mapSquareZ end
    if sample.mapSquareX > max_x then max_x = sample.mapSquareX end
    if sample.mapSquareZ > max_z then max_z = sample.mapSquareZ end
  end

  log(min_x, min_z, max_x, max_z)

  local rec = Rect.new(min_x, min_z, max_x - min_x + 1, max_z - min_z + 1)

  log(api_util.to_plain_table(samples))
  log(api_util.to_plain_table(rec))

  return rec
end

---Activates this TerrainHighlight so that it will be drawn. If the bounds are not yet available, it will be drawn as soon as they are.
---@return zyklib.TerrainHighlight
function TerrainHighlight:activate()
  update(self)

  if not self.shape_created then
    pending_instances[self] = true
  end

  return self
end

---Deactivates this TerrainHighlight so that it will no longer be drawn. The existing shape instance will be destroyed and will be recreated if the highlight is activated again.
---@return self
function TerrainHighlight:deactivate()
  if self.instance then
    self.instance:Destroy()
    self.instance = nil
    self.shape_created = false
  end

  pending_instances[self] = nil

  return self
end

local listener = api_util.subscribe_managed(Event.ServerLogic, function(event)
  for instance, _ in pairs(pending_instances) do
    update(instance)

    if instance.shape_created then
      -- Remove completed instance to avoid unnecessary updates.
      pending_instances[instance] = nil
    end
  end
end)

return TerrainHighlight
