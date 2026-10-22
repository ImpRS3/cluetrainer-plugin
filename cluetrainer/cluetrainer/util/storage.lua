local storage = {}

local zyklib = require "zyklib"

local profile = zyklib.reactive.Observable.new("default")
local PREFIX = "settings/"

---@generic T
---@param key string
---@param schema ct.util.schema.Schema<T>
---@return zyklib.reactive.Observable<T>
---@return zyklib.reactive.Observable<T>
function storage.variable(key, schema)
  ---@type string
  local full_key

  profile:subscribe(function(current_profile)
    full_key = PREFIX .. current_profile .. "/" .. key
  end, true)

  local initial_value = schema(PersistentDB:Get(full_key))

  local observable = zyklib.reactive.Observable.new(initial_value)

  observable:subscribe(function(value)
    if value == nil then
      PersistentDB:Delete(full_key)
    else
      PersistentDB:Set(full_key, value)
    end
  end)

  return observable
end

return storage
