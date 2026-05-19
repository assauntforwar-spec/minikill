-- dash.lua
local dash = {}

local afterimages = {}
local particles = {}

function dash.createAfterimage(x, y)
    local img = {
        x = x,
        y = y,
        life = 0.2,
        maxLife = 0.2
    }
    table.insert(afterimages, img)
end

function dash.createParticles(x, y, angle)
    for i = 1, 8 do
        local spread = (i - 4.5) * 0.3
        local p = {
            x = x,
            y = y,
            vx = math.cos(angle + spread) * 200,
            vy = math.sin(angle + spread) * 200,
            life = 0.3,
            maxLife = 0.3
        }
        table.insert(particles, p)
    end
end

function dash.update(dt)
    for i = #afterimages, 1, -1 do
        local img = afterimages[i]
        img.life = img.life - dt
        if img.life <= 0 then
            table.remove(afterimages, i)
        end
    end
    
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        end
    end
end

function dash.draw(playerImg)
    for _, img in ipairs(afterimages) do
        local alpha = img.life / img.maxLife * 0.4
        love.graphics.setColor(0.3, 0.7, 1, alpha)
        love.graphics.draw(playerImg, img.x, img.y, 0, 0.15, 0.15, 223, 223)
    end
    
    for _, p in ipairs(particles) do
        local alpha = p.life / p.maxLife
        local size = 3 * alpha
        love.graphics.setColor(0.3, 0.7, 1, alpha)
        love.graphics.circle("fill", p.x, p.y, size)
    end
end

function dash.clear()
    afterimages = {}
    particles = {}
end

return dash