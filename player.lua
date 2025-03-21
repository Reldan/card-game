local Hand = require("hand")
require("hand_renderer")
local Player = {}
Player.__index = Player

function Player.new()
    local self = setmetatable({}, Player)
    self.energy = 3
    self.maxEnergy = 3
    self.health = 30
    self.deck = {}
    self.discardPile = {}
    self.hand = Hand.new()
    return self
end

function Player:drawInfo(x, y, w, h) -- Отрисовка информации
    love.graphics.setColor(0.2, 0.5, 0.8, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf("HP: " .. self.health, x + w * 0.05, y + h * 0.05, w * 0.9, "left")
    love.graphics.printf("Deck: " .. #self.deck, x + w * 0.05, y + h * 0.25, w * 0.9, "left")
    love.graphics.printf("Discard: " .. #self.discardPile, x + w * 0.05, y + h * 0.45, w * 0.9, "left")
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf("Energy: " .. self.energy .. "/" .. self.maxEnergy, x + w * 0.05, y + h * 0.65, w * 0.9, "left")
end

function Player:endTurn()
    print("\n[End Turn] Starting end turn sequence")
    print(string.format("[End Turn] Initial state - Hand: %d, Deck: %d, Discard: %d",
        #self.hand.cards, #self.deck, #self.discardPile))
    
    -- Reset energy
    self.energy = self.maxEnergy
    
    -- Move current hand to discard pile
    local handSize = #self.hand.cards
    for i = handSize, 1, -1 do
        local card = self.hand:removeCard(i)
        if card then
            table.insert(self.discardPile, card)
        end
    end
    
    print(string.format("[End Turn] After discarding - Hand: %d, Deck: %d, Discard: %d",
        #self.hand.cards, #self.deck, #self.discardPile))
    
    -- Draw new hand
    self:drawCards()
    
    print(string.format("[End Turn] Final state - Hand: %d, Deck: %d, Discard: %d\n",
        #self.hand.cards, #self.deck, #self.discardPile))
    
    -- Verify total card count
    local totalCards = #self.hand.cards + #self.deck + #self.discardPile
    print(string.format("[Card Count] Total cards in game: %d", totalCards))
    if totalCards < 9 then
        print("[WARNING] Cards have been lost! Expected 9 cards total.")
    end
end

function Player:drawCards()
    local Game = require("game")
    local cardsNeeded = Game.CONST.HAND_SIZE - #self.hand.cards
    
    print(string.format("[Draw Cards] Need: %d, Deck: %d, Discard: %d", 
        cardsNeeded, #self.deck, #self.discardPile))
    local totalBefore = #self.hand.cards + #self.deck + #self.discardPile
    print(string.format("[Draw Cards] Total cards before: %d", totalBefore))
    
    -- First check if we need to reshuffle
    if #self.deck < cardsNeeded and #self.discardPile > 0 then
        print("[Draw Cards] Reshuffling deck")
        self:reshuffleDeck()
    end
    
    -- Calculate available cards after potential reshuffle
    local cardsAvailable = #self.deck
    local cardsToDraw = math.min(cardsNeeded, cardsAvailable)
    
    print(string.format("[Draw Cards] Drawing %d cards from deck", cardsToDraw))
    
    -- Draw cards
    local drawnCards = {}
    for i = 1, cardsToDraw do
        local card = table.remove(self.deck)
        if card then
            table.insert(drawnCards, card)
        end
    end
    
    -- Add drawn cards to hand
    for _, card in ipairs(drawnCards) do
        self.hand:addCard(card)
    end
    
    print(string.format("[Draw Cards] Final hand size: %d", #self.hand.cards))
    local totalAfter = #self.hand.cards + #self.deck + #self.discardPile
    print(string.format("[Draw Cards] Total cards after: %d", totalAfter))
end

function Player:drawCard()
    -- Only draw if we have cards in the deck
    if #self.deck > 0 then
        return table.remove(self.deck, 1)
    end
    return nil
end

function Player:reshuffleDeck()
    print(string.format("[Reshuffle] Before - Deck: %d, Discard: %d",
        #self.deck, #self.discardPile))
    
    -- Create a temporary table to store all cards
    local allCards = {}
    
    -- Move all cards from discard to the temporary table
    while #self.discardPile > 0 do
        local card = table.remove(self.discardPile)
        if card then
            table.insert(allCards, card)
        end
    end
    
    -- Move all cards from deck to the temporary table
    while #self.deck > 0 do
        local card = table.remove(self.deck)
        if card then
            table.insert(allCards, card)
        end
    end
    
    -- Shuffle all cards
    for i = #allCards, 2, -1 do
        local j = math.random(i)
        allCards[i], allCards[j] = allCards[j], allCards[i]
    end
    
    -- Move all cards back to deck
    for _, card in ipairs(allCards) do
        table.insert(self.deck, card)
    end
    
    print(string.format("[Reshuffle] After - Deck: %d, Discard: %d",
        #self.deck, #self.discardPile))
end

function Player:isAlive() -- Проверка жизни
    return self.health > 0
end

function Player:playCard(index, target)
    print(string.format("[Play Card] Before - Hand: %d, Deck: %d, Discard: %d",
        #self.hand.cards, #self.deck, #self.discardPile))

    local card = self.hand.cards[index]
    if not card then 
        print("[Play Card] Error: No card at index")
        return false 
    end
    
    -- Check if we can play the card
    if self.energy < card.cost then
        print("[Play Card] Error: Not enough energy")
        return false
    end

    -- Move card to discard pile first
    local playedCard = self.hand:removeCard(index)
    if not playedCard then
        print("[Play Card] Error: Failed to remove card from hand")
        return false
    end
    
    -- Deduct energy cost
    self.energy = self.energy - card.cost
    
    -- Calculate and apply damage
    local damage = card.attack
    if target.defending then
        damage = math.floor(damage * 0.5)
    end
    target.health = target.health - damage
    
    -- Add to discard pile
    table.insert(self.discardPile, playedCard)
    
    print(string.format("[Play Card] After - Hand: %d, Deck: %d, Discard: %d",
        #self.hand.cards, #self.deck, #self.discardPile))
    
    -- Verify total cards
    local totalCards = #self.hand.cards + #self.deck + #self.discardPile
    print(string.format("[Play Card] Total cards: %d", totalCards))
    
    return true
end

return Player