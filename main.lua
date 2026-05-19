function love.load()
    music = require("music")
    music.load()
    dash = require("cooldasheffect")
    explosion = require("explosion")
    explosion.load()
    love.window.setMode(800, 600)
    love.window.setTitle("ULTRAMINIKILL - Top Down")
    love.mouse.setVisible(false)
    
    gameState = "menu"
    
    player = {
        x = 400, y = 300,
        w = 20, h = 20,
        speed = 300,
        angle = 0,
        
        dashing = false,
        dashCooldown = 0,
        dashTimer = 0,
        dashSpeed = 700,
        dashInvuln = false,
        
        health = 100,
        parryWindow = 0,
        parryRadius = 60
    }
    impactFreeze = 0
    impactFlash = 0
    bullets = {}
    bulletSpeed = 700
    bulletCooldown = 0
    bulletCooldownTime = 0.12
    
    enemyProjectiles = {}
    
    turret = {
        x = 400, y = 100,
        shootTimer = 0,
        shootDelay = 1.2
    }
    
    turret2 = {
        x = 200, y = 400,
        shootTimer = 0.5,
        shootDelay = 1.5
    }
    
    turrets = {turret, turret2}
    
    player.img = love.graphics.newImage("v1.png")
    turretImg = love.graphics.newImage("gabriel.png")
    parrySound = love.audio.newSource("parry.ogg", "static")
    
    menuFlash = 0
    music.playMenu()
end

