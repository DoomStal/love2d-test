Animation = inherits(nil)

function Animation:init(frames, rate, loop)
	self.frames = {} -- [n] => Frame
	self.rate = 0 -- frames per tick
	self.loop = false
end

Frame = inherits(nil)

function Frame:init(image_name, ox, oy, x, y, w, h)
	self.ox = ox or 0 -- origin x
	self.oy = oy or 0 -- origin y

	self.image = ImageManager:get(image_name)
	self.x = x or 0
	self.y = y or 0
	local iw,ih = self.image:getDimensions()
	self.w = w or iw
	self.h = h or ih
	self.quad = love.graphics.newQuad(self.x, self.y, self.w, self.h, iw, ih)
end

function Frame:draw(off_x, off_y, flip_x)
	if flip_x then
		love.graphics.draw(self.image, self.quad, off_x + self.w - self.ox, off_y - self.oy, 0, -1, 1)
	else
		love.graphics.draw(self.image, self.quad, off_x - self.ox, off_y - self.oy, 0, 1, 1)
	end
end
