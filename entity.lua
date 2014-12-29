require("oop")

Entity = inherits(nil, "Entity")

Entity.x = 0
Entity.y = 0
Entity.width = 0
Entity.height = 0
Entity.flip_x = false

Entity.animations = {}
Entity.animation = nil
Entity.animation_frame = 1
Entity.animation_time = 0

Entity.color_r = 255
Entity.color_g = 255
Entity.color_b = 255

function Entity:update(dt)

	if self.animation then
		self.animation_time = self.animation_time + dt * self.animation.rate
		if self.animation_time > 1 then
			self.animation_time = 0
			self.animation_frame = self.animation_frame + 1
			if self.animation_frame > #self.animation.frames then
				if self.animation.loop then
					self.animation_frame = 1
				else
					self.animation_frame = #self.animation.frames
				end
			end
		end
	end
end

function Entity:setAnimation(name)
	if self.animation == self.animations[name] then return end

	self.animation = self.animations[name]
	self.animation_frame = 1
	self.animation_time = 0
end

function Entity:draw(off_x, off_y)
	off_x = off_x or 0
	off_y = off_y or 0

	off_x = math.floor(off_x)
	off_y = math.floor(off_y)

	if self.animation then
		self.animation.frames[self.animation_frame]:draw(
			off_x + self.x - self.width/2,
			off_y + self.y - self.height,
			self.flip_x
		)
	end
	--else
		local r,g,b = love.graphics.getColor()
		love.graphics.setColor(self.color_r, self.color_g, self.color_b)
		love.graphics.rectangle(
			"line",
			off_x + self.x - self.width/2,
			off_y + self.y - self.height,
			self.width,
			self.height
		)
		love.graphics.setColor(r, g, b)
	--end

end

EntityMoving = inherits(Entity)
EntityMoving.xv = 0
EntityMoving.yv = 0

EntityMoving.on_ground = false

function EntityMoving:update(dt)
	Entity.update(self, dt)

	self.yv = self.yv + 0.3

	self.x = self.x + self.xv
	self.y = self.y + self.yv

	self.on_ground = false

	if self.y > 200 then
		self.y = 200
		self.yv = 0
		self.on_ground = true
	end

	if self.on_ground then
	else
		self.yv = self.yv * 0.98
	end
end

EntityLiving = inherits(EntityMoving)
EntityLiving.key_left = false
EntityLiving.key_right = false
EntityLiving.key_jump = false

function EntityLiving:update(dt)
	EntityMoving.update(self, dt)

	if(self.on_ground) then
		if(self.key_jump) then
			self.yv = -7.5
			self.on_ground = false
		end
	end

	local spd = 3.5

	if(self.key_left) then
		self.xv = -spd
		self.flip_x = true
	elseif(self.key_right) then
		self.xv = spd
		self.flip_x = false
	else
		self.xv = self.xv * 0.7
		if math.abs(self.xv) < 0.5 then self.xv = 0 end
	end

	if self.on_ground then
		if self.key_left or self.key_right then
			self:setAnimation("run")
		else
			self:setAnimation("stand")
		end
	else
		if self.key_left or self.key_right then
			self:setAnimation("jump")
		else
			self:setAnimation("stand")
		end
	end

end
