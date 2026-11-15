local zyklib = require "zyklib"

---@alias ct.util.PersistentVariableType "int" | "generic"

---@param key string
---@param type ct.util.PersistentVariableType
---@return any?
local function persistent_get(key, type)
  if type == "int" then
    return PersistentDB:GetInt(key)
  else
    return PersistentDB:Get(key)
  end
end

---@param key string
---@param type ct.util.PersistentVariableType
---@param value any
local function persistent_set(key, type, value)
  if type == "int" then
    PersistentDB:SetInt(key, value)
  else
    PersistentDB:Set(key, value)
  end
end

---@class ct.util.PersistentVariable<T>
---@field parent ct.util.StorageManager
---@field type ct.util.PersistentVariableType
---@field name string
---@field schema fun(value: any): T
---@field _observable zyklib.reactive.Observable<T>?
local PersistentVariable = {}
PersistentVariable.__index = PersistentVariable

---@generic T
---@param parent ct.util.StorageManager
---@param name string
---@param schema fun(value: any): T
---@param is_profile_specific boolean
---@param type ct.util.PersistentVariableType?
---@return ct.util.PersistentVariable
function PersistentVariable.new(parent, name, schema, is_profile_specific, type)
  local self

  --- @class ct.util.PersistentVariable<T>
  self = setmetatable({
    parent = parent,
    name = name,
    schema = schema,
    is_profile_specific = is_profile_specific,
    _observable = nil,
    type = type or "generic",
    value = nil
  }, PersistentVariable)

  if is_profile_specific then
    parent.active_profile:observable():subscribe(function() self:reload() end)
  end

  self:reload()

  return self
end

function PersistentVariable:fullKey()
  if self.is_profile_specific then
    return self.parent.domain .. "/profiles/" .. self.parent.active_profile:get() .. "/" .. self.name
  else
    return self.parent.domain .. "/" .. self.name
  end
end

function PersistentVariable:observable()
  if not self._observable then
    self._observable = zyklib.reactive.Observable.new(self:get())
  end

  return self._observable
end

---Reloads the value of this persistent variable from the database
function PersistentVariable:reload()
  local loaded_value = persistent_get(self:fullKey(), self.type)

  self.value = self.schema(loaded_value)

  if self._observable ~= nil then
    self._observable:set(self.value)
  end
end

---@generic T
---@param self ct.util.PersistentVariable<T>
---@return T
function PersistentVariable:get()
  return self.value
end

---@generic T
---@param self ct.util.PersistentVariable<T>
---@param value T
---@return nil
function PersistentVariable:set(value)
  persistent_set(self:fullKey(), self.type, value)
  self.value = value

  if self._observable ~= nil then
    self._observable:set(self.value)
  end
  self:reload()
end

---@class ct.util.StorageManager
local StorageManager = {}
StorageManager.__index = StorageManager

function StorageManager.new(domain, default_profile_name)
  ---@class ct.util.StorageManager
  local self = setmetatable({
    domain = domain,
    default_profile_name = default_profile_name
  }, StorageManager)

  self.active_profile = PersistentVariable.new(self, "active_profile", function(value)
    return value or default_profile_name
  end, false)

  return self
end

--- @param profile_name string
function StorageManager:setProfile(profile_name)
  self.active_profile:set(profile_name)
end

---Create a profile specific variable that will automatically update when the profile is changed
---@generic T
---@param name string
---@param schema ct.util.schema.Schema<T>
---@param type ct.util.PersistentVariableType?
---@return ct.util.PersistentVariable<T>
function StorageManager:profileVariable(name, schema, type)
  return PersistentVariable.new(self, name, schema, true, type or "generic")
end

---Create a global variable that is not tied to any specific profile
---@generic T
---@param name string
---@param schema ct.util.schema.Schema<T>
---@param type ct.util.PersistentVariableType?
---@return ct.util.PersistentVariable<T>
function StorageManager:globalVariable(name, schema, type)
  return PersistentVariable.new(self, name, schema, false, type or "generic")
end

return StorageManager
