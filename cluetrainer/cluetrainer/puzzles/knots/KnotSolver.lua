-- KnotSolver.lua
local zyklib     = require "zyklib"
local util       = require "cluetrainer/util"

---@class cluetrainer.puzzles.knots.KnotSolver
local KnotSolver = {}

---Get the current shuffle state of the knot puzzle from player variables.
---@return integer[]
local function getShuffleState()
  --- Getting the solution is trivial since the variables directly represent the shuffle state.
  return {
    var.VarPlayer["TRAIL_SHUFFLE0"].value,
    var.VarPlayer["TRAIL_SHUFFLE1"].value,
    var.VarPlayer["TRAIL_SHUFFLE2"].value,
    var.VarPlayer["TRAIL_SHUFFLE3"].value,
  }
end


---Get the shape of the specified knot type from the database. A knot shape is the sequence of track lengths for that knot.
---@param knot_id integer
---@return integer[]
local function getKnotShape(knot_id)
  return zyklib.array.map(
    config.DBRow["KNOT0" .. knot_id]:GetColumnValues(2) --[[@as DBRowType[] ]],            -- Get DBRow for the specified knot type
    function(row) return (row:GetColumnValues(3) --[[@as EnumType[] ]])[1].valueCount end) -- Extract the track lengths
end

---Minimized the solution from only using clockwise rotations to using the shortest rotation direction.
---@param shuffle integer[] The current shuffle state.
---@param shape integer[] The shape of the knot, representing the sequence of track lengths.
---@return integer[] # The minimized solution using the shortest rotation direction.
local function minifySolution(shuffle, shape)
  return zyklib.array.zip(shuffle, shape, function(s, size)
    if s < size // 2 then
      return s
    else
      return s - size
    end
  end)
end

---comment
---@param knot_id integer
---@param shape integer[]
---@return {track: integer, clockwise: boolean, comp: ui.Component}[]
local function getComponentMap(knot_id, shape)
  return zyklib.array.flatMap(shape, function(track_length, track_id)
    track_id = track_id - 1 -- Adjust for zero-based indexing

    local cw = ui.Interfaces:GetComponent(id.Component["TRAIL_KNOT_0" .. knot_id .. "__TRACK_" .. track_id .. "_CW"])
    local ccw = ui.Interfaces:GetComponent(id.Component["TRAIL_KNOT_0" .. knot_id .. "__TRACK_" .. track_id .. "_CCW"])

    return {
      { track = track_id, clockwise = true,  comp = cw },
      { track = track_id, clockwise = false, comp = ccw },
    }
  end)
end

local STATE_VARIABLE = var.VarPlayer["TRAIL_SHUFFLE0"].baseVar

---@class ActiveKnotPuzzle: zyklib.disposable.IDisposable
---@field knot_id integer
---@field component_map {track: integer, clockwise: boolean, comp: ui.Component}[]
---@field canvas ui.Canvas
---@field disposable_group zyklib.disposable.DisposableGroup
local ActivePuzzle = {}
ActivePuzzle.__index = ActivePuzzle

---comment
---@param knot_id integer
---@return ActiveKnotPuzzle
function ActivePuzzle.new(knot_id)
  local self = setmetatable({
    knot_id = knot_id,
  }, ActivePuzzle)

  local shape = getKnotShape(knot_id)
  self.component_map = getComponentMap(knot_id, shape)

  self.disposable_group = zyklib.disposable.DisposableGroup.new()

  ---@type zyklib.reactive.Observable<integer[]>
  local shuffle_state = zyklib.reactive.Observable.new(getShuffleState())
  local solution = shuffle_state:map(function(shuffle) return minifySolution(shuffle, shape) end)

  -- Create the canvas for the solution overlay
  local interface = ui.Interfaces:GetComponent(id.Component["TRAIL_KNOT_0" .. knot_id .. "__MAINMODAL_WINDOW_CONTENT"]) --[[@as ui.ComponentCollection]]
  self.canvas = ui.Canvas.new(interface)
  self.canvas:SetSize(interface.width, interface.height)

  local CLIENT_SIDE_HISTORY_CAPACITY = 20
  local next_history_index = 1
  local client_side_history = {}

  self.disposable_group:add(

    shuffle_state:subscribe(function(shuffle)
      -- We keep track of the recent state history to avoid server transmissions to wrongly override client-side prediction
      client_side_history[next_history_index] = shuffle
      next_history_index = (next_history_index + 1) % CLIENT_SIDE_HISTORY_CAPACITY + 1
    end),

    zyklib.game_events.native.VarTransmit
    :filter(function(event) return event.var.id == STATE_VARIABLE.id end)
    :subscribe(function()
      local state = getShuffleState()

      -- Only override the client side state if this state is actually a new one we haven't seen recently.
      if not zyklib.array.exists(client_side_history, function(history) return zyklib.objects.deepEquals(history, state) end) then
        shuffle_state:set(getShuffleState())
      end
    end),

    -- Listen to actions to implement custom client-side prediction
    zyklib.game_events.native.MiniMenuEntrySelected:subscribe(function(event)
      if event.entry.componentData ~= nil then
        local action = zyklib.array.find(self.component_map, function(comp)
          return comp.comp == event.entry.componentData.component
        end)

        if action ~= nil then
          local state = { table.unpack(shuffle_state:get()) }

          local index = action.track + 1

          state[index] = (state[index] + (action.clockwise and -1 or 1)) % shape[index]

          shuffle_state:set(state)
        end
      end
    end),

    solution:subscribe(function(sol) self:draw(sol) end, true)
  )

  return self
end

local FONT = id.Font.NOTOSANS_22

function ActivePuzzle.draw(self, solution)
  if solution == nil then
    log("Solution is nil")
    return
  end

  self.canvas:Clear()

  if zyklib.array.forAll(solution, function(value) return value == 0 end) then
    -- Is Solved
    local unlock_button = ui.Interfaces:GetComponent(id.Component["TRAIL_KNOT_0" .. self.knot_id .. "__UNLOCK_BUTTON"]) --[[@as ui.Sprite]]

    util.overlayCenteredText(self.canvas, self.canvas, "Solved!", FONT, 0x00FF00FF,
      0x00000080)

    self.canvas:AddRectangle(unlock_button.x, unlock_button.y, unlock_button.width, unlock_button.height, 0x00FF0080)
  else
    -- Not solved, display offsets

    for i = 1, #solution do
      local offset = solution[i]

      if offset ~= 0 then
        local comp = zyklib.array.find(self.component_map,
          function(c) return c.track == i - 1 and c.clockwise == (offset > 0) end)

        if comp ~= nil then
          util.overlayCenteredText(self.canvas, comp.comp, tostring(math.abs(offset)), FONT, 0xFFFFFFFF,
            0x00000080)
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
      if value ~= nil then
        ActivePuzzle.instance = ActivePuzzle.new(value)
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