function love.update(dt)
    if dt > 0.05 then dt = 0.05 end
    
    if gameState == "menu" then
        menuFlash = menuFlash + dt * 3
        return
    end
    
    if gameState == "paused" then
        return
    end
    
    if impactFreeze <= 0 then
        explosion.update(dt)
        dash.update(dt)
    end
    
    if impactFreeze > 0 then
        impactFreeze = impactFreeze - dt
        return
    end
    
    if impactFlash > 0 then
        impactFlash = impactFlash - dt * 10
    end
    
    local mx, my = love.mouse.getPosition()
    player.angle = math.atan2(my - player.y, mx - player.x)
    
    local moveX = 0
    local moveY = 0
    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then moveY = moveY - 1 end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then moveY = moveY + 1 end
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then moveX = moveX - 1 end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then moveX = moveX + 1 end
    
    if moveX ~= 0 and moveY ~= 0 then
        moveX = moveX * 0.707
        moveY = moveY * 0.707
    end
    
    if love.keyboard.isDown("lshift") and not player.dashing and player.dashCooldown <= 0 then
        player.dashing = true
        player.dashTimer = 0.12
        player.dashCooldown = 0.6
        player.dashInvuln = true
        dash.createParticles(player.x, player.y, player.angle)
        if moveX == 0 and moveY == 0 then
            player.dashDx = math.cos(player.angle)
            player.dashDy = math.sin(player.angle)
        else
            local len = math.sqrt(moveX^2 + moveY^2)
            player.dashDx = moveX / len
            player.dashDy = moveY / len
        end
    end
    
    if player.dashing then
        player.dashTimer = player.dashTimer - dt
        if player.dashTimer <= 0 then
            player.dashing = false
            player.dashInvuln = false
        dash.createAfterimage(player.x, player.y)
        end
    end
    if player.dashCooldown > 0 then
        player.dashCooldown = player.dashCooldown - dt
    end
    
    if love.mouse.isDown(2) and player.parryWindow <= 0 then
        player.parryWindow = 0.12
    end
    if player.parryWindow > 0 then
        player.parryWindow = player.parryWindow - dt
        for i = #enemyProjectiles, 1, -1 do
            local p = enemyProjectiles[i]
            local dist = math.sqrt((p.x - player.x)^2 + (p.y - player.y)^2)
            if dist < player.parryRadius and not p.parried then
                p.vx = -p.vx * 1.2
                p.vy = -p.vy * 1.2
                p.parried = true
                impactFreeze = 0.05
                impactFlash = 1.0
                parrySound:stop()
                parrySound:play()
            end
        end
    end
    if love.mouse.isDown(1) and bulletCooldown <= 0 then
        local angle = player.angle
        local b = {
            x = player.x, y = player.y,
            vx = math.cos(angle) * bulletSpeed,
            vy = math.sin(angle) * bulletSpeed,
            life = 1.2,
            maxLife = 1.2,
            angle = angle
        }
        table.insert(bullets, b)
        bulletCooldown = 0.25
    end
    if bulletCooldown > 0 then bulletCooldown = bulletCooldown - dt end
    
    local speed = player.speed
    if player.dashing then speed = player.dashSpeed end
    
    if not player.dashing then
        player.x = player.x + moveX * speed * dt
        player.y = player.y + moveY * speed * dt
    else
        player.x = player.x + player.dashDx * speed * dt
        player.y = player.y + player.dashDy * speed * dt
    end
    
    player.x = math.max(20, math.min(780, player.x))
    player.y = math.max(20, math.min(580, player.y))
    
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt
        if b.life <= 0 or b.x < 0 or b.x > 800 or b.y < 0 or b.y > 600 then
            table.remove(bullets, i)
        else
            for _, t in ipairs(turrets) do
                local dist = math.sqrt((b.x - t.x)^2 + (b.y - t.y)^2)
                if dist < 20 then
                    t.hp = (t.hp or 3) - 1
                    table.remove(bullets, i)
                    break
                end
            end
        end
    end
    
    for i = #enemyProjectiles, 1, -1 do
        local p = enemyProjectiles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(enemyProjectiles, i)
        else
            local dist = math.sqrt((p.x - player.x)^2 + (p.y - player.y)^2)
            if dist < 15 and not player.dashInvuln then
                player.health = player.health - 15
                table.remove(enemyProjectiles, i)
            elseif p.parried then
                for j, t in ipairs(turrets) do
                    local td = math.sqrt((p.x - t.x)^2 + (p.y - t.y)^2)
                    if td < 30 then
                        -- Урон всем турелям в радиусе взрыва
                        for _, tt in ipairs(turrets) do
                            local distToExplosion = math.sqrt((p.x - tt.x)^2 + (p.y - tt.y)^2)
                            if distToExplosion < 80 then
                                tt.hp = (tt.hp or 3) - 2
                            end
                        end
                        -- Создаём взрыв
                        explosion.create(p.x, p.y, 0.5)
                        table.remove(enemyProjectiles, i)
                        break
                    end
                end
            end
        end
    end
    
    for i = #turrets, 1, -1 do
        local t = turrets[i]
        if (t.hp or 3) <= 0 then
            table.remove(turrets, i)
        else
            t.shootTimer = t.shootTimer + dt
            if t.shootTimer >= t.shootDelay then
                t.shootTimer = 0
                local angle = math.atan2(player.y - t.y, player.x - t.x)
                local p = {
                    x = t.x, y = t.y,
                    vx = math.cos(angle) * 250,
                    vy = math.sin(angle) * 250,
                    life = 3,
                    parried = false
                }
                table.insert(enemyProjectiles, p)
            end
        end
    end
end

