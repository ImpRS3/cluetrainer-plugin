local abstraction         = require "abstraction"
local util                = require "util"
local Towers              = require "solvers/towers/Towers"

local towers_solver       = {}

local TILE_OFFSET         = 44
local TL_OFFSET_IN_CANVAS = {
  x = 40,
  y = 37,
}

local TR_OVERLAY_OFFSET   = { x = 16, y = -10 }
local TL_OVERLAY_OFFSET   = { x = -5, y = -10 }

---Draws the current state of the towers puzzle.
---@param canvas Canvas
---@param is_state Towers.Blocks
---@param should_state Towers.Blocks
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
---@return Towers.Hints
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

---@return Towers.Blocks
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

---@class ActivePuzzle
---@field canvas Canvas
---@field solution Towers.PuzzleState
---@field action_handler Handler
---@field latestState Towers.Blocks?

---@type ActivePuzzle?
local active_puzzle = nil

local function maybeRefreshOverlay()
  if active_puzzle == nil then return end

  local current_state = getPuzzleState()

  -- Skip if no change detected
  if util.deepEquals(current_state, active_puzzle.latestState) then return end

  active_puzzle.latestState = current_state

  draw(active_puzzle.canvas, current_state, active_puzzle.solution.blocks,
    { show_deltas = true, show_should = true })
end

function towers_solver:init()
  abstraction.subscribe(Event.ServerLogic, function(event)
    local interface = ui.Interfaces:GetInterface(id.Interface.TRAIL17_SKYSCRAPERS)

    if not interface then
      if active_puzzle ~= nil then
        active_puzzle.action_handler.cancel()
        active_puzzle.canvas:Clear()
        active_puzzle = nil
      end

      return
    end

    local content = ui.Interfaces:GetComponent(id.Component.TRAIL17_SKYSCRAPERS__SKYSCRAPERS_CONTENT)
    ---@cast content ui.ComponentCollection

    if active_puzzle == nil and content ~= nil then
      local solution = Towers.solve(getPuzzleHints())

      if not solution then return end

      local canvas = ui.Canvas.new(content)
      canvas:SetSize(300, 300)
      canvas:AddOutline(0, 0, 300, 300, 1, 0xFF0000FF)

      local handler = abstraction.subscribe(Event.MiniMenuEntrySelected, function()
        maybeRefreshOverlay()
      end)

      active_puzzle = {
        canvas = canvas,
        solution = solution,
        action_handler = handler,
        latestState = nil
      }

      maybeRefreshOverlay()
    end

    -- TODO: The following call should be placed somewhere client-side when we figure out how to read client-side puzzle state
    maybeRefreshOverlay()
  end)
end

return towers_solver
