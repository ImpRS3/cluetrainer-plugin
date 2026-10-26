---@alias ct.interfaces.cluestate.ActionState "incomplete" | "complete" | "blocked"

-- TODO: placeholder sprites, replace with proper checkbox/cross icons.
local STATE_SPRITES = {
  incomplete = id.Sprite.RS3_BTN_INCREASE_ACTIVE,
  complete = id.Sprite.RS3_ICON_DIRECTION_ASCEND_32PX_2,
  blocked = id.Sprite.RS3_BTN_DECREASE_DISABLED,
}

local STATE_ALPHA = {
  incomplete = 1.0,
  complete = 0.5,
  blocked = 0.35,
}

---@class ct.interfaces.cluestate.ClueStateAction
---@field sprite ui.Sprite
---@field text ui.Text
---@field state ct.interfaces.cluestate.ActionState
local ClueStateAction = {}
ClueStateAction.__index = ClueStateAction

---@param sprite ui.Sprite
---@param text ui.Text
---@return ct.interfaces.cluestate.ClueStateAction
function ClueStateAction.new(sprite, text)
  ---@class ct.interfaces.cluestate.ClueStateAction
  local self = setmetatable({}, ClueStateAction)

  self.sprite = sprite
  self.text = text
  self:setState("incomplete")

  return self
end

---@param state ct.interfaces.cluestate.ActionState
function ClueStateAction:setState(state)
  self.state = state
  self.sprite.spriteID = STATE_SPRITES[state]
  self.sprite.alpha = STATE_ALPHA[state]
  self.text.alpha = STATE_ALPHA[state]
end

return ClueStateAction
