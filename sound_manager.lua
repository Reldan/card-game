local SoundManager = {
    sounds = {},
    music = nil,
    volume = {
        master = 1.0,
        sfx = 0.7,
        music = 0.5
    }
}

-- Initialize all game sounds
function SoundManager.init()
    -- Card sounds
    SoundManager.sounds.cardPlay = love.audio.newSource("resources/sounds/card_play.wav", "static")
    SoundManager.sounds.cardDraw = love.audio.newSource("resources/sounds/card_draw.wav", "static")
    
    -- Combat sounds
    SoundManager.sounds.hit = love.audio.newSource("resources/sounds/hit.wav", "static")
    SoundManager.sounds.defend = love.audio.newSource("resources/sounds/defend.wav", "static")
    SoundManager.sounds.victory = love.audio.newSource("resources/sounds/victory.wav", "static")
    SoundManager.sounds.defeat = love.audio.newSource("resources/sounds/defeat.wav", "static")
    
    -- Enemy sounds
    SoundManager.sounds.enemyHit = love.audio.newSource("resources/sounds/enemy_hit.wav", "static")
    SoundManager.sounds.enemyDefend = love.audio.newSource("resources/sounds/enemy_defend.wav", "static")
    SoundManager.sounds.enemyDeath = love.audio.newSource("resources/sounds/enemy_death.wav", "static")
    
    -- UI sounds
    SoundManager.sounds.buttonHover = love.audio.newSource("resources/sounds/button_hover.wav", "static")
    SoundManager.sounds.buttonClick = love.audio.newSource("resources/sounds/button_click.wav", "static")
    
    -- Background music
    SoundManager.music = love.audio.newSource("resources/sounds/background.mp3", "stream")
    SoundManager.music:setLooping(true)
    
    -- Set initial volumes
    for _, sound in pairs(SoundManager.sounds) do
        sound:setVolume(SoundManager.volume.sfx * SoundManager.volume.master)
    end
    SoundManager.music:setVolume(SoundManager.volume.music * SoundManager.volume.master)
end

function SoundManager.playSound(soundName)
    if SoundManager.sounds[soundName] then
        -- Clone the source to allow overlapping sounds
        local clone = SoundManager.sounds[soundName]:clone()
        clone:setVolume(SoundManager.volume.sfx * SoundManager.volume.master)
        clone:play()
    end
end

function SoundManager.playMusic()
    if SoundManager.music and not SoundManager.music:isPlaying() then
        SoundManager.music:play()
    end
end

function SoundManager.stopMusic()
    if SoundManager.music then
        SoundManager.music:stop()
    end
end

function SoundManager.setVolume(category, value)
    SoundManager.volume[category] = value
    
    if category == "master" or category == "sfx" then
        for _, sound in pairs(SoundManager.sounds) do
            sound:setVolume(SoundManager.volume.sfx * SoundManager.volume.master)
        end
    end
    
    if category == "master" or category == "music" then
        SoundManager.music:setVolume(SoundManager.volume.music * SoundManager.volume.master)
    end
end

return SoundManager
