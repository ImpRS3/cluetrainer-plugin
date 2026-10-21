-- TowerSolver.lua
local Towers              = require "cluetrainer/puzzles/towers/Towers"
local zyklib              = require "zyklib"

---@class ct.towers.TowerSolver
local towers_solver       = {}

local TILE_OFFSET         = 44
local TL_OFFSET_IN_CANVAS = {
  x = 40,
  y = 37,
}

local TR_OVERLAY_OFFSET   = { x = 16, y = -10 }
local TL_OVERLAY_OFFSET   = { x = -5, y = -10 }

---Draws the current state of the towers puzzle.
---@param canvas ui.Canvas
---@param is_state ct.towers.Blocks
---@param should_state ct.towers.Blocks
---@param settings { show_deltas: boolean, show_should: boolean }
local function draw(canvas, is_state, should_state, settings)
  canvas:Clear()

  for x = 1, 5, 1 do
    for y = 1, 5, 1 do
      local correct = should_state and should_state.rows[y][x] == is_state.rows[y][x]

      if correct then
        canvas:AddRectangle(
          TL_OFFSET_IN_CANVAS.x + TILE_OFFSET * (x - 1) + 1,
          TL_OFFSET_IN_CANVAS.y + TILE_OFFSET * (y - 1) + 1,
          TILE_OFFSET - 2,
          TILE_OFFSET - 2,
          0x00FF0080)
      else
        local delta = (6 + should_state.rows[y][x] - is_state.rows[y][x]) % 6

        if settings.show_deltas then
          canvas:AddText(
            TL_OFFSET_IN_CANVAS.x + TR_OVERLAY_OFFSET.x + TILE_OFFSET * (x - 1) + 10,
            TL_OFFSET_IN_CANVAS.y + TR_OVERLAY_OFFSET.y + TILE_OFFSET * (y - 1) + 10,
            "+" .. tostring(delta),
            id.Font.NOTOSANS_12,
            0xFFFFFFFF)
        end

        if settings.show_should then
          canvas:AddText(
            TL_OFFSET_IN_CANVAS.x + TL_OVERLAY_OFFSET.x + TILE_OFFSET * (x - 1) + 10,
            TL_OFFSET_IN_CANVAS.y + TL_OVERLAY_OFFSET.y + TILE_OFFSET * (y - 1) + 10,
            tostring(should_state.rows[y][x]),
            id.Font.NOTOSANS_12,
            0xFFFFFFFF
          )
        end
      end
    end
  end
end

--- Gets the hints of the current puzzle
---@return ct.towers.Hints
local function getPuzzleHints()
  return {
    top = {
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_0_TOP_PLAYER.value,
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_1_TOP_PLAYER.value,
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_2_TOP_PLAYER.value,
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_3_TOP_PLAYER.value,
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_4_TOP_PLAYER.value,
    },
    bottom = {
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_0_BOTTOM_PLAYER.value,
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_1_BOTTOM_PLAYER.value,
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_2_BOTTOM_PLAYER.value,
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_3_BOTTOM_PLAYER.value,
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_4_BOTTOM_PLAYER.value,
    },
    left = {
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_0_LEFT_PLAYER.value,
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_1_LEFT_PLAYER.value,
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_2_LEFT_PLAYER.value,
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_3_LEFT_PLAYER.value,
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_4_LEFT_PLAYER.value,
    },
    right = {
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_0_RIGHT_PLAYER.value,
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_1_RIGHT_PLAYER.value,
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_2_RIGHT_PLAYER.value,
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_3_RIGHT_PLAYER.value,
      var.VarPlayer.TRAIL17_SKYSCRAPERS_HINT_SLOT_4_RIGHT_PLAYER.value,
    },
  }
end

---@return ct.towers.Blocks
local function getPuzzleState()
  local current_state = Towers.Blocks.empty()

  for x = 1, 5, 1 do
    for y = 1, 5, 1 do
      current_state.rows[y][x] =
          var.VarPlayer["TRAIL17_SKYSCRAPERS_SLOT_" .. (x - 1) .. "_" .. (y - 1)]
          .value
    end
  end

  return current_state
end

---@class ct.towers.ActiveTowersPuzzle: zyklib.disposable.IDisposable
---@field canvas ui.Canvas
---@field solution ct.towers.PuzzleState
---@field disposable_group zyklib.disposable.DisposableGroup
local ActivePuzzle = {}
ActivePuzzle.__index = ActivePuzzle

---@return ct.towers.ActiveTowersPuzzle? # `nil` if the puzzle has no solution for the current hints
function ActivePuzzle.new()
  local solution = Towers.solve(getPuzzleHints())

  if not solution then return nil end

  local self = setmetatable({ solution = solution }, ActivePuzzle)

  self.disposable_group = zyklib.disposable.DisposableGroup.new()

  -- Create the canvas for the solution overlay
  local content = ui.Interfaces:GetComponent(id.Component.TRAIL17_SKYSCRAPERS__SKYSCRAPERS_CONTENT) --[[@as ui.ComponentCollection]]
  self.canvas = ui.Canvas.new(content)
  self.canvas:SetSize(content.width, content.height)

  ---@type zyklib.reactive.Observable<ct.towers.Blocks>
  local state = zyklib.reactive.Observable.new(getPuzzleState())

  local function refresh()
    state:set(getPuzzleState())
  end

  self.disposable_group:add(
  -- TODO: Replace these with a client-side trigger once the client-side puzzle state can be read
    zyklib.game_events.native.MiniMenuEntrySelected:subscribe(refresh),
    zyklib.game_events.native.ServerLogic:subscribe(refresh),

    state:subscribe(function(current_state)
      draw(self.canvas, current_state, self.solution.blocks, { show_deltas = true, show_should = true })
    end, true)
  )

  return self
end

function ActivePuzzle:dispose()
  self.disposable_group:dispose()
  self.canvas:Clear()
  ActivePuzzle.instance = nil
end

---@type ct.towers.ActiveTowersPuzzle?
ActivePuzzle.instance = nil

local interface_open_handler = zyklib.game_events.native.ServerLogic:map(function()
      local interface = ui.Interfaces:GetInterface(id.Interface.TRAIL17_SKYSCRAPERS)
      local comp = ui.Interfaces:GetComponent(id.Component.TRAIL17_SKYSCRAPERS__SKYSCRAPERS_CONTENT)

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

---Enables or disables the towers solver. Disabling also removes any currently shown overlay.
---@param active boolean
function towers_solver.setActive(active)
  interface_open_handler:setActive(active)

  if not active and ActivePuzzle.instance ~= nil then
    ActivePuzzle.instance:dispose()
  end
end

return towers_solver
