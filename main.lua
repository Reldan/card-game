local utf8 = require("utf8")

-- Константы
local CONST = {
    CARD_WIDTH = 0.15,
    CARD_HEIGHT = 0.3,
    BUTTON_WIDTH = 0.12,
    BUTTON_HEIGHT = 0.06,
    INFO_WIDTH = 0.22,
    INFO_HEIGHT = 0.15,
    HAND_SIZE = 5
}

-- Card
local Card = {}
Card.__index = Card

function Card.new(name, attack, cost, description)
    local self = setmetatable({}, Card)
    self.name = name
    self.attack = attack
    self.cost = cost
    self.description = description
    return self
end

function Card:draw(x, y, w, h, isSelected)
    -- Тень
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", x + 5, y + 5, w, h, 10, 10)
    -- Основной фон карты с рамкой
    love.graphics.setColor(isSelected and {1, 1, 0.5, 0.9} or {0.9, 0.9, 0.9, 0.8})
    love.graphics.rectangle("fill", x, y, w, h, 10, 10)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("line", x, y, w, h, 10, 10)
    -- Свечение при выборе
    if isSelected then
        love.graphics.setColor(1, 1, 0, 0.5)
        love.graphics.rectangle("line", x - 2, y - 2, w + 4, h + 4, 12, 12)
    end
    -- Текст
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(self.name, x + 5, y + 5, w - 10, "center")
    love.graphics.printf("ATK: " .. self.attack, x + 5, y + h - 50, w - 10, "left")
    love.graphics.printf("Cost: " .. self.cost, x + 5, y + h - 30, w - 10, "left")
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.printf(self.description, x + 5, y + 30, w - 10, "center")
end

-- Hand
local Hand = {}
Hand.__index = Hand

function Hand.new()
    return setmetatable({cards = {}}, Hand)
end

function Hand:addCard(card)
    if card then table.insert(self.cards, card) end
end

function Hand:removeCard(index)
    return table.remove(self.cards, index)
end

function Hand:draw(x, y, w, h, selectedIndex)
    local totalWidth = #self.cards * w + (#self.cards - 1) * (w * 0.33)
    local startX = x - totalWidth / 2
    for i, card in ipairs(self.cards) do
        local cardX = startX + (i - 1) * (w + w * 0.33)
        card:draw(cardX, y, w, h, i == selectedIndex)
    end
end

-- Entity (игрок)
local Entity = {}
Entity.__index = Entity

function Entity.new(health, deck)
    local self = setmetatable({}, Entity)
    self.health = health or 30
    self.deck = deck or {}
    self.discardPile = {}
    self.hand = Hand.new()
    return self
end

