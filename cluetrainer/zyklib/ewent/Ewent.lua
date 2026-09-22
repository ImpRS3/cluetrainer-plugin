local EwentHandler        = require("zyklib/ewent/EwentHandler")
local UniqueNameGenerator = require("zyklib/UniqueNameGenerator")

---@class zyklib.Ewent<T, RetT>
---@field private listeners zyklib.EwentHandler<T, RetT>[]
---@field private status_changed_callback fun(status: boolean):nil
---@field private hasActiveListeners boolean
local Ewent               = {}
Ewent.__index             = Ewent

---comment
---@param status_changed_callback fun(hasActiveListeners: boolean):nil A call
---@return zyklib.Ewent<T, RetT>?
function Ewent.new(status_changed_callback)
  local self = setmetatable({}, Ewent)
  self.listeners = {}
  self.status_changed_callback = status_changed_callback
  self.hasActiveListeners = false
  return self
end

---Subscribe to this event with the given listener.
---@generic T, RetT
---@param self zyklib.Ewent<T, RetT>
---@param listener fun(payload: T):RetT The function to call when the event is triggered.
---@param start_suspended boolean? Whether the listener should start in a suspended state to be activated later.
---@return zyklib.EwentHandler<T, RetT> The created event handler
function Ewent:subscribe(listener, start_suspended)
  local handler = EwentHandler.new(listener, self)
  if not start_suspended then
    handler:resume()
  end

  return self:addHandler(handler)
end

---Subscribe to this event with the given listener.
---@generic T, RetT
---@param self zyklib.Ewent<T, RetT>
---@param listener fun(payload: T):RetT The function to call when the event is triggered.
---@return zyklib.EwentHandler<T, RetT> The created event handler
function Ewent:subscribeSuspended(listener)
  return self:subscribe(listener, true)
end

--- DO NOT CALL this directly. Use zyklib.Ewent:subscribe instead.
---@generic T, RetT
---@param self zyklib.Ewent<T, RetT>
---@param handler zyklib.EwentHandler<T, RetT> The event handler to add to this event
---@return zyklib.EwentHandler<T, RetT> The added event handler
function Ewent:addHandler(handler)
  table.insert(self.listeners, handler)
  self:update_status()
  return handler
end

---@generic T, RetT
---@param self zyklib.Ewent<T, RetT>
---@param handler zyklib.EwentHandler<T, RetT> The event handler to remove from this event
---@return nil
function Ewent:removeHandler(handler)
  for i = #self.listeners, 1, -1 do
    if self.listeners[i] == handler then
      table.remove(self.listeners, i)
      self:update_status()
      break
    end
  end
end

---Trigger this event with the given payload.
---@generic T, RetT
---@param self zyklib.Ewent<T, RetT>
---@param payload T
---@return RetT result The result value of the last active listener
function Ewent:trigger(payload)
  ---@type RetT
  local result_value = nil

  for _, listener in ipairs(self.listeners) do
    result_value = listener:notify(payload)
  end

  return result_value
end

---Update the status of this event, calling the status changed callback if the active listener state has changed.
---@generic T, RetT
---@param self zyklib.Ewent<T, RetT>
function Ewent:update_status()
  local hasActiveListeners = #self.listeners > 0
  if hasActiveListeners ~= self.hasActiveListeners then
    self.hasActiveListeners = hasActiveListeners
    if self.status_changed_callback then
      self.status_changed_callback(hasActiveListeners)
    end
  end
end

local handler_name_generator = UniqueNameGenerator.new("api_util_handler_")

---Create a new event specifically for game events.
---@generic T, RetT
---@param game_event EventSubscription<T>
---@return zyklib.Ewent<T, RetT>?
function Ewent.forNativeGameEvent(game_event)
  ---@type string
  local active_native_listener = nil

  ---@type zyklib.Ewent<T>
  local ewent = nil

  ewent = Ewent.new(function(status)
    if status then
      active_native_listener = handler_name_generator:next()

      game_event.Subscribe(active_native_listener, function(payload)
        ---@cast ewent zyklib.Ewent<T>
        return ewent:trigger(payload)
      end)
    else
      game_event.Unsubscribe(active_native_listener)
    end
  end)

  return ewent
