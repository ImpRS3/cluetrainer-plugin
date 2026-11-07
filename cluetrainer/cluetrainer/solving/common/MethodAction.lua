local ClueStateAction = require("cluetrainer/interfaces/cluestate/ClueStateAction")
local method_management = require("cluetrainer/methods/method_management")
local MethodSelectDialog = require("cluetrainer/methods/MethodSelectDialog")

local STATE_ALPHA = {
  incomplete = 1.0,
  complete = 0.5,
}

local PLACEHOLDER_ALPHA = 0.5
local NOT_SELECTABLE_TEXT = "Not available yet"

local ROW_HEIGHT = 22
local TEXT_X = 3
local BUTTON_SIZE = 20
local BUTTON_MARGIN = 4

---Action line displaying the selected method's name, with a button to open the method selection dialog.
---`setText` is intentionally unsupported, the text is derived from the method.
---Without a spot, no method can be selected yet and the select button is hidden.
---@class ct.solving.MethodAction : ct.interfaces.cluestate.ClueStateAction
---@field spot ClueSpot.Id?
---@field method ct.AugmentedMethod.Generic?
---@field onMethodSelected fun(method: ct.AugmentedMethod.Generic?)?
---@field text ui.Text?
---@field select_button PrettyUI.SpriteButton?
local MethodAction = setmetatable({}, { __index = ClueStateAction })
MethodAction.__index = MethodAction

---@class ct.solving.MethodAction.Options
---@field onMethodSelected fun(method: ct.AugmentedMethod.Generic?)? Called whenever the player picks a method in the dialog, immediately and not only on confirmation. Nil means "None"

---@param spot ClueSpot.Id? The spot to select a method for, nil if it is not known yet
---@param options ct.solving.MethodAction.Options?
---@return ct.solving.MethodAction
function MethodAction.new(spot, options)
  local self = setmetatable({}, MethodAction)
  self:_init()

  self.onMethodSelected = options and options.onMethodSelected or nil
  self.spot = spot
  self.method = spot and method_management.getPreferred(spot) or nil

  return self
end

---Sets the spot and resets the method to the preferred one. Does not call `onMethodSelected`, read `method` afterwards.
---@param spot ClueSpot.Id? nil if the spot is not known yet
---@return ct.solving.MethodAction
function MethodAction:setSpot(spot)
  self.spot = spot
  self.method = spot and method_management.getPreferred(spot) or nil
  if self.constructed then self:_apply() end

  return self
end

---@param method ct.AugmentedMethod.Generic?
---@return ct.solving.MethodAction
function MethodAction:setMethod(method)
  self.method = method
  if self.constructed then self:_apply() end

  return self
end

---@private
function MethodAction:_openDialog()
  if self.spot == nil then return end

  MethodSelectDialog.open({
    spot = self.spot,
    selected = self.method,
    onSelect = function(method)
      self:setMethod(method)
      if self.onMethodSelected then self.onMethodSelected(method) end
    end,
  })
end

---@protected
function MethodAction:_construct(view)
  self.text = view:AddText({
    text = "",
    x = TEXT_X,
    width = -(TEXT_X + BUTTON_SIZE + BUTTON_MARGIN * 2),
    widthAnchor = 1.0,
    height = ROW_HEIGHT,
    marginBottom = 0,
    maxLines = 1,
    rowBackgroundGroup = self,
  })
  self.text.clickthrough = true

  self.select_button = view:AddSpriteButton("LIST_LAYOUT", function()
    self:_openDialog()
  end, {
    inline = true,
    x = -(BUTTON_SIZE + BUTTON_MARGIN),
    xAnchor = 1.0,
    offsetY = (ROW_HEIGHT - BUTTON_SIZE) // 2,
    size = BUTTON_SIZE,
    tooltip = "Select method",
    rowBackgroundGroup = self,
  })
end

---@param text ui.Text
---@param content string
local function setTruncatedText(text, content)
  local font = config.Font.MUSEO_SANS_15PT_REGULAR
  local width = text.width
  content = content:gsub("<br>", " "):gsub("[\r\n]", " ")
  if font:GetStringWidth(content) <= width then
    text.content = content
    return
  end

  local suffix = "..."
  if font:GetStringWidth(suffix) > width then
    text.content = ""
    return
  end

  while #content > 0 and font:GetStringWidth(content .. suffix) > width do
    local last = #content
    while last > 1 and content:byte(last) >= 128 and content:byte(last) < 192 do
      last = last - 1
    end
    content = content:sub(1, last - 1)
  end
  text.content = content .. suffix
end

---@protected
function MethodAction:_apply()
  local method = self.method
  local alpha = STATE_ALPHA[self.state]
  local selectable = self.spot ~= nil
  local content

  if not selectable then
    content = NOT_SELECTABLE_TEXT
    alpha = PLACEHOLDER_ALPHA
  elseif method ~= nil then
    content = method.method.name
  else
    content = "No method set"
    alpha = PLACEHOLDER_ALPHA
  end

  if type(self.text) == "table" and self.text.dock then
    setTruncatedText(self.text.dock, content)
    setTruncatedText(self.text.overlay, content)
    self.select_button.dock.root.hidden = not selectable
    self.select_button.overlay.root.hidden = not selectable
  else
    setTruncatedText(self.text, content)
    self.select_button.root.hidden = not selectable
  end
  self.text.alpha = alpha
end

function MethodAction:destroy()
  for _, component in ipairs({ self.select_button, self.text }) do
    component:Destroy()
  end

  self.select_button, self.text = nil, nil
  self.constructed = false
end

return MethodAction
