local StaticTwig = require("prettymap/luaflet/twigs/StaticTwig")
local common = require("prettymap/luaflet/twigs/prefab/controls_common")

---@class prettymap.luaflet.FloorControlTwig : prettymap.StaticElement
---@field text ui.Text?
---@field down prettymap.luaflet.ControlButton?
---@field up prettymap.luaflet.ControlButton?
local FloorControlTwig = setmetatable({}, { __index = StaticTwig })
FloorControlTwig.__index = FloorControlTwig

--- A viewport-anchored panel with buttons to move one floor down or up and the current floor.
---@param options {anchor: prettymap.Anchor?, offsetX: number?, offsetY: number?}?
---@return prettymap.luaflet.FloorControlTwig
function FloorControlTwig.new(options)
    options = options or {}
    local self = setmetatable(StaticTwig.new({
        anchor = options.anchor or "topright",
        offsetX = options.offsetX or 4,
        offsetY = options.offsetY or 4,
        width = 80,
        height = 32,
    }), FloorControlTwig)
    ---@cast self prettymap.luaflet.FloorControlTwig
    return self
end

---@return prettymap.MapView
function FloorControlTwig:_Map()
    return self.manager.map
end

---@param layer ui.Layer
---@return boolean added
function FloorControlTwig:CreateComponent(layer)
    local container = common.panel(layer)
    self.down = common.button(container, common.SPRITES.floorDown, function()
        local map = self:_Map()
        map:SetPlane(map:GetPlane() - 1)
    end, 0, 24)
    self.text = common.label(container, 24, 24, 24)
    self.up = common.button(container, common.SPRITES.floorUp, function()
        local map = self:_Map()
        map:SetPlane(map:GetPlane() + 1)
    end, 48, 24)
    return true
end

---@param plane integer
function FloorControlTwig:_OnPlaneChanged(plane)
    self.text.content = tostring(plane)
    self.down:SetDisabled(plane <= 0)
    self.up:SetDisabled(plane >= 3)
end

return FloorControlTwig
