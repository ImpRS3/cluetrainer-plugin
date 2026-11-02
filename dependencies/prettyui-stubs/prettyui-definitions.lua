---@meta

-- BSD 3-Clause License
-- 
-- Copyright (c) 2026, PrettyRS
-- 
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
-- 
-- 1. Redistributions of source code must retain the above copyright notice, this
--    list of conditions and the following disclaimer.
-- 
-- 2. Redistributions in binary form must reproduce the above copyright notice,
--    this list of conditions and the following disclaimer in the documentation
--    and/or other materials provided with the distribution.
-- 
-- 3. Neither the name of the copyright holder nor the names of its
--    contributors may be used to endorse or promote products derived from
--    this software without specific prior written permission.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

---PrettyUI editor definitions (not executable).
---Source version: 1.3.0-beta.2
---@class PrettyUI
---@field version string
---@field AchievementPopup PrettyUI.AchievementPopup
---@field AnchoredTooltip PrettyUI.AnchoredTooltip
---@field BarChart PrettyUI.BarChart
---@field BigSpinner PrettyUI.BigSpinner
---@field BuffBar PrettyUI.BuffBar
---@field CheckboxButton PrettyUI.CheckboxButton
---@field CollapseButton PrettyUI.CollapseButton
---@field ColourPicker PrettyUI.ColourPicker
---@field ComboBox PrettyUI.ComboBox
---@field Confirm PrettyUI.Confirm
---@field Dialog PrettyUI.Dialog
---@field Divider PrettyUI.Divider
---@field FancyButton PrettyUI.FancyButton
---@field Histogram PrettyUI.Histogram
---@field ItemGrid PrettyUI.ItemGrid
---@field ItemSlot PrettyUI.ItemSlot
---@field KeybindField PrettyUI.KeybindField
---@field List PrettyUI.List
---@field MiniMenu PrettyUI.MiniMenu
---@field OverheadBar PrettyUI.OverheadBar
---@field Panel PrettyUI.Panel
---@field RadioButton PrettyUI.RadioButton
---@field RibbonBar PrettyUI.RibbonBar
---@field RibbonButton PrettyUI.RibbonButton
---@field Scrollbar PrettyUI.Scrollbar
---@field SimpleButton PrettyUI.SimpleButton
---@field SimpleView PrettyUI.SimpleView
---@field Slider PrettyUI.Slider
---@field Spinner PrettyUI.Spinner
---@field Sprite PrettyUI.Sprite
---@field SpriteButton PrettyUI.SpriteButton
---@field Sprites PrettyUI.Sprites
---@field Tabs PrettyUI.Tabs
---@field Text PrettyUI.Text
---@field TextField PrettyUI.TextField
---@field TimeGraph PrettyUI.TimeGraph
---@field Tooltip PrettyUI.Tooltip
---@field Window PrettyUI.Window
prettyui = {}

---@class PrettyUI.View
local View = {}

---Source: src/core/content_methods.lua:32
---@param options PrettyUI.BarChartOptions?
---@return PrettyUI.BarChart
function View:AddBarChart(options) end
---Source: src/core/content_methods.lua:30
---@param options PrettyUI.BigSpinnerOptions?
---@return PrettyUI.BigSpinner
function View:AddBigSpinner(options) end
---Source: src/core/content_methods.lua:89
---@param choices (any|PrettyUI.Choice)[]
---@param options PrettyUI.CheckboxButtonOptions?
---@return PrettyUI.CheckboxButton
function View:AddCheckboxButton(choices, options) end
---Source: src/core/content_methods.lua:61
---@param text string
---@param options PrettyUI.CollapseButtonOptions?
---@return PrettyUI.CollapseButton
function View:AddCollapseButton(text, options) end
---Source: src/core/content_methods.lua:98
---@param options PrettyUI.ColourPickerOptions?
---@return PrettyUI.ColourPicker
function View:AddColourPicker(options) end
---Source: src/core/content_methods.lua:114
---@param options PrettyUI.ComboBoxOptions?
---@return PrettyUI.ComboBox
function View:AddComboBox(options) end
---Source: src/core/content_methods.lua:35
---@param options PrettyUI.DividerOptions?
---@return PrettyUI.Divider
function View:AddDivider(options) end
---Source: src/core/content_methods.lua:146
---@param text string
---@param action fun(button: PrettyUI.FancyButton)?
---@param options PrettyUI.FancyButtonOptions?
---@return PrettyUI.FancyButton
function View:AddFancyButton(text, action, options) end
---Source: src/core/content_methods.lua:33
---@param options PrettyUI.HistogramOptions?
---@return PrettyUI.Histogram
function View:AddHistogram(options) end
---Source: src/core/content_methods.lua:45
---@param objects table<integer, any|PrettyUI.ItemGridEntry>
---@param options PrettyUI.ItemGridOptions?
---@return PrettyUI.ItemGrid
function View:AddItemGrid(objects, options) end
---Source: src/core/content_methods.lua:43
---@param object any?
---@param options PrettyUI.ItemSlotOptions?
---@return PrettyUI.ItemSlot
function View:AddItemSlot(object, options) end
---Source: src/core/content_methods.lua:107
---@param options PrettyUI.KeybindFieldOptions?
---@return PrettyUI.KeybindField
function View:AddKeybindField(options) end
---Source: src/core/content_methods.lua:120
---@param options PrettyUI.ListOptions?
---@return PrettyUI.List
function View:AddList(options) end
---Source: src/core/content_methods.lua:69
---@param options PrettyUI.PanelOptions?
---@return PrettyUI.Panel
function View:AddPanel(options) end
---Source: src/core/content_methods.lua:79
---@param choices (any|PrettyUI.Choice)[]
---@param options PrettyUI.RadioButtonOptions?
---@return PrettyUI.RadioButton
function View:AddRadioButton(choices, options) end
---Source: src/core/content_methods.lua:122
---@param spriteID number
---@param action fun(button: PrettyUI.RibbonButton)?
---@param options PrettyUI.RibbonButtonOptions?
---@return PrettyUI.RibbonButton
function View:AddRibbonButton(spriteID, action, options) end
---Source: src/core/content_methods.lua:130
---@param content string|number
---@param action fun(button: PrettyUI.SimpleButton, active: boolean)?
---@param options PrettyUI.SimpleButtonOptions?
---@return PrettyUI.SimpleButton
function View:AddSimpleButton(content, action, options) end
---Source: src/core/content_methods.lua:138
---@param options PrettyUI.SliderOptions?
---@return PrettyUI.Slider
function View:AddSlider(options) end
---Source: src/core/content_methods.lua:29
---@param options PrettyUI.SpinnerOptions?
---@return PrettyUI.Spinner
function View:AddSpinner(options) end
---Source: src/core/content_methods.lua:28
---@param sprite any
---@param options PrettyUI.SpriteOptions?
---@return PrettyUI.Sprite
function View:AddSprite(sprite, options) end
---Source: src/core/content_methods.lua:154
---@param spriteName string
---@param action fun(button: PrettyUI.SpriteButton, enabled: boolean)?
---@param options PrettyUI.SpriteButtonOptions?
---@return PrettyUI.SpriteButton
function View:AddSpriteButton(spriteName, action, options) end
---Source: src/core/content_methods.lua:52
---@param values (string|number|PrettyUI.TabEntry)[]
---@param options PrettyUI.TabsOptions?
---@return PrettyUI.Tabs
function View:AddTabs(values, options) end
---Source: src/core/content_methods.lua:26
---@param value string|PrettyUI.TextOptions
---@return any
function View:AddText(value) end
---Source: src/core/content_methods.lua:100
---@param options PrettyUI.TextFieldOptions?
---@return PrettyUI.TextField
function View:AddTextField(options) end
---Source: src/core/content_methods.lua:31
---@param options PrettyUI.TimeGraphOptions
---@return PrettyUI.TimeGraph
function View:AddTimeGraph(options) end
---Source: src/core/content_methods.lua:27
---@param value any
---@return any

---Options for AchievementPopup. Source: src/achievement_popup.lua
---@class PrettyUI.AchievementPopupOptions
---@field height? number
---@field item? any
---@field itemInset? number
---@field onComplete? fun(popup: PrettyUI.AchievementPopup)
---@field outlineWidth? number
---@field parent? any
---@field quantity? integer
---@field quantityMode? any
---@field shadowRGBA? number
---@field shadowed? boolean
---@field sound? boolean
---@field soundID? number
---@field text? string
---@field textColour? number
---@field title? string
---@field titleColour? number
---@field width? number
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/achievement_popup.lua
---@class PrettyUI.AchievementPopup
prettyui.AchievementPopup = {}
---Source: src/achievement_popup.lua:227
---@return any
function prettyui.AchievementPopup:Destroy() end
---Source: src/achievement_popup.lua:90
---@param parent any
---@param options PrettyUI.AchievementPopupOptions?
---@return PrettyUI.AchievementPopup
function prettyui.AchievementPopup.new(parent, options) end
---Source: src/achievement_popup.lua:219
---@param options PrettyUI.AchievementPopupOptions?
---@return PrettyUI.AchievementPopup|nil
function prettyui.AchievementPopup.show(options) end

---Options for AnchoredTooltip. Source: src/anchored_tooltip.lua
---@class PrettyUI.AnchoredTooltipOptions
---@field alignHorizontal? any
---@field alignVertical? any
---@field anchor? fun(tooltip: PrettyUI.AnchoredTooltip): any
---@field backgroundAlpha? number
---@field backgroundColour? number
---@field buildContent? fun(tooltip: PrettyUI.AnchoredTooltip, content: any): any
---@field clickthrough? any
---@field colour? any
---@field content? fun(tooltip: PrettyUI.AnchoredTooltip, content: any): any
---@field contentHeight? number
---@field contentWidth? number
---@field font? any
---@field height? number
---@field heightAboveGround? number
---@field hidden? boolean
---@field loc? any
---@field maxWidth? number
---@field npc? any
---@field offsetX? number
---@field offsetY? number
---@field padding? number
---@field paddingX? number
---@field paddingY? number
---@field parent? any
---@field position? any
---@field shadowed? any
---@field text? string
---@field width? number

---Source: src/anchored_tooltip.lua
---@class PrettyUI.AnchoredTooltip
---@field content any
---@field contentResult any
---@field root any
---@field visible boolean
prettyui.AnchoredTooltip = {}
---Source: src/anchored_tooltip.lua:346
---@return any
function prettyui.AnchoredTooltip:Destroy() end
---Source: src/anchored_tooltip.lua:341
---@return any
function prettyui.AnchoredTooltip:Hide() end
---Source: src/anchored_tooltip.lua:318
---@param text string
---@return boolean
function prettyui.AnchoredTooltip:SetText(text) end
---Source: src/anchored_tooltip.lua:336
---@return boolean
function prettyui.AnchoredTooltip:Show() end
---Source: src/anchored_tooltip.lua:288
---@return boolean
function prettyui.AnchoredTooltip:Update() end
---Source: src/anchored_tooltip.lua:261
---@param loc any
---@param options PrettyUI.AnchoredTooltipOptions?
---@return PrettyUI.AnchoredTooltip|nil
function prettyui.AnchoredTooltip.forLoc(loc, options) end
---Source: src/anchored_tooltip.lua:255
---@param npc any
---@param options PrettyUI.AnchoredTooltipOptions?
---@return PrettyUI.AnchoredTooltip|nil
function prettyui.AnchoredTooltip.forNPC(npc, options) end
---Source: src/anchored_tooltip.lua:143
---@param parent any
---@param options PrettyUI.AnchoredTooltipOptions
---@return PrettyUI.AnchoredTooltip
function prettyui.AnchoredTooltip.new(parent, options) end
---Source: src/anchored_tooltip.lua:244
---@param options PrettyUI.AnchoredTooltipOptions
---@return PrettyUI.AnchoredTooltip|nil
function prettyui.AnchoredTooltip.show(options) end

---Options for BarChart. Source: src/bar_chart.lua
---@class PrettyUI.BarChartOptions
---@field absolute? any
---@field columnGap? any
---@field data? PrettyUI.BarRow[]
---@field height? number
---@field heightAnchor? number
---@field inline? any
---@field label? string
---@field marginBottom? any
---@field marginTop? any
---@field offsetY? any
---@field orientation? 'horizontal'|'vertical'
---@field rgba? number
---@field rowBackground? any
---@field rowBackgroundGroup? any
---@field size? any
---@field visible? boolean
---@field width? number
---@field widthAnchor? number
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/bar_chart.lua
---@class PrettyUI.BarChart
prettyui.BarChart = {}
---Source: src/core/bar_renderer.lua:371
---@return any
function prettyui.BarChart:Destroy() end
---Source: src/bar_chart.lua:28
---@return PrettyUI.BarSnapshot
function prettyui.BarChart:GetSnapshot() end
---Source: src/bar_chart.lua:32
---@return boolean
function prettyui.BarChart:Reset() end
---Source: src/bar_chart.lua:20
---@param rows PrettyUI.BarRow[]
---@return boolean
function prettyui.BarChart:SetData(rows) end
---Source: src/core/bar_renderer.lua:361
---@param width number
---@param height number
---@return boolean
function prettyui.BarChart:SetSize(width, height) end
---Source: src/core/bar_renderer.lua:351
---@param visible boolean
---@return boolean
function prettyui.BarChart:SetVisible(visible) end
---Source: src/bar_chart.lua:10
---@param parent any
---@param options PrettyUI.BarChartOptions?
---@return PrettyUI.BarChart
function prettyui.BarChart.new(parent, options) end

---@class PrettyUI.BarRow
---@field id string
---@field label string
---@field rgba number?
---@field value number
local BarRow = {}

---@class PrettyUI.BarSnapshot
---@field data PrettyUI.BarRow[]
---@field label string
local BarSnapshot = {}

---Options for BigSpinner. Source: src/spinner.lua
---@class PrettyUI.BigSpinnerOptions
---@field absolute? any
---@field autoPlay? boolean
---@field columnGap? any
---@field degreesPerLogicUpdate? number
---@field height? number
---@field inline? any
---@field marginBottom? any
---@field marginTop? any
---@field offsetY? any
---@field rotation? number
---@field rowBackground? any
---@field rowBackgroundGroup? any
---@field size? number
---@field tooltip? string|PrettyUI.TooltipOptions
---@field width? number
---@field widthAnchor? any
---@field x? any
---@field xAnchor? any
---@field y? any
---@field yAnchor? any

