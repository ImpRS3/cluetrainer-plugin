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

---Computes the Levenshtein distance between two strings.
---@param str1 string
---@param str2 string
---@param case_sensitive? boolean Defaults to true
---@return integer
function util.levenshtein(str1, str2, case_sensitive)
  if case_sensitive == false then
    str1 = str1:lower()
    str2 = str2:lower()
  end

  if str1 == str2 then return 0 end

  local len1, len2 = #str1, #str2

  if len1 == 0 then return len2 end
  if len2 == 0 then return len1 end

  -- Minimize memory usage
  if len1 > len2 then
    str1, str2 = str2, str1
    len1, len2 = len2, len1
  end

  local previous, current = {}, {}

  for i = 0, len1 do
    previous[i] = i
  end

  for j = 1, len2 do
    current[0] = j
    local byte2 = str2:byte(j)

    for i = 1, len1 do
      local cost = str1:byte(i) == byte2 and 0 or 1

      current[i] = math.min(
        previous[i] + 1,       -- deletion
        current[i - 1] + 1,    -- insertion
        previous[i - 1] + cost -- substitution
      )
    end

    previous, current = current, previous
  end

  return previous[len1]
end

---Computes normalized string similarity between 0 and 1.
---@param str string
---@param reference string
---@param case_sensitive? boolean Defaults to false
---@return number
function util.stringSimilarity(str, reference, case_sensitive)
  local maxLength = math.max(#str, #reference)

  if maxLength == 0 then return 1 end

  return 1 - util.levenshtein(
    str,
    reference,
    case_sensitive == true
  ) / maxLength
end

return util
