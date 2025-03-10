local Hand = {} -- Создаём таблицу для класса Hand
Hand.__index = Hand

function Hand.new() -- Конструктор новой руки
    return setmetatable({cards = {}}, Hand)
end

function Hand:addCard(card) -- Добавление карты
    if card then table.insert(self.cards, card) end
end

function Hand:removeCard(index) -- Удаление карты
    return table.remove(self.cards, index)
end

function Hand:draw(x, y, w, h, selectedIndex) -- Отрисовка руки
    local totalWidth = #self.cards * w + (#self.cards - 1) * (w * 0.33)
    local startX = x - totalWidth / 2
    for i, card in ipairs(self.cards) do
        local cardX = startX + (i - 1) * (w + w * 0.33)
        card:draw(cardX, y, w, h, i == selectedIndex)
    end
end

return Hand