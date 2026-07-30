local Shape = require("model/Shape")

local Mesh = {}
Mesh.__index = Mesh

---@class ColorRGBA
---@field r integer
---@field g integer
---@field b integer
---@field a integer

---@class Mesh.Vertex
---@field pos Vector3
---@field color_rgba ColorRGBA

---@class Mesh
---@field vertices Mesh.Vertex[]
---@field triangles integer[]
---@field lines integer[]
---@field private shape_data Shape?

---@param vertices Mesh.Vertex[]
---@param triangles integer[]
---@param lines integer[]
---@return Mesh
function Mesh.new(vertices, triangles, lines)
    return setmetatable({
        vertices = vertices or {},
        triangles = triangles or {},
        lines = lines or {},
        shape_data = nil
    }, Mesh)
end

---@return Shape
function Mesh:shapeData()
    if not self.shape_data then
        local positions = {}
        local colors = {}
        local tris = {}
        local lines = {}

        for _, vertex in ipairs(self.vertices) do
            table.insert(positions, Vector3.new(vertex.pos.x, vertex.pos.y, vertex.pos.z))
            local color = vertex.color_rgba
            local color_int = (color.r << 24) | (color.g << 16) | (color.b << 8) | color.a
            table.insert(colors, color_int)
        end

        for i, index in ipairs(self.triangles) do
            table.insert(tris, index)
        end

        for i, index in ipairs(self.lines) do
            table.insert(lines, index)
        end

        self.shape_data = Shape.new(positions, colors, tris, lines)
    end

    return self.shape_data
end

return Mesh