---Source: src/spinner.lua
---@class PrettyUI.BigSpinner: PrettyUI.Spinner
prettyui.BigSpinner = {}
---Source: src/spinner.lua:85
---@return any
function prettyui.BigSpinner:Destroy() end
---Source: src/spinner.lua:81
---@return any
function prettyui.BigSpinner:Reset() end
---Source: src/spinner.lua:59
---@param degrees any
---@return any
function prettyui.BigSpinner:SetDegreesPerLogicUpdate(degrees) end
---Source: src/spinner.lua:54
---@param degrees any
---@return any
function prettyui.BigSpinner:SetRotation(degrees) end
---Source: src/spinner.lua:63
---@param value any
---@return any
function prettyui.BigSpinner:SetTooltip(value) end
---Source: src/spinner.lua:67
---@return any
function prettyui.BigSpinner:Start() end
---Source: src/spinner.lua:75
---@return any
function prettyui.BigSpinner:Stop() end
---Source: src/spinner.lua:16
---@param parent any
---@param options PrettyUI.BigSpinnerOptions?
---@return PrettyUI.Spinner
function prettyui.BigSpinner.new(parent, options) end

---Options for BuffBar. Source: src/buff_bar.lua
---@class PrettyUI.BuffBarOptions
---@field backgroundRgba? number
---@field borderRgba? number
---@field duration? number
---@field font? number
---@field label? string
---@field labelRgba? number
---@field objId? any
---@field spriteID? number
---@field tooltip? string|PrettyUI.TooltipOptions
---@field visible? boolean

---Source: src/buff_bar.lua
---@class PrettyUI.BuffBar
prettyui.BuffBar = {}
---Source: src/buff_bar.lua:616
---@param options PrettyUI.BuffBarOptions?
---@return PrettyUI.BuffHandle|nil
function prettyui.BuffBar.addBuff(options) end
---Source: src/buff_bar.lua:624
---@param options PrettyUI.BuffBarOptions?
---@return PrettyUI.BuffHandle|nil
function prettyui.BuffBar.addDebuff(options) end
---Source: src/buff_bar.lua:620
---@param handle PrettyUI.BuffHandle
---@return boolean
function prettyui.BuffBar.removeBuff(handle) end
---Source: src/buff_bar.lua:628
---@param handle PrettyUI.BuffHandle
---@return boolean
function prettyui.BuffBar.removeDebuff(handle) end

---Source: src/buff_bar.lua
---@class PrettyUI.BuffHandle
local BuffHandle = {}
---Source: src/buff_bar.lua:454
---@param text string
---@param rgba number?
---@return boolean
function BuffHandle:SetLabel(text, rgba) end
---Source: src/buff_bar.lua:462
---@param objId any?
---@return boolean
function BuffHandle:SetObject(objId) end
---Source: src/buff_bar.lua:475
---@param spriteID number?
---@return boolean
function BuffHandle:SetSprite(spriteID) end
---Source: src/buff_bar.lua:487
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function BuffHandle:SetTooltip(value) end
---Source: src/buff_bar.lua:493
---@param visible boolean
---@return boolean
function BuffHandle:SetVisible(visible) end

---Options for CheckboxButton. Source: src/selection_button.lua
---@class PrettyUI.CheckboxButtonOptions
---@field absolute? any
---@field colour? number
---@field columnGap? any
---@field crossCursor? any
---@field disabled? boolean
---@field disabledColour? number
---@field height? any
---@field inline? boolean
---@field marginBottom? any
---@field marginTop? any
---@field offsetY? any
---@field onChange? fun(group: PrettyUI.CheckboxButton, values: any[], changedValue: any, selected: boolean)
---@field rowBackground? any
---@field rowBackgroundGroup? any
---@field selectedValue? any
---@field selectedValues? any[]|table<any, boolean>
---@field shadowed? any
---@field size? any
---@field tickCursor? any
---@field tooltip? string|PrettyUI.TooltipOptions
---@field width? any
---@field widthAnchor? any
---@field x? any
---@field xAnchor? any
---@field y? any
---@field yAnchor? any

---Source: src/selection_button.lua
---@class PrettyUI.CheckboxButton: PrettyUI.SelectionButton
prettyui.CheckboxButton = {}
---Source: src/selection_button.lua:312
---@return any
function prettyui.CheckboxButton:Destroy() end
---Source: src/selection_button.lua:242
---@return any
function prettyui.CheckboxButton:GetSelectedValue() end
---Source: src/selection_button.lua:263
---@return any[]
function prettyui.CheckboxButton:GetSelectedValues() end
---Source: src/selection_button.lua:269
---@param value any
---@return any
function prettyui.CheckboxButton:IsSelected(value) end
---Source: src/selection_button.lua:292
---@param disabled any
---@return any
function prettyui.CheckboxButton:SetDisabled(disabled) end
---Source: src/selection_button.lua:302
---@param value any
---@param tooltip any
---@return any
function prettyui.CheckboxButton:SetOptionTooltip(value, tooltip) end
---Source: src/selection_button.lua:274
---@param value any
---@param selected boolean
---@param notify boolean?
---@return boolean
function prettyui.CheckboxButton:SetSelected(value, selected, notify) end
---Source: src/selection_button.lua:246
---@param value any
---@param notify any
---@return any
function prettyui.CheckboxButton:SetSelectedValue(value, notify) end
---Source: src/selection_button.lua:298
---@param value any
---@return any
function prettyui.CheckboxButton:SetTooltip(value) end
---Source: src/selection_button.lua:328
---@param parent any
---@param choices (any|PrettyUI.Choice)[]
---@param options PrettyUI.CheckboxButtonOptions?
---@return PrettyUI.CheckboxButton
function prettyui.CheckboxButton.new(parent, choices, options) end

---@class PrettyUI.Choice
---@field disabled boolean?
---@field label string?
---@field selected boolean?
---@field text string?
---@field tooltip string|PrettyUI.TooltipOptions|nil
---@field value any?
local Choice = {}

---Options for CollapseButton. Source: src/collapse_button.lua
---@class PrettyUI.CollapseButtonOptions
---@field absolute? any
---@field colour? number
---@field columnGap? any
---@field disabled? boolean
---@field disabledColour? number
---@field expanded? boolean
---@field font? any
---@field height? any
---@field hoverCursor? any
---@field indent? number
---@field inline? boolean
---@field lineSpacing? any
---@field marginBottom? number
---@field marginTop? number
---@field offsetY? any
---@field onToggle? fun(section: PrettyUI.CollapseButton, expanded: boolean)
---@field resizeParent? boolean
---@field rowBackground? boolean
---@field rowBackgroundGroup? any
---@field shadowed? boolean
---@field size? any
---@field text? any
---@field tooltip? string|PrettyUI.TooltipOptions
---@field width? number
---@field widthAnchor? number
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/collapse_button.lua
---@class PrettyUI.CollapseButton
---@field content any
prettyui.CollapseButton = {}
---Source: src/collapse_button.lua:292
---@param options PrettyUI.ComboBoxOptions?
---@return PrettyUI.ComboBox
function prettyui.CollapseButton:AddComboBox(options) end
---Source: src/collapse_button.lua:239
---@param text string
---@param action fun(button: PrettyUI.FancyButton)?
---@param options PrettyUI.FancyButtonOptions?
---@return PrettyUI.FancyButton
function prettyui.CollapseButton:AddFancyButton(text, action, options) end
---Source: src/collapse_button.lua:288
---@param options PrettyUI.KeybindFieldOptions?
---@return PrettyUI.KeybindField
function prettyui.CollapseButton:AddKeybindField(options) end
---Source: src/collapse_button.lua:296
---@param options PrettyUI.ListOptions?
---@return PrettyUI.List
function prettyui.CollapseButton:AddList(options) end
---Source: src/collapse_button.lua:226
---@param content string|number
---@param action fun(button: PrettyUI.SimpleButton, active: boolean)?
---@param options PrettyUI.SimpleButtonOptions?
---@return PrettyUI.SimpleButton
function prettyui.CollapseButton:AddSimpleButton(content, action, options) end
---Source: src/collapse_button.lua:253
---@param options PrettyUI.SliderOptions?
---@return PrettyUI.Slider
function prettyui.CollapseButton:AddSlider(options) end
---Source: src/collapse_button.lua:300
---@param value string|PrettyUI.TextOptions
---@return any
function prettyui.CollapseButton:AddText(value) end
---Source: src/collapse_button.lua:284
---@param options PrettyUI.TextFieldOptions?
---@return PrettyUI.TextField
function prettyui.CollapseButton:AddTextField(options) end
---Source: src/collapse_button.lua:200
---@param owner any
---@return any
function prettyui.CollapseButton:BindFlow(owner) end
---Source: src/collapse_button.lua:382
---@return any
function prettyui.CollapseButton:Destroy() end
---Source: src/collapse_button.lua:338
---@param disabled boolean
---@return any
function prettyui.CollapseButton:SetDisabled(disabled) end
---Source: src/collapse_button.lua:324
---@param expanded boolean
---@return any
function prettyui.CollapseButton:SetExpanded(expanded) end
---Source: src/collapse_button.lua:350
---@param cursor any
---@return any
function prettyui.CollapseButton:SetHoverCursor(cursor) end
---Source: src/collapse_button.lua:345
---@param text any
---@return any
function prettyui.CollapseButton:SetText(text) end
---Source: src/collapse_button.lua:355
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function prettyui.CollapseButton:SetTooltip(value) end
---Source: src/collapse_button.lua:334
---@return any
function prettyui.CollapseButton:Toggle() end
---Source: src/collapse_button.lua:71
---@param parent any
---@param text string
---@param options PrettyUI.CollapseButtonOptions?
---@return PrettyUI.CollapseButton
function prettyui.CollapseButton.new(parent, text, options) end

---Options for ColourPicker. Source: src/colour_picker.lua
---@class PrettyUI.ColourPickerOptions
---@field absolute? any
---@field acceptText? string
---@field acceptVariant? 'neutral'|'positive'|'negative'
---@field acceptWidth? number
---@field alphaSlider? boolean
---@field buttonSize? number
---@field colour? number
---@field columnGap? any
---@field defaultColour? number
---@field disabled? boolean
---@field height? number
---@field inline? boolean
---@field marginBottom? number
---@field marginTop? number
---@field offsetY? any
---@field onChange? fun(picker: PrettyUI.ColourPicker, colour: number)
---@field overlayParent? any
---@field pickerX? number
---@field pickerY? number
---@field rowBackground? any
---@field rowBackgroundGroup? any
---@field showAlpha? boolean
---@field size? number
---@field title? string
---@field tooltip? string|PrettyUI.TooltipOptions
---@field value? number
---@field width? number
---@field widthAnchor? any
---@field windowHeight? number
---@field windowParent? any
---@field windowTitle? string
---@field windowWidth? number
---@field windowX? number
---@field windowY? number
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/colour_picker.lua
---@class PrettyUI.ColourPicker
prettyui.ColourPicker = {}
---Source: src/colour_picker.lua:643
---@return any
function prettyui.ColourPicker:Close() end
---Source: src/colour_picker.lua:647
---@return any
function prettyui.ColourPicker:Destroy() end
---Source: src/colour_picker.lua:635
---@return number
function prettyui.ColourPicker:GetColour() end
---Source: src/colour_picker.lua:617
---@return number
function prettyui.ColourPicker:GetValue() end
---Source: src/colour_picker.lua:459
---@return boolean
function prettyui.ColourPicker:Open() end
---Source: src/colour_picker.lua:636
---@param colour number
---@param notify boolean?
---@return any
function prettyui.ColourPicker:SetColour(colour, notify) end
---Source: src/colour_picker.lua:638
---@param disabled boolean
---@return any
function prettyui.ColourPicker:SetDisabled(disabled) end
---Source: src/colour_picker.lua:621
---@param colour number
---@param notify boolean?
---@return any
function prettyui.ColourPicker:SetValue(colour, notify) end
---Source: src/colour_picker.lua:121
---@param parent any
---@param options PrettyUI.ColourPickerOptions?
---@return PrettyUI.ColourPicker
function prettyui.ColourPicker.new(parent, options) end

---Options for ComboBox. Source: src/combo_box.lua
---@class PrettyUI.ComboBoxOptions
---@field absolute? any
---@field caretColor? number
---@field caretColour? number
---@field choices? (string|PrettyUI.ComboEntry)[]
---@field color? number
---@field colour? number
---@field columnGap? any
---@field contentMargin? any
---@field disabled? boolean
---@field disabledTextColor? number
---@field disabledTextColour? number
---@field dropdownBackgroundColor? number
---@field dropdownBackgroundColour? number
---@field dropdownBorderColor? number
---@field dropdownBorderColour? number
---@field dropdownMaxVisibleEntries? integer
---@field entries? (string|PrettyUI.ComboEntry)[]
---@field entryHeight? number
---@field errorCaretColor? number
---@field errorCaretColour? number
---@field font? number
---@field headerMargin? any
---@field height? number
---@field heightAnchor? number
---@field hoverColor? number
---@field hoverColour? number
---@field hoverTextColor? number
---@field hoverTextColour? number
---@field inline? any
---@field inputMode? any
---@field inputStylesheetID? number
---@field marginBottom? any
---@field marginTop? any
---@field maxLength? integer
---@field maxVisibleEntries? integer
---@field offsetY? any
---@field onChange? fun(combo: PrettyUI.ComboBox, id: any, label: string, eventType: any)
---@field overlayParent? any
---@field placeholderColor? number
---@field placeholderColour? number
---@field rowBackground? any
---@field rowBackgroundGroup? any
---@field selected? any
---@field selectedColor? number
---@field selectedColour? number
---@field selectedID? any
---@field selectedTextColor? number
---@field selectedTextColour? number
---@field selectionColor? number
---@field selectionColour? number
---@field shadowed? boolean
---@field size? any
---@field stylesheetID? number
---@field tooltip? string|PrettyUI.TooltipOptions
---@field width? number
---@field widthAnchor? number
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/combo_box.lua
---@class PrettyUI.ComboBox
prettyui.ComboBox = {}
---Source: src/combo_box.lua:123
---@param label string
---@param entryID any
---@return boolean
function prettyui.ComboBox:Add(label, entryID) end
---Source: src/combo_box.lua:136
---@return any
function prettyui.ComboBox:Clear() end
---Source: src/combo_box.lua:223
---@return any
function prettyui.ComboBox:Destroy() end
---Source: src/combo_box.lua:204
---@return any
function prettyui.ComboBox:GetSelectedID() end
---Source: src/combo_box.lua:208
---@return string|nil
function prettyui.ComboBox:GetSelectedLabel() end
---Source: src/combo_box.lua:130
---@param entryID any
---@return boolean
function prettyui.ComboBox:Remove(entryID) end
---Source: src/combo_box.lua:197
---@param entryID any
---@param triggerEvents boolean?
---@return boolean
function prettyui.ComboBox:Select(entryID, triggerEvents) end
---Source: src/combo_box.lua:213
---@param disabled boolean
---@return any
function prettyui.ComboBox:SetDisabled(disabled) end
---Source: src/combo_box.lua:141
---@param entries (string|PrettyUI.ComboEntry)[]
---@param selectedID any?
---@return any
function prettyui.ComboBox:SetEntries(entries, selectedID) end
---Source: src/combo_box.lua:219
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function prettyui.ComboBox:SetTooltip(value) end
---Source: src/combo_box.lua:60
---@param parent any
---@param options PrettyUI.ComboBoxOptions?
---@return PrettyUI.ComboBox
function prettyui.ComboBox.new(parent, options) end

