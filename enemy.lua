local SpriteGenerator = require("sprite_generator")
local SoundManager = require("sound_manager")

local Enemy = {}
Enemy.__index = Enemy

-- Sprite configuration
local SPRITE_PIXEL_SIZE = 4
local SPRITE_SCALE = 2

-- Enemy types and their properties
local ENEMY_TYPES = {
    slime = { health = 20, attack = 2, sprite = "slime.txt" },
    skeleton = { health = 30, attack = 3, sprite = "skeleton.txt" },
    ghost = { health = 25, attack = 4, sprite = "ghost.txt" }
}

function Enemy.new(enemyType)
    local self = setmetatable({}, Enemy)
    
    -- Get enemy properties from type
    local typeData = ENEMY_TYPES[enemyType] or ENEMY_TYPES.slime
    self.name = enemyType:gsub("^%l", string.upper)
    self.health = typeData.health
    self.attack = typeData.attack
    self.defending = false
    self.hitAnimation = 0
    self.bounceOffset = 0
    self.bounceSpeed = 2
    self.bounceTime = 0
    
    -- Load sprite
    local spritePath = "resources/enemies/" .. typeData.sprite
    self.sprite = SpriteGenerator.generateSprite(spritePath, SPRITE_PIXEL_SIZE)
    self.spriteWidth = self.sprite:getWidth() * SPRITE_SCALE
    self.spriteHeight = self.sprite:getHeight() * SPRITE_SCALE
    
    return self
end

function Enemy:drawInfo(x, y, w, h)
    -- Draw info panel background
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", x + 5, y + 5, w, h, 8, 8)
    love.graphics.setColor(self.defending and {0.8, 0.8, 0.8, 0.9} or {0.8, 0.5, 0.7, 0.9})
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("line", x, y, w, h, 8, 8)
    
    -- Draw sprite
    love.graphics.setColor(1, 1, 1, 1)
    local spriteX = x + (w - self.spriteWidth) / 2
    local spriteY = y + h * 0.2 + self.bounceOffset
    
    if self.hitAnimation > 0 then
        love.graphics.setColor(1, 0.5, 0.5, 1)
    elseif self.defending then
        love.graphics.setColor(0.8, 0.8, 1, 1)
    end
    
    love.graphics.draw(self.sprite, spriteX, spriteY, 0, SPRITE_SCALE, SPRITE_SCALE)
    
    -- Draw status effects
    if self.hitAnimation > 0 then
        love.graphics.setColor(1, 0, 0, self.hitAnimation)
        love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    end
    
    -- Draw text info
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(self.name .. " HP: " .. self.health, x + w * 0.05, y + h * 0.05, w * 0.9, "left")
    love.graphics.printf("ATK: " .. self.attack, x + w * 0.05, y + h * 0.8, w * 0.9, "left")
    
    if self.defending then
        love.graphics.setColor(0, 0, 0.8)
        love.graphics.printf("Defending", x + w * 0.05, y + h * 0.9, w * 0.9, "left")
    end
    
    if not self:isAlive() then
        love.graphics.setColor(1, 0, 0, 0.7)
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
        SoundManager.playSound("enemy_hit")
        return true
    else
        self.defending = true
        SoundManager.playSound("enemy_defend")
        return false
    end
end

function Enemy:isAlive() -- Проверка жизни
    return self.health > 0
end

function Enemy:update(dt)
    -- Update hit animation
    if self.hitAnimation > 0 then
        self.hitAnimation = self.hitAnimation - dt * 2
        if self.health <= 0 and self.hitAnimation <= 0 then
            SoundManager.playSound("enemy_death")
        end
    end
    
    -- Update bounce animation
    self.bounceTime = self.bounceTime + dt * self.bounceSpeed
    self.bounceOffset = math.sin(self.bounceTime) * 5
    
    -- Add slight wobble when defending
    if self.defending then
        self.bounceOffset = self.bounceOffset + math.sin(self.bounceTime * 2) * 2
    end
end

return Enemy