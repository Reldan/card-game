local Shaders = require("shaders")

local Card = {}
Card.__index = Card

function Card.new(name, attack, cost, description) -- Конструктор новой карты
    local self = setmetatable({}, Card)
    self.name = name
    self.attack = attack
    self.cost = cost
    self.description = description
    return self
end

function Card:draw(x, y, w, h, isSelected)
    -- Create canvas for the card
    local cardCanvas = love.graphics.newCanvas(w + 10, h + 10)
    love.graphics.setCanvas(cardCanvas)
    love.graphics.clear()
    
    -- Draw card base
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", 5, 5, w, h, 10, 10)
    love.graphics.setColor(isSelected and {1, 1, 0.5, 0.9} or {0.9, 0.9, 0.9, 0.8})
    love.graphics.rectangle("fill", 0, 0, w, h, 10, 10)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("line", 0, 0, w, h, 10, 10)
    
    -- Reset canvas and apply shaders
    love.graphics.setCanvas()
    
    if isSelected then
        love.graphics.setShader(Shaders.cardGlow)
    else
        love.graphics.setShader(Shaders.cardHover)
    end
    
    -- Draw the card with shader effects
    love.graphics.draw(cardCanvas, x, y)
    -- Reset shader before drawing text
    love.graphics.setShader()
    
    -- Draw text content
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(self.name, x + 5, y + 5, w - 10, "center")
    love.graphics.printf("ATK: " .. self.attack, x + 5, y + h - 50, w - 10, "left")
    love.graphics.printf("Cost: " .. self.cost, x + 5, y + h - 30, w - 10, "left")
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.printf(self.description, x + 5, y + 30, w - 10, "center")
end

return Card