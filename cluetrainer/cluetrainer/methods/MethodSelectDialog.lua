local methods = require("cluetrainer/model/shared/methods")
local method_management = require("cluetrainer/methods/method_management")
local RichText = require("cluetrainer/util/RichText")

---@class ct.ui.MethodSelectDialog
local MethodSelectDialog = {}

local DIALOG_WIDTH = 420
local DIALOG_BASE_HEIGHT = 130
local DIALOG_ROW_HEIGHT = 56
local DIALOG_MAX_HEIGHT = 480
local INTRO_HEIGHT = 50

-- Estimated values. Tune visually.
local RADIO_INDENT = 28
local RADIO_HEIGHT = 20
local TEXT_HEIGHT = 16
local PACK_COLOUR = 0xAAAAAAFF
local DESCRIPTION_COLOUR = 0x999999FF

---Adds a row for an option: pack name, method name and optional description, with a radio button on the left.
---@param window PrettyUI.Window
---@param augmented ct.AugmentedMethod<Method.GenericPath>
---@param group integer
---@param selected boolean
---@param onPicked fun(radio: PrettyUI.RadioButton)
---@return PrettyUI.RadioButton
local function addOption(window, augmented, group, selected, onPicked)
  local width = window.contentWidth - RADIO_INDENT

  window:AddText({
    text = augmented.method.name,
    marginTop = 6,
    x = RADIO_INDENT,
    width = width,
    rowBackgroundGroup = group,
  })

  window:AddText({
    text = "From Pack: " .. augmented.pack.name,
    marginBottom = 6,
    colour = PACK_COLOUR,
    x = RADIO_INDENT,
    width = width,
    rowBackgroundGroup = group,
  })

  local lines = 2

  -- The radio button joins the last row, so it is offset upwards to the vertical middle of the block.
  local block_height = TEXT_HEIGHT * lines + 2 * (lines - 1)
  local row_top = (TEXT_HEIGHT + 2) * (lines - 1)

  return window:AddRadioButton({ { text = "", value = "picked", selected = selected } }, {
    inline = true,
    x = 6,
    offsetY = block_height / 2 - row_top - RADIO_HEIGHT / 2,
    rowBackgroundGroup = group,
    onChange = function(radio)
      onPicked(radio)
    end,
  })
end

---Adds the row that deselects the method.
---@param window PrettyUI.Window
---@param group integer
---@param selected boolean
---@param onPicked fun(radio: PrettyUI.RadioButton)
---@return PrettyUI.RadioButton
local function addNoneOption(window, group, selected, onPicked)
  window:AddText({
    text = "None: Does not show teleports or movement.",
    marginTop = 6,
    marginBottom = 6,
    x = RADIO_INDENT,
    width = window.contentWidth - RADIO_INDENT,
    rowBackgroundGroup = group,
  })

  return window:AddRadioButton({ { text = "", value = "picked", selected = selected } }, {
    inline = true,
    x = 6,
    offsetY = (TEXT_HEIGHT - RADIO_HEIGHT) / 2,
    rowBackgroundGroup = group,
    onChange = function(radio)
      onPicked(radio)
    end,
  })
end

local INTRO_TEXT =
    "Choose the method you want to be used for this clue. " ..
    RichText.italic("Note: Creating custom methods will arrive in a future update.")

---@class ct.ui.MethodSelectDialog.Options
---@field spot ClueSpot.Id The clue spot for which to select a method
---@field selected ct.AugmentedMethod<Method.GenericPath>? The currently selected method; nil selects "None"
---@field onSelect fun(method: ct.AugmentedMethod<Method.GenericPath>?) Called when the player picks an option; nil means "None"

---Opens a modal dialog in which one of the given methods can be selected.
---@param options ct.ui.MethodSelectDialog.Options
---@return PrettyUI.Dialog
function MethodSelectDialog.open(options)
  local parent = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP)

  local candidates = method_management.getAllForClue(options.spot)

  return prettyui.Dialog.new(parent, {
    title = "Select method",
    height = math.min(DIALOG_MAX_HEIGHT, DIALOG_BASE_HEIGHT + INTRO_HEIGHT + (#candidates + 1) * DIALOG_ROW_HEIGHT),
    width = DIALOG_WIDTH,
    content = function(window)
      window:AddText({
        text = INTRO_TEXT,
        colour = DESCRIPTION_COLOUR,
        marginBottom = 8,
        width = window.contentWidth,
      })

      -- Every option is its own single-choice radio button, so exclusivity is handled here.
      ---@type PrettyUI.RadioButton[]
      local radios = {}

      ---@param index integer
      ---@param method ct.AugmentedMethod<Method.GenericPath>?
      local function pick(index, method)
        for j, other in pairs(radios) do
          if j ~= index then other:SetSelectedValue(nil, false) end
        end

        radios[index]:SetSelectedValue("picked", false)

        method_management.setPreferred(options.spot, method and method.method or nil)
        options.onSelect(method)
      end

      radios[0] = addNoneOption(window, 0, options.selected == nil, function() pick(0, nil) end)

      for i, method in ipairs(candidates) do
        radios[i] = addOption(window, method, i, method == options.selected, function() pick(i, method) end)
      end
    end,
    actions = {},
  })
end

return MethodSelectDialog
