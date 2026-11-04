local Twig = require("prettymap/luaflet/twigs/Twig")

---@alias prettymap.Primitive
---| { kind: "line", a: prettymap.luaflet.Coord, b: prettymap.luaflet.Coord, thickness: number, colour: integer }
---| { kind: "polyline", points: prettymap.luaflet.Coord[], thickness: number, colour: integer }
---| { kind: "rect", a: prettymap.luaflet.Coord, b: prettymap.luaflet.Coord, colour: integer }
---| { kind: "outline", a: prettymap.luaflet.Coord, b: prettymap.luaflet.Coord, thickness: number, colour: integer }
---| { kind: "triangle", a: prettymap.luaflet.Coord, b: prettymap.luaflet.Coord, c: prettymap.luaflet.Coord, colour: integer }

--- Draws any number of lines, polylines, rectangles, outlines and filled triangles on a canvas. All geometry
--- is given in map coordinates and follows the map when zooming; stroke widths are fixed pixels. It is clipped to the
--- visible part of the map. All points of a polygon should be on the same plane; it is hidden on any other plane.
---
--- "Canvas pixels" are those of the map's whole scrollable canvas, as in `MapView:CoordToCanvas`; the twig's own
--- `canvas` only covers its layer, and is drawn on relative to that.
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
    self.clipsToView = true
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

--- The segments to draw for a polyline, given its points in canvas pixels, extended at the corners.
---@param points number[][]
---@param thickness number
---@return number[][] segments As {ax, ay, bx, by}
local function polyline_segments(points, thickness)
    local segments = {}
    for i = 1, #points - 1 do
        local a, b = points[i], points[i + 1]
        local dx, dy = b[1] - a[1], b[2] - a[2]
        local len = math.sqrt(dx * dx + dy * dy)

        if len > 0 then
            local start = i > 1 and corner_extension(points[i - 1], a, b, thickness) or 0
            local finish = i < #points - 1 and corner_extension(a, b, points[i + 2], thickness) or 0

            segments[#segments + 1] = {
                a[1] - dx / len * start, a[2] - dy / len * start,
                b[1] + dx / len * finish, b[2] + dy / len * finish,
            }
        end
    end
    return segments
end

---@alias prettymap.ClipRect { minX: number, minY: number, maxX: number, maxY: number }

--- The part of the segment inside the rectangle (Liang-Barsky), or nil if none.
---@param ax number
---@param ay number
---@param bx number
---@param by number
---@param clip prettymap.ClipRect
---@return number?, number?, number?, number?
local function clip_segment(ax, ay, bx, by, clip)
    local dx, dy = bx - ax, by - ay
    local t0, t1 = 0, 1

    -- Narrows [t0, t1] to where `p * t <= q` holds; false once it's empty.
    local function narrow(p, q)
        if p == 0 then return q >= 0 end
        local t = q / p
        if p < 0 then
            if t > t1 then return false end
            if t > t0 then t0 = t end
        else
            if t < t0 then return false end
            if t < t1 then t1 = t end
        end
        return true
    end

    if narrow(-dx, ax - clip.minX) and narrow(dx, clip.maxX - ax)
        and narrow(-dy, ay - clip.minY) and narrow(dy, clip.maxY - ay) then
        return ax + t0 * dx, ay + t0 * dy, ax + t1 * dx, ay + t1 * dy
    end
    return nil
end