function Entity:drawInfo(x, y, w, h)
    love.graphics.setColor(0.2, 0.5, 0.8, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf("HP: " .. self.health, x + w * 0.05, y + h * 0.05, w * 0.9, "left")
    love.graphics.printf("Deck: " .. #self.deck, x + w * 0.05, y + h * 0.25, w * 0.9, "left")
    love.graphics.printf("Discard: " .. #self.discardPile, x + w * 0.05, y + h * 0.45, w * 0.9, "left")
end

function Entity:drawHand(x, y, cardW, cardH, selectedIndex)
    self.hand:draw(x, y, cardW, cardH, selectedIndex)
end

function Entity:drawCards()
    local cardsNeeded = CONST.HAND_SIZE - #self.hand.cards
    local cardsAvailable = #self.deck + #self.discardPile
    local cardsToDraw = math.min(cardsNeeded, cardsAvailable)
    for i = 1, cardsToDraw do
        self.hand:addCard(self:drawCard())
    end
end

function Entity:drawCard()
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

function Entity:shuffleDeck()
    for i = #self.deck, 2, -1 do
        local j = math.random(i)
        self.deck[i], self.deck[j] = self.deck[j], self.deck[i]
    end
end

function Entity:isAlive()
    return self.health > 0
end

-- Player
local Player = {}
Player.__index = Player

function Player.new()
    local self = setmetatable({}, Player)
    self.entity = Entity.new()
    self.energy = 3
    self.maxEnergy = 3
    return self
end

function Player:drawInfo(x, y, w, h)
    self.entity:drawInfo(x, y, w, h)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf("Energy: " .. self.energy .. "/" .. self.maxEnergy, x + w * 0.05, y + h * 0.65, w * 0.9, "left")
end

function Player:drawHand(x, y, cardW, cardH, selectedIndex)
    self.entity:drawHand(x, y, cardW, cardH, selectedIndex)
end

function Player:endTurn()
    self.energy = self.maxEnergy
    self.entity:drawCards()
end

function Player:playCard(index, target)
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

function Player:isAlive()
    return self.entity:isAlive()
end

function Player:shuffleDeck()
    self.entity:shuffleDeck()
end

-- Enemy
local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(name, health, attack)
    local self = setmetatable({}, Enemy)
    self.name = name
    self.health = health or 30
    self.attack = attack or 2
    self.defending = false
    self.hitAnimation = 0
    return self
end

function Enemy:drawInfo(x, y, w, h)
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", x + 5, y + 5, w, h, 8, 8)
    love.graphics.setColor(self.defending and {0.8, 0.8, 0.8, 0.9} or {0.8, 0.5, 0.7, 0.9})
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("line", x, y, w, h, 8, 8)
    if self.hitAnimation > 0 then
        love.graphics.setColor(1, 0, 0, self.hitAnimation)
        love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    end
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(self.name .. " HP: " .. self.health, x + w * 0.05, y + h * 0.05, w * 0.9, "left")
    love.graphics.printf("ATK: " .. self.attack, x + w * 0.05, y + h * 0.25, w * 0.9, "left")
    if self.defending then
        love.graphics.printf("Defending", x + w * 0.05, y + h * 0.45, w * 0.9, "left")
    end
    if not self:isAlive() then
        love.graphics.setColor(1, 0, 0)
        love.graphics.line(x, y, x + w, y + h)
        love.graphics.line(x + w, y, x, y + h)
    end
end

function Enemy:playTurn(target)
    if not self:isAlive() then return false end
    self.defending = false
    if math.random() < 0.5 then
        target.health = target.health - self.attack
        self.hitAnimation = 0.5
        return true
    else
        self.defending = true
        return false
    end
end

function Enemy:isAlive()
    return self.health > 0
end

function Enemy:update(dt)
    if self.hitAnimation > 0 then
        self.hitAnimation = self.hitAnimation - dt * 2
    end
end

-- LevelManager
local LevelManager = {}
LevelManager.__index = LevelManager

function LevelManager.new()
    local self = setmetatable({}, LevelManager)
    self.levels = {
        {enemies = {Enemy.new("Goblin", 20, 2)}},
        {enemies = {Enemy.new("Orc", 30, 3), Enemy.new("Troll", 25, 2)}},
        {enemies = {Enemy.new("Dragon", 40, 4), Enemy.new("Giant", 35, 3)}}
    }
    self.currentLevel = 1
    return self
end

function LevelManager:getCurrentEnemies()
    local level = self.levels[self.currentLevel]
    return level and level.enemies or {}
end

function LevelManager:nextLevel()
    self.currentLevel = self.currentLevel + 1
    return self.currentLevel <= #self.levels
end

function LevelManager:getLevelCount()
    return #self.levels
end

-- Утилиты
local function serializeTable(t, indent)
    indent = indent or ""
    local result = "{\n"
    for key, value in pairs(t) do
        local keyStr = type(key) == "string" and '["' .. key .. '"]' or "[" .. tostring(key) .. "]"
        if type(value) == "table" then
            result = result .. indent .. "  " .. keyStr .. " = " .. serializeTable(value, indent .. "  ") .. ",\n"
        elseif type(value) == "string" then
            result = result .. indent .. "  " .. keyStr .. ' = "' .. value .. '",\n'
        else
            result = result .. indent .. "  " .. keyStr .. " = " .. tostring(value) .. ",\n"
        end
    end
    return result .. indent .. "}"
end

local function isMouseOver(x, y, w, h)
    local mx, my = love.mouse.getPosition()
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

-- Частицы для эффектов
local Particles = {}
function Particles.new(x, y, count)
    local particles = {}
    for i = 1, count do
        table.insert(particles, {
            x = x,
            y = y,
            vx = math.random(-100, 100),
            vy = math.random(-100, 100),
            life = math.random(0.5, 1)
        })
    end
    return particles
end

function Particles.update(particleGroups, dt)
    for i = #particleGroups, 1, -1 do
        local group = particleGroups[i]
        for j = #group, 1, -1 do
            local p = group[j]
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.life = p.life - dt
            if p.life <= 0 then
                table.remove(group, j)
            end
        end
        if #group == 0 then
            table.remove(particleGroups, i)
        end
    end
end

function Particles.draw(particleGroups)
    love.graphics.setColor(1, 0, 0, 0.7)
    for _, group in ipairs(particleGroups) do
        for _, p in ipairs(group) do
            love.graphics.circle("fill", p.x, p.y, p.life * 5)
        end
    end
end

-- Game
local Game = {
    state = "menu",
    selectedMenu = 1,
    cards = {},
    newCard = {name = "", attack = "", cost = "", description = ""},
    selectedField = "name",
    player = Player.new(),
    levelManager = LevelManager.new(),
    enemies = {},
    selectedCardIndex = nil,
    selectedEnemyIndex = nil,
    roundCounter = 0,
    enemyTurnAnimation = {active = false, timer = 0},
    selectedCardToDelete = nil,
    editingCardIndex = nil,
    particles = {},
    transition = {active = false, alpha = 0}
}

Game.menuItems = {
    {text = "Start Game", action = function() Game.state = "game"; Game:initializeGame() end, hover = 0},
    {text = "Edit Deck", action = function() Game.state = "edit" end, hover = 0},
    {text = "Create Card", action = function() Game.state = "create" end, hover = 0},
    {text = "Exit", action = function() love.event.quit() end, hover = 0}
}

function Game:initializeGame()
    self.player = Player.new()
    self.levelManager = LevelManager.new()
    self.enemies = self.levelManager:getCurrentEnemies()
    for _, card in ipairs(self.cards) do
        table.insert(self.player.entity.deck, Card.new(card.name, card.attack, card.cost, card.description))
    end
    self.player:shuffleDeck()
    self.selectedCardIndex = nil
    self.selectedEnemyIndex = nil
    self.roundCounter = 1
    self.player.entity:drawCards()
    self.transition.active = true
    self.transition.alpha = 1
end

function Game:endTurn()
    if self.enemyTurnAnimation.active then return end
    self.enemyTurnAnimation.active = true
    self.enemyTurnAnimation.timer = 1
    self.roundCounter = self.roundCounter + 1
    self.player:endTurn()
end

function Game:saveNewCard()
    local card = Card.new(self.newCard.name, tonumber(self.newCard.attack) or 0, tonumber(self.newCard.cost) or 0, self.newCard.description)
    if card.name ~= "" then
        if self.editingCardIndex then
            self.cards[self.editingCardIndex] = {name = card.name, attack = card.attack, cost = card.cost, description = card.description}
            self.editingCardIndex = nil
        else
            table.insert(self.cards, {name = card.name, attack = card.attack, cost = card.cost, description = card.description})
        end
        local fullPath = love.filesystem.getSaveDirectory() .. "/cards.lua"
        print("Writing to file: " .. fullPath)
        love.filesystem.write("cards.lua", "return " .. serializeTable(self.cards))
        self.newCard = {name = "", attack = "", cost = "", description = ""}
        self.state = "edit"
    end
end

function Game:deleteCard(index)
    if index and index > 0 and index <= #self.cards then
        table.remove(self.cards, index)
        local fullPath = love.filesystem.getSaveDirectory() .. "/cards.lua"
        print("Writing to file after deletion: " .. fullPath)
        love.filesystem.write("cards.lua", "return " .. serializeTable(self.cards))
        self.selectedCardToDelete = nil
    end
end

function Game:startEditingCard(index)
    if index and index > 0 and index <= #self.cards then
        local card = self.cards[index]
        self.newCard = {name = card.name, attack = tostring(card.attack), cost = tostring(card.cost), description = card.description}
        self.editingCardIndex = index
        self.state = "create"
    end
end

function Game:enemiesAlive()
    for _, enemy in ipairs(self.enemies) do
        if enemy:isAlive() then return true end
    end
    return false
end

function Game:checkGameState()
    if not self:enemiesAlive() then
        if self.levelManager:nextLevel() then
            self.enemies = self.levelManager:getCurrentEnemies()
            self.selectedCardIndex = nil
            self.selectedEnemyIndex = nil
            self.roundCounter = 1
            -- Очистка руки и сдача новых карт
            self.player.entity.hand.cards = {}
            self.player.entity:drawCards()
            self.transition.active = true
            self.transition.alpha = 1
        else
            self.state = "victory"
        end
    elseif not self.player:isAlive() then
        self.state = "gameover"
    end
end

function Game:update(dt)
    if self.enemyTurnAnimation.active then
        self.enemyTurnAnimation.timer = self.enemyTurnAnimation.timer - dt
        if self.enemyTurnAnimation.timer <= 0 then
            for _, enemy in ipairs(self.enemies) do
                if enemy:isAlive() then
                    enemy:playTurn(self.player.entity)
                end
                enemy:update(dt)
            end
            self.enemyTurnAnimation.active = false
            self:checkGameState()
        end
    end
    for _, enemy in ipairs(self.enemies) do
        enemy:update(dt)
    end
    Particles.update(self.particles, dt)
    if self.transition.active then
        self.transition.alpha = self.transition.alpha - dt
        if self.transition.alpha <= 0 then
            self.transition.active = false
        end
    end
    for i, item in ipairs(self.menuItems) do
        if isMouseOver((love.graphics.getWidth() - love.graphics.getWidth() * CONST.BUTTON_WIDTH * 3) / 2, love.graphics.getHeight() * 0.3 + (i - 1) * (love.graphics.getHeight() * CONST.BUTTON_HEIGHT + love.graphics.getHeight() * 0.05), love.graphics.getWidth() * CONST.BUTTON_WIDTH * 3, love.graphics.getHeight() * CONST.BUTTON_HEIGHT) then
            item.hover = math.min(item.hover + dt * 2, 1)
        else
            item.hover = math.max(item.hover - dt * 2, 0)
        end
    end
end

-- Загрузка и сохранение
function love.load()
    love.window.setTitle("Card Deck Adventure")
    love.window.setFullscreen(true)
    love.graphics.setBackgroundColor(0.1, 0.1, 0.2)
    local fullPath = love.filesystem.getSaveDirectory() .. "/cards.lua"
    print("Reading from file: " .. fullPath)
    local chunk = love.filesystem.load("cards.lua")
    Game.cards = chunk and chunk() or {
        {name = "Warrior", attack = 3, cost = 2, description = "Basic fighter"},
        {name = "Mage", attack = 2, cost = 3, description = "Casts spells"}
    }
end

function love.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Градиентный фон
    for i = 0, h do
        love.graphics.setColor(0.1, 0.1, 0.2 + i / h * 0.3)
        love.graphics.line(0, i, w, i)
    end

    if Game.state == "menu" then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("Card Deck Adventure", 0, h * 0.1, w, "center", 0, 2, 2)
        local bw, bh = w * CONST.BUTTON_WIDTH * 3, h * CONST.BUTTON_HEIGHT
        local startY = h * 0.3
        for i, item in ipairs(Game.menuItems) do
            local x = (w - bw) / 2
            local y = startY + (i - 1) * (bh + h * 0.05)
            love.graphics.setColor(0.3 + item.hover * 0.3, 0.5 + item.hover * 0.3, 0.7 + item.hover * 0.3)
            love.graphics.rectangle("fill", x, y, bw, bh, 15, 15)
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf(item.text, x, y + bh * 0.35, bw, "center")
        end
    elseif Game.state == "game" then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("Round " .. Game.roundCounter .. " (Level " .. Game.levelManager.currentLevel .. "/" .. Game.levelManager:getLevelCount() .. ")", 0, h * 0.02, w, "center")
        
        Game.player:drawInfo(w * 0.05, h * 0.82, w * CONST.INFO_WIDTH, h * CONST.INFO_HEIGHT)
        
        local enemyWidth = w * CONST.INFO_WIDTH
        local totalEnemyWidth = #Game.enemies * enemyWidth + (#Game.enemies - 1) * (w * 0.02)
        local startX = (w - totalEnemyWidth) / 2
        for i, enemy in ipairs(Game.enemies) do
            local x = startX + (i - 1) * (enemyWidth + w * 0.02)
            enemy:drawInfo(x, h * 0.05, enemyWidth, h * CONST.INFO_HEIGHT)
        end
        
        local cw, ch = w * CONST.CARD_WIDTH, h * CONST.CARD_HEIGHT
        Game.player:drawHand(w / 2, h - ch - h * 0.02, cw, ch, Game.selectedCardIndex)
        
        love.graphics.setColor(0.4, 0.6, 0.8)
        love.graphics.rectangle("fill", w * 0.85, h * 0.85, w * CONST.BUTTON_WIDTH, h * CONST.BUTTON_HEIGHT, 10, 10)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("End Turn", w * 0.85, h * 0.86, w * CONST.BUTTON_WIDTH, "center")
        
        love.graphics.setColor(0.4, 0.6, 0.8)
        love.graphics.rectangle("fill", w * 0.01, h * 0.01, w * CONST.BUTTON_WIDTH, h * CONST.BUTTON_HEIGHT, 10, 10)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Back", w * 0.01, h * 0.015, w * CONST.BUTTON_WIDTH, "center")
        
        Particles.draw(Game.particles)
    elseif Game.state == "edit" then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("Deck Editor", 0, h * 0.05, w, "center", 0, 1.5, 1.5)
        local cw, ch = w * CONST.CARD_WIDTH, h * CONST.CARD_HEIGHT
        local marginX, marginY = w * 0.05, h * 0.15
        for i, card in ipairs(Game.cards) do
            local x = marginX + ((i - 1) % 4) * (cw + w * 0.02)
            local y = marginY + math.floor((i - 1) / 4) * (ch + h * 0.02)
            Card.new(card.name, card.attack, card.cost, card.description):draw(x, y, cw, ch, i == Game.selectedCardToDelete)
            love.graphics.setColor(1, 0, 0, 0.8)
            love.graphics.rectangle("fill", x + cw - 20, y, 20, 20)
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf("X", x + cw - 20, y + 2, 20, "center")
            love.graphics.setColor(0, 1, 0, 0.8)
            love.graphics.rectangle("fill", x + cw - 40, y, 20, 20)
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf("E", x + cw - 40, y + 2, 20, "center")
        end
        love.graphics.setColor(0.4, 0.6, 0.8)
        love.graphics.rectangle("fill", w * 0.01, h * 0.01, w * CONST.BUTTON_WIDTH, h * CONST.BUTTON_HEIGHT, 10, 10)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Back", w * 0.01, h * 0.015, w * CONST.BUTTON_WIDTH, "center")
    elseif Game.state == "create" then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf(Game.editingCardIndex and "Edit Card" or "Create New Card", 0, h * 0.1, w, "center", 0, 1.5, 1.5)
        local fields = {
            {label = "Name", key = "name", y = h * 0.25},
            {label = "Attack", key = "attack", y = h * 0.35},
            {label = "Cost", key = "cost", y = h * 0.45},
            {label = "Description", key = "description", y = h * 0.55}
        }
        for _, field in ipairs(fields) do
            love.graphics.setColor(Game.selectedField == field.key and {1, 1, 0} or {1, 1, 1})
            love.graphics.printf(field.label .. ": " .. Game.newCard[field.key], w * 0.15, field.y, w * 0.7, "left")
        end
        love.graphics.setColor(0.4, 0.6, 0.8)
        love.graphics.rectangle("fill", w * 0.45, h * 0.75, w * CONST.BUTTON_WIDTH, h * CONST.BUTTON_HEIGHT, 10, 10)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Save", w * 0.45, h * 0.76, w * CONST.BUTTON_WIDTH, "center")
        love.graphics.setColor(0.4, 0.6, 0.8)
        love.graphics.rectangle("fill", w * 0.01, h * 0.01, w * CONST.BUTTON_WIDTH, h * CONST.BUTTON_HEIGHT, 10, 10)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Back", w * 0.01, h * 0.015, w * CONST.BUTTON_WIDTH, "center")
    elseif Game.state == "victory" then
        love.graphics.setColor(1, 1, 0, 0.8)
        love.graphics.printf("Victory! You defeated all enemies!", 0, h * 0.4, w, "center", 0, 2, 2)
        love.graphics.setColor(0.4, 0.6, 0.8)
        love.graphics.rectangle("fill", w * 0.45, h * 0.6, w * CONST.BUTTON_WIDTH, h * CONST.BUTTON_HEIGHT, 10, 10)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Menu", w * 0.45, h * 0.615, w * CONST.BUTTON_WIDTH, "center")
    elseif Game.state == "gameover" then
        love.graphics.setColor(1, 0, 0, 0.8)
        love.graphics.printf("Game Over! You were defeated.", 0, h * 0.4, w, "center", 0, 2, 2)
        love.graphics.setColor(0.4, 0.6, 0.8)
        love.graphics.rectangle("fill", w * 0.45, h * 0.6, w * CONST.BUTTON_WIDTH, h * CONST.BUTTON_HEIGHT, 10, 10)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Menu", w * 0.45, h * 0.615, w * CONST.BUTTON_WIDTH, "center")
    end
    
    if Game.transition.active then
        love.graphics.setColor(0, 0, 0, Game.transition.alpha)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end
end

function love.update(dt)
    Game:update(dt)
end

function love.mousepressed(x, y, button)
    if button ~= 1 then return end
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    if Game.state == "menu" then
        local bw, bh = w * CONST.BUTTON_WIDTH * 3, h * CONST.BUTTON_HEIGHT
        local startY = h * 0.3
        for i, item in ipairs(Game.menuItems) do
            local bx = (w - bw) / 2
            local by = startY + (i - 1) * (bh + h * 0.05)
            if isMouseOver(bx, by, bw, bh) then
                Game.selectedMenu = i
                item.action()
                break
            end
        end
    elseif Game.state == "game" and not Game.enemyTurnAnimation.active then
        if isMouseOver(w * 0.01, h * 0.01, w * CONST.BUTTON_WIDTH, h * CONST.BUTTON_HEIGHT) then
            Game.state = "menu"
        elseif isMouseOver(w * 0.85, h * 0.85, w * CONST.BUTTON_WIDTH, h * CONST.BUTTON_HEIGHT) then
            Game.selectedCardIndex = nil
            Game.selectedEnemyIndex = nil
            Game:endTurn()
        else
            local cw, ch = w * CONST.CARD_WIDTH, h * CONST.CARD_HEIGHT
            local marginX = cw * 0.33
            local totalWidth = #Game.player.entity.hand.cards * cw + (#Game.player.entity.hand.cards - 1) * marginX
            local startX = (w - totalWidth) / 2
            local cardY = h - ch - h * 0.02
            for i, card in ipairs(Game.player.entity.hand.cards) do
                local cardX = startX + (i - 1) * (cw + marginX)
                if isMouseOver(cardX, cardY, cw, ch) then
                    Game.selectedCardIndex = i
                    break
                end
            end
            local enemyWidth = w * CONST.INFO_WIDTH
            local totalEnemyWidth = #Game.enemies * enemyWidth + (#Game.enemies - 1) * (w * 0.02)
            local enemyStartX = (w - totalEnemyWidth) / 2
            for i, enemy in ipairs(Game.enemies) do
                local enemyX = enemyStartX + (i - 1) * (enemyWidth + w * 0.02)
                if isMouseOver(enemyX, h * 0.05, enemyWidth, h * CONST.INFO_HEIGHT) and Game.selectedCardIndex then
                    if Game.player:playCard(Game.selectedCardIndex, enemy) then
                        table.insert(Game.particles, Particles.new(enemyX + enemyWidth / 2, h * 0.05 + h * CONST.INFO_HEIGHT / 2, 10))
                        Game.selectedCardIndex = nil
                        Game.selectedEnemyIndex = nil
                        Game:checkGameState()
                    end
                    break
                end
            end
        end
    elseif Game.state == "edit" then
        if isMouseOver(w * 0.01, h * 0.01, w * CONST.BUTTON_WIDTH, h * CONST.BUTTON_HEIGHT) then
            Game.state = "menu"
        else
            local cw, ch = w * CONST.CARD_WIDTH, h * CONST.CARD_HEIGHT
            local marginX, marginY = w * 0.05, h * 0.15
            for i, card in ipairs(Game.cards) do
                local x = marginX + ((i - 1) % 4) * (cw + w * 0.02)
                local y = marginY + math.floor((i - 1) / 4) * (ch + h * 0.02)
                if isMouseOver(x + cw - 20, y, 20, 20) then
                    if Game.selectedCardToDelete == i then
                        Game:deleteCard(i)
                    else
                        Game.selectedCardToDelete = i
                    end
                    break
                elseif isMouseOver(x + cw - 40, y, 20, 20) then
                    Game:startEditingCard(i)
                    break
                elseif isMouseOver(x, y, cw, ch) then
                    Game.selectedCardToDelete = nil
                    break
                end
            end
        end
    elseif Game.state == "create" then
        if isMouseOver(w * 0.01, h * 0.01, w * CONST.BUTTON_WIDTH, h * CONST.BUTTON_HEIGHT) then
            Game.state = "edit"
            Game.editingCardIndex = nil
            Game.newCard = {name = "", attack = "", cost = "", description = ""}
        elseif isMouseOver(w * 0.15, h * 0.25, w * 0.7, h * 0.05) then Game.selectedField = "name"
        elseif isMouseOver(w * 0.15, h * 0.35, w * 0.7, h * 0.05) then Game.selectedField = "attack"
        elseif isMouseOver(w * 0.15, h * 0.45, w * 0.7, h * 0.05) then Game.selectedField = "cost"
        elseif isMouseOver(w * 0.15, h * 0.55, w * 0.7, h * 0.05) then Game.selectedField = "description"
        elseif isMouseOver(w * 0.45, h * 0.75, w * CONST.BUTTON_WIDTH, h * CONST.BUTTON_HEIGHT) then Game:saveNewCard() end
    elseif Game.state == "victory" or Game.state == "gameover" then
        if isMouseOver(w * 0.45, h * 0.6, w * CONST.BUTTON_WIDTH, h * CONST.BUTTON_HEIGHT) then
            Game.state = "menu"
        end
    end
end

function love.keypressed(key)
    if Game.state == "menu" then
        if key == "up" then
            Game.selectedMenu = math.max(1, Game.selectedMenu - 1)
        elseif key == "down" then
            Game.selectedMenu = math.min(#Game.menuItems, Game.selectedMenu + 1)
        elseif key == "return" then
            Game.menuItems[Game.selectedMenu].action()
        end
    elseif Game.state == "create" then
        if key == "tab" then
            local fieldOrder = {"name", "attack", "cost", "description"}
            for i, field in ipairs(fieldOrder) do
                if field == Game.selectedField then
                    Game.selectedField = fieldOrder[(i % #fieldOrder) + 1]
                    break
                end
            end
        elseif key == "return" then
            Game:saveNewCard()
        elseif key == "backspace" then
            local byteoffset = utf8.offset(Game.newCard[Game.selectedField], -1)
            if byteoffset then
                Game.newCard[Game.selectedField] = string.sub(Game.newCard[Game.selectedField], 1, byteoffset - 1)
            end
        end
    end
end

function love.textinput(t)
    if Game.state == "create" then
        Game.newCard[Game.selectedField] = Game.newCard[Game.selectedField] .. t
    end
end