local Particles = {}

function Particles.new(x, y, count) -- Создание частиц
    local particles = {}
    for i = 1, count do
        table.insert(particles, {
            x = x,
            y = y,
            vx = math.random(-100, 100),
            vy = math.random(-100, 100),
            life = math.random(0.5, 1)
        })
    end
    return particles
end

function Particles.update(particleGroups, dt) -- Обновление частиц
    for i = #particleGroups, 1, -1 do
        local group = particleGroups[i]
        for j = #group, 1, -1 do
            local p = group[j]
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.life = p.life - dt
            if p.life <= 0 then
                table.remove(group, j)
            end
        end
        if #group == 0 then
            table.remove(particleGroups, i)
        end
    end
end

function Particles.draw(particleGroups) -- Отрисовка частиц
    love.graphics.setColor(1, 0, 0, 0.7)
    for _, group in ipairs(particleGroups) do
        for _, p in ipairs(group) do
            love.graphics.circle("fill", p.x, p.y, p.life * 5)
        end
    end
end

return Particles