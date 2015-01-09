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
EntityMoving.riding_entity = nil
EntityMoving.riding_moved = false

EntityMoving.friction = 10

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

	local cp

	for _, platform in ipairs(platforms) do
		toi2, cnx2, cny2, cx2, cy2 = platform:collide(self, dx, dy)
		if toi2 and (not toi or toi2 < toi) then
			toi, cnx, cny, cx, cy = toi2, cnx2, cny2, cx2, cy2
			cp = platform
		end
	end

	toi2, cnx2, cny2, cx2, cy2 = map.level:collideEntity(map.tiles, self, dx, dy)
	if not toi or (toi2 and toi2 < toi) then
		toi, cnx, cny, cx, cy = toi2, cnx2, cny2, cx2, cy2
		cp = nil
	end

	toi2, cnx2, cny2, cx2, cy2 = collideList(self.collision_object, self.x, self.y,
	dx, dy, map.collision_objects, 0, 0)
	if not toi or (toi2 and toi2 < toi) then
		toi, cnx, cny, cx, cy = toi2, cnx2, cny2, cx2, cy2
		cp = nil
	end

	if toi then
		if toi < 0 then toi = 0 end

		toi = toi - eps
		self.x = self.x + toi * dx
		self.y = self.y + toi * dy

		self:clampVelocity(cnx, cny)

		if math.abs(cy - self.y) < 1 and not self.on_ground then
			self.ground_nx = cnx
			self.ground_ny = cny
		end
		if cny < -0.5 then
			self.on_ground = true
			if cp then
				self.riding_entity = cp
			end
		end

		return toi
	else
		self.x = self.x + dx
		self.y = self.y + dy
		return 1
	end
end

function EntityMoving:pushByPlatforms()
	local toi, cnx, cny, cx, cy, cp

	for _, platform in ipairs(platforms) do
		local toi2, cnx2, cny2, cx2, cy2 = platform:push(self)
		if not toi or (toi2 and toi2 < toi) then
			toi, cnx, cny, cx, cy = toi2, cnx2, cny2, cx2, cy2
			cp = platform
		end
	end
	if toi then
		if math.abs(cy - self.y) < 1 and not self.on_ground then
			self.ground_nx = cnx
			self.ground_ny = cny
		end
		local ground = false
		if cny < -0.5 then
			ground = true
			self.on_ground = true
		end

		self:clampVelocity(cnx, cny)

		if ground then
			self.xv = self.xv + cp.xv * (1 - toi)
			self.yv = self.yv + cp.yv * (1 - toi)
		else
			self.xv = self.xv + cnx * math.abs(cp.xv) * (1 - toi)
			self.yv = self.yv + cny * math.abs(cp.yv) * (1 - toi)
		end
	end
end

function EntityMoving:clampVelocity(cnx, cny)
	local dv = self.xv * cnx + self.yv * cny
	if dv < -eps then
		self.xv = self.xv - cnx * dv
		self.yv = self.yv - cny * dv
	end
end

function EntityMoving:applyFriction(cnx, cny, re)
	local rxv, ryv = 0, 0
	if re then rxv, ryv = re.xv, re.yv end

	local xv = self.xv - rxv
	local yv = self.yv - ryv

	local dv = -cny * xv + cnx * yv
	if dv > self.friction then dv = self.friction
	elseif dv < -self.friction then dv = -self.friction end

	self.xv = self.xv + dv * cny
	self.yv = self.yv - dv * cnx
end

function EntityMoving:update(dt)
	Entity.update(self, dt)

	self.riding_moved = false

	if self.riding_entity then
		self.xv = self.xv + self.riding_entity.xv
		self.yv = self.yv + self.riding_entity.yv
		self.riding_moved = true
		self.riding_entity = nil
	end

	self.on_ground = false
	self.ground_nx = 0
	self.ground_ny = -1

	print()
	print("xv,yv", self.xv, self.yv)

	self:pushByPlatforms()

		local toi = self:tryMove(self.xv, self.yv)
		if toi<1 then
--			self:tryMove((1-toi) * self.xv, (1-toi) * self.yv)
		end

	if not self.on_ground then
		self.yv = self.yv + 0.3
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

	if self.ground_ny > -0.5 then
		spd = spd / 2
		self.on_ground = false
	end

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
