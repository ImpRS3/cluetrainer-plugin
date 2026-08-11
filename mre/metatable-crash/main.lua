local Class = {}
Class.__index = Class

function Class.new()
  local self = setmetatable({}, Class)
  return self
end

function Class:f()
  log("f")
  self:g()
end

function Class:g()
  log("g")

  self.test = {}
end

Class:f()
