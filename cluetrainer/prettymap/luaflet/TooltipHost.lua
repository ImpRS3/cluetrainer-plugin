local PADDING = 6
local GAP = 2
local BACKGROUND_RGBA = 0x000000E6
local BORDER_RGBA = 0x6E6450FF

---@class prettymap.TooltipEntry
---@field layer ui.Layer
---@field width integer
---@field height integer

--- Shows the tooltip of the hovered element in one shared frame that lives outside the map, so
--- it is drawn above everything and may extend past the map. Tooltip content is built on every
--- show and destroyed again when the tooltip disappears.
---@class prettymap.TooltipHost
---@field parent ui.Component Top-level component the frame lives in; defines the placement bounds.
---@field mapLayer ui.Layer Scrolling viewport; the origin of the element's screen coordinates.
---@field root ui.Layer
---@field region ui.Layer Invisible hover area covering element, gap and tooltip while interactive.
---@field content prettymap.TooltipEntry? Content of the currently shown tooltip.
---@field current prettymap.luaflet.Twig?
---@field holding boolean True while an interactive tooltip keeps its element hovered.
---@field inside {region: boolean, frame: boolean}
---@field onRelease fun()
local TooltipHost = {}
TooltipHost.__index = TooltipHost

---@param parent ui.Component
---@param mapLayer ui.Layer
---@param onRelease fun() Called when the cursor has left an interactive tooltip and its region.
---@return prettymap.TooltipHost
function TooltipHost.new(parent, mapLayer, onRelease)
    ---@class prettymap.TooltipHost
    local self = setmetatable({
        parent = parent,
        mapLayer = mapLayer,
        holding = false,
        inside = { region = false, frame = false },
        onRelease = onRelease,
    }, TooltipHost)

    -- Created before the frame so the frame is always drawn above the region.
    self.region = ui.Layer.new(parent)
    self.region.clickthrough = false
    self.region.hidden = true

    self.root = ui.Layer.new(parent)
    self.root.hidden = true
    local background = ui.Rectangle.new(self.root)
    background:SetSize(0, 0, 1.0, 1.0)
    background.fill = true
    background.rgba = BACKGROUND_RGBA
    background.clickthrough = true
    local border = ui.Rectangle.new(self.root)
    border:SetSize(0, 0, 1.0, 1.0)
    border.fill = false
    border.rgba = BORDER_RGBA
    border.clickthrough = true

    self:_Track(self.region, "region")
    self:_Track(self.root, "frame")
    return self
end

---@param component ui.Component
---@param key "region"|"frame"
function TooltipHost:_Track(component, key)
    component:Subscribe(ui.Hook.ONMOUSEOVER, function()
        self.inside[key] = true
        return true
    end)
    component:Subscribe(ui.Hook.ONMOUSELEAVE, function()
        self.inside[key] = false
        if self.holding and not self.inside.region and not self.inside.frame then
            self.onRelease()
        end
        return true
    end)
end

--- Builds the content of `element`'s tooltip into a fresh layer.
---@param element prettymap.luaflet.Twig
---@return prettymap.TooltipEntry?
function TooltipHost:_Build(element)
    local config = element.tooltip
    local layer = ui.Layer.new(self.root)
    layer:SetPos(PADDING, PADDING)
    layer.clickthrough = not config.interactive
    if not config:Build(layer, element) then
        layer:Destroy()
        return nil
    end
    assert(layer.width > 0 and layer.height > 0,
        "tooltip builders must size the layer they are given")
    return { layer = layer, width = layer.width, height = layer.height }
end

---@param value number
---@param minimum number
---@param maximum number
local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

--- Shows `element`'s tooltip above it (below if there is no room), anchored to its current rect.
---@param element prettymap.luaflet.Twig
---@return nil
function TooltipHost:Show(element)
    if not element.tooltip or not element.screenX then return end
    self:Hide()
    local entry = self:_Build(element)
    if not entry then return end

    self.content = entry
    self.current = element
    local width, height = entry.width + PADDING * 2, entry.height + PADDING * 2
    self.root:SetSize(width, height)

    -- Element rect in the parent's coordinates. `mapLayer` is the scrolling viewport; element
    -- coordinates are in its scrolled content space, so the scroll offset is subtracted.
    local origin, parentOrigin = self.mapLayer.xyGlobal, self.parent.xyGlobal
    local viewX = origin.x - parentOrigin.x + element.screenX - (self.mapLayer.scrollX or 0)
    local viewY = origin.y - parentOrigin.y + element.screenY - (self.mapLayer.scrollY or 0)
    local left = viewX - math.floor(element.width / 2)
    local top = viewY - math.floor(element.height / 2)

    local x = left + math.floor((element.width - width) / 2)
    local y = top - height - GAP
    if y < 0 then y = top + element.height + GAP end
    x = clamp(x, 0, math.max(0, self.parent.width - width))
    y = clamp(y, 0, math.max(0, self.parent.height - height))

    self.root:SetPos(x, y)
    self.root.hidden = false
    self.root.clickthrough = not element.tooltip.interactive

    if element.tooltip.interactive then
        -- One rectangle around element, gap and tooltip, so moving between them never leaves it.
        local minX, minY = math.min(left, x), math.min(top, y)
        local maxX = math.max(left + element.width, x + width)
        local maxY = math.max(top + element.height, y + height)
        self.region:SetPos(minX, minY)
        self.region:SetSize(maxX - minX, maxY - minY)
        self.region.hidden = false
        self.region:MoveToFront()
        self.inside.region, self.inside.frame = true, false -- the cursor is on the element
        self.holding = true
    end
    self.root:MoveToFront()
    -- Re-raised explicitly: the frame's own rectangles must never end up above the content.
    entry.layer:MoveToFront()
end

--- Hides the tooltip and destroys its content.
---@return nil
function TooltipHost:Hide()
    if self.content then self.content.layer:Destroy() end
    self.content = nil
    self.current = nil
    self.holding = false
    self.inside.region, self.inside.frame = false, false
    self.root.hidden = true
    self.region.hidden = true
end

--- Hides the tooltip if it belongs to `element`.
---@param element prettymap.luaflet.Twig
---@return nil
function TooltipHost:Forget(element)
    if self.current == element then self:Hide() end
end

---@return nil
function TooltipHost:Destroy()
    self.current = nil
    self.content = nil
    self.holding = false
    self.root:Destroy()
    self.region:Destroy()
end

return TooltipHost
