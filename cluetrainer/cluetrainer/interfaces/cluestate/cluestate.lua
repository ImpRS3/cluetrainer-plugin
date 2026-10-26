local ClueStateAction = require("cluetrainer/interfaces/cluestate/ClueStateAction")

local WINDOW_WIDTH = 260
-- Mirrors the PrettyUI window chrome, which is not exposed.
local WINDOW_BORDER = 8
local WINDOW_TITLE_HEIGHT = 32
local ROW_HEIGHT = 24
local ICON_SIZE = 20
local TEXT_X = ICON_SIZE + 6
local TEXT_COLOUR = 0xE7D7B0FF

---@class ct.ClueStateInterface
---@field window prettyui.Window
---@field action_content ui.Layer
---@field actions ct.interfaces.cluestate.ClueStateAction[]
local ClueStateInterface = {}
ClueStateInterface.__index = ClueStateInterface

function ClueStateInterface:new()
  ---@class ct.ClueStateInterface
  local self = setmetatable({}, self)

  self.window = prettyui.Window.new(ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA), {
    title = "Clue state",
    x = 10,
    y = 10,
    width = WINDOW_WIDTH,
    height = WINDOW_TITLE_HEIGHT + WINDOW_BORDER,
    resizable = false,
    scrollable = false,
    destroyOnClose = false,
  })

  self.actions = {}
  self.action_content = ui.Layer.new(self.window.content)
  self.action_content:SetSize(0, 0, 1.0, 1.0)

  self:setVisible(false)

  return self
end

function ClueStateInterface:_FitWindow()
  self.window:SetSize(WINDOW_WIDTH, WINDOW_TITLE_HEIGHT + WINDOW_BORDER + #self.actions * ROW_HEIGHT)
end

function ClueStateInterface:clearActions()
  self.action_content:Destroy()
  self.action_content = ui.Layer.new(self.window.content)
  self.action_content:SetSize(0, 0, 1.0, 1.0)
  self.actions = {}
  self:_FitWindow()
end

---@param name string
---@return ct.interfaces.cluestate.ClueStateAction
function ClueStateInterface:addAction(name)
  local row = ui.Layer.new(self.action_content)
  row:SetPos(0, #self.actions * ROW_HEIGHT)
  row:SetSize(0, ROW_HEIGHT, 1.0)
  row.clickthrough = true

  local sprite = ui.Sprite.new(row)
  sprite:SetPos(0, (ROW_HEIGHT - ICON_SIZE) // 2)
  sprite:SetSize(ICON_SIZE, ICON_SIZE)
  sprite.clickthrough = true

  local text = ui.Text.new(row)
  text:SetPos(TEXT_X, 0)
  text:SetSize(-TEXT_X, ROW_HEIGHT, 1.0)
  text.font = id.Font.MUSEO_SANS_15PT_REGULAR
  text.rgba = TEXT_COLOUR
  text.isShadowed = true
  text.alignVertical = ui.AlignMode.CENTRE
  text.content = name
  text.clickthrough = true

  local action = ClueStateAction.new(sprite, text)
  self.actions[#self.actions + 1] = action
  self:_FitWindow()

  return action
end

---@param visible boolean
function ClueStateInterface:setVisible(visible)
  if visible then
    self.window:Show()
  else
    self.window:Close()
  end
end

---@type ct.ClueStateInterface?
local instance = nil

---@return ct.ClueStateInterface
function ClueStateInterface.get()
  if instance == nil then
    instance = ClueStateInterface:new()
  end

  return instance
end

return ClueStateInterface
