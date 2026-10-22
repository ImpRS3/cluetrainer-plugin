local zyklib = require("zyklib")

local settings = {}

---@class ct.settings.Settings.Sliders
---@field enabled boolean
---@field mode "keyboard" | "mouse" | "hybrid"
---@field prevent_overlap boolean
---@field show_recovery_moves boolean
---@field color_mainline integer
---@field color_recovery integer
---@field solve_time number
---@field estimate_slider_speed boolean

---@class ct.settings.Settings.Knots
---@field enabled boolean

---@class ct.settings.Settings.Lockboxes
---@field enabled boolean
---@field optimization_coefficient number

---@class ct.settings.Settings.Towers
---@field enabled boolean
---@field info "delta" | "target" | "both"
---@field highlight_completed_tiles boolean

---@class ct.settings.Settings
---@field sliders ct.settings.Settings.Sliders
---@field knots ct.settings.Settings.Knots
---@field lockboxes ct.settings.Settings.Lockboxes
---@field towers ct.settings.Settings.Towers

-- TODO: Confirm the default values
--- @type ct.settings.Settings
settings.active_settings = {
  sliders = {
    enabled = true,
    mode = "hybrid",
    prevent_overlap = true,
    show_recovery_moves = true,
    color_mainline = 0x00FF00FF,
    color_recovery = 0xFFA500FF,
    solve_time = 5,
    estimate_slider_speed = true,
  },
  knots = {
    enabled = true,
  },
  lockboxes = {
    enabled = true,
    optimization_coefficient = 1,
  },
  towers = {
    enabled = true,
    info = "both",
    highlight_completed_tiles = true,
  },
}

return settings
