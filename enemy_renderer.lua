-- Sprite configuration

local SPRITE_SCALE = 2

function RenderEnemy(enemy, x, y, w, h)
    -- Draw info panel background
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", x + 5, y + 5, w, h, 8, 8)
    love.graphics.setColor(enemy.defending and {0.8, 0.8, 0.8, 0.9} or {0.8, 0.5, 0.7, 0.9})
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("line", x, y, w, h, 8, 8)
    
    -- Draw sprite
    love.graphics.setColor(1, 1, 1, 1)
    local spriteX = x + (w - enemy.spriteWidth) / 2
    local spriteY = y + h * 0.2 + enemy.bounceOffset
    
    if enemy.hitAnimation > 0 then
        love.graphics.setColor(1, 0.5, 0.5, 1)
    elseif enemy.defending then
        love.graphics.setColor(0.8, 0.8, 1, 1)
    end
    
    love.graphics.draw(enemy.sprite, spriteX, spriteY, 0, SPRITE_SCALE, SPRITE_SCALE)
    
    -- Draw status effects
    if enemy.hitAnimation > 0 then
        love.graphics.setColor(1, 0, 0, enemy.hitAnimation)
        love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    end
    
    -- Draw text info
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(enemy.name .. " HP: " .. enemy.health, x + w * 0.05, y + h * 0.05, w * 0.9, "left")
    love.graphics.printf("ATK: " .. enemy.attack, x + w * 0.05, y + h * 0.8, w * 0.9, "left")
    
    if enemy.defending then
        love.graphics.setColor(0, 0, 0.8)
        love.graphics.printf("Defending", x + w * 0.05, y + h * 0.9, w * 0.9, "left")
    end
    
    if not enemy:isAlive() then
        love.graphics.setColor(1, 0, 0, 0.7)
        love.graphics.line(x, y, x + w, y + h)
        love.graphics.line(x + w, y, x, y + h)
    end
end