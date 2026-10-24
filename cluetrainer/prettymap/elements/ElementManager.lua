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
---@field hovered prettymap.Element? The single hovered element, if any.
---@field tooltipParent ui.Component? Component tooltips are placed in; defaults to the game area.
---@field tooltips prettymap.TooltipHost? Created on the first tooltip.
local ElementManager = {}
ElementManager.__index = ElementManager

local TooltipHost = require("prettymap/elements/TooltipHost")

---@type table<string, prettymap.PaneID>
ElementManager.DEFAULT_Z_LAYERS = { overlay = 100, marker = 200 }

--- The z-layers are fixed at construction. Elements in a higher pane are always drawn above
--- elements in a lower one; within a pane, later additions are on top (and hovered elements
--- are raised). Names sharing a pane id share a pane.
---@param map prettymap.MapView
---@param layer ui.Layer Parent layer in canvas (content) coordinates.
---@param zLayers table<string, prettymap.PaneID>? Defaults to `DEFAULT_Z_LAYERS`.
---@param tooltipParent ui.Component? Defaults to the game area; tooltips may extend past the map inside it.
---@return prettymap.ElementManager
function ElementManager.new(map, layer, zLayers, tooltipParent)
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
        tooltipParent = tooltipParent,
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

--- Hovers `element` unless another element is already hovered; the first hover holds the slot
--- until it is cleared, so a new hover never evicts it.
---@param element prettymap.Element
function ElementManager:_Hover(element)
    if self.hovered then return end
    self.hovered = element
    element.component:MoveToFront() -- on top within its z-layer
    element:_SetHovered(true)
    if element.tooltip then self:_Tooltips():Show(element) end
end

--- An interactive tooltip keeps the element hovered until the cursor leaves its region.
---@param element prettymap.Element
function ElementManager:_Unhover(element)
    if self.hovered ~= element then return end
    if self.tooltips and self.tooltips.holding then return end
    self:_Release()
end

---@return nil
function ElementManager:_Release()
    local element = self.hovered
    if self.tooltips then self.tooltips:Hide() end
    self.hovered = nil
    if element then element:_SetHovered(false) end
end

---@return prettymap.TooltipHost
function ElementManager:_Tooltips()
    if not self.tooltips then
        local parent = self.tooltipParent
            or ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA)
        self.tooltips = TooltipHost.new(parent, self.map.viewport, function() self:_Release() end)
    end
    return self.tooltips
end

--- Drops the cached tooltip content of `element`.
---@param element prettymap.Element
function ElementManager:_ForgetTooltip(element)
    if self.tooltips then self.tooltips:Forget(element) end
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
    if self.hovered == element then self:_Release() end
    self:_ForgetTooltip(element)
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
    self.hovered = nil
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
