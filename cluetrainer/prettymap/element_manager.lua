--- Owns all elements placed on a map. Composed into MapView, which only
--- forwards layout changes via Refresh().
---@class prettymap.ElementManager
---@field map prettymap.MapView
---@field layer ui.Layer
---@field elements table<prettymap.Element, true>
local ElementManager = {}
ElementManager.__index = ElementManager

---@param map prettymap.MapView
---@param layer ui.Layer Parent layer in canvas (content) coordinates.
---@return prettymap.ElementManager
function ElementManager.new(map, layer)
    return setmetatable({ map = map, layer = layer, elements = {} }, ElementManager)
end

---@param element prettymap.Element
function ElementManager:_Position(element)
    if not element.component then return end
    element:_ApplyZoom(self.map.currentScale, self.map)
    element.component:SetSize(element.width, element.height)
    if element.coordinate then
        element:_ApplyPosition(self.map:WorldToCanvas(element.coordinate))
    end
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
    local layer = ui.Layer.new(self.layer)
    layer.clickthrough = true
    if element.hoverScale ~= 1 then
        -- The layer must receive mouse events for the hover growth to work.
        layer.clickthrough = false
        layer:Subscribe(ui.Hook.ONMOUSEOVER, function()
            element:SetHovered(true)
            return true
        end)
        layer:Subscribe(ui.Hook.ONMOUSELEAVE, function()
            element:SetHovered(false)
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
