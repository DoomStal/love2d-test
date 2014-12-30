-- http://www.love2d.org/wiki/Minimalist_Sound_Manager

require("camera")
require("tiled")
require("image_man")

require("collection")

require("animation")
require("entity")

entities = Collection:new()

ground_y = 200

function love.load()

	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setBackgroundColor(255, 255, 255)

	font = love.graphics.newImageFont("font.png",
		" abcdefghijklmnopqrstuvwxyz"..
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ0"..
		"123456789.,!?-+/():;%&`'*#=[]\"")

	love.graphics.setFont(font)

	background = ImageManager:get("sky.png")
	background_quad = love.graphics.newQuad(0, 0, love.graphics.getWidth(), love.graphics.getHeight(), background:getDimensions()) 

	map = Map.load("level.tmx")
--	TiledMap_Load("level.tmx")

	player = EntityLiving:new();
	player.x = 10
	player.y = 10
	player.width = 40
	player.height = 56
	player.color_r = 255
	player.color_g = 0
	player.color_b = 0

	local a = Animation:new()
	a.rate = 0
	a.frames = {
		Frame:new("stand.png", 48, 83)
	}
	player.animations["stand"] = a

	a = Animation:new()
	a.rate = 15
	a.loop = true
	a.frames = {
		Frame:new("run.png", 48, 81, 0, 0, 96),
		Frame:new("run.png", 48, 81, 96, 0, 96),
		Frame:new("run.png", 48, 81, 192, 0, 96),
		Frame:new("run.png", 48, 81, 288, 0, 96),
		Frame:new("run.png", 48, 81, 384, 0, 96),
		Frame:new("run.png", 48, 81, 480, 0, 96),
	}
	player.animations["run"] = a

	a = Animation:new()
	a.rate = 0
	a.frames = {
		Frame:new("jump.png", 48, 79)
	}
	player.animations["jump"] = a

	player:setAnimation("stand")

	player.x = 156
	player.y = 200

	entities:insert(player)

	sound = {
		jump = love.audio.newSource("jump.wav", "static")
	}

--[[
	music_list = {
		"CHRIS31B.IT"
	}
	music = love.audio.newSource( music_list[1] )
	music:setVolume(0.3)
	music:play()
]]

end

function love.keyreleased(key)
	if(key == "escape") then love.event.quit() end
end

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
	if love.keyboard.isDown("down") then ground_y = ground_y + 4 end

	for _,v in ipairs(entities) do
		v:update(dt)
	end

	camera:setPosition(player.x, player.y - player.height/2)

--[[
	local min_x = love.graphics.getWidth()/2
	local max_x = TiledMap_GetMapW()*kTileSize - love.graphics.getWidth()/2
	-- local min_y = love.graphics.getHeight()/2
	local max_y = TiledMap_GetMapH()*kTileSize - love.graphics.getHeight()/2
	camera:setPosition(
		math.min(math.max(min_x, camera.x), max_x),
		-- math.min(math.max(min_y, camera.y), max_y)
		math.min(camera.y, max_y)
	)
]]
end

function love.draw()

	love.graphics.draw(background, background_quad, 0, 0)

	local off_x = love.graphics.getWidth()/2 - camera.x
	local off_y = love.graphics.getHeight()/2 - camera.y

	for _,layer in ipairs(map.bg_layers) do
		layer:draw(map.tiles, off_x, off_y)
	end
	map.level:draw(map.tiles, off_x, off_y)
	for _,layer in ipairs(map.fg_layers) do
		layer:draw(map.tiles, off_x, off_y)
	end

	for _,v in ipairs(entities) do
		v:draw(off_x, off_y)
	end

	love.graphics.print(math.floor(player.x), 0, 0)
	love.graphics.print(math.floor(player.y), 0, font:getHeight())
end

