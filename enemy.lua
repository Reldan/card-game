Enemy = {}
Enemy.__index = Enemy

function Enemy.new(name, hp, strength)
    local self = setmetatable({}, Enemy)
    self.name = name
    self.hp = hp
    self.strength = strength
    return self
end

function Enemy:attack(target)
    target.hp = target.hp - self.strength
end