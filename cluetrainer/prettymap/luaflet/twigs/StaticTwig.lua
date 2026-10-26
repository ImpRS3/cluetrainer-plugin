local Twig = require("prettymap/luaflet/twigs/Twig")

--- Fractions of the free viewport space (horizontal, vertical) per anchor.
---@type table<string, {[1]: number, [2]: number}>
local ANCHORS = {
    topleft = { 0, 0 }, top = { 0.5, 0 }, topright = { 1, 0 },
    left = { 0, 0.5 }, center = { 0.5, 0.5 }, right = { 1, 0.5 },
    bottomleft = { 0, 1 }, bottom = { 0.5, 1 }, bottomright = { 1, 1 },
}

---@alias prettymap.Anchor
---| "topleft"
---| "top"
---| "topright"
---| "left"
---| "center"
---| "right"
---| "bottomleft"
---| "bottom"
---| "bottomright"

---@class prettymap.StaticElementOptions
---@field anchor prettymap.Anchor Edge or corner of the viewport the element is attached to.
---@field offsetX number? Pixels away from the anchored edge (towards the centre); shifts right for centred anchors.
---@field offsetY number? Pixels away from the anchored edge (towards the centre); shifts down for centred anchors.
---@field width number? Width in pixels.
---@field height number? Height in pixels.
---@field size number? Shorthand for width and height.

--- An element fixed to the viewport (a UI control) that does not move with the map. It is placed
--- relative to an edge or corner of the viewport and is always drawn above map elements, outside of
--- the z-layers. Use this for UI elements that can be grouped with the rest of the twig system.
---@class prettymap.StaticElement : prettymap.luaflet.Twig
---@field anchor prettymap.Anchor
---@field offsetX number
---@field offsetY number
local StaticTwig = setmetatable({}, { __index = Twig })
StaticTwig.__index = StaticTwig

---@param options prettymap.StaticElementOptions
---@return prettymap.StaticElement
function StaticTwig.new(options)
    assert(ANCHORS[options.anchor], "unknown anchor: " .. tostring(options.anchor))
    local self = setmetatable(Twig.new({
        width = options.width,
        height = options.height,
        size = options.size,
        zoomScale = false,
    }), StaticTwig)
    ---@cast self prettymap.StaticElement
    self.static = true
    self.anchor = options.anchor
    self.offsetX = options.offsetX or 0
    self.offsetY = options.offsetY or 0
    return self
end

---@param anchor prettymap.Anchor
---@param offsetX number?
---@param offsetY number?
---@return nil
function StaticTwig:SetAnchor(anchor, offsetX, offsetY)
    assert(ANCHORS[anchor], "unknown anchor: " .. tostring(anchor))
    self.anchor = anchor
    self.offsetX = offsetX or 0
    self.offsetY = offsetY or 0
    if self.manager then self.manager:_Position(self) end
end

---@param map prettymap.MapView
function StaticTwig:_Layout(map)
    self.component:SetSize(self.width, self.height)
    self:_Place()
end

--- Static elements only depend on the viewport, so the coordinates given by the base class are ignored.
function StaticTwig:_ApplyPosition()
    self:_Place()
end

---@return nil
function StaticTwig:_Place()
    local component = self.component
    local map = self.manager.map
    local fraction = ANCHORS[self.anchor]
    local x = math.floor(fraction[1] * (map.viewportWidth - self.width) + 0.5)
    local y = math.floor(fraction[2] * (map.viewportHeight - self.height) + 0.5)
    x = x + (fraction[1] == 1 and -self.offsetX or self.offsetX)
    y = y + (fraction[2] == 1 and -self.offsetY or self.offsetY)
    self.screenX, self.screenY = x, y
    component.hidden = false
    component:SetPos(x, y)
end

---@param plane integer
function StaticTwig:_OnPlaneChanged(plane)
end

return StaticTwig
