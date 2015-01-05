require("oop")
require("entity")

Platform = inherits(Entity)

Platform.spd = 0.5
Platform.xv = 0
Platform.yv = 0
Platform.cobj = nil

Platform.color_r = 255
Platform.color_g = 0
Platform.color_b = 0

function Platform:draw(off_x, off_y)
	Entity.draw(self, off_x, off_y)

	love.graphics.setColor(255, 0, 0)
	self.cobj:draw(off_x + self.x, off_y + self.y)
	love.graphics.lastColor()
	love.graphics.print(self.x, off_x + self.x, off_y + self.y - 20)
	love.graphics.print(self.y, off_x + self.x, off_y + self.y)
end

function Platform:update(dt)
	self.x = self.x + self.xv
	self.y = self.y + self.yv
	if self.x <= 32*29 then
		self.x = 32*29
		self.xv = self.spd
		self.yv = self.spd
	end
	if self.x >= 32*33 then
		self.x = 32*33
		self.xv = -self.spd
		self.yv = -self.spd
	end
end

function Platform:collide(entity, dx, dy)
	local toi, cnx, cny, cx, cy = self.cobj:collide(
		entity.collision_object,
		entity.x, entity.y,
		dx, dy,
		self.x + self.xv, self.y + self.yv)

	return toi, cnx, cny, cx, cy
end

function Platform:push(entity)
	local toi, cnx, cny, cx, cy = self.cobj:collide(
		entity.collision_object,
		entity.x, entity.y,
		-self.xv, -self.yv,
		self.x, self.y)

	return toi, cnx, cny, cx, cy
end
