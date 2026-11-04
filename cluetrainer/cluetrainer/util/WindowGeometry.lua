local storage = require("cluetrainer/util/storage")
local schema  = require("cluetrainer/util/schema")

---Persists the position, and optionally the size, of a PrettyUI window or panel.
---@class ct.util.WindowGeometry
---@field private value zyklib.reactive.Observable<ct.util.WindowGeometry.Value>
---@field private save_size boolean
local WindowGeometry = {}
WindowGeometry.__index = WindowGeometry

---@class ct.util.WindowGeometry.Value
---@field x number? Nil until a geometry was saved
---@field y number?
---@field width number?
---@field height number?

---@class ct.util.WindowGeometry.Options
---@field size boolean? Whether to persist and restore the size as well. Default false

---@param key string Storage key, unique per window
---@param options ct.util.WindowGeometry.Options?
---@return ct.util.WindowGeometry
function WindowGeometry.new(key, options)
  local self = setmetatable({}, WindowGeometry)

  self.save_size = options ~= nil and options.size == true
  self.value = storage.preference(key, schema.struct({
    x = schema.number({}),
    y = schema.number({}),
    width = schema.number({}),
    height = schema.number({}),
  }))

  return self
end

---Overrides the position (and size, if persisted) in the window creation options with the saved values.
---Without saved values the options are returned unchanged.
---@generic T : table
---@param options T PrettyUI.Window or PrettyUI.Panel options
---@return T options The same table
function WindowGeometry:apply(options)
  local saved = self.value:get()
  if saved.x == nil or saved.y == nil then return options end

  options.x, options.y = saved.x, saved.y
  options.xAnchor, options.yAnchor = 0, 0

  if self.save_size and saved.width ~= nil and saved.height ~= nil then
    options.width, options.height = saved.width, saved.height
  end

  return options
end

---Persists the current geometry of the window or panel.
---@param window PrettyUI.Window | PrettyUI.Panel
function WindowGeometry:save(window)
  -- A popped out panel lives on its overlay surface, otherwise the root is the window itself
  local root = window.poppedOut and window.overlay and window.overlay.root or window.root
  if root == nil then return end

  self.value:set({
    x = root.x,
    y = root.y,
    width = self.save_size and root.width or nil,
    height = self.save_size and root.height or nil,
  })
end

return WindowGeometry
