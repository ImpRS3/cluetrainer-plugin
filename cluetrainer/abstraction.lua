local abstraction = {}

---@class Handler 
---@field id string
---@field cancel fun(): nil

---@type integer
local handler_counter = 0

---@generic T, RetT
---@param event EventSubscription<T, RetT>
---@param handler fun(event: T): RetT
---@return Handler
function abstraction.subscribe(event, handler)

  while true do
    handler_counter = handler_counter + 1
    local handler_name = "handler_" .. handler_counter

    local success = event.Subscribe(handler_name, handler)

    if(success) then
      return {
        id = handler_name,
        cancel = function()
          event.Unsubscribe(handler_name)
        end
      }
    end
  end
end

return abstraction

