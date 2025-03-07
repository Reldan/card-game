input = {}

function input.mousepressed(x, y, button)
    if game.state == "combat" and button == 1 then
        for i, card in ipairs(game.player.hand) do
            local card_x, card_y, card_w, card_h = 10 + (i-1)*110, 400, 100, 150
            if x >= card_x and x <= card_x + card_w and y >= card_y and y <= card_y + card_h then
                if game.selected_card == i then
                    if game.player:can_play_card(i) then
                        game.player:play_card(i, game.current_enemy)
                        game.selected_card = nil
                    end
                else
                    game.selected_card = i
                end
                return
            end
        end
        game.selected_card = nil
    end
end

function input.keypressed(key)
    if game.state == "combat" then
        if key == "e" then
            game.player:end_turn(game.current_enemy)
            game.selected_card = nil
        elseif key == "s" then
            game.shader_enabled = not game.shader_enabled
        end
    elseif game.state == "victory" or game.state == "defeat" then
        if key == "r" then
            love.load()
        end
    end
end