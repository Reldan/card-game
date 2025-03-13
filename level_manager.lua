local Enemy = require("enemy")
local LevelManager = {}
LevelManager.__index = LevelManager

function LevelManager.new()
    local self = setmetatable({}, LevelManager)
    
    -- Define levels with new enemy types
    self.levels = {
        -- Level 1: Single slime introduction
        {enemies = {Enemy.new("slime")}},
        
        -- Level 2: Multiple slimes
        {enemies = {Enemy.new("slime"), Enemy.new("slime")}},
        
        -- Level 3: Skeleton introduction
        {enemies = {Enemy.new("skeleton"), Enemy.new("slime")}},
        
        -- Level 4: Ghost introduction
        {enemies = {Enemy.new("ghost"), Enemy.new("slime")}},
        
        -- Level 5: Mixed enemies
        {enemies = {Enemy.new("skeleton"), Enemy.new("ghost")}},
        
        -- Final Level: All enemy types
        {enemies = {Enemy.new("ghost"), Enemy.new("skeleton"), Enemy.new("slime")}}
    }
    
    self.currentLevel = 1
    return self
end

function LevelManager:getCurrentEnemies() -- Получение врагов текущего уровня
    local level = self.levels[self.currentLevel]
    return level and level.enemies or {}
end

function LevelManager:nextLevel() -- Переход на следующий уровень
    self.currentLevel = self.currentLevel + 1
    return self.currentLevel <= #self.levels
end

function LevelManager:getLevelCount() -- Получение числа уровней
    return #self.levels
end

return LevelManager