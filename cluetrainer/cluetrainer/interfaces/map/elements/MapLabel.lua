local StaticTwig = require("prettymap/luaflet/twigs/StaticTwig")
local common = require("prettymap/luaflet/twigs/prefab/controls_common")

-- Room between the panel's edge and the text, in pixels.
local PADDING = 4

--- A viewport-anchored panel with one line of text, such as a counter.
---@class ct.MapLabel : prettymap.StaticElement
---@field private content string
---@field private text ui.Text?
local MapLabel = setmetatable({}, { __index = StaticTwig })
MapLabel.__index = MapLabel

---@param options prettymap.StaticElementOptions
---@return ct.MapLabel
function MapLabel.new(options)
  local self = setmetatable(StaticTwig.new(options), MapLabel)
  ---@cast self ct.MapLabel
  self.content = ""
  return self
end

---@param content string
function MapLabel:setText(content)
  self.content = content
  if self.text then self.text.content = content end
end

---@param layer ui.Layer
---@return boolean added
function MapLabel:CreateComponent(layer)
  local container = common.panel(layer)
  self.text = common.label(container, 0, self.baseWidth - 2 * PADDING, self.baseHeight - 2 * PADDING)
  self:setText(self.content)
  return true
end

return MapLabel
