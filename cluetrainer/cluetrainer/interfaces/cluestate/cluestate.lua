local WindowGeometry       = require("cluetrainer/util/WindowGeometry")
local prettyui_workarounds = require("cluetrainer/util/prettyui_workarounds")
local item_icon            = require("cluetrainer/util/item_icon")
local method_management    = require("cluetrainer/methods/method_management")
local MethodSelectDialog   = require("cluetrainer/methods/MethodSelectDialog")

local geometry             = WindowGeometry.new("cluestate_interface_geometry")

local WINDOW_WIDTH         = 260
-- Mirrors the PrettyUI window chrome, which is not exposed.
local PANEL_BORDER         = 8
local ROW_HEIGHT           = 24
-- Native settings panel row colours
local ROW_COLOURS          = { 0x24211EFF, 0x2E2825FF }

-- Keeps the clue text and the inline reset button on the same row background.
local HEADER_GROUP         = "clue_header"
local RESET_BUTTON_SIZE    = 20
local RESET_BUTTON_MARGIN  = 4
local METHOD_BUTTON_WIDTH  = 90
local METHOD_BUTTON_MARGIN = 4
local METHOD_SEPARATOR_MARGIN = 4
local METHOD_SEPARATOR_X   = -(METHOD_BUTTON_WIDTH + METHOD_BUTTON_MARGIN + 6 + METHOD_SEPARATOR_MARGIN)
local ACTIVE_RESET_X       = METHOD_SEPARATOR_X - RESET_BUTTON_SIZE - RESET_BUTTON_MARGIN
local TIER_ICON_SIZE       = 20
local TIER_ICON_X          = 4
local TIER_TEXT_X          = TIER_ICON_X + TIER_ICON_SIZE + 4

---Object ids of the items displayed as the sprite of each clue tier. Fill in the ids, tiers without an id show no icon.
---@type table<ClueTier, string?>
local TIER_OBJECT_IDS      = {
  easy         = "TRAIL17_TRAIL_START_EASY",
  medium       = "TRAIL17_TRAIL_START_MEDIUM",
  hard         = "TRAIL17_TRAIL_START_HARD",
  elite        = "TRAIL17_TRAIL_START_ELITE",
  master       = "TRAIL17_TRAIL_START_MASTER",
  tetracompass = "ARCH_TETRACOMPASS_POWERED"
}

local PLACEHOLDER_ALPHA    = 0.5

---@class ct.ClueStateInterface: zyklib.disposable.IDisposable
---@field window PrettyUI.Panel
---@field actions ct.interfaces.cluestate.ClueStateAction[]
---@field clue_text PrettyUI.Text
---@field tier_icon PrettyUI.Sprite
---@field reset_button PrettyUI.SpriteButton
---@field active_reset_button PrettyUI.SpriteButton
---@field method_button PrettyUI.SimpleButton
---@field method_separator ui.Text
---@field clue_spot ClueSpot?
---@field selected_method ct.AugmentedMethod<Method>?
---@field method_selected zyklib.reactive.Event<ct.AugmentedMethod<Method>?, nil> Fires for the preferred method on a spot change and for selections in the dialog
---@field private method_dialog PrettyUI.Dialog?
---@field divider PrettyUI.Divider
---@field private reset_rows fun() Puts the flow layout back to right after the header, see `prettyui_workarounds`
local ClueStateInterface   = {}
ClueStateInterface.__index = ClueStateInterface

