local Card = {} -- Создаём таблицу для класса Card
Card.__index = Card -- Устанавливаем метатаблицу для ООП

function Card.new(name, attack, cost, description) -- Конструктор новой карты
    local self = setmetatable({}, Card)
    self.name = name
    self.attack = attack
    self.cost = cost
    self.description = description
    return self
end

function Card:draw(x, y, w, h, isSelected) -- Метод отрисовки карты
    love.graphics.setColor(0, 0, 0, 0.3) -- Тень
    love.graphics.rectangle("fill", x + 5, y + 5, w, h, 10, 10)
    love.graphics.setColor(isSelected and {1, 1, 0.5, 0.9} or {0.9, 0.9, 0.9, 0.8}) -- Фон
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)
    love.graphics.setColor(0.2, 0.2, 0.2) -- Рамка
    love.graphics.rectangle("line", x, y, w, h, 10, 10)
    if isSelected then -- Свечение
        love.graphics.setColor(1, 1, 0, 0.5)
        love.graphics.rectangle("line", x - 2, y - 2, w + 4, h + 4, 12, 12)
    end
    love.graphics.setColor(0, 0, 0) -- Текст
    love.graphics.printf(self.name, x + 5, y + 5, w - 10, "center")
    love.graphics.printf("ATK: " .. self.attack, x + 5, y + h - 50, w - 10, "left")
    love.graphics.printf("Cost: " .. self.cost, x + 5, y + h - 30, w - 10, "left")
    love.graphics.setColor(0.4, 0.4, 0.4) -- Описание
    love.graphics.printf(self.description, x + 5, y + 30, w - 10, "center")
end

return Card