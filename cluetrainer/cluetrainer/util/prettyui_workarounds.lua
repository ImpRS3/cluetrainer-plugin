-- prettyui_workarounds.lua
-- Workarounds for PrettyUI 1.3.0-beta.3, bundled in cluetrainer/prettyui. They use private PrettyUI fields, so updating
-- the bundled copy may break them. Remove each one once the bundled PrettyUI has the fix described with it.
local prettyui_workarounds = {}

-- 1. Clearing rows from a panel
--
-- Resets the flow layout after rows are destroyed, so new rows start below the header again. PrettyUI only removes Lua
-- components from the layout on `Destroy`, not native ones like the ui.Text from `AddText`.
--
-- Fix in PrettyUI: in `pairObjects` (prettyui/panel.lua), call `Layout.remove` for both surfaces on `Destroy`.
-- Then remove: `rememberFlow`, and `reset_rows` in cluestate.lua.

--- A shallow copy, so the remembered row isn't changed by later rows.
---@param row table?
---@return table?
local function copy(row)
  if row == nil then return nil end
  local result = {}
  for key, value in pairs(row) do result[key] = value end
  return result
end

--- Remembers where the panel's flow layout stands now, on both panel surfaces (docked and popped out).
---@param panel PrettyUI.Panel
---@return fun() reset Puts the layout back to this point, forgetting everything added after it
function prettyui_workarounds.rememberFlow(panel)
  local saved = {}
  for _, owner in ipairs({ panel.dockOwner, panel.overlayOwner }) do
    local layout = owner and owner._flowLayout
    if layout then
      saved[#saved + 1] = {
        owner = owner,
        entries = #owner._managedFlowEntries,
        nextY = layout.nextY,
        hasItems = layout.hasItems,
        row = copy(layout.row),
      }
    end
  end

  return function()
    for _, point in ipairs(saved) do
      local entries = point.owner._managedFlowEntries
      for i = #entries, point.entries + 1, -1 do entries[i] = nil end

      local layout = point.owner._flowLayout
      layout.nextY, layout.hasItems, layout.row = point.nextY, point.hasItems, copy(point.row)
    end
  end
end

-- 2. Hiding a panel
--
-- Hides both the docked and the popped-out surface, as PrettyUI has no call for that.
--
-- Fix in PrettyUI: a `Panel:SetVisible(visible)`.
-- Then remove: `hide`, and call `window:SetVisible(visible)` in cluestate.lua's `setVisible`.

--- Hides the panel, docked or popped out, including its drag layers. `show` makes it visible again.
---@param panel PrettyUI.Panel
function prettyui_workarounds.hide(panel)
  panel.dock.root.hidden = true
  panel.overlay.root.hidden = true
  -- The drag layers are separate components that would otherwise keep catching clicks
  if panel.dockDragLayer then panel.dockDragLayer.hidden = true end
  if panel.overlayDragLayer then panel.overlayDragLayer.hidden = true end
end

--- Shows a panel hidden with `hide`, on the surface it is currently docked or popped out on.
---@param panel PrettyUI.Panel
function prettyui_workarounds.show(panel)
  if panel.dockDragLayer then panel.dockDragLayer.hidden = false end
  if panel.overlayDragLayer then panel.overlayDragLayer.hidden = false end
  panel:SetPoppedOut(panel.poppedOut, false)
end

-- 3. Measuring a panel's content
--
-- `contentHeight` on a panel's content owner is only set after PrettyUI reflows, which does not happen for every added or
-- removed row. The flow layout's own bookkeeping is always current, so the height is read from there.
--
-- Fix in PrettyUI: call `reflow` (prettyui/core/layout.lua) after `Layout.place`, `Layout.remove` and on reset.
-- Then remove: `contentHeight`, and use `panel.dockOwner.contentHeight` in cluestate.lua's `_FitWindow`.

--- The height of everything laid out in the panel so far, including the layout's bottom padding.
---@param panel PrettyUI.Panel
---@return number
function prettyui_workarounds.contentHeight(panel)
  local owner = panel.poppedOut and panel.overlayOwner or panel.dockOwner
  local layout = owner._flowLayout

  local bottom = layout.nextY
  if layout.row ~= nil then bottom = layout.row.y + layout.row.height end

  return bottom + layout.paddingBottom
end

return prettyui_workarounds
