-- LockboxSolver.lua
local Lockboxes         = require "cluetrainer/puzzles/lockbox/Lockboxes"
local zyklib            = require "zyklib"
local schema            = require "cluetrainer/util/schema"
local storage           = require "cluetrainer/util/storage"

---@class ct.lockbox.LockboxSolver
local lockbox_solver    = {}

lockbox_solver.settings = {
  enabled = ctGlobal.persistence:profileVariable("lockboxes/enabled", schema.bool({ default = true })),
  optimization_coefficient = ctGlobal.persistence:profileVariable("lockboxes/optimization_coefficient",
    schema.int({ min = 10, max = 50, default = 13 }), "int"),
}

---@return ct.lockbox.LockboxState
local function getPuzzleState()
  local rows012 = var.VarClient["TRAIL_LIGHTSOUT_CLIENT_1"].value
  local rows34 = var.VarClient["TRAIL_LIGHTSOUT_CLIENT_2"].value

  return {
    tile_rows = zyklib.array.grouped(
      zyklib.array.flatten(
        { zyklib.bits.getAll(2, rows012, 16),
          zyklib.bits.getAll(2, rows34, 9) }
      ), 5)
  }
end

local FONT                = config.Font.NOTOSANS_28

local TILE_OFFSET         = 38
local TL_OFFSET_IN_CANVAS = {
  x = 50,
  y = 17,
}

---Draws the current state of the lockbox puzzle.
---@param canvas Canvas
---@param solution ct.lockbox.LockboxSolution
local function draw(canvas, solution)
  canvas:Clear()

  local width = {
    FONT:GetStringWidth("1"),
    FONT:GetStringWidth("2"),
  }
  for x = 1, 5, 1 do
    for y = 1, 5, 1 do
      local delta = solution[y][x]

      if delta ~= 0 then
        -- Draw text with a shadow to make it more readable
        canvas:AddText(
          TL_OFFSET_IN_CANVAS.x + TILE_OFFSET * (x - 1) + 1,
          TL_OFFSET_IN_CANVAS.y + TILE_OFFSET * (y - 1) + 1,
          tostring(delta),
          FONT.id,
          0x00000080)

        canvas:AddText(
          TL_OFFSET_IN_CANVAS.x + TILE_OFFSET * (x - 1) - 1,
          TL_OFFSET_IN_CANVAS.y + TILE_OFFSET * (y - 1) - 1,
          tostring(delta),
          FONT.id,
          0x00000080)

        canvas:AddText(
          TL_OFFSET_IN_CANVAS.x + TILE_OFFSET * (x - 1) + 1,
          TL_OFFSET_IN_CANVAS.y + TILE_OFFSET * (y - 1) - 1,
          tostring(delta),
          FONT.id,
          0x00000080)

        canvas:AddText(
          TL_OFFSET_IN_CANVAS.x + TILE_OFFSET * (x - 1) - 1,
          TL_OFFSET_IN_CANVAS.y + TILE_OFFSET * (y - 1) + 1,
          tostring(delta),
          FONT.id,
          0x00000080)

        canvas:AddText(
          TL_OFFSET_IN_CANVAS.x + TILE_OFFSET * (x - 1),
          TL_OFFSET_IN_CANVAS.y + TILE_OFFSET * (y - 1),
          tostring(delta),
          FONT.id,
          0xFFFFFFFF)
      end
    end
  end
end

---@class ct.lockbox.ActiveLockboxPuzzle: zyklib.disposable.IDisposable
---@field canvas ui.Canvas
---@field disposable_group zyklib.disposable.DisposableGroup
local ActivePuzzle = {}
ActivePuzzle.__index = ActivePuzzle

---@return ct.lockbox.ActiveLockboxPuzzle
function ActivePuzzle.new()
  local self = setmetatable({}, ActivePuzzle)

  self.disposable_group = zyklib.disposable.DisposableGroup.new()

  -- Create the canvas for the solution overlay
  local content = ui.Interfaces:GetComponent(id.Component.LIGHTSOUT__MAINMODAL_WINDOW_CONTENT) --[[@as ui.ComponentCollection]]
  self.canvas = ui.Canvas.new(content)
  self.canvas:SetSize(content.width, content.height)

  -- The puzzle state lives in VarClient variables, which do not trigger transmit events, so it is polled every frame.
  -- The observable's equality check makes sure the solution is only recomputed and redrawn when the state actually changed.
  local state = zyklib.reactive.Observable.new(getPuzzleState())
  ---@type zyklib.reactive.Observable<ct.lockbox.LockboxSolution?>
  local solution = zyklib.reactive.Observable.new(nil)

  local function refreshSolution()
    local last_solution = solution:get()

    solution:set(Lockboxes.solve(getPuzzleState(), {
      minimize_by = function(sol)
        local difference_penalty = last_solution
            and Lockboxes.MoveMap.difference(sol, last_solution) / 10
            or 0

        -- If there is no existing solution, use the intended scoring function
        return Lockboxes.MoveMap.scoring({ 0, 1, lockbox_solver.settings.optimization_coefficient:get() / 10 })(sol) +
            difference_penalty
      end,
    }))
  end

  state:subscribe(refreshSolution, true)

  self.disposable_group:add(
    lockbox_solver.settings.optimization_coefficient:observable():subscribe(refreshSolution),
    zyklib.game_events.native.Draw:subscribe(function()
      state:set(getPuzzleState())
    end),

    solution:subscribe(function(sol) draw(self.canvas, sol) end, true)
  )

  return self
end

function ActivePuzzle:dispose()
  self.disposable_group:dispose()
  self.canvas:Destroy()
  ActivePuzzle.instance = nil
end

---@type ct.lockbox.ActiveLockboxPuzzle?
ActivePuzzle.instance = nil

local interface_open_handler = zyklib.game_events.native.ServerLogic:map(function()
      local interface = ui.Interfaces:GetInterface(id.Interface.LIGHTSOUT)
      local comp = ui.Interfaces:GetComponent(id.Component.LIGHTSOUT__MAINMODAL_WINDOW_CONTENT)
      return interface ~= nil and comp ~= nil and comp.parent ~= nil
    end)
    :toObservable(false)
    :subscribeSuspended(function(is_open)
      if ActivePuzzle.instance ~= nil then
        ActivePuzzle.instance:dispose()
      end

      if is_open then
        ActivePuzzle.instance = ActivePuzzle.new()
      end
    end)

---Enables or disables the lockbox solver. Disabling also removes any currently shown overlay.
---@param active boolean
local function setActive(active)
  interface_open_handler:setActive(active)

  if not active and ActivePuzzle.instance ~= nil then
    ActivePuzzle.instance:dispose()
  end
end

local initialized = false

--- Activates the solver whenever it is enabled in the settings and deactivates it otherwise. Only the first call has an effect.
function lockbox_solver.init()
  if initialized then return end
  initialized = true

  lockbox_solver.settings.enabled:observable():subscribe(setActive, true)
end

return lockbox_solver
