local elements = require("prettymap/elements")
local FontFamily = require("cluetrainer/util/FontFamily")

local LABEL_RGBA = 0xBFBFBFFF
local VALUE_RGBA = 0xFFFFFFFF
local ICON_SIZE = 20
local COLUMN_GAP = 8
local ROW_GAP = 2

--- Tooltip describing a teleport: header with icon and name, then label/value rows.
---@class cluetrainer.TeleportTooltip: prettymap.Tooltip
---@field teleport cluetrainer.TeleportSpot
local TeleportTooltip = setmetatable({}, { __index = elements.Tooltip })
TeleportTooltip.__index = TeleportTooltip

---@param teleport cluetrainer.TeleportSpot
---@param options prettymap.TooltipOptions?
---@return cluetrainer.TeleportTooltip
function TeleportTooltip.new(teleport, options)
  local self = setmetatable(elements.Tooltip.new(options), TeleportTooltip)
  self.teleport = teleport
  return self
end

---@param layer ui.Layer
---@param content string
---@param font FontType
---@param x integer
---@param y integer
---@param rgba integer
---@return integer width
---@return integer height
local function add_text(layer, content, font, x, y, rgba)
  local width, height = font:GetStringWidth(content), font.baseline
  local text = ui.Text.new(layer)
  text:SetPos(x, y)
  text:SetSize(width, height)
  text.content = content
  text.font = font.id
  text.rgba = rgba
  text.isShadowed = true
  text.clickthrough = true
  return width, height
end

---@param access TeleportAccess
---@return string
local function access_name(access)
  local name = access.name
  return type(name) == "table" and name.name or tostring(name)
end

--- Label/value rows describing how and how fast the teleport is reached.
---@param teleport cluetrainer.TeleportSpot
---@return {[1]: string, [2]: string[]}[]
local function property_rows(teleport)
  local rows = {}
  local menu, animation = teleport.props.menu_ticks, teleport.props.animation_ticks
  if teleport.access then
    rows[#rows + 1] = { "Accessed by", { access_name(teleport.access) } }
  end
  rows[#rows + 1] = { "Time", { string.format("%d (%d menu + %d animation)", menu + animation, menu, animation) } }
  rows[#rows + 1] = { "Static", { teleport.spot.target.size and "No" or "Yes" } }

  local alternatives = {}
  for _, access in ipairs(teleport.group.access or {}) do
    if access ~= teleport.access then alternatives[#alternatives + 1] = access_name(access) end
  end
  if #alternatives > 0 then
    rows[#rows + 1] = { teleport.access and "Alternative Access" or "Access", alternatives }
  end
  return rows
end

---@param layer ui.Layer
---@return boolean added
function TeleportTooltip:Build(layer)
  local teleport = self.teleport
  local title_font = FontFamily.NOTOSANS:Get(15, "bold")
  if not title_font then return false end
  local body_font = FontFamily.NOTOSANS:Get(11) or FontFamily.NOTOSANS:Get(11, "bold") or title_font

  local sprite_name = teleport.props.cache_data and teleport.props.cache_data.sprite
  local text_x = 0
  if sprite_name and id.Sprite[sprite_name] then
    local icon = ui.Sprite.new(layer)
    icon:SetPos(0, 0)
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon.sprite = id.Sprite[sprite_name]
    icon.clickthrough = true
    text_x = ICON_SIZE + COLUMN_GAP
  end

  local header_height = text_x > 0 and ICON_SIZE or title_font.baseline
  -- Vertically centred next to the icon.
  local title_y = math.max(0, math.floor((header_height - title_font.baseline) / 2))
  local title_width = add_text(layer, teleport:hover(), title_font, text_x, title_y, VALUE_RGBA)
  local width = text_x + title_width
  local y = header_height + ROW_GAP * 2

  local rows = property_rows(teleport)
  local label_width = 0
  for _, row in ipairs(rows) do
    label_width = math.max(label_width, body_font:GetStringWidth(row[1] .. ":"))
  end
  local value_x = label_width + COLUMN_GAP
  for _, row in ipairs(rows) do
    add_text(layer, row[1] .. ":", body_font, 0, y, LABEL_RGBA)
    for _, value in ipairs(row[2]) do
      local value_width, value_height = add_text(layer, value, body_font, value_x, y, VALUE_RGBA)
      width = math.max(width, value_x + value_width)
      y = y + value_height + ROW_GAP
    end
  end

  layer:SetSize(width, y)
  return true
end

return TeleportTooltip
