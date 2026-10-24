local elements = require("prettymap/elements")

local MARKER_SIZE = 24 -- pixels
local HIGHLIGHT_FACTOR = 1.5
local HOVER_FACTOR = 1.5

--- Sprite per interaction cursor.
--- TODO: fill in the sprite ids; markers of a cursor without a sprite are not drawn.
---@type table<string, CursorId>
local CURSOR_SPRITES = {
  talk = id.Cursor["CURSOR_TALKTO"], -- TODO: sprite id for the talk-to cursor
  search = nil, -- TODO: sprite id for the search cursor
  shovel = nil, -- TODO: sprite id for the dig/shovel cursor
  equip = nil, -- TODO: sprite id for the equip cursor
  emote = nil, -- TODO: sprite id for the emote icon
}

---@class cluetrainer.InteractionMarkerOptions
---@field coordinate CoordGrid
---@field cursor string Key of the cursor sprite: "talk", "search", "shovel", "equip" or "emote".
---@field highlight boolean? Draw larger.

--- A fixed-size icon showing how an entity is interacted with. Grows on hover; attach a tooltip with `SetTooltip`.
---@class cluetrainer.InteractionMarker : prettymap.SpriteElement
---@field cursor string
local InteractionMarker = setmetatable({}, { __index = elements.SpriteElement })
InteractionMarker.__index = InteractionMarker

---@param options cluetrainer.InteractionMarkerOptions
---@return cluetrainer.InteractionMarker
function InteractionMarker.new(options)
  local size = MARKER_SIZE * (options.highlight and HIGHLIGHT_FACTOR or 1)
  local self = setmetatable(elements.SpriteElement.new({
    coordinate = options.coordinate,
    spriteID = config.Cursor.FromID(CURSOR_SPRITES[options.cursor]).spriteID,
    size = size,
    zoomScale = false,
    hoverSize = size * HOVER_FACTOR,
    zLayer = "marker",
  }), InteractionMarker)
  ---@cast self cluetrainer.InteractionMarker
  self.cursor = options.cursor
  return self
end

---@param layer ui.Layer
---@return boolean added
function InteractionMarker:CreateComponent(layer)
  if not self.spriteID then return false end
  return elements.SpriteElement.CreateComponent(self, layer)
end

return InteractionMarker