---@class PrettyUI.ComboEntry
---@field id any?
---@field label string?
---@field order integer?
---@field text string?
---@field value any?
local ComboEntry = {}

---Options for Confirm. Source: src/confirm.lua
---@class PrettyUI.ConfirmOptions
---@field body? string
---@field cancelLabel? string
---@field confirmLabel? string
---@field confirmVariant? 'neutral'|'positive'|'negative'
---@field height? number
---@field modal? boolean
---@field onCancel? fun(): boolean?
---@field onConfirm? fun(): boolean?
---@field title? string
---@field width? number

---Source: src/confirm.lua
---@class PrettyUI.Confirm
prettyui.Confirm = {}
---Source: src/confirm.lua:26
---@param parent any
---@param options PrettyUI.ConfirmOptions?
---@return PrettyUI.Dialog
function prettyui.Confirm.new(parent, options) end

---Options for Dialog. Source: src/dialog.lua
---@class PrettyUI.DialogOptions
---@field actions? PrettyUI.DialogAction[]
---@field content? fun(window: PrettyUI.Window)
---@field height? number
---@field modal? boolean
---@field onDismiss? fun()
---@field title? string
---@field width? number

---Source: src/dialog.lua
---@class PrettyUI.Dialog
---@field window PrettyUI.Window
prettyui.Dialog = {}
---Source: src/dialog.lua:284
---@return any
function prettyui.Dialog:Destroy() end
---Source: src/dialog.lua:274
---@param action any
---@param disabled any
---@return any
function prettyui.Dialog:SetActionDisabled(action, disabled) end
---Source: src/dialog.lua:40
---@param parent any
---@return integer
function prettyui.Dialog.depth(parent) end
---Source: src/dialog.lua:154
---@param parent any
---@return any
function prettyui.Dialog.dismissAll(parent) end
---Source: src/dialog.lua:224
---@param parent any
---@param options PrettyUI.DialogOptions?
---@return PrettyUI.Dialog
function prettyui.Dialog.new(parent, options) end

---@class PrettyUI.DialogAction
---@field disabled boolean?
---@field label string
---@field onClick fun(): boolean?
---@field tooltip string|PrettyUI.TooltipOptions|nil
---@field variant 'neutral'|'positive'|'negative'?
local DialogAction = {}

---Options for Divider. Source: src/divider.lua
---@class PrettyUI.DividerOptions
---@field absolute? any
---@field columnGap? any
---@field height? any
---@field inline? any
---@field marginBottom? number
---@field marginTop? number
---@field offsetY? any
---@field rowBackground? boolean
---@field rowBackgroundGroup? any
---@field size? any
---@field tooltip? string|PrettyUI.TooltipOptions
---@field width? number
---@field widthAnchor? number
---@field x? number
---@field xAnchor? any
---@field y? number
---@field yAnchor? any

---Source: src/divider.lua
---@class PrettyUI.Divider
prettyui.Divider = {}
---Source: src/divider.lua:54
---@return any
function prettyui.Divider:Destroy() end
---Source: src/divider.lua:50
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function prettyui.Divider:SetTooltip(value) end
---Source: src/divider.lua:24
---@param parent any
---@param options PrettyUI.DividerOptions?
---@return PrettyUI.Divider
function prettyui.Divider.new(parent, options) end

---Options for FancyButton. Source: src/fancy_button.lua
---@class PrettyUI.FancyButtonOptions
---@field absolute? boolean
---@field colour? number
---@field columnGap? number
---@field disabled? boolean
---@field disabledColour? number
---@field height? any
---@field hoverCursor? any
---@field inline? boolean
---@field marginBottom? number
---@field marginTop? number
---@field offsetY? number
---@field rowBackground? any
---@field rowBackgroundGroup? any
---@field size? any
---@field tooltip? string|PrettyUI.TooltipOptions
---@field variant? 'neutral'|'positive'|'negative'
---@field width? number
---@field widthAnchor? any
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/fancy_button.lua
---@class PrettyUI.FancyButton
prettyui.FancyButton = {}
---Source: src/fancy_button.lua:184
---@return any
function prettyui.FancyButton:Destroy() end
---Source: src/fancy_button.lua:151
---@param disabled boolean
---@return any
function prettyui.FancyButton:SetDisabled(disabled) end
---Source: src/fancy_button.lua:179
---@param cursor any
---@return any
function prettyui.FancyButton:SetHoverCursor(cursor) end
---Source: src/fancy_button.lua:171
---@param text string
---@return any
function prettyui.FancyButton:SetText(text) end
---Source: src/fancy_button.lua:158
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function prettyui.FancyButton:SetTooltip(value) end
---Source: src/fancy_button.lua:162
---@param variant 'neutral'|'positive'|'negative'
---@return any
function prettyui.FancyButton:SetVariant(variant) end
---Source: src/fancy_button.lua:55
---@param parent any
---@param text string
---@param action fun(button: PrettyUI.FancyButton)?
---@param options PrettyUI.FancyButtonOptions?
---@return PrettyUI.FancyButton
function prettyui.FancyButton.new(parent, text, action, options) end

---Options for FlowOptions. Source: editor/api.json
---@class PrettyUI.FlowOptions
---@field absolute? boolean?
---@field columnGap? number?
---@field height? number?
---@field heightAnchor? number?
---@field inline? boolean?
---@field marginBottom? number?
---@field marginTop? number?
---@field offsetY? number?
---@field rowBackground? boolean?
---@field rowBackgroundGroup? any?
---@field width? number?
---@field widthAnchor? number?
---@field x? number?
---@field xAnchor? number?
---@field y? number?
---@field yAnchor? number?

---Options for Histogram. Source: src/histogram.lua
---@class PrettyUI.HistogramOptions
---@field absolute? any
---@field binWidth? number
---@field columnGap? any
---@field height? number
---@field heightAnchor? number
---@field inline? any
---@field label? string
---@field marginBottom? any
---@field marginTop? any
---@field offsetY? any
---@field origin? number
---@field rgba? number
---@field rowBackground? any
---@field rowBackgroundGroup? any
---@field samples? number[]
---@field size? any
---@field visible? boolean
---@field width? number
---@field widthAnchor? number
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/histogram.lua
---@class PrettyUI.Histogram
prettyui.Histogram = {}
---Source: src/core/bar_renderer.lua:371
---@return any
function prettyui.Histogram:Destroy() end
---Source: src/histogram.lua:44
---@return PrettyUI.HistogramSnapshot
function prettyui.Histogram:GetSnapshot() end
---Source: src/histogram.lua:51
---@return boolean
function prettyui.Histogram:Reset() end
---Source: src/histogram.lua:36
---@param bins PrettyUI.HistogramBin[]
---@return boolean
function prettyui.Histogram:SetBins(bins) end
---Source: src/histogram.lua:26
---@param samples number[]
---@return boolean
function prettyui.Histogram:SetSamples(samples) end
---Source: src/core/bar_renderer.lua:361
---@param width number
---@param height number
---@return boolean
function prettyui.Histogram:SetSize(width, height) end
---Source: src/core/bar_renderer.lua:351
---@param visible boolean
---@return boolean
function prettyui.Histogram:SetVisible(visible) end
---Source: src/histogram.lua:12
---@param parent any
---@param options PrettyUI.HistogramOptions?
---@return PrettyUI.Histogram
function prettyui.Histogram.new(parent, options) end

---@class PrettyUI.HistogramBin
---@field count integer
---@field lower number
---@field upper number
local HistogramBin = {}

---@class PrettyUI.HistogramSnapshot
---@field binWidth number
---@field bins PrettyUI.HistogramBin[]
---@field label string
---@field origin number
---@field sampleCount integer
local HistogramSnapshot = {}

---Options for ItemGrid. Source: src/item_grid.lua
---@class PrettyUI.ItemGridOptions
---@field absolute? any
---@field columnGap? any
---@field columns? integer
---@field dragDrop? boolean
---@field height? any
---@field inline? any
---@field itemInset? number
---@field marginBottom? any
---@field marginTop? any
---@field offsetY? any
---@field onDrop? fun(grid: PrettyUI.ItemGrid, sourceIndex: integer, destinationIndex: integer, moved: any, displaced: any)
---@field outlineWidth? number
---@field quantityMode? any
---@field rowBackground? any
---@field rowBackgroundGroup? any
---@field rows? integer
---@field shadowRGBA? number
---@field size? any
---@field slotGap? number
---@field tooltip? boolean|string|PrettyUI.TooltipOptions|fun(object: any, index: integer, row: integer, column: integer): (string|PrettyUI.TooltipOptions|nil)
---@field width? any
---@field widthAnchor? any
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/item_grid.lua
---@class PrettyUI.ItemGrid
prettyui.ItemGrid = {}
---Source: src/item_grid.lua:386
---@return any
function prettyui.ItemGrid:Destroy() end
---Source: src/item_grid.lua:331
---@param index integer
---@return PrettyUI.ItemSlot|nil
function prettyui.ItemGrid:GetSlot(index) end
---Source: src/item_grid.lua:354
---@param sourceIndex integer
---@param destinationIndex integer
---@param notify boolean?
---@return boolean
function prettyui.ItemGrid:MoveObject(sourceIndex, destinationIndex, notify) end
---Source: src/item_grid.lua:371
---@param enabled boolean
---@return any
function prettyui.ItemGrid:SetDragDropEnabled(enabled) end
---Source: src/item_grid.lua:335
---@param index integer
---@param object any?
---@param tooltip string|PrettyUI.TooltipOptions|nil
---@param quantity integer?
---@return boolean
function prettyui.ItemGrid:SetObject(index, object, tooltip, quantity) end
---Source: src/item_grid.lua:342
---@param column integer
---@param row integer
---@param object any?
---@param tooltip string|PrettyUI.TooltipOptions|nil
---@param quantity integer?
---@return boolean
function prettyui.ItemGrid:SetObjectAt(column, row, object, tooltip, quantity) end
---Source: src/item_grid.lua:378
---@param objects table<integer, any|PrettyUI.ItemGridEntry>
---@return any
function prettyui.ItemGrid:SetObjects(objects) end
---Source: src/item_grid.lua:347
---@param value boolean|string|PrettyUI.TooltipOptions|fun(object: any, index: integer, row: integer, column: integer): (string|PrettyUI.TooltipOptions|nil)
---@return boolean
function prettyui.ItemGrid:SetTooltip(value) end
---Source: src/item_grid.lua:251
---@param parent any
---@param objects table<integer, any|PrettyUI.ItemGridEntry>
---@param options PrettyUI.ItemGridOptions?
---@return PrettyUI.ItemGrid
function prettyui.ItemGrid.new(parent, objects, options) end

---@class PrettyUI.ItemGridEntry
---@field object any
---@field quantity integer?
---@field tooltip string|PrettyUI.TooltipOptions|nil
local ItemGridEntry = {}

---Options for ItemSlot. Source: src/item_slot.lua
---@class PrettyUI.ItemSlotOptions
---@field absolute? any
---@field backgroundSpriteID? any
---@field clickthrough? boolean
---@field columnGap? any
---@field disabled? boolean
---@field height? any
---@field inline? any
---@field itemInset? number
---@field marginBottom? any
---@field marginTop? any
---@field offsetY? any
---@field onObjectChange? any
---@field outlineWidth? number
---@field quantity? integer
---@field quantityMode? any
---@field rowBackground? any
---@field rowBackgroundGroup? any
---@field shadowRGBA? number
---@field size? any
---@field tooltip? string|PrettyUI.TooltipOptions
---@field width? any
---@field widthAnchor? any
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/item_slot.lua
---@class PrettyUI.ItemSlot
prettyui.ItemSlot = {}
---Source: src/item_slot.lua:188
---@return any
function prettyui.ItemSlot:Destroy() end
---Source: src/item_slot.lua:176
---@param disabled boolean
---@return any
function prettyui.ItemSlot:SetDisabled(disabled) end
---Source: src/item_slot.lua:163
---@param object any?
---@param quantity integer?
---@return any
function prettyui.ItemSlot:SetObject(object, quantity) end
---Source: src/item_slot.lua:171
---@param quantity integer?
---@return any
function prettyui.ItemSlot:SetQuantity(quantity) end
---Source: src/item_slot.lua:181
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function prettyui.ItemSlot:SetTooltip(value) end
---Source: src/item_slot.lua:114
---@param parent any
---@param object any?
---@param options PrettyUI.ItemSlotOptions?
---@return PrettyUI.ItemSlot
function prettyui.ItemSlot.new(parent, object, options) end

---Options for KeybindField. Source: src/keybind_field.lua
---@class PrettyUI.KeybindFieldOptions
---@field absolute? any
---@field color? number
---@field colour? number
---@field columnGap? any
---@field defaultValue? integer[]
---@field disabled? boolean
---@field font? number
---@field height? number
---@field heightAnchor? number
---@field inline? any
---@field inputSprite? any
---@field marginBottom? any
---@field marginTop? any
---@field offsetY? any
---@field onChange? fun(field: PrettyUI.KeybindField, value: integer[])
---@field rowBackground? any
---@field rowBackgroundGroup? any
---@field shadowed? boolean
---@field size? any
---@field stylesheetID? number
---@field value? integer[]
---@field width? number
---@field widthAnchor? number
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/keybind_field.lua
---@class PrettyUI.KeybindField
prettyui.KeybindField = {}
---Source: src/keybind_field.lua:236
---@return any
function prettyui.KeybindField:CancelListening() end
---Source: src/keybind_field.lua:271
---@return any
function prettyui.KeybindField:Destroy() end
---Source: src/keybind_field.lua:38
---@param value integer[]
---@return string
function prettyui.KeybindField.FormatValue(value) end
---Source: src/keybind_field.lua:248
---@return integer[]
function prettyui.KeybindField:GetValue() end
---Source: src/keybind_field.lua:51
---@return boolean
function prettyui.KeybindField.IsCapturing() end
---Source: src/keybind_field.lua:58
---@param value integer[]
---@return boolean
function prettyui.KeybindField.IsDown(value) end
---Source: src/keybind_field.lua:244
---@return boolean
function prettyui.KeybindField:IsListening() end
---Source: src/keybind_field.lua:260
---@param disabled boolean
---@return any
function prettyui.KeybindField:SetDisabled(disabled) end
---Source: src/keybind_field.lua:252
---@param value integer[]
---@param notify boolean?
---@return any
function prettyui.KeybindField:SetValue(value, notify) end
---Source: src/keybind_field.lua:225
---@return any
function prettyui.KeybindField:StartListening() end
---Source: src/keybind_field.lua:132
---@param parent any
---@param options PrettyUI.KeybindFieldOptions?
---@return PrettyUI.KeybindField
function prettyui.KeybindField.new(parent, options) end

