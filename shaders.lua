local Shaders = {}

-- Glow shader for cards
Shaders.cardGlow = love.graphics.newShader[[
    extern number glowStrength;
    extern vec3 glowColor;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);
        vec4 glow = vec4(glowColor, 1.0) * glowStrength;
        return pixel * color + glow * (1.0 - pixel.a);
    }
]]

-- Wave effect shader for background
Shaders.backgroundWave = love.graphics.newShader[[
    extern number time;
    extern number amplitude;
    extern number frequency;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 tc = texture_coords;
        tc.x += sin(tc.y * frequency + time) * amplitude;
        return Texel(texture, tc) * color;
    }
]]

-- Card hover effect shader
Shaders.cardHover = love.graphics.newShader[[
    extern number time;
    extern number hoverStrength;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);
        float brightness = 1.0 + sin(time * 2.0) * 0.1 * hoverStrength;
        return pixel * color * vec4(brightness, brightness, brightness, 1.0);
    }
]]

return Shaders
