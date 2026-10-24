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
local TITLE_FONT = config.Font.CINZEL_18PT_BOLD

-- Every setting spans several flow rows, so its components share a row background group to be painted as one block.
local group_counter = 0

---@return integer
local function nextGroup()
  group_counter = group_counter + 1
  return group_counter
end

-- Panel border, inner padding and scrollbar gutter that the page width does not account for.
local PAGE_PADDING = 60
-- Space kept free right of the text for an inline control (its size, the column gap and some padding). Estimated, tune visually.
local CHECKBOX_RESERVED = 24
local COLOUR_RESERVED = 30
-- Space for the value label right of a slider. Estimated, tune visually.
local VALUE_LABEL_RESERVED = 50

--- Width left for text on a page after reserving space on the right.
---@param page prettyui.Panel
---@param reserved integer?
---@return integer
local function availableWidth(page, reserved)
  return page.width - PAGE_PADDING - (reserved or 0)
end

--- Adds the title of a setting.
---@param page prettyui.Panel
---@param text string
---@param group integer
---@param reserved integer? Space kept free on the right hand side
local function addSettingTitle(page, text, group, reserved)
  return page:AddText({
    text = text,
    colour = SETTINGS_NAME_COLOUR,
    marginTop = 12,
    rowBackgroundGroup = group,
    width = availableWidth(page, reserved),
  })
end

--- Adds a greyed out explanation below a setting.
---@param reserved integer? Space kept free on the right hand side
local function addDescription(page, text, group, reserved)
  if not text or text == "" then return nil end

  return page:AddText({
    text = text,
    colour = DESCRIPTION_COLOUR,
    marginTop = 2,
    rowBackgroundGroup = group,
    width = availableWidth(page, reserved),
  })
end

-- Estimated control heights in interface units. Tune visually.
local CHECKBOX_HEIGHT = 20
local COLOUR_HEIGHT = 20
local FALLBACK_TEXT_HEIGHT = 16

--- An inline control joins the row of the description. This offset moves it to the vertical middle of the title and description.
---@param title table
---@param description table?
---@param control_height number
---@return number
local function centeredOffset(title, description, control_height)
  local title_height = title.height or FALLBACK_TEXT_HEIGHT
  local description_height = description and (description.height or FALLBACK_TEXT_HEIGHT) or 0
  local block_height = title_height + (description and 2 or 0) + description_height

  local row_top = description and (title_height + 2) or 0

  return block_height / 2 - row_top - control_height / 2
end

--- Adds an explanation with an unlabelled checkbox to its right. The label is only shown as a tooltip.
---@param page prettyui.Panel
---@param label string
---@param description string
---@param setting zyklib.reactive.Observable<boolean>
local function addToggle(page, label, description, setting)
  local group = nextGroup()

  local title = addSettingTitle(page, label, group, CHECKBOX_RESERVED)
  local text = addDescription(page, description, group, CHECKBOX_RESERVED)

  page:AddCheckboxButton({
    { text = "", value = "on", selected = setting:get() },
  }, {
    inline = true,
    columnGap = 8,
    offsetY = centeredOffset(title, text, CHECKBOX_HEIGHT),
    rowBackgroundGroup = group,
    onChange = function(group, values, value, selected)
      setting:set(selected)
    end,
  })
end

--- Adds a radio group with an explanation.
---@generic T
---@param page prettyui.Panel
---@param title string
---@param description string
---@param choices { text: string, value: T, tooltip: string? }[]
---@param setting zyklib.reactive.Observable<T>
local function addChoice(page, title, description, choices, setting)
  local group = nextGroup()

  addSettingTitle(page, title, group)
  addDescription(page, description, group)

  -- The group is inline and would otherwise join the description's row, so an empty row is added for it to join instead.
  page:AddText({ text = "", height = 1, marginTop = 0, marginBottom = 0, rowBackgroundGroup = group })
  page:AddRadioButton(choices, {
    inline = true,
    selectedValue = setting:get(),
    rowBackgroundGroup = group,
    onChange = function(_, selected)
      setting:set(selected)
    end,
  })
