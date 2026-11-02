--- Building blocks shared by the control twigs: the HUD-style panel, icon buttons and number labels.
local common = {}

local TEXT_COLOUR = 0xE7D7B0FF
local BORDER_SIZE = 4
local PANEL_BACKGROUND_ALPHA = 0.82

common.SPRITES = {
    panel = {
        content = id.Sprite.RS3_HUD_WINDOW_CONTENT_TILE,
        top = id.Sprite.RS3_HUD_WINDOW_TOP_TILE,
        bottom = id.Sprite.RS3_HUD_WINDOW_BOTTOM_TILE,
        side = id.Sprite.RS3_HUD_WINDOW_SIDE_TILE,
        cornerTop = id.Sprite.RS3_HUD_WINDOW_CORNER_TOP,
        cornerBottom = id.Sprite.RS3_HUD_WINDOW_CORNER_BOTTOM,
    },
    floorDown = {
        disabled = id.Sprite.RS3_ICON_DIRECTION_DESCEND_32PX_4,
        neutral = id.Sprite.RS3_ICON_DIRECTION_DESCEND_32PX_2,
        active = id.Sprite.RS3_ICON_DIRECTION_DESCEND_32PX_3,
    },
    floorUp = {
        disabled = id.Sprite.RS3_ICON_DIRECTION_ASCEND_32PX_4,
        neutral = id.Sprite.RS3_ICON_DIRECTION_ASCEND_32PX_2,
        active = id.Sprite.RS3_ICON_DIRECTION_ASCEND_32PX_3,
    },
    zoomOut = {
        disabled = id.Sprite.RS3_BTN_DECREASE_DISABLED,
        neutral = id.Sprite.RS3_BTN_DECREASE_ACTIVE,
        active = id.Sprite.RS3_BTN_DECREASE_OVER,
    },
    zoomIn = {
        disabled = id.Sprite.RS3_BTN_INCREASE_DISABLED,
        neutral = id.Sprite.RS3_BTN_INCREASE_ACTIVE,
        active = id.Sprite.RS3_BTN_INCREASE_OVER,
    },
    ARROW_RIGHT = { disabled = id.Sprite.RS3_ICON_DIRECTION_RIGHT_32PX_4, neutral = id.Sprite.RS3_ICON_DIRECTION_RIGHT_32PX_2, active = id.Sprite.RS3_ICON_DIRECTION_RIGHT_32PX_3 },
    ARROW_LEFT = { disabled = id.Sprite.RS3_ICON_DIRECTION_LEFT_32PX_4, neutral = id.Sprite.RS3_ICON_DIRECTION_LEFT_32PX_2, active = id.Sprite.RS3_ICON_DIRECTION_LEFT_32PX_3 },

}

---@class prettymap.luaflet.ControlButton
---@field root ui.Sprite
---@field disabled boolean
---@field hovered boolean
---@field pressed boolean
---@field action fun()
---@field Refresh fun(self: prettymap.luaflet.ControlButton)
---@field SetDisabled fun(self: prettymap.luaflet.ControlButton, disabled: boolean?)

--- An icon button with disabled, neutral and active sprites.
---@param parent ui.Layer
---@param states {disabled: integer, neutral: integer, active: integer}
---@param action fun()
---@param x integer
---@param size integer
---@return prettymap.luaflet.ControlButton
function common.button(parent, states, action, x, size)
    local control = {
        disabled = false,
        hovered = false,
        pressed = false,
        action = action,
    }
    control.root = ui.Sprite.new(parent)
    control.root:SetPos(x, 0)
    control.root:SetSize(size, size)

    function control:Refresh()
        self.root.enabled = not self.disabled
        self.root.clickthrough = self.disabled
        if self.disabled then
            self.root.spriteID = states.disabled
        elseif self.hovered or self.pressed then
            self.root.spriteID = states.active
        else
            self.root.spriteID = states.neutral
        end
    end

    function control:SetDisabled(disabled)
        self.disabled = disabled == true
        self.hovered = false
        self.pressed = false
        self:Refresh()
    end

    control.root:Subscribe(ui.Hook.ONMOUSEOVER, function()
        if control.disabled then return false end
        control.hovered = true
        control:Refresh()
        return true
    end)
    control.root:Subscribe(ui.Hook.ONMOUSELEAVE, function()
        control.hovered = false
        control.pressed = false
        control:Refresh()
        return true
    end)
    control.root:Subscribe(ui.Hook.ONCLICK, function()
        if control.disabled then return false end
        control.pressed = true
        control:Refresh()
        return false
    end)
    control.root:Subscribe(ui.Hook.ONRELEASE, function()
        local activate = control.pressed and not control.disabled
        control.pressed = false
        control:Refresh()
        if activate then control.action() end
        return false
    end)
    control:Refresh()
    return control
