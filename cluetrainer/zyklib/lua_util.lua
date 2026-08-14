local lua_util = {}

---@generic T
---@param list T[]
---@param predicate fun(value: T, index: integer): boolean
---@return T?
function lua_util.find(list, predicate)
  for i, value in ipairs(list) do
    if predicate(value, i) then
      return value
    end
  end

  return nil
end

---Takes any value and turns it into a plain lua value.
---Particularly, this handles userdata values by calling all getter functions on the metatable and returning a table of the results.
---@param value any
---@return table | boolean | number | string | nil
function lua_util.to_plain_table(value)
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
      local plain_value = lua_util.to_plain_table(child)

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
          result[name] = lua_util.to_plain_table(field_value)
        end
      end
    end

    return result
  end

  return nil
end

---Compares two plain lua values or tables for deep equality.
---@param a boolean|number|string|table
---@param b boolean|number|string|table
---@return boolean 
function lua_util.deepEquals(a, b)
  if a == b then
    return true
  end

  if type(a) ~= "table" or type(b) ~= "table" then
    return false
  end

  for k, v in pairs(a) do
    if not lua_util.deepEquals(v, b[k]) then
      return false
    end
  end

  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end

  return true
end

function lua_util.shallow_copy(orig)
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

---@generic T
---@generic U
---@param list T[]
---@param func fun(value: T, index: integer): U
---@return U[]
function lua_util.map(list, func)
  local result = {}
  for i, v in ipairs(list) do
    table.insert(result, func(v, i))
  end
  return result
end

return lua_util
