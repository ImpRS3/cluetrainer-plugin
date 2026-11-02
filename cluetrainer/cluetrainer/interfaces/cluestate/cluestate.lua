local ClueStateAction      = require("cluetrainer/interfaces/cluestate/ClueStateAction")
local storage              = require("cluetrainer/util/storage")
local schema               = require("cluetrainer/util/schema")

--- @type zyklib.reactive.Observable<{x: number, y: number}>
local persistent_position  = storage.preference("cluestate_interface_position", schema.struct({
  x = schema.number({ default = 0 }),
  y = schema.number({ default = 0 }),
}))

local WINDOW_WIDTH         = 260
-- Mirrors the PrettyUI window chrome, which is not exposed.
local WINDOW_BORDER        = 8
local WINDOW_TITLE_HEIGHT  = 32
local ROW_HEIGHT           = 24
-- Native settings panel row colours
local ROW_COLOURS          = { 0x24211EFF, 0x2E2825FF }

---@class ct.ClueStateInterface
---@field window prettyui.Window
---@field actions ct.interfaces.cluestate.ClueStateAction[]
local ClueStateInterface   = {}
ClueStateInterface.__index = ClueStateInterface

function ClueStateInterface:new()
  ---@class ct.ClueStateInterface
  local self = setmetatable({}, self)

local pos = persistent_position:get()

  self.window = prettyui.Window.new(ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA), {
    title = "Clue State",
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

  self:setVisible(false)

  return self
end

function ClueStateInterface:_FitWindow()
  self.window:SetSize(WINDOW_WIDTH, WINDOW_TITLE_HEIGHT + WINDOW_BORDER + #self.actions * ROW_HEIGHT)
  self.window:RefreshRowBackgrounds()
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

---@param visible boolean
function ClueStateInterface:setVisible(visible)
  if visible then
    self.window:Show()
  else
    self.window:Close()
  end
end

function ClueStateInterface:ensureVisible()
  self:setVisible(true)
  return self
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
