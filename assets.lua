assets = {}

function assets.load()
    -- Seed random
    math.randomseed(os.time())
    
    -- Fonts
    assets.font = love.graphics.newFont(20)
    assets.small_font = love.graphics.newFont(12)
    love.graphics.setFont(assets.font)
    
    -- Images
    assets.background = love.graphics.newImage("resources/images/background.jpg")
    assets.player_sprite = love.graphics.newImage("resources/images/player.jpg")
    
    -- Player sprite scaling (2x card size: 100x150 -> 200x300)
    assets.player_scale_x = 200 / assets.player_sprite:getWidth()
    assets.player_scale_y = 300 / assets.player_sprite:getHeight()
    
    -- Particle system for cursor sparks
    local canvas = love.graphics.newCanvas(2, 2)
    love.graphics.setCanvas(canvas)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, 2, 2)
    love.graphics.setCanvas()
    local particle_image = love.graphics.newImage(canvas:newImageData())
    assets.sparks = love.graphics.newParticleSystem(particle_image, 100)
    assets.sparks:setParticleLifetime(0.5, 1)
    assets.sparks:setEmissionRate(20)
    assets.sparks:setSpeed(50, 100)
    assets.sparks:setSpread(math.pi)
    assets.sparks:setColors(1, 1, 0, 1, 1, 1, 0, 0)
    assets.sparks:setSizes(0.5, 0)
    
    -- Background shader
    assets.background_shader = love.graphics.newShader[[
        extern number time;
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec2 distorted_coords = texture_coords;
            distorted_coords.x += sin(texture_coords.y * 10.0 + time) * 0.02;
            distorted_coords.y += cos(texture_coords.x * 10.0 + time) * 0.02;
            vec4 pixel = Texel(texture, distorted_coords) * color;
            float glow = 0.2 * (sin(time * 2.0) + 1.0);
            pixel.rgb += vec3(glow * 0.5, glow * 0.3, glow * 0.7);
            return pixel;
        }
    ]]
end