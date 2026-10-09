local api_util = require "zyklib/api_util"
local zyklib   = require "zyklib/init"

local knot_solver = {}


---Draws the current state of the towers puzzle.
---@param canvas Canvas
local function draw(canvas)
  canvas:Clear()

  canvas:AddOutline(
    0,
    0,
    canvas.width,
    canvas.height,
    1,
    0xFF0000FF
  )
end

---@class ActiveKnotPuzzle
---@field knot_type integer
---@field canvas Canvas
---@field action_handler zyklib.EwentHandler

---@type ActiveKnotPuzzle?
local active_puzzle = nil


local function getPuzzleState()
  -- log("KNOT "..var.VarPlayer.TRAIL_KNOTS.value)
  -- log("KNOT2 "..var.VarPlayer.TRAIL_KNOTS2.value)
  -- log("SHUFFLE1 "..var.VarPlayer.TRAIL_SHUFFLESTYLE_TRACK0.value)
  -- log("SHUFFLE2 "..var.VarPlayer.TRAIL_SHUFFLESTYLE_TRACK1.value)
  -- log("SHUFFLE3 "..var.VarPlayer.TRAIL_SHUFFLESTYLE_TRACK2.value)
  -- log("SHUFFLE4 "..var.VarPlayer.TRAIL_SHUFFLESTYLE_TRACK3.value)
end


local function maybeRefreshOverlay()
  if active_puzzle == nil then return end

  local current_state = getPuzzleState()

  -- -- Skip if no change detected
  -- if util.deepEquals(current_state, active_puzzle.latestState) then return end

  -- active_puzzle.latestState = current_state

  draw(active_puzzle.canvas)
end

---@type {handler: zyklib.EwentHandler}?
knot_solver.instance = nil

---comment---@return {interface: ui.Interface, knot_type: integer}?
local function getInterfaceAndKnotType()
  for i = 0, 9, 1 do
    local interface = ui.Interfaces:GetInterface(id.Interface["TRAIL_KNOT_0" .. i])

    if interface ~= nil then
      return {
        interface = interface,
        knot_type = i
      }
    end
  end

  return nil
end

local function getContainer(knot_type)
  local container_id = id.Component["TRAIL_KNOT_0" .. knot_type .. "__MAINMODAL_WINDOW_CONTENT"]
  return ui.Interfaces:GetComponent(container_id)
end

function knot_solver:init()
  if knot_solver.instance ~= nil then return end

  local handler = zyklib.reactive.Native.ServerLogic:subscribe(function(event)
    local interface = getInterfaceAndKnotType()

    if not interface or (active_puzzle and interface.knot_type ~= active_puzzle.knot_type) then
      if active_puzzle ~= nil then
        active_puzzle.action_handler:cancel()
        active_puzzle.canvas:Clear()
        active_puzzle = nil
      end

      return
    end

    local content = getContainer(interface.knot_type) --[[@as ui.ComponentCollection]]

    if active_puzzle == nil and content ~= nil then
      local canvas = ui.Canvas.new(content)
      canvas:SetSize(content.width, content.height)

      local handler = zyklib.reactive.Native.ServerLogic:subscribe(function(event)
        maybeRefreshOverlay()
      end)

      active_puzzle = {
        canvas = canvas,
        action_handler = handler,
        knot_type = interface.knot_type
      }

      maybeRefreshOverlay()
    end
  end)

  knot_solver.instance = { handler = handler }
end

return knot_solver