end

--- Adds a colour picker with a label and an explanation.
---@param setting zyklib.reactive.Observable<integer>
local function addColour(page, title, description, setting)
  local group = nextGroup()

  local title_text = addSettingTitle(page, title, group, COLOUR_RESERVED)
  local text = addDescription(page, description, group, COLOUR_RESERVED)
  page:AddColourPicker({
    value = setting:get(),
    windowTitle = title,
    inline = true,
    offsetY = centeredOffset(title_text, text, COLOUR_HEIGHT),
    rowBackgroundGroup = group,
    onChange = function(_, colour)
      setting:set(colour)
    end,
  })
end

--- Adds a numeric slider with its current value shown to the right, and an explanation.
---@param config { min: number, max: number, step: number, format: (fun(value: number): string)?, reserved: integer? }
--- `format` renders the value as displayed text (default `tostring`), `reserved` is the width kept free for that text.
---@param setting zyklib.reactive.Observable<number>
local function addNumber(page, title, description, config, setting)
  local group = nextGroup()
  local format = config.format or tostring
  local value = setting:get()

  addSettingTitle(page, title, group)
  addDescription(page, description, group)

  local value_label
  local slider = page:AddSlider({
    min = config.min,
    max = config.max,
    step = config.step,
    value = value,
    width = availableWidth(page, config.reserved or VALUE_LABEL_RESERVED),
    rowBackgroundGroup = group,
    onChange = function(_, new_value)
      value_label.content = format(new_value)
      setting:set(new_value)
    end,
  })

  value_label = page:AddText({
    text = format(value),
    colour = SETTINGS_NAME_COLOUR,
    inline = true,
    columnGap = 8,
    offsetY = centeredOffset(slider, nil, FALLBACK_TEXT_HEIGHT),
    rowBackgroundGroup = group,
  })
end

--- Adds a page title. It is excluded from the alternating row colours.
local function addPageTitle(page, text)
  -- PrettyUI has no text alignment option, so the title is centred by estimating its width.
  local page_width = page.width
  local estimated_width = TITLE_FONT:GetStringWidth(text)

  page:AddTitle({
    text = text,
    font = TITLE_FONT.id,
    colour = TITLE_COLOR,
    x = math.max(0, math.floor((page_width - estimated_width) / 2)),
    rowBackground = false,
  })
end

--- Adds a smaller section header within a page. It is excluded from the alternating row colours.
local function addSection(page, text)
  page:AddText({
    text = text,
    font = id.Font.NOTOSANS_BOLD_14,
    colour = TITLE_COLOR,
    marginTop = 12,
    rowBackground = false,
  })
end

---@param page table
local function buildSliders(page)
  addPageTitle(page, "Slider puzzles")

  addToggle(page, "Enabled", "Show solutions for slider puzzles.", settings.sliders.enabled)

  addChoice(page, "Input mode",
    "How you move the tiles. In mouse mode, all required clicks are drawn as boxes. Keyboard mode shows arrows for every single-tile move. Hybrid mode uses boxes for multitile moves and arrows for single-tile moves.",
    {
      { text = "Keyboard", value = "keyboard" },
      { text = "Mouse",    value = "mouse" },
      { text = "Hybrid",   value = "hybrid" },
    }, settings.sliders.mode)

  addSection(page, "Overlay")

  addNumber(page, "Lookahead", "Maximum number of moves ahead to draw.",
    {
      min = 2,
      max = 10,
      step = 1,
      format = function(value)
        return formatStr("{:.0f}", value)
      end
    }, settings.sliders.lookahead)

  addToggle(page, "Prevent overlap",
    "Stops drawing the solution at the first move that would cover a tile already passed over by an earlier move, so the overlay stays readable.",
    settings.sliders.prevent_overlap)

  addToggle(page, "Show recovery moves",
    "When making a mistake (e.g. misclicking), recovery moves are shown to guide you back to the correct solution.",
    settings.sliders.show_recovery_moves)

  addColour(page, "Mainline colour", "Colour used to draw the moves of the solution.",
    settings.sliders.color_mainline)

  addColour(page, "Recovery colour", "Colour used to draw the recovery moves.",
    settings.sliders.color_recovery)

  addSection(page, "Solver")

  addNumber(page, "Solve time", "How much time the solver is allowed to spend on finding a solution before drawing it on the overlay.",
    {
      min = 100,
      max = 5000,
      step = 100,
      format = function(value)
        return formatStr("{:.1f} s", value / 1000)
      end
    }, settings.sliders.solve_time)

  addToggle(page, "Estimate slider speed",
    "When enabled, the solver will display an estimate for the classic Alt1 Clue Solver's slider speed you would have achieved with your solving speed after completing a puzzle.",
    settings.sliders.estimate_slider_speed)
