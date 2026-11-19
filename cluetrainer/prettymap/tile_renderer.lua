local WorldMap = require("prettymap/world_map")
local Resources = require("prettymap/resources")
local Helpers = require("prettymap/map_helpers")

---@class prettymap.tile_renderer
local TileRenderer = {}
local clamp = Helpers.Clamp
local rounded = Helpers.Rounded
local FLOOR_DIVIDER_COLOUR = 0x00000080

function TileRenderer:_DestroyTileSet(tileSet)
    for key, tile in pairs(tileSet) do
        tile.sprite:Destroy()
        Resources.Unload(tile.resource)
        tileSet[key] = nil
    end
end

function TileRenderer:_DestroyTiles()
    TileRenderer._DestroyTileSet(self, self.tileSprites)
    TileRenderer._DestroyTileSet(self, self.iconTileSprites)
    self.tileViewportKey = nil
end

function TileRenderer:_TileBounds(level, atlasX, atlasZ)
    local originX = level.originX or 0
    local originZ = level.originZ or 0
    local left = rounded(self.mapOffsetX + (originX + atlasX * level.span) * self.currentScale)
    local right = rounded(self.mapOffsetX + (originX + (atlasX + 1) * level.span) * self.currentScale)
    local top = rounded(self.mapOffsetY
        + (WorldMap.maxZ - originZ - (atlasZ + 1) * level.span) * self.currentScale)
    local bottom = rounded(self.mapOffsetY
        + (WorldMap.maxZ - originZ - atlasZ * level.span) * self.currentScale)
    return left, top, right - left, bottom - top
end

