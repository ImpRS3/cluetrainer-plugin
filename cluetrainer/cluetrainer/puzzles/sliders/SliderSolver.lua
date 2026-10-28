-- SliderSolver.lua
-- This is an AI assited translation of the coroutine based PDBSolver.
-- It's less efficient, but at least is doesn't crash the client
local zyklib          = require("zyklib")
local schema          = require("cluetrainer/util/schema")
local storage         = require("cluetrainer/util/storage")
local SliderState     = require("cluetrainer/puzzles/sliders/SliderState")
local Move            = require("cluetrainer/puzzles/sliders/Move")
local PdbSolverTicked = require("cluetrainer/puzzles/sliders/pdb/PdbSolverTicked")
-- The pattern database solver is disabled for now. To re-enable it, restore these requires, the `graph` below and the PdbSolver call in ActivePuzzle.new.
local RegionGraph     = require("cluetrainer/puzzles/sliders/pdb/RegionGraph")
local util            = require("cluetrainer/util")



---@class ct.sliders.SliderSolver
local slider_solver    = {}

---@class ct.sliders.slider_solver.settings
slider_solver.settings = {
  enabled = storage.variable("sliders/enabled", schema.bool({ default = true })),
  mode = storage.variable("sliders/mode",
    schema.choices({ choices = { "keyboard", "mouse", "hybrid" }, default = "mouse" })),
  prevent_overlap = storage.variable("sliders/prevent_overlap", schema.bool({ default = true })),
  lookahead = storage.variable("sliders/lookahead", schema.int({ min = 2, max = 10, default = 5 })),
  show_recovery_moves = storage.variable("sliders/show_recovery_moves", schema.bool({ default = true })),
  color_mainline = storage.variable("sliders/color_mainline", schema.colour({ default = 0x00FF00FF })),
  color_recovery = storage.variable("sliders/color_recovery", schema.colour({ default = 0xFFA500FF })),
  solve_time = storage.variable("sliders/solve_time", schema.int({ min = 100, max = 5000, default = 200 })),
  estimate_slider_speed = storage.variable("sliders/estimate_slider_speed", schema.bool({ default = true })),
}

---@alias ct.sliders.PdbDownloadState {progress: number, data: zyklib.async.Promise<ct.sliders.pdb.RegionGraph>}


