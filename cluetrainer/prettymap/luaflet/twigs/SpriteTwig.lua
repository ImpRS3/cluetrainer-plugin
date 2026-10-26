local twig = require("prettymap/luaflet/twigs/Twig")

---@class prettymap.luaflet.SpriteTwigOptions : prettymap.luaflet.TwigOptions
---@field spriteID integer?
---@field sprite any?
---@field colour integer? RGBA tint.

---@class prettymap.luaflet.SpriteTwig : prettymap.luaflet.Twig
---@field spriteID integer?
---@field sprite any?
---@field colour integer?
local SpriteTwig = setmetatable({}, { __index = twig })
SpriteTwig.__index = SpriteTwig

---@param options prettymap.luaflet.SpriteTwigOptions
---@return prettymap.luaflet.SpriteTwig
function SpriteTwig.new(options)
    options.zLayer = options.zLayer or "marker"
    local self = setmetatable(twig.new(options), SpriteTwig)
    ---@cast self prettymap.luaflet.SpriteTwig
    self.spriteID = options.spriteID
    self.sprite = options.sprite
    self.colour = options.colour
    return self
end

---@param layer ui.Layer
---@return boolean added
function SpriteTwig:CreateComponent(layer)
    local sprite = ui.Sprite.new(layer)
    sprite:SetSize(0, 0, 1.0, 1.0)
    if self.spriteID then sprite.spriteID = self.spriteID end
    if self.sprite then sprite.sprite = self.sprite end
    if self.colour then sprite.rgba = self.colour end
    sprite.clickthrough = true
    return true
end

return SpriteTwig