function TileRenderer:_RefreshTiles()
    if not self.viewport or not self.currentScale then return end
    local level = WorldMap.LevelForScale(self.currentScale)
    if self.tileLevel ~= level then
        TileRenderer._DestroyTiles(self)
        self.tileLevel = level
    end

    -- One layer per floor, created in floor order, so that upper floors always
    -- render above lower ones regardless of when their sprites are loaded.
    -- A translucent divider follows each floor layer and is only shown below the active floor.
    if not self.tileFloorLayers then
        self.tileFloorLayers = {}
        self.tileFloorDividers = {}
    end
    for floor = 0, 3 do
        local layer = self.tileFloorLayers[floor]
        if not layer then
            layer = ui.Layer.new(self.tileLayer)
            layer.clickthrough = true
            self.tileFloorLayers[floor] = layer
            if floor < 3 then
                local divider = ui.Rectangle.new(self.tileLayer)
                divider.fill = true
                divider.rgba = FLOOR_DIVIDER_COLOUR
                divider.clickthrough = true
                self.tileFloorDividers[floor] = divider
            end
        end
        layer:SetSize(self.contentWidth, self.contentHeight)
        local divider = self.tileFloorDividers[floor]
        if divider then
            divider:SetSize(self.contentWidth, self.contentHeight)
            divider.hidden = floor >= self.plane
        end
    end

    local scrollX = self.viewport.scrollX or 0
    local scrollY = self.viewport.scrollY or 0
    local worldLeft = clamp((scrollX - self.mapOffsetX) / self.currentScale, 0, WorldMap.maxX)
    local worldRight = clamp(
        (scrollX + self.viewportWidth - self.mapOffsetX) / self.currentScale,
        0,
        WorldMap.maxX
    )
    local worldNorth = clamp(
        WorldMap.maxZ - (scrollY - self.mapOffsetY) / self.currentScale,
        WorldMap.minZ,
        WorldMap.maxZ
    )
    local worldSouth = clamp(
        WorldMap.maxZ - (scrollY + self.viewportHeight - self.mapOffsetY) / self.currentScale,
        WorldMap.minZ,
        WorldMap.maxZ
    )
    local originX = level.originX or 0
    local minAtlasX = math.floor((worldLeft - originX) / level.span)
    local maxAtlasX = math.floor((math.max(worldLeft, worldRight - 0.001) - originX) / level.span)
    local originZ = level.originZ or 0
    local minAtlasZ = math.floor((worldSouth - originZ) / level.span)
    local maxAtlasZ = math.floor((math.max(worldSouth, worldNorth - 0.001) - originZ) / level.span)
    local viewportKey = string.format("%s:%d:%s:%d:%d:%d:%d:%s", level.folder,
        self.plane, tostring(self.currentScale), minAtlasX, maxAtlasX, minAtlasZ,
        maxAtlasZ, tostring(self.showIcons))
    -- A completed reconciliation is cacheable even when no image exists.
    if self.tileViewportKey == viewportKey then return end
    self.tileViewportKey = viewportKey
    self.tileReconciliationCount = (self.tileReconciliationCount or 0) + 1

    local required = {}
    local requiredIcons = {}
    local loadFailure = nil

    local function refreshTile(floor, tileSet, availability, resourceFolder, keyPrefix, atlasX, atlasZ)
        local availabilityKey = string.format("%d:%d:%d", floor, atlasX, atlasZ)
        local availableResource = availability and availability[availabilityKey]
        if not availableResource then return end
        -- Floors that reuse the image of the floor below add nothing on top of it.
        if floor > 0 and availability[string.format("%d:%d:%d", floor - 1, atlasX, atlasZ)]
            == availableResource then
            return
        end
        local key = keyPrefix .. level.folder .. ":" .. availabilityKey
        local requiredSet = tileSet == self.tileSprites and required or requiredIcons
        requiredSet[key] = true
        local tile = tileSet[key]
        if tile then
            -- Kept through a zoom or plane change: placed again for the current scale.
            local x, y, width, height = TileRenderer._TileBounds(self, level, atlasX, atlasZ)
            tile.sprite:SetPos(x, y)
            tile.sprite:SetSize(width, height)
        else
            local filename
            if type(availableResource) == "string" then
                filename = availableResource
            elseif tileSet == self.iconTileSprites then
                filename = string.format("icon_%d_%d_%d.png", floor, atlasX, atlasZ)
            else
                filename = string.format("%d_%d_%d.png", floor, atlasX, atlasZ)
            end
            local resourceName = string.format("%s/%s/%s", resourceFolder, level.folder, filename)
            local resource, resourceError = Resources.Image(resourceName)
            if not resource and not loadFailure then
                loadFailure = resourceName .. ": " .. (resourceError or "Resource unavailable.")
            end
            if resource then
                local parent = tileSet == self.iconTileSprites
                    and self.iconTileLayer or self.tileFloorLayers[floor]
                local sprite = ui.Sprite.new(parent)
                sprite.sprite = resource
                sprite.clickthrough = true
                local x, y, width, height = TileRenderer._TileBounds(
                    self, level, atlasX, atlasZ)
                sprite:SetPos(x, y)
                sprite:SetSize(width, height)
                tile = { sprite = sprite, resource = resource }
                tileSet[key] = tile
            end
        end
    end

    -- Every floor up to and including the current one is drawn, lowest first.
    for atlasZ = minAtlasZ, maxAtlasZ do
        for atlasX = minAtlasX, maxAtlasX do
            for floor = 0, self.plane do
                refreshTile(floor, self.tileSprites, level.available, "prettymap/maps", "",
                    atlasX, atlasZ)
            end
        end
    end

    for key, tile in pairs(self.tileSprites) do
        if not required[key] then
            tile.sprite:Destroy()
            Resources.Unload(tile.resource)
            self.tileSprites[key] = nil
        end
    end
    for key, tile in pairs(self.iconTileSprites) do
        if not requiredIcons[key] then
            tile.sprite:Destroy()
            Resources.Unload(tile.resource)
            self.iconTileSprites[key] = nil
        end
    end

    self.imageAvailable = next(self.tileSprites) ~= nil
    if not self.imageAvailable then
        local failure = loadFailure and "resource" or "missing"
        if self.reportedMissingImage ~= failure then
            self.reportedMissingImage = failure
            self:_ReportError(loadFailure
                or "No rendered map tiles are available in this area and floor.", true)
        end
    elseif self.imageAvailable then
        self.reportedMissingImage = false
    end
end

function TileRenderer:SetIconsVisible(visible)
    visible = visible == true
    if self.showIcons == visible then return end
    self.showIcons = visible
    self.tileViewportKey = nil
    if not visible then
        TileRenderer._DestroyTileSet(self, self.iconTileSprites)
    else
        self:_RefreshView("tile_contents")
    end
end

function TileRenderer:GetIconsVisible()
    return self.showIcons
end

return TileRenderer
