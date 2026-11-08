-- TowerSolver.lua
local Towers            = require "cluetrainer/puzzles/towers/Towers"
local zyklib            = require "zyklib"
local util              = require "cluetrainer/util"
local schema            = require "cluetrainer/util/schema"
local storage           = require "cluetrainer/util/storage"

---@class ct.towers.TowerSolver
local towers_solver     = {}

towers_solver.settings  = {
  enabled = ctGlobal.persistence:profileVariable("towers/enabled", schema.bool({ default = true })),
  info = ctGlobal.persistence:profileVariable("towers/info",
    schema.choices({ choices = { "delta", "target", "both" }, default = "both" })),
  highlight_completed_tiles = ctGlobal.persistence:profileVariable("towers/highlight_completed_tiles", schema.bool({ default = true })),
}

local TILE_OFFSET       = 44

local TR_OVERLAY_OFFSET = { x = 16, y = -10 }
local TL_OVERLAY_OFFSET = { x = -5, y = -10 }

---Draws the current state of the towers puzzle.
---@param canvas ui.Canvas
---@param is_state ct.towers.Blocks
---@param should_state ct.towers.Blocks
local function draw(canvas, is_state, should_state)

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

---The 20 edge hints, or nil while any of them is not a height from 1 to 5. The game opens the window a few server
---ticks before it sends the hints, so they read as 0 at first.
---@return ct.towers.Hints?
local function readValidHints()
  local hints = getPuzzleHints()
  for _, side in pairs(hints) do
    for _, hint in ipairs(side) do
      if type(hint) ~= "number" or hint < 1 or hint > 5 then return nil end
    end
  end
  return hints
end

---@param a ct.towers.Hints
---@param b ct.towers.Hints
---@return boolean
local function sameHints(a, b)
  for _, side in ipairs({ "top", "bottom", "left", "right" }) do
    for i = 1, 5 do
      if a[side][i] ~= b[side][i] then return false end
    end
  end
  return true
end

---@class ct.towers.ActiveTowersPuzzle: zyklib.disposable.IDisposable
---@field canvas ui.Canvas
---@field solution ct.towers.PuzzleState
---@field disposable_group zyklib.disposable.DisposableGroup
local ActivePuzzle = {}
ActivePuzzle.__index = ActivePuzzle

---@param hints ct.towers.Hints Valid hints, from `readValidHints`
---@return ct.towers.ActiveTowersPuzzle? # `nil` if the puzzle has no solution for the hints, or the overlay failed
function ActivePuzzle.new(hints)
  local solution = Towers.solve(hints)

  if not solution then return nil end

  local self = setmetatable({ solution = solution }, ActivePuzzle)

  self.disposable_group = zyklib.disposable.DisposableGroup.new()

  -- Everything is added to the group as soon as it exists, so a failure halfway removes what was built so far
  -- instead of leaving listeners and the canvas behind, and the error stays out of the server tick event.
  local ok, err = pcall(ActivePuzzle.build, self)
  if not ok then
    self.disposable_group:dispose()
    log("Towers overlay failed: " .. tostring(err))
    return nil
  end

  return self
end

