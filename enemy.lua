local SpriteGenerator = require("sprite_generator")

local Enemy = {}
Enemy.__index = Enemy
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

function Enemy:isAlive() -- Проверка жизни
    return self.health > 0
end

function Enemy:update(dt)
    -- Update hit animation
    if self.hitAnimation > 0 then
        self.hitAnimation = self.hitAnimation - dt * 2
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