love.graphics.setDefaultFilter("nearest", "nearest")
local Player = require("player")
local Coin = require("coin")
local Tree = require("tree")
local GUI = require("gui")
local Spike = require("spike")
local Stone = require("stone")
local Camera = require("camera")
local Map = require("map")
local RT = require("rt")

function love.load()
	Map:load()
	background = love.graphics.newImage("assets/background.png")
	GUI:load()
	Player:load()
	bgm = love.audio.newSource("assets/audio/ChristmasSynths.ogg", "stream")
    bgm:setLooping(true)
	love.audio.play(bgm)
	snow = rt.SnowEffect(1500)
	
end

function love.update(dt)
	World:update(dt)
	Player:update(dt)
	Coin.updateAll(dt)
	Spike.updateAll(dt)
	Tree.updateAll(dt)
	Stone.updateAll(dt)
	GUI:update(dt)
	Camera:setPosition(Player.x, 0)
	Map:update(dt)
end

function love.draw()
	love.graphics.draw(background)
	Map.level:draw(-Camera.x, -Camera.y, Camera.scale, Camera.scale)

	Camera:apply()
	Player:draw()
	Coin.drawAll()
	Spike.drawAll()
	Tree.drawAll()
	Stone.drawAll()
	Camera:clear()
	GUI:draw()
	-- draw this last so it draws over everything
    snow:draw()

end

function love.keypressed(key)
	Player:jump(key)
end
function love.mousepressed(x, y, button, istouch)
	Player:jump("space")
   
end

function beginContact(a, b, collision)
	if Coin.beginContact(a, b, collision) then return end
	if Spike.beginContact(a, b, collision) then return end
	Player:beginContact(a, b, collision)
end

function endContact(a, b, collision)
	Player:endContact(a, b, collision)
end