---@return ct.ClueStateInterface
function ClueStateInterface.new()
  ---@class ct.ClueStateInterface
  local self = setmetatable({}, ClueStateInterface)

  ---@type zyklib.reactive.Event<nil, nil>
  self.reset_event = zyklib.reactive.Event.new()
  ---@type zyklib.reactive.Event<ct.AugmentedMethod<Method>?, nil>
  self.method_selected = zyklib.reactive.Event.new()

  self.window = prettyui.Panel.new(ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA), geometry:apply({
    title = "Clue Trainer",
    x = 0,
    y = 0,
    width = WINDOW_WIDTH,
    height = PANEL_BORDER,
    resizable = false,
    scrollable = false,
    backgroundAlpha = 0.5,
    destroyOnClose = false,
    -- Called once a drag of the panel ends
    onPositionChange = function(panel) geometry:save(panel) end,
    rowBackgroundColours = ROW_COLOURS,
    rowBackgroundEdgeToEdge = true,
    layout = { startY = 0, padding = 0, rowGap = 0 },
  }))

  self.actions = {}

  self.clue_text = self.window:AddText({
    text = "No clue",
    x = TIER_TEXT_X,
    width = -(TIER_TEXT_X + RESET_BUTTON_SIZE + RESET_BUTTON_MARGIN * 2),
    widthAnchor = 1.0,
    height = ROW_HEIGHT,
    marginBottom = 0,
    maxLines = 1,
    rowBackgroundGroup = HEADER_GROUP,
  })

  local icon_x, icon_y, icon_width, icon_height =
      item_icon.rect(TIER_ICON_X, (ROW_HEIGHT - TIER_ICON_SIZE) // 2, TIER_ICON_SIZE)
  self.tier_icon = self.window:AddSprite(-1, {
    inline = true,
    x = icon_x,
    offsetY = icon_y,
    width = icon_width,
    height = icon_height,
    rowBackgroundGroup = HEADER_GROUP,
  })
  self.tier_icon.root.hidden = true

  self.reset_button = self.window:AddSpriteButton("CROSS", function()
    self.reset_event:trigger(nil)
  end, {
    inline = true,
    x = -(RESET_BUTTON_SIZE + RESET_BUTTON_MARGIN),
    xAnchor = 1.0,
    offsetY = (ROW_HEIGHT - RESET_BUTTON_SIZE) // 2,
    size = RESET_BUTTON_SIZE,
    tooltip = "Close",
    rowBackgroundGroup = HEADER_GROUP,
  })

  self.active_reset_button = self.window:AddSpriteButton("CROSS", function()
    self.reset_event:trigger(nil)
  end, {
    inline = true,
    x = ACTIVE_RESET_X,
    xAnchor = 1.0,
    offsetY = (ROW_HEIGHT - RESET_BUTTON_SIZE) // 2,
    size = RESET_BUTTON_SIZE,
    tooltip = "Close",
    rowBackgroundGroup = HEADER_GROUP,
  })

  self.method_separator = self.window:AddText({
    text = "|",
    inline = true,
    x = METHOD_SEPARATOR_X,
    xAnchor = 1.0,
    width = 6,
    height = ROW_HEIGHT,
    rowBackgroundGroup = HEADER_GROUP,
  })
  self.method_separator.clickthrough = true
  self.method_separator.alpha = PLACEHOLDER_ALPHA

  self.method_button = self.window:AddSimpleButton("None", function()
    self:_openMethodDialog()
  end, {
    inline = true,
    x = -(METHOD_BUTTON_WIDTH + METHOD_BUTTON_MARGIN),
    xAnchor = 1.0,
    width = METHOD_BUTTON_WIDTH,
    height = ROW_HEIGHT,
    tooltip = "Select method",
    rowBackgroundGroup = HEADER_GROUP,
  })

  --self.divider = self.window:AddDivider({ rowBackground = false, marginTop = 1, marginBottom = 1 })

  self.reset_rows = prettyui_workarounds.rememberFlow(self.window)
  self:setClueSpot(nil)

  return self
end

---@private
function ClueStateInterface:_closeMethodDialog()
  if self.method_dialog then
    self.method_dialog:Destroy()
    self.method_dialog = nil
  end
end

---@private
---@return boolean
function ClueStateInterface:_isMethodSelectorActive()
  local spot = self.clue_spot
  return spot ~= nil and (spot.clue.type ~= "compass" or spot.spot ~= nil)
end

---@private
function ClueStateInterface:_updateMethodButton()
  local method = self.selected_method
  local active = self:_isMethodSelectorActive()
  local label = not active and "-" or ((method and method.method.id:sub(1, 4) or "None"))
  local tooltip = not active and "Identify the spot first"
      or (method and ("Method: " .. method.method.name .. "<br>" .. method.method.id) or "No method selected")
  self.method_button.dock.content.content = label
  self.method_button.overlay.content.content = label
  self.method_button.textColour = method and 0xFFFFFFFF or 0x999999FF
  self.method_button:SetDisabled(not active)
  self.method_button:SetTooltip(tooltip)
end

---@private
function ClueStateInterface:_openMethodDialog()
  local spot = self.clue_spot
  if spot == nil or not self:_isMethodSelectorActive() then return end
  self:_closeMethodDialog()
  self.method_dialog = MethodSelectDialog.open({
    spot = { clue = spot.clue.id, spot = spot.spot },
    selected = self.selected_method,
    onSelect = function(method)
      self.selected_method = method
      self:_updateMethodButton()
      self.method_selected:trigger(method)
    end,
  })
end

--- Shows or hides the window, keeping whether it is docked or popped out.
---@param visible boolean
function ClueStateInterface:setVisible(visible)
  local window = self.window
  if window == nil then return end

  if visible then
    prettyui_workarounds.show(window)
  else
    prettyui_workarounds.hide(window)
  end
end

function ClueStateInterface:_FitWindow()
  self.window:SetSize(WINDOW_WIDTH, PANEL_BORDER + prettyui_workarounds.contentHeight(self.window))
  self.window:RefreshRowBackgrounds()
end

---Sets the displayed clue spot and selects its preferred method.
---@param clue_spot ClueSpot? The current clue spot, or nil if there is none
function ClueStateInterface:setClueSpot(clue_spot)
  self:_closeMethodDialog()
  self.clue_spot = clue_spot
  local clue = clue_spot and clue_spot.clue
  self.selected_method = nil
  if clue_spot and self:_isMethodSelectorActive() then
    self.selected_method = method_management.getPreferred({ clue = clue_spot.clue.id, spot = clue_spot.spot })
  end
  self:_updateMethodButton()
  local has_clue = clue ~= nil
  self.reset_button.dock.root.hidden = has_clue
  self.reset_button.overlay.root.hidden = has_clue
  self.active_reset_button.dock.root.hidden = not has_clue
  self.active_reset_button.overlay.root.hidden = not has_clue
  self.method_separator.hidden = not has_clue
  self.method_button.dock.root.hidden = not has_clue
  self.method_button.overlay.root.hidden = not has_clue
  local reserved = has_clue and -ACTIVE_RESET_X + RESET_BUTTON_MARGIN
      or RESET_BUTTON_SIZE + RESET_BUTTON_MARGIN * 2
  self.clue_text:SetSize(-(TIER_TEXT_X + reserved), ROW_HEIGHT, 1.0)
  if clue == nil then
    -- Faded to be distinct from a selected clue
    self.clue_text.content = "No clue"
    self.clue_text.alpha = PLACEHOLDER_ALPHA
    self.tier_icon.dock.root.hidden = true
    self.tier_icon.overlay.root.hidden = true
  else
    self.clue_text.alpha = 1.0

    local object_id = id.Obj[TIER_OBJECT_IDS[clue.tier]]

    self.tier_icon.dock.root:SetAssociatedObject(object_id)
    self.tier_icon.overlay.root:SetAssociatedObject(object_id)
    self.tier_icon.dock.root.hidden = false
    self.tier_icon.overlay.root.hidden = false
    self.clue_text.content = string.format("%s/%s", tostring(clue.type), tostring(clue.id))
  end

  self:_FitWindow()
  self.method_selected:trigger(self.selected_method)
end

function ClueStateInterface:clearActions()
  for _, action in ipairs(self.actions) do
    action:destroy()
  end
  self.actions = {}
  self.reset_rows()
  self:_FitWindow()
end

---@generic T : ct.interfaces.cluestate.ClueStateAction
---@param action T text for a simple text line, or a custom action
---@return T
function ClueStateInterface:addAction(action)
  action:construct(self.window)
  self.actions[#self.actions + 1] = action
  self:_FitWindow()

  return action
end

function ClueStateInterface:dispose()
  self:_closeMethodDialog()
  if self.window ~= nil then
    geometry:save(self.window)
    self.window:Destroy()
    self.window = nil
  end
end

return ClueStateInterface
