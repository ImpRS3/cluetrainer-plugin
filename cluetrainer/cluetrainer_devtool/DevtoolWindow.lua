-- DevtoolWindow.lua
-- A window to pick a clue scroll by tier and type, give it to yourself and teleport to its method or solution, or to
-- a teleport of your choice. Uses dev server cheats, so it only works there.
local cheats = require "cluetrainer_devtool/cheats"
local entries = require "cluetrainer_devtool/catalog"
local teleports = require "cluetrainer/data/teleports"

local DevtoolWindow = {}

-- In pixels. Wide enough for a clue label in one row.
local WINDOW_WIDTH = 500
-- In pixels. Wide enough for the longest tier or type, "Coordinates".
local COMBO_BOX_WIDTH = 120
-- In pixels. Wide enough for the longest teleport, "Arc sailing: Turtle Islands Docks", with room for the label and
-- the button on its row.
local TELE_BOX_WIDTH = 260
-- Options are numbered from 1. The first is the default: the first tier, "All types", or the first teleport.
local FIRST_OPTION_ID = 1
-- The clue box always has a selection, this entry stands for none. Its order puts it on top.
local NO_CLUE = { label = "Pick a clue", id = 0, order = 0 }
-- Teleports in the tele box: groups from Clue Trainer's teleport data by id, with the label to list their spots under.
local TELE_GROUPS = {
  { id = "arctabs", label = "Arc Journal" },
  { id = "arcsailing", label = "Arc sailing" },
}

