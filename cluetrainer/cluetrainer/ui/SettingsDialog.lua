local settings = require("cluetrainer/settings")
local zyklib = require("zyklib")

local SettingsDialog = {}

---@type prettyui.Window?
local window = nil

local TITLE_COLOR = 0xf0be79ff
local DESCRIPTION_COLOUR = 0xdbcfc7ff
local SETTINGS_NAME_COLOUR = 0xb4a092ff
local ROW_COLOURS = { 0x24211EFF, 0x2E2825FF }

-- Nil keeps the default title font (Cinzel). Set an id.Font value here to change the title size.
local TITLE_FONT = nil
-- Average glyph width of the title font in interface units, used to centre titles. Adjust with the font.
local TITLE_CHAR_WIDTH = 11

-- Every setting spans several flow rows, so its components share a row background group to be painted as one block.
local group_counter = 0

---@return string
local function nextGroup()
  group_counter = group_counter + 1
  return "setting_" .. group_counter
end

--- Adds a greyed out explanation below a setting.
local function addDescription(page, text, group)
  page:AddText({ text = text, colour = DESCRIPTION_COLOUR, marginTop = 2, rowBackgroundGroup = group })
end

local TOGGLE_DESCRIPTION_WIDTH = 380

--- Adds an explanation with an unlabelled checkbox to its right. The label is only shown as a tooltip.
---@param page prettyui.core.View
---@param label string
---@param description string
---@param value boolean
---@param on_change fun(value: boolean)
local function addToggle(page, label, description, value, on_change)
  local group = nextGroup()

  page:AddText({
    text = description,
    colour = DESCRIPTION_COLOUR,
    width = TOGGLE_DESCRIPTION_WIDTH,
    marginTop = 8,
    rowBackgroundGroup = group,
  })
  page:AddCheckboxButton({
    { text = "", value = "on", selected = value },
  }, {
    inline = true,
    columnGap = 8,
    marginTop = 8,
    tooltip = label,
    rowBackgroundGroup = group,
    onChange = function(_, values)
      on_change(#values > 0)
    end,
  })
end

--- Adds a radio group with an explanation.
---@generic T
---@param page table
---@param title string
---@param description string
---@param choices { text: string, value: T, tooltip: string? }[]
---@param value T
---@param on_change fun(value: T)
local function addChoice(page, title, description, choices, value, on_change)
  local group = nextGroup()

  page:AddText({ text = title, colour = SETTINGS_NAME_COLOUR, marginTop = 12, rowBackgroundGroup = group })
  addDescription(page, description, group)

  -- The group is inline and would otherwise join the description's row, so an empty row is added for it to join instead.
  page:AddText({ text = "", height = 1, marginTop = 0, marginBottom = 0, rowBackgroundGroup = group })
  page:AddRadioButton(choices, {
    inline = true,
    selectedValue = value,
    rowBackgroundGroup = group,
    onChange = function(_, selected)
      on_change(selected)
    end,
  })
end

--- Adds a colour picker with a label and an explanation.
local function addColour(page, title, description, value, on_change)
  local group = nextGroup()

  page:AddText({ text = title, colour = SETTINGS_NAME_COLOUR, marginTop = 12, rowBackgroundGroup = group })
  addDescription(page, description, group)
  page:AddColourPicker({
    value = value,
    windowTitle = title,
    rowBackgroundGroup = group,
    onChange = function(_, colour)
      on_change(colour)
    end,
  })
end

--- Adds a numeric slider with a label showing its current value and an explanation.
local function addNumber(page, title, description, config, value, on_change)
  local group = nextGroup()

  local label = page:AddText({
    text = title .. ": " .. tostring(value),
    colour = SETTINGS_NAME_COLOUR,
    marginTop = 12,
    rowBackgroundGroup = group,
  })
  addDescription(page, description, group)
  page:AddSlider({
    min = config.min,
    max = config.max,
    step = config.step,
    value = value,
    rowBackgroundGroup = group,
    onChange = function(_, new_value)
      label.content = title .. ": " .. tostring(new_value)
      on_change(new_value)
    end,
  })
end

--- Adds a page title. It is excluded from the alternating row colours.
local function addPageTitle(page, text)
  -- PrettyUI has no text alignment option, so the title is centred by estimating its width.
  local page_width = page.width or 454
  local estimated_width = #text * TITLE_CHAR_WIDTH

  page:AddTitle({
    text = text,
    font = TITLE_FONT,
    colour = TITLE_COLOR,
    x = math.max(0, math.floor((page_width - estimated_width) / 2)),
    rowBackground = false,
  })
end

--- Adds a smaller section header within a page. It is excluded from the alternating row colours.
local function addSection(page, text)
  page:AddText({
    text = text,
    font = id.Font.NOTOSANS_BOLD_12,
    colour = TITLE_COLOR,
    marginTop = 12,
    rowBackground = false,
  })
end

---@param page table
local function buildSliders(page)
  local s = settings.active_settings.sliders

  addPageTitle(page, "Slider puzzles")

  addSection(page, "General")

  addToggle(page, "Enabled", "Show the solution overlay for slider puzzles.", s.enabled, function(v) s.enabled = v end)

  addChoice(page, "Input mode",
    "How you move the tiles. In keyboard and hybrid mode, single-tile moves are shown as arrows to press instead of tiles to click.",
    {
      { text = "Keyboard", value = "keyboard" },
      { text = "Mouse",    value = "mouse" },
      { text = "Hybrid",   value = "hybrid" },
    }, s.mode, function(v) s.mode = v end)

  addSection(page, "Overlay")

  addToggle(page, "Prevent overlap",
    "Stops drawing the solution at the first move that would cover a tile already passed over by an earlier move, so the overlay stays readable.",
    s.prevent_overlap, function(v) s.prevent_overlap = v end)

  addToggle(page, "Show recovery moves",
    "TODO: Describe recovery moves.",
    s.show_recovery_moves, function(v) s.show_recovery_moves = v end)

  addColour(page, "Mainline colour", "Colour used to draw the moves of the solution.",
    s.color_mainline, function(v) s.color_mainline = v end)

  addColour(page, "Recovery colour", "TODO: Describe where this colour is used.",
    s.color_recovery, function(v) s.color_recovery = v end)

  addSection(page, "Solver")

  -- TODO: Confirm the unit and the range
  addNumber(page, "Solve time", "TODO: Describe how long the solver is allowed to search for a solution.",
    { min = 1, max = 30, step = 1 }, s.solve_time, function(v) s.solve_time = v end)

  addToggle(page, "Estimate slider speed",
    "TODO: Describe how the slider speed is estimated and used.",
    s.estimate_slider_speed, function(v) s.estimate_slider_speed = v end)
end

---@param page table
local function buildKnots(page)
  local s = settings.active_settings.knots

  addPageTitle(page, "Knots")

  addToggle(page, "Enabled", "Show the solution overlay for knot puzzles.", s.enabled, function(v) s.enabled = v end)
end

---@param page table
local function buildLockboxes(page)
  local s = settings.active_settings.lockboxes

  addPageTitle(page, "Lockboxes")

  addSection(page, "General")

  addToggle(page, "Enabled", "Show the solution overlay for lockbox puzzles.", s.enabled, function(v) s.enabled = v end)

  addSection(page, "Solver")

  -- TODO: Confirm the range
  addNumber(page, "Optimization coefficient",
    "TODO: Describe how this coefficient trades off the solution against the solver's other goals.",
    { min = 0, max = 2, step = 0.05 }, s.optimization_coefficient, function(v) s.optimization_coefficient = v end)
end

---@param page table
local function buildTowers(page)
  local s = settings.active_settings.towers

  addPageTitle(page, "Towers")

  addSection(page, "General")

  addToggle(page, "Enabled", "Show the solution overlay for tower puzzles.", s.enabled, function(v) s.enabled = v end)

  addSection(page, "Overlay")

  addChoice(page, "Displayed information",
    "TODO: Describe the difference between the options. Delta presumably shows the change required for a tile, target the value it needs to end up at.",
    {
      { text = "Delta",  value = "delta" },
      { text = "Target", value = "target" },
      { text = "Both",   value = "both" },
    }, s.info, function(v) s.info = v end)

  addToggle(page, "Highlight completed tiles",
    "TODO: Describe how completed tiles are highlighted.",
    s.highlight_completed_tiles, function(v) s.highlight_completed_tiles = v end)
end

--- Returns the currently active settings.
---@return ct.settings.Settings
function SettingsDialog.get()
  return settings.active_settings
end

--- Opens the settings window, or raises it if it is already open.
function SettingsDialog.open()
  if window ~= nil then
    window:Show()
    return
  end

  local parent = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA)

  local WINDOW_WIDTH = 600
  local WINDOW_HEIGHT = 460
  local NAV_WIDTH = 110
  local VIEW_X = NAV_WIDTH + 20

  window = prettyui.Window.new(parent, {
    title = "Clue Trainer",
    x = -WINDOW_WIDTH // 2,
    y = -WINDOW_HEIGHT // 2,
    xAnchor = 0.5,
    yAnchor = 0.5,
    width = WINDOW_WIDTH,
    height = WINDOW_HEIGHT,
    scrollable = false,
    destroyOnClose = true,
    onClose = function()
      window = nil
    end,
  })

  local pages = {
    { name = "Sliders",   build = buildSliders },
    { name = "Knots",     build = buildKnots },
    { name = "Lockboxes", build = buildLockboxes },
    { name = "Towers",    build = buildTowers },
  }

  ---@type prettyui.SimpleButton[]
  local buttons = {}

  ---@type table?
  local current_view = nil

  -- Only the selected page exists at any time. Hidden views kept on top of each other can swallow the input meant for the visible one.
  local function select(index)
    if current_view ~= nil then
      current_view:Destroy()
    end

    for i, button in ipairs(buttons) do
      button:SetActive(i == index)
    end

    -- A Panel is used instead of a SimpleView because the docs list row backgrounds for windows, panels and tab pages only.
    current_view = prettyui.Panel.new(window.content, {
      x = VIEW_X,
      y = 0,
      width = WINDOW_WIDTH - VIEW_X - 16,
      height = WINDOW_HEIGHT - 60,
      rowBackgroundColours = ROW_COLOURS,
      backgroundAlpha = 0,
    })

    pages[index].build(current_view)

    current_view:RefreshRowBackgrounds()
  end

  for i, page in ipairs(pages) do
    buttons[i] = window:AddSimpleButton(page.name, function() select(i) end, { width = NAV_WIDTH })
  end

  select(1)
  zyklib.lifecycle.shutdown_event:subscribe(function()
    if window ~= nil then
      window:Destroy()
      window = nil
    end
  end)
end

return SettingsDialog
