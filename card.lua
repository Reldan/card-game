Card = {}
Card.__index = Card

function Card.new(name, cost, effect)
    local self = setmetatable({}, Card)
    self.name = name
    self.cost = cost
    self.effect = effect
    return self
end