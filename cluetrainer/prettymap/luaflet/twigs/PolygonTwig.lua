local Twig = require("prettymap/luaflet/twigs/Twig")

---@alias prettymap.Primitive
---| { kind: "line", a: prettymap.luaflet.Coord, b: prettymap.luaflet.Coord, thickness: number, colour: integer }
---| { kind: "polyline", points: prettymap.luaflet.Coord[], thickness: number, colour: integer }
---| { kind: "rect", a: prettymap.luaflet.Coord, b: prettymap.luaflet.Coord, colour: integer }
---| { kind: "outline", a: prettymap.luaflet.Coord, b: prettymap.luaflet.Coord, thickness: number, colour: integer }
---| { kind: "triangle", a: prettymap.luaflet.Coord, b: prettymap.luaflet.Coord, c: prettymap.luaflet.Coord, colour: integer }

--- Draws any number of lines, rectangles, outlines and filled triangles on a canvas. All geometry
--- is given in map coordinates and follows the map when zooming; stroke widths are fixed pixels.
--- All points of a polygon should be on the same plane; it is hidden on any other plane.
---@class prettymap.luaflet.PolygonTwig : prettymap.luaflet.Twig
---@field primitives prettymap.Primitive[]
---@field canvas ui.Canvas?
local PolygonTwig = setmetatable({}, { __index = Twig })
PolygonTwig.__index = PolygonTwig

---@return prettymap.luaflet.PolygonTwig
function PolygonTwig.new()
    ---@class prettymap.luaflet.PolygonTwig
    local self = setmetatable(Twig.new({ zoomScale = false, zLayer = "overlay" }), PolygonTwig)
    self.primitives = {}
    return self
end

