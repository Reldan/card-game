local SpriteGenerator = {}

-- Color mapping for ASCII art
local COLOR_MAP = {
    ['.'] = {0, 0, 0, 0},      -- Transparent
    ['G'] = {0, 255, 0, 255},  -- Green
    ['W'] = {255, 255, 255, 255}, -- White
    ['R'] = {255, 0, 0, 255},  -- Red
    ['B'] = {0, 0, 255, 255},  -- Blue
    ['Y'] = {255, 255, 0, 255} -- Yellow
}

function SpriteGenerator.generateSprite(asciiFile, pixelSize)
    -- Read ASCII art file
    local content = love.filesystem.read(asciiFile)
    if not content then
        error("Could not read ASCII art file: " .. asciiFile)
    end

    -- Parse dimensions
    local lines = {}
    for line in content:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    
    local height = #lines
    local width = #lines[1]
    
    -- Create image data
    local imageData = love.image.newImageData(width * pixelSize, height * pixelSize)
    
    -- Convert ASCII to pixels
    for y = 0, height - 1 do
        for x = 0, width - 1 do
            local char = lines[y + 1]:sub(x + 1, x + 1)
            local color = COLOR_MAP[char] or {0, 0, 0, 0}
            
            -- Fill pixel block
            for py = 0, pixelSize - 1 do
                for px = 0, pixelSize - 1 do
                    imageData:setPixel(
                        x * pixelSize + px,
                        y * pixelSize + py,
                        color[1]/255,
                        color[2]/255,
                        color[3]/255,
                        color[4]/255
                    )
                end
            end
        end
    end
    
    return love.graphics.newImage(imageData)
end

return SpriteGenerator
