local Twig = require("prettymap/luaflet/twigs/Twig")

local INTERVALS = {
    { minScale = 2 ^ -3, interval = 64 },
    { minScale = 2 ^ 0.5, interval = 8 },
    { minScale = 2, interval = 4 },
    { minScale = 4, interval = 1 },
}
local LINE_COLOUR = 0x11111140
local LINE_INSET = 1

--- A tile-boundary grid with intervals selected by map zoom.
--- Custom map z-layers must define "grid" below "overlay".
---@class prettymap.luaflet.GridTwig : prettymap.luaflet.Twig
---@field canvas ui.Canvas?
local GridTwig = setmetatable({}, { __index = Twig })
GridTwig.__index = GridTwig

---@return prettymap.luaflet.GridTwig
function GridTwig.new()
    local self = setmetatable(Twig.new({ zoomScale = false, zLayer = "grid" }), GridTwig)
    ---@cast self prettymap.luaflet.GridTwig
    self.clipsToView = true
    return self
end

---@param layer ui.Layer
---@return boolean
function GridTwig:CreateComponent(layer)
    local canvas = ui.Canvas.new(layer)
    canvas:SetSize(0, 0, 1.0, 1.0)
    canvas.clickthrough = true
    self.canvas = canvas
    return true
end

---@param map prettymap.MapView
function GridTwig:_Layout(map)
    local component = assert(self.component, "grid component is not attached")
    local canvas = assert(self.canvas, "grid canvas is not attached")
    canvas:Clear()

    local world = map.map
    local scrollX, scrollY = map.viewport.scrollX or 0, map.viewport.scrollY or 0
    local left = math.max(scrollX, map.mapOffsetX)
    local top = math.max(scrollY, map.mapOffsetY)
    local right = math.min(scrollX + map.viewportWidth, map.mapOffsetX + map.mapWidth)
    local bottom = math.min(scrollY + map.viewportHeight, map.mapOffsetY + map.mapHeight)
    local width, height = right - left, bottom - top

    if width <= 2 * LINE_INSET or height <= 2 * LINE_INSET then
        component.hidden = true
        return
    end

    local spacing
    for _, step in ipairs(INTERVALS) do
        if map.currentScale < step.minScale then break end
        spacing = step.interval
    end
    if not spacing then
        component.hidden = true
        return
    end

    component.hidden = false
    component:SetPos(left, top)
    component:SetSize(width, height)
    self.width, self.height = width, height

    local scaleX, scaleY = map.mapWidth / world.width, map.mapHeight / world.height
    -- World coordinates here refer to tile edges; luaflet's integer coordinates are tile centres.
    local minX = world.minX + (left - map.mapOffsetX) / scaleX
    local maxX = world.minX + (right - map.mapOffsetX) / scaleX
    local minY = world.maxZ - (bottom - map.mapOffsetY) / scaleY
    local maxY = world.maxZ - (top - map.mapOffsetY) / scaleY
    local function round(value) return math.floor(value + 0.5) end

    for x = math.ceil(minX / spacing) * spacing, maxX, spacing do
        local pixel = round(map.mapOffsetX + (x - world.minX) * scaleX - left)
        if pixel >= LINE_INSET and pixel <= width - LINE_INSET then
            canvas:AddLine(pixel, LINE_INSET, pixel, height - LINE_INSET, 1, LINE_COLOUR)
        end
    end
    for y = math.ceil(minY / spacing) * spacing, maxY, spacing do
        local pixel = round(map.mapOffsetY + (world.maxZ - y) * scaleY - top)
        if pixel >= LINE_INSET and pixel <= height - LINE_INSET then
            canvas:AddLine(LINE_INSET, pixel, width - LINE_INSET, pixel, 1, LINE_COLOUR)
        end
    end
end

return GridTwig
