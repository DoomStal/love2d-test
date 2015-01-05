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

	if not self.animation then
		love.graphics.setColor(self.color_r, self.color_g, self.color_b, 128)
		love.graphics.rectangle(
			"fill",
			math.floor(off_x + self.x - self.width/2 + 0.5),
			math.floor(off_y + self.y - self.height + 0.5),
			self.width,
			self.height
		)
		love.graphics.lastColor()
	else	
		if nil ~= self.animation.frames[self.animation_frame] then
			self.animation.frames[self.animation_frame]:draw(
				math.floor(off_x + self.x + 0.5),
				math.floor(off_y + self.y + 0.5),
				self.flip_x
			)
		end
	end

end

EntityMoving = inherits(Entity)

EntityMoving.xv = 0
EntityMoving.yv = 0

EntityMoving.collision_object = nil

EntityMoving.on_ground = false
EntityMoving.ground_nx = 0
EntityMoving.ground_ny = 0

EntityMoving.friction = 0.5

function EntityMoving:makeCollisionBox()
	self.collision_object = CollisionPolygon:new({
		CollisionSegment:new(-self.width/2, -self.height, self.width/2, -self.height),
		CollisionSegment:new(self.width/2, -self.height, self.width/2, 0),
		CollisionSegment:new(self.width/2, 0, -self.width/2, 0),
		CollisionSegment:new(-self.width/2, 0, -self.width/2, -self.height)
	})
end

function EntityMoving:tryMove(dx, dy)
	local toi, cnx, cny, cx, cy
	local toi2, cnx2, cny2, cx2, cy2

	toi, cnx, cny, cx, cy = map.level:collideEntity(map.tiles, self, dx, dy)

	for _, platform in ipairs(platforms) do
		toi2, cnx2, cny2, cx2, cy2 = platform:collide(self, dx, dy)
		if not toi or (toi2 and toi2 < toi) then toi, cnx, cny, cx, cy = toi2, cnx2, cny2, cx2, cy2 end
	end

	toi2, cnx2, cny2, cx2, cy2 = collideList(self.collision_object, self.x, self.y,
	dx, dy, map.collision_objects, 0, 0)
	if not toi or (toi2 and toi2 < toi) then toi, cnx, cny, cx, cy = toi2, cnx2, cny2, cx2, cy2 end

	if toi then
		toi = toi - eps
		self.x = self.x + toi * dx
		self.y = self.y + toi * dy

		local dv = self.xv * cnx + self.yv * cny
		self.xv = self.xv - cnx * dv
		self.yv = self.yv - cny * dv

		self.ground_nx = cnx
		self.ground_ny = cny
		if cny < -0.5 then
			self.on_ground = true
		end

		return toi
	else
		self.x = self.x + dx
		self.y = self.y + dy
		return 1
	end
end

function EntityMoving:pushByPlatforms()
	local toi, cnx, cny, platform_xv, platform_yv

	for _, platform in ipairs(platforms) do
		local toi2, cnx2, cny2 = platform:push(self)
		if not toi or (toi2 and toi2 < toi) then
			toi, cnx, cny = toi2, cnx2, cny2
			platform_xv, platform_yv = platform.xv, platform.yv
		end
	end
	if toi then
		self.xv = self.xv + platform_xv * (1 - toi)
		self.yv = self.yv + platform_yv * (1 - toi)

		self.ground_nx = cnx
		self.ground_ny = cny
		if cny < -0.5 then
			self.on_ground = true
		end
	end
end

function EntityMoving:update(dt)
	Entity.update(self, dt)

	self.on_ground = false
	self.ground_nx = 0
	self.ground_ny = -1

	self:pushByPlatforms()

--	if math.abs(self.xv) > 0.1 or math.abs(self.yv) > 0.1 then
		local toi = self:tryMove(self.xv, self.yv)
		if toi<1 then
			self:tryMove((1-toi) * self.xv, (1-toi) * self.yv)
		end
--	end

	self.yv = self.yv + 0.3

	if not self.on_ground then
		self:tryMove(0, 0.1)
	end

	local ground_y = map:getHeight()
	if self.y > ground_y then
		self.y = ground_y
		self.on_ground = true
		self.ground_nx = 0
		self.ground_ny = -1
	end

	if self.on_ground then
		self.xv = 0
		self.yv = 0
	else
		self.xv = self.xv * 0.98
		if math.abs(self.xv) < 0.1 then self.xv = 0 end
		self.yv = self.yv * 0.98
	end
end

function EntityMoving:draw(off_x, off_y)
	Entity.draw(self, off_x, off_y)

	if self.collision_object then
		love.graphics.setColor(0, 0, 255)
		self.collision_object:draw(self.x + off_x, self.y + off_y)
		love.graphics.lastColor()
	end
	love.graphics.setColor(0, 255, 0)
	love.graphics.line(off_x + self.x, off_y + self.y,
		off_x + self.x + self.ground_nx * 20, off_y + self.y + self.ground_ny * 20)
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

	if self.ground_ny > -0.5 then spd = spd / 2 end

	if(self.key_left) then
		self.flip_x = true
		if self.on_ground then
			self.xv = self.ground_ny * spd
			self.yv = -self.ground_nx * spd
		else
			self.xv = -spd
		end
	elseif(self.key_right) then
		self.flip_x = false
		if self.on_ground then
			self.xv = -self.ground_ny * spd
			self.yv = self.ground_nx * spd
		else
			self.xv = spd
		end
	else
		if not self.on_ground then
			self.xv = 0
		end
	end

	if(self.on_ground) then
		if(self.key_jump) then
			love.audio.play(sound["jump"])
			self.yv = self.jump_vel
			self.on_ground = false
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