function love.draw()
    love.graphics.setBackgroundColor(0.08, 0.08, 0.1)
    
    if gameState == "menu" then
        drawMenu()
        return
    end
    
    love.graphics.setColor(0.2, 0.2, 0.2)
    for x = 0, 800, 80 do
        for y = 0, 600, 80 do
            love.graphics.rectangle("line", x, y, 80, 80)
        end
    end
    
    for _, t in ipairs(turrets) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(turretImg, t.x, t.y, 0, 0.08, 0.08, 454, 605)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(t.hp or 3, t.x - 5, t.y - 30)
    end
        explosion.draw()
    for _, p in ipairs(enemyProjectiles) do
        if p.parried then
            love.graphics.setColor(0, 1, 1)
        else
            love.graphics.setColor(1, 0.3, 0.2)
        end
        love.graphics.circle("fill", p.x, p.y, 6)
    end
    
    for _, b in ipairs(bullets) do
        local lifeRatio = b.life / b.maxLife
        local length = 8 + (30 - 8) * lifeRatio
        local width = 4
        
        love.graphics.setColor(1, 0.9, 0.2)
        love.graphics.push()
        love.graphics.translate(b.x, b.y)
        love.graphics.rotate(b.angle)
        love.graphics.rectangle("fill", 0, -width/2, length, width)
        love.graphics.pop()
    end

    if player.dashInvuln then
        love.graphics.setColor(1, 1, 1, 0.5)
    else
        love.graphics.setColor(1, 1, 1)
    end
    dash.draw(player.img)
    love.graphics.draw(player.img, player.x, player.y, 0, 0.15, 0.15, 223, 223)
    
    local mx, my = love.mouse.getPosition()
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.circle("line", mx, my, 6)
    love.graphics.line(mx - 10, my, mx + 10, my)
    love.graphics.line(mx, my - 10, mx, my + 10)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HP: " .. player.health, 10, 10)
    love.graphics.print("Dash: " .. string.format("%.1f", math.max(0, player.dashCooldown)), 10, 28)
    love.graphics.print("Parry: " .. (player.parryWindow > 0 and "READY" or "---"), 10, 46)
    love.graphics.print("Enemies: " .. #turrets, 10, 64)
    love.graphics.print("WASD - move | LMB - shoot | RMB - parry | SHIFT - dash | ESC - pause", 10, 580)
    
    if impactFlash > 0 then
        love.graphics.setColor(1, 1, 1, impactFlash)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
    end
    
    if gameState == "paused" then
        drawPauseMenu()
    end
end

function drawMenu()
    local title = "ULTRAMINIKILL"
    local subtitle = "Press SPACE or ENTER to start"
    local credit = "A fan game based on ULTRAKILL"
    
    local pulse = math.sin(menuFlash) * 0.2 + 0.8
    
    love.graphics.setColor(0.08, 0.08, 0.1)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    
    love.graphics.setColor(1, 0.2, 0.2, pulse)
    love.graphics.setNewFont(48)
    love.graphics.printf(title, 0, 180, 800, "center")
    
    love.graphics.setColor(1, 1, 1, pulse)
    love.graphics.setNewFont(20)
    love.graphics.printf(subtitle, 0, 320, 800, "center")
    
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setNewFont(14)
    love.graphics.printf(credit, 0, 500, 800, "center")
    
    love.graphics.setNewFont(12)
end

function drawPauseMenu()
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, 800, 600)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(36)
    love.graphics.printf("PAUSED", 0, 230, 800, "center")
    
    love.graphics.setNewFont(18)
    love.graphics.printf("Press ESC to resume", 0, 300, 800, "center")
    love.graphics.setNewFont(12)
end

function resetGame()
    player.x = 400
    player.y = 300
    player.health = 100
    player.dashing = false
    player.dashCooldown = 0
    player.dashTimer = 0
    player.dashInvuln = false
    player.parryWindow = 0
    
    bullets = {}
    enemyProjectiles = {}
    bulletCooldown = 0
    impactFreeze = 0
    impactFlash = 0
    
    turret = {
        x = 400, y = 100,
        shootTimer = 0,
        shootDelay = 1.2
    }
    
    turret2 = {
        x = 200, y = 400,
        shootTimer = 0.5,
        shootDelay = 1.5
    }
    
    turrets = {turret, turret2}
    dash.clear()
end

function love.keypressed(key)
    if key == "escape" then
        if gameState == "playing" then
            gameState = "paused"
            love.mouse.setVisible(true)
        elseif gameState == "paused" then
            gameState = "playing"
            love.mouse.setVisible(false)
        end
    end
    
    if key == "space" or key == "return" then
        if gameState == "menu" then
            resetGame()
            gameState = "playing"
            love.mouse.setVisible(false)
            music.playGame()
        end
    end
end