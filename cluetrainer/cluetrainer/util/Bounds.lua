---@class ct.Bounds
---@field private min ct.lib.math.Vector2?
---@field private max ct.lib.math.Vector2?
---@field private level integer?
---@field private distance_limit { center: ct.lib.math.Vector2, limit: number }?
---@field private fixed_center boolean
---@field private level_fixed boolean
local Bounds = {}
Bounds.__index = Bounds

---@return ct.Bounds
function Bounds.new()
  local self = setmetatable({}, Bounds)

  self.min = nil
  self.max = nil
  self.level = nil
  self.distance_limit = nil
  self.fixed_center = false
  self.level_fixed = false

  return self
end

---@private
---@return ct.lib.math.Vector2
function Bounds:center()
  return { x = (self.min.x + self.max.x) / 2, y = (self.min.y + self.max.y) / 2 }
end

---@private
---@param p ct.lib.math.Vector2
function Bounds:extend_to(p)
  self.min = { x = math.min(self.min.x, p.x), y = math.min(self.min.y, p.y) }
  self.max = { x = math.max(self.max.x, p.x), y = math.max(self.max.y, p.y) }
end

---@param limit number?
---@return ct.Bounds
function Bounds:setDistanceLimit(limit)
  if limit ~= nil and self.min ~= nil then
    self.distance_limit = { limit = limit, center = self:center() }
  else
    self.distance_limit = nil
  end

  return self
end

---@param v boolean?
---@return ct.Bounds
function Bounds:fixCenter(v)
  self.fixed_center = v ~= false
  return self
end

---@param v boolean?
---@return ct.Bounds
function Bounds:fixLevel(v)
  self.level_fixed = v ~= false
  return self
end

---@param ... (TileCoordinates | ct.lib.math.Vector2)?
function Bounds:addTile(...)
  for i = 1, select("#", ...) do
    local tile = select(i, ...)

    if tile ~= nil then
      local skip = false

      if self.distance_limit ~= nil then
        local dx = self.distance_limit.center.x - tile.x
        local dy = self.distance_limit.center.y - tile.y
        skip = dx * dx + dy * dy > self.distance_limit.limit * self.distance_limit.limit
      end

      if not skip then
        if self.min == nil then
          self.min = { x = tile.x, y = tile.y }
          self.max = { x = tile.x, y = tile.y }
        else
          if self.fixed_center then
            local c = self:center()
            self:extend_to({ x = 2 * c.x - tile.x, y = 2 * c.y - tile.y })
          end

          self:extend_to(tile)
        end

        local level = tile.level
        if level ~= nil and not self.level_fixed then
          if self.level == nil then
            self.level = level
          else
            self.level = math.min(self.level, level)
          end
        end
      end
    end
  end
end

---Accepts a rectangle with topleft/botright corners, optionally with a level.
---@param rect { topleft: ct.lib.math.Vector2, botright: ct.lib.math.Vector2, level: integer? }?
function Bounds:addRectangle(rect)
  if rect == nil then return end

  local tl, br = rect.topleft, rect.botright

  if rect.level ~= nil then
    tl = { x = tl.x, y = tl.y, level = rect.level }
    br = { x = br.x, y = br.y, level = rect.level }
  end

  self:addTile(tl)
  self:addTile(br)
end

---@param area TileArea?
function Bounds:addArea(area)
  if area == nil then return end

  local origin = area.origin
  local size = area.size or { x = 1, y = 1 }

  self:addRectangle({
    topleft = { x = origin.x, y = origin.y + size.y - 1 },
    botright = { x = origin.x + size.x - 1, y = origin.y },
    level = origin.level,
  })
end

---@return ct.Bounds
function Bounds:copy()
  local copy = setmetatable({}, Bounds)
  copy.min = self.min and { x = self.min.x, y = self.min.y }
  copy.max = self.max and { x = self.max.x, y = self.max.y }
  copy.level = self.level
  copy.distance_limit = self.distance_limit
  copy.fixed_center = self.fixed_center
  copy.level_fixed = self.level_fixed
  return copy
end

---@class ct.BoundsExtension
---@field north number?
---@field east number?
---@field south number?
---@field west number?

--- Extends the bounds in each direction by a fraction of their current size (height for north/south,
--- width for east/west). Does nothing for empty bounds.
---@param amount number | ct.BoundsExtension A single fraction for all directions, or one per direction (missing means 0).
---@return ct.Bounds self
function Bounds:extend(amount)
  if self.min == nil then return self end

  if type(amount) == "number" then
    amount = { north = amount, east = amount, south = amount, west = amount }
  end

  local width = self.max.x - self.min.x + 1
  local height = self.max.y - self.min.y + 1

  self.max.y = self.max.y + height * (amount.north or 0)
  self.min.y = self.min.y - height * (amount.south or 0)
  self.max.x = self.max.x + width * (amount.east or 0)
  self.min.x = self.min.x - width * (amount.west or 0)
  return self
end

--- Grows the bounds around their centre to at least `size` tiles in both directions, so fitting them doesn't zoom in
--- all the way. Does nothing for empty bounds.
---@param size number
---@return ct.Bounds self
function Bounds:ensureSize(size)
  if self.min == nil then return self end

  local c = self:center()
  self:extend_to({ x = c.x - size / 2, y = c.y - size / 2 })
  self:extend_to({ x = c.x + size / 2, y = c.y + size / 2 })
  return self
end

---@return { topleft: ct.lib.math.Vector2, botright: ct.lib.math.Vector2, level: integer }?
function Bounds:get()
  if self.min == nil then return nil end

  return {
    topleft = { x = self.min.x, y = self.max.y },
    botright = { x = self.max.x, y = self.min.y },
    level = self.level or 0,
  }
end

return Bounds
