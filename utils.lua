local Utils = {}

function Utils.isMouseOver(x, y, w, h) -- Проверка мыши
    local mx, my = love.mouse.getPosition()
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

return Utils