-- http://www.love2d.org/wiki/Minimalist_Sound_Manager

require("camera")
require("tiled")
require("image_man")

require("collection")

require("animation")
require("entity")

entities = Collection:new()

function love.load()

	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setBackgroundColor(255, 255, 255)

	font = love.graphics.newImageFont("font.png",
		" abcdefghijklmnopqrstuvwxyz"..
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ0"..
		"123456789.,!?-+/():;%&`'*#=[]\"")

	love.graphics.setFont(font)

	TiledMap_Load("level.tmx")

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
		Frame:new("stand.png", 0, 0, 96, 96, 28, 28)
	}
	player.animations["stand"] = a

	a = Animation:new()
	a.rate = 15
	a.loop = true
	a.frames = {
		Frame:new("run.png", 0, 0, 96, 96, 28, 25),
		Frame:new("run.png", 96, 0, 96, 96, 28, 25),
		Frame:new("run.png", 192, 0, 96, 96, 28, 25),
		Frame:new("run.png", 288, 0, 96, 96, 28, 25),
		Frame:new("run.png", 384, 0, 96, 96, 28, 25),
		Frame:new("run.png", 480, 0, 96, 96, 28, 25)
	}
	player.animations["run"] = a

	a = Animation:new()
	a.rate = 0
	a.frames = {
		Frame:new("jump.png", 0, 0, 96, 96, 28, 24)
	}
	player.animations["jump"] = a

	player:setAnimation("stand")

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

	for _,v in ipairs(entities) do
		v:update(dt)
	end

	camera:setPosition(player.x, player.y - player.height/2)

	local min_x = love.graphics.getWidth()/2
	local max_x = TiledMap_GetMapW()*kTileSize - love.graphics.getWidth()/2
	-- local min_y = love.graphics.getHeight()/2
	local max_y = TiledMap_GetMapH()*kTileSize - love.graphics.getHeight()/2
	camera:setPosition(
		math.min(math.max(min_x, camera.x), max_x),
		-- math.min(math.max(min_y, camera.y), max_y)
		math.min(camera.y, max_y)
	)
end

function love.draw()
	-- camera:set()

	TiledMap_DrawNearCam(camera.x, camera.y)

	local off_x = love.graphics.getWidth()/2 - camera.x
	local off_y = love.graphics.getHeight()/2 - camera.y

	for _,v in ipairs(entities) do
		v:draw(off_x, off_y)
	end

	-- love.graphics.setColor(0, 0, 0)
	-- love.graphics.print(text, 0, 0)
	-- love.graphics.setColor(255, 255, 255)

	-- camera:unset()
end
