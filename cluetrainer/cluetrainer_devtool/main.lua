local DevtoolWindow = require("cluetrainer_devtool/DevtoolWindow")
---@type PrettyUI.Window?
local window

local function closeWindow()
  if window then
    local closing = window
    window = nil
    closing:Destroy()
  end
end

---@class ct.devtools.main
local main = {
  init = function()
    zyklib.game_events.native.KeyDown:subscribe(function(payload)
      if payload.modifiers & ModifierKey.ALT ~= 0 and payload.gameKey == GameKey.F6 then
        if window then return end

        local opened

        opened = DevtoolWindow.open(function()
          if window == opened then window = nil end
        end)

        window = opened
      end
    end)

    zyklib.lifecycle.shutdown_event:subscribe(closeWindow)
  end
}

return main
