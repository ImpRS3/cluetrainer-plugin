-- SliderSolver.lua
local zyklib           = require("zyklib")
local schema           = require("cluetrainer/util/schema")
local storage          = require("cluetrainer/util/storage")
local SliderState      = require("cluetrainer/puzzles/sliders/SliderState")
local Move             = require("cluetrainer/puzzles/sliders/Move")
local DummySolver      = require("cluetrainer/puzzles/sliders/DummySolver")
local PdbSolverTicked  = require("cluetrainer/puzzles/sliders/pdb/PdbSolverTicked")
-- The pattern database solver is disabled for now. To re-enable it, restore these requires, the `graph` below and the PdbSolver call in ActivePuzzle.new.
local RegionGraph      = require("cluetrainer/puzzles/sliders/pdb/RegionGraph")
-- local PdbSolver              = require("cluetrainer/puzzles/sliders/pdb/PdbSolver")

---@class ct.sliders.SliderSolver
local slider_solver    = {}

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

--- Downloads a pattern database from cluetrainer.app
---@return zyklib.async.Promise<string>
local function downloadFiles()
  -- FIXME: Cache disabled due to a bug in PersistentDB regarding embedded nulls
  -- local cached = PersistentDB:Get("workaround_sliderpdb_mtm_huge_v0")

  -- if cached ~= nil and cached.value ~= nil and cached.value ~= "" then
  --   log("Retrieved from cache")
  --   return zyklib.async.Promise.resolved(cached.value)
  -- end

  local cached = ""

  local promise = zyklib.async.Promise.new()

  --- We cannot use an async-await pattern here because it triggers a client crash, so we use recursion with a delayed call instead.
  local function recur(chunks)
    if #chunks == 9 then
      log("All chunks downloaded")
      local final_value = table.concat(chunks)

      -- Cache pdb for next time. FIXME: Disabled for now
      -- PersistentDB:Set("workaround_sliderpdb_mtm_huge_v0", { value = final_value })

      promise:resolve(final_value)
    else
      zyklib.http.get(Plugin.urls["cluetrainer"], "/data/sliderpdb/mtm_huge/v0chunk0" .. #chunks .. ".bin")
          :onCompletion(function(result, data)
            log("Downloaded chunk " .. #chunks)
            table.insert(chunks, data)

            --- The following is a bug workaround. Recursing directly triggers a client crash
            zyklib.game_events.native.Logic:once(function()
              recur(chunks)
            end)
          end)
    end
  end

  recur({})

  return promise
end

local pdb_data = downloadFiles()

local graph = pdb_data:map(function(data)
  return RegionGraph.new(RegionGraph.parseTables(data), true)
end)

local LOOKAHEAD = 5
local STROKE = 3
local CONTRAST_BORDER = 2
local COLOR_CONTRAST = 0x000000FF
local COLOR_SQUARE = 0x5ca000FF
local COLOR_MOVE = 0x41740EFF

---Draws the slider puzzle overlay.
---@param canvas ui.Canvas
---@param state ct.sliders.SliderState The current puzzle state
---@param solution ct.sliders.AugmentedMove[] The solution, with pre- and post-states for each move
local function draw(canvas, state, solution)
  canvas:Clear()

  --- Center of a tile index (1-25) in canvas coordinates
  local function centerOfTile(index)
    return ((index - 1) % 5) * 56 + 24, ((index - 1) // 5) * 56 + 24
  end

  local _, position = zyklib.array.findLast(solution, function(move)
    return zyklib.array.exists(move.pre_states, function(pre) return SliderState.isEqual(pre, state) end)
  end)

  -- The current state is not on the solution path, so there is nothing meaningful to show
  if position < 0 then return end

  local last_size = 10
  local overlap_map = {}

  for i = 0, LOOKAHEAD - 1 do
    local move_index = position + i

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

    local size = 20 * (1 - i / LOOKAHEAD)

    local ax, ay = centerOfTile(blank)
    local bx, by = centerOfTile(clicked)

    -- Connecting line from the previous marker to this one
    local dx, dy = bx - ax, by - ay
    local length = math.sqrt(dx * dx + dy * dy)
    local ux, uy = dx / length, dy / length

    local x1, y1 = ax + ux * last_size, ay + uy * last_size
    local x2, y2 = bx - ux * size, by - uy * size

    canvas:AddLine(x1, y1, x2, y2, 2, COLOR_CONTRAST)
    canvas:AddLine(x1, y1, x2, y2, 1, COLOR_MOVE)

    -- Marker on the clicked tile
    local outer = size + CONTRAST_BORDER
    canvas:AddOutline(bx - outer, by - outer, outer * 2, outer * 2, STROKE + 2 * CONTRAST_BORDER, COLOR_CONTRAST)
    canvas:AddOutline(bx - size, by - size, size * 2, size * 2, STROKE, COLOR_SQUARE)

    last_size = size
  end
end

---@class ct.sliders.ActiveSliderPuzzle: zyklib.disposable.IDisposable
---@field canvas ui.Canvas
---@field solution ct.sliders.AugmentedMove[]
---@field lifetime zyklib.disposable.DisposableGroup
local ActivePuzzle = {}
ActivePuzzle.__index = ActivePuzzle

---@return ct.sliders.ActiveSliderPuzzle
function ActivePuzzle.new()
  ---@class ct.sliders.ActiveSliderPuzzle
  local self = setmetatable({}, ActivePuzzle)

  self.lifetime = zyklib.disposable.DisposableGroup.new()

  -- Create the canvas for the solution overlay
  local puzzle_container = ui.Interfaces:GetComponent(id.Component.SLIDE_PUZZLE__PUZZLE_LAYER) --[[@as ui.ComponentCollection]]
  self.canvas = ui.Canvas.new(puzzle_container)
  self.canvas:SetSize(puzzle_container.width, puzzle_container.height)

  -- The puzzle state lives in VarClient variables, which do not trigger transmit events, so it is polled every frame.
  ---@type zyklib.reactive.Observable<ct.sliders.SliderState>
  local observable_slider_state = zyklib.game_events.derived.forClientVariables(function()
    return SliderState.getSliderState()
  end)

  -- Temporarily uses a synchronous dummy solver instead of a SliderSolvingTask, since coroutines are broken.
  local start_state = observable_slider_state:get()
  self.solver = PdbSolverTicked.new(start_state, graph)
  self.solver:start()
  self.solver:tick(2048)
  self.solution = SliderState.augmentMoves(start_state, self.solver.best_solution)

  --self.solution = SliderState.augmentMoves(start_state, DummySolver.solve(start_state))

  self.lifetime:add(
    zyklib.game_events.native.Draw:subscribe(function()
      observable_slider_state:set(SliderState.getSliderState())
    end),

    observable_slider_state:subscribe(function(current_state)
      draw(self.canvas, current_state, self.solution)
    end, true)
  )

  return self
end

function ActivePuzzle:dispose()
  self.lifetime:dispose()
  self.canvas:Destroy()
  self.solver:dispose()
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

      if is_open and graph:resolved() then
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
