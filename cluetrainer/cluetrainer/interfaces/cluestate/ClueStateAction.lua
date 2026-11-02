---@alias ct.interfaces.cluestate.ActionState "incomplete" | "complete"

local STATE_ALPHA = {
  incomplete = 1.0,
  complete = 0.5,
}

local ROW_HEIGHT = 24

---Interface for a single line in the clue state panel.
---State is always stored in the object and only applied to components once they have been constructed.
---Implementations add their components to the PrettyUI view (and thereby its flow rows, which receive the
---alternating backgrounds) and override `setText`, `_construct`, `_apply` and `destroy`.
---@class ct.interfaces.cluestate.ClueStateAction
---@field state ct.interfaces.cluestate.ActionState
---@field constructed boolean
local ClueStateAction = {}
ClueStateAction.__index = ClueStateAction

---@protected
function ClueStateAction:_init()
  self.state = "incomplete"
  self.constructed = false
end

---Creates the components of this action in the given view and applies the stored state to them.
---@param view prettyui.core.View
function ClueStateAction:construct(view)
  assert(not self.constructed, "ClueStateAction already constructed")
  self:_construct(view)
  self.constructed = true
  self:_apply()
end

---Destroys the components of this action.
function ClueStateAction:destroy()
  error("ClueStateAction:destroy not implemented")
end

---@param state ct.interfaces.cluestate.ActionState
function ClueStateAction:setState(state)
  self.state = state
  if self.constructed then self:_apply() end
end

---Updates the text contained in this action line.
---@param text string
function ClueStateAction:setText(text)
  error("ClueStateAction:setText not implemented")
end

---@protected
---@param view prettyui.core.View
function ClueStateAction:_construct(view)
  error("ClueStateAction:_construct not implemented")
end

---Pushes the stored state to the constructed components.
---@protected
function ClueStateAction:_apply()
  error("ClueStateAction:_apply not implemented")
end

---Action line displaying a simple text.
---@class ct.interfaces.cluestate.TextClueStateAction : ct.interfaces.cluestate.ClueStateAction
---@field content string
---@field text ui.Text?
local Text = setmetatable({}, { __index = ClueStateAction })
Text.__index = Text

---@param content string
---@return ct.interfaces.cluestate.TextClueStateAction
function Text.new(content)
  local self = setmetatable({}, Text)
  self:_init()
  self.content = content
  return self
end

---@param content string
---@return ct.interfaces.cluestate.TextClueStateAction
function Text:setText(content)
  self.content = content
  if self.constructed then self:_apply() end

  return self
end

---@protected
---@param view prettyui.core.View
function Text:_construct(view)
  self.text = view:AddText({
    text = self.content,
    x = 0,
    height = ROW_HEIGHT,
    marginBottom = 0,
  })
  self.text.clickthrough = true
end

function Text:destroy()
  if self.text then
    self.text:Destroy()
    self.text = nil
  end
  self.constructed = false
end

---@protected
function Text:_apply()
  self.text.content = self.content
  self.text.alpha = STATE_ALPHA[self.state]
end

ClueStateAction.Text = Text

return ClueStateAction
