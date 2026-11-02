local ClueStateAction      = require("cluetrainer/interfaces/cluestate/ClueStateAction")
local storage              = require("cluetrainer/util/storage")
local schema               = require("cluetrainer/util/schema")

--- @type zyklib.reactive.Observable<{x: number, y: number}>
local persistent_position  = storage.preference("cluestate_interface_position", schema.struct({
  x = schema.number({ default = 0 }),
  y = schema.number({ default = 0 }),
}))

local WINDOW_WIDTH         = 150
-- Mirrors the PrettyUI window chrome, which is not exposed.
local WINDOW_BORDER        = 8
local WINDOW_TITLE_HEIGHT  = 32
local ROW_HEIGHT           = 24
-- Native settings panel row colours
local ROW_COLOURS          = { 0x24211EFF, 0x2E2825FF }

-- Keeps the clue text and the inline reset button on the same row background.
local HEADER_GROUP         = "clue_header"
local RESET_BUTTON_SIZE    = 20
local RESET_BUTTON_MARGIN  = 4
local TIER_ICON_SIZE       = 20
local TIER_ICON_X          = 4
local TIER_TEXT_X          = TIER_ICON_X + TIER_ICON_SIZE + 4

---Object ids of the items displayed as the sprite of each clue tier. Fill in the ids, tiers without an id show no icon.
---@type table<ClueTier, integer?>
local TIER_OBJECT_IDS      = {
  easy         = nil,
  medium       = nil,
  hard         = nil,
  elite        = nil,
  master       = nil,
  tetracompass = nil,
  sandy        = nil,
}

-- Estimated height of the divider including its margins. Tune visually.
local DIVIDER_HEIGHT       = 6
local HEADER_HEIGHT        = ROW_HEIGHT + DIVIDER_HEIGHT

---@class ct.ClueStateInterface: zyklib.disposable.IDisposable
---@field window PrettyUI.Panel
---@field actions ct.interfaces.cluestate.ClueStateAction[]
---@field clue_text PrettyUI.Text
---@field tier_icon PrettyUI.Sprite
---@field reset_button PrettyUI.SpriteButton
---@field divider PrettyUI.Divider
local ClueStateInterface   = {}
ClueStateInterface.__index = ClueStateInterface

---@return ct.ClueStateInterface
function ClueStateInterface.new()
  ---@class ct.ClueStateInterface
  local self = setmetatable({}, ClueStateInterface)

  ---@type zyklib.reactive.Event
  self.reset_event = zyklib.reactive.Event.new()

  local pos = persistent_position:get()

  self.window = prettyui.Panel.new(ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA), {
    title = "Clue Trainer",
    x = pos.x,
    y = pos.y,
    width = WINDOW_WIDTH,
    height = WINDOW_TITLE_HEIGHT + WINDOW_BORDER,
    resizable = false,
    scrollable = false,
    destroyOnClose = false,
    rowBackgroundColours = ROW_COLOURS,
    rowBackgroundEdgeToEdge = true,
    layout = { startY = 0, padding = 0, rowGap = 0 },
  })

  self.actions = {}

  self.clue_text = self.window:AddText({
    text = "No clue",
    x = TIER_TEXT_X,
    width = -(TIER_TEXT_X + RESET_BUTTON_SIZE + RESET_BUTTON_MARGIN * 2),
    widthAnchor = 1.0,
    height = ROW_HEIGHT,
    marginBottom = 0,
    rowBackgroundGroup = HEADER_GROUP,
  })

  self.tier_icon = self.window:AddSprite(-1, {
    inline = true,
    x = TIER_ICON_X,
    offsetY = (ROW_HEIGHT - TIER_ICON_SIZE) // 2,
    size = TIER_ICON_SIZE,
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
    tooltip = "Reset clue",
    rowBackgroundGroup = HEADER_GROUP,
  })

  --self.divider = self.window:AddDivider({ rowBackground = false, marginTop = 1, marginBottom = 1 })

  self:_FitWindow()

  return self
end

function ClueStateInterface:_FitWindow()
  -- The flow layout keeps contentHeight up to date, the row based estimate is only a fallback.
  local content = self.window.contentHeight
  if type(content) ~= "number" or content <= 0 then
    content = HEADER_HEIGHT + #self.actions * ROW_HEIGHT
  end

  self.window:SetSize(WINDOW_WIDTH, WINDOW_TITLE_HEIGHT + WINDOW_BORDER + content)
  self.window:RefreshRowBackgrounds()
end

---Sets the clue displayed above the divider.
---@param clue StepShared? The current clue, or nil if there is none
function ClueStateInterface:setClue(clue)
  if clue == nil then
    self.clue_text.content = "No clue"
    self.tier_icon.root.hidden = true
  else
    local object_id = TIER_OBJECT_IDS[clue.tier]

    if object_id ~= nil then
      self.tier_icon.root:SetAssociatedObject(object_id)
      self.tier_icon.root.hidden = false
      self.clue_text.content = string.format("#%s", tostring(clue.id))
    else
      -- Without an icon the tier name is shown instead
      self.tier_icon.root.hidden = true
      self.clue_text.content = string.format("%s #%s", clue.tier:sub(1, 1):upper() .. clue.tier:sub(2), tostring(clue.id))
    end
  end

  self:_FitWindow()
end

function ClueStateInterface:clearActions()
  for _, action in ipairs(self.actions) do
    action:destroy()
  end
  self.actions = {}
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
  if self.window ~= nil then
    self.window:Destroy()
    self.window = nil
  end
end

return ClueStateInterface
