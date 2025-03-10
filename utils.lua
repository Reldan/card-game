local Utils = {}

function Utils.serializeTable(t, indent) -- Сериализация таблицы
    indent = indent or ""
    local result = "{\n"
    for key, value in pairs(t) do
        local keyStr = type(key) == "string" and '["' .. key .. '"]' or "[" .. tostring(key) .. "]"
        if type(value) == "table" then
            result = result .. indent .. "  " .. keyStr .. " = " .. Utils.serializeTable(value, indent .. "  ") .. ",\n"
        elseif type(value) == "string" then
            result = result .. indent .. "  " .. keyStr .. ' = "' .. value .. '",\n'
        else
            result = result .. indent .. "  " .. keyStr .. " = " .. tostring(value) .. ",\n"
        end
    end
    return result .. indent .. "}"
end

function Utils.isMouseOver(x, y, w, h) -- Проверка мыши
    local mx, my = love.mouse.getPosition()
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

return Utils