local zyklib = require("zyklib")

--- A normalizer is a function that takes any value and returns a normalized value of the same type.
---@generic T
---@alias ct.util.schema.Schema<T> fun(value?: any): T

---@class ct.util.schema.Schemas
local schema = {}

---@param options {min: integer, max: integer, default: integer }
---@return ct.util.schema.Schema<integer>
function schema.int(options)
  return function(value)
    if type(value) ~= "number" then return options.default end

    if value < options.min then
      return options.min
    elseif value > options.max then
      return options.max
    else
      return math.floor(value)
    end
  end
end

---@param options {default: boolean}
---@return ct.util.schema.Schema<boolean>
function schema.bool(options)
  return function(value)
    if type(value) ~= "boolean" then return options.default end

    return value
  end
end

---@generic T
---@param options {choices: T[], default: T}
---@return ct.util.schema.Schema<T>
function schema.choices(options)
  return function(value)
    if zyklib.array.includes(options.choices, value) then
      return value
    else
      return options.default
    end
  end
end

---@param options {default: integer}
---@return ct.util.schema.Schema<integer>
function schema.colour(options)
  return function(val)
    return schema.int({ min = 0, max = 0xFFFFFFFF, default = options.default })(val) | 0xFF
  end
end

---@param options {min: number?, max: number?, default: number}
---@return ct.util.schema.Schema<number>
function schema.number(options)
  return function(value)
    if type(value) ~= "number" then return options.default end

    return math.max(options.min or -math.huge, math.min(options.max or math.huge, value))
  end
end

--- Normalizes each field with its normalizer and removes all keys that are not part of the struct.
---@param table any
---@return ct.util.schema.Schema<table>
function schema.struct(table)
  return function(value)
    if type(value) ~= "table" then value = {} end

    -- Clear all keys that are not part of the struct
    for key in pairs(value) do
      if table[key] == nil then
        value[key] = nil
      end
    end

    -- Normalize each field using its corresponding normalizer
    for key, normalizer in pairs(table) do
      value[key] = normalizer(value[key])
    end

    return value
  end
end

return schema