---@private
function ActivePuzzle:build()
  -- Create the canvas for the solution overlay
  local content = ui.Interfaces:GetComponent(id.Component.TRAIL17_SKYSCRAPERS__SKYSCRAPERS_PLAYING_BOARD) --[[@as ui.ComponentCollection]]
  self.canvas = ui.Canvas.new(content)
  self.disposable_group:add(zyklib.disposable.wrap(function() self.canvas:Destroy() end))
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

  local function draw()
    self.canvas:Clear()
    local is_state = state:get()
    local should_state = self.solution.blocks

    for x = 1, 5, 1 do
      for y = 1, 5, 1 do
        local correct = should_state and should_state.rows[y][x] == is_state.rows[y][x]

        if correct then
          if towers_solver.settings.highlight_completed_tiles:get() then
            self.canvas:AddRectangle(
              TILE_OFFSET * (x - 1) + 1,
              TILE_OFFSET * (y - 1) + 1,
              TILE_OFFSET - 2,
              TILE_OFFSET - 2,
              0x00FF0080)
          end
        else
          local delta = (6 + should_state.rows[y][x] - is_state.rows[y][x]) % 6

          if towers_solver.settings.info:get() == "delta" or towers_solver.settings.info:get() == "both" then
            self.canvas:AddText(
              TR_OVERLAY_OFFSET.x + TILE_OFFSET * (x - 1) + 10,
              TR_OVERLAY_OFFSET.y + TILE_OFFSET * (y - 1) + 10,
              "+" .. tostring(delta),
              id.Font.NOTOSANS_12,
              0xFFFFFFFF)
          end

          if towers_solver.settings.info:get() == "target" or towers_solver.settings.info:get() == "both" then
            self.canvas:AddText(
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

  local group = self.disposable_group
  group:add(towers_solver.settings.info:observable():subscribe(draw))
  group:add(towers_solver.settings.highlight_completed_tiles:observable():subscribe(draw))
  group:add(zyklib.lifecycle.shutdown_event:subscribe(function() group:dispose() end))
  group:add(state:subscribe(function(puzzle_state) client_side_history:push(puzzle_state) end, true))
  group:add(zyklib.game_events.native.MiniMenuEntrySelected:subscribe(function(payload)
      if payload.entry.componentData ~= nil and payload.entry.componentData.component ~= nil then
        if payload.entry.componentData.component.parent == click_layer then
          local tile = payload.entry.componentData.component.dynamicID

          local row_i = (tile // 5) + 1
          local col_ci = (tile % 5) + 1

          local current_state = zyklib.objects.deepClone(state:get())

          local actions = {
            -- 0 is the game's own value for an empty tile; nil would break the drawing.
            ["Clear"] = function() current_state.rows[row_i][col_ci] = 0 --[[@as ct.towers.Tower]] end,
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
    end))
  group:add(zyklib.game_events.native.ServerLogic:subscribe(refresh))
  group:add(state:subscribe(draw, true))
end

function ActivePuzzle:dispose()
  self.disposable_group:dispose()
  ActivePuzzle.instance = nil
end

---@type ct.towers.ActiveTowersPuzzle?
ActivePuzzle.instance = nil

---@type zyklib.reactive.EventHandler? Reads the hints on every server tick while the window is open
local hint_watch = nil

---@type ct.towers.Hints? The hints of the current overlay or of the last attempt that had no solution
local built_for = nil

local function disposeInstance()
  if ActivePuzzle.instance ~= nil then ActivePuzzle.instance:dispose() end
end

---Builds the overlay once the hints are valid, and again whenever they change, so a window that opens before the
---hints arrive, or still holds the previous puzzle's hints, gets the right overlay a few ticks later.
local function buildWhenHintsReady()
  local hints = readValidHints()
  if hints == nil or (built_for ~= nil and sameHints(hints, built_for)) then return end

  built_for = hints
  disposeInstance()
  ActivePuzzle.instance = ActivePuzzle.new(hints)
end

local function stopWatching()
  if hint_watch ~= nil then hint_watch:cancel() end
  hint_watch, built_for = nil, nil
  disposeInstance()
end

local interface_open_handler = zyklib.game_events.native.ServerLogic:map(function()
      local interface = ui.Interfaces:GetInterface(id.Interface.TRAIL17_SKYSCRAPERS)
      local comp = ui.Interfaces:GetComponent(id.Component.TRAIL17_SKYSCRAPERS__SKYSCRAPERS_CONTENT)

      return interface ~= nil and comp ~= nil and comp.parent ~= nil
    end)
    :toObservable(false)
    :subscribeSuspended(function(is_open)
      stopWatching()

      if is_open then
        hint_watch = zyklib.game_events.native.ServerLogic:subscribe(buildWhenHintsReady)
        buildWhenHintsReady()
      end
    end)

---Enables or disables the towers solver. Disabling also removes any currently shown overlay.
---@param active boolean
local function setActive(active)
  interface_open_handler:setActive(active)

  if not active then stopWatching() end
end

local initialized = false

--- Activates the solver whenever it is enabled in the settings and deactivates it otherwise. Only the first call has an effect.
function towers_solver.init()
  if initialized then return end
  initialized = true

  towers_solver.settings.enabled:observable():subscribe(setActive, true)
end

return towers_solver
