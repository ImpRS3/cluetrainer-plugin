local ClueStateAction = require("cluetrainer/interfaces/cluestate/ClueStateAction")
local methods = require("cluetrainer/model/shared/methods")
local method_management = require("cluetrainer/methods/method_management")
local MethodSelectDialog = require("cluetrainer/methods/MethodSelectDialog")
local item_icon = require("cluetrainer/util/item_icon")

local STATE_ALPHA = {
  incomplete = 1.0,
  complete = 0.5,
}

local PLACEHOLDER_ALPHA = 0.5
local NOT_SELECTABLE_TEXT = "Not available yet"

-- Flow rows can't change height after construction, so the row always has room for the two lines of a selected
-- method. Texts are vertically centred, so the single-line states sit in the middle.
local ROW_HEIGHT = 40
local ICON_SIZE = 32
local ICON_X = 3
local TEXT_X = ICON_SIZE + 6
local BUTTON_SIZE = 20
local BUTTON_MARGIN = 4

---Action line displaying the primary teleport of the preferred method for a clue spot, with a button to open the
---method selection dialog. `setText` is intentionally unsupported, the text is derived from the method.
---Without a spot, no method can be selected yet and the select button is hidden.
---@class ct.solving.MethodAction : ct.interfaces.cluestate.ClueStateAction
---@field spot ClueSpot.Id?
---@field method ct.AugmentedMethod.Generic?
---@field onMethodSelected fun(method: ct.AugmentedMethod.Generic?)?
---@field text ui.Text?
---@field icon PrettyUI.Sprite? Shows a teleport's sprite
---@field item_icon PrettyUI.Sprite? Shows a teleport's item, placed by `item_icon`
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

  -- A separate sprite, as items need another box than sprites and flow rows can't move a component afterwards.
  local item_x, item_y, item_width, item_height = item_icon.rect(ICON_X, (ROW_HEIGHT - ICON_SIZE) // 2, ICON_SIZE)
  self.item_icon = view:AddSprite(-1, {
    inline = true,
    x = item_x,
    offsetY = item_y,
    width = item_width,
    height = item_height,
    rowBackgroundGroup = self,
  })

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

---@param icon PrettyUI.Sprite
---@param item PrettyUI.Sprite
---@param teleport cluetrainer.TeleportSpot?
local function applyIcon(icon, item, teleport)
  local cache = teleport and teleport.props.cache_data or nil

  icon.root.hidden = not (cache and cache.sprite)
  item.root.hidden = not (cache and not cache.sprite and cache.obj)

  if cache and cache.sprite then
    icon.root.sprite = id.Sprite[cache.sprite]
  elseif cache and cache.obj then
    item.root:SetAssociatedObject(id.Obj[cache.obj])
  end
end

---@protected
function MethodAction:_apply()
  local method = self.method
  local teleport = method and methods.primaryTeleport(method.method) or nil
  local alpha = STATE_ALPHA[self.state]

  local selectable = self.spot ~= nil

  if not selectable then
    -- Nothing to choose yet, so the select button is not offered
    self.text.content = NOT_SELECTABLE_TEXT
    alpha = PLACEHOLDER_ALPHA
    teleport = nil
  elseif teleport ~= nil then
    self.text.content = teleport.group.name .. "<br>" .. teleport.spot.name
  elseif method ~= nil then
    self.text.content = method.method.name
  else
    self.text.content = "No method set"
    alpha = PLACEHOLDER_ALPHA
  end

  applyIcon(self.icon, self.item_icon, teleport)
  self.select_button.root.hidden = not selectable

  self.text.alpha = alpha
  self.icon.root.alpha = alpha
  self.item_icon.root.alpha = alpha
end

function MethodAction:destroy()
  for _, component in ipairs({ self.select_button, self.icon, self.item_icon, self.text }) do
    component:Destroy()
  end

  self.select_button, self.icon, self.item_icon, self.text = nil, nil, nil, nil
  self.constructed = false
end

return MethodAction
