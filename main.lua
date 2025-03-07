-- Main game file: Orchestrates the game loop
require "assets"
require "game"
require "render"
require "input"
require "player"
require "enemy"
require "card"

function love.load()
    assets.load()
    game.load()
end

function love.update(dt)
    game.update(dt)
end

function love.draw()
    render.draw()
end

function love.mousepressed(x, y, button)
    input.mousepressed(x, y, button)
end

function love.keypressed(key)
    input.keypressed(key)
end