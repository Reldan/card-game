render = {}

function render.draw()
    -- Background with optional shader
    if game.shader_enabled then
        love.graphics.setShader(assets.background_shader)
        assets.background_shader:send("time", game.shader_time)
    end
    love.graphics.draw(assets.background, 0, 0, 0, love.graphics.getWidth() / assets.background:getWidth(), love.graphics.getHeight() / assets.background:getHeight())
    love.graphics.setShader()
    
    if game.state == "combat" then
        -- Player sprite
        love.graphics.draw(assets.player_sprite, 50, 150, 0, assets.player_scale_x, assets.player_scale_y)
        
        -- Player stats
        love.graphics.print("Player HP: " .. game.player.hp .. " Energy: " .. game.player.energy, 10, 10)
        
        -- Enemy (goblin shape)
        love.graphics.setColor(0, 0.5, 0, 1)
        love.graphics.rectangle("fill", 400, 150, 150, 200)
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.circle("fill", 430, 180, 10)
        love.graphics.circle("fill", 470, 180, 10)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(game.current_enemy.name .. " HP: " .. game.current_enemy.hp, 400, 10)
        love.graphics.print("Intent: Attack for " .. game.current_enemy.strength, 400, 40)
        
        -- Hand with selection highlighting
        for i, card in ipairs(game.player.hand) do
            local x, y, w, h = 10 + (i-1)*110, 400, 100, 150
            if game.selected_card == i then
                love.graphics.setColor(1, 1, 0, 0.5)
                love.graphics.rectangle("fill", x-5, y-5, w+10, h+10)
                love.graphics.setColor(1, 1, 1, 1)
            end
            love.graphics.rectangle("line", x, y, w, h)
            love.graphics.print(card.name .. "\nCost: " .. card.cost, x+5, y+10)
        end
        
        -- Sparks and cursor
        love.graphics.draw(assets.sparks, 0, 0)
        love.graphics.circle("fill", game.cursor_x, game.cursor_y, 5)
        
        -- Key legend
        love.graphics.setFont(assets.small_font)
        love.graphics.print("Keys:\nE - End Turn\nS - Toggle Shader\nR - Restart (on win/loss)", 650, 550)
        love.graphics.setFont(assets.font)
    elseif game.state == "victory" then
        love.graphics.print("Victory! Enemy defeated.", 300, 300)
        love.graphics.setFont(assets.small_font)
        love.graphics.print("R - Restart", 700, 580)
        love.graphics.setFont(assets.font)
    elseif game.state == "defeat" then
        love.graphics.print("Defeat! You died.", 300, 300)
        love.graphics.setFont(assets.small_font)
        love.graphics.print("R - Restart", 700, 580)
        love.graphics.setFont(assets.font)
    end
end