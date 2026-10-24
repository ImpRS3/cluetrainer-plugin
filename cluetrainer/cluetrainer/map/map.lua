local prettymap = require("prettymap")
local zyklib = require("zyklib")
local teleport_layer = require("cluetrainer/map/teleport_layer")

local elements = require("prettymap/elements")

-- Mirrors the PrettyUI window chrome, which is not exposed.
local WINDOW_BORDER = 8
local WINDOW_TITLE_HEIGHT = 32

-- Mirrors prettymap's internal zoom steps and world size, which are not exposed.
local ZOOM_LEVELS = { 1, 2, 4, 8, 16, 32, 64, 128, 192 }
local WORLD_WIDTH = 12800
local WORLD_HEIGHT = 12800

---@class ct.GameMap
local GameMap = {}
GameMap.__index = GameMap

function GameMap.new()
  ---@class ct.GameMap
  local self = setmetatable({}, GameMap)

  self.window = prettyui.Window.new(ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA), {
    title = "Clue Trainer",
    x = -210,
    y = -150,
    xAnchor = 0.5,
    yAnchor = 0.5,
    width = 470,
    height = 400,
    minWidth = 320,
    minHeight = 220,
    resizable = true,
    scrollable = false,
    destroyOnClose = true,
    rowBackgroundColours = {
      0x24211EFF,
      0x2E2825FF,
    }
  })

  self.map = prettymap.Map.new(self.window.content, {
    x = 0,
    y = 0,
    width = self.window.contentWidth,
    height = self.window.content.height,
    showFloorControls = true,
    showZoomControls = false,
    showPlayerMarker = false,
    trackPlayer = false,
    onError = function(message)
    end,
  })

  local clueMarker = self.map.overlays:CreateSprite({
    coordinate = CoordGrid.new(0, 50, 46, 0, 56),
    spriteID = id.Sprite.CLUE_SCROLL_ICON,
    size = 32,
  })

  prettyui.Tooltip.attach(clueMarker, clueMarker.parent, {text = "Test"})

  self.map:CentreOn(CoordGrid.new(0, 50, 46, 0, 56))

  -- Window has no resize callback, so hook SetSize, which the resize handle calls on every drag step.
  local windowSetSize = self.window.SetSize

  local game_map_self = self
  self.window.SetSize = function(self, width, height)
    windowSetSize(self, width, height)
    game_map_self.map:SetSize(
      self.root.width - WINDOW_BORDER * 2,
      self.root.height - WINDOW_TITLE_HEIGHT - WINDOW_BORDER
    )
  end

  self.map:AddElement(elements.SpriteElement.new{coordinate = CoordGrid.new(0, 51, 47, 0, 56), spriteID = id.Sprite.CLUE_SCROLL_ICON, size = 8})

  self.map:AddElement(teleport_layer.new())

  -- Example: a filled triangle with a 2px outline, drawn as one polygon element.
  local function fine(x, z) return CoordFine.new(CoordGrid.new(0, 50, 46, x, z), false) end
  local triangle = { fine(2, 2), fine(10, 2), fine(6, 10) }
  self.map:AddElement(
    elements.PolygonElement.new()
      :AddTriangle(triangle[1], triangle[2], triangle[3], 0xFF000080)
      :AddLine(triangle[1], triangle[2], 2, 0xFFFFFFFF)
      :AddLine(triangle[2], triangle[3], 2, 0xFFFFFFFF)
      :AddLine(triangle[3], triangle[1], 2, 0xFFFFFFFF)
  )

  zyklib.lifecycle.shutdown_event:subscribe(function() self.window:Destroy() end)

  return self
end

---comment
---@param bounds {tl:CoordGrid, br:CoordGrid}
function GameMap:fitBounds(bounds)
  local map = self.map
  local x1, z1, level = bounds.tl.x, bounds.tl.z, bounds.tl.level
  local x2, z2 = bounds.br.x, bounds.br.z
  local minX, maxX = math.min(x1, x2), math.max(x1, x2)
  local minZ, maxZ = math.min(z1, z2), math.max(z1, z2)

  local cx, cz = (minX + maxX) // 2, (minZ + maxZ) // 2
  local centre = CoordGrid.new(level, cx // 64, cz // 64, cx % 64, cz % 64)

  map:SetPlane(level)

  local targetScale = math.min(
    map.viewportWidth / (maxX - minX + 1),
    map.viewportHeight / (maxZ - minZ + 1)
  )
  local fitScale = math.min(
    map.viewportWidth / WORLD_WIDTH,
    map.viewportHeight / WORLD_HEIGHT
  )
  local targetMultiplier = targetScale / fitScale

  local nearestIndex, nearestDistance = 1, math.huge
  for index, multiplier in ipairs(ZOOM_LEVELS) do
    local distance = math.abs(multiplier - targetMultiplier)
    if distance < nearestDistance then
      nearestIndex, nearestDistance = index, distance
    end
  end

  map:_ApplyZoom(nearestIndex, nil, nil, targetScale)
  return map:CentreOn(centre)
end

---@type ct.GameMap
local instance = nil

function GameMap.show()
  if not instance then
    instance = GameMap.new()
  end

  instance.window:Show()
end

return GameMap
