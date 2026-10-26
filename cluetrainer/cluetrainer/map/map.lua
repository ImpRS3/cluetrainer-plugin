local prettymap = require("prettymap")
local zyklib = require("zyklib")
local teleport_layer = require("cluetrainer/map/teleport_layer")

local luaflet = require("prettymap/luaflet")

-- Mirrors the PrettyUI window chrome, which is not exposed.
local WINDOW_BORDER = 8
local WINDOW_TITLE_HEIGHT = 32

-- Mirrors prettymap's internal zoom steps and world size, which are not exposed.
local ZOOM_LEVELS = { 1, 2, 4, 8, 16, 32, 64, 128, 256, 512 }
local MIN_ZOOM_INDEX = 4
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
    destroyOnClose = false,
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
    showFloorControls = false,
    showZoomControls = false,
    showPlayerMarker = false,
    trackPlayer = false,
    onError = function(message)
    end,
  })

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

  self.map:AddElement(teleport_layer.new())

  luaflet.twigs.prefab.FloorControlTwig.new({ anchor = "bottomright" }):AddTo(self.map.twigs)
  --luaflet.twigs.prefab.ZoomControlTwig.new({ anchor = "bottomright" }):AddTo(self.map.twigs)

  zyklib.lifecycle.shutdown_event:subscribe(function() self.window:Destroy() end)

  return self
end

---@param bounds ct.Bounds
function GameMap:fitBounds(bounds)
  local rect = bounds:get()
  if rect == nil then return end

  local map = self.map
  local level = rect.level
  -- Bounds uses x/y tile coordinates, the map uses x/z
  local x1, z1 = rect.topleft.x, rect.topleft.y
  local x2, z2 = rect.botright.x, rect.botright.y
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
  targetScale = math.max(
    fitScale * ZOOM_LEVELS[MIN_ZOOM_INDEX],
    math.min(fitScale * ZOOM_LEVELS[#ZOOM_LEVELS], targetScale)
  )
  local targetMultiplier = targetScale / fitScale

  local nearestIndex, nearestDistance = MIN_ZOOM_INDEX, math.huge
  for index = MIN_ZOOM_INDEX, #ZOOM_LEVELS do
    local distance = math.abs(ZOOM_LEVELS[index] - targetMultiplier)
    if distance < nearestDistance then
      nearestIndex, nearestDistance = index, distance
    end
  end

  map:_ApplyZoom(nearestIndex, nil, nil, targetScale)
  return map:CentreOn(centre)
end

---@type ct.GameMap
local instance = nil

--- Ensures the map exists and its window is visible, then returns it.
---@return ct.GameMap
function GameMap.ensure_open()
  if not instance then
    instance = GameMap.new()
  end

  instance.window:Show()
  return instance
end

function GameMap.show()
  GameMap.ensure_open()
end

return GameMap
