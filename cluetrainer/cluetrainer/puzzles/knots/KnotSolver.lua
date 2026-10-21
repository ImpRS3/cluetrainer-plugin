-- KnotSolver.lua
local zyklib     = require "zyklib"

---@class cluetrainer.puzzles.knots.KnotSolver
local KnotSolver = {}

local function getSolution()
  --- Getting the solution is trivial since the variables directly represent the shuffle state.
  return {
    var.VarPlayer["TRAIL_SHUFFLE0"].value,
    var.VarPlayer["TRAIL_SHUFFLE1"].value,
    var.VarPlayer["TRAIL_SHUFFLE2"].value,
    var.VarPlayer["TRAIL_SHUFFLE3"].value,
  }
end
---@class ActiveKnotPuzzle: zyklib.disposable.IDisposable
---@field knot_type integer
---@field canvas ui.Canvas
---@field disposable_group zyklib.disposable.DisposableGroup
---@field solution zyklib.reactive.Observable<integer[]>
local ActivePuzzle = {}
ActivePuzzle.__index = ActivePuzzle

---comment
---@param knot_type integer
---@return ActiveKnotPuzzle
function ActivePuzzle.new(knot_type)
  local self = setmetatable({}, ActivePuzzle)

  self.disposable_group = zyklib.disposable.DisposableGroup.new()
  self.solution = zyklib.reactive.Observable.new(nil)
  self.knot_type = knot_type

  -- Create the canvas for the solution overlay
  local interface = ui.Interfaces:GetComponent(id.Component["TRAIL_KNOT_0" .. knot_type .. "__MAINMODAL_WINDOW_CONTENT"]) --[[@as ui.ComponentCollection]]
  self.canvas = ui.Canvas.new(interface)
  self.canvas:SetSize(interface.width, interface.height)

  self.disposable_group:add(
    zyklib.game_events.native.ServerLogic:subscribe(function()
      self.solution:set(getSolution())
    end),

    zyklib.game_events.native.MiniMenuEntrySelected:subscribe(function(event)
      -- TODO: Implement our own client side prediction, at least for the rendered solution
    end),

    self.solution:subscribe(function(change)
      self:draw(change.new)
    end)
  )

  -- Set initial solution for rendering
  self.solution:set(getSolution())

  return self
end

function ActivePuzzle.draw(self, solution)
  self.canvas:Clear()

  if zyklib.array.forAll(solution, function(value) return value == 0 end) then
    -- Is Solved
    local unlock_button = ui.Interfaces:GetComponent(id.Component["TRAIL_KNOT_0" .. self.knot_type .. "__UNLOCK_BUTTON"]) --[[@as ui.Sprite]]

    zyklib.api_util.draw_text_with_shadow(self.canvas, self.canvas.width / 2, self.canvas.height / 2, "Solved!",
      id.Font.NOTOSANS_28, 0x00FF00FF)
    self.canvas:AddRectangle(unlock_button.x, unlock_button.y, unlock_button.width, unlock_button.height, 0x00FF0080)
  else
    -- Not solved

    for i = 1, #solution do
      local track_id = i - 1
      local offset = solution[i]

      if offset ~= 0 then
        local comp_name = "TRAIL_KNOT_0" .. self.knot_type .. "__TRACK_" .. track_id .. (offset < 0 and "_CCW" or "_CW")
        local comp = ui.Interfaces:GetComponent(id.Component[comp_name]) --[[@as ui.Sprite]]

        if comp ~= nil then
          zyklib.api_util.draw_text_with_shadow(self.canvas, comp.x, comp.y, tostring(math.abs(offset)),
            id.Font.NOTOSANS_28)
        end
      end
    end
  end
end

function ActivePuzzle:dispose()
  self.disposable_group:dispose()
  ActivePuzzle.instance = nil
end

---@type ActiveKnotPuzzle?
ActivePuzzle.instance = nil

local open_track_type_observable = zyklib.game_events.native.ServerLogic:map(function()
      local v = zyklib.array.find({ 0, 1, 2, 3, 4, 5, 6, 7, 8 }, function(i)
        return ui.Interfaces:GetInterface(id.Interface["TRAIL_KNOT_0" .. i]) ~= nil
      end)

      return v
    end)
    :toObservable(nil)
    :subscribeSuspended(function(value)
      if ActivePuzzle.instance ~= nil then
        ActivePuzzle.instance:dispose()
      end

      -- Handle the suspended subscription here if needed
      if value.new ~= nil then
        ActivePuzzle.instance = ActivePuzzle.new(value.new)
      end
    end)

function KnotSolver.setActive(active)
  open_track_type_observable:setActive(active)

  if not active then
    if ActivePuzzle.instance ~= nil then
      ActivePuzzle.instance:dispose()
    end
  end
end

return KnotSolver
