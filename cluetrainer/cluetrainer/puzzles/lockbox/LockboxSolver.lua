local lua_util       = require "zyklib/lua_util"
local Lockboxes      = require "cluetrainer/puzzles/lockbox/Lockboxes"
local api_util       = require "zyklib/api_util"
local zyklib         = require "zyklib/init"

local lockbox_solver = {}

local function getTwoBit(value, i)
  return (value >> (i * 2)) & 0x3
end

---@return LockboxState
local function getPuzzleState()
  local rows012 = var.VarClient["TRAIL_LIGHTSOUT_CLIENT_1"].value
  local rows34 = var.VarClient["TRAIL_LIGHTSOUT_CLIENT_2"].value

  local state = {
    tile_rows = {
      { getTwoBit(rows012, 0),  getTwoBit(rows012, 1),  getTwoBit(rows012, 2),  getTwoBit(rows012, 3),  getTwoBit(rows012, 4) },
      { getTwoBit(rows012, 5),  getTwoBit(rows012, 6),  getTwoBit(rows012, 7),  getTwoBit(rows012, 8),  getTwoBit(rows012, 9) },
      { getTwoBit(rows012, 10), getTwoBit(rows012, 11), getTwoBit(rows012, 12), getTwoBit(rows012, 13), getTwoBit(rows012, 14) },
      { getTwoBit(rows012, 15), getTwoBit(rows34, 0),   getTwoBit(rows34, 1),   getTwoBit(rows34, 2),   getTwoBit(rows34, 3), },
      { getTwoBit(rows34, 4),   getTwoBit(rows34, 5),   getTwoBit(rows34, 6),   getTwoBit(rows34, 7),   getTwoBit(rows34, 8) },
    }
  }

  return state
end

local TILE_OFFSET         = 38
local TL_OFFSET_IN_CANVAS = {
  x = 50,
  y = 17,
}

---Draws the current state of the lockbox puzzle.
---@param canvas Canvas
---@param solution LockboxSolution
local function draw(canvas, solution)
  canvas:Clear()

  for x = 1, 5, 1 do
    for y = 1, 5, 1 do
      local delta = solution.moves[y][x]

      if delta ~= 0 then
        -- Draw text with a shadow to make it more readable
        canvas:AddText(
          TL_OFFSET_IN_CANVAS.x + TILE_OFFSET * (x - 1) + 1,
          TL_OFFSET_IN_CANVAS.y + TILE_OFFSET * (y - 1) + 1,
          tostring(delta),
          id.Font.NOTOSANS_28,
          0x00000080)

        canvas:AddText(
          TL_OFFSET_IN_CANVAS.x + TILE_OFFSET * (x - 1) - 1,
          TL_OFFSET_IN_CANVAS.y + TILE_OFFSET * (y - 1) - 1,
          tostring(delta),
          id.Font.NOTOSANS_28,
          0x00000080)

        canvas:AddText(
          TL_OFFSET_IN_CANVAS.x + TILE_OFFSET * (x - 1) + 1,
          TL_OFFSET_IN_CANVAS.y + TILE_OFFSET * (y - 1) - 1,
          tostring(delta),
          id.Font.NOTOSANS_28,
          0x00000080)

        canvas:AddText(
          TL_OFFSET_IN_CANVAS.x + TILE_OFFSET * (x - 1) - 1,
          TL_OFFSET_IN_CANVAS.y + TILE_OFFSET * (y - 1) + 1,
          tostring(delta),
          id.Font.NOTOSANS_28,
          0x00000080)

        canvas:AddText(
          TL_OFFSET_IN_CANVAS.x + TILE_OFFSET * (x - 1),
          TL_OFFSET_IN_CANVAS.y + TILE_OFFSET * (y - 1),
          tostring(delta),
          id.Font.NOTOSANS_28,
          0xFFFFFFFF)
      end
    end
  end
end

---@class ActiveLockboxPuzzle
---@field canvas Canvas
---@field latestState LockboxState?
---@field action_handler zyklib.EwentHandler

---@type ActiveLockboxPuzzle?
local active_puzzle = nil

local function maybeRefreshOverlay()
  if active_puzzle == nil then return end

  local current_state = getPuzzleState()

  -- Skip if no change detected
  if lua_util.deep_equals(current_state, active_puzzle.latestState) then return end

  active_puzzle.latestState = current_state

  draw(active_puzzle.canvas, Lockboxes.solve(current_state, {
    modulo_targets_allowed = true,
    minimize = true,
    minimize_by = Lockboxes.MoveMap.hybridScore -- TODO: Update when everything is hooked up to settings
  }))
end

---@type {handler: zyklib.EwentHandler}?
lockbox_solver.instance = nil

function lockbox_solver:init()
  if lockbox_solver.instance ~= nil then return end

  local handler = zyklib.ewent.Ewent.native.ServerLogic:subscribe(function(event)
    local interface = ui.Interfaces:GetInterface(id.Interface.LIGHTSOUT)

    if not interface then
      if active_puzzle ~= nil then
        active_puzzle.action_handler:cancel()
        active_puzzle.canvas:Clear()
        active_puzzle = nil
      end

      return
    end

    local content = ui.Interfaces:GetComponent(id.Component.LIGHTSOUT__MAINMODAL_WINDOW_CONTENT)
    ---@cast content ui.ComponentCollection

    if active_puzzle == nil and content ~= nil then
      local canvas = ui.Canvas.new(content)
      canvas:SetSize(content.width, content.height)

      log(content.width .. "x" .. content.height)

      local handler = zyklib.ewent.Ewent.native.Draw:subscribe(function(event)
        maybeRefreshOverlay()
      end)

      active_puzzle = {
        canvas = canvas,
        latestState = nil,
        action_handler = handler
      }

      maybeRefreshOverlay()
    end
  end)

  lockbox_solver.instance = { handler = handler }
end

return lockbox_solver
