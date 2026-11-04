local storage = require("cluetrainer/util/storage")
local schema  = require("cluetrainer/util/schema")

---Persists the position, and optionally the size, of a PrettyUI window or panel.
---@class ct.util.WindowGeometry
---@field private value zyklib.reactive.Observable<ct.util.WindowGeometry.Value>
---@field private save_size boolean
local WindowGeometry = {}
WindowGeometry.__index = WindowGeometry

---@class ct.util.WindowGeometry.Value
---@field saved boolean Whether a geometry was ever saved
---@field x number
---@field y number
---@field width number
---@field height number

---@class ct.util.WindowGeometry.Options
---@field size boolean? Whether to persist and restore the size as well. Default false

---@param key string Storage key, unique per window
---@param options ct.util.WindowGeometry.Options?
---@return ct.util.WindowGeometry
function WindowGeometry.new(key, options)
  local self = setmetatable({}, WindowGeometry)

  self.save_size = options ~= nil and options.size == true
  self.value = storage.preference(key, schema.struct({
    saved = schema.bool({ default = false }),
    x = schema.number({ default = 0 }),
    y = schema.number({ default = 0 }),
    width = schema.number({ default = 0 }),
    height = schema.number({ default = 0 }),
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
  if not saved.saved then return options end

  options.x, options.y = saved.x, saved.y
  options.xAnchor, options.yAnchor = 0, 0

  if self.save_size and saved.width > 0 and saved.height > 0 then
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
    saved = true,
    x = root.x,
    y = root.y,
    width = self.save_size and root.width or 0,
    height = self.save_size and root.height or 0,
  })
end

return WindowGeometry
