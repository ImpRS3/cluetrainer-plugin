---@alias prettymap.TooltipBuilder fun(layer: ui.Layer, element: prettymap.luaflet.Twig): boolean?

---@class prettymap.TooltipOptions
---@field interactive boolean? The element stays hovered while the cursor is in the tooltip. Default false.

--- Content of a tooltip. Subclass it and override `Build`, or use `Tooltip.fromBuilder`.
---@class prettymap.Tooltip
---@field interactive boolean
local Tooltip = {}
Tooltip.__index = Tooltip

---@param options prettymap.TooltipOptions?
---@return prettymap.Tooltip
function Tooltip.new(options)
    return setmetatable({ interactive = options ~= nil and options.interactive == true }, Tooltip)
end

--- Creates a tooltip whose content is produced by `builder`.
---@param builder prettymap.TooltipBuilder
---@param options prettymap.TooltipOptions?
---@return prettymap.Tooltip
function Tooltip.of(builder, options)
    local tooltip = Tooltip.new(options)
    tooltip.Build = function(_, layer, element) return builder(layer, element) end
    return tooltip
end

--- Abstract. Fills `layer` with the tooltip content, sizes it with `layer:SetSize` and returns true.
--- Returning a falsy value shows no tooltip. Called on every show; the layer is destroyed on hide.
---@param layer ui.Layer
---@param element prettymap.luaflet.Twig
---@return boolean?
function Tooltip:Build(layer, element)
    error("Tooltip:Build is abstract; override it or use Tooltip.of", 2)
end

return Tooltip
