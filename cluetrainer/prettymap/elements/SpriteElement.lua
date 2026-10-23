local Element = require("prettymap/elements/Element")

---@class prettymap.SpriteElementOptions : prettymap.ElementOptions
---@field spriteID integer?
---@field sprite any?
---@field colour integer? RGBA tint.

---@class prettymap.SpriteElement : prettymap.Element
---@field spriteID integer?
---@field sprite any?
---@field colour integer?
local SpriteElement = setmetatable({}, { __index = Element })
SpriteElement.__index = SpriteElement

---@param options prettymap.SpriteElementOptions
---@return prettymap.SpriteElement
function SpriteElement.new(options)
    local self = setmetatable(Element.new(options), SpriteElement)
    ---@cast self prettymap.SpriteElement
    self.spriteID = options.spriteID
    self.sprite = options.sprite
    self.colour = options.colour
    return self
end

---@param layer ui.Layer
---@return boolean added
function SpriteElement:CreateComponent(layer)
    local sprite = ui.Sprite.new(layer)
    sprite:SetSize(0, 0, 1.0, 1.0)
    if self.spriteID then sprite.spriteID = self.spriteID end
    if self.sprite then sprite.sprite = self.sprite end
    if self.colour then sprite.rgba = self.colour end
    sprite.clickthrough = true
    return true
end

return SpriteElement
