local Enemy = {} -- Создаём таблицу для класса Enemy
Enemy.__index = Enemy

function Enemy.new(name, health, attack) -- Конструктор нового врага
    local self = setmetatable({}, Enemy)
    self.name = name
    self.health = health or 30
    self.attack = attack or 2
    self.defending = false
    self.hitAnimation = 0
    return self
end

function Enemy:drawInfo(x, y, w, h) -- Отрисовка информации
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

function Enemy:playTurn(target) -- Ход врага
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

function Enemy:update(dt) -- Обновление врага
    if self.hitAnimation > 0 then
        self.hitAnimation = self.hitAnimation - dt * 2
    end
end

return Enemy