---@param primitive prettymap.Primitive
---@return prettymap.luaflet.PolygonTwig self
function PolygonTwig:_AddPrimitive(primitive)
    self.primitives[#self.primitives + 1] = primitive
    if self.manager then self.manager:_Position(self) end
    return self
end

--- Adds a line.
---@param a prettymap.luaflet.Coord
---@param b prettymap.luaflet.Coord
---@param thickness number Stroke width in pixels.
---@param colour integer RGBA colour.
---@return prettymap.luaflet.PolygonTwig self
function PolygonTwig:AddLine(a, b, thickness, colour)
    return self:_AddPrimitive({ kind = "line", a = a, b = b, thickness = thickness, colour = colour })
end

--- Adds connected lines through the given points. Corners of 90° and 135° are mitered so the thick
--- segments join without gaps.
---@param points prettymap.luaflet.Coord[]
---@param thickness number Stroke width in pixels.
---@param colour integer RGBA colour.
---@return prettymap.luaflet.PolygonTwig self
function PolygonTwig:AddPolyline(points, thickness, colour)
    return self:_AddPrimitive({ kind = "polyline", points = points, thickness = thickness, colour = colour })
end

--- How far a segment ending at `b` must be extended along its direction to close the gap at a corner.
---@param a number[] Previous point (pixels).
---@param b number[] Corner (pixels).
---@param c number[] Next point (pixels).
---@param thickness number
---@return number pixels
local function corner_extension(a, b, c, thickness)
    local ux, uy = b[1] - a[1], b[2] - a[2]
    local vx, vy = c[1] - b[1], c[2] - b[2]
    local lengths = math.sqrt(ux * ux + uy * uy) * math.sqrt(vx * vx + vy * vy)
    if lengths == 0 then return 0 end

    local dot = math.max(-1, math.min(1, (ux * vx + uy * vy) / lengths))

    -- Ignore straight segments (180° inner angle) and sharp 45° inner angles.
    if dot > 0.9999 or dot < -0.0001 then return 0 end

    return thickness * 0.5 * math.tan(math.acos(dot) / 2)
end
--- Draws the polyline segments, given the points in canvas pixels.
---@param canvas ui.Canvas
---@param points number[][]
---@param thickness number
---@param colour integer
---@param originX number
---@param originY number
local function draw_polyline(canvas, points, thickness, colour, originX, originY)
    for i = 1, #points - 1 do
        local a, b = points[i], points[i + 1]
        local dx, dy = b[1] - a[1], b[2] - a[2]
        local len = math.sqrt(dx * dx + dy * dy)

        if len > 0 then
            local start = i > 1 and corner_extension(points[i - 1], a, b, thickness) or 0
            local finish = i < #points - 1 and corner_extension(a, b, points[i + 2], thickness) or 0

            canvas:AddLine(
                math.floor(a[1] - dx / len * start - originX + 0.5), math.floor(a[2] - dy / len * start - originY + 0.5),
                math.floor(b[1] + dx / len * finish - originX + 0.5), math.floor(b[2] + dy / len * finish - originY + 0.5),
                thickness, colour
            )
        end
    end
end

--- Adds a filled rectangle spanning two opposite corners.
---@param a prettymap.luaflet.Coord
---@param b prettymap.luaflet.Coord
---@param colour integer RGBA colour.
---@return prettymap.luaflet.PolygonTwig self
function PolygonTwig:AddRectangle(a, b, colour)
    return self:_AddPrimitive({ kind = "rect", a = a, b = b, colour = colour })
end

--- Adds an unfilled rectangle spanning two opposite corners.
---@param a prettymap.luaflet.Coord
---@param b prettymap.luaflet.Coord
---@param thickness number Stroke width in pixels.
---@param colour integer RGBA colour.
---@return prettymap.luaflet.PolygonTwig self
function PolygonTwig:AddOutline(a, b, thickness, colour)
    return self:_AddPrimitive({ kind = "outline", a = a, b = b, thickness = thickness, colour = colour })
end

--- Adds a filled triangle.
---@param a prettymap.luaflet.Coord
---@param b prettymap.luaflet.Coord
---@param c prettymap.luaflet.Coord
---@param colour integer RGBA colour.
---@return prettymap.luaflet.PolygonTwig self
function PolygonTwig:AddTriangle(a, b, c, colour)
    return self:_AddPrimitive({ kind = "triangle", a = a, b = b, c = c, colour = colour })
end

--- Removes all primitives.
---@return prettymap.luaflet.PolygonTwig self
function PolygonTwig:Clear()
    self.primitives = {}
    if self.manager then self.manager:_Position(self) end
    return self
end

---@param layer ui.Layer
---@return boolean added
function PolygonTwig:CreateComponent(layer)
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
function PolygonTwig:_Layout(map)
    local component, canvas = self.component, self.canvas
    canvas:Clear()

    local resolved = {}
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local pad = 1
    for i, p in ipairs(self.primitives) do
        local points = {}
        local function resolve(coord)
            local x, y = map:CoordToCanvas(coord)
            if not x then return nil end
            -- The canvas takes integer pixels.
            x, y = math.floor(x + 0.5), math.floor(y + 0.5)
            minX, minY = math.min(minX, x), math.min(minY, y)
            maxX, maxY = math.max(maxX, x), math.max(maxY, y)
            return { x, y }
        end

        if p.kind == "polyline" then
            for j, coord in ipairs(p.points) do
                points[j] = resolve(coord)
                if not points[j] then
                    component.hidden = true
                    return
                end
            end
        else
            for _, key in ipairs(POINT_KEYS) do
                if p[key] then
                    points[key] = resolve(p[key])
                    if not points[key] then
                        component.hidden = true
                        return
                    end
                end
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
        if p.kind == "polyline" then
            draw_polyline(canvas, pts, p.thickness, p.colour, minX, minY)
        elseif p.kind == "line" then
            canvas:AddLine(pts.a[1] - minX, pts.a[2] - minY, pts.b[1] - minX, pts.b[2] - minY, p.thickness, p.colour)
        elseif p.kind == "triangle" then
            canvas:AddTriangle(pts.a[1] - minX, pts.a[2] - minY, pts.b[1] - minX, pts.b[2] - minY,
                pts.c[1] - minX, pts.c[2] - minY, p.colour)
        else
            local ax, ay = pts.a[1] - minX, pts.a[2] - minY
            local bx, by = pts.b[1] - minX, pts.b[2] - minY
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

return PolygonTwig
