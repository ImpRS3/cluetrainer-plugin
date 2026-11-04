-- prettyui_workarounds.lua
-- Workarounds for PrettyUI 1.3.0-beta (mod.io 6398181). They use private PrettyUI fields, so an update may break them.
-- Remove each one once PrettyUI has the fix described with it.
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

--- Hides the panel, docked or popped out. `panel:SetPoppedOut(panel.poppedOut, false)` shows it again.
---@param panel PrettyUI.Panel
function prettyui_workarounds.hide(panel)
  panel.dock.root.hidden = true
  panel.overlay.root.hidden = true
end

return prettyui_workarounds
