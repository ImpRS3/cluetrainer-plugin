---@class Shape
---@field positions Vector3[]
---@field colors integer[]
---@field triangleIndices integer[]
---@field lineIndices integer[]
local Shape = {}

---Create a new Shape instance
---@param positions Vector3[]
---@param colors integer[]
---@param triangleIndices integer[]
---@param lineIndices integer[]
---@return Shape
function Shape.new(positions, colors, triangleIndices, lineIndices)
    return {
        positions = positions,
        colors = colors,
        triangleIndices = triangleIndices,
        lineIndices = lineIndices
    }
end

return Shape
