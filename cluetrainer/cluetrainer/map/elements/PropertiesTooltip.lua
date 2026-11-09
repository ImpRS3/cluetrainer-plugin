local luaflet = require("prettymap/luaflet")
local FontFamily = require("cluetrainer/util/FontFamily")

local MAX_WIDTH = 280
local PADDING_BELOW_HEADER = 4
local COLUMN_GAP = 8
local ROW_GAP = 3
local LABEL_RGBA = 0xBFBFBFFF
local TEXT_RGBA = 0xFFFFFFFF

---@alias cluetrainer.PropertiesLine
---| { kind: "header", text: string }
---| { kind: "subheader", text: string }
---| { kind: "paragraph", text: string }
---| { kind: "row", label: string, text: string }

--- A simple tooltip made of headers, wrapped paragraphs and label/value rows.
---@class cluetrainer.PropertiesTooltip : prettymap.Tooltip
---@field lines cluetrainer.PropertiesLine[]
local PropertiesTooltip = setmetatable({}, { __index = luaflet.Tooltip })
PropertiesTooltip.__index = PropertiesTooltip

---@param options prettymap.TooltipOptions?
---@return cluetrainer.PropertiesTooltip
function PropertiesTooltip.new(options)
  local self = setmetatable(luaflet.Tooltip.new(options), PropertiesTooltip)
  self.lines = {}
  return self
end

---@param text string
---@return cluetrainer.PropertiesTooltip self
function PropertiesTooltip:Header(text)
  self.lines[#self.lines + 1] = { kind = "header", text = text }
  return self
end

---@param text string
---@return cluetrainer.PropertiesTooltip self
function PropertiesTooltip:Subheader(text)
  self.lines[#self.lines + 1] = { kind = "subheader", text = text }
  return self
end

---@param text string
---@return cluetrainer.PropertiesTooltip self
function PropertiesTooltip:Paragraph(text)
  self.lines[#self.lines + 1] = { kind = "paragraph", text = text }
  return self
end

---@param label string
---@param text string
---@return cluetrainer.PropertiesTooltip self
function PropertiesTooltip:Row(label, text)
  self.lines[#self.lines + 1] = { kind = "row", label = label, text = text }
  return self
end

---@param text string
---@param font FontType
---@param max_width integer
---@return string[]
local function wrap(text, font, max_width)
  local lines, current = {}, nil
  for word in text:gmatch("%S+") do
    local candidate = current and (current .. " " .. word) or word
    if current and font:GetStringWidth(candidate) > max_width then
      lines[#lines + 1] = current
      current = word
    else
      current = candidate
    end
  end
  if current then lines[#lines + 1] = current end
  return lines
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

---@param layer ui.Layer
---@return boolean added
function PropertiesTooltip:Build(layer)
  local header_font = FontFamily.NOTOSANS:Get(15, "bold")
  if not header_font or #self.lines == 0 then return false end
  local body_font = FontFamily.NOTOSANS:Get(11) or FontFamily.NOTOSANS:Get(11, "bold") or header_font
  local subheader_font = FontFamily.NOTOSANS:Get(11, "bold") or body_font

  local label_width = 0
  for _, line in ipairs(self.lines) do
    if line.kind == "row" then
      label_width = math.max(label_width, body_font:GetStringWidth(line.label .. ":"))
    end
  end
  local value_x = label_width + COLUMN_GAP

  local width, y = 0, 0
  ---@param lines string[]
  ---@param font FontType
  ---@param x integer
  ---@param rgba integer
  local function add_lines(lines, font, x, rgba)
    for _, text in ipairs(lines) do
      local line_width, line_height = add_text(layer, text, font, x, y, rgba)
      width = math.max(width, x + line_width)
      y = y + line_height
    end
  end

  for index, line in ipairs(self.lines) do
    if index > 1 then y = y + ROW_GAP end
    if line.kind == "header" then
      add_lines(wrap(line.text, header_font, MAX_WIDTH), header_font, 0, TEXT_RGBA)
      y = y + PADDING_BELOW_HEADER
    elseif line.kind == "subheader" then
      add_lines(wrap(line.text, subheader_font, MAX_WIDTH), subheader_font, 0, TEXT_RGBA)
    elseif line.kind == "paragraph" then
      add_lines(wrap(line.text, body_font, MAX_WIDTH), body_font, 0, TEXT_RGBA)
    else
      add_text(layer, line.label .. ":", body_font, 0, y, LABEL_RGBA)
      add_lines(wrap(line.text, body_font, math.max(60, MAX_WIDTH - value_x)), body_font, value_x, TEXT_RGBA)
    end
  end

  layer:SetSize(math.max(width, 1), math.max(y, 1))
  return true
end

return PropertiesTooltip
