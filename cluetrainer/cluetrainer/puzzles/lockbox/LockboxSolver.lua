local lua_util       = require "zyklib/lua_util"
local Lockboxes      = require "cluetrainer/puzzles/lockbox/Lockboxes"
local zyklib         = require "zyklib/init"

local lockbox_solver = {}

---@return LockboxState
local function getPuzzleState()
  local rows012 = var.VarClient["TRAIL_LIGHTSOUT_CLIENT_1"].value
  local rows34 = var.VarClient["TRAIL_LIGHTSOUT_CLIENT_2"].value

  return {
    tile_rows = zyklib.lua_util.grouped(
      zyklib.lua_util.concat(
        zyklib.bit.getAll(2, rows012, 16),
        zyklib.bit.getAll(2, rows34, 9)
      ), 5)
  }
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

  local handler = zyklib.reactive.Native.ServerLogic:subscribe(function(event)
    local interface = ui.Interfaces:GetInterface(id.Interface.LIGHTSOUT)

    if not interface then
      if active_puzzle ~= nil then
        active_puzzle.action_handler:cancel()
        active_puzzle.canvas:Clear()
        active_puzzle = nil
      end

      return
    end

    local content = ui.Interfaces:GetComponent(id.Component.LIGHTSOUT__MAINMODAL_WINDOW_CONTENT) --[[@as ui.ComponentCollection]]

    if active_puzzle == nil and content ~= nil then
      local canvas = ui.Canvas.new(content)
      canvas:SetSize(content.width, content.height)

      log(content.width .. "x" .. content.height)

      local handler = zyklib.reactive.Native.Draw:subscribe(function(event)
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
