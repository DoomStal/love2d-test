-- http://www.love2d.org/wiki/Minimalist_Sound_Manager

dofile("camera.lua")
dofile("tiled.lua")

function love.load()

	love.graphics.setDefaultFilter("nearest", "nearest")

	love.graphics.setNewFont(20)
	love.graphics.setBackgroundColor(255, 255, 255)

	TiledMap_Load("level.tmx")

	stand = love.graphics.newImage("stand.png")

	sound = {
		jump = love.audio.newSource("jump.wav", "static")
	}

	music_list = {
		"CHRIS31B.IT"
	}

	music = love.audio.newSource( music_list[1] )
	music:setVolume(0.3)

	-- camera:setScale(0.5, 0.5)

	music:play()
end

player = { x = 10, y = 10 }

text = "Hello world!"

function love.mousepressed(x, y, button) -- https://love2d.org/wiki/MouseConstant
	text = "mouse pressed '"..button.."' at "..x..", "..y
end

function love.mousereleased(x, y, button) -- https://love2d.org/wiki/MouseConstant
	text = "mouse released '"..button.."' at "..x..", "..y
end

function love.keypressed(key) -- https://love2d.org/wiki/KeyConstant
	text = "key '"..key.."' was pressed"
end

function love.keyreleased(key) -- https://love2d.org/wiki/KeyConstant
	text = "key '"..key.."' was released"
	if key == "escape" then love.event.quit() end
end

function love.focus(f)
	if f then
		text = "gained focus"
	else
		text = "lost focus"
	end
end

function love.quit()
	print("come back soon!")
end

function love.update(dt)
	local camera_speed = 200
	if love.keyboard.isDown("up") then
		camera:move(0, -camera_speed * dt)
	end
	if love.keyboard.isDown("down") then
		camera:move(0, camera_speed * dt)
	end
	if love.keyboard.isDown("left") then
		camera:move(-camera_speed * dt, 0)
	end
	if love.keyboard.isDown("right") then
		camera:move(camera_speed * dt, 0)
	end
end

function love.draw()
	-- camera:set()

	TiledMap_DrawNearCam(camera.x, camera.y)

	local off_x = love.graphics.getWidth()/2 - camera.x
	local off_y = love.graphics.getHeight()/2 - camera.y

	love.graphics.draw(stand, off_x + player.x, off_y + player.y)

	love.graphics.setColor(0, 0, 0)
	love.graphics.print(text, 0, 0)
	love.graphics.setColor(255, 255, 255)

	-- camera:unset()
end
