local numbers = {}

-- Rounds a number to the nearest integer.
---@param number number
---@return integer
function numbers.round(number)
  return math.floor(number + 0.5)
end

return numbers
