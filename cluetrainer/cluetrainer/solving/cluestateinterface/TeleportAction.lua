local ClueStateAction = require("cluetrainer/solving/cluestateinterface/ClueStateAction")
local TeleportTooltip = require("cluetrainer/map/elements/TeleportTooltip")
local item_icon = require("cluetrainer/util/item_icon")
local FontFamily = require("cluetrainer/util/FontFamily")
local TeleportCustomization = require("cluetrainer/solving/common/TeleportCustomization")

local ROW_HEIGHT = 40
local ICON_SIZE = 32
local ICON_X = 120
local ICON_Y = (ROW_HEIGHT - ICON_SIZE) // 2
local CODE_WIDTH = 208
local STATE_ALPHA = { incomplete = 1.0, complete = 0.5 }
local TOOLTIP_PADDING = 6
local TOOLTIP_GAP = 2

---@class ct.solving.TeleportAction : ct.interfaces.cluestate.ClueStateAction
---@field teleport cluetrainer.TeleportSpot?
---@field label ui.Text?
---@field placeholder ui.Text?
---@field icon PrettyUI.Sprite?
---@field item_icon PrettyUI.Sprite?
---@field code_text ui.Text?
---@field private tooltip_root ui.Layer?
---@field private hovered_icon ui.Sprite?
---@field private customization_handler zyklib.reactive.EventHandler?
local TeleportAction = setmetatable({}, { __index = ClueStateAction })
TeleportAction.__index = TeleportAction

---@param teleport cluetrainer.TeleportSpot?
---@return ct.solving.TeleportAction
function TeleportAction.new(teleport)
  local self = setmetatable({}, TeleportAction)
  self:_init()
  self.teleport = teleport
  return self
end

---@param teleport cluetrainer.TeleportSpot?
---@return ct.solving.TeleportAction
function TeleportAction:setTeleport(teleport)
  self.teleport = teleport
  if self.constructed then self:_apply() end
  return self
end

---@private
function TeleportAction:_hideTooltip()
  if self.tooltip_root then
    self.tooltip_root:Destroy()
    self.tooltip_root = nil
  end
end

---@private
---@param icon ui.Sprite
function TeleportAction:_showTooltip(icon)
  self:_hideTooltip()
  if not self.teleport then return end

  local parent = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__ROOT)
      or ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_BOTTOM)
  assert(parent, "TeleportAction requires a top-level tooltip parent")

  local root = ui.Layer.new(parent)
  root.clickthrough = true
  local background = ui.Rectangle.new(root)
  background:SetSize(0, 0, 1.0, 1.0)
  background.fill = true
  background.rgba = 0x000000E6
  background.clickthrough = true
  local border = ui.Rectangle.new(root)
  border:SetSize(0, 0, 1.0, 1.0)
  border.fill = false
  border.rgba = 0x6E6450FF
  border.clickthrough = true

  local content = ui.Layer.new(root)
  content:SetPos(TOOLTIP_PADDING, TOOLTIP_PADDING)
  content.clickthrough = true
  if not TeleportTooltip.new(self.teleport):Build(content) then
    root:Destroy()
    return
  end

  local width, height = content.width + TOOLTIP_PADDING * 2, content.height + TOOLTIP_PADDING * 2
  root:SetSize(width, height)
  local origin, parent_origin = icon.xyGlobal, parent.xyGlobal
  local left, top = origin.x - parent_origin.x, origin.y - parent_origin.y
  local x = left + math.floor((icon.width - width) / 2)
  local y = top - height - TOOLTIP_GAP
  if y < 0 then y = top + icon.height + TOOLTIP_GAP end
  x = math.max(0, math.min(x, math.max(0, parent.width - width)))
  y = math.max(0, math.min(y, math.max(0, parent.height - height)))
  root:SetPos(x, y)
  root:MoveToFront()
  content:MoveToFront()
  self.tooltip_root = root
end

---@private
---@param sprite PrettyUI.Sprite
function TeleportAction:_bindTooltip(sprite)
  local function bind(icon)
    icon.enabled = true
    icon.clickthrough = false
    icon:Subscribe(ui.Hook.ONMOUSEOVER, function()
      self.hovered_icon = icon
      self:_showTooltip(icon)
      return true
    end)
    icon:Subscribe(ui.Hook.ONMOUSELEAVE, function()
      if self.hovered_icon == icon then
        self.hovered_icon = nil
        self:_hideTooltip()
      end
      return true
    end)
  end

  if sprite.dock then
    bind(sprite.dock.root)
    bind(sprite.overlay.root)
  else
    bind(sprite.root)
  end