end

--- Fills `root` with the panel's background and border, which follow the size of `root`.
---@param root ui.Layer
---@return ui.Layer container Layer inside the border for the panel's content.
function common.panel(root)
    local sprites = common.SPRITES.panel

    local function decoration(spriteID)
        local value = ui.Sprite.new(root)
        value.spriteID = spriteID
        value.clickthrough = true
        return value
    end

    root.clickthrough = false

    local background = decoration(sprites.content)
    background:SetPos(BORDER_SIZE, BORDER_SIZE)
    background:SetSize(-BORDER_SIZE * 2, -BORDER_SIZE * 2, 1.0, 1.0)
    background.isTiling = true
    background.alpha = PANEL_BACKGROUND_ALPHA
    background.clickthrough = false

    local top = decoration(sprites.top)
    top:SetPos(BORDER_SIZE, 0)
    top:SetSize(-BORDER_SIZE * 2, BORDER_SIZE, 1.0)
    top.isTiling = true

    local bottom = decoration(sprites.bottom)
    bottom:SetPos(BORDER_SIZE, -BORDER_SIZE, 0, 1.0)
    bottom:SetSize(-BORDER_SIZE * 2, BORDER_SIZE, 1.0)
    bottom.isTiling = true

    local left = decoration(sprites.side)
    left:SetPos(0, BORDER_SIZE)
    left:SetSize(BORDER_SIZE, -BORDER_SIZE * 2, 0, 1.0)
    left.isTiling = true

    local right = decoration(sprites.side)
    right:SetPos(-BORDER_SIZE, BORDER_SIZE, 1.0)
    right:SetSize(BORDER_SIZE, -BORDER_SIZE * 2, 0, 1.0)
    right.isTiling = true
    right.isFlippedHorizontally = true

    local topLeft = decoration(sprites.cornerTop)
    topLeft:SetSize(BORDER_SIZE, BORDER_SIZE)

    local topRight = decoration(sprites.cornerTop)
    topRight:SetPos(-BORDER_SIZE, 0, 1.0)
    topRight:SetSize(BORDER_SIZE, BORDER_SIZE)
    topRight.isFlippedHorizontally = true

    local bottomLeft = decoration(sprites.cornerBottom)
    bottomLeft:SetPos(0, -BORDER_SIZE, 0, 1.0)
    bottomLeft:SetSize(BORDER_SIZE, BORDER_SIZE)

    local bottomRight = decoration(sprites.cornerBottom)
    bottomRight:SetPos(-BORDER_SIZE, -BORDER_SIZE, 1.0, 1.0)
    bottomRight:SetSize(BORDER_SIZE, BORDER_SIZE)
    bottomRight.isFlippedHorizontally = true

    local container = ui.Layer.new(root)
    container:SetPos(BORDER_SIZE, BORDER_SIZE)
    container:SetSize(-BORDER_SIZE * 2, -BORDER_SIZE * 2, 1.0, 1.0)
    container.clickthrough = false
    container.enabled = true

    return container
end

---@param parent ui.Layer
---@param x integer
---@param width integer
---@param height integer
---@return ui.Text
function common.label(parent, x, width, height)
    local value = ui.Text.new(parent)
    value:SetPos(x, 0)
    value:SetSize(width, height)
    value.font = id.Font.MUSEO_SANS_15PT_REGULAR
    value.rgba = TEXT_COLOUR
    value.isShadowed = true
    value.alignHorizontal = ui.AlignMode.CENTRE
    value.alignVertical = ui.AlignMode.CENTRE
    value.clickthrough = true
    return value
end

return common
