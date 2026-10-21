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

return util
