---@class prettymap.luaflet.TwigOptions
---@field coordinate prettymap.luaflet.Coord? Position the element is centred on. Elements without one have no position.
---@field width number? Width in map tiles (pixels if `zoomScale` is false).
---@field height number? Height in map tiles (pixels if `zoomScale` is false).
---@field size number? Shorthand for width and height.
---@field hoverSize number? Fixed pixel size (width and height) while hovered. Makes the element hoverable.
---@field zoomScale (false|fun(mapScale: number, map: prettymap.MapView): number)? Size factor from map zoom. Default is tile-proportional; false keeps a fixed pixel size.
---@field zLayer (string|prettymap.PaneID)? Named z-layer or pane id of the map. The map's topmost pane if nil.
---@field allPlanes boolean? Show the element and its children on every plane at their x/z position instead of hiding them on other planes. Use `_OnPlaneChanged` to restyle it.
---@field opacity number? Opacity from 0 to 1, multiplied into the element's children. Default 1. Fixed once added.
---@field pivotX number? Point of the element on its coordinate, as a fraction of its width from the left. Default 0.5.
---@field pivotY number? Point of the element on its coordinate, as a fraction of its height from the top. Default 0.5; 1 for a pin whose tip marks the coordinate.

---@class prettymap.luaflet.Twig : zyklib.disposable.IDisposable
---@field static boolean? True for elements fixed to the viewport instead of the map; see StaticElement.
---@field zLayer (string|prettymap.PaneID)? Named z-layer or pane id the element is drawn in; the map's topmost pane if nil.
---@field allPlanes boolean? If true, the element and its children are shown on every plane instead of being hidden on other planes; see `ShowsAllPlanes`.
---@field tooltip prettymap.Tooltip? Tooltip shown while hovered; set with `SetTooltip`.
---@field coordinate prettymap.luaflet.Coord? Position the element is centred on; nil means it has no position.
---@field width integer Current width in pixels, including zoom and hover effects.
---@field height integer Current height in pixels, including zoom and hover effects.
---@field baseWidth number Unscaled width: map tiles, or pixels if `zoomScale` is false.
---@field baseHeight number Unscaled height: map tiles, or pixels if `zoomScale` is false.
---@field hoverSize number? Fixed pixel size (width and height) while hovered; makes the element hoverable.
---@field zoomScale (false|fun(mapScale: number, map: prettymap.MapView): number) Size factor from the map zoom; false keeps a fixed pixel size.
---@field zoomFactor number Current result of `zoomScale`, multiplied with the base size.
---@field hovered boolean Whether the element is currently the hovered one.
---@field screenX integer? Last pixel position (centre, in canvas coordinates); nil while hidden or unplaced.
---@field screenY integer? Last pixel position (centre, in canvas coordinates); nil while hidden or unplaced.
---@field component ui.Layer? Layer filled by CreateComponent; nil if the element has no visual.
---@field manager prettymap.ElementManager? The manager the element is added to; nil while not on a map.
---@field parent prettymap.luaflet.Twig? Element this one is a child of; nil for top-level elements.
---@field children prettymap.luaflet.Twig[] Child elements, added to and removed from the map together with this one.
---@field clipsToView boolean? Laid out again when the map is panned; for elements that clip their drawing to the view.
---@field opacity number Own opacity from 0 to 1; the drawn opacity also includes the parents', see `GetOpacity`.
---@field pivotX number Point of the element on its coordinate, as a fraction of its width from the left.
---@field pivotY number Point of the element on its coordinate, as a fraction of its height from the top.
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

---@param options prettymap.luaflet.TwigOptions?
---@return prettymap.luaflet.Twig
function Element.new(options)
    options = options or {}
    local width = options.width or options.size or 32
    local height = options.height or options.size or 32
    ---@class prettymap.luaflet.Twig
    local self = setmetatable({
        coordinate = options.coordinate,
        zLayer = options.zLayer,
        allPlanes = options.allPlanes,
        children = {},
        width = width,
        height = height,
        baseWidth = width,
        baseHeight = height,
        hoverSize = options.hoverSize,
        zoomScale = options.zoomScale == nil and TileProportional or options.zoomScale,
        zoomFactor = 1,
        hovered = false,
        opacity = options.opacity or 1,
        pivotX = options.pivotX or 0.5,
        pivotY = options.pivotY or 0.5,
    }, Element)
    return self
