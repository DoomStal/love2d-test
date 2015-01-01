require("oop")

require("utils")

Entity = inherits(nil)

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
		if not self.animation.loop and self.animation_frame == #self.animation.frames then return end

		self.animation_time = self.animation_time + dt * self.animation.rate
		local ai, af = math.modf(self.animation_time)
		self.animation_frame = self.animation_frame + ai
		self.animation_frame = math.fmod(self.animation_frame - 1, #self.animation.frames) + 1
		self.animation_time = af
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

--	if not self.animation then
		love.graphics.setColor(self.color_r, self.color_g, self.color_b, 128)
		love.graphics.rectangle(
			"fill",
			off_x + self.x - self.width/2,
			off_y + self.y - self.height,
			self.width,
			self.height
		)
		love.graphics.lastColor()
--	else	
		if nil ~= self.animation.frames[self.animation_frame] then
			self.animation.frames[self.animation_frame]:draw(
				off_x + self.x,
				off_y + self.y,
				self.flip_x
			)
		end
--	end

end

EntityMoving = inherits(Entity)

EntityMoving.nx = 0
EntityMoving.ny = 0
EntityMoving.xv = 0
EntityMoving.yv = 0

EntityMoving.on_ground = false
EntityMoving.lcorner = nil
EntityMoving.rcorner = nil
EntityMoving.lcollided = false
EntityMoving.rcollided = false
EntityMoving.ucollided = false
EntityMoving.dcollided = false

function EntityMoving:clearCollision()
	self.on_ground = false
	self.lcorner = nil
	self.rcorner = nil
	self.lcollided = false
	self.rcollided = false
	self.ucollided = false
	self.dcollided = false
end

function EntityMoving:update(dt)
	Entity.update(self, dt)

	self.yv = self.yv + 0.3

	self.nx = self.x + self.xv
	self.ny = self.y + self.yv

	self:clearCollision()

	for i = 1,2 do
		map.level:collide(map.tiles, self)
		collideList(self, map.collision_objects)
	end

	local ground_y = map:getHeight()
	if self.ny > ground_y then
		self.ny = ground_y
		self.yv = 0
		self.on_ground = true
	end

	if self.on_ground then
	else
		self.yv = self.yv * 0.98
	end
	self.x = self.nx
	self.y = self.ny
end

function EntityMoving:draw(off_x, off_y)
	Entity.draw(self, off_x, off_y)

	love.graphics.setColor(0, 0, 255)
	if self.ucollided then love.graphics.line(
		off_x + self.x - self.width/2, off_y + self.y - self.height,
		off_x + self.x + self.width/2, off_y + self.y - self.height) end
	if self.dcollided then love.graphics.line(
		off_x + self.x - self.width/2, off_y + self.y,
		off_x + self.x + self.width/2, off_y + self.y) end
	if self.lcollided then love.graphics.line(
		off_x + self.x - self.width/2, off_y + self.y - self.height,
		off_x + self.x - self.width/2, off_y + self.y) end
	if self.rcollided then love.graphics.line(
		off_x + self.x + self.width/2, off_y + self.y - self.height,
		off_x + self.x + self.width/2, off_y + self.y) end
	love.graphics.lastColor()
end

EntityLiving = inherits(EntityMoving)

EntityLiving.key_left = false
EntityLiving.key_right = false
EntityLiving.key_jump = false

EntityLiving.jump_vel = -7.5
EntityLiving.move_spd = 3.5

function EntityLiving:update(dt)
	EntityMoving.update(self, dt)

	local spd = self.move_spd

	if(self.key_left) then
		self.flip_x = true
		if self.lcorner then
			self.xv = -spd * self.lcorner.x
			self.yv = -spd * self.lcorner.y
		elseif self.rcorner then
			self.xv = -spd * self.rcorner.x
			self.yv = -spd * self.rcorner.y
		else
			self.xv = -spd
		end
	elseif(self.key_right) then
		self.flip_x = false
		if self.rcorner then
			self.xv = spd * self.rcorner.x
			self.yv = spd * self.rcorner.y
		elseif self.lcorner then
			self.xv = spd * self.lcorner.x
			self.yv = spd * self.lcorner.y
		else
			self.xv = spd
		end
	else
		self.xv = self.xv * 0.6
		if math.abs(self.xv) < 0.5 then self.xv = 0 end
	end

	if(self.on_ground) then
		if(self.key_jump) then
			love.audio.play(sound["jump"])
			self.yv = self.yv + self.jump_vel
			-- self:clearCollision()
		end
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
