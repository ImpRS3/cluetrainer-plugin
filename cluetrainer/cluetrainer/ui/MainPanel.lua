local MainPanel = {}

---@class MainPanel.Options
---@field solving_enabled boolean? Initial state of the solving toggle. Defaults to true.
---@field map_visible boolean? Initial state of the map toggle. Defaults to false.
---@field onSolvingChanged fun(enabled: boolean)?
---@field onMapChanged fun(visible: boolean)?
---@field onOpenSettings fun()? Defaults to opening the settings dialog.

local ROW_COLOURS = { 0x24211EFF, 0x2E2825FF }
local LABEL_COLOUR = 0xb4a092ff
local CHECKBOX_RESERVED = 24
-- Panel border, inner padding and scrollbar gutter that the layer width does not account for. Estimated, tune visually.
local PAGE_PADDING = 60

local group_counter = 0

--- Adds a labelled checkbox row.
---@param panel PrettyUI.Panel
---@param label string
---@param initial boolean
---@param onChange fun(selected: boolean)?
local function addToggle(panel, label, initial, onChange)
  group_counter = group_counter + 1
  local group = group_counter

  panel:AddText({
    text = label,
    colour = LABEL_COLOUR,
    marginTop = 8,
    marginBottom = 8,
    rowBackgroundGroup = group,
    width = panel.width - PAGE_PADDING - CHECKBOX_RESERVED,
  })

  panel:AddCheckboxButton({
    { text = "", value = "on", selected = initial },
  }, {
    inline = true,
    columnGap = 8,
    rowBackgroundGroup = group,
    onChange = function(_, _, _, selected)
      if onChange then onChange(selected) end
    end,
  })
end

--- Mounts the main panel onto a layer.
---@param layer ui.Layer
---@param options MainPanel.Options?
function MainPanel.mount(layer, options)
  options = options or {}

  local panel = prettyui.Panel.new(layer, {
    x = 0,
    y = 0,
    width = layer.width,
    height = layer.height,
    rowBackgroundColours = ROW_COLOURS,
  })

  addToggle(panel, "Enable clue solving", options.solving_enabled ~= false, options.onSolvingChanged)
  addToggle(panel, "Display map", options.map_visible == true, options.onMapChanged)

  panel:AddSimpleButton("Open Settings", options.onOpenSettings or function()
    require("cluetrainer/ui/SettingsDialog").open()
  end, { marginTop = 8 })

  panel:RefreshRowBackgrounds()
end

return MainPanel
