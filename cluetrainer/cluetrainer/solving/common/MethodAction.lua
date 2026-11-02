local ClueStateAction = require("cluetrainer/interfaces/cluestate/ClueStateAction")
local methods = require("cluetrainer/model/shared/methods")

local STATE_ALPHA = {
  incomplete = 1.0,
  complete = 0.5,
}

local ROW_HEIGHT = 24
local ICON_SIZE = 20
local ICON_X = 3
local TEXT_X = ICON_SIZE + 6
local BUTTON_SIZE = 20
local BUTTON_MARGIN = 4

---Action line displaying the primary teleport of a method, with a button to request selecting another method.
---`setText` is intentionally unsupported, the text is derived from the method.
---@class ct.solving.MethodAction : ct.interfaces.cluestate.ClueStateAction
---@field method ct.AugmentedMethod.Generic?
---@field onSelectRequested fun(action: ct.solving.MethodAction)?
---@field text ui.Text?
---@field icon PrettyUI.Sprite?
---@field select_button PrettyUI.SpriteButton?
local MethodAction = setmetatable({}, { __index = ClueStateAction })
MethodAction.__index = MethodAction

---@class ct.solving.MethodAction.Options
---@field onSelectRequested fun(action: ct.solving.MethodAction)? Called when the player clicks the select button

---@param method ct.AugmentedMethod.Generic?
---@param options ct.solving.MethodAction.Options?
---@return ct.solving.MethodAction
function MethodAction.new(method, options)
  local self = setmetatable({}, MethodAction)
  self:_init()

  self.method = method
  self.onSelectRequested = options and options.onSelectRequested or nil

  return self
end

---@param method ct.AugmentedMethod.Generic?
---@return ct.solving.MethodAction
function MethodAction:setMethod(method)
  self.method = method
  if self.constructed then self:_apply() end

  return self
end

---@protected
---@param view PrettyUI.SimpleView
function MethodAction:_construct(view)
  self.text = view:AddText({
    text = "",
    x = TEXT_X,
    width = -(TEXT_X + BUTTON_SIZE + BUTTON_MARGIN * 2),
    widthAnchor = 1.0,
    height = ROW_HEIGHT,
    marginBottom = 0,
    rowBackgroundGroup = self,
  })
  self.text.clickthrough = true

  self.icon = view:AddSprite(-1, {
    inline = true,
    x = ICON_X,
    offsetY = (ROW_HEIGHT - ICON_SIZE) // 2,
    size = ICON_SIZE,
    rowBackgroundGroup = self,
  })

  self.select_button = view:AddSpriteButton("LIST_LAYOUT", function()
    if self.onSelectRequested then self.onSelectRequested(self) end
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

---@param icon PrettyUI.Sprite
---@param teleport cluetrainer.TeleportSpot?
local function applyIcon(icon, teleport)
  local cache = teleport and teleport.props.cache_data or nil
  local root = icon.root

  if cache and cache.sprite then
    root.hidden = false
    root.sprite = id.Sprite[cache.sprite]
    root:SetAssociatedObject(-1)
  elseif cache and cache.obj then
    root.hidden = false
    root:SetAssociatedObject(id.Obj[cache.obj])
  else
    root.hidden = true
  end
end

---@protected
function MethodAction:_apply()
  local method = self.method
  local teleport = method and methods.primaryTeleport(method.method) or nil
  local alpha = STATE_ALPHA[self.state]

  if teleport ~= nil then
    self.text.content = teleport:hover()
  else
    self.text.content = method and method.method.name or "No method"
  end

  applyIcon(self.icon, teleport)

  self.text.alpha = alpha
  self.icon.root.alpha = alpha
end

function MethodAction:destroy()
  for _, component in ipairs({ self.select_button, self.icon, self.text }) do
    component:Destroy()
  end

  self.select_button, self.icon, self.text = nil, nil, nil
  self.constructed = false
end

return MethodAction
