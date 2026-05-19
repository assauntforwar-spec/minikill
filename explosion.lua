-- explosion.lua
local explosion = {}

local frames = {}
local frameCount = 17
local explosions = {}

function explosion.load()
    for i = 1, frameCount do
        local filename = "explosion/frame_" .. string.format("%04d", i) .. ".png"
        if love.filesystem.getInfo(filename) then
            frames[i] = love.graphics.newImage(filename)
        end
    end
    if love.filesystem.getInfo("boom.ogg") then
        explosion.sound = love.audio.newSource("boom.ogg", "static")
        explosion.sound:setVolume(0.7)
    end
end

function explosion.create(x, y, size)
    local exp = {
        x = x,
        y = y,
        frame = 1,
        timer = 0,
        frameTime = 0.06,
        size = size or 1,
        done = false
    }
    table.insert(explosions, exp)
    if explosion.sound then
        explosion.sound:stop()
        explosion.sound:play()
    end
    return exp
end

function explosion.update(dt)
    for i = #explosions, 1, -1 do
        local exp = explosions[i]
        exp.timer = exp.timer + dt
        if exp.timer >= exp.frameTime then
            exp.timer = exp.timer - exp.frameTime
            exp.frame = exp.frame + 1
            if exp.frame > #frames then
                exp.done = true
                table.remove(explosions, i)
            end
        end
    end
end

function explosion.draw()
    for _, exp in ipairs(explosions) do
        local img = frames[exp.frame]
        if img then
            local scale = exp.size
            local w = img:getWidth() * scale
            local h = img:getHeight() * scale
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(img, exp.x, exp.y, 0, scale, scale, img:getWidth()/2, img:getHeight()/2)
        end
    end
end

return explosion