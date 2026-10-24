local Element = require("prettymap/elements/Element")

---@alias prettymap.Primitive
---| { kind: "line", a: CoordFine|CoordGrid, b: CoordFine|CoordGrid, thickness: number, colour: integer }
---| { kind: "rect", a: CoordFine|CoordGrid, b: CoordFine|CoordGrid, colour: integer }
---| { kind: "outline", a: CoordFine|CoordGrid, b: CoordFine|CoordGrid, thickness: number, colour: integer }
---| { kind: "triangle", a: CoordFine|CoordGrid, b: CoordFine|CoordGrid, c: CoordFine|CoordGrid, colour: integer }

--- Draws any number of lines, rectangles, outlines and filled triangles on a canvas. All geometry
--- is given in map coordinates and follows the map when zooming; stroke widths are fixed pixels.
--- All points of a polygon should be on the same plane; it is hidden on any other plane.
---@class prettymap.PolygonElement : prettymap.Element
---@field primitives prettymap.Primitive[]
---@field canvas ui.Canvas?
local PolygonElement = setmetatable({}, { __index = Element })
PolygonElement.__index = PolygonElement

---@return prettymap.PolygonElement
function PolygonElement.new()
    ---@class prettymap.PolygonElement
    local self = setmetatable(Element.new({ zoomScale = false, zLayer = "overlay" }), PolygonElement)
    self.primitives = {}
    return self
end

---@param primitive prettymap.Primitive
---@return prettymap.PolygonElement self
function PolygonElement:_AddPrimitive(primitive)
    self.primitives[#self.primitives + 1] = primitive
    if self.manager then self.manager:_Position(self) end
    return self
end

--- Adds a line.
---@param a CoordFine|CoordGrid
---@param b CoordFine|CoordGrid
---@param thickness number Stroke width in pixels.
---@param colour integer RGBA colour.
---@return prettymap.PolygonElement self
function PolygonElement:AddLine(a, b, thickness, colour)
    return self:_AddPrimitive({ kind = "line", a = a, b = b, thickness = thickness, colour = colour })
end

--- Adds a filled rectangle spanning two opposite corners.
---@param a CoordFine|CoordGrid
---@param b CoordFine|CoordGrid
---@param colour integer RGBA colour.
---@return prettymap.PolygonElement self
function PolygonElement:AddRectangle(a, b, colour)
    return self:_AddPrimitive({ kind = "rect", a = a, b = b, colour = colour })
end

--- Adds an unfilled rectangle spanning two opposite corners.
---@param a CoordFine|CoordGrid
---@param b CoordFine|CoordGrid
---@param thickness number Stroke width in pixels.
---@param colour integer RGBA colour.
---@return prettymap.PolygonElement self
function PolygonElement:AddOutline(a, b, thickness, colour)
    return self:_AddPrimitive({ kind = "outline", a = a, b = b, thickness = thickness, colour = colour })
end

--- Adds a filled triangle.
---@param a CoordFine|CoordGrid
---@param b CoordFine|CoordGrid
---@param c CoordFine|CoordGrid
---@param colour integer RGBA colour.
---@return prettymap.PolygonElement self
function PolygonElement:AddTriangle(a, b, c, colour)
    return self:_AddPrimitive({ kind = "triangle", a = a, b = b, c = c, colour = colour })
end

--- Removes all primitives.
---@return prettymap.PolygonElement self
function PolygonElement:Clear()
    self.primitives = {}
    if self.manager then self.manager:_Position(self) end
    return self
end

---@param layer ui.Layer
---@return boolean added
function PolygonElement:CreateComponent(layer)
    local canvas = ui.Canvas.new(layer)
    canvas:SetSize(0, 0, 1.0, 1.0)
    canvas.clickthrough = true
    self.canvas = canvas
    return true
end

local POINT_KEYS = { "a", "b", "c" }

--- Converts all points to canvas pixels and redraws. The layer covers just the bounding box of the
--- geometry (plus the stroke), so it is hidden when any point is off the current plane.
---@param map prettymap.MapView
function PolygonElement:_Layout(map)
    local component, canvas = self.component, self.canvas
    canvas:Clear()

    local resolved = {}
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local pad = 1
    for i, p in ipairs(self.primitives) do
        local points = {}
        for _, key in ipairs(POINT_KEYS) do
            if p[key] then
                local x, y = map:FineToCanvas(p[key])
                if not x then
                    component.hidden = true
                    return
                end
                -- The canvas takes integer pixels.
                x, y = math.floor(x + 0.5), math.floor(y + 0.5)
                points[key] = { x, y }
                minX, minY = math.min(minX, x), math.min(minY, y)
                maxX, maxY = math.max(maxX, x), math.max(maxY, y)
            end
        end
        resolved[i] = points
        if p.thickness then pad = math.max(pad, math.ceil(p.thickness / 2) + 1) end
    end

    if #self.primitives == 0 then
        component.hidden = true
        return
    end

    minX, minY, maxX, maxY = minX - pad, minY - pad, maxX + pad, maxY + pad
    component.hidden = false
    component:SetPos(minX, minY)
    component:SetSize(maxX - minX, maxY - minY)
    self.width, self.height = maxX - minX, maxY - minY

    for i, p in ipairs(self.primitives) do
        local pts = resolved[i]
        local ax, ay = pts.a[1] - minX, pts.a[2] - minY
        local bx, by = pts.b[1] - minX, pts.b[2] - minY
        if p.kind == "line" then
            canvas:AddLine(ax, ay, bx, by, p.thickness, p.colour)
        elseif p.kind == "triangle" then
            canvas:AddTriangle(ax, ay, bx, by, pts.c[1] - minX, pts.c[2] - minY, p.colour)
        else
            local x, y = math.min(ax, bx), math.min(ay, by)
            local w, h = math.abs(bx - ax), math.abs(by - ay)
            if p.kind == "rect" then
                canvas:AddRectangle(x, y, w, h, p.colour)
            else
                canvas:AddOutline(x, y, w, h, p.thickness, p.colour)
            end
        end
    end
end

return PolygonElement
