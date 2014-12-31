CollisionObject = inherits(nil)

function CollisionObject:collide(entity)
	error("override collided(entity)!")
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

function CollisionSegment:collide(entity)
	local cornerx, cornery = -entity.width/2, 0

	if self.x1 > self.x2 then cornery = -entity.height end
	if self.y1 > self.y2 then cornerx = entity.width/2 end

	local x1, y1 = entity.x + cornerx, entity.y + cornery
	local x2, y2 = entity.nx + cornerx, entity.ny + cornery

	local slide = true

	local d1 = (x1-self.x1)*self.nx + (y1-self.y1)*self.ny
	local d2 = (x2-self.x1)*self.nx + (y2-self.y1)*self.ny

	if d1 >= 0 and d2 < 0 then
		-- print( d1/(d1-d2) )

		local cx = x1 + ((x2-x1)*(d1-0.1))/(d1-d2)
		local cy = y1 + ((y2-y1)*(d1-0.1))/(d1-d2)

		if (cx >= math.min(self.x1, self.x2) and cx <= math.max(self.x1, self.x2))
		or (cy >= math.min(self.y1, self.y2) and cy <= math.max(self.y1, self.y2)) then

			if slide then
				entity.nx = entity.nx - self.nx*(d2-0.01)
				entity.ny = entity.ny - self.ny*(d2-0.01)
				local dv = self.nx * entity.xv + self.ny * entity.yv
				print (dv)
				entity.xv = entity.xv - self.nx * (dv+0.1)
				entity.yv = entity.yv - self.ny * (dv+0.1)
			else
				entity.nx = cx - cornerx
				entity.ny = cy - cornery
				entity.xv = 0
				entity.yv = 0
			end

			entity.on_ground = true
		end
	end
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

function CollisionRect:collide(entity)
end