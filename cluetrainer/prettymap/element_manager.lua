--- Owns all elements placed on a map. Composed into MapView, which only
--- forwards layout changes via Refresh().
---@alias prettymap.PaneID integer Determines the stacking order of a z-layer; lower is further behind.

---@class prettymap.ElementManager
---@field map prettymap.MapView
---@field layer ui.Layer
---@field panes table<prettymap.PaneID, ui.Layer> Clickthrough containers, one per distinct pane id.
---@field paneIDs table<string, prettymap.PaneID> Named z-layers.
---@field topPane prettymap.PaneID Highest pane id; the fallback for elements without a z-layer.
---@field elements table<prettymap.Element, true>
local ElementManager = {}
ElementManager.__index = ElementManager

---@type table<string, prettymap.PaneID>
ElementManager.DEFAULT_Z_LAYERS = { overlay = 100, marker = 200 }

--- The z-layers are fixed at construction. Elements in a higher pane are always drawn above
--- elements in a lower one; within a pane, later additions are on top (and hovered elements
--- are raised). Names sharing a pane id share a pane.
---@param map prettymap.MapView
---@param layer ui.Layer Parent layer in canvas (content) coordinates.
---@param zLayers table<string, prettymap.PaneID>? Defaults to `DEFAULT_Z_LAYERS`.
---@return prettymap.ElementManager
function ElementManager.new(map, layer, zLayers)
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

    return setmetatable({
        map = map,
        layer = layer,
        elements = {},
        panes = panes,
        paneIDs = zLayers,
        topPane = ids[#ids],
    }, ElementManager)
end

---@param element prettymap.Element
---@return ui.Layer
function ElementManager:_ContainerFor(element)
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

---@param element prettymap.Element
function ElementManager:_Position(element)
    if not element.component then return end
    element:_Layout(self.map)
end

--- Adds an element together with all of its children.
--- The element's component is a fresh layer filled by `CreateComponent`; the layer is destroyed
--- again if `CreateComponent` reports that it added nothing, leaving `component` nil.
---@param element prettymap.Element
---@return prettymap.Element
function ElementManager:Add(element)
    if self.elements[element] then return element end
    self.elements[element] = true
    element.manager = self
    local layer = ui.Layer.new(self:_ContainerFor(element))
    -- Stays clickthrough: hover hooks are subscribed without blocking clicks to the map below.
    layer.clickthrough = true
    if element.hoverScale ~= 1 or element.hoverSize then
        layer:Subscribe(ui.Hook.ONMOUSEOVER, function()
            layer:MoveToFront() -- on top within its z-layer
            element:_SetHovered(true)
            return true
        end)
        layer:Subscribe(ui.Hook.ONMOUSELEAVE, function()
            element:_SetHovered(false)
            return true
        end)
    end

    if element:CreateComponent(layer) then
        element.component = layer
        self:_Position(element)
    else
        layer:Destroy()
    end
    for _, child in ipairs(element.children) do self:Add(child) end
    return element
end

--- Removes an element together with all of its children.
---@param element prettymap.Element
---@return boolean removed
function ElementManager:Remove(element)
    if element.parent then return element.parent:Remove(element) end
    if not self.elements[element] then return false end
    self:_RemoveSubtree(element)
    return true
end

---@param element prettymap.Element
function ElementManager:_RemoveSubtree(element)
    for _, child in ipairs(element.children) do self:_RemoveSubtree(child) end
    self.elements[element] = nil
    element.manager = nil
    if element.component then
        element.component:Destroy()
        element.component = nil
    end
end

--- Repositions everything; call after scale/plane/size changes.
---@return nil
function ElementManager:Refresh()
    for element in pairs(self.elements) do self:_Position(element) end
end

---@return nil
function ElementManager:Destroy()
    for element in pairs(self.elements) do
        element.manager = nil
        element.component = nil
    end
    self.elements = {}
end

return ElementManager
