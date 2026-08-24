local HighlightParams = require "zyklib/highlights/HighlightParams"

---@class zyklib.Geometry
---@field shapeData ShapeData
---@field lineWidth number
---@field isBillboard boolean

---@class zyklib.Highlight
---@field parent zyklib.HighlightGroup?
---@field self_params zyklib.HighlightParams
---@field actual_params zyklib.HighlightParams
---@field activate fun(self: zyklib.Highlight): self
---@field deactivate fun(self: zyklib.Highlight): self
---@field set fun(self: zyklib.Highlight, param: zyklib.HighlightParams): self
local Highlight = {}
Highlight.__index = Highlight

function Highlight:init()
  self.self_params = HighlightParams.default()
  self.actual_params = HighlightParams.default()
end

function Highlight:propagate_param_change()
  self.actual_params = HighlightParams.blend(self.parent.actual_params, self.self_params)
end

function Highlight:hide()
  self.self_params.visible = false
  self:propagate_param_change()
end

function Highlight:show()
  self.self_params.visible = true
  self:propagate_param_change()
end



return Highlight