end

---@param page table
local function buildKnots(page)
  addPageTitle(page, "Knots")

  addToggle(page, "Enabled", "Show solutions for celtic knot puzzles.", settings.knots.enabled)
end

---@param page table
local function buildLockboxes(page)
  addPageTitle(page, "Lockboxes")

  addToggle(page, "Enabled", "Show solutions for lockbox puzzles.", settings.lockboxes.enabled)

  addSection(page, "Solver")

  addNumber(page, "Optimization coefficient",
    "Determines how the solver balances single-click tiles against double-click tiles. The selected value determines the weight of double-click tiles relative to single-click tiles. Higher values favor lower number of tiles that need to be clicked overall, while lower values optimize for total number of clicks.",
    {
      min = 10,
      max = 50,
      step = 1,
      format = function(value)
        return formatStr("{:.1f}", value / 10)
      end
    }, settings.lockboxes.optimization_coefficient)
end

---@param page table
local function buildTowers(page)
  addPageTitle(page, "Towers")

  addToggle(page, "Enabled", "Show the solution overlay for tower puzzles.", settings.towers.enabled)

  addSection(page, "Overlay")

  addChoice(page, "Displayed information",
    "Choose which value is displayed on the tower puzzle overlay. Delta shows the change required for a tile, i.e. the number of 'Increment' actions needed. Target shows the final value the tile needs to reach. Both displays both pieces of information.",
    {
      { text = "Delta",  value = "delta" },
      { text = "Target", value = "target" },
      { text = "Both",   value = "both" },
    }, settings.towers.info)

  addToggle(page, "Highlight completed tiles",
    "When enabled, completed tiles receive a transparent green overlay.",
    settings.towers.highlight_completed_tiles)
end

--- Mounts the settings pages (navigation on the left, selected page on the right) onto a layer.
---@param layer ui.Layer
---@return prettyui.SimpleView view The view hosting the settings. Destroy it to remove them again.
function SettingsDialog.mount(layer)
  local NAV_WIDTH = 110
  local VIEW_X = NAV_WIDTH + 25

  local host = prettyui.SimpleView.new(layer, {
    width = layer.width,
    height = layer.height,
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
    current_view = prettyui.Panel.new(layer, {
      x = VIEW_X,
      y = 0,
      width = layer.width - VIEW_X,
      height = layer.height,
      rowBackgroundColours = ROW_COLOURS,
    })

    pages[index].build(current_view)

    current_view:RefreshRowBackgrounds()
  end

  for i, page in ipairs(pages) do
    buttons[i] = host:AddSimpleButton(page.name, function() select(i) end, { width = NAV_WIDTH })
  end

  select(1)

  return host
end

--- Opens the settings in a window of its own, or raises it if it is already open.
function SettingsDialog.open()
  if window ~= nil then
    window:Show()
    return
  end

  local parent = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA)

  local WINDOW_WIDTH = 588 -- Mimics the width of the builtin settings window
  local WINDOW_HEIGHT = 460

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

  SettingsDialog.mount(window.content)

  zyklib.lifecycle.shutdown_event:subscribe(function()
    if window ~= nil then
      window:Destroy()
      window = nil
    end
  end)
end

return SettingsDialog
