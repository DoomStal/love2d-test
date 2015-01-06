-- http://www.love2d.org/wiki/Minimalist_Sound_Manager

require("camera")
require("tiled")
require("image_man")

require("collection")

require("animation")
require("entity")
require("player")
require("platform")

entities = Collection:new()
platforms = Collection:new()

function love.load()

	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setBackgroundColor(255, 255, 255)

	font = love.graphics.newImageFont("font.png",
		" abcdefghijklmnopqrstuvwxyz"..
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ0"..
		"123456789.,!?-+/():;%&`'*#=[]\"")

	love.graphics.setFont(font)

	background = ImageManager:get("sky.png")
	background_quad = love.graphics.newQuad(0, 0, love.graphics.getWidth(),
		love.graphics.getHeight(), background:getDimensions())

	map = Map.load("level.tmx")

	player = Player:new()
	player.x = 10
	player.y = 10

	if map.spawn_points[1] then
		player.x = map.spawn_points[1].x
		player.y = map.spawn_points[1].y
	else
		print("warning: player spawn point not set!")
	end

	entities:insert(player)

	love.audio.setVolume(0.3)

	sound = {
		jump = love.audio.newSource("jump.wav", "static")
	}

	music_list = {
		"CHRIS31B.IT"
	}
	music = love.audio.newSource( music_list[1] )
	music:play()

end

frame_by_frame = false
frame_next = false

function love.keypressed(key)
	if key == "m" then
		love.audio.setVolume(0)
	end
	if key == "r" then
		player.x = map.spawn_points[1].x
		player.y = map.spawn_points[1].y
	end
	if key == "f" then
		frame_by_frame = not frame_by_frame
	end
	if key == " " then
		frame_next = true
	end
end

function love.keyreleased(key)
	if key == "escape" then love.event.quit() end
end

current_display = 0

function love.focus(f)
	if f then
	else
	end
end

function love.quit()
	print("come back soon!")
end

function love.update(dt)
	local camera_speed = 200
	local speed = 200

	player.key_jump = love.keyboard.isDown("up")
	player.key_left = love.keyboard.isDown("left")
	player.key_right = love.keyboard.isDown("right")

	if not frame_by_frame or frame_next then
		frame_next = false
		for _,v in ipairs(entities) do
			v:update(dt)
		end
		for _,v in ipairs(platforms) do
			v:update(dt)
		end
	end

	camera:setPosition(player.x, player.y - player.height/2)

	local sw2 = love.graphics.getWidth()/2
	local sh2 = love.graphics.getHeight()/2
	local min_x = sw2
	local max_x = map:getWidth() - sw2
	local max_y = map:getHeight() - sh2
	camera:setPosition(
		math.min(math.max(min_x, camera.x), max_x),
		math.min(camera.y, max_y)
	)
end

function love.draw()

	love.graphics.draw(background, background_quad, 0, 0)

	local off_x = love.graphics.getWidth()/2 - camera.x
	local off_y = love.graphics.getHeight()/2 - camera.y

	for _,layer in ipairs(map.bg_layers) do
		layer:draw(map.tiles, off_x, off_y)
	end
	map.level:draw(map.tiles, off_x, off_y)

	for _,v in ipairs(platforms) do
		v:draw(off_x, off_y)
	end

	for _,v in ipairs(entities) do
		v:draw(off_x, off_y)
	end

	for _,layer in ipairs(map.fg_layers) do
		layer:draw(map.tiles, off_x, off_y)
	end

	love.graphics.setColor(255, 0, 0)

	map.level:drawCollisions(map.tiles, off_x, off_y)
	drawCollisions(map.collision_objects, off_x, off_y)

	love.graphics.lastColor()

	love.graphics.print(player.x, 0, 0)
	love.graphics.print(player.y, 0, font:getHeight())
	if player.on_ground then love.graphics.print("G", 0, font:getHeight()*2) end
	love.graphics.print(player.xv, 0, font:getHeight()*3)
	love.graphics.print(player.yv, 0, font:getHeight()*4)
end