---Options for LayoutOptions. Source: src/core/layout.lua
---@class PrettyUI.LayoutOptions
---@field columnGap? any
---@field padding? any
---@field paddingBottom? any
---@field paddingLeft? any
---@field paddingRight? any
---@field rowGap? any
---@field startY? any

---Options for List. Source: src/list.lua
---@class PrettyUI.ListOptions
---@field absolute? any
---@field backgroundColor? number
---@field backgroundColour? number
---@field borderColor? number
---@field borderColour? number
---@field choices? (string|PrettyUI.ListEntry)[]
---@field color? number
---@field colour? number
---@field columnGap? any
---@field disabled? boolean
---@field disabledColor? number
---@field disabledColour? number
---@field disabledTextColor? number
---@field disabledTextColour? number
---@field entries? (string|PrettyUI.ListEntry)[]
---@field entryHeight? number
---@field entryIconScale? number
---@field font? number
---@field height? number
---@field heightAnchor? number
---@field hoverColor? number
---@field hoverColour? number
---@field inline? any
---@field marginBottom? any
---@field marginTop? any
---@field maxSelected? integer
---@field offsetY? any
---@field onChange? fun(list: PrettyUI.List, id: any, selected: boolean, eventType: any)
---@field rowBackground? any
---@field rowBackgroundGroup? any
---@field selectedColor? number
---@field selectedColour? number
---@field shadowed? boolean
---@field size? any
---@field tooltip? string|PrettyUI.TooltipOptions
---@field width? number
---@field widthAnchor? number
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/list.lua
---@class PrettyUI.List
prettyui.List = {}
---Source: src/list.lua:440
---@param label string
---@param entryID any
---@return boolean
function prettyui.List:Add(label, entryID) end
---Source: src/list.lua:455
---@return any
function prettyui.List:Clear() end
---Source: src/list.lua:559
---@return any
function prettyui.List:Destroy() end
---Source: src/list.lua:540
---@return PrettyUI.ListStateEntry[]
function prettyui.List:GetSelectedEntries() end
---Source: src/list.lua:548
---@param disabled boolean
---@return any
function prettyui.List:SetDisabled(disabled) end
---Source: src/list.lua:461
---@param entries (string|PrettyUI.ListEntry)[]
---@return any
function prettyui.List:SetEntries(entries) end
---Source: src/list.lua:514
---@param entryID any
---@param enabled boolean
---@return boolean
function prettyui.List:SetEntryEnabled(entryID, enabled) end
---Source: src/list.lua:532
---@param entryID any
---@param spriteID number?
---@return boolean
function prettyui.List:SetEntryIcon(entryID, spriteID) end
---Source: src/list.lua:523
---@param entryID any
---@param visible boolean
---@return boolean
function prettyui.List:SetEntryVisible(entryID, visible) end
---Source: src/list.lua:275
---@param value number
---@return any
function prettyui.List:SetScrollPosition(value) end
---Source: src/list.lua:505
---@param entryID any
---@param selected boolean
---@param triggerEvents boolean?
---@return boolean
function prettyui.List:SetSelected(entryID, selected, triggerEvents) end
---Source: src/list.lua:240
---@param width number
---@param height number
---@param widthAnchor number?
---@param heightAnchor number?
---@return any
function prettyui.List:SetSize(width, height, widthAnchor, heightAnchor) end
---Source: src/list.lua:555
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function prettyui.List:SetTooltip(value) end
---Source: src/list.lua:509
---@return any
function prettyui.List:UnselectAll() end
---Source: src/list.lua:80
---@param parent any
---@param options PrettyUI.ListOptions?
---@return PrettyUI.List
function prettyui.List.new(parent, options) end

---@class PrettyUI.ListEntry
---@field backgroundColor number?
---@field backgroundColour number?
---@field color number?
---@field colour number?
---@field disabled boolean?
---@field disabledTextColor number?
---@field disabledTextColour number?
---@field enabled boolean?
---@field hoverColor number?
---@field hoverColour number?
---@field icon number?
---@field id any?
---@field label string?
---@field selected boolean?
---@field selectedColor number?
---@field selectedColour number?
---@field text string?
---@field textColor number?
---@field textColour number?
---@field value any?
---@field visible boolean?
local ListEntry = {}

---@class PrettyUI.ListStateEntry
---@field backgroundColour number|nil
---@field disabledTextColour number|nil
---@field enabled boolean
---@field hoverColour number|nil
---@field icon number|nil
---@field id any
---@field selected boolean
---@field selectedColour number|nil
---@field text string
---@field textColour number|nil
---@field visible boolean
local ListStateEntry = {}

---Options for MiniMenu. Source: src/minimenu.lua
---@class PrettyUI.MiniMenuOptions
---@field arrow? boolean?
---@field parentAction? fun()?
---@field position? 'top'|'bottom'|integer?
---@field title? string?

---Source: src/minimenu.lua
---@class PrettyUI.MiniMenu
prettyui.MiniMenu = {}
---Source: src/minimenu.lua:632
---@param miniMenu any
---@param label string
---@param children PrettyUI.MiniMenuChild[]
---@param options PrettyUI.MiniMenuOptions?
---@return any
function prettyui.MiniMenu.AddSubmenu(miniMenu, label, children, options) end

---@class PrettyUI.MiniMenuChild
---@field action fun(...: any)
---@field args any[]?
---@field arguments any[]?
---@field label string
local MiniMenuChild = {}

---Source: src/overhead_bar.lua
---@class PrettyUI.OverheadBar
prettyui.OverheadBar = {}
---Source: src/overhead_bar.lua:159
---@return any
function prettyui.OverheadBar:Destroy() end
---Source: src/overhead_bar.lua:154
---@return any
function prettyui.OverheadBar:Hide() end
---Source: src/overhead_bar.lua:82
---@param value any
---@return any
function prettyui.OverheadBar:SetValue(value) end
---Source: src/overhead_bar.lua:91
---@param name any
---@return any
function prettyui.OverheadBar:SetVariant(name) end
---Source: src/overhead_bar.lua:149
---@return any
function prettyui.OverheadBar:Show() end
---Source: src/overhead_bar.lua:106
---@return any
function prettyui.OverheadBar:Update() end
---Source: src/overhead_bar.lua:78
---@param loc any
---@param options any
---@return any
function prettyui.OverheadBar.forLoc(loc, options) end
---Source: src/overhead_bar.lua:70
---@param npc any
---@param options any
---@return any
function prettyui.OverheadBar.forNPC(npc, options) end
---Source: src/overhead_bar.lua:74
---@param player any
---@param options any
---@return any
function prettyui.OverheadBar.forPlayer(player, options) end

---Options for Panel. Source: src/panel.lua
---@class PrettyUI.PanelOptions
---@field absolute? any
---@field backgroundAlpha? number
---@field clickthrough? boolean
---@field columnGap? any
---@field contentHeight? number
---@field height? number
---@field heightAnchor? number
---@field inline? any
---@field layout? PrettyUI.LayoutOptions
---@field marginBottom? any
---@field marginTop? any
---@field maxHeight? number
---@field maxWidth? number
---@field minHeight? number
---@field minWidth? number
---@field offsetY? any
---@field onChange? any
---@field onPopoutChange? fun(panel: PrettyUI.Panel, poppedOut: boolean)
---@field onPositionChange? any
---@field onSubmit? any
---@field overlayParent? any
---@field popout? boolean
---@field popoutBackgroundAlpha? number
---@field popoutClickthrough? boolean
---@field popoutHeight? number
---@field popoutWidth? number
---@field popoutX? number
---@field popoutXAnchor? any
---@field popoutY? number
---@field popoutYAnchor? any
---@field poppedOut? boolean
---@field resizable? boolean
---@field rowBackground? any
---@field rowBackgroundColors? number[]
---@field rowBackgroundColours? number[]
---@field rowBackgroundEdgeToEdge? boolean
---@field rowBackgroundGroup? any
---@field scrollStep? number
---@field scrollable? boolean
---@field size? any
---@field textLayout? PrettyUI.LayoutOptions
---@field tooltip? string|PrettyUI.TooltipOptions
---@field width? number
---@field widthAnchor? number
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/panel.lua
---@class PrettyUI.Panel : PrettyUI.View
---@field content any
---@field contentHeight number
---@field contentWidth number
---@field overlayContent any
---@field poppedOut boolean
---@field root any
prettyui.Panel = {}
---Source: src/core/content_methods.lua:32
---@param options PrettyUI.BarChartOptions?
---@return PrettyUI.PanelBarChartProxy
function prettyui.Panel:AddBarChart(options) end
---Source: src/core/content_methods.lua:30
---@param options PrettyUI.BigSpinnerOptions?
---@return PrettyUI.PanelBigSpinnerProxy
function prettyui.Panel:AddBigSpinner(options) end
---Source: src/core/content_methods.lua:89
---@param choices (any|PrettyUI.Choice)[]
---@param options PrettyUI.CheckboxButtonOptions?
---@return PrettyUI.PanelCheckboxButtonProxy
function prettyui.Panel:AddCheckboxButton(choices, options) end
---Source: src/panel.lua:785
---@param text string
---@param options PrettyUI.CollapseButtonOptions?
---@return PrettyUI.PanelCollapseButtonProxy
function prettyui.Panel:AddCollapseButton(text, options) end
---Source: src/panel.lua:881
---@param options PrettyUI.ColourPickerOptions?
---@return PrettyUI.PanelColourPickerProxy
function prettyui.Panel:AddColourPicker(options) end
---Source: src/panel.lua:956
---@param options PrettyUI.ComboBoxOptions?
---@return PrettyUI.PanelComboBoxProxy
function prettyui.Panel:AddComboBox(options) end
---Source: src/core/content_methods.lua:35
---@param options PrettyUI.DividerOptions?
---@return PrettyUI.PanelDividerProxy
function prettyui.Panel:AddDivider(options) end
---Source: src/core/content_methods.lua:146
---@param text string
---@param action fun(button: PrettyUI.FancyButton)?
---@param options PrettyUI.FancyButtonOptions?
---@return PrettyUI.PanelFancyButtonProxy
function prettyui.Panel:AddFancyButton(text, action, options) end
---Source: src/core/content_methods.lua:33
---@param options PrettyUI.HistogramOptions?
---@return PrettyUI.PanelHistogramProxy
function prettyui.Panel:AddHistogram(options) end
---Source: src/core/content_methods.lua:45
---@param objects table<integer, any|PrettyUI.ItemGridEntry>
---@param options PrettyUI.ItemGridOptions?
---@return PrettyUI.PanelItemGridProxy
function prettyui.Panel:AddItemGrid(objects, options) end
---Source: src/core/content_methods.lua:43
---@param object any?
---@param options PrettyUI.ItemSlotOptions?
---@return PrettyUI.PanelItemSlotProxy
function prettyui.Panel:AddItemSlot(object, options) end
---Source: src/panel.lua:777
---@param options PrettyUI.KeybindFieldOptions?
---@return PrettyUI.PanelKeybindFieldProxy
function prettyui.Panel:AddKeybindField(options) end
---Source: src/panel.lua:992
---@param options PrettyUI.ListOptions?
---@return PrettyUI.PanelListProxy
function prettyui.Panel:AddList(options) end
---Source: src/core/content_methods.lua:79
---@param choices (any|PrettyUI.Choice)[]
---@param options PrettyUI.RadioButtonOptions?
---@return PrettyUI.PanelRadioButtonProxy
function prettyui.Panel:AddRadioButton(choices, options) end
---Source: src/core/content_methods.lua:122
---@param spriteID number
---@param action fun(button: PrettyUI.RibbonButton)?
---@param options PrettyUI.RibbonButtonOptions?
---@return PrettyUI.PanelRibbonButtonProxy
function prettyui.Panel:AddRibbonButton(spriteID, action, options) end
---Source: src/core/content_methods.lua:130
---@param content string|number
---@param action fun(button: PrettyUI.SimpleButton, active: boolean)?
---@param options PrettyUI.SimpleButtonOptions?
---@return PrettyUI.PanelSimpleButtonProxy
function prettyui.Panel:AddSimpleButton(content, action, options) end
---Source: src/panel.lua:1032
---@param options PrettyUI.SliderOptions?
---@return PrettyUI.PanelSliderProxy
function prettyui.Panel:AddSlider(options) end
---Source: src/core/content_methods.lua:29
---@param options PrettyUI.SpinnerOptions?
---@return PrettyUI.PanelSpinnerProxy
function prettyui.Panel:AddSpinner(options) end
---Source: src/core/content_methods.lua:28
---@param sprite any
---@param options PrettyUI.SpriteOptions?
---@return PrettyUI.PanelSpriteProxy
function prettyui.Panel:AddSprite(sprite, options) end
---Source: src/core/content_methods.lua:154
---@param spriteName string
---@param action fun(button: PrettyUI.SpriteButton, enabled: boolean)?
---@param options PrettyUI.SpriteButtonOptions?
---@return PrettyUI.PanelSpriteButtonProxy
function prettyui.Panel:AddSpriteButton(spriteName, action, options) end
---Source: src/panel.lua:851
---@param tabs (string|number|PrettyUI.TabEntry)[]
---@param options PrettyUI.TabsOptions?
---@return PrettyUI.PanelTabsProxy
function prettyui.Panel:AddTabs(tabs, options) end
---Source: src/core/content_methods.lua:26
---@param value string|PrettyUI.TextOptions
---@return any
function prettyui.Panel:AddText(value) end
---Source: src/panel.lua:917
---@param options PrettyUI.TextFieldOptions?
---@return PrettyUI.PanelTextFieldProxy
function prettyui.Panel:AddTextField(options) end
---Source: src/panel.lua:808
---@param options PrettyUI.TimeGraphOptions
---@return PrettyUI.PanelTimeGraphProxy
function prettyui.Panel:AddTimeGraph(options) end
---Source: src/core/content_methods.lua:27
---@param value any
---@return any
function prettyui.Panel:AddTitle(value) end
---Source: src/panel.lua:655
---@param owner any
---@return any
function prettyui.Panel:BindFlow(owner) end
---Source: src/panel.lua:1056
---@return any
function prettyui.Panel:Destroy() end
---Source: src/panel.lua:755
---@return any
function prettyui.Panel:RefreshRowBackgrounds() end
---Source: src/panel.lua:760
---@param child any
---@param topOffset number?
---@return any
function prettyui.Panel:ScrollToChild(child, topOffset) end
---Source: src/panel.lua:706
---@param alpha number
---@return any
function prettyui.Panel:SetPopoutBackgroundAlpha(alpha) end
---Source: src/panel.lua:696
---@param value boolean
---@return any
function prettyui.Panel:SetPopoutClickthrough(value) end
---Source: src/panel.lua:661
---@param value boolean
---@param notify boolean?
---@return any
function prettyui.Panel:SetPoppedOut(value, notify) end
---Source: src/panel.lua:747
---@param value boolean
---@return any
function prettyui.Panel:SetScrollable(value) end
---Source: src/panel.lua:711
---@param width number
---@param height number
---@return any
function prettyui.Panel:SetSize(width, height) end
---Source: src/panel.lua:741
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function prettyui.Panel:SetTooltip(value) end
---Source: src/panel.lua:692
---@return any
function prettyui.Panel:TogglePopout() end
---Source: src/panel.lua:357
---@param parent any
---@param options PrettyUI.PanelOptions?
---@return PrettyUI.Panel
function prettyui.Panel.new(parent, options) end