end

---@protected
function TeleportAction:_construct(view)
  self.label = view:AddText({
    text = "Next Teleport:",
    x = 0,
    width = ICON_X,
    height = ROW_HEIGHT,
    marginBottom = 0,
    rowBackgroundGroup = self,
  })
  self.label.clickthrough = true
  self.placeholder = view:AddText({
    text = "No teleport",
    inline = true,
    x = ICON_X,
    width = -ICON_X,
    widthAnchor = 1.0,
    height = ROW_HEIGHT,
    rowBackgroundGroup = self,
  })
  self.placeholder.clickthrough = true
  self.icon = view:AddSprite(-1, {
    inline = true,
    x = ICON_X,
    offsetY = ICON_Y,
    size = ICON_SIZE,
    rowBackgroundGroup = self,
  })
  local x, y, width, height = item_icon.rect(ICON_X, ICON_Y, ICON_SIZE)
  self.item_icon = view:AddSprite(-1, {
    inline = true,
    x = x,
    offsetY = y,
    width = width,
    height = height,
    rowBackgroundGroup = self,
  })
  local font = FontFamily.NOTOSANS:Get(7 * ICON_SIZE / 15, "bold")
  self.code_text = view:AddText({
    text = "",
    inline = true,
    x = ICON_X + (ICON_SIZE - CODE_WIDTH) // 2,
    offsetY = ICON_Y,
    width = CODE_WIDTH,
    height = ICON_SIZE,
    font = font and font.id or nil,
    colour = 0xFFFFFFFF,
    shadowed = true,
    alignHorizontal = ui.AlignMode.CENTRE,
    alignVertical = ui.AlignMode.CENTRE,
    maxLines = 1,
    rowBackgroundGroup = self,
  })
  self.code_text.clickthrough = true
  self:_bindTooltip(self.icon)
  self:_bindTooltip(self.item_icon)

  -- Read once per row, in case a var transmit named an id that isn't watched.
  TeleportCustomization.refreshFavourites()

  -- Pota slots and fairy ring favourites change the code and icon while the row is shown.
  self.customization_handler = TeleportCustomization.changed:subscribe(function()
    if self.constructed then self:_apply() end
  end)
end

---@protected
function TeleportAction:_apply()
  self:_hideTooltip()
  local cache = self.teleport and self.teleport:cacheData()
  local alpha = STATE_ALPHA[self.state]
  self.label.alpha = alpha
  self.placeholder.hidden = self.teleport ~= nil
  self.placeholder.alpha = 0.5 * alpha
  local font = FontFamily.NOTOSANS:Get(7 * ICON_SIZE / 15, "bold")
  local code = self.teleport and self.teleport:code() or ""
  self.code_text.content = code
  self.code_text.hidden = not (code ~= "" and font and cache and (cache.sprite or cache.obj))
  self.code_text.alpha = alpha

  local function apply(icon, item)
    icon.hidden = not (cache and cache.sprite)
    item.hidden = not (cache and not cache.sprite and cache.obj)
    icon.alpha, item.alpha = alpha, alpha
    if cache and cache.sprite then
      icon.sprite = id.Sprite[cache.sprite]
    elseif cache and cache.obj then
      item:SetAssociatedObject(id.Obj[cache.obj])
    end
  end

  if self.icon.dock then
    apply(self.icon.dock.root, self.item_icon.dock.root)
    apply(self.icon.overlay.root, self.item_icon.overlay.root)
  else
    apply(self.icon.root, self.item_icon.root)
  end

  local hovered = self.hovered_icon
  if hovered and not hovered.hidden and hovered.isMouseOver then self:_showTooltip(hovered) end
end

function TeleportAction:destroy()
  self:_hideTooltip()
  self.hovered_icon = nil
  if self.customization_handler then
    self.customization_handler:cancel()
    self.customization_handler = nil
  end
  for _, component in ipairs({ self.code_text, self.item_icon, self.icon, self.placeholder, self.label }) do
    component:Destroy()
  end
  self.code_text, self.item_icon, self.icon, self.placeholder, self.label = nil, nil, nil, nil, nil
  self.constructed = false
end

return TeleportAction