require("card_renderer")

function RenderHand(hand, x, y, w, h, selectedIndex)
    if #hand.cards == 0 then return end
    
    local totalWidth = #hand.cards * w + (#hand.cards - 1) * (w * 0.33)
    local startX = x - totalWidth / 2
    
    for i, card in ipairs(hand.cards) do
        if card then  -- Safety check
            local cardX = startX + (i - 1) * (w + w * 0.33)
            RenderCard(card, cardX, y, w, h, i == selectedIndex)
        else
            print(string.format("[Hand] Warning: Nil card at index %d", i))
        end
    end
end