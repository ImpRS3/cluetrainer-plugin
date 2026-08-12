---@alias ColorRGBA integer

---@class Mesh.Vertex
---@field pos Vector3
---@field color_rgba ColorRGBA

---@class MutableMesh.VertexRef
---@field vertex Mesh.Vertex
---@field index integer

---@class MutableMesh
---@field private vertices Mesh.Vertex[]
---@field private triangle_indices integer[]
---@field private line_indices integer[]
local MutableMesh = {}
MutableMesh.__index = MutableMesh

---@return MutableMesh
function MutableMesh.new()
    return setmetatable({
        vertices = {},
        triangle_indices = {},
        line_indices = {},
    }, MutableMesh)
end

---@return integer
function MutableMesh:vertex_count()
    return #self.vertices
end

---@return integer
function MutableMesh:triangle_count()
    return #self.triangle_indices // 3
end

---@return integer
function MutableMesh:line_count()
    return #self.line_indices // 2
end

---@param pos Vector3
---@param color? ColorRGBA
---@return MutableMesh.VertexRef
function MutableMesh:createVertex(pos, color)
    ---@type Mesh.Vertex
    local vertex = {
        pos = pos,
        color_rgba = color or 0xFFFFFFFF,
    }

    self.vertices[#self.vertices + 1] = vertex

    return {
        -- Mesh indices remain zero-based.
        index = #self.vertices - 1,
        vertex = vertex,
    }
end

---@param v0 MutableMesh.VertexRef
---@param v1 MutableMesh.VertexRef
---@param v2 MutableMesh.VertexRef
function MutableMesh:triangle(v0, v1, v2)
    local indices = self.triangle_indices

    indices[#indices + 1] = v0.index
    indices[#indices + 1] = v1.index
    indices[#indices + 1] = v2.index

    indices[#indices + 1] = v0.index
    indices[#indices + 1] = v2.index
    indices[#indices + 1] = v1.index
end

---@param v0 MutableMesh.VertexRef
---@param v1 MutableMesh.VertexRef
---@param v2 MutableMesh.VertexRef
---@param v3 MutableMesh.VertexRef
function MutableMesh:quad(v0, v1, v2, v3)
    local indices = self.triangle_indices

    local function push(...)
        for i = 1, select("#", ...) do
            indices[#indices + 1] = select(i, ...)
        end
    end

    push(v0.index, v1.index, v2.index, v0.index, v2.index, v3.index)
    push(v0.index, v2.index, v1.index, v0.index, v3.index, v2.index)
end

---@param offset Vector3
---@return self
function MutableMesh:translate(offset)
    for _, vertex in ipairs(self.vertices) do
        vertex.pos.x = vertex.pos.x + offset.x
        vertex.pos.y = vertex.pos.y + offset.y
        vertex.pos.z = vertex.pos.z + offset.z
    end

    return self
end

---@param factor number
---@return self
function MutableMesh:scale(factor)
    for _, vertex in ipairs(self.vertices) do
        vertex.pos.x = vertex.pos.x * factor
        vertex.pos.y = vertex.pos.y * factor
        vertex.pos.z = vertex.pos.z * factor
    end

    return self
end

---@param color ColorRGBA
---@return self
function MutableMesh:recolor(color)
    for _, vertex in ipairs(self.vertices) do
        vertex.color_rgba = color
    end

    return self
end

---Turns the mesh inside out by reversing the winding order of all triangles.
---@return self 
function MutableMesh:inside_out()
    local indices = self.triangle_indices

    for i = 1, #indices, 3 do
        indices[i + 1], indices[i + 2] = indices[i + 2], indices[i + 1]
    end

    return self
end

---@param ... MutableMesh
---@return self
function MutableMesh:add(...)
    for i = 1, select("#", ...) do
        local mesh = select(i, ...)
        local vertex_offset = #self.vertices

        for _, vertex in ipairs(mesh.vertices) do
            self.vertices[#self.vertices + 1] = vertex
        end

        for _, index in ipairs(mesh.triangle_indices) do
            self.triangle_indices[#self.triangle_indices + 1] = index + vertex_offset
        end
    end

    return self
end

---@return ShapeData
function MutableMesh:shapeData()
    local positions = {}
    local colors = {}
    local tris = {}
    local lines = {}

    for _, vertex in ipairs(self.vertices) do
        table.insert(positions, Vector3.new(vertex.pos.x, vertex.pos.y, vertex.pos.z))
        table.insert(colors, vertex.color_rgba)
    end

    for i, index in ipairs(self.triangle_indices) do
        table.insert(tris, index)
    end

    for i, index in ipairs(self.line_indices) do
        table.insert(lines, index)
    end

    local shape = ShapeData.new()

    shape.positions = positions
    shape.rgba = colors
    shape.tris = tris
    shape.lines = lines

    return shape
end

function MutableMesh.cube()
    local mesh = MutableMesh.new()

    local vertices = {
        { pos = Vector3.new(0, 0, 0), color_rgba = 0xFFFFFFFF },
        { pos = Vector3.new(1, 0, 0), color_rgba = 0xFFFFFFFF },
        { pos = Vector3.new(1, 1, 0), color_rgba = 0xFFFFFFFF },
        { pos = Vector3.new(0, 1, 0), color_rgba = 0xFFFFFFFF },
        { pos = Vector3.new(0, 0, 1), color_rgba = 0xFFFFFFFF },
        { pos = Vector3.new(1, 0, 1), color_rgba = 0xFFFFFFFF },
        { pos = Vector3.new(1, 1, 1), color_rgba = 0xFFFFFFFF },
        { pos = Vector3.new(0, 1, 1), color_rgba = 0xFFFFFFFF },
    }

    local triangle_indices = {
        0, 1, 2, 2, 3, 0,
        4, 5, 6, 6, 7, 4,
        0, 1, 5, 5, 4, 0,
        2, 3, 7, 7, 6, 2,
        0, 3, 7, 7, 4, 0,
        1, 2, 6, 6, 5, 1,
    }

    mesh.vertices = vertices
    mesh.triangle_indices = triangle_indices

    return mesh
end

return MutableMesh