end

--- The size in pixels from the base size and zoom factor; while hovered, `hoverSize` (fixed pixels).
--- Subclasses override this when their size also depends on their content.
---@return number width
---@return number height
function Element:_ComputeSize()
    if self.hovered and self.hoverSize then
        return self.hoverSize, self.hoverSize
    end
    local scale = self.zoomFactor
    return math.max(1, math.floor(self.baseWidth * scale + 0.5)),
        math.max(1, math.floor(self.baseHeight * scale + 0.5))
end

--- Recomputes the size with `_ComputeSize`, keeping the element centred.
--- Children of the component should use relative sizes to follow the resize.
function Element:_UpdateSize()
    local width, height = self:_ComputeSize()
    if width == self.width and height == self.height then return end
    self.width, self.height = width, height
    if self.component then
        self.component:SetSize(width, height)
        if self.screenX then self:_ApplyPosition(self.screenX, self.screenY) end
    end
end

--- The opacity the element is drawn with: its own times that of its parents.
---@return number
function Element:GetOpacity()
    return (self.opacity or 1) * (self.parent and self.parent:GetOpacity() or 1)
end

--- Whether the element is shown on every plane: set on itself or on a parent.
---@return boolean
function Element:ShowsAllPlanes()
    return self.allPlanes == true or (self.parent ~= nil and self.parent:ShowsAllPlanes())
end

--- Called by the manager whenever the component must be sized and placed (only while it has a
--- component). Subclasses with their own geometry override this.
---@param map prettymap.MapView
function Element:_Layout(map)
    self:_ApplyZoom(map.currentScale, map)
    self.component:SetSize(self.width, self.height)
    if self.coordinate then
        self:_ApplyPosition(map:CoordToCanvas(self.coordinate, self:ShowsAllPlanes()))
    end
end

--- Called when the element's component is created and whenever the map's plane changes.
--- Subclasses override this to restyle the element for the plane.
---@param plane integer
function Element:_OnPlaneChanged(plane)
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

--- True if the element reacts to hovering (grows on hover); only such elements can have tooltips.
---@return boolean
function Element:IsHoverable()
    return self.hoverSize ~= nil
end

--- Sets (or, with nil, removes) the tooltip shown while the element is hovered. Its content is
--- built on every hover and destroyed when the tooltip disappears.
---@param tooltip prettymap.Tooltip?
---@return nil
function Element:SetTooltip(tooltip)
    if tooltip and not self:IsHoverable() then
        error("Only hoverable elements (hoverSize) can have a tooltip", 2)
    end
    if self.manager then self.manager:_ForgetTooltip(self) end
    self.tooltip = tooltip
end

--- Resizes the element to `hoverSize` while hovered and restores it afterwards.
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
---@generic T: prettymap.luaflet.Twig
---@param self T
---@param child prettymap.luaflet.Twig The child element
---@return T self
function Element.Add(self, child)
    if child.parent == self then return self end
    if child.parent then child.parent:Remove(child) end
    child.parent = self
    self.children[#self.children + 1] = child
    --- If this element is already managed by a map, add the child to the same manager.
    if self.manager then self.manager:Add(child) end
    return self
end

--- Adds this element to a parent element or to an element manager.
---@generic T: prettymap.luaflet.Twig
---@param self T
---@param target prettymap.luaflet.Twig|prettymap.ElementManager
---@return T self
function Element.AddTo(self, target)
    target:Add(self)
    return self
end

---@param child prettymap.luaflet.Twig
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

function Element:dispose()
    self:Detach()
end

--- Moves the element; it is repositioned immediately if it is on a map.
---@param coordinate prettymap.luaflet.Coord?
---@return nil
function Element:SetCoordinate(coordinate)
    self.coordinate = coordinate
    if self.manager then self.manager:_Position(self) end
end

--- Places the component with its pivot on the coordinate, hiding it when it is not on the current plane.
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
    component:SetPos(x - math.floor(self.width * self.pivotX), y - math.floor(self.height * self.pivotY))
end

return Element
