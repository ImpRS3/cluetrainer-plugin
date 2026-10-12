local PathMesh           = require "cluetrainer/model/PathMesh"
local TerrainHighlight   = require "zyklib/highlights/TerrainHighlight"
local api_util           = require "zyklib/api_util"
local coordinate_adaptor = require "cluetrainer/model_shared/coordinate_adaptor"
local Path               = require "cluetrainer/model_shared/path"
local Navigator          = require "cluetrainer/solving/navigator"
local array              = require "zyklib/array"
local zyklib             = require "zyklib"

---@class ScanTreeSolver
---@field method Method.ScanTree
---@field active_node ScanTree.ScanTreeNode?
---@field target_region_highlight zyklib.Highlight?
---@field navigator Navigator
local ScanTreeSolver     = {}
ScanTreeSolver.__index   = ScanTreeSolver

---@param method Method.ScanTree
function ScanTreeSolver.new(method)
  local self = setmetatable({}, ScanTreeSolver)

  self.method = method
  self.navigator = Navigator.new()

  zyklib.game_events.native.KeyUp:subscribe(function(event)
    if event.modifiers & ModifierKey.SHIFT ~= 0 and event.gameKey == GameKey._1 then
      self:setNode(array.find(self.active_node.children, function(value)
        return value.key.pulse == 1
      end).value)
    end
    if event.modifiers & ModifierKey.SHIFT ~= 0 and event.gameKey == GameKey._2 then
      self:setNode(array.find(self.active_node.children, function(value)
        return value.key.pulse == 2
      end).value)
    end
  end)

  return self
end


---@param node ScanTree.ScanTreeNode
function ScanTreeSolver:setNode(node)
  if node == self.active_node or node == nil then return end

  self.active_node = node

  if self.target_region_highlight ~= nil then
    self.target_region_highlight:deactivate()
    self.target_region_highlight = nil
  end

  local target_area = (self.active_node.region and self.active_node.region.area) or Path.ends_up(self.active_node.path)

  if target_area ~= nil then
    self.target_region_highlight = TerrainHighlight.new(
      api_util.map_square_rect_from_tiles({ coordinate_adaptor.tile_coordinates_to_coord_grid(target_area.origin) }),
      function()
        return PathMesh.drawTileArea(
          target_area,
          0x00FF00FF,
          0x00FF0080
        ):translate(Vector3.new(0, 32, 0)):shapeData()
      end
    ):activate()
  end

  self.navigator:set(node.path)
end

function ScanTreeSolver:start()
  self:setNode(self.method.tree.root)
  return self
end

function ScanTreeSolver:stop()
  if self.target_region_highlight ~= nil then
    self.target_region_highlight:deactivate()
    self.target_region_highlight = nil
  end

  self.navigator:destroy()

  return self
end

return ScanTreeSolver
