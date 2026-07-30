-- util.lua

local util = {}

---@generic T
---@param list T[]
---@param predicate fun(value: T, index: integer): boolean
---@return T?
function util.find(list, predicate)
  for i, value in ipairs(list) do
    if predicate(value, i) then
      return value
    end
  end

  return nil
end

function util.to_plain_table(value)
  local value_type = type(value)

  -- Values directly supported by most serializers.
  if value_type == "nil"
      or value_type == "boolean"
      or value_type == "number"
      or value_type == "string"
  then
    return value
  end

  if value_type == "table" then
    local result = {}

    for key, child in pairs(value) do
      local plain_value = util.to_plain_table(child)

      result[key] = plain_value
    end

    return result
  end

  if value_type == "userdata" then
    local result = {}
    local metatable = getmetatable(value)

    for name, getter in pairs(metatable) do
      if type(name) == "string"
          and name:sub(1, 2) ~= "__"
          and type(getter) == "function"
      then
        -- Assumes getter functions are methods: getter(value).
        local ok, field_value = pcall(function()
          return value[name]
        end)

        if ok then
          result[name] = util.to_plain_table(field_value)
        end
      end
    end

    return result
  end

  return nil
end

function util.serializeTable(val, name, skipnewlines, depth)
  skipnewlines = skipnewlines or false
  depth = depth or 0

  local tmp = string.rep(" ", depth)

  if name then tmp = tmp .. name .. " = " end

  if type(val) == "table" then
    tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

    for k, v in pairs(val) do
      tmp = tmp .. util.serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
    end

    tmp = tmp .. string.rep(" ", depth) .. "}"
  elseif type(val) == "number" then
    tmp = tmp .. tostring(val)
  elseif type(val) == "string" then
    tmp = tmp .. string.format("%q", val)
  elseif type(val) == "boolean" then
    tmp = tmp .. (val and "true" or "false")
  else
    tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
  end

  return tmp
end

function util.diff(a, b, path, out)
  path = path or ""
  out = out or {}

  -- Different types
  if type(a) ~= type(b) then
    out[path] = { old = a, new = b }
    return out
  end

  -- Primitive values
  if type(a) ~= "table" then
    if a ~= b then
      out[path] = { old = a, new = b }
    end
    return out
  end

  -- Compare all keys
  local seen = {}

  for k, va in pairs(a) do
    seen[k] = true
    local p = path == "" and tostring(k) or (path .. "." .. tostring(k))
    util.diff(va, b[k], p, out)
  end

  for k, vb in pairs(b) do
    if not seen[k] then
      local p = path == "" and tostring(k) or (path .. "." .. tostring(k))
      out[p] = { old = nil, new = vb }
    end
  end

  return out
end

function util.shallow_copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

return util
