local StaticTwig = require("prettymap/luaflet/twigs/StaticTwig")
local common = require("prettymap/luaflet/twigs/prefab/controls_common")

---@class prettymap.luaflet.ZoomControlTwig : prettymap.StaticElement
---@field text ui.Text?
---@field out prettymap.luaflet.ControlButton?
---@field inside prettymap.luaflet.ControlButton?
local ZoomControlTwig = setmetatable({}, { __index = StaticTwig })
ZoomControlTwig.__index = ZoomControlTwig

--- A viewport-anchored panel with zoom out/in buttons and the current zoom step.
---@param options {anchor: prettymap.Anchor?, offsetX: number?, offsetY: number?}?
---@return prettymap.luaflet.ZoomControlTwig
function ZoomControlTwig.new(options)
    options = options or {}
    local self = setmetatable(StaticTwig.new({
        anchor = options.anchor or "topright",
        offsetX = options.offsetX or 4,
        offsetY = options.offsetY or 4,
        width = 80,
        height = 31,
    }), ZoomControlTwig)
    ---@cast self prettymap.luaflet.ZoomControlTwig
    return self
end

---@param layer ui.Layer
---@return boolean added
function ZoomControlTwig:CreateComponent(layer)
    local container = common.panel(layer)
    self.out = common.button(container, common.SPRITES.zoomOut, function()
        self.manager.map:ZoomOut()
    end, 0, 23)
    self.text = common.label(container, 23, 26, 23)
    self.inside = common.button(container, common.SPRITES.zoomIn, function()
        self.manager.map:ZoomIn()
    end, 49, 23)
    return true
end

--- Layout runs on every zoom change, which keeps the zoom display current.
---@param map prettymap.MapView
function ZoomControlTwig:_Layout(map)
    StaticTwig._Layout(self, map)
    local index, minimum, maximum = map:GetZoom()
    self.text.content = tostring(index - minimum + 1)
    self.out:SetDisabled(index <= minimum)
    self.inside:SetDisabled(index >= maximum)
end

return ZoomControlTwig
