--- Owns all elements placed on a map. Composed into MapView, which only
--- forwards layout changes via Refresh().
---@alias prettymap.PaneID integer Determines the stacking order of a z-layer; lower is further behind.

---@class prettymap.ElementManager
---@field map prettymap.MapView
---@field layer ui.Layer
---@field panes table<prettymap.PaneID, ui.Layer> Clickthrough containers, one per distinct pane id.
---@field paneIDs table<string, prettymap.PaneID> Named z-layers.
---@field topPane prettymap.PaneID Highest pane id; the fallback for elements without a z-layer.
---@field staticLayer ui.Layer Parent of static elements; they have no z-layers and are drawn above everything.
---@field elements table<prettymap.luaflet.Twig, true>
---@field hoverQueue prettymap.luaflet.Twig[] Elements under the cursor in order of entry; the first one is hovered.
---@field tooltipParent ui.Component? Component tooltips are placed in; defaults to the game area.
---@field tooltips prettymap.TooltipHost? Created on the first tooltip.
---@field viewChangeListeners table<table, fun(map: prettymap.MapView)>
local ElementManager = {}
ElementManager.__index = ElementManager

local TooltipHost = require("prettymap/luaflet/TooltipHost")

---@type table<string, prettymap.PaneID>
ElementManager.DEFAULT_Z_LAYERS = { grid = 50, overlay = 100, marker = 200 }

