-- PdbRegion.lua
local AllowedMoveTable          = require("cluetrainer/puzzles/sliders/pdb/AllowedMoveTable")
local Region                    = require("cluetrainer/puzzles/sliders/pdb/Region")
local Indexing                  = require("cluetrainer/puzzles/sliders/pdb/RegionIndexing")

---@class cluetrainer.sliders.pdb.RegionDistanceTable
---@field region cluetrainer.sliders.pdb.RegionDescription
---@field indexing cluetrainer.sliders.pdb.RegionIndexing
---@field underlying_data string
---@field data_offset integer
---@field byte_size integer
---@field real_data_offset integer
---@field description cluetrainer.sliders.pdb.RegionDescription
---@field move_table cluetrainer.sliders.pdb.AllowedMoveTable
local RegionDistanceTable       = {}
RegionDistanceTable.__index     = RegionDistanceTable

local Description               = {}
RegionDistanceTable.Description = Description

Description.SERIALIZED_SIZE     = 26

function Description.serialize(description)
  local bytes = {
    string.char(description.multitile and 1 or 0)
  }

  for i = 1, 25 do
    bytes[i + 1] = string.char(description.region[i])
  end

  return table.concat(bytes)
end

function Description.deserialize(data, offset)
  offset = offset or 0

  log("length: " .. #data)
  log("offset: " .. offset)
  log(data:byte(1, 30))

  local multitile = data:byte(offset + 1) == 1
  local region = {}

  for i = 1, 25 do
    log("deserializing byte: " .. data:byte(offset + 1 + i) .. "@" .. i)
    region[i] = data:byte(offset + 1 + i)
  end

  log("deserialized region: " .. table.concat(region, ", "))

  return {
    multitile = multitile,
    region = region
  }
end

function Description.byteSize(indexing)
  return Description.SERIALIZED_SIZE
      + math.ceil(indexing.size / 4)
end

---Creates a new RegionDistanceTable instance from the given data and offset.
---@param data string
---@param offset integer 0-based offset where the data starts
---@return cluetrainer.sliders.pdb.RegionDistanceTable
function RegionDistanceTable.new(data, offset)
  local self = setmetatable({}, RegionDistanceTable)

  self.underlying_data = data
  self.data_offset = offset
  self.description = Description.deserialize(data, offset)

  self.indexing = Indexing.new(self.description.region)
  self.move_table = AllowedMoveTable.new(
    self.description.region,
    self.description.multitile,
    false
  )

  self.byte_size = Description.byteSize(self.indexing)
  self.real_data_offset = offset + Description.SERIALIZED_SIZE

  return self
end

function RegionDistanceTable:getDistance(state)
  return self:getDistanceByIndex(
    self.indexing:stateIndex(state)
  )
end

function RegionDistanceTable:getDistanceByIndex(index)
  local byte_index = self.real_data_offset
      + (index // 4) + 1

  local byte = self.underlying_data:byte(byte_index)
  local shift = 2 * (index % 4)

  return (byte >> shift) & 0x03
end

-- Region graph

local RegionGraph = {}
RegionGraph.__index = RegionGraph
RegionDistanceTable.RegionGraph = RegionGraph

function RegionGraph.new(databases, include_reflected_nodes)
  local self = setmetatable({}, RegionGraph)
  local nodes = {}

  for i, db in ipairs(databases) do
    local region = db.description.region

    nodes[#nodes + 1] = {
      effective_region = region,
      table = db,
      reflected = false,
      children = {},
      name = tostring(i - 1)
    }

    if include_reflected_nodes then
      local reflected = Region.reflect(region)
      local exists = false

      for _, node in ipairs(nodes) do
        if Region.equals(
              node.effective_region, reflected
            ) then
          exists = true
          break
        end
      end

      if not exists then
        nodes[#nodes + 1] = {
          effective_region = reflected,
          table = db,
          reflected = true,
          children = {},
          name = tostring(i - 1) .. "R"
        }
      end
    end
  end

  for _, parent in ipairs(nodes) do
    for _, child in ipairs(nodes) do
      if parent ~= child and Region.isChild(
            parent.effective_region,
            child.effective_region
          ) then
        parent.children[#parent.children + 1] = child
      end
    end
  end

  self.nodes = nodes
  self.entry_nodes = {}

  for _, node in ipairs(nodes) do
    if Region.isFirst(node.effective_region) then
      self.entry_nodes[#self.entry_nodes + 1] = node
    end
  end

  return self
end

function RegionGraph:getEntryPoints()
  return self.entry_nodes
end

-- Ring buffer queue.
-- Stores independent state copies.


return RegionDistanceTable
