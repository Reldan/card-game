Player = {}
Player.__index = Player

function Player.new(hp, energy)
    local self = setmetatable({}, Player)
    self.hp = hp
    self.max_energy = energy
    self.energy = energy
    self.deck = {
        Card.new("Attack", 1, function(target) target.hp = target.hp - 6 end),
        Card.new("Defend", 1, function(target) target.hp = target.hp + 5 end) -- Simplified as heal
    }
    self.hand = {}
    self:draw_hand()
    return self
end

function Player:draw_hand()
    self.hand = {}
    for i = 1, math.min(5, #self.deck) do
        table.insert(self.hand, self.deck[math.random(#self.deck)])
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
    end
end

function Player:end_turn(enemy)
    enemy:attack(self)
    self.energy = self.max_energy
    self:draw_hand()
end