---@class PrettyUI.PanelBarChartProxy: PrettyUI.BarChart
---@field dock PrettyUI.BarChart
---@field overlay PrettyUI.BarChart
local PanelBarChartProxy = {}

---@class PrettyUI.PanelBigSpinnerProxy: PrettyUI.BigSpinner
---@field dock PrettyUI.BigSpinner
---@field overlay PrettyUI.BigSpinner
local PanelBigSpinnerProxy = {}

---@class PrettyUI.PanelCheckboxButtonProxy: PrettyUI.CheckboxButton
---@field dock PrettyUI.CheckboxButton
---@field overlay PrettyUI.CheckboxButton
local PanelCheckboxButtonProxy = {}

---@class PrettyUI.PanelCollapseButtonProxy: PrettyUI.CollapseButton
---@field dock PrettyUI.CollapseButton
---@field overlay PrettyUI.CollapseButton
local PanelCollapseButtonProxy = {}

---@class PrettyUI.PanelColourPickerProxy: PrettyUI.ColourPicker
---@field dock PrettyUI.ColourPicker
---@field overlay PrettyUI.ColourPicker
local PanelColourPickerProxy = {}

---@class PrettyUI.PanelComboBoxProxy: PrettyUI.ComboBox
---@field dock PrettyUI.ComboBox
---@field overlay PrettyUI.ComboBox
local PanelComboBoxProxy = {}

---@class PrettyUI.PanelDividerProxy: PrettyUI.Divider
---@field dock PrettyUI.Divider
---@field overlay PrettyUI.Divider
local PanelDividerProxy = {}

---@class PrettyUI.PanelFancyButtonProxy: PrettyUI.FancyButton
---@field dock PrettyUI.FancyButton
---@field overlay PrettyUI.FancyButton
local PanelFancyButtonProxy = {}

---@class PrettyUI.PanelHistogramProxy: PrettyUI.Histogram
---@field dock PrettyUI.Histogram
---@field overlay PrettyUI.Histogram
local PanelHistogramProxy = {}

---@class PrettyUI.PanelItemGridProxy: PrettyUI.ItemGrid
---@field dock PrettyUI.ItemGrid
---@field overlay PrettyUI.ItemGrid
local PanelItemGridProxy = {}

---@class PrettyUI.PanelItemSlotProxy: PrettyUI.ItemSlot
---@field dock PrettyUI.ItemSlot
---@field overlay PrettyUI.ItemSlot
local PanelItemSlotProxy = {}

---@class PrettyUI.PanelKeybindFieldProxy: PrettyUI.KeybindField
---@field dock PrettyUI.KeybindField
---@field overlay PrettyUI.KeybindField
local PanelKeybindFieldProxy = {}

---@class PrettyUI.PanelListProxy: PrettyUI.List
---@field dock PrettyUI.List
---@field overlay PrettyUI.List
local PanelListProxy = {}

---@class PrettyUI.PanelRadioButtonProxy: PrettyUI.RadioButton
---@field dock PrettyUI.RadioButton
---@field overlay PrettyUI.RadioButton
local PanelRadioButtonProxy = {}

---@class PrettyUI.PanelRibbonButtonProxy: PrettyUI.RibbonButton
---@field dock PrettyUI.RibbonButton
---@field overlay PrettyUI.RibbonButton
local PanelRibbonButtonProxy = {}

---@class PrettyUI.PanelSimpleButtonProxy: PrettyUI.SimpleButton
---@field dock PrettyUI.SimpleButton
---@field overlay PrettyUI.SimpleButton
local PanelSimpleButtonProxy = {}

---@class PrettyUI.PanelSliderProxy: PrettyUI.Slider
---@field dock PrettyUI.Slider
---@field overlay PrettyUI.Slider
local PanelSliderProxy = {}

---@class PrettyUI.PanelSpinnerProxy: PrettyUI.Spinner
---@field dock PrettyUI.Spinner
---@field overlay PrettyUI.Spinner
local PanelSpinnerProxy = {}

---@class PrettyUI.PanelSpriteButtonProxy: PrettyUI.SpriteButton
---@field dock PrettyUI.SpriteButton
---@field overlay PrettyUI.SpriteButton
local PanelSpriteButtonProxy = {}

---@class PrettyUI.PanelSpriteProxy: PrettyUI.Sprite
---@field dock PrettyUI.Sprite
---@field overlay PrettyUI.Sprite
local PanelSpriteProxy = {}

---@class PrettyUI.PanelTabPageProxy: PrettyUI.TabPage
---@field dock PrettyUI.TabPage
---@field overlay PrettyUI.TabPage
local PanelTabPageProxy = {}

---@class PrettyUI.PanelTabsProxy: PrettyUI.Tabs
---@field dock PrettyUI.Tabs
---@field overlay PrettyUI.Tabs
local PanelTabsProxy = {}
---Source: src/tabs.lua:454
---@param index integer
---@return PrettyUI.PanelTabPageProxy|nil
function PanelTabsProxy:GetPage(index) end

---@class PrettyUI.PanelTextFieldProxy: PrettyUI.TextField
---@field dock PrettyUI.TextField
---@field overlay PrettyUI.TextField
local PanelTextFieldProxy = {}

---@class PrettyUI.PanelTimeGraphProxy: PrettyUI.TimeGraph
---@field dock PrettyUI.TimeGraph
---@field overlay PrettyUI.TimeGraph
local PanelTimeGraphProxy = {}

---Options for RadioButton. Source: src/selection_button.lua
---@class PrettyUI.RadioButtonOptions
---@field absolute? any
---@field colour? number
---@field columnGap? any
---@field crossCursor? any
---@field disabled? boolean
---@field disabledColour? number
---@field height? any
---@field inline? boolean
---@field marginBottom? any
---@field marginTop? any
---@field offsetY? any
---@field onChange? fun(group: PrettyUI.RadioButton, value: any)
---@field rowBackground? any
---@field rowBackgroundGroup? any
---@field selectedValue? any
---@field selectedValues? any
---@field shadowed? any
---@field size? any
---@field tickCursor? any
---@field tooltip? string|PrettyUI.TooltipOptions
---@field width? any
---@field widthAnchor? any
---@field x? any
---@field xAnchor? any
---@field y? any
---@field yAnchor? any

---Source: src/selection_button.lua
---@class PrettyUI.RadioButton: PrettyUI.SelectionButton
prettyui.RadioButton = {}
---Source: src/selection_button.lua:312
---@return any
function prettyui.RadioButton:Destroy() end
---Source: src/selection_button.lua:242
---@return any
function prettyui.RadioButton:GetSelectedValue() end
---Source: src/selection_button.lua:263
---@return any
function prettyui.RadioButton:GetSelectedValues() end
---Source: src/selection_button.lua:269
---@param value any
---@return any
function prettyui.RadioButton:IsSelected(value) end
---Source: src/selection_button.lua:292
---@param disabled any
---@return any
function prettyui.RadioButton:SetDisabled(disabled) end
---Source: src/selection_button.lua:302
---@param value any
---@param tooltip any
---@return any
function prettyui.RadioButton:SetOptionTooltip(value, tooltip) end
---Source: src/selection_button.lua:274
---@param value any
---@param selected any
---@param notify any
---@return any
function prettyui.RadioButton:SetSelected(value, selected, notify) end
---Source: src/selection_button.lua:246
---@param value any?
---@param notify boolean?
---@return boolean
function prettyui.RadioButton:SetSelectedValue(value, notify) end
---Source: src/selection_button.lua:298
---@param value any
---@return any
function prettyui.RadioButton:SetTooltip(value) end
---Source: src/selection_button.lua:334
---@param parent any
---@param choices (any|PrettyUI.Choice)[]
---@param options PrettyUI.RadioButtonOptions?
---@return PrettyUI.RadioButton
function prettyui.RadioButton.new(parent, choices, options) end

---Options for RibbonBar. Source: src/ribbon_bar.lua
---@class PrettyUI.RibbonBarOptions
---@field active? boolean
---@field disabled? boolean
---@field icon? number
---@field id? string
---@field identifier? string
---@field label? string
---@field object? any
---@field onClick? fun(handle: PrettyUI.RibbonHandle, active: boolean)
---@field tooltip? string|PrettyUI.TooltipOptions

---Source: src/ribbon_bar.lua
---@class PrettyUI.RibbonBar
prettyui.RibbonBar = {}
---Source: src/ribbon_bar.lua:423
---@return boolean
function prettyui.RibbonBar.GetAutoHide() end
---Source: src/ribbon_bar.lua:411
---@return string
function prettyui.RibbonBar.GetPosition() end
---Source: src/ribbon_bar.lua:355
---@param options PrettyUI.RibbonBarOptions
---@return PrettyUI.RibbonHandle
function prettyui.RibbonBar.Register(options) end
---Source: src/ribbon_bar.lua:415
---@param value boolean
---@return any
function prettyui.RibbonBar.SetAutoHide(value) end
---Source: src/ribbon_bar.lua:402
---@param value string
---@return any
function prettyui.RibbonBar.SetPosition(value) end
---Source: src/ribbon_bar.lua:385
---@param identifier string
---@return boolean
function prettyui.RibbonBar.Unregister(identifier) end

---Options for RibbonButton. Source: src/ribbon_button.lua
---@class PrettyUI.RibbonButtonOptions
---@field absolute? any
---@field active? boolean
---@field columnGap? any
---@field disabled? boolean
---@field height? any
---@field inline? boolean
---@field marginBottom? number
---@field marginTop? number
---@field offsetY? any
---@field rowBackground? any
---@field rowBackgroundGroup? any
---@field size? any
---@field tooltip? string|PrettyUI.TooltipOptions
---@field width? any
---@field widthAnchor? any
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/ribbon_button.lua
---@class PrettyUI.RibbonButton
prettyui.RibbonButton = {}
---Source: src/ribbon_button.lua:100
---@return any
function prettyui.RibbonButton:Destroy() end
---Source: src/ribbon_button.lua:91
---@param active boolean
---@return any
function prettyui.RibbonButton:SetActive(active) end
---Source: src/ribbon_button.lua:85
---@param spriteID number
---@return any
function prettyui.RibbonButton:SetIcon(spriteID) end
---Source: src/ribbon_button.lua:96
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function prettyui.RibbonButton:SetTooltip(value) end
---Source: src/ribbon_button.lua:12
---@param parent any
---@param spriteID number
---@param action fun(button: PrettyUI.RibbonButton)?
---@param options PrettyUI.RibbonButtonOptions?
---@return PrettyUI.RibbonButton
function prettyui.RibbonButton.new(parent, spriteID, action, options) end

---@class PrettyUI.RibbonHandle
---@field id string
local RibbonHandle = {}
---@return boolean
function RibbonHandle:Destroy() end
---@param active boolean
---@return boolean
function RibbonHandle:SetActive(active) end
---@param icon number
---@return boolean
function RibbonHandle:SetIcon(icon) end
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function RibbonHandle:SetTooltip(value) end

---Options for Scrollbar. Source: src/scrollbar.lua
---@class PrettyUI.ScrollbarOptions
---@field contentHeight? number
---@field height? number
---@field scrollStep? number
---@field scrollable? boolean
---@field width? number
---@field x? number
---@field y? number

---Source: src/scrollbar.lua
---@class PrettyUI.Scrollbar: PrettyUI.SimpleView
prettyui.Scrollbar = {}
---Source: src/scrollbar.lua:20
---@param parent any
---@param options PrettyUI.ScrollbarOptions?
---@return PrettyUI.Scrollbar
function prettyui.Scrollbar.new(parent, options) end

---@class PrettyUI.SelectionButton
local SelectionButton = {}
---@return any
function SelectionButton:Destroy() end
---@return any
function SelectionButton:GetSelectedValue() end
---@return any[]
function SelectionButton:GetSelectedValues() end
---@param value any
---@return boolean
function SelectionButton:IsSelected(value) end
---@param disabled boolean
---@return any
function SelectionButton:SetDisabled(disabled) end
---@param value any
---@param tooltip string|PrettyUI.TooltipOptions|nil
---@return any
function SelectionButton:SetOptionTooltip(value, tooltip) end
---@param value any
---@param selected boolean
---@param notify boolean?
---@return boolean
function SelectionButton:SetSelected(value, selected, notify) end
---@param value any?
---@param notify boolean?
---@return boolean
function SelectionButton:SetSelectedValue(value, notify) end
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function SelectionButton:SetTooltip(value) end

---Options for SimpleButton. Source: src/simple_button.lua
---@class PrettyUI.SimpleButtonOptions
---@field absolute? boolean
---@field active? boolean
---@field colour? number
---@field columnGap? number
---@field disabled? boolean
---@field disabledColour? number
---@field height? number
---@field hoverCursor? any
---@field iconHeight? number
---@field iconSize? number
---@field iconWidth? number
---@field inline? boolean
---@field marginBottom? number
---@field marginTop? number
---@field offsetY? number
---@field rowBackground? boolean
---@field rowBackgroundGroup? any
---@field shadowed? boolean
---@field size? number
---@field toggleable? boolean
---@field tooltip? string|PrettyUI.TooltipOptions
---@field width? number
---@field widthAnchor? any
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/simple_button.lua
---@class PrettyUI.SimpleButton
prettyui.SimpleButton = {}
---Source: src/simple_button.lua:208
---@return any
function prettyui.SimpleButton:Destroy() end
---Source: src/simple_button.lua:194
---@param active boolean
---@return any
function prettyui.SimpleButton:SetActive(active) end
---Source: src/simple_button.lua:187
---@param disabled boolean
---@return any
function prettyui.SimpleButton:SetDisabled(disabled) end
---Source: src/simple_button.lua:199
---@param cursor any
---@return any
function prettyui.SimpleButton:SetHoverCursor(cursor) end
---Source: src/simple_button.lua:204
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function prettyui.SimpleButton:SetTooltip(value) end
---Source: src/simple_button.lua:60
---@param parent any
---@param content string|number
---@param action fun(button: PrettyUI.SimpleButton, active: boolean)?
---@param options PrettyUI.SimpleButtonOptions?
---@return PrettyUI.SimpleButton
function prettyui.SimpleButton.new(parent, content, action, options) end

