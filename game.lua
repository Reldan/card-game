local Card = require("card")
local Player = require("player")
local LevelManager = require("level_manager")
local Utils = require("utils")
require("enemy_renderer")

local Game = {
    CONST = {
        CARD_WIDTH = 0.125,
        CARD_HEIGHT = 0.175,
        BUTTON_WIDTH = 0.12,
        BUTTON_HEIGHT = 0.06,
        INFO_WIDTH = 0.22,
        INFO_HEIGHT = 0.15,
        HAND_SIZE = 5
    },
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
    transition = {active = false, alpha = 0},
    shaderTime = 0,
    backgroundCanvas = nil
}

Game.menuItems = {
    {text = "Start Game", action = function() Game.state = "game"; Game:initializeGame() end, hover = 0},
    {text = "Exit", action = function() love.event.quit() end, hover = 0}
}

function Game:load()
    -- Initialize background canvas
    self.backgroundCanvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
    
    self.cards = {
        {name = "Warrior", attack = 3, cost = 2, description = "Basic fighter"},
        {name = "Mage", attack = 2, cost = 3, description = "Casts spells"}
    }
end

function Game:initializeGame()
    self.player = Player.new()
    self.levelManager = LevelManager.new()
    self.enemies = self.levelManager:getCurrentEnemies()
    
    -- Add multiple copies of each card to the deck
    for _, card in ipairs(self.cards) do
        local copies = 3  -- Add 3 copies of each card
        for i = 1, copies do
            table.insert(self.player.deck, Card.new(card.name, card.attack, card.cost, card.description))
        end
    end
    
    print(string.format("[Initialize] Created deck with %d cards", #self.player.deck))
    
    self.player:reshuffleDeck()
    self.selectedCardIndex = nil
    self.selectedEnemyIndex = nil
    self.roundCounter = 1
    self.player:drawCards()
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
            self.player.hand.cards = {}
            self.player:drawCards()
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
    -- Handle menu button hover sounds
    if self.state == "menu" then
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()
        local bw, bh = w * self.CONST.BUTTON_WIDTH * 3, h * self.CONST.BUTTON_HEIGHT
        local startY = h * 0.3
        
        for i, item in ipairs(self.menuItems) do
            local x = (w - bw) / 2
            local y = startY + (i - 1) * (bh + h * 0.05)
        end
    end
    
    if self.enemyTurnAnimation.active then
        self.enemyTurnAnimation.timer = self.enemyTurnAnimation.timer - dt
        if self.enemyTurnAnimation.timer <= 0 then
            for _, enemy in ipairs(self.enemies) do
                if enemy:isAlive() then
                    enemy:playTurn(self.player)
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
    if self.transition.active then
        self.transition.alpha = self.transition.alpha - dt
        if self.transition.alpha <= 0 then
            self.transition.active = false
        end
    end
    for i, item in ipairs(self.menuItems) do
        if Utils.isMouseOver((love.graphics.getWidth() - love.graphics.getWidth() * self.CONST.BUTTON_WIDTH * 3) / 2, love.graphics.getHeight() * 0.3 + (i - 1) * (love.graphics.getHeight() * self.CONST.BUTTON_HEIGHT + love.graphics.getHeight() * 0.05), love.graphics.getWidth() * self.CONST.BUTTON_WIDTH * 3, love.graphics.getHeight() * self.CONST.BUTTON_HEIGHT) then
            item.hover = math.min(item.hover + dt * 2, 1)
        else
            item.hover = math.max(item.hover - dt * 2, 0)
        end
    end
end

function Game:draw()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    
    if self.state == "menu" then
        love.graphics.setColor(1, 1, 1, 0.8)
        local font = love.graphics.newFont(48) 
        love.graphics.setFont(font)
        love.graphics.printf("Card Deck Adventure", 0, h * 0.1, w, "center")
        love.graphics.setColor(1, 0.2, 0.2, 0.8)
        local font = love.graphics.newFont(20) 
        love.graphics.setFont(font)
        local bw, bh = w * self.CONST.BUTTON_WIDTH * 3, h * self.CONST.BUTTON_HEIGHT
        local startY = h * 0.3
        for i, item in ipairs(self.menuItems) do
            local x = (w - bw) / 2
            local y = startY + (i - 1) * (bh + h * 0.05)
            love.graphics.setColor(0.3 + item.hover * 0.3, 0.5 + item.hover * 0.3, 0.7 + item.hover * 0.3)
            love.graphics.rectangle("fill", x, y, bw, bh, 15, 15)
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf(item.text, x, y + bh * 0.35, bw, "center")
        end
    elseif self.state == "game" then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("Round " .. self.roundCounter .. " (Level " .. self.levelManager.currentLevel .. "/" .. self.levelManager:getLevelCount() .. ")", 0, h * 0.02, w, "center")
        self.player:drawInfo(w * 0.05, h * 0.82, w * self.CONST.INFO_WIDTH, h * self.CONST.INFO_HEIGHT)
        local enemyWidth = w * self.CONST.INFO_WIDTH
        local totalEnemyWidth = #self.enemies * enemyWidth + (#self.enemies - 1) * (w * 0.02)
        local startX = (w - totalEnemyWidth) / 2
        for i, enemy in ipairs(self.enemies) do
            local x = startX + (i - 1) * (enemyWidth + w * 0.02)
            RenderEnemy(enemy, x, h * 0.05, enemyWidth, h * self.CONST.INFO_HEIGHT)
        end
        local cw, ch = h * self.CONST.CARD_WIDTH, h * self.CONST.CARD_HEIGHT
        RenderHand(self.player.hand, w / 2, h - ch - h * 0.02, cw, ch, self.selectedCardIndex)
        love.graphics.setColor(0.4, 0.6, 0.8)
        love.graphics.rectangle("fill", w * 0.85, h * 0.85, w * self.CONST.BUTTON_WIDTH, h * self.CONST.BUTTON_HEIGHT, 10, 10)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("End Turn", w * 0.85, h * 0.86, w * self.CONST.BUTTON_WIDTH, "center")
        love.graphics.setColor(0.4, 0.6, 0.8)
        love.graphics.rectangle("fill", w * 0.01, h * 0.01, w * self.CONST.BUTTON_WIDTH, h * self.CONST.BUTTON_HEIGHT, 10, 10)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Back", w * 0.01, h * 0.015, w * self.CONST.BUTTON_WIDTH, "center")
    elseif self.state == "victory" then
        love.graphics.setColor(1, 1, 0, 0.8)
        love.graphics.printf("Victory! You defeated all enemies!", 0, h * 0.4, w, "center", 0, 2, 2)
        love.graphics.setColor(0.4, 0.6, 0.8)
        love.graphics.rectangle("fill", w * 0.45, h * 0.6, w * self.CONST.BUTTON_WIDTH, h * self.CONST.BUTTON_HEIGHT, 10, 10)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Menu", w * 0.45, h * 0.615, w * self.CONST.BUTTON_WIDTH, "center")
    elseif self.state == "gameover" then
        love.graphics.setColor(1, 0, 0, 0.8)
        love.graphics.printf("Game Over! You were defeated.", 0, h * 0.4, w, "center", 0, 2, 2)
        love.graphics.setColor(0.4, 0.6, 0.8)
        love.graphics.rectangle("fill", w * 0.45, h * 0.6, w * self.CONST.BUTTON_WIDTH, h * self.CONST.BUTTON_HEIGHT, 10, 10)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Menu", w * 0.45, h * 0.615, w * self.CONST.BUTTON_WIDTH, "center")
    end

    if self.transition.active then
        love.graphics.setColor(0, 0, 0, self.transition.alpha)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end
end

function Game:mousepressed(x, y, button)
    if button ~= 1 then return end
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    if self.state == "menu" then
        local bw, bh = w * self.CONST.BUTTON_WIDTH * 3, h * self.CONST.BUTTON_HEIGHT
        local startY = h * 0.3
        for i, item in ipairs(self.menuItems) do
            local bx = (w - bw) / 2
            local by = startY + (i - 1) * (bh + h * 0.05)
            if Utils.isMouseOver(bx, by, bw, bh) then
                self.selectedMenu = i
                item.action()
                break
            end
        end
    elseif self.state == "game" and not self.enemyTurnAnimation.active then
        if Utils.isMouseOver(w * 0.01, h * 0.01, w * self.CONST.BUTTON_WIDTH, h * self.CONST.BUTTON_HEIGHT) then
            self.state = "menu"
        elseif Utils.isMouseOver(w * 0.85, h * 0.85, w * self.CONST.BUTTON_WIDTH, h * self.CONST.BUTTON_HEIGHT) then
            self.selectedCardIndex = nil
            self.selectedEnemyIndex = nil
            self:endTurn()
        else
            local cw, ch = w * self.CONST.CARD_WIDTH, h * self.CONST.CARD_HEIGHT
            local marginX = cw * 0.33
            local totalWidth = #self.player.hand.cards * cw + (#self.player.hand.cards - 1) * marginX
            local startX = (w - totalWidth) / 2
            local cardY = h - ch - h * 0.02
            for i, card in ipairs(self.player.hand.cards) do
                local cardX = startX + (i - 1) * (cw + marginX)
                if Utils.isMouseOver(cardX, cardY, cw, ch) then
                    self.selectedCardIndex = i
                    break
                end
            end
            local enemyWidth = w * self.CONST.INFO_WIDTH
            local totalEnemyWidth = #self.enemies * enemyWidth + (#self.enemies - 1) * (w * 0.02)
            local enemyStartX = (w - totalEnemyWidth) / 2
            for i, enemy in ipairs(self.enemies) do
                local enemyX = enemyStartX + (i - 1) * (enemyWidth + w * 0.02)
                if Utils.isMouseOver(enemyX, h * 0.05, enemyWidth, h * self.CONST.INFO_HEIGHT) and self.selectedCardIndex then
                    if self.player:playCard(self.selectedCardIndex, enemy) then
                        self.selectedCardIndex = nil
                        self.selectedEnemyIndex = nil
                        self:checkGameState()
                    end
                    break
                end
            end
        end
    elseif self.state == "victory" or self.state == "gameover" then
        if Utils.isMouseOver(w * 0.45, h * 0.6, w * self.CONST.BUTTON_WIDTH, h * self.CONST.BUTTON_HEIGHT) then
            self.state = "menu"
        end
    end
end

function Game:keypressed(key)
    if self.state == "menu" then
        if key == "up" then
            self.selectedMenu = math.max(1, self.selectedMenu - 1)
        elseif key == "down" then
            self.selectedMenu = math.min(#self.menuItems, self.selectedMenu + 1)
        elseif key == "return" then
            self.menuItems[self.selectedMenu].action()
        end
    end
end

function Game:textinput(t)
    if self.state == "create" then
        self.newCard[self.selectedField] = self.newCard[self.selectedField] .. t
    end
end

return Game