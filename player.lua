Player = {}
Player.__index = Player

function Player.new(hp, energy)
    local self = setmetatable({}, Player)
    self.hp = hp
    self.max_hp = hp
    self.energy = energy
    self.max_energy = energy
    self.deck = {
        Card.new("Flameblade", 1, function(target) target.hp = target.hp - 6; target:add_condition("Fire", 1) end),
        Card.new("Frostbow", 1, function(target) target.hp = target.hp - 4; target:add_condition("Ice", 1) end),
        Card.new("Shockstaff", 1, function(target) target.hp = target.hp - 5; target:add_condition("Electric", 1) end)
    }
    self.hand = {}
    self.scars = 0
    self.prosthetics = {}
    self:draw_hand()
    return self
end

function Player:draw_hand()
    self.hand = {}
    local available = math.min(3 - self.scars, #self.deck)
    for i = 1, math.min(3, available) do
        table.insert(self.hand, self.deck[i])
    end
end

function Player:can_play_card(index)
    local card = self.hand[index]
    return card and self.energy >= card.cost
end

function Player:play_card(index, target)
    local card = self.hand[index]
    if self:can_play_card(index) then
        card.effect(target)
        self.energy = self.energy - card.cost
        table.remove(self.hand, index)
        self:check_synergies(target)
    end
end

function Player:end_turn(enemy)
    enemy:attack(self)
    self.energy = self.max_energy
    self:resolve_conditions()
    self:draw_hand()
    self:check_scars()
end

function Player:add_condition(condition, stacks)
    self.conditions = self.conditions or {}
    self.conditions[condition] = math.min((self.conditions[condition] or 0) + stacks, 3)
end

function Player:resolve_conditions()
    if self.conditions then
        if self.conditions.Fire then
            self.hp = self.hp - self.conditions.Fire * 2
            self.conditions.Fire = self.conditions.Fire - 1
            if self.conditions.Fire <= 0 then self.conditions.Fire = nil end
        end
        if self.conditions.Ice then
            self.max_energy = self.max_energy - self.conditions.Ice
            self.conditions.Ice = self.conditions.Ice - 1
            if self.conditions.Ice <= 0 then self.conditions.Ice = nil end
        end
        if self.conditions.Electric then
            self.hp = self.hp - self.conditions.Electric
            self.conditions.Electric = self.conditions.Electric - 1
            if self.conditions.Electric <= 0 then self.conditions.Electric = nil end
        end
        if self.conditions.Poison then
            self.max_hp = self.max_hp - self.conditions.Poison * 2
            self.conditions.Poison = self.conditions.Poison - 1
            if self.conditions.Poison <= 0 then self.conditions.Poison = nil; self.max_hp = 50 end
        end
    end
end

function Player:check_synergies(target)
    -- Simplified synergy check (expand as needed)
    if self.conditions and target.conditions then
        if self.conditions.Fire and target.conditions.Ice then
            target.hp = target.hp - 10
            self.conditions.Fire = nil
            target.conditions.Ice = nil
        end
    end
end

function Player:check_scars()
    if self.hp < self.max_hp * 0.25 and self.scars < 3 then
        self.scars = self.scars + 1
        table.insert(self.prosthetics, "Iron Arm") -- Simplified; randomize later
        self.deck[self.scars] = nil -- Remove a weapon
    end
end