---Options for SimpleView. Source: src/simple_view.lua
---@class PrettyUI.SimpleViewOptions
---@field contentHeight? number
---@field height? number
---@field heightAnchor? number
---@field layout? PrettyUI.LayoutOptions
---@field scrollStep? number
---@field scrollable? boolean
---@field textLayout? PrettyUI.LayoutOptions
---@field tooltip? string|PrettyUI.TooltipOptions
---@field width? number
---@field widthAnchor? number
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/simple_view.lua
---@class PrettyUI.SimpleView : PrettyUI.View
---@field content any
---@field contentHeight number
---@field contentWidth number
---@field root any
---@field scrollY number
---@field scrollbarVisible boolean
---@field viewport any
prettyui.SimpleView = {}
---Source: src/core/content_methods.lua:32
---@param options PrettyUI.BarChartOptions?
---@return PrettyUI.BarChart
function prettyui.SimpleView:AddBarChart(options) end
---Source: src/core/content_methods.lua:30
---@param options PrettyUI.BigSpinnerOptions?
---@return PrettyUI.BigSpinner
function prettyui.SimpleView:AddBigSpinner(options) end
---Source: src/core/content_methods.lua:89
---@param choices (any|PrettyUI.Choice)[]
---@param options PrettyUI.CheckboxButtonOptions?
---@return PrettyUI.CheckboxButton
function prettyui.SimpleView:AddCheckboxButton(choices, options) end
---Source: src/core/content_methods.lua:61
---@param text string
---@param options PrettyUI.CollapseButtonOptions?
---@return PrettyUI.CollapseButton
function prettyui.SimpleView:AddCollapseButton(text, options) end
---Source: src/core/content_methods.lua:98
---@param options PrettyUI.ColourPickerOptions?
---@return PrettyUI.ColourPicker
function prettyui.SimpleView:AddColourPicker(options) end
---Source: src/core/content_methods.lua:114
---@param options PrettyUI.ComboBoxOptions?
---@return PrettyUI.ComboBox
function prettyui.SimpleView:AddComboBox(options) end
---Source: src/core/content_methods.lua:35
---@param options PrettyUI.DividerOptions?
---@return PrettyUI.Divider
function prettyui.SimpleView:AddDivider(options) end
---Source: src/core/content_methods.lua:146
---@param text string
---@param action fun(button: PrettyUI.FancyButton)?
---@param options PrettyUI.FancyButtonOptions?
---@return PrettyUI.FancyButton
function prettyui.SimpleView:AddFancyButton(text, action, options) end
---Source: src/core/content_methods.lua:33
---@param options PrettyUI.HistogramOptions?
---@return PrettyUI.Histogram
function prettyui.SimpleView:AddHistogram(options) end
---Source: src/core/content_methods.lua:45
---@param objects table<integer, any|PrettyUI.ItemGridEntry>
---@param options PrettyUI.ItemGridOptions?
---@return PrettyUI.ItemGrid
function prettyui.SimpleView:AddItemGrid(objects, options) end
---Source: src/core/content_methods.lua:43
---@param object any?
---@param options PrettyUI.ItemSlotOptions?
---@return PrettyUI.ItemSlot
function prettyui.SimpleView:AddItemSlot(object, options) end
---Source: src/core/content_methods.lua:107
---@param options PrettyUI.KeybindFieldOptions?
---@return PrettyUI.KeybindField
function prettyui.SimpleView:AddKeybindField(options) end
---Source: src/core/content_methods.lua:120
---@param options PrettyUI.ListOptions?
---@return PrettyUI.List
function prettyui.SimpleView:AddList(options) end
---Source: src/core/content_methods.lua:69
---@param options PrettyUI.PanelOptions?
---@return PrettyUI.Panel
function prettyui.SimpleView:AddPanel(options) end
---Source: src/core/content_methods.lua:79
---@param choices (any|PrettyUI.Choice)[]
---@param options PrettyUI.RadioButtonOptions?
---@return PrettyUI.RadioButton
function prettyui.SimpleView:AddRadioButton(choices, options) end
---Source: src/core/content_methods.lua:122
---@param spriteID number
---@param action fun(button: PrettyUI.RibbonButton)?
---@param options PrettyUI.RibbonButtonOptions?
---@return PrettyUI.RibbonButton
function prettyui.SimpleView:AddRibbonButton(spriteID, action, options) end
---Source: src/core/content_methods.lua:130
---@param content string|number
---@param action fun(button: PrettyUI.SimpleButton, active: boolean)?
---@param options PrettyUI.SimpleButtonOptions?
---@return PrettyUI.SimpleButton
function prettyui.SimpleView:AddSimpleButton(content, action, options) end
---Source: src/core/content_methods.lua:138
---@param options PrettyUI.SliderOptions?
---@return PrettyUI.Slider
function prettyui.SimpleView:AddSlider(options) end
---Source: src/core/content_methods.lua:29
---@param options PrettyUI.SpinnerOptions?
---@return PrettyUI.Spinner
function prettyui.SimpleView:AddSpinner(options) end
---Source: src/core/content_methods.lua:28
---@param sprite any
---@param options PrettyUI.SpriteOptions?
---@return PrettyUI.Sprite
function prettyui.SimpleView:AddSprite(sprite, options) end
---Source: src/core/content_methods.lua:154
---@param spriteName string
---@param action fun(button: PrettyUI.SpriteButton, enabled: boolean)?
---@param options PrettyUI.SpriteButtonOptions?
---@return PrettyUI.SpriteButton
function prettyui.SimpleView:AddSpriteButton(spriteName, action, options) end
---Source: src/core/content_methods.lua:52
---@param values (string|number|PrettyUI.TabEntry)[]
---@param options PrettyUI.TabsOptions?
---@return PrettyUI.Tabs
function prettyui.SimpleView:AddTabs(values, options) end
---Source: src/core/content_methods.lua:26
---@param value string|PrettyUI.TextOptions
---@return any
function prettyui.SimpleView:AddText(value) end
---Source: src/core/content_methods.lua:100
---@param options PrettyUI.TextFieldOptions?
---@return PrettyUI.TextField
function prettyui.SimpleView:AddTextField(options) end
---Source: src/core/content_methods.lua:31
---@param options PrettyUI.TimeGraphOptions
---@return PrettyUI.TimeGraph
function prettyui.SimpleView:AddTimeGraph(options) end
---Source: src/core/content_methods.lua:27
---@param value any
---@return any
function prettyui.SimpleView:AddTitle(value) end
---Source: src/simple_view.lua:63
---@return any
function prettyui.SimpleView:Destroy() end
---Source: src/core/scroll.lua:369
---@return any
function prettyui.SimpleView:Refresh() end
---Source: src/core/scroll.lua:280
---@param target any
---@return any
function prettyui.SimpleView:RegisterClipTarget(target) end
---Source: src/core/scroll.lua:426
---@param delta number
---@return any
function prettyui.SimpleView:ScrollBy(delta) end
---Source: src/core/scroll.lua:430
---@param child any
---@param topOffset number?
---@return any
function prettyui.SimpleView:ScrollToChild(child, topOffset) end
---Source: src/core/scroll.lua:448
---@param clickthrough any
---@return any
function prettyui.SimpleView:SetClickthrough(clickthrough) end
---Source: src/core/scroll.lua:437
---@param height number
---@return any
function prettyui.SimpleView:SetContentHeight(height) end
---Source: src/core/scroll.lua:373
---@param y number
---@return any
function prettyui.SimpleView:SetScrollPosition(y) end
---Source: src/core/scroll.lua:442
---@param value boolean
---@return any
function prettyui.SimpleView:SetScrollable(value) end
---Source: src/core/scroll.lua:466
---@param width number
---@param height number
---@return any
function prettyui.SimpleView:SetSize(width, height) end
---Source: src/simple_view.lua:59
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function prettyui.SimpleView:SetTooltip(value) end
---Source: src/core/scroll.lua:286
---@param target any
---@return any
function prettyui.SimpleView:UnregisterClipTarget(target) end
---Source: src/simple_view.lua:10
---@param parent any
---@param options PrettyUI.SimpleViewOptions?
---@return PrettyUI.SimpleView
function prettyui.SimpleView.new(parent, options) end

---Options for Slider. Source: src/slider.lua
---@class PrettyUI.SliderOptions
---@field absolute? any
---@field buttonGap? number
---@field columnGap? any
---@field disabled? boolean
---@field height? any
---@field hoverCursor? any
---@field inline? any
---@field marginBottom? any
---@field marginTop? any
---@field max? number
---@field min? number
---@field offsetY? any
---@field onChange? fun(slider: PrettyUI.Slider, value: number)
---@field rowBackground? any
---@field rowBackgroundGroup? any
---@field size? any
---@field step? number
---@field tooltip? string|PrettyUI.TooltipOptions
---@field value? number
---@field width? number
---@field widthAnchor? number
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/slider.lua
---@class PrettyUI.Slider
prettyui.Slider = {}
---Source: src/slider.lua:320
---@return any
function prettyui.Slider:Destroy() end
---Source: src/slider.lua:302
---@return number
function prettyui.Slider:GetValue() end
---Source: src/slider.lua:306
---@param disabled boolean
---@return any
function prettyui.Slider:SetDisabled(disabled) end
---Source: src/slider.lua:316
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function prettyui.Slider:SetTooltip(value) end
---Source: src/slider.lua:288
---@param value number
---@param notify boolean?
---@return any
function prettyui.Slider:SetValue(value, notify) end
---Source: src/slider.lua:51
---@param parent any
---@param options PrettyUI.SliderOptions?
---@return PrettyUI.Slider
function prettyui.Slider.new(parent, options) end

---Options for Spinner. Source: src/spinner.lua
---@class PrettyUI.SpinnerOptions
---@field absolute? boolean
---@field autoPlay? boolean
---@field columnGap? number
---@field degreesPerLogicUpdate? number
---@field height? number
---@field inline? boolean
---@field marginBottom? number
---@field marginTop? number
---@field offsetY? number
---@field rotation? number
---@field rowBackground? any
---@field rowBackgroundGroup? any
---@field size? number
---@field tooltip? string|PrettyUI.TooltipOptions
---@field width? number
---@field widthAnchor? any
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/spinner.lua
---@class PrettyUI.Spinner
prettyui.Spinner = {}
---Source: src/spinner.lua:85
---@return any
function prettyui.Spinner:Destroy() end
---Source: src/spinner.lua:81
---@return any
function prettyui.Spinner:Reset() end
---Source: src/spinner.lua:59
---@param degrees number
---@return any
function prettyui.Spinner:SetDegreesPerLogicUpdate(degrees) end
---Source: src/spinner.lua:54
---@param degrees number
---@return any
function prettyui.Spinner:SetRotation(degrees) end
---Source: src/spinner.lua:63
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function prettyui.Spinner:SetTooltip(value) end
---Source: src/spinner.lua:67
---@return any
function prettyui.Spinner:Start() end
---Source: src/spinner.lua:75
---@return any
function prettyui.Spinner:Stop() end
---Source: src/spinner.lua:16
---@param parent any
---@param options PrettyUI.SpinnerOptions?
---@return PrettyUI.Spinner
function prettyui.Spinner.new(parent, options) end

---Options for Sprite. Source: src/sprite.lua
---@class PrettyUI.SpriteOptions
---@field absolute? boolean
---@field alpha? number
---@field color? number
---@field colour? number
---@field columnGap? number
---@field height? number
---@field heightAnchor? number
---@field inline? boolean
---@field marginBottom? number
---@field marginTop? number
---@field offsetY? number
---@field rowBackground? boolean
---@field rowBackgroundGroup? any
---@field size? number
---@field tooltip? string|PrettyUI.TooltipOptions
---@field width? number
---@field widthAnchor? number
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/sprite.lua
---@class PrettyUI.Sprite
prettyui.Sprite = {}
---Source: src/sprite.lua:46
---@return any
function prettyui.Sprite:Destroy() end
---Source: src/sprite.lua:38
---@param sprite any
---@return any
function prettyui.Sprite:SetSprite(sprite) end
---Source: src/sprite.lua:42
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function prettyui.Sprite:SetTooltip(value) end
---@param options PrettyUI.SpriteOptions?
---@return number
---@return number
function prettyui.Sprite.getSize(options) end
---Source: src/sprite.lua:15
---@param parent any
---@param sprite any
---@param options PrettyUI.SpriteOptions?
---@return PrettyUI.Sprite
function prettyui.Sprite.new(parent, sprite, options) end

---Options for SpriteButton. Source: src/sprite_button.lua
---@class PrettyUI.SpriteButtonOptions
---@field absolute? boolean
---@field columnGap? number
---@field disabled? boolean
---@field height? number
---@field hoverCursor? any
---@field inline? boolean
---@field marginBottom? number
---@field marginTop? number
---@field offsetY? number
---@field rowBackground? any
---@field rowBackgroundGroup? any
---@field size? number
---@field toggleable? boolean
---@field tooltip? string|PrettyUI.TooltipOptions
---@field width? number
---@field widthAnchor? any
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/sprite_button.lua
---@class PrettyUI.SpriteButton
prettyui.SpriteButton = {}
---Source: src/sprite_button.lua:122
---@return any
function prettyui.SpriteButton:Destroy() end
---Source: src/sprite_button.lua:99
---@param disabled boolean
---@return any
function prettyui.SpriteButton:SetDisabled(disabled) end
---Source: src/sprite_button.lua:112
---@param cursor any
---@return any
function prettyui.SpriteButton:SetHoverCursor(cursor) end
---Source: src/sprite_button.lua:106
---@param spriteName string
---@return any
function prettyui.SpriteButton:SetSprite(spriteName) end
---Source: src/sprite_button.lua:118
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function prettyui.SpriteButton:SetTooltip(value) end
---Source: src/sprite_button.lua:24
---@param parent any
---@param spriteName string
---@param action fun(button: PrettyUI.SpriteButton, enabled: boolean)?
---@param options PrettyUI.SpriteButtonOptions?
---@return PrettyUI.SpriteButton
function prettyui.SpriteButton.new(parent, spriteName, action, options) end

