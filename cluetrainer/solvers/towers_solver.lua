local abstraction   = require "abstraction"
local util          = require "util"
local towers_solver = {}

local BOARD         = id.Component.TRAIL17_SKYSCRAPERS__SKYSCRAPERS_PLAYING_BOARD

function towers_solver:init()
  abstraction.subscribe(Event.ServerLogic, function(event)
    local interface = ui.Interfaces:GetInterface(id.Interface.TRAIL17_SKYSCRAPERS)

    if not interface then return end

    local click = ui.Interfaces:GetComponent(id.Component.TRAIL17_SKYSCRAPERS__SKYSCRAPERS_CONTENT)

    if click ~= nil then
      log(click.type)

      click.colour = Vector4.new(1, 0, 0, 1)
      click.alpha = 1
      local label = ui.Text.new(click)

      label:AlignTo(ui.AlignMode.CENTRE)
      label:SetSize(100, 50)
      label.content = "Hello World"
      label.colour = Vector4.new(1.0, 0.0, 1.0, 1.0)
    end
  end)

  abstraction.subscribe(Event.MiniMenuEntrySelected, function(event)
    log(util.to_plain_table(event.entry))
  end)
end

return towers_solver
