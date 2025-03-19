local Card = {}
Card.__index = Card

function Card.new(name, attack, cost, description) -- Конструктор новой карты
    local self = setmetatable({}, Card)
    self.name = name
    self.attack = attack
    self.cost = cost
    self.description = description
    return self
end


return Card