---Source: src/core/sprites.lua
---@class PrettyUI.Sprites
---@field ANCHORED_TOOLTIP table
---@field BIG_SPINNER_BACKDROP number
---@field BIG_SPINNER_ROTATING number
---@field BORDER_BOTTOM number
---@field BORDER_CORNER number
---@field BORDER_LEFT number
---@field CHECKBOX_BUTTON table
---@field CLOSE number
---@field CLOSE_ACTIVE number
---@field COLLAPSE_BUTTON table
---@field CONTENT_FRAME table
---@field DIVIDER number
---@field FANCY_BUTTON table
---@field FEEDBACK_FINAL_FRAME table
---@field FEEDBACK_POSITION_FRAME table
---@field HUD_WINDOW table
---@field ICON_TAB table
---@field ITEM_GRID_BACKGROUND number
---@field ITEM_GRID_DROP_TARGET number
---@field ITEM_SLOT_BACKGROUND number
---@field MINIMENU table
---@field OVERHEAD_BARS table
---@field PANEL_DOCK_BUTTON table
---@field PANEL_POPOUT_BUTTON table
---@field RADIO_BUTTON table
---@field RIBBON_BUTTON_ACTIVE number
---@field RIBBON_BUTTON_DISABLED number
---@field RIBBON_BUTTON_HOVERED number
---@field RIBBON_BUTTON_NEUTRAL number
---@field SCROLL_ARROW_DOWN number
---@field SCROLL_ARROW_UP number
---@field SCROLL_THUMB_BOTTOM number
---@field SCROLL_THUMB_CENTRE number
---@field SCROLL_THUMB_TOP number
---@field SCROLL_TRACK_BOTTOM number
---@field SCROLL_TRACK_CENTRE number
---@field SCROLL_TRACK_TOP number
---@field SIMPLE_BUTTON table
---@field SLIDER table
---@field SPRITE_BUTTONS table
---@field SPRITE_BUTTON_NAMES table
---@field TEXT_TAB table
---@field TITLEBAR_CENTRE number
---@field TITLEBAR_CENTRE_LEFT number
---@field TITLEBAR_CENTRE_RIGHT number
---@field TITLEBAR_LEFT number
---@field TITLEBAR_RIGHT number
---@field WINDOW_BACKGROUND number
prettyui.Sprites = {}

---@class PrettyUI.TabEntry
---@field contentHeight number?
---@field disabled boolean?
---@field icon number?
---@field iconSize number?
---@field kind 'text'|'icon'?
---@field label string?
---@field rowBackgroundColors number[]?
---@field rowBackgroundColours number[]?
---@field rowBackgroundEdgeToEdge boolean?
---@field scrollable boolean?
---@field spriteID number?
---@field text string?
---@field tooltip string|PrettyUI.TooltipOptions|nil
---@field type 'text'|'icon'?
---@field value any?
---@field width number?
local TabEntry = {}

---Source: src/tabs.lua
---@class PrettyUI.TabPage
---@field content any
---@field contentHeight number
---@field contentWidth number
---@field root any
---@field scrollY number
---@field scrollbarVisible boolean
---@field viewport any
local TabPage = {}
---Source: src/core/content_methods.lua:32
---@param options PrettyUI.BarChartOptions?
---@return PrettyUI.BarChart
function TabPage:AddBarChart(options) end
---Source: src/core/content_methods.lua:30
---@param options PrettyUI.BigSpinnerOptions?
---@return PrettyUI.BigSpinner
function TabPage:AddBigSpinner(options) end
---Source: src/core/content_methods.lua:89
---@param choices (any|PrettyUI.Choice)[]
---@param options PrettyUI.CheckboxButtonOptions?
---@return PrettyUI.CheckboxButton
function TabPage:AddCheckboxButton(choices, options) end
---Source: src/core/content_methods.lua:61
---@param text string
---@param options PrettyUI.CollapseButtonOptions?
---@return PrettyUI.CollapseButton
function TabPage:AddCollapseButton(text, options) end
---Source: src/core/content_methods.lua:98
---@param options PrettyUI.ColourPickerOptions?
---@return PrettyUI.ColourPicker
function TabPage:AddColourPicker(options) end
---Source: src/core/content_methods.lua:114
---@param options PrettyUI.ComboBoxOptions?
---@return PrettyUI.ComboBox
function TabPage:AddComboBox(options) end
---Source: src/core/content_methods.lua:35
---@param options PrettyUI.DividerOptions?
---@return PrettyUI.Divider
function TabPage:AddDivider(options) end
---Source: src/core/content_methods.lua:146
---@param text string
---@param action fun(button: PrettyUI.FancyButton)?
---@param options PrettyUI.FancyButtonOptions?
---@return PrettyUI.FancyButton
function TabPage:AddFancyButton(text, action, options) end
---Source: src/core/content_methods.lua:33
---@param options PrettyUI.HistogramOptions?
---@return PrettyUI.Histogram
function TabPage:AddHistogram(options) end
---Source: src/core/content_methods.lua:45
---@param objects table<integer, any|PrettyUI.ItemGridEntry>
---@param options PrettyUI.ItemGridOptions?
---@return PrettyUI.ItemGrid
function TabPage:AddItemGrid(objects, options) end
---Source: src/core/content_methods.lua:43
---@param object any?
---@param options PrettyUI.ItemSlotOptions?
---@return PrettyUI.ItemSlot
function TabPage:AddItemSlot(object, options) end
---Source: src/core/content_methods.lua:107
---@param options PrettyUI.KeybindFieldOptions?
---@return PrettyUI.KeybindField
function TabPage:AddKeybindField(options) end
---Source: src/core/content_methods.lua:120
---@param options PrettyUI.ListOptions?
---@return PrettyUI.List
function TabPage:AddList(options) end
---Source: src/core/content_methods.lua:69
---@param options PrettyUI.PanelOptions?
---@return PrettyUI.Panel
function TabPage:AddPanel(options) end
---Source: src/core/content_methods.lua:79
---@param choices (any|PrettyUI.Choice)[]
---@param options PrettyUI.RadioButtonOptions?
---@return PrettyUI.RadioButton
function TabPage:AddRadioButton(choices, options) end
---Source: src/core/content_methods.lua:122
---@param spriteID number
---@param action fun(button: PrettyUI.RibbonButton)?
---@param options PrettyUI.RibbonButtonOptions?
---@return PrettyUI.RibbonButton
function TabPage:AddRibbonButton(spriteID, action, options) end
---Source: src/core/content_methods.lua:130
---@param content string|number
---@param action fun(button: PrettyUI.SimpleButton, active: boolean)?
---@param options PrettyUI.SimpleButtonOptions?
---@return PrettyUI.SimpleButton
function TabPage:AddSimpleButton(content, action, options) end
---Source: src/core/content_methods.lua:138
---@param options PrettyUI.SliderOptions?
---@return PrettyUI.Slider
function TabPage:AddSlider(options) end
---Source: src/core/content_methods.lua:29
---@param options PrettyUI.SpinnerOptions?
---@return PrettyUI.Spinner
function TabPage:AddSpinner(options) end
---Source: src/core/content_methods.lua:28
---@param sprite any
---@param options PrettyUI.SpriteOptions?
---@return PrettyUI.Sprite
function TabPage:AddSprite(sprite, options) end
---Source: src/core/content_methods.lua:154
---@param spriteName string
---@param action fun(button: PrettyUI.SpriteButton, enabled: boolean)?
---@param options PrettyUI.SpriteButtonOptions?
---@return PrettyUI.SpriteButton
function TabPage:AddSpriteButton(spriteName, action, options) end
---Source: src/core/content_methods.lua:52
---@param values (string|number|PrettyUI.TabEntry)[]
---@param options PrettyUI.TabsOptions?
---@return PrettyUI.Tabs
function TabPage:AddTabs(values, options) end
---Source: src/core/content_methods.lua:26
---@param value string|PrettyUI.TextOptions
---@return any
function TabPage:AddText(value) end
---Source: src/core/content_methods.lua:100
---@param options PrettyUI.TextFieldOptions?
---@return PrettyUI.TextField
function TabPage:AddTextField(options) end
---Source: src/core/content_methods.lua:31
---@param options PrettyUI.TimeGraphOptions
---@return PrettyUI.TimeGraph
function TabPage:AddTimeGraph(options) end
---Source: src/core/content_methods.lua:27
---@param value any
---@return any
function TabPage:AddTitle(value) end
---Source: src/tabs.lua:493
---@return any
function TabPage:RefreshRowBackgrounds() end
---Source: src/core/scroll.lua:426
---@param delta number
---@return any
function TabPage:ScrollBy(delta) end
---Source: src/core/scroll.lua:430
---@param child any
---@param topOffset number?
---@return any
function TabPage:ScrollToChild(child, topOffset) end
---Source: src/core/scroll.lua:437
---@param height number
---@return any
function TabPage:SetContentHeight(height) end
---Source: src/core/scroll.lua:373
---@param y number
---@return any
function TabPage:SetScrollPosition(y) end
---Source: src/core/scroll.lua:442
---@param value boolean
---@return any
function TabPage:SetScrollable(value) end

---Options for Tabs. Source: src/tabs.lua
---@class PrettyUI.TabsOptions
---@field absolute? any
---@field activeIndex? integer
---@field columnGap? any
---@field contentHeight? number
---@field contentLayout? PrettyUI.LayoutOptions
---@field height? number
---@field heightAnchor? number
---@field iconSize? number
---@field inline? any
---@field marginBottom? any
---@field marginTop? any
---@field offsetY? any
---@field onChange? fun(group: PrettyUI.Tabs, index: integer, value: any, page: PrettyUI.TabPage)
---@field rowBackground? any
---@field rowBackgroundColors? number[]
---@field rowBackgroundColours? number[]
---@field rowBackgroundEdgeToEdge? boolean
---@field rowBackgroundGroup? any
---@field scrollStep? number
---@field scrollable? boolean
---@field size? any
---@field tabGap? number
---@field tabInset? number
---@field tooltip? string|PrettyUI.TooltipOptions
---@field width? number
---@field widthAnchor? number
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/tabs.lua
---@class PrettyUI.Tabs
prettyui.Tabs = {}
---Source: src/tabs.lua:408
---@param owner any
---@return any
function prettyui.Tabs:BindFlow(owner) end
---Source: src/tabs.lua:503
---@return any
function prettyui.Tabs:Destroy() end
---Source: src/tabs.lua:446
---@return integer|nil
function prettyui.Tabs:GetActiveIndex() end
---Source: src/tabs.lua:454
---@param index integer
---@return PrettyUI.TabPage|nil
function prettyui.Tabs:GetPage(index) end
---Source: src/tabs.lua:450
---@param index integer
---@return PrettyUI.TabEntry|nil
function prettyui.Tabs:GetTab(index) end
---Source: src/tabs.lua:427
---@param index integer
---@param notify boolean?
---@return boolean
function prettyui.Tabs:SetActive(index, notify) end
---Source: src/tabs.lua:469
---@param index integer
---@param disabled boolean
---@return any
function prettyui.Tabs:SetDisabled(index, disabled) end
---Source: src/tabs.lua:488
---@param value boolean
---@return any
function prettyui.Tabs:SetScrollable(value) end
---Source: src/tabs.lua:462
---@param index integer
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function prettyui.Tabs:SetTabTooltip(index, value) end
---Source: src/tabs.lua:458
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function prettyui.Tabs:SetTooltip(value) end
---Source: src/tabs.lua:340
---@param parent any
---@param values (string|number|PrettyUI.TabEntry)[]
---@param options PrettyUI.TabsOptions?
---@return PrettyUI.Tabs
function prettyui.Tabs.new(parent, values, options) end

---Options for Text. Source: src/text.lua
---@class PrettyUI.TextOptions
---@field absolute? boolean
---@field alignHorizontal? any
---@field alignVertical? any
---@field colour? number
---@field columnGap? number
---@field font? number
---@field height? number
---@field heightAnchor? number
---@field inline? boolean
---@field lineSpacing? number
---@field marginBottom? number
---@field marginTop? number
---@field maxLines? integer
---@field offsetY? number
---@field rowBackground? boolean
---@field rowBackgroundGroup? any
---@field shadowed? boolean
---@field size? any
---@field text? string
---@field tooltip? string|PrettyUI.TooltipOptions
---@field width? number
---@field widthAnchor? number
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/text.lua
---@class PrettyUI.Text
prettyui.Text = {}
---Source: src/text.lua:76
---@param owner any
---@param value any
---@param isTitle any
---@return any
function prettyui.Text.append(owner, value, isTitle) end
---Source: src/text.lua:115
---@param parent any
---@param options PrettyUI.TextOptions?
---@return any
function prettyui.Text.new(parent, options) end
---Source: src/text.lua:119
---@param parent any
---@param options PrettyUI.TextOptions?
---@return any
function prettyui.Text.title(parent, options) end

---Options for TextField. Source: src/text_field.lua
---@class PrettyUI.TextFieldOptions
---@field absolute? any
---@field caretColor? number
---@field caretColour? number
---@field color? number
---@field colour? number
---@field columnGap? any
---@field content? string
---@field contentMargin? any
---@field disabled? boolean
---@field emptyText? string
---@field filter? any
---@field filterMode? any
---@field font? number
---@field height? number
---@field heightAnchor? number
---@field inline? any
---@field inputMode? any
---@field inputSprite? any
---@field marginBottom? any
---@field marginTop? any
---@field maxLength? integer
---@field offsetY? any
---@field onChange? fun(field: PrettyUI.TextField, reason: any, content: string)
---@field onSubmit? fun(field: PrettyUI.TextField, content: string)
---@field placeholder? string
---@field placeholderColor? number
---@field placeholderColour? number
---@field rowBackground? any
---@field rowBackgroundGroup? any
---@field selectionColor? number
---@field selectionColour? number
---@field shadowed? boolean
---@field size? any
---@field stylesheetID? number
---@field text? string
---@field tooltip? string|PrettyUI.TooltipOptions
---@field visibility? any
---@field width? number
---@field widthAnchor? number
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/text_field.lua
---@class PrettyUI.TextField
prettyui.TextField = {}
---Source: src/text_field.lua:148
---@return any
function prettyui.TextField:Destroy() end
---Source: src/text_field.lua:86
---@return string
function prettyui.TextField:GetText() end
---Source: src/text_field.lua:105
---@param disabled boolean
---@return any
function prettyui.TextField:SetDisabled(disabled) end
---Source: src/text_field.lua:101
---@param value string
---@return any
function prettyui.TextField:SetPlaceholder(value) end
---Source: src/text_field.lua:90
---@param value string
---@param notify boolean?
---@return any
function prettyui.TextField:SetText(value, notify) end
---Source: src/text_field.lua:144
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function prettyui.TextField:SetTooltip(value) end
---Source: src/text_field.lua:25
---@param parent any
---@param options PrettyUI.TextFieldOptions?
---@return PrettyUI.TextField
function prettyui.TextField.new(parent, options) end

