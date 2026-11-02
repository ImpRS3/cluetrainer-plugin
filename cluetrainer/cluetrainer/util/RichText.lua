---@class ct.util.RichText
local RichText = {}

---@param text string
---@param color string The color code as a hexadecimal string, e.g., "FF0000" for red
function RichText.coloured(text, color)
  return "<col=" .. color .. ">" .. text .. "</col>"
end

---@param name string
function RichText.loc(name)
  return RichText.coloured(name, "00FFFF")
end

---@param name string
function RichText.npc(name)
  return RichText.coloured(name, "FFFF00")
end

function RichText.membersItem(name)
  return RichText.coloured(name, "F8D56B")
end

function RichText.freetoplayItem(name)
  return RichText.coloured(name, "B8D1D1")
end

---@param obj ObjType
function RichText.obj(obj)
  if obj.isMembers then
    return RichText.membersItem(obj.name)
  else
    return RichText.freetoplayItem(obj.name)
  end
end

function RichText.newline()
  return "<br>"
end

function RichText.bold(text)
  return "<b>" .. text .. "</b>"
end

function RichText.italic(text)
  return "<i>" .. text .. "</i>"
end

function RichText.strikethrough(text, color)
  if color then
    return "<str=" .. color .. ">" .. text .. "</str>"
  else
    return "<str>" .. text .. "</str>"
  end
end

function RichText.underlined(text, color)
  if color then
    return "<u=" .. color .. ">" .. text .. "</u>"
  else
    return "<u>" .. text .. "</u>"
  end
end

function RichText.less()
  return "<lt>"
end

function RichText.greater()
  return "<gt>"
end

return RichText