---@return ct.sliders.PdbDownloadState
local function getPDB()
  -- FIXME: Cache disabled due to a bug in PersistentDB regarding embedded nulls
  -- local cached = PersistentDB:Get("workaround_sliderpdb_mtm_huge_v0")

  -- if cached ~= nil and cached.value ~= nil and cached.value ~= "" then
  --   log("Retrieved from cache")
  --   return zyklib.async.Promise.resolved(cached.value)
  -- end

  local download = {
    progress = 0,
    data = zyklib.async.Promise.new()
  }

  local cached = ""
  --- We cannot use an async-await pattern here because it triggers a client crash, so we use recursion with a delayed call instead.
  local function recur(chunks)
    if #chunks == 9 then
      log("All chunks downloaded")
      local final_value = table.concat(chunks)

      -- Cache pdb for next time. FIXME: Disabled for now
      -- PersistentDB:Set("workaround_sliderpdb_mtm_huge_v0", { value = final_value })

      download.data:resolve(RegionGraph.new(RegionGraph.parseTables(final_value), true))
    else
      zyklib.http.get(Plugin.urls["cluetrainer"], "/data/sliderpdb/mtm_huge/v0chunk0" .. #chunks .. ".bin")
          :onCompletion(function(result, data)
            if not result then
              log("Failed to download chunk " .. #chunks)
              download.data:reject("Failed to download chunk " .. #chunks)
              return
            end

            log("Downloaded chunk " .. #chunks)
            table.insert(chunks, data)
            download.progress = #chunks / 9

            --- The following is a bug workaround. Recursing directly triggers a client crash, hence we delay by a tick
            zyklib.game_events.native.Logic:once(function()
              recur(chunks)
            end)
          end)
    end
  end

  recur({})

  return download
end

local pdb = util.lazy(getPDB)

local STROKE = 3
local CONTRAST_BORDER = 2
local COLOR_CONTRAST = 0x000000FF

-- Offset of the canvas content's top-left corner. Applied to everything drawn on the canvases.
-- Lazily determined by the position of the puzzle layer within the UI.
local CANVAS_OFFSET = util.lazy(function()
  -- Create the canvas for the solution overlay
  local layer = ui.Interfaces:GetComponent(id.Component.SLIDE_PUZZLE__PUZZLE_LAYER) --[[@as ui.ComponentCollection]]

  return { x = layer.xyLocal.x, y = layer.xyLocal.y }
end)

-- Canvas-relative positions of the solving overlay (the canvas covers the 5x5 tile area)
local PROGRESS_VERTICAL_OFFSET = -7
-- Center of the first statistics line at the bottom of the canvas. Further lines follow 20px below.
local STATS_POSITION = { x = 137, y = 260 }
local TICK_SECONDS = 0.02

local SMALL_TEXT_CONFIG = ui.TextDataConfig.new()
SMALL_TEXT_CONFIG.alignHorizontal = ui.AlignMode.CENTRE
SMALL_TEXT_CONFIG.alignVertical = ui.AlignMode.CENTRE
SMALL_TEXT_CONFIG.font = id.Font.NOTOSANS_14
SMALL_TEXT_CONFIG.rgba = 0xFFFFFFFF
SMALL_TEXT_CONFIG.shadowRGBA = 0x000000FF
SMALL_TEXT_CONFIG.isShadowed = true

---@alias ct.sliders.ct.sliders.ActiveSliderPuzzle.State
---           | {state: "waitingforpdb", last_drawn_progress: number?, progress: ct.sliders.PdbDownloadState}
---           | {state: "solving", start_tick: number, solver: ct.sliders.pdb.PdbSolverTicked}
---           | {state: "executing", start_tick: number, solution: ct.sliders.AugmentedMove[], mainline_index: integer, finished_tick: integer?, last_drawn_state: ct.sliders.SliderState?}
---           | {state: "failed", reason: string}


---@class ct.sliders.ActiveSliderPuzzle: zyklib.disposable.IDisposable
---@field solution_canvas ui.Canvas
---@field progress_canvas ui.Canvas
---@field solution ct.sliders.AugmentedMove[]
---@field lifetime zyklib.disposable.DisposableGroup
---@field ticks number
---@field state ct.sliders.ct.sliders.ActiveSliderPuzzle.State
local ActivePuzzle = {}
ActivePuzzle.__index = ActivePuzzle

---Draws the slider puzzle overlay.
---@param state ct.sliders.SliderState The current puzzle state
function ActivePuzzle:drawSolution(state)
  assert(self.state.state == "executing")

  local canvas = self.solution_canvas
  canvas:Clear()

  --- Center of a tile index (1-25) in canvas coordinates
  local function centerOfTile(index)
    return ((index - 1) % 5) * 56 + 24 + CANVAS_OFFSET().x, ((index - 1) // 5) * 56 + 24 + CANVAS_OFFSET().y
  end

  local s = self.state
  local solution = s.solution
  local mainline_index = s.mainline_index

  -- The current state is not on the solution path, so there is nothing meaningful to show
  if mainline_index < 0 then return end

  local last_size = 10
  local overlap_map = {}

  for i = 0, slider_solver.settings.lookahead:get() - 1 do
    local move_index = mainline_index + i

    if move_index > #solution then break end

    local entry = solution[move_index]

    local blank = (move_index > 1 and solution[move_index - 1].post or state)[SliderState.BLANK_TILE_INDEX]
    local clicked = blank + entry.move

    -- Stop at the first move that would cover a tile already passed over by an earlier move
    if overlap_map[clicked] then break end

    local passed = blank
    for _, step in ipairs(Move.split(entry.move)) do
      passed = passed + step
      overlap_map[passed] = true
    end

    local size = 20 * (1 - i / slider_solver.settings.lookahead:get())

    local ax, ay = centerOfTile(blank)
    local bx, by = centerOfTile(clicked)

    -- Connecting line from the previous marker to this one
    local dx, dy = bx - ax, by - ay
    local length = math.sqrt(dx * dx + dy * dy)
    local ux, uy = dx / length, dy / length

    local x1, y1 = ax + ux * last_size, ay + uy * last_size
    local x2, y2 = bx - ux * size, by - uy * size

    canvas:AddLine(x1, y1, x2, y2, 2, COLOR_CONTRAST)
    canvas:AddLine(x1, y1, x2, y2, 1, slider_solver.settings.color_mainline:get())

    -- Marker on the clicked tile
    local outer = size + CONTRAST_BORDER
    canvas:AddOutline(bx - outer, by - outer, outer * 2, outer * 2, STROKE + 2 * CONTRAST_BORDER, COLOR_CONTRAST)
    canvas:AddOutline(bx - size, by - size, size * 2, size * 2, STROKE, slider_solver.settings.color_mainline:get())

    last_size = size
  end
end

---Draws a horizontal progress bar with a contrast border.
---@param canvas ui.Canvas
---@param center_x number
---@param center_y number
---@param length number
---@param progress number Fraction between 0 and 1
---@param thickness number?
---@param contrast_border number?
---@param done_color integer?
---@param remaining_color integer?
local function drawProgressBar(canvas, center_x, center_y, length, progress, thickness, contrast_border, done_color,
                               remaining_color)
  thickness = thickness or 5
  contrast_border = contrast_border or 2
  done_color = done_color or 0x00FF00FF
  remaining_color = remaining_color or 0xFF0000FF

  local start_x = center_x - length // 2
  local end_x = start_x + length
  local mid_x = math.floor(start_x + math.max(0, math.min(1, progress)) * length + 0.5)

  canvas:AddLine(start_x - 2 * contrast_border, center_y, end_x + 2 * contrast_border, center_y,
    thickness + 2 * contrast_border, COLOR_CONTRAST)
  canvas:AddLine(start_x, center_y, mid_x, center_y, thickness, done_color)
  canvas:AddLine(mid_x, center_y, end_x, center_y, thickness, remaining_color)
end

---Draws centered text around a point.
---@param canvas ui.Canvas
---@param x number
---@param y number
---@param text string
---@param text_config ui.TextDataConfig
local function drawCenteredText(canvas, x, y, text, text_config)
  local estimated_width = config.Font.FromID(text_config.font):GetStringWidth(text)

  canvas:AddText(x - estimated_width // 2, y - 10, estimated_width, 20, text, text_config)
end


local CENTER_TEXT_CONFIG = ui.TextDataConfig.new()
CENTER_TEXT_CONFIG.alignHorizontal = ui.AlignMode.CENTRE
CENTER_TEXT_CONFIG.alignVertical = ui.AlignMode.CENTRE
CENTER_TEXT_CONFIG.font = id.Font.NOTOSANS_20
CENTER_TEXT_CONFIG.rgba = 0xFFFFFFFF
CENTER_TEXT_CONFIG.shadowRGBA = 0x000000FF
CENTER_TEXT_CONFIG.isShadowed = true

---Stub: draws the pattern database download progress.
---@param progress number Fraction between 0 and 1
function ActivePuzzle:drawDownloadProgress(progress)
  local canvas = self.progress_canvas
  canvas:Clear()

  drawCenteredText(canvas, canvas.width // 2, canvas.height // 2 - 15, "Downloading Data", CENTER_TEXT_CONFIG)

  drawProgressBar(canvas, canvas.width // 2, canvas.height // 2 + 25, 100, progress, 2, 1, 0x00FFFFFF, 0xFFFFFFFF)
end

---Draws the "Solving" text and a progress bar while the solver is searching.
---@param tick integer Ticks spent solving so far
---@param max_ticks integer
function ActivePuzzle:drawSolvingProgress(tick, max_ticks)
  local canvas = self.progress_canvas

  drawCenteredText(canvas, canvas.width // 2, canvas.height // 2 - 15, "Solving", CENTER_TEXT_CONFIG)

  drawProgressBar(canvas, canvas.width // 2, canvas.height // 2 + 25, 100, tick / max_ticks, 2, 1, 0x00FF00FF, 0xFF0000FF)
end

---Draws the progress bar, timers and speed statistics. Works in the "solving" and "executing" states.
---Does not clear the canvas, callers are responsible for that.
function ActivePuzzle:drawProgress()
  local s = self.state
  local canvas = self.progress_canvas

  local solving = s.state == "solving"
  local executing = s.state == "executing"
  if not solving and not executing then return end

  local solution_length = 250
  if executing then
    solution_length = #s.solution
  elseif s.solver.best_solution then
    solution_length = #s.solver.best_solution
  end

  local cx, cy = canvas.width // 2, 9
  local sx, sy = canvas.width // 2, canvas.height - 9

  log(s.mainline_index)

  -- Always Draw progress bar
  local completed = executing and (s.mainline_index - 1) or 0
  local progress = executing and (completed / solution_length) or 0
  local length = math.min(2 * solution_length, 250)
  drawProgressBar(canvas, cx, cy, length, progress, 2, 1)
  drawCenteredText(canvas, cx + length / 2 + 20, cy, tostring(solution_length), SMALL_TEXT_CONFIG)

  -- Always draw elapsed time
  drawCenteredText(canvas, cx - (length / 2 + 25), cy,
    string.format("%.1fs", (s.finished_tick or self.ticks) * TICK_SECONDS),
    SMALL_TEXT_CONFIG)

  -- Draw solution length if available
  if solution_length then
    drawCenteredText(canvas, cx + length / 2 + 20, cy, tostring(solution_length), SMALL_TEXT_CONFIG)
  end

  if s.finished_tick == nil then
    -- Draw current speed in moves/s
    local solving_time = (self.ticks - s.start_tick) * TICK_SECONDS
    local moves_per_second = solving_time > 0 and completed / solving_time or 0

    drawCenteredText(canvas, sx, sy, string.format("%.1f moves/s", moves_per_second), SMALL_TEXT_CONFIG)
  else
    -- Slider is done, draw total solving time and speed
    local total_time = s.finished_tick * TICK_SECONDS
    local solving_time = (s.finished_tick - s.start_tick) * TICK_SECONDS
    local moves_per_second = #s.solution / solving_time

    drawCenteredText(canvas, sx, sy, string.format("Done! %.1fs, %.1f moves/s", total_time, moves_per_second),
      SMALL_TEXT_CONFIG)

    if slider_solver.settings.estimate_slider_speed:get() then
      -- Estimate slider speed is a legacy option that calculates the corresponding slider speed setting in Alt1 Clue Solver
      -- that the user's speed would have achieved.

      local small_steps = 0
      for _, entry in ipairs(s.solution) do
        small_steps = small_steps + #Move.split(entry.move)
      end

      local partial_steps = small_steps - #s.solution
      local full_steps = small_steps - partial_steps
      local counted = partial_steps * 0.5 + full_steps

      local estimated_slider_speed = (solving_time - 0.5) / counted

      drawCenteredText(canvas, sx, sy + 20, string.format("Slider Speed %.3f", estimated_slider_speed), SMALL_TEXT_CONFIG)
    end
  end
end

---Stub: draws the overlay shown when no solution could be produced.
function ActivePuzzle:drawFailed()
  local canvas = self.progress_canvas
  canvas:Clear()

  local x = canvas.width // 2
  local y = canvas.height // 2

  drawCenteredText(canvas, x, y - 25, "Error", CENTER_TEXT_CONFIG)
  drawCenteredText(canvas, x, y + 5, self.state.reason, SMALL_TEXT_CONFIG)
end

---@return ct.sliders.ActiveSliderPuzzle
function ActivePuzzle.new()
  ---@class ct.sliders.ActiveSliderPuzzle
  local self = setmetatable({}, ActivePuzzle)

  self.lifetime = zyklib.disposable.DisposableGroup.new()

  -- Create the canvas for the solution overlay
  local puzzle_container = ui.Interfaces:GetComponent(id.Component.SLIDE_PUZZLE__PUZZLE_WRAPPER) --[[@as ui.ComponentCollection]]

  self.progress_canvas = ui.Canvas.new(puzzle_container)
  self.progress_canvas:SetSize(puzzle_container.width, puzzle_container.height)
  self.solution_canvas = ui.Canvas.new(puzzle_container)
  self.solution_canvas:SetSize(puzzle_container.width, puzzle_container.height)

  self.ticks = 0
  self.state = { state = "waitingforpdb", progress = pdb(), last_drawn_progress = nil }

  self.lifetime:add(zyklib.game_events.native.Logic:subscribe(function() self:logictick() end))

  self:logictick()

  return self
end

function ActivePuzzle:logictick()
  self.ticks = self.ticks + 1

  local s = self.state

  if s.state == "waitingforpdb" then
    local download = s.progress

    if download.data:isSettled() then
      local ok, graph = pcall(download.data.get, download.data)

      if not ok then
        self.state = { state = "failed", reason = "Failed to get PDB data" }
        self:drawFailed()
        return
      end

      local solver = PdbSolverTicked.new(SliderState.getSliderState(), graph)
      solver:start()
      self.solver = solver
      self.state = { state = "solving", start_tick = self.ticks, solver = solver }
      self.progress_canvas:Clear()
    elseif s.last_drawn_progress ~= download.progress then
      s.last_drawn_progress = download.progress
      self:drawDownloadProgress(download.progress)
    end
  end

  -- We may have switched to the "solving" state, which we handle immediately
  if s.state == "solving" then
    local SOLVER_TICK_BUDGET = 256 -- How many states to process per tick

    local done = s.solver:tick(SOLVER_TICK_BUDGET)

    local max_ticks = slider_solver.settings.solve_time:get() / 20

    if self.ticks - s.start_tick >= max_ticks then
      -- Solving time is over, lock in the best solution found so far
      local current = SliderState.getSliderState()
      local best = s.solver.best_solution

      if best == nil then
        self.state = { state = "failed", reason = "No solution found" }
        self:drawFailed()
        return
      end

      s.solver:cancel()

      self.solution = SliderState.augmentMoves(current, best)
      self.state = {
        state = "executing",
        start_tick = self.ticks,
        solution = self.solution,
        mainline_index = 1,
      }
    else
      self.progress_canvas:Clear()
      self:drawSolvingProgress(self.ticks - s.start_tick, max_ticks)
      self:drawProgress()
    end
  end

  -- We may have switched to the "executing" state, which we handle immediately
  if s.state == "executing" then
    local current = SliderState.getSliderState()

    if SliderState.isSolved(current) and s.finished_tick == nil then
      s.finished_tick = self.ticks
    elseif not SliderState.isSolved(current) and s.finished_tick ~= nil then
      -- Left the solved state for some reason. Go back to showing overlay
      s.finished_tick = nil
    end

    local state_changed = s.last_drawn_state == nil or not SliderState.isEqual(s.last_drawn_state, current)

    if state_changed then
      local _, mainline_index = zyklib.array.findLast(s.solution, function(move)
        return zyklib.array.exists(move.pre_states, function(pre) return SliderState.isEqual(pre, current) end)
      end)

      if mainline_index == #s.solution - 1 and SliderState.isSolved(current) then
        mainline_index = #s.solution + 1
      end

      s.mainline_index = mainline_index

      if SliderState.isSolved(current) then
        if s.finished_tick == nil then s.finished_tick = self.ticks end

        self.solution_canvas:Clear()
      else
        s.finished_tick = nil
        self:drawSolution(current)
      end

      s.last_drawn_state = current
    end

    -- Reduce number of progress redraws to match the clock accuracy
    if state_changed or self.ticks % 5 == 0 then
      self.progress_canvas:Clear()
      self:drawProgress()
    end
  end
end

function ActivePuzzle:dispose()
  self.lifetime:dispose()
  self.progress_canvas:Destroy()
  self.solution_canvas:Destroy()
  if self.solver then self.solver:dispose() end
  ActivePuzzle.instance = nil
end

---@type ct.sliders.ActiveSliderPuzzle?
ActivePuzzle.instance = nil

local interface_open_handler = zyklib.game_events.native.ServerLogic:map(function()
      local comp = ui.Interfaces:GetComponent(id.Component.SLIDE_PUZZLE__UNIVERSE)

      return comp ~= nil and comp.parent ~= nil
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

---Enables or disables the slider solver. Disabling also removes any currently shown overlay.
---@param active boolean
local function setActive(active)
  interface_open_handler:setActive(active)

  if not active and ActivePuzzle.instance ~= nil then
    ActivePuzzle.instance:dispose()
  end
end

local initialized = false

--- Activates the solver whenever it is enabled in the settings and deactivates it otherwise. Only the first call has an effect.
function slider_solver.init()
  if initialized then return end
  initialized = true

  slider_solver.settings.enabled:subscribe(setActive, true)
end

return slider_solver
