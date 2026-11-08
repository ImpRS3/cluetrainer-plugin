-- scan_display.lua
local scan_display           = {}

scan_display.PULSE_COLOURS   = { 0x0F91D3FF, 0xE1A53FFF, 0xD51918FF }
scan_display.DIFFERENT_LEVEL_COLOUR = 0x8ADC13FF
scan_display.WARNING_COLOUR  = 0xFF6A4DFF

---@param key PulseInformation
---@return integer RGBA
function scan_display.pulseColour(key)
  return key.different_level and scan_display.DIFFERENT_LEVEL_COLOUR or scan_display.PULSE_COLOURS[key.pulse]
end

return scan_display
