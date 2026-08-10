local Mesh = require("model/MyMesh")
local lua_util = require("util/lua_util")

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

---@param pos Vector3
---@param color? ColorRGBA
---@return MutableMesh.VertexRef
function MutableMesh:createVertex(pos, color)
    ---@type Mesh.Vertex
    local vertex = {
        pos = pos,
        color_rgba = color or { 255, 255, 255, 255 },
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

---@return Mesh
function MutableMesh:finalize()
    return Mesh.new(
        lua_util.shallow_copy(self.vertices),
        lua_util.shallow_copy(self.triangle_indices),
        lua_util.shallow_copy(self.line_indices)
    )
end

return MutableMesh