---@class PrettyUI.TimeBucket
---@field complete boolean
---@field endSeconds number
---@field startSeconds number
---@field value number
local TimeBucket = {}

---@class PrettyUI.TimeEventBus
---@field Update PrettyUI.TimeUpdateEvent
local TimeEventBus = {}

---Options for TimeGraph. Source: src/time_graph.lua
---@class PrettyUI.TimeGraphOptions
---@field absolute? any
---@field bus? PrettyUI.TimeEventBus
---@field capacity? integer
---@field columnGap? any
---@field height? number
---@field heightAnchor? number
---@field inline? any
---@field interval? number
---@field marginBottom? any
---@field marginTop? any
---@field metric? PrettyUI.TimeMetric
---@field offsetY? any
---@field onZoom? fun(graph: PrettyUI.TimeGraph, zoom: number)
---@field rowBackground? any
---@field rowBackgroundGroup? any
---@field size? any
---@field visible? boolean
---@field width? number
---@field widthAnchor? number
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number
---@field zoom? number
---@field zoomable? boolean

---Source: src/time_graph.lua
---@class PrettyUI.TimeGraph
---@field bus PrettyUI.TimeEventBus
---@field root any
prettyui.TimeGraph = {}
---Source: src/time_graph.lua:8
---@return PrettyUI.TimeEventBus
function prettyui.TimeGraph.CreateEventBus() end
---Source: src/time_graph.lua:448
---@return any
function prettyui.TimeGraph:Destroy() end
---Source: src/time_graph.lua:415
---@return PrettyUI.TimeSnapshot
function prettyui.TimeGraph:GetSnapshot() end
---Source: src/time_graph.lua:402
---@return number
function prettyui.TimeGraph:GetZoom() end
---Source: src/time_graph.lua:419
---@return boolean
function prettyui.TimeGraph:Reset() end
---Source: src/time_graph.lua:439
---@param width number
---@param height number
---@return boolean
function prettyui.TimeGraph:SetSize(width, height) end
---Source: src/time_graph.lua:428
---@param visible boolean
---@return boolean
function prettyui.TimeGraph:SetVisible(visible) end
---Source: src/time_graph.lua:390
---@param zoom number
---@param notify boolean?
---@return boolean
function prettyui.TimeGraph:SetZoom(zoom, notify) end
---Source: src/time_graph.lua:406
---@return boolean
function prettyui.TimeGraph:ZoomIn() end
---Source: src/time_graph.lua:410
---@return boolean
function prettyui.TimeGraph:ZoomOut() end
---Source: src/time_graph.lua:97
---@param parent any
---@param options PrettyUI.TimeGraphOptions
---@return PrettyUI.TimeGraph
function prettyui.TimeGraph.new(parent, options) end

---@class PrettyUI.TimeMetric
---@field id string
---@field label string?
---@field rgba number?
---@field spriteID number?
local TimeMetric = {}

---@class PrettyUI.TimeSnapshot
---@field buckets PrettyUI.TimeBucket[]
---@field capacity integer
---@field elapsedSeconds number
---@field interval number
---@field metric string
---@field total number
local TimeSnapshot = {}

---@class PrettyUI.TimeUpdate
---@field metric string
---@field value number
local TimeUpdate = {}

---@class PrettyUI.TimeUpdateEvent
---@field Publish fun(payload: PrettyUI.TimeUpdate): boolean, string?
---@field Subscribe fun(callback: fun(payload: PrettyUI.TimeUpdate)): boolean, string?
---@field Unsubscribe fun(callback: fun(payload: PrettyUI.TimeUpdate)): boolean
local TimeUpdateEvent = {}

---Source: src/tooltip.lua
---@class PrettyUI.Tooltip
prettyui.Tooltip = {}
---Source: src/tooltip.lua:394
---@return any
function prettyui.Tooltip:Destroy() end
---Source: src/tooltip.lua:385
---@return any
function prettyui.Tooltip:Hide() end
---Source: src/tooltip.lua:370
---@param text string
---@return boolean
function prettyui.Tooltip:SetText(text) end
---Source: src/tooltip.lua:324
---@return any
function prettyui.Tooltip:Show() end
---Source: src/tooltip.lua:268
---@param target any
---@param parent any
---@param value string|PrettyUI.TooltipOptions|nil
---@return PrettyUI.Tooltip|nil
function prettyui.Tooltip.attach(target, parent, value) end
---Source: src/tooltip.lua:140
---@param owner any
---@param target any
---@param parent any
---@param value any
---@param field any
---@return any
function prettyui.Tooltip.bind(owner, target, parent, value, field) end
---Source: src/tooltip.lua:74
---@param collection any
---@return any
function prettyui.Tooltip.getContext(collection) end
---Source: src/tooltip.lua:136
---@param collection any
---@return any
function prettyui.Tooltip.hideContextTooltips(collection) end
---Source: src/tooltip.lua:126
---@param collection any
---@return any
function prettyui.Tooltip.moveContextTooltipsToFront(collection) end
---Source: src/tooltip.lua:78
---@param collection any
---@param parent any
---@param position any
---@param parentContext any
---@return any
function prettyui.Tooltip.registerContext(collection, parent, position, parentContext) end
---Source: src/tooltip.lua:155
---@param owner any
---@param value any
---@param field any
---@return any
function prettyui.Tooltip.set(owner, value, field) end
---Source: src/tooltip.lua:172
---@param owner any
---@param field any
---@return any
function prettyui.Tooltip.unbind(owner, field) end
---Source: src/tooltip.lua:108
---@param collection any
---@return any
function prettyui.Tooltip.unregisterContext(collection) end

---Options for TooltipOptions. Source: editor/api.json
---@class PrettyUI.TooltipOptions
---@field boundsMargin? number?
---@field constrainToParent? boolean?
---@field height? number?
---@field maxWidth? number?
---@field parent? any?
---@field placement? 'left'|'right'|'above'|'below'?
---@field text? string?
---@field width? number?
---@field x? number?
---@field y? number?

---Options for Window. Source: src/window.lua
---@class PrettyUI.WindowOptions
---@field contentHeight? number
---@field destroyOnClose? boolean
---@field height? number
---@field layout? PrettyUI.LayoutOptions
---@field maxHeight? number
---@field maxWidth? number
---@field minHeight? number
---@field minWidth? number
---@field onClose? fun(window: PrettyUI.Window)
---@field onPositionChange? any
---@field resizable? boolean
---@field rowBackgroundColors? number[]
---@field rowBackgroundColours? number[]
---@field rowBackgroundEdgeToEdge? boolean
---@field scrollStep? number
---@field scrollable? boolean
---@field textLayout? PrettyUI.LayoutOptions
---@field title? string
---@field tooltip? any
---@field width? number
---@field x? number
---@field xAnchor? number
---@field y? number
---@field yAnchor? number

---Source: src/window.lua
---@class PrettyUI.Window : PrettyUI.View
---@field content any
---@field contentHeight number
---@field contentWidth number
---@field root any
---@field scrollY number
---@field scrollbarVisible boolean
---@field viewport any
prettyui.Window = {}
---Source: src/core/content_methods.lua:32
---@param options PrettyUI.BarChartOptions?
---@return PrettyUI.BarChart
function prettyui.Window:AddBarChart(options) end
---Source: src/core/content_methods.lua:30
---@param options PrettyUI.BigSpinnerOptions?
---@return PrettyUI.BigSpinner
function prettyui.Window:AddBigSpinner(options) end
---Source: src/core/content_methods.lua:89
---@param choices (any|PrettyUI.Choice)[]
---@param options PrettyUI.CheckboxButtonOptions?
---@return PrettyUI.CheckboxButton
function prettyui.Window:AddCheckboxButton(choices, options) end
---Source: src/core/content_methods.lua:61
---@param text string
---@param options PrettyUI.CollapseButtonOptions?
---@return PrettyUI.CollapseButton
function prettyui.Window:AddCollapseButton(text, options) end
---Source: src/core/content_methods.lua:98
---@param options PrettyUI.ColourPickerOptions?
---@return PrettyUI.ColourPicker
function prettyui.Window:AddColourPicker(options) end
---Source: src/core/content_methods.lua:114
---@param options PrettyUI.ComboBoxOptions?
---@return PrettyUI.ComboBox
function prettyui.Window:AddComboBox(options) end
---Source: src/core/content_methods.lua:35
---@param options PrettyUI.DividerOptions?
---@return PrettyUI.Divider
function prettyui.Window:AddDivider(options) end
---Source: src/core/content_methods.lua:146
---@param text string
---@param action fun(button: PrettyUI.FancyButton)?
---@param options PrettyUI.FancyButtonOptions?
---@return PrettyUI.FancyButton
function prettyui.Window:AddFancyButton(text, action, options) end
---Source: src/core/content_methods.lua:33
---@param options PrettyUI.HistogramOptions?
---@return PrettyUI.Histogram
function prettyui.Window:AddHistogram(options) end
---Source: src/core/content_methods.lua:45
---@param objects table<integer, any|PrettyUI.ItemGridEntry>
---@param options PrettyUI.ItemGridOptions?
---@return PrettyUI.ItemGrid
function prettyui.Window:AddItemGrid(objects, options) end
---Source: src/core/content_methods.lua:43
---@param object any?
---@param options PrettyUI.ItemSlotOptions?
---@return PrettyUI.ItemSlot
function prettyui.Window:AddItemSlot(object, options) end
---Source: src/core/content_methods.lua:107
---@param options PrettyUI.KeybindFieldOptions?
---@return PrettyUI.KeybindField
function prettyui.Window:AddKeybindField(options) end
---Source: src/core/content_methods.lua:120
---@param options PrettyUI.ListOptions?
---@return PrettyUI.List
function prettyui.Window:AddList(options) end
---Source: src/core/content_methods.lua:69
---@param options PrettyUI.PanelOptions?
---@return PrettyUI.Panel
function prettyui.Window:AddPanel(options) end
---Source: src/core/content_methods.lua:79
---@param choices (any|PrettyUI.Choice)[]
---@param options PrettyUI.RadioButtonOptions?
---@return PrettyUI.RadioButton
function prettyui.Window:AddRadioButton(choices, options) end
---Source: src/core/content_methods.lua:122
---@param spriteID number
---@param action fun(button: PrettyUI.RibbonButton)?
---@param options PrettyUI.RibbonButtonOptions?
---@return PrettyUI.RibbonButton
function prettyui.Window:AddRibbonButton(spriteID, action, options) end
---Source: src/core/content_methods.lua:130
---@param content string|number
---@param action fun(button: PrettyUI.SimpleButton, active: boolean)?
---@param options PrettyUI.SimpleButtonOptions?
---@return PrettyUI.SimpleButton
function prettyui.Window:AddSimpleButton(content, action, options) end
---Source: src/core/content_methods.lua:138
---@param options PrettyUI.SliderOptions?
---@return PrettyUI.Slider
function prettyui.Window:AddSlider(options) end
---Source: src/core/content_methods.lua:29
---@param options PrettyUI.SpinnerOptions?
---@return PrettyUI.Spinner
function prettyui.Window:AddSpinner(options) end
---Source: src/core/content_methods.lua:28
---@param sprite any
---@param options PrettyUI.SpriteOptions?
---@return PrettyUI.Sprite
function prettyui.Window:AddSprite(sprite, options) end
---Source: src/core/content_methods.lua:154
---@param spriteName string
---@param action fun(button: PrettyUI.SpriteButton, enabled: boolean)?
---@param options PrettyUI.SpriteButtonOptions?
---@return PrettyUI.SpriteButton
function prettyui.Window:AddSpriteButton(spriteName, action, options) end
---Source: src/core/content_methods.lua:52
---@param values (string|number|PrettyUI.TabEntry)[]
---@param options PrettyUI.TabsOptions?
---@return PrettyUI.Tabs
function prettyui.Window:AddTabs(values, options) end
---Source: src/core/content_methods.lua:26
---@param value string|PrettyUI.TextOptions
---@return PrettyUI.Text
function prettyui.Window:AddText(value) end
---Source: src/core/content_methods.lua:100
---@param options PrettyUI.TextFieldOptions?
---@return PrettyUI.TextField
function prettyui.Window:AddTextField(options) end
---Source: src/core/content_methods.lua:31
---@param options PrettyUI.TimeGraphOptions
---@return PrettyUI.TimeGraph
function prettyui.Window:AddTimeGraph(options) end
---Source: src/core/content_methods.lua:27
---@param value any
---@return any
function prettyui.Window:AddTitle(value) end
---Source: src/window.lua:415
---@return any
function prettyui.Window:Close() end
---Source: src/window.lua:429
---@return any
function prettyui.Window:Destroy() end
---Source: src/core/scroll.lua:369
---@return any
function prettyui.Window:Refresh() end
---Source: src/window.lua:364
---@return any
function prettyui.Window:RefreshRowBackgrounds() end
---Source: src/core/scroll.lua:280
---@param target any
---@return any
function prettyui.Window:RegisterClipTarget(target) end
---Source: src/core/scroll.lua:426
---@param delta number
---@return any
function prettyui.Window:ScrollBy(delta) end
---Source: src/core/scroll.lua:430
---@param child any
---@param topOffset number?
---@return any
function prettyui.Window:ScrollToChild(child, topOffset) end
---Source: src/core/scroll.lua:448
---@param clickthrough any
---@return any
function prettyui.Window:SetClickthrough(clickthrough) end
---Source: src/core/scroll.lua:437
---@param height number
---@return any
function prettyui.Window:SetContentHeight(height) end
---Source: src/core/scroll.lua:373
---@param y number
---@return any
function prettyui.Window:SetScrollPosition(y) end
---Source: src/core/scroll.lua:442
---@param value boolean
---@return any
function prettyui.Window:SetScrollable(value) end
---Source: src/window.lua:334
---@param width number
---@param height number
---@return any
function prettyui.Window:SetSize(width, height) end
---Source: src/window.lua:355
---@param title string
---@return any
function prettyui.Window:SetTitle(title) end
---Source: src/window.lua:360
---@param value string|PrettyUI.TooltipOptions|nil
---@return boolean
function prettyui.Window:SetTooltip(value) end
---Source: src/window.lua:404
---@return any
function prettyui.Window:Show() end
---Source: src/core/scroll.lua:286
---@param target any
---@return any
function prettyui.Window:UnregisterClipTarget(target) end
---Source: src/window.lua:36
---@param parent any
---@param options PrettyUI.WindowOptions?
---@return PrettyUI.Window
function prettyui.Window.new(parent, options) end
