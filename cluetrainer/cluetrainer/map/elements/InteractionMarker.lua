local luaflet = require("prettymap/luaflet")

local MARKER_SIZE = 24 -- pixels
local HOVER_FACTOR = 1.5

--- Sprite per interaction cursor.
--- TODO: fill in the sprite ids; markers of a cursor without a sprite are not drawn.
---@type table<string, CursorId>
local CURSOR_SPRITES = {
  talk = id.Cursor["CURSOR_TALKTO"],
  search = id.Cursor["CURSOR_SEARCH"],
  shovel = id.Cursor["CURSOR_DIG"],
  equip = id.Cursor["CURSOR_EQUIP"],
  generic = id.Cursor["CURSOR_DEFAULT"],
}

---@class cluetrainer.InteractionMarkerOptions
---@field coordinate prettymap.luaflet.Coord
---@field cursor string Key of the cursor sprite: "talk", "search", "shovel", "equip" or "emote".

--- A fixed-size icon showing how an entity is interacted with. Grows on hover; attach a tooltip with `SetTooltip`.
---@class cluetrainer.InteractionMarker : prettymap.luaflet.SpriteTwig
local InteractionMarker = setmetatable({}, { __index = luaflet.twigs.SpriteTwig })
InteractionMarker.__index = InteractionMarker

---@param options cluetrainer.InteractionMarkerOptions
---@return cluetrainer.InteractionMarker
function InteractionMarker.new(options)
  local size = MARKER_SIZE

  local self = setmetatable(luaflet.twigs.SpriteTwig.new({
    coordinate = options.coordinate,
    spriteID = config.Cursor.FromID(CURSOR_SPRITES[options.cursor] or CURSOR_SPRITES.generic).spriteID,
    size = size,
    zoomScale = false,
    hoverSize = size * HOVER_FACTOR,
    zLayer = "marker",
  }), InteractionMarker)
  ---@cast self cluetrainer.InteractionMarker
  return self
end

---@param layer ui.Layer
---@return boolean added
function InteractionMarker:CreateComponent(layer)
  if not self.spriteID then return false end
  return luaflet.twigs.SpriteTwig.CreateComponent(self, layer)
end

return InteractionMarker
