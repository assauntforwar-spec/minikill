-- music.lua
local music = {}

local currentTrack = nil
local menuMusic = nil
local gameMusic = nil

function music.load()
    if love.filesystem.getInfo("menu.mp3") then
      --  menuMusic = love.audio.newSource("menu.mp3", "stream")
        menuMusic = nil
        menuMusic:setLooping(true)
        menuMusic:setVolume(0.5)
    end
    if love.filesystem.getInfo("maingame.mp3") then
      --  gameMusic = love.audio.newSource("maingame.mp3", "stream")
        gameMusic = nil
        gameMusic:setLooping(true)
        gameMusic:setVolume(0.4)
    end
end

function music.playMenu()
    if menuMusic and currentTrack ~= menuMusic then
        music.stop()
        menuMusic:play()
        currentTrack = menuMusic
    end
end

function music.playGame()
    if gameMusic and currentTrack ~= gameMusic then
        music.stop()
        gameMusic:play()
        currentTrack = gameMusic
    end
end

function music.stop()
    if currentTrack then
        currentTrack:stop()
        currentTrack = nil
    end
end

return music
