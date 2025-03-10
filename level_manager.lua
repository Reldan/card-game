local Enemy = require("enemy") -- Зависимость от Enemy
local LevelManager = {} -- Создаём таблицу для класса LevelManager
LevelManager.__index = LevelManager

function LevelManager.new() -- Конструктор
    local self = setmetatable({}, LevelManager)
    self.levels = {
        {enemies = {Enemy.new("Goblin", 20, 2)}},
        {enemies = {Enemy.new("Orc", 30, 3), Enemy.new("Troll", 25, 2)}},
        {enemies = {Enemy.new("Dragon", 40, 4), Enemy.new("Giant", 35, 3)}}
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