--- The z-layers are fixed at construction. Elements in a higher pane are always drawn above
--- elements in a lower one; within a pane, later additions are on top (and hovered elements
--- are raised). Names sharing a pane id share a pane.
---@param map prettymap.MapView
---@param layer ui.Layer Parent layer in canvas (content) coordinates.
---@param zLayers table<string, prettymap.PaneID>? Defaults to `DEFAULT_Z_LAYERS`.
---@param tooltipParent ui.Component? Defaults to the game area; tooltips may extend past the map inside it.
---@param staticLayer ui.Layer Non-scrolling layer covering the viewport, parent of static elements.
---@return prettymap.ElementManager
function ElementManager.new(map, layer, zLayers, tooltipParent, staticLayer)
    zLayers = zLayers or ElementManager.DEFAULT_Z_LAYERS

    local ids, seen = {}, {}
    for _, paneID in pairs(zLayers) do
        if not seen[paneID] then
            seen[paneID] = true
            ids[#ids + 1] = paneID
        end
    end
    table.sort(ids)

    local panes = {}
    for _, paneID in ipairs(ids) do
        local container = ui.Layer.new(layer)
        container:SetSize(0, 0, 1.0, 1.0)
        container.clickthrough = true
        panes[paneID] = container
    end

    local self = setmetatable({
        map = map,
        layer = layer,
        staticLayer = staticLayer,
        elements = {},
        hoverQueue = {},
        viewChangeListeners = {},
        panes = panes,
        paneIDs = zLayers,
        topPane = ids[#ids],
        tooltipParent = tooltipParent,
    }, ElementManager)

    -- Lay out elements that clip their drawing to the view again when the map is panned, so the clipping follows.
    self:AddViewChangeListener(function()
        for element in pairs(self.elements) do
            if element.clipsToView then self:_Position(element) end
        end
    end)

    return self
end

--- Registers a callback invoked with the map when its view changes.
---@param callback fun(map: prettymap.MapView)
---@return table token
function ElementManager:AddViewChangeListener(callback)
    assert(type(callback) == "function", "view change callback must be a function")
    local token = {}
    self.viewChangeListeners[token] = callback
    return token
end

---@param token table
function ElementManager:RemoveViewChangeListener(token)
    self.viewChangeListeners[token] = nil
end

function ElementManager:_NotifyViewChanged()
    self:_PruneHoverQueue() -- Prune off-screen or hidden elements from the hover queue
    for _, callback in pairs(self.viewChangeListeners) do
        self.map:_InvokeCallback("view change", callback, self.map)
    end
end

---@param element prettymap.luaflet.Twig
---@return ui.Layer
function ElementManager:_ContainerFor(element)
    if element.static then return self.staticLayer end
    local key = element.zLayer or self.topPane
    local paneID = type(key) == "string" and self.paneIDs[key] or key
    local container = self.panes[paneID]
    if not container then
        local names = {}
        for name, id in pairs(self.paneIDs) do names[#names + 1] = ("%s=%s"):format(name, id) end
        table.sort(names)
        error(("Unknown z-layer '%s'; valid layers: %s"):format(
            tostring(key), table.concat(names, ", ")), 3)
    end
    return container
end

---@param element prettymap.luaflet.Twig
function ElementManager:_Position(element)
    if not element.component then return end
    element:_Layout(self.map)
end

--- The cursor entered `element`. The first element of the queue is the hovered one; others wait
--- behind it (a new hover never evicts the current one) and take over in order once it leaves,
--- provided the cursor is still on them.
---@param element prettymap.luaflet.Twig
function ElementManager:_Hover(element)
    for _, queued in ipairs(self.hoverQueue) do
        if queued == element then return end
    end
    self.hoverQueue[#self.hoverQueue + 1] = element
    if #self.hoverQueue == 1 then self:_Activate(element) end
end

---@param element prettymap.luaflet.Twig
function ElementManager:_Activate(element)
    element.component:MoveToFront() -- on top within its z-layer
    element:_SetHovered(true)
    if element.tooltip then self:_Tooltips():Show(element) end
end

--- The cursor left `element`. An interactive tooltip keeps the hovered element until the cursor
--- leaves its region.
---@param element prettymap.luaflet.Twig
function ElementManager:_Unhover(element)
    if self.hoverQueue[1] == element and self.tooltips and self.tooltips.holding then return end
    self:_Leave(element)
end

--- Releases the hovered element regardless of its tooltip.
---@return nil
function ElementManager:_Release()
    local element = self.hoverQueue[1]
    if element then self:_Leave(element) end
end

--- Removes off-screen or hidden entries from the hover queue.
--- Prevents lingering hover states for elements that are no longer visible on the screen.
function ElementManager:_PruneHoverQueue()
    local map = self.map
    for i = #self.hoverQueue, 1, -1 do
        local element = self.hoverQueue[i]
        local component = element.component
        local x, y = element.screenX, element.screenY
        local visible = component and not component.hidden and x ~= nil and y ~= nil
        if visible then
            local left, top
            if element.static then
                left, top = x, y
            else
                left = x - math.floor(element.width * element.pivotX) - (map.viewport.scrollX or 0)
                top = y - math.floor(element.height * element.pivotY) - (map.viewport.scrollY or 0)
            end
            visible = left < map.viewportWidth and left + element.width > 0
                and top < map.viewportHeight and top + element.height > 0
        end
        if not visible then self:_Leave(element) end
    end
end

--- Removes `element` from the queue; if it was hovered, un-hovers it and hands over to the next.
---@param element prettymap.luaflet.Twig
function ElementManager:_Leave(element)
    for i, queued in ipairs(self.hoverQueue) do
        if queued == element then
            table.remove(self.hoverQueue, i)
            if i ~= 1 then return end
            if self.tooltips then self.tooltips:Hide() end
            element:_SetHovered(false)
            local nextElement = self.hoverQueue[1]
            if nextElement then self:_Activate(nextElement) end
            return
        end
    end
end

---@return prettymap.TooltipHost
function ElementManager:_Tooltips()
    if not self.tooltips then
        local parent = self.tooltipParent
            or ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP)
        self.tooltips = TooltipHost.new(parent, self.map.viewport, function() self:_Release() end)
    end
    return self.tooltips
end

--- Drops the cached tooltip content of `element`.
---@param element prettymap.luaflet.Twig
function ElementManager:_ForgetTooltip(element)
    if self.tooltips then self.tooltips:Forget(element) end
end

--- Adds an element together with all of its children.
--- The element's component is a fresh layer filled by `CreateComponent`; the layer is destroyed
--- again if `CreateComponent` reports that it added nothing, leaving `component` nil.
---@param element prettymap.luaflet.Twig
---@return prettymap.luaflet.Twig
function ElementManager:Add(element)
    if self.elements[element] then return element end
    self.elements[element] = true
    element.manager = self
    local layer = ui.Layer.new(self:_ContainerFor(element))
    -- Stays clickthrough: hover hooks are subscribed without blocking clicks to the map below.
    layer.clickthrough = true
    if element:IsHoverable() then
        layer:Subscribe(ui.Hook.ONMOUSEOVER, function()
            self:_Hover(element)
            return true
        end)
        layer:Subscribe(ui.Hook.ONMOUSELEAVE, function()
            self:_Unhover(element)
            return true
        end)
    end

    if element:CreateComponent(layer) then
        element.component = layer
        local opacity = element:GetOpacity()
        if opacity < 1 then layer.alpha = opacity end
        self:_Position(element)
        element:_OnPlaneChanged(self.map:GetPlane())
    else
        layer:Destroy()
    end
    for _, child in ipairs(element.children) do self:Add(child) end
    return element
end

--- Removes an element together with all of its children.
---@param element prettymap.luaflet.Twig
---@return boolean removed
function ElementManager:Remove(element)
    if element.parent then return element.parent:Remove(element) end
    if not self.elements[element] then return false end
    self:_RemoveSubtree(element)
    return true
end

---@param element prettymap.luaflet.Twig
function ElementManager:_RemoveSubtree(element)
    for _, child in ipairs(element.children) do self:_RemoveSubtree(child) end
    self.elements[element] = nil
    element.manager = nil
    self:_Leave(element)
    self:_ForgetTooltip(element)
    if element.component then
        element.component:Destroy()
        element.component = nil
    end
end

--- Notifies all elements with a component that the map's plane changed.
---@param plane integer
function ElementManager:_PlaneChanged(plane)
    for element in pairs(self.elements) do
        if element.component then element:_OnPlaneChanged(plane) end
    end
end

--- Repositions everything; call after scale/plane/size changes.
---@return nil
function ElementManager:Refresh()
    for element in pairs(self.elements) do self:_Position(element) end
end

---@return nil
function ElementManager:Destroy()
    self.viewChangeListeners = {}
    self.hoverQueue = {}
    if self.tooltips then
        self.tooltips:Destroy()
        self.tooltips = nil
    end
    for element in pairs(self.elements) do
        element.manager = nil
        element.component = nil
    end
    self.elements = {}
end

return ElementManager
