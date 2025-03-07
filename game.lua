game = {
    state = "combat",
    player = nil,
    current_enemy = nil,
    selected_card = nil,
    shader_enabled = false,
    shader_time = 0,
    cursor_x = 0,
    cursor_y = 0,
    floor = 1,
    room = 1
}

function game.load()
    game.player = Player.new(50, 3)
    game.current_enemy = Enemy.new("Goblin", 20, 2, "Poison")
    game.selected_card = nil
    game.shader_enabled = false
    game.shader_time = 0
    love.mouse.setVisible(false)
    game.cursor_x, game.cursor_y = love.mouse.getPosition()
end

function game.update(dt)
    if game.state == "combat" then
        game.cursor_x, game.cursor_y = love.mouse.getPosition()
        assets.sparks:setPosition(game.cursor_x, game.cursor_y)
        assets.sparks:update(dt)
        game.shader_time = game.shader_time + dt
        
        if game.current_enemy.hp <= 0 then
            game.state = "victory"
            game.room = game.room + 1
        elseif game.player.hp <= 0 then
            game.state = "defeat"
        end
    end
end