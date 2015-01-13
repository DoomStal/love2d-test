ImageManager = {}

ImageManager.images = {}

function ImageManager:load(name)
	if nil == self.images[name] then
		if love.filesystem.exists(name) then
			self.images[name] = love.graphics.newImage(name)
		else
			self.images[name] = love.graphics.newImage("stub.png")
		end
	end
end

function ImageManager:get(name)
	self:load(name)

	return self.images[name]
end
