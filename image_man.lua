ImageManager = {}
ImageManager.images = {}

function ImageManager:load(name)
	if nil == self.images[name] then
		self.images[name] = love.graphics.newImage(name)
	end
end

function ImageManager:get(name)
	self:load(name)

	return self.images[name]
end
