require("oop")
require("image_man")

Animation = inherits(nil)

Animation.frames = {}
Animation.rate = 0
Animation.loop = false

Frame = inherits(nil)

function Frame:init(image_name, ox, oy, x, y, w, h)
	if nil == image_name then
		image_name = "stub.png"
		ox = 24
		oy = 48
	end

	self.ox = ox or 0
	self.oy = oy or 0

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

