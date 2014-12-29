require("oop")
require("image_man")

Animation = inherits(nil)
Animation.frames = {}
Animation.rate = 0
Animation.loop = false

Frame = inherits(nil)
Frame.image = nil
Frame.quad = nil
Frame.w = 0
Frame.ox = 0
Frame.oy = 0

function Frame:init(image_name, x, y, w, h, ox, oy)
	self.ox = ox or 0
	self.oy = oy or 0

	self.image = ImageManager:get(image_name)
	self.quad = love.graphics.newQuad(x, y, w, h, self.image:getDimensions())
	self.w = w
end

function Frame:draw(off_x, off_y, flip_x)
	if flip_x then
		love.graphics.draw(self.image, self.quad, off_x + self.w - self.ox, off_y - self.oy, 0, -1, 1)
	else
		love.graphics.draw(self.image, self.quad, off_x - self.ox, off_y - self.oy, 0, 1, 1)
	end
end

