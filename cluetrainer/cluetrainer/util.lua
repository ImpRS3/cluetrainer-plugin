-- util.lua

-- This file includes various general purpose utilities that have not made it into zyklib (yet).
-- Think of it as a staging area for utilities that might eventually be mature to zyklib.

---@class cluetrainer.util
local util = {}

--- @param canvas any
--- @param ref_comp ui.Component
--- @param font FontId
--- @param colour number
--- @param shadowColour number
--- @param text string
function util.overlayCenteredText(canvas, ref_comp, text, font, colour, shadowColour)
  local text_config = ui.TextDataConfig.new()

  font = font or id.Font.NOTOSANS_28
  colour = colour or 0xFFFFFFFF
  shadowColour = shadowColour or 0x00000080

  text_config.alignHorizontal = ui.AlignMode.CENTRE
  text_config.alignVertical = ui.AlignMode.CENTRE
  text_config.font = font
  text_config.rgba = colour
  text_config.shadowRGBA = shadowColour
  text_config.isShadowed = true

  canvas:AddText(ref_comp.x - 25, ref_comp.y - 25, ref_comp.width + 50, ref_comp.height + 50, text, text_config)
end

---A fixed-capacity buffer that overwrites its oldest element once full.
---@class cluetrainer.util.RingBuffer<T>
---@field [integer] T Element slots, stored at indices `1..capacity` in insertion-ring order
---@field private capacity integer
---@field private next_index integer
---@field private count integer
local RingBuffer = {}
RingBuffer.__index = RingBuffer

---@generic T
---@param capacity integer Maximum number of elements to retain
---@return cluetrainer.util.RingBuffer<T>
function RingBuffer.new(capacity)
  return setmetatable({ capacity = capacity, next_index = 1, count = 0 }, RingBuffer)
end

---Adds an element, overwriting the oldest one if the buffer is full.
---@generic T
---@param self cluetrainer.util.RingBuffer<T>
---@param value T
function RingBuffer:push(value)
  self[self.next_index] = value
  self.next_index = self.next_index % self.capacity + 1
  self.count = math.min(self.count + 1, self.capacity)
end

---Removes all elements.
function RingBuffer:clear()
  for i = 1, self.capacity do
    self[i] = nil
  end

  self.next_index = 1
  self.count = 0
end

util.RingBuffer = RingBuffer

---@generic T
---@param f fun():T
---@return fun():T
function util.lazy(f)
  local evaluated = false
  local result
  return function()
    if not evaluated then
      result = f()
      evaluated = true
    end
    return result
  end
end

return util
