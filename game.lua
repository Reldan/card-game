local Card = require("card")
local Player = require("player")
local LevelManager = require("level_manager")
local Particles = require("particles")
local Utils = require("utils")
local Shaders = require("shaders")
local SoundManager = require("sound_manager")

local Game = {
    CONST = {
        CARD_WIDTH = 0.15,
        CARD_HEIGHT = 0.3,
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
    particles = {},
    transition = {active = false, alpha = 0},
    shaderTime = 0,
    backgroundCanvas = nil
}

Game.menuItems = {
    {text = "Start Game", action = function() Game.state = "game"; Game:initializeGame() end, hover = 0},
    {text = "Edit Deck", action = function() Game.state = "edit" end, hover = 0},
    {text = "Create Card", action = function() Game.state = "create" end, hover = 0},
    {text = "Exit", action = function() love.event.quit() end, hover = 0}
}

function Game:load()
    -- Initialize sounds
    SoundManager.init()
    SoundManager.playMusic()
    
    -- Initialize background canvas
    self.backgroundCanvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Set shader parameters
    Shaders.cardGlow:send("glowStrength", 0.5)
    Shaders.cardGlow:send("glowColor", {0.5, 0.7, 1.0})
    Shaders.backgroundWave:send("amplitude", 0.005)
    Shaders.backgroundWave:send("frequency", 10.0)
    Shaders.cardHover:send("hoverStrength", 1.0)
    
    local fullPath = love.filesystem.getSaveDirectory() .. "/cards.lua"
    print("Reading from file: " .. fullPath)
    local chunk = love.filesystem.load("cards.lua")
    self.cards = chunk and chunk() or {
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
    
    if self.player.debug then
        print(string.format("[Initialize] Created deck with %d cards", #self.player.deck))
    end
    
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
        love.filesystem.write("cards.lua", "return " .. Utils.serializeTable(self.cards))
        self.newCard = {name = "", attack = "", cost = "", description = ""}
        self.state = "edit"
    end
end

function Game:deleteCard(index)
    if index and index > 0 and index <= #self.cards then
        table.remove(self.cards, index)
        local fullPath = love.filesystem.getSaveDirectory() .. "/cards.lua"
        print("Writing to file after deletion: " .. fullPath)
        love.filesystem.write("cards.lua", "return " .. Utils.serializeTable(self.cards))
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
            if Utils.isMouseOver(x, y, bw, bh) and item.hover == 0 then
                SoundManager.playSound("button_hover")
            end
        end
    end
    
    -- Update shader time
    self.shaderTime = self.shaderTime + dt
    Shaders.backgroundWave:send("time", self.shaderTime)
    Shaders.cardHover:send("time", self.shaderTime)
    
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
    Particles.update(self.particles, dt)
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
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Draw background with wave effect
    love.graphics.setCanvas(self.backgroundCanvas)
    love.graphics.clear()
    for i = 0, h do
        love.graphics.setColor(0.1, 0.1, 0.2 + i / h * 0.3)
        love.graphics.line(0, i, w, i)
    end
    love.graphics.setCanvas()
    
    love.graphics.setShader(Shaders.backgroundWave)
    love.graphics.draw(self.backgroundCanvas)
    love.graphics.setShader()

    if self.state == "menu" then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("Card Deck Adventure", 0, h * 0.1, w, "center", 0, 2, 2)
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
            enemy:drawInfo(x, h * 0.05, enemyWidth, h * self.CONST.INFO_HEIGHT)
        end
        local cw, ch = w * self.CONST.CARD_WIDTH, h * self.CONST.CARD_HEIGHT
        self.player:drawHand(w / 2, h - ch - h * 0.02, cw, ch, self.selectedCardIndex)
        love.graphics.setColor(0.4, 0.6, 0.8)
        love.graphics.rectangle("fill", w * 0.85, h * 0.85, w * self.CONST.BUTTON_WIDTH, h * self.CONST.BUTTON_HEIGHT, 10, 10)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("End Turn", w * 0.85, h * 0.86, w * self.CONST.BUTTON_WIDTH, "center")
        love.graphics.setColor(0.4, 0.6, 0.8)
        love.graphics.rectangle("fill", w * 0.01, h * 0.01, w * self.CONST.BUTTON_WIDTH, h * self.CONST.BUTTON_HEIGHT, 10, 10)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Back", w * 0.01, h * 0.015, w * self.CONST.BUTTON_WIDTH, "center")
        Particles.draw(self.particles)
    elseif self.state == "edit" then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("Deck Editor", 0, h * 0.05, w, "center", 0, 1.5, 1.5)
        local cw, ch = w * self.CONST.CARD_WIDTH, h * self.CONST.CARD_HEIGHT
        local marginX, marginY = w * 0.05, h * 0.15
        for i, card in ipairs(self.cards) do
            local x = marginX + ((i - 1) % 4) * (cw + w * 0.02)
            local y = marginY + math.floor((i - 1) / 4) * (ch + h * 0.02)
            Card.new(card.name, card.attack, card.cost, card.description):draw(x, y, cw, ch, i == self.selectedCardToDelete)
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
        love.graphics.rectangle("fill", w * 0.01, h * 0.01, w * self.CONST.BUTTON_WIDTH, h * self.CONST.BUTTON_HEIGHT, 10, 10)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Back", w * 0.01, h * 0.015, w * self.CONST.BUTTON_WIDTH, "center")
    elseif self.state == "create" then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf(self.editingCardIndex and "Edit Card" or "Create New Card", 0, h * 0.1, w, "center", 0, 1.5, 1.5)
        local fields = {
            {label = "Name", key = "name", y = h * 0.25},
            {label = "Attack", key = "attack", y = h * 0.35},
            {label = "Cost", key = "cost", y = h * 0.45},
            {label = "Description", key = "description", y = h * 0.55}
        }
        for _, field in ipairs(fields) do
            love.graphics.setColor(self.selectedField == field.key and {1, 1, 0} or {1, 1, 1})
            love.graphics.printf(field.label .. ": " .. self.newCard[field.key], w * 0.15, field.y, w * 0.7, "left")
        end
        love.graphics.setColor(0.4, 0.6, 0.8)
        love.graphics.rectangle("fill", w * 0.45, h * 0.75, w * self.CONST.BUTTON_WIDTH, h * self.CONST.BUTTON_HEIGHT, 10, 10)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Save", w * 0.45, h * 0.76, w * self.CONST.BUTTON_WIDTH, "center")
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
    SoundManager.playSound("button_click")
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
                        table.insert(self.particles, Particles.new(enemyX + enemyWidth / 2, h * 0.05 + h * self.CONST.INFO_HEIGHT / 2, 10))
                        self.selectedCardIndex = nil
                        self.selectedEnemyIndex = nil
                        self:checkGameState()
                    end
                    break
                end
            end
        end
    elseif self.state == "edit" then
        if Utils.isMouseOver(w * 0.01, h * 0.01, w * self.CONST.BUTTON_WIDTH, h * self.CONST.BUTTON_HEIGHT) then
            self.state = "menu"
        else
            local cw, ch = w * self.CONST.CARD_WIDTH, h * self.CONST.CARD_HEIGHT
            local marginX, marginY = w * 0.05, h * 0.15
            for i, card in ipairs(self.cards) do
                local x = marginX + ((i - 1) % 4) * (cw + w * 0.02)
                local y = marginY + math.floor((i - 1) / 4) * (ch + h * 0.02)
                if Utils.isMouseOver(x + cw - 20, y, 20, 20) then
                    if self.selectedCardToDelete == i then
                        self:deleteCard(i)
                    else
                        self.selectedCardToDelete = i
                    end
                    break
                elseif Utils.isMouseOver(x + cw - 40, y, 20, 20) then
                    self:startEditingCard(i)
                    break
                elseif Utils.isMouseOver(x, y, cw, ch) then
                    self.selectedCardToDelete = nil
                    break
                end
            end
        end
    elseif self.state == "create" then
        if Utils.isMouseOver(w * 0.01, h * 0.01, w * self.CONST.BUTTON_WIDTH, h * self.CONST.BUTTON_HEIGHT) then
            self.state = "edit"
            self.editingCardIndex = nil
            self.newCard = {name = "", attack = "", cost = "", description = ""}
        elseif Utils.isMouseOver(w * 0.15, h * 0.25, w * 0.7, h * 0.05) then self.selectedField = "name"
        elseif Utils.isMouseOver(w * 0.15, h * 0.35, w * 0.7, h * 0.05) then self.selectedField = "attack"
        elseif Utils.isMouseOver(w * 0.15, h * 0.45, w * 0.7, h * 0.05) then self.selectedField = "cost"
        elseif Utils.isMouseOver(w * 0.15, h * 0.55, w * 0.7, h * 0.05) then self.selectedField = "description"
        elseif Utils.isMouseOver(w * 0.45, h * 0.75, w * self.CONST.BUTTON_WIDTH, h * self.CONST.BUTTON_HEIGHT) then self:saveNewCard() end
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
    elseif self.state == "create" then
        local utf8 = require("utf8") -- Локальная зависимость для обработки текста
        if key == "tab" then
            local fieldOrder = {"name", "attack", "cost", "description"}
            for i, field in ipairs(fieldOrder) do
                if field == self.selectedField then
                    self.selectedField = fieldOrder[(i % #fieldOrder) + 1]
                    break
                end
            end
        elseif key == "return" then
            self:saveNewCard()
        elseif key == "backspace" then
            local byteoffset = utf8.offset(self.newCard[self.selectedField], -1)
            if byteoffset then
                self.newCard[self.selectedField] = string.sub(self.newCard[self.selectedField], 1, byteoffset - 1)
            end
        end
    end
end

function Game:textinput(t)
    if self.state == "create" then
        self.newCard[self.selectedField] = self.newCard[self.selectedField] .. t
    end
end

return Game