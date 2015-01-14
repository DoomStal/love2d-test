
Platform = inherits(Entity)

Platform.speed = 0.5
Platform.xv = 0
Platform.yv = 0
Platform.dxv = 0
Platform.dyv = 0
Platform.cobj = nil
Platform.layer = nil

Platform.stop = false
Platform.waypoints = {}
Platform.waypoint_next = nil
Platform.waypoint_next_ex = 0
Platform.waypoint_next_ey = 0
Platform.waypoint_forward = true

Platform.color_r = 255
Platform.color_g = 0
Platform.color_b = 0

function Platform:init(obj, waypoints)
	if obj:instanceOf(CollisionPolygon) then
		self.cobj = obj
	elseif obj:instanceOf(Layer) then
		self.layer = obj
		self.width = obj:getWidth()
		self.height = obj:getHeight()
	end
	if waypoints then self.waypoints = waypoints end
end

function Platform:draw(off_x, off_y)
	if self.cobj then
		love.graphics.setColor(255, 0, 255)
		self.cobj:draw(off_x + self.x, off_y + self.y)
		love.graphics.lastColor()
	elseif self.layer then
		self.layer:draw(off_x + self.x, off_y + self.y)
--[[
		love.graphics.setColor(255, 0, 255)
			self.layer:drawCollisions(map.tiles, off_x+  self.x, off_y + self.y, true)
		love.graphics.lastColor()
]]
	end
	love.graphics.print(self.x, off_x + self.x, off_y + self.y - 20)
	love.graphics.print(self.y, off_x + self.x, off_y + self.y)
end

function Platform:nextWaypoint()
	local next_wp
	if not self.waypoint_next then
		if math.abs(self.x - self.waypoints[1].x) + math.abs(self.y - self.waypoints[1].y) < 1 then
			if #self.waypoints == 1 then
				self.stop = true
				return
			end
			next_wp = 2
		else
			next_wp = 1
		end
	else
		if #self.waypoints == 1 then
			self.stop = true
			return
		end
		if self.waypoint_forward then
			next_wp = self.waypoint_next + 1
			if next_wp > #self.waypoints then
				if self.waypoints.loop then
					next_wp = 1
				else
					next_wp = #self.waypoints - 1
					self.waypoint_forward = false
				end
			end
		else
			next_wp = self.waypoint_next - 1
			if next_wp < 1 then
				if self.waypoints.loop then
					next_wp = #self.waypoints
				else
					next_wp = 2
					self.waypoint_forward = true
				end
			end
		end
	end

	local ex, ey
	if self.waypoint_next then
		ex = self.waypoints[next_wp].x - self.waypoints[self.waypoint_next].x
		ey = self.waypoints[next_wp].y - self.waypoints[self.waypoint_next].y
	else
		ex = self.waypoints[next_wp].x - self.x
		ey = self.waypoints[next_wp].y - self.y
	end
	local r = math.sqrt(ex*ex + ey*ey)
	if r > 0.1 then
		ex = ex / r
		ey = ey / r
	end

	self.waypoint_next = next_wp
	self.waypoint_next_ex = ex
	self.waypoint_next_ey = ey
	self.xv = ex * self.speed + self.dxv
	self.yv = ey * self.speed + self.dyv

end

function Platform:update(dt)
	if #self.waypoints < 1 then return end
	if self.stop then return end

	if not self.waypoint_next then self:nextWaypoint() end
	self.x = self.x + self.xv
	self.y = self.y + self.yv

	if self.dxv ~= 0 or self.dyv ~= 0 then
		self.xv = self.xv - self.dxv
		self.yv = self.yv - self.dyv
		self.dxv, self.dyv = 0, 0
	end

	if (self.x - self.waypoints[self.waypoint_next].x)*self.waypoint_next_ex +
		(self.y - self.waypoints[self.waypoint_next].y)*self.waypoint_next_ey > 0 then

		self.dxv = self.waypoints[self.waypoint_next].x - self.x
		self.dyv = self.waypoints[self.waypoint_next].y - self.y

		self:nextWaypoint()
	end
end

function Platform:collide(entity, dx, dy)
	local toi, cnx, cny, cx, cy

	if self.cobj then
		toi, cnx, cny, cx, cy = self.cobj:collide(
			entity.collision_object,
			entity.x, entity.y,
			dx, dy,
			self.x + self.xv, self.y + self.yv)
	elseif self.layer then
		toi, cnx, cny, cx, cy = self.layer:collideEntity(
			entity, 
			dx, dy,
			self.x + self.xv, self.y + self.yv)
	end

	return toi, cnx, cny, cx, cy
end

function Platform:push(entity)
	local toi, cnx, cny, cx, cy

	if self.cobj then
		toi, cnx, cny, cx, cy = self.cobj:collide(
			entity.collision_object,
			entity.x, entity.y,
			-self.xv, -self.yv,
			self.x, self.y)
	elseif self.layer then
		toi, cnx, cny, cx, cy = self.layer:collideEntity(map.tiles,
			entity,
			-self.xv, -self.yv,
			self.x, self.y)
	end

	return toi, cnx, cny, cx, cy
end
