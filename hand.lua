local Hand = {}
Hand.__index = Hand

function Hand.new()
    local self = setmetatable({}, Hand)
    self.cards = {}
    return self
end

function Hand:addCard(card)
    print(string.format("[Hand] Adding card - Current size: %d", #self.cards))
    
    if card then 
        table.insert(self.cards, card)
        
        print(string.format("[Hand] Card added - New size: %d", #self.cards))
        return true
    end
    
    print("[Hand] Warning: Attempted to add nil card")
    return false
end

function Hand:removeCard(index)
    print(string.format("[Hand] Removing card at index %d - Current size: %d", index, #self.cards))
    
    if index < 1 or index > #self.cards then
        print("[Hand] Error: Invalid card index")
        return nil
    end
    
    local card = table.remove(self.cards, index)
    
    if card then
        print(string.format("[Hand] Card removed - New size: %d", #self.cards))
    else
        print("[Hand] Warning: Failed to remove card")
    end
    
    return card
end

return Hand