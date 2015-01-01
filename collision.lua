CollisionObject = inherits(nil)

function CollisionObject:collide(entity, ox, oy)
	error("override collided(entity)!")
end

function collideList(entity, list, ox, oy)
	ox = ox or 0
	oy = oy or 0
	if not list then return end
	for _, cobj in ipairs(list) do
		cobj:collide(entity, ox, oy)
	end
end

function drawCollisions(list, off_x, off_y)
	if not list then return end
	for _, cobj in ipairs(list) do
		cobj:draw(off_x, off_y)
	end
end

CollisionDot = inherits(CollisionObject)

function CollisionDot:init(x, y)
	self.x = x
	self.y = y
end

function CollisionDot:draw(off_x, off_y)
	love.graphics.setColor(255, 0, 0)
	love.graphics.rectangle("line", off_x + self.x - 2, off_y + self.y - 2, 5, 5)
	love.graphics.lastColor()
end

-- simple implementation
function CollisionDot:collide(entity, ox, oy)
	if ox+self.x > entity.nx - entity.width/2 and ox+self.x < entity.nx + entity.width/2 then
		if entity.ny >= oy+self.y and entity.y <= oy+self.y then
			entity.ny = oy+self.y
			entity.yv = 0
			entity.on_ground = true
			entity.dcollided = true
			return true
		end
		if entity.ny - entity.height < oy+self.y and entity.y - entity.height >= oy+self.y then
			entity.ny = oy+self.y + entity.height
			entity.yv = 0
			entity.ucollided = true
			return true
		end
	end
	if oy+self.y > entity.ny - entity.height and oy+self.y < entity.ny then
		if entity.nx + entity.width/2 > ox+self.x and entity.x + entity.width/2 <= ox+self.x then
			entity.nx = ox+self.x - entity.width/2
			entity.xv = 0
			entity.rcollided = true
			return true
		end
		if entity.nx - entity.width/2 < ox+self.x and entity.x - entity.width/2 >= ox+self.x then
			entity.nx = ox+self.x + entity.width/2
			entity.xv = 0
			entity.lcollided = true
			return true
		end
	end
	return false
end

CollisionSegment = inherits(CollisionObject)

function CollisionSegment:init(x1, y1, x2, y2)
	self.x1 = x1
	self.y1 = y1
	self.x2 = x2
	self.y2 = y2

	local r = math.sqrt((self.x2-self.x1)^2 + (self.y2-self.y1)^2)
	self.ex, self.ey = (self.x2-self.x1)/r, (self.y2-self.y1)/r
	self.nx, self.ny = self.ey, -self.ex
end

function CollisionSegment:draw(off_x, off_y)
	love.graphics.setColor(255, 0, 0)
	love.graphics.line(off_x+self.x1, off_y+self.y1, off_x+self.x2, off_y+self.y2)
	local cx = (self.x1 + self.x2) / 2
	local cy = (self.y1 + self.y2) / 2
	love.graphics.line(off_x+cx, off_y+cy, off_x+cx+self.nx*5, off_y+cy+self.ny*5)
	love.graphics.lastColor()
end

function CollisionSegment:collide(entity, ox, oy)
	local cornerx, cornery = -entity.width/2, 0
	local right, top = false, false

	if self.x1 > self.x2 then cornery, top = -entity.height, true end
	if self.y1 > self.y2 then cornerx, right = entity.width/2, true end

	local x1, y1 = entity.x + cornerx, entity.y + cornery
	local x2, y2 = entity.nx + cornerx, entity.ny + cornery

	local d1 = (x1-ox-self.x1)*self.nx + (y1-oy-self.y1)*self.ny
	local d2 = (x2-ox-self.x1)*self.nx + (y2-oy-self.y1)*self.ny

	local slide, hard = false, false
	if self.ny > -0.5 then slide = true end
	if math.abs(entity.xv) < 0.01 and not top then hard = true end

	if (right and entity.lcollided) or (not right and entity.rcollided)
	or (top and entity.dcollided) or (not top and entity.ucollided) then hard = true end

	if d1 >= 0 and d2 < 0 then
		local cx = x1 + ((x2-x1)*(d1-0.1))/(d1-d2)
		local cy = y1 + ((y2-y1)*(d1-0.1))/(d1-d2)

		if (cx >= ox+math.min(self.x1, self.x2) and cx <= ox+math.max(self.x1, self.x2))
		or (cy >= oy+math.min(self.y1, self.y2) and cy <= oy+math.max(self.y1, self.y2)) then

			entity.nx = entity.nx - self.nx*(d2-0.01)
			entity.ny = entity.ny - self.ny*(d2-0.01)
			-- entity.nx = cx - cornerx
			-- entity.ny = cy - cornery

			-- local dv = self.nx * entity.xv + self.ny * entity.yv
			-- entity.xv = entity.xv - self.nx * (dv+0.1)
			-- entity.yv = entity.yv - self.ny * (dv+0.1)
			if not slide then
				if hard then
					entity.nx = cx - cornerx
					entity.ny = cy - cornery
				end

				local dv = self.nx * entity.xv + self.ny * entity.yv
				entity.xv = entity.xv - self.nx * (dv+0.1)
				entity.yv = entity.yv - self.ny * (dv+0.1)

				assert(not top)
				entity.on_ground = true
				if self.y1 < self.y2 then
					entity.lcorner = { x=self.ex, y=self.ey }
				else
					entity.rcorner = { x=self.ex, y=self.ey }
				end
			end

			if right then entity.rcollided = true else entity.lcollided = true end
			if top then entity.ucollided = true else entity.dcollided = true end

			return true
		end
	end
	return false
end

CollisionRect = inherits(CollisionObject)
function CollisionRect:init(x, y, w, h)
	self.x = x
	self.y = y
	self.w = w
	self.h = h
end

function CollisionRect:draw(off_x, off_y)
	love.graphics.setColor(255, 0, 0)
	love.graphics.rectangle("line", off_x + self.x, off_y + self.y, self.w, self.h)
	love.graphics.line(
		off_x + self.x + self.w/2, off_y + self.y,
		off_x + self.x + self.w/2, off_y + self.y - 5
	)
	love.graphics.line(
		off_x + self.x + self.w/2, off_y + self.y + self.h,
		off_x + self.x + self.w/2, off_y + self.y + self.h + 5
	)
	love.graphics.line(
		off_x + self.x, off_y + self.y + self.h/2,
		off_x + self.x - 5, off_y + self.y + self.h/2
	)
	love.graphics.line(
		off_x + self.x + self.w, off_y + self.y + self.h/2,
		off_x + self.x + self.w + 5, off_y + self.y + self.h/2
	)
	love.graphics.lastColor()
end

function CollisionRect:collide(entity, ox, oy)
end
