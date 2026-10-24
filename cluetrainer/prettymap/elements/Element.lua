---@class prettymap.ElementOptions
---@field coordinate CoordGrid? Tile the element is centred on. Elements without one have no position.
---@field width number? Width in map tiles (pixels if `zoomScale` is false).
---@field height number? Height in map tiles (pixels if `zoomScale` is false).
---@field size number? Shorthand for width and height.
---@field hoverScale number? Size multiplier applied while hovered. Default 1.
---@field hoverSize number? Fixed pixel size (width and height) while hovered; overrides `hoverScale`.
---@field zoomScale (false|fun(mapScale: number, map: prettymap.MapView): number)? Size factor from map zoom. Default is tile-proportional; false keeps a fixed pixel size.
---@field zLayer (string|prettymap.PaneID)? Named z-layer or pane id of the map. The map's topmost pane if nil.

---@class prettymap.Element
---@field zLayer (string|prettymap.PaneID)?
---@field coordinate CoordGrid?
---@field width integer Current size in pixels.
---@field height integer Current size in pixels.
---@field baseWidth number
---@field baseHeight number
---@field hoverScale number
---@field hoverSize number?---@field zoomScale (false|fun(mapScale: number, map: prettymap.MapView): number)
---@field zoomFactor number
---@field hovered boolean
---@field screenX integer?
---@field screenY integer?
---@field component ui.Layer? Layer filled by CreateComponent; nil if the element has no visual.
---@field manager prettymap.ElementManager?
---@field parent prettymap.Element?
---@field children prettymap.Element[]
local Element = {}
Element.__index = Element

--- Subclasses override this to fill `layer`, a fresh layer sized and positioned by the map.
--- Return true if content was added; otherwise the layer is destroyed and the element has no component.
--- The base implementation adds nothing, which makes a plain Element a pure group of its children.
---@param layer ui.Layer
---@return boolean? added
function Element:CreateComponent(layer)
    return false
end

--- Default zoom behaviour: `width`/`height`/`size` are measured in map tiles, so the element
--- keeps its size relative to the tiles at every zoom level.
---@param mapScale number Screen pixels per tile.
---@return number
local function TileProportional(mapScale)
    return mapScale
end

---@param options prettymap.ElementOptions?
---@return prettymap.Element
function Element.new(options)
    options = options or {}
    local width = options.width or options.size or 32
    local height = options.height or options.size or 32
    ---@class prettymap.Element
    local self = setmetatable({
        coordinate = options.coordinate,
        zLayer = options.zLayer,
        children = {},
        width = width,
        height = height,
        baseWidth = width,
        baseHeight = height,
        hoverScale = options.hoverScale or 1,
        hoverSize = options.hoverSize,
        zoomScale = options.zoomScale == nil and TileProportional or options.zoomScale,
        zoomFactor = 1,
        hovered = false,
    }, Element)
    return self
end

--- Recomputes the size from the base size, zoom factor and hover state, keeping the element centred.
--- While hovered, `hoverSize` (fixed pixels) wins over the zoomed size multiplied by `hoverScale`.
--- Children of the component should use relative sizes to follow the resize.
function Element:_UpdateSize()
    local width, height
    if self.hovered and self.hoverSize then
        width, height = self.hoverSize, self.hoverSize
    else
        local scale = self.zoomFactor * (self.hovered and self.hoverScale or 1)
        width = math.max(1, math.floor(self.baseWidth * scale + 0.5))
        height = math.max(1, math.floor(self.baseHeight * scale + 0.5))
    end
    if width == self.width and height == self.height then return end
    self.width, self.height = width, height
    if self.component then
        self.component:SetSize(width, height)
        if self.screenX then self:_ApplyPosition(self.screenX, self.screenY) end
    end
end

--- Called by the manager whenever the component must be sized and placed (only while it has a
--- component). Subclasses with their own geometry override this.
---@param map prettymap.MapView
function Element:_Layout(map)
    self:_ApplyZoom(map.currentScale, map)
    self.component:SetSize(self.width, self.height)
    if self.coordinate then
        self:_ApplyPosition(map:WorldToCanvas(self.coordinate))
    end
end

--- Called by the manager on every layout change with the map's pixels-per-tile scale.
---@param mapScale number
---@param map prettymap.MapView
function Element:_ApplyZoom(mapScale, map)
    if not self.zoomScale then
        self.zoomFactor = 1
        return
    end
    self.zoomFactor = self.zoomScale(mapScale, map)
    self:_UpdateSize()
end

--- Grows or restores the element by `hoverScale`.
---@param hovered boolean
---@return nil
function Element:_SetHovered(hovered)
    if self.hovered == hovered then return end
    self.hovered = hovered
    self:_UpdateSize()
end

--- Attaches a child. Children keep their own coordinates and are placed on the map like any
--- element; the parent only controls their lifetime (they are added to and removed from the
--- map together with it).
---@param child prettymap.Element The child element
---@return prettymap.Element # 
function Element:Add(child)
    if child.parent == self then return child end
    if child.parent then child.parent:Remove(child) end
    child.parent = self
    self.children[#self.children + 1] = child
    if self.manager then self.manager:Add(child) end
    return child
end

---@param child prettymap.Element
---@return boolean removed False if `child` was not a child of this element.
function Element:Remove(child)
    if child.parent ~= self then return false end
    for i, existing in ipairs(self.children) do
        if existing == child then
            table.remove(self.children, i)
            break
        end
    end
    child.parent = nil
    if self.manager then self.manager:Remove(child) end
    return true
end

--- Removes this element (and its children) from its parent or, for top-level elements, the map.
---@return nil
function Element:Detach()
    if self.parent then
        self.parent:Remove(self)
    elseif self.manager then
        self.manager:Remove(self)
    end
end

--- Moves the element; it is repositioned immediately if it is on a map.
---@param coordinate CoordGrid?
---@return nil
function Element:SetCoordinate(coordinate)
    self.coordinate = coordinate
    if self.manager then self.manager:_Position(self) end
end

--- Places the component centred on the coordinate, hiding it when it is not on the current plane.
---@param x integer?
---@param y integer?
function Element:_ApplyPosition(x, y)
    local component = self.component
    if not component then return end
    self.screenX, self.screenY = x, y
    if x == nil then
        component.hidden = true
        return
    end
    component.hidden = false
    component:SetPos(x - math.floor(self.width / 2), y - math.floor(self.height / 2))
end

return Element
