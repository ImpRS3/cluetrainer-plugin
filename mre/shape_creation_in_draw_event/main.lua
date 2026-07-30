---@type ShapeData?
local shape = nil

Event.Draw.Subscribe("draw_handler", function(event)
    if not shape then
        shape = ShapeData.new() -- When this line exists, the plugin will crash the client.

        shape.positions = { Vector3.new(-250, 0, -250), Vector3.new(250, 0, -250), Vector3.new(250, 0, 250), Vector3.new(
            -250, 0, 250) }

        shape.rgba = { {} }
    end
end)