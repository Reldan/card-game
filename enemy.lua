Enemy = {}
Enemy.__index = Enemy

function Enemy.new(name, hp, strength, condition)
    local self = setmetatable({}, Enemy)
    self.name = name
    self.hp = hp
    self.strength = strength
    self.condition = condition
    return self
end

function Enemy:attack(target)
    target.hp = target.hp - self.strength
    target:add_condition(self.condition, 1)
end

function Enemy:add_condition(condition, stacks)
    self.conditions = self.conditions or {}
    self.conditions[condition] = math.min((self.conditions[condition] or 0) + stacks, 3)
end