--- Clips a convex polygon at one edge of the clip rectangle (one step of Sutherland-Hodgman).
---@param points number[][]
---@param axis 1|2 1 for x, 2 for y.
---@param limit number
---@param is_max boolean Whether the limit is a maximum, keeping the part up to it, instead of a minimum.
---@return number[][]
local function clip_edge(points, axis, limit, is_max)
    local function inside(point)
        if is_max then return point[axis] <= limit end
        return point[axis] >= limit
    end

    local result = {}
    for i = 1, #points do
        local a, b = points[(i - 2) % #points + 1], points[i]
        if inside(a) ~= inside(b) then
            local t = (limit - a[axis]) / (b[axis] - a[axis])
            result[#result + 1] = { a[1] + t * (b[1] - a[1]), a[2] + t * (b[2] - a[2]) }
        end
        if inside(b) then result[#result + 1] = b end
    end
    return result
end

--- The part of a convex polygon inside the rectangle; empty if none.
---@param points number[][]
---@param clip prettymap.ClipRect
---@return number[][]
local function clip_polygon(points, clip)
    points = clip_edge(points, 1, clip.minX, false)
    points = clip_edge(points, 1, clip.maxX, true)
    points = clip_edge(points, 2, clip.minY, false)
    return clip_edge(points, 2, clip.maxY, true)
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

--- The visible part of the map in canvas pixels.
---@param map prettymap.MapView
---@return prettymap.ClipRect
local function view_rect(map)
    local x, y = map.viewport.scrollX or 0, map.viewport.scrollY or 0
    return { minX = x, minY = y, maxX = x + map.viewportWidth, maxY = y + map.viewportHeight }
end

--- The rectangle shrunk by `inset` on every side.
---@param rect prettymap.ClipRect
---@param inset number
---@return prettymap.ClipRect
local function shrink(rect, inset)
    return { minX = rect.minX + inset, minY = rect.minY + inset, maxX = rect.maxX - inset, maxY = rect.maxY - inset }
end

--- Converts all points to canvas pixels, clips the geometry to the visible part of the map and redraws, so nothing is
--- drawn outside the map. The layer covers just the bounding box of what is left (plus the line thickness); it is
--- hidden when nothing is left or when any point is off the current plane.
---@param map prettymap.MapView
function PolygonTwig:_Layout(map)
    local component, canvas = self.component, self.canvas
    canvas:Clear()

    local view = view_rect(map)

    -- The clipped primitives in canvas pixels, still to be drawn: { kind, coordinates..., thickness?, colour }.
    local clipped = {}
    local function line(ax, ay, bx, by, thickness, colour)
        -- Shrink by half the thickness, to keep the whole line inside the map.
        ax, ay, bx, by = clip_segment(ax, ay, bx, by, shrink(view, thickness / 2))
        if ax then clipped[#clipped + 1] = { "line", ax, ay, bx, by, thickness, colour } end
    end

    for _, p in ipairs(self.primitives) do
        local function resolve(coord)
            local x, y = map:CoordToCanvas(coord)
            return x and { x, y }
        end

        local pts, missing = {}, false
        for i, coord in ipairs(p.points or {}) do
            pts[i] = resolve(coord)
            missing = missing or not pts[i]
        end
        for _, key in ipairs(POINT_KEYS) do
            if p[key] then
                pts[key] = resolve(p[key])
                missing = missing or not pts[key]
            end
        end
        if missing then
            component.hidden = true
            return
        end

        if p.kind == "polyline" then
            for _, seg in ipairs(polyline_segments(pts, p.thickness)) do
                line(seg[1], seg[2], seg[3], seg[4], p.thickness, p.colour)
            end
        elseif p.kind == "line" then
            line(pts.a[1], pts.a[2], pts.b[1], pts.b[2], p.thickness, p.colour)
        elseif p.kind == "triangle" then
            local polygon = clip_polygon({ pts.a, pts.b, pts.c }, view)
            for i = 2, #polygon - 1 do
                clipped[#clipped + 1] = { "triangle", polygon[1], polygon[i], polygon[i + 1], p.colour }
            end
        else
            local minX, maxX = math.min(pts.a[1], pts.b[1]), math.max(pts.a[1], pts.b[1])
            local minY, maxY = math.min(pts.a[2], pts.b[2]), math.max(pts.a[2], pts.b[2])
            if p.kind == "rect" then
                minX, minY = math.max(minX, view.minX), math.max(minY, view.minY)
                maxX, maxY = math.min(maxX, view.maxX), math.min(maxY, view.maxY)
                if minX < maxX and minY < maxY then
                    clipped[#clipped + 1] = { "rect", minX, minY, maxX, maxY, p.colour }
                end
            elseif minX >= view.minX and minY >= view.minY and maxX <= view.maxX and maxY <= view.maxY then
                clipped[#clipped + 1] = { "outline", minX, minY, maxX, maxY, p.thickness, p.colour }
            else
                -- Partly visible: draw the four sides as lines, to clip each one on its own. Move each side in by half
                -- the thickness, to match the full outline, which the canvas draws inwards.
                local half = p.thickness / 2
                local left, top, right, bottom = minX + half, minY + half, maxX - half, maxY - half
                line(minX, top, maxX, top, p.thickness, p.colour)
                line(right, minY, right, maxY, p.thickness, p.colour)
                line(maxX, bottom, minX, bottom, p.thickness, p.colour)
                line(left, maxY, left, minY, p.thickness, p.colour)
            end
        end
    end

    if #clipped == 0 then
        component.hidden = true
        return
    end

    -- The canvas takes integer pixels.
    local function round(value) return math.floor(value + 0.5) end

    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local pad = 1
    local function include(x, y)
        minX, minY = math.min(minX, x), math.min(minY, y)
        maxX, maxY = math.max(maxX, x), math.max(maxY, y)
    end
    for _, item in ipairs(clipped) do
        if item[1] == "triangle" then
            for i = 2, 4 do include(item[i][1], item[i][2]) end
        else
            include(item[2], item[3])
            include(item[4], item[5])
            if item[1] ~= "rect" then pad = math.max(pad, math.ceil(item[6] / 2) + 1) end
        end
    end

    minX, minY, maxX, maxY = round(minX) - pad, round(minY) - pad, round(maxX) + pad, round(maxY) + pad
    component.hidden = false
    component:SetPos(minX, minY)
    component:SetSize(maxX - minX, maxY - minY)
    self.width, self.height = maxX - minX, maxY - minY

    local function x(value) return round(value) - minX end
    local function y(value) return round(value) - minY end

    for _, item in ipairs(clipped) do
        local kind = item[1]
        if kind == "line" then
            canvas:AddLine(x(item[2]), y(item[3]), x(item[4]), y(item[5]), item[6], item[7])
        elseif kind == "triangle" then
            local a, b, c = item[2], item[3], item[4]
            canvas:AddTriangle(x(a[1]), y(a[2]), x(b[1]), y(b[2]), x(c[1]), y(c[2]), item[5])
        elseif kind == "rect" then
            canvas:AddRectangle(x(item[2]), y(item[3]), x(item[4]) - x(item[2]), y(item[5]) - y(item[3]),
                item[6])
        else
            canvas:AddOutline(x(item[2]), y(item[3]), x(item[4]) - x(item[2]), y(item[5]) - y(item[3]),
                item[6], item[7])
        end
    end
end

return PolygonTwig
