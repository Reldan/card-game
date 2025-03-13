local Hand = {}
Hand.__index = Hand

function Hand.new()
    local self = setmetatable({}, Hand)
    self.cards = {}
    self.debug = true  -- Match player's debug setting
    return self
end

function Hand:addCard(card)
    if self.debug then
        print(string.format("[Hand] Adding card - Current size: %d", #self.cards))
    end
    
    if card then 
        table.insert(self.cards, card)
        
        if self.debug then
            print(string.format("[Hand] Card added - New size: %d", #self.cards))
        end
        return true
    end
    
    if self.debug then
        print("[Hand] Warning: Attempted to add nil card")
    end
    return false
end

function Hand:removeCard(index)
    if self.debug then
        print(string.format("[Hand] Removing card at index %d - Current size: %d", 
            index, #self.cards))
    end
    
    if index < 1 or index > #self.cards then
        if self.debug then
            print("[Hand] Error: Invalid card index")
        end
        return nil
    end
    
    local card = table.remove(self.cards, index)
    
    if self.debug then
        if card then
            print(string.format("[Hand] Card removed - New size: %d", #self.cards))
        else
            print("[Hand] Warning: Failed to remove card")
        end
    end
    
    return card
end

function Hand:draw(x, y, w, h, selectedIndex)
    if #self.cards == 0 then return end
    
    local totalWidth = #self.cards * w + (#self.cards - 1) * (w * 0.33)
    local startX = x - totalWidth / 2
    
    for i, card in ipairs(self.cards) do
        if card then  -- Safety check
            local cardX = startX + (i - 1) * (w + w * 0.33)
            card:draw(cardX, y, w, h, i == selectedIndex)
        elseif self.debug then
            print(string.format("[Hand] Warning: Nil card at index %d", i))
        end
    end
end

return Hand