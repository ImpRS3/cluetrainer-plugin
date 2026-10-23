local Element = require("prettymap/elements/Element")

--- General purpose element for custom components. Subclasses override CreateComponent.
---@class prettymap.ComponentElement : prettymap.Element
local ComponentElement = setmetatable({}, { __index = Element })
ComponentElement.__index = ComponentElement

---@param options prettymap.ElementOptions
---@return prettymap.ComponentElement
function ComponentElement.new(options)
    ---@class prettymap.ComponentElement
    local self = setmetatable(Element.new(options), ComponentElement)
    return self
end

---@param layer ui.Layer
---@return boolean? added
function ComponentElement:CreateComponent(layer)
    error("ComponentElement:CreateComponent must be overridden")
end

return ComponentElement