end

-- Define native game event mappings
Ewent.native = {
  Logic = Ewent.forNativeGameEvent(Event.Logic),
  ServerLogic = Ewent.forNativeGameEvent(Event.ServerLogic),
  Draw = Ewent.forNativeGameEvent(Event.Draw),
  OptionalDependencyChanged = Ewent.forNativeGameEvent(Event.OptionalDependencyChanged),
  KeyUp = Ewent.forNativeGameEvent(Event.KeyUp),
  KeyDown = Ewent.forNativeGameEvent(Event.KeyDown),
  KeyTyped = Ewent.forNativeGameEvent(Event.KeyTyped),
  VarTransmit = Ewent.forNativeGameEvent(Event.VarTransmit),
  ChatMessage = Ewent.forNativeGameEvent(Event.ChatMessage),
  PlayerEntityAdded = Ewent.forNativeGameEvent(Event.PlayerEntityAdded),
  PlayerEntityRemoved = Ewent.forNativeGameEvent(Event.PlayerEntityRemoved),
  NPCEntityAdded = Ewent.forNativeGameEvent(Event.NPCEntityAdded),
  NPCEntityRemoved = Ewent.forNativeGameEvent(Event.NPCEntityRemoved),
  ObjStackEntityAdded = Ewent.forNativeGameEvent(Event.ObjStackEntityAdded),
  ObjStackEntityRemoved = Ewent.forNativeGameEvent(Event.ObjStackEntityRemoved),
  ObjStackEntityChanged = Ewent.forNativeGameEvent(Event.ObjStackEntityChanged),
  WindowFocusChanged = Ewent.forNativeGameEvent(Event.WindowFocusChanged),
  GameStateChanged = Ewent.forNativeGameEvent(Event.GameStateChanged),
  EntityDraw = Ewent.forNativeGameEvent(Event.EntityDraw),
  WindowSizeChanged = Ewent.forNativeGameEvent(Event.WindowSizeChanged),
  SkillTransmit = Ewent.forNativeGameEvent(Event.SkillTransmit),
  RunEnergyTransmit = Ewent.forNativeGameEvent(Event.RunEnergyTransmit),
  RunWeightTransmit = Ewent.forNativeGameEvent(Event.RunWeightTransmit),
  MiniMenuOpened = Ewent.forNativeGameEvent(Event.MiniMenuOpened),
  MiniMenuClosed = Ewent.forNativeGameEvent(Event.MiniMenuClosed),
  MiniMenuReady = Ewent.forNativeGameEvent(Event.MiniMenuReady),
  MiniMenuEntryAdded = Ewent.forNativeGameEvent(Event.MiniMenuEntryAdded),
  MiniMenuEntrySelected = Ewent.forNativeGameEvent(Event.MiniMenuEntrySelected),
  LocAdded = Ewent.forNativeGameEvent(Event.LocAdded),
  LocRemoved = Ewent.forNativeGameEvent(Event.LocRemoved),
  LocCustomised = Ewent.forNativeGameEvent(Event.LocCustomised),
  LocAnimation = Ewent.forNativeGameEvent(Event.LocAnimation),
  InventoryAdded = Ewent.forNativeGameEvent(Event.InventoryAdded),
  InventoryUpdated = Ewent.forNativeGameEvent(Event.InventoryUpdated),
  InventoryRemoved = Ewent.forNativeGameEvent(Event.InventoryRemoved),
  GrandExchangeOfferUpdated = Ewent.forNativeGameEvent(Event.GrandExchangeOfferUpdated),
  WorldCreated = Ewent.forNativeGameEvent(Event.WorldCreated),
  WorldUpdated = Ewent.forNativeGameEvent(Event.WorldUpdated),
  RegionCreated = Ewent.forNativeGameEvent(Event.RegionCreated),
  RegionUpdated = Ewent.forNativeGameEvent(Event.RegionUpdated),
}

return Ewent
