local Ewent = require("zyklib/ewent/Ewent")
local lua_util = require("zyklib/lua_util")

---@class zyklib.Observable<T> : zyklib.Ewent<{old: T, new: T}, nil>
---@field private value T
---@field private equals fun(a: T, b: T): boolean
local Observable = {}
Observable.__index = Observable
setmetatable(Observable, { __index = Ewent })

---@generic T
---@param initial_value T
---@param equals? fun(a: T, b: T): boolean
---@return zyklib.Observable<T>
function Observable.new(initial_value, equals)
  ---@type zyklib.Observable<T>
  local self = Ewent.new(function() end)
  setmetatable(self, Observable)

  self.value = initial_value
  self.equals = equals or lua_util.deep_equals

  return self
end

---@generic T
---@param self zyklib.Observable<T>
---@return T
function Observable:get()
  return self.value
end

---@generic T
---@param self zyklib.Observable<T>
---@param value T
function Observable:set(value)
  local old = self.value

  if self.equals(old, value) then
    return
  end

  self.value = value
  self:trigger({
    old = old,
    new = value,
  })
end

return Observable
