local Hand = require("hand") -- Зависимость от Hand
local Player = {} -- Создаём таблицу для класса Player
Player.__index = Player

function Player.new() -- Конструктор нового игрока
    local self = setmetatable({}, Player)
    self.energy = 3
    self.maxEnergy = 3
    self.health = health or 30
    self.deck = deck or {}
    self.discardPile = {}
    self.hand = Hand.new()
    return self
end

function Player:drawInfo(x, y, w, h) -- Отрисовка информации
    love.graphics.setColor(0.2, 0.5, 0.8, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf("HP: " .. self.health, x + w * 0.05, y + h * 0.05, w * 0.9, "left")
    love.graphics.printf("Deck: " .. #self.deck, x + w * 0.05, y + h * 0.25, w * 0.9, "left")
    love.graphics.printf("Discard: " .. #self.discardPile, x + w * 0.05, y + h * 0.45, w * 0.9, "left")
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf("Energy: " .. self.energy .. "/" .. self.maxEnergy, x + w * 0.05, y + h * 0.65, w * 0.9, "left")
end

function Player:drawHand(x, y, cardW, cardH, selectedIndex) -- Отрисовка руки
    self.hand:draw(x, y, cardW, cardH, selectedIndex)
end

function Player:endTurn() -- Завершение хода
    self.energy = self.maxEnergy
    local Game = require("game") -- Зависимость от Game для доступа к CONST
    local cardsNeeded = Game.CONST.HAND_SIZE - #self.hand.cards
    local cardsAvailable = #self.deck + #self.discardPile
    local cardsToDraw = math.min(cardsNeeded, cardsAvailable)
    for i = 1, cardsToDraw do
        self.hand:addCard(self:drawCard())
    end
end

function Player:drawCards() -- Взятие карт
    local Game = require("game") -- Зависимость от Game для доступа к CONST
    local cardsNeeded = Game.CONST.HAND_SIZE - #self.hand.cards
    local cardsAvailable = #self.deck + #self.discardPile
    local cardsToDraw = math.min(cardsNeeded, cardsAvailable)
    for i = 1, cardsToDraw do
        self.hand:addCard(self:drawCard())
    end
end

function Player:drawCard() -- Взятие одной карты
    if #self.deck == 0 and #self.discardPile > 0 then
        for _, card in ipairs(self.discardPile) do
            table.insert(self.deck, card)
        end
        self.discardPile = {}
        self:shuffleDeck()
    end
    if #self.deck > 0 then
        return table.remove(self.deck, 1)
    end
    return nil
end

function Player:shuffleDeck() -- Перемешивание колоды
    for i = #self.deck, 2, -1 do
        local j = math.random(i)
        self.deck[i], self.deck[j] = self.deck[j], self.deck[i]
    end
end

function Player:isAlive() -- Проверка жизни
    return self.health > 0
end

function Player:playCard(index, target) -- Разыгрывание карты
    local card = self.hand.cards[index]
    if card and self.energy >= card.cost then
        self.energy = self.energy - card.cost
        local damage = card.attack
        if target.defending then
            damage = math.floor(damage * 0.5)
        end
        target.health = target.health - damage
        table.insert(self.discardPile, self.hand:removeCard(index))
        return true
    end
    return false
end

return Player