--- Combo box entries for the distinct values of a field in catalog order, optionally behind an "All" entry with value
--- nil. The order makes PrettyUI draw the combo box itself, the client's one does not redraw a selection made in code.
---@param field "tier"|"type" The catalog field to group by
---@param all_label string? Label of the "All" entry, none when nil
---@param include? fun(entry: devtool.CatalogEntry): boolean Only entries for which this is true count
---@return table[] options Numbered from FIRST_OPTION_ID, the id is also the index
local function groupOptions(field, all_label, include)
  local options, seen = {}, {}
  if all_label then options[FIRST_OPTION_ID] = { label = all_label, id = FIRST_OPTION_ID, order = FIRST_OPTION_ID } end
  for _, entry in ipairs(entries) do
    local value = entry[field]
    if not seen[value] and (not include or include(entry)) then
      seen[value] = true
      options[#options + 1] = { label = value, id = #options + 1, order = #options + 1, value = value }
    end
  end
  return options
end

--- The only option behind the first one in the list, which is "All types" or "Pick a clue".
---@param options table[]
---@return table? nil when there are no or several options behind the first
local function onlyOption(options)
  return #options == 2 and options[2] or nil
end

--- Combo box entries for the spots of TELE_GROUPS, in that order.
---@return table[] options Numbered from FIRST_OPTION_ID, the id is also the index
local function teleOptions()
  local groups_by_id = {}
  for _, group in ipairs(teleports) do groups_by_id[group.id] = group end

  local options = {}
  for _, tele_group in ipairs(TELE_GROUPS) do
    for _, spot in ipairs(groups_by_id[tele_group.id].spots) do
      local index = #options + 1
      local label = tele_group.label .. ": " .. spot.name
      options[index] = { label = label, id = index, order = index, spot = spot.target.origin }
    end
  end
  return options
end

--- PrettyUI 1.2.0's combo box shows or hides its entries one by one when it opens or filters, and each one rebuilds its
--- whole list. With a hundred clues that takes longer than the client allows. This replaces the filter of one combo
--- box with one that rebuilds the list once. TODO: remove once PrettyUI filters in one pass itself.
---
--- The combo box also drops the disabled flag of its entries, so the list can not grey them out. As this filter builds
--- the list, it asks isDisabled for each entry instead.
---@param combo_box prettyui.OrderedComboBox
---@param isDisabled fun(id: integer): boolean? Whether the entry with this id is greyed out and can not be clicked
local function filterInOnePass(combo_box, isDisabled)
  function combo_box:_Filter(value)
    local query = tostring(value or ""):lower()
    local visible = {}
    for _, entry in ipairs(self.entries) do
      entry.visible = query == "" or entry.label:lower():find(query, 1, true) ~= nil
      if entry.visible then
        visible[#visible + 1] = { label = entry.label, id = entry.id, disabled = isDisabled(entry.id) }
      end
    end

    self.dropdown:SetEntries(visible)
    if self.entriesByID[self.selectedID] and self.entriesByID[self.selectedID].visible then
      self.dropdown:SetSelected(self.selectedID, true, false)
    end
    self:_LayoutDropdown()
  end
end

--- Opens the devtool window on the game area, with the first tier and all types chosen.
---
--- Row 1: tier and type. Row 2: the clues of that tier and type. Row 3: give the chosen clue, or a sealed clue or the
--- puzzles of the tier. Row 4: teleport to the start of the method or the solution of the chosen clue. Row 5: a
--- teleport to pick and go to. Row 6: fill the globetrotter outfit, and make the current step of each trail unfinished
--- again.
---@param onClose fun(window: PrettyUI.Window)? Called when the window is closed
---@return PrettyUI.Window
function DevtoolWindow.open(onClose)
  local tier_options = groupOptions("tier")
  local type_options = groupOptions("type", "All types")
  local tele_options = teleOptions()
  local tele_choice = tele_options[FIRST_OPTION_ID]
  local tier, clue_type = nil, nil
  ---@type devtool.CatalogEntry?
  local selected

  -- Assigned once the widgets exist. The functions below only run after that.
  local type_box, clue_box, give_button, sealed_button, puzzle_button, method_button, clue_button

  --- Makes a clue the target of the buttons, or clears it with nil. Buttons without a target are disabled.
  ---@param entry devtool.CatalogEntry?
  local function selectEntry(entry)
    selected = entry
    give_button:SetDisabled(not entry or entry.disabled)
    method_button:SetDisabled(not (entry and entry.method_spot))
    clue_button:SetDisabled(not (entry and entry.clue_spot))
  end

  --- Lists the clues of the chosen tier and type. Each control resets the ones after it, so this also clears the
  --- selected clue, unless one clue is left: then that one is selected, which saves a click.
  local function refreshClues()
    local visible = { NO_CLUE }
    for index, entry in ipairs(entries) do
      if entry.tier == tier and (not clue_type or entry.type == clue_type) then
        visible[#visible + 1] = { label = entry.label, id = index, order = index }
      end
    end

    local only = onlyOption(visible)
    clue_box:SetEntries(visible, only and only.id or NO_CLUE.id)
    selectEntry(only and entries[only.id])
  end

  --- Chooses a tier, which give sealed and give puzzle also use, and resets the types to all. A tier with one type
  --- gets that type instead, which saves a click.
  ---@param value string
  local function selectTier(value)
    tier = value
    sealed_button:SetDisabled(not cheats.SEALED_CLUES[tier])
    puzzle_button:SetDisabled(not cheats.PUZZLES[tier])
    type_options = groupOptions("type", "All types", function(entry) return entry.tier == tier end)
    local choice = onlyOption(type_options) or type_options[FIRST_OPTION_ID]
    clue_type = choice.value
    type_box:SetEntries(type_options, choice.id)
    refreshClues()
  end

  local window = prettyui.Window.new(ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA), {
    title = "Clue Trainer Devtool",
    width = WINDOW_WIDTH,
    scrollable = false,
    destroyOnClose = true,
    onClose = onClose,
  })

  -- Row 1: tier and type.
  window:AddComboBox({
    width = COMBO_BOX_WIDTH,
    entries = tier_options,
    selectedID = FIRST_OPTION_ID,
    onChange = function(_, index) selectTier(tier_options[index].value) end,
  })

  type_box = window:AddComboBox({
    width = COMBO_BOX_WIDTH,
    inline = true,
    entries = type_options,
    selectedID = FIRST_OPTION_ID,
    onChange = function(_, index)
      clue_type = type_options[index].value
      refreshClues()
    end,
  })

  -- Row 2: the clues. Typing in it searches the labels.
  clue_box = window:AddComboBox({
    entries = { NO_CLUE },
    selectedID = NO_CLUE.id,
    onChange = function(_, index) selectEntry(entries[index]) end,
  })
  -- Clue ids are catalog indices, the "Pick a clue" entry has none.
  filterInOnePass(clue_box, function(index) return entries[index] and entries[index].disabled end)

  -- Row 3: give. Give sealed and give puzzle use the chosen tier.
  give_button = window:AddSimpleButton("Give", function() cheats.give(selected and selected.config_name) end)
  sealed_button = window:AddSimpleButton("Give sealed", function() cheats.give(cheats.SEALED_CLUES[tier]) end,
    { inline = true })
  puzzle_button = window:AddSimpleButton("Give puzzle", function() cheats.givePuzzles(tier) end, { inline = true })

  -- Row 4: the teleports of the chosen clue.
  method_button = window:AddSimpleButton("Tele method", function() cheats.tele(selected and selected.method_spot) end)
  clue_button = window:AddSimpleButton("Tele clue loc", function() cheats.tele(selected and selected.clue_spot) end,
    { inline = true })

  -- Row 5: a teleport of your choice.
  window:AddText("Static tele")
  window:AddComboBox({
    width = TELE_BOX_WIDTH,
    inline = true,
    entries = tele_options,
    selectedID = FIRST_OPTION_ID,
    onChange = function(_, index) tele_choice = tele_options[index] end,
  })
  window:AddSimpleButton("Tele", function() cheats.tele(tele_choice.spot) end, { inline = true })

  -- Row 6: account state, for every tier at once.
  window:AddSimpleButton("Fill globetrotter", cheats.fillGlobetrotter)
  window:AddSimpleButton("Reset step", cheats.resetStep, { inline = true })

  selectTier(tier_options[FIRST_OPTION_ID].value)

  -- Sizes the window to its rows.
  window:_FitContent()

  return window
end

return DevtoolWindow
