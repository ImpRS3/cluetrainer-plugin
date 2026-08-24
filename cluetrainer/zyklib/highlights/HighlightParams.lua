local api_util = require "zyklib/api_util"

---@class zyklib.HighlightParams
---@field colour ColourRGBA?
---@field translation Vector3?
---@field ignoreDepth boolean?
---@field visible boolean?

local HighlightParams = {}

---@param parentColor integer
---@param childColor integer
---@return ColourRGBA
local function blendColors(parentColor, childColor)
  local r1, g1, b1, a1 = api_util.color_to_rgba(parentColor)
  local r2, g2, b2, a2 = api_util.color_to_rgba(childColor)

  return api_util.color_rgba(
    math.floor(r1 * r2 / 255),
    math.floor(g1 * g2 / 255),
    math.floor(b1 * b2 / 255),
    math.floor(a1 * a2 / 255)
  )
end

---comment
---@param parent zyklib.HighlightParams
---@param child zyklib.HighlightParams
---@return zyklib.HighlightParams
function HighlightParams.merge(parent, child)
  return {
    colour = blendColors(parent.colour, child.colour),
    translation = parent.translation + child.translation,
    ignoreDepth = parent.ignoreDepth ~= nil and parent.ignoreDepth or child.ignoreDepth,
    visible = parent.visible ~= nil and parent.visible or child.visible,
  }
end

---@return zyklib.HighlightParams
function HighlightParams.default()
  return {
    colour = 0xFFFFFFFF,
    translation = Vector3.new(0, 0, 0),
    ignoreDepth = nil,
    visible = nil,
  }
end

---@param params zyklib.HighlightParams
---@param shape_instance ShapeInstance
function HighlightParams.apply_to_shape_instance(params, shape_instance)
  if params.translation ~= nil then
    shape_instance.translation = params.translation
  end
  if params.colour ~= nil then
    shape_instance.colour = params.colour
  end
  if params.ignoreDepth ~= nil then
    shape_instance.ignoreDepth = params.ignoreDepth
  end
  if params.visible ~= nil then
    shape_instance.visible = params.visible
  end
end

---@param params zyklib.HighlightParams
---@param draw_call ShapeListDrawSettings
function HighlightParams.apply_to_draw_call(params, draw_call)
  if params.translation ~= nil then
    draw_call.translation = params.translation + draw_call.translation
  end
  if params.colour ~= nil then
    draw_call.colour = blendColors(params.colour, draw_call.colour)
  end
  if params.ignoreDepth ~= nil then
    draw_call.ignoreDepth = params.ignoreDepth ~= nil and params.ignoreDepth or draw_call.ignoreDepth
  end
end

return HighlightParams
