--- Places the icon of an item (an Obj, rendered by the game from its model) so the item sits in the middle of a
--- square box. Sprites are plain images and don't need this.
---
--- The game renders every item into a 36×32 canvas, drawn around the point (16,15) rather than the canvas centre.
--- Placed in a square box as is, the canvas is stretched and the item lands left of and above the centre. The anchor
--- was measured in game with a probe and is the same for every item.
local item_icon = {}

local CANVAS_WIDTH, CANVAS_HEIGHT = 36, 32
local ANCHOR_X, ANCHOR_Y = 16, 15

-- Fractions of the box size: the canvas is scaled to the box's width so it keeps its proportions, and moved so the
-- anchor lands on the box centre. The right edge sticks out past the box, where the canvas is empty.
local HEIGHT = CANVAS_HEIGHT / CANVAS_WIDTH
local SHIFT_X = 0.5 - ANCHOR_X / CANVAS_WIDTH
local SHIFT_Y = 0.5 - ANCHOR_Y / CANVAS_WIDTH

---@param value number
---@return integer
local function round(value)
  return math.floor(value + 0.5)
end

--- The rectangle to draw an item icon in, for a square box.
---@param x number Left of the box in pixels
---@param y number Top of the box in pixels
---@param size number Width and height of the box in pixels
---@return integer x
---@return integer y
---@return integer width
---@return integer height
function item_icon.rect(x, y, size)
  return x + round(size * SHIFT_X), y + round(size * SHIFT_Y), size, round(size * HEIGHT)
end

--- Places `sprite` in a square box.
---@param sprite ui.Sprite
---@param x number Left of the box in pixels
---@param y number Top of the box in pixels
---@param size number Width and height of the box in pixels
function item_icon.place(sprite, x, y, size)
  local left, top, width, height = item_icon.rect(x, y, size)
  sprite:SetSize(width, height)
  sprite:SetPos(left, top)
end

--- Places `sprite` in its parent, which is the square box. Relative, so it follows the parent when that is resized.
---@param sprite ui.Sprite
function item_icon.fill(sprite)
  sprite:SetSize(0, 0, 1.0, HEIGHT)
  sprite:SetPos(0, 0, SHIFT_X, SHIFT_Y)
end

return item_icon
