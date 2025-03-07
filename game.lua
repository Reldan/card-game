game = {
    state = "combat",
    player = nil,
    current_enemy = nil,
    selected_card = nil,
    shader_enabled = false,
    shader_time = 0,
    cursor_x = 0,
    cursor_y = 0
}

function game.load()
    game.player = Player.new(50, 3)
    game.current_enemy = Enemy.new("Goblin", 20, 2)
    game.selected_card = nil
    game.shader_enabled = false
    game.shader_time = 0
    love.mouse.setVisible(false)
    game.cursor_x, game.cursor_y = love.mouse.getPosition()
end

function game.update(dt)
    if game.state == "combat" then
        -- Update cursor and sparks
        game.cursor_x, game.cursor_y = love.mouse.getPosition()
        assets.sparks:setPosition(game.cursor_x, game.cursor_y)
        assets.sparks:update(dt)
        
        -- Update shader time
        game.shader_time = game.shader_time + dt
        
        -- Check win/loss conditions
        if game.current_enemy.hp <= 0 then
            game.state = "victory"
        elseif game.player.hp <= 0 then
            game.state = "defeat"
        end
    end
end