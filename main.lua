-- Main game file
require "player"
require "enemy"
require "card"

function love.load()
    -- Initialize game state
    math.randomseed(os.time())
    player = Player.new(50, 3) -- 50 HP, 3 energy
    current_enemy = Enemy.new("Goblin", 20, 2) -- Name, HP, Strength
    game_state = "combat" -- Can be "combat", "map", "shop", etc.
    font = love.graphics.newFont(20)
    love.graphics.setFont(font)
    
    -- Load the background image
    background = love.graphics.newImage("resources/images/background.jpg") -- Assumes background.png is in the project folder
    
    -- Load the player sprite
    player_sprite = love.graphics.newImage("resources/images/player.jpg") -- Assumes player_sprite.png is in the project folder
end

function love.update(dt)
    if game_state == "combat" then
        if current_enemy.hp <= 0 then
            game_state = "victory"
        elseif player.hp <= 0 then
            game_state = "defeat"
        end
    end
end

function love.draw()
    -- Draw the background first (scaled to window size)
    love.graphics.draw(background, 0, 0, 0, love.graphics.getWidth() / background:getWidth(), love.graphics.getHeight() / background:getHeight())
    
    if game_state == "combat" then
        -- Draw player sprite (facing right, no scaling flipped, positioned left side)
        love.graphics.draw(player_sprite, 50, 150, 0, 0.2, 0.2) -- x=50, y=150, no rotation, scale=1
        
        -- Draw player stats above or near the sprite
        love.graphics.print("Player HP: " .. player.hp .. " Energy: " .. player.energy, 10, 10)
        
        -- Draw enemy
        love.graphics.print(current_enemy.name .. " HP: " .. current_enemy.hp, 400, 10)
        love.graphics.print("Intent: Attack for " .. current_enemy.strength, 400, 40)
        
        -- Draw hand
        for i, card in ipairs(player.hand) do
            love.graphics.rectangle("line", 10 + (i-1)*110, 400, 100, 150)
            love.graphics.print(card.name .. "\nCost: " .. card.cost, 15 + (i-1)*110, 410)
        end
    elseif game_state == "victory" then
        love.graphics.print("Victory! Enemy defeated.", 300, 300)
    elseif game_state == "defeat" then
        love.graphics.print("Defeat! You died.", 300, 300)
    end
end

function love.keypressed(key)
    if game_state == "combat" then
        if key == "1" and player:can_play_card(1) then
            player:play_card(1, current_enemy)
        elseif key == "2" and player:can_play_card(2) then
            player:play_card(2, current_enemy)
        elseif key == "e" then
            player:end_turn(current_enemy)
        end
    elseif game_state == "victory" or game_state == "defeat" then
        if key == "r" then
            love.load() -- Restart
        end
    end
end