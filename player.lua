local Entity = require("entity") -- Зависимость от Entity
local Player = {} -- Создаём таблицу для класса Player
Player.__index = Player

function Player.new() -- Конструктор нового игрока
    local self = setmetatable({}, Player)
    self.entity = Entity.new()
    self.energy = 3
    self.maxEnergy = 3
    return self
end

function Player:drawInfo(x, y, w, h) -- Отрисовка информации
    self.entity:drawInfo(x, y, w, h)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf("Energy: " .. self.energy .. "/" .. self.maxEnergy, x + w * 0.05, y + h * 0.65, w * 0.9, "left")
end

function Player:drawHand(x, y, cardW, cardH, selectedIndex) -- Отрисовка руки
    self.entity:drawHand(x, y, cardW, cardH, selectedIndex)
end

function Player:endTurn() -- Завершение хода
    self.energy = self.maxEnergy
    self.entity:drawCards()
end

function Player:playCard(index, target) -- Разыгрывание карты
    local card = self.entity.hand.cards[index]
    if card and self.energy >= card.cost then
        self.energy = self.energy - card.cost
        local damage = card.attack
        if target.defending then
            damage = math.floor(damage * 0.5)
        end
        target.health = target.health - damage
        table.insert(self.entity.discardPile, self.entity.hand:removeCard(index))
        return true
    end
    return false
end

function Player:isAlive() -- Проверка жизни
    return self.entity:isAlive()
end

function Player:shuffleDeck() -- Перемешивание колоды
    self.entity:shuffleDeck()
end

return Player