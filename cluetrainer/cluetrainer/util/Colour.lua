-- Colour.lua
-- Colours as integers: RGB is 0xRRGGBB, RGBA is 0xRRGGBBAA.
local Colour = {}

---@param rgb integer
---@param opacity number From 0 to 1
---@return integer rgba
function Colour.rgba(rgb, opacity)
  return rgb * 256 + math.floor(opacity * 255 + 0.5)
end

--- The colour with another alpha.
---@param rgba integer
---@param alpha integer From 0 to 255
---@return integer rgba
function Colour.withAlpha(rgba, alpha)
  return (rgba & 0xFFFFFF00) | alpha
end

return Colour
