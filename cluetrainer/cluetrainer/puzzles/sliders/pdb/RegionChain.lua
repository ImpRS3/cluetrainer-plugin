local RegionDistanceTable        = require("cluetrainer/puzzles/sliders/pdb/PdbRegion")
local Region                     = require("cluetrainer/puzzles/sliders/pdb/Region")

---@class cluetrainer.sliders.pdb.RegionChainDistanceTable
---@field data string
---@field tables cluetrainer.sliders.pdb.RegionDistanceTable[]
local RegionChainDistanceTable   = {}
RegionChainDistanceTable.__index = RegionChainDistanceTable

---Parses the given data into a list of RegionDistanceTable instances.
---@param data string
---@return cluetrainer.sliders.pdb.RegionDistanceTable[]
local function parseTables(data)
  local tables = {}

  local offset = 0

  while offset < #data do
    local region = RegionDistanceTable.new(data, offset)

    tables[#tables + 1] = region
    offset = offset + region.byte_size
  end

  return tables
end

local array = require("zyklib/array")

---@class cluetrainer.sliders.pdb.RegionGraph.Node
---@field reflected boolean
---@field effective_region cluetrainer.sliders.pdb.Region
---@field table cluetrainer.sliders.pdb.RegionDistanceTable
---@field children cluetrainer.sliders.pdb.RegionGraph.Node[]

---@class cluetrainer.sliders.pdb.RegionGraph
---@field private nodes cluetrainer.sliders.pdb.RegionGraph.Node[]
---@field private entry_nodes cluetrainer.sliders.pdb.RegionGraph.Node[]
local RegionGraph = {}
RegionGraph.__index = RegionGraph

---@param databases cluetrainer.sliders.pdb.RegionDistanceTable[]
---@param include_reflected_nodes boolean
---@return cluetrainer.sliders.pdb.RegionGraph
function RegionGraph.new(databases, include_reflected_nodes)
  local self = setmetatable({}, RegionGraph)

  local nodes = {}

  for _, tbl in ipairs(databases) do
    nodes[#nodes + 1] = {
      effective_region = tbl.description.region,
      table = tbl,
      reflected = false,
      children = {},
    }

    if include_reflected_nodes then
      local reflected = Region.reflect(tbl.description.region)

      if not array.exists(nodes, function(node)
            return Region.equals(node.effective_region, reflected)
          end) then
        nodes[#nodes + 1] = {
          effective_region = reflected,
          table = tbl,
          reflected = true,
          children = {},
        }
      end
    end
  end

  self.nodes = nodes

  for _, parent in ipairs(nodes) do
    for _, child in ipairs(nodes) do
      if parent ~= child
          and Region.isChild(parent.effective_region, child.effective_region)
      then
        parent.children[#parent.children + 1] = child
      end
    end
  end

  self.entry_nodes = array.filter(nodes, function(node)
    return Region.isFirst(node.effective_region)
  end)

  return self
end

---@return RegionGraph.Node[]
function RegionGraph:getEntryPoints()
  return self.entry_nodes
end

return RegionGraph
