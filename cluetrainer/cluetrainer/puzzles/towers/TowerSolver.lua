-- TowerSolver.lua
local Towers            = require "cluetrainer/puzzles/towers/Towers"
local zyklib            = require "zyklib"
local util              = require "cluetrainer/util"

---@class ct.towers.TowerSolver
local towers_solver     = {}

local TILE_OFFSET       = 44

local TR_OVERLAY_OFFSET = { x = 16, y = -10 }
local TL_OVERLAY_OFFSET = { x = -5, y = -10 }

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
          TILE_OFFSET * (x - 1) + 1,
          TILE_OFFSET * (y - 1) + 1,
          TILE_OFFSET - 2,
          TILE_OFFSET - 2,
          0x00FF0080)
      else
        local delta = (6 + should_state.rows[y][x] - is_state.rows[y][x]) % 6

        if settings.show_deltas then
          canvas:AddText(
            TR_OVERLAY_OFFSET.x + TILE_OFFSET * (x - 1) + 10,
            TR_OVERLAY_OFFSET.y + TILE_OFFSET * (y - 1) + 10,
            "+" .. tostring(delta),
            id.Font.NOTOSANS_12,
            0xFFFFFFFF)
        end

        if settings.show_should then
          canvas:AddText(
            TL_OVERLAY_OFFSET.x + TILE_OFFSET * (x - 1) + 10,
            TL_OVERLAY_OFFSET.y + TILE_OFFSET * (y - 1) + 10,
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
  local content = ui.Interfaces:GetComponent(id.Component.TRAIL17_SKYSCRAPERS__SKYSCRAPERS_PLAYING_BOARD) --[[@as ui.ComponentCollection]]
  self.canvas = ui.Canvas.new(content)
  self.canvas:SetSize(content.width, content.height)

  local click_layer = ui.Interfaces:GetComponent(id.Component.TRAIL17_SKYSCRAPERS__CLICK) --[[@as ui.ComponentCollection]]


  -- local root = ui.Interfaces:GetComponent(id.Component.TRAIL17_SKYSCRAPERS__SKYSCRAPERS_CONTENT) --[[@as ui.ComponentCollection]]
  -- local description = ui.Interfaces:GetComponent(id.Component.TRAIL17_SKYSCRAPERS__DESCRIPTION) --[[@as ui.Text]]

  -- -- Rewrite the description to make some space in the UI
  -- description.content =
  -- "Place a tower of height 1 to 5 in each square so no row or column repeats a height. The edge clues show how many towers are visible from that position; taller towers hide smaller ones behind them."

  -- description:SetPos(340, description.y)
  -- description:SetSize(140, description.height)

  -- local component_1 = prettyui.SimpleView.new(root, { width = root.width, height = root.height, x = 0 })
  -- component_1:AddRadioButton(
  --   { { text = "Default", value = nil }, { text = "1", value = 1 }, { text = "2", value = 2 }, { text = "3", value = 3 }, { text = "4", value = 4 }, { text = "5", value = 5 } },
  --   {
  --     inline = false,
  --     selectedValue = nil,
  --     onChange = function(change)

  --     end
  --   })
  -- self.disposable_group:add(zyklib.disposable.wrap(function() component_1:Destroy() end))


  ---@type zyklib.reactive.Observable<ct.towers.Blocks>
  local state = zyklib.reactive.Observable.new(getPuzzleState())

  local CLIENT_SIDE_HISTORY_CAPACITY = 20

  ---@type cluetrainer.util.RingBuffer<ct.towers.Blocks>
  local client_side_history = util.RingBuffer.new(CLIENT_SIDE_HISTORY_CAPACITY)

  -- Only override the tracked state with the state read from the game if we haven't seen it recently.
  local function refresh()
    local current = getPuzzleState()

    if not zyklib.array.exists(client_side_history, function(history) return zyklib.objects.deepEquals(history, current) end) then
      state:set(current)
    end
  end

  self.disposable_group:add(
    zyklib.lifecycle.shutdown_event:subscribe(function() self.disposable_group:dispose() end),
    state:subscribe(function(puzzle_state) client_side_history:push(puzzle_state) end, true),
    zyklib.game_events.native.MiniMenuEntrySelected:subscribe(function(payload)
      if payload.entry.componentData ~= nil and payload.entry.componentData.component ~= nil then
        if payload.entry.componentData.component.parent == click_layer then
          local tile = payload.entry.componentData.component.dynamicID

          local row_i = (tile // 5) + 1
          local col_ci = (tile % 5) + 1

          local current_state = zyklib.objects.deepClone(state:get())

          local actions = {
            ["Clear"] = function() current_state.rows[row_i][col_ci] = nil end,
            ["Increment"] = function()
              current_state.rows[row_i][col_ci] = ((current_state.rows[row_i][col_ci] or 0) + 1) % 6
            end,
            ["1"] = function() current_state.rows[row_i][col_ci] = 1 end,
            ["2"] = function() current_state.rows[row_i][col_ci] = 2 end,
            ["3"] = function() current_state.rows[row_i][col_ci] = 3 end,
            ["4"] = function() current_state.rows[row_i][col_ci] = 4 end,
            ["5"] = function() current_state.rows[row_i][col_ci] = 5 end,
          }

          local action = actions[payload.entry.verbText]
          if action ~= nil then
            action()

            state:set(current_state)
          end
        end
      end
    end),
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
