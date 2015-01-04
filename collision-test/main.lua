-- http://www.love2d.org/wiki/Minimalist_Sound_Manager

require("oop")

eps = 0.00001

CollisionSegment = inherits(nil)

function CollisionSegment:init(x1, y1, x2, y2)
	self.x1 = x1
	self.y1 = y1
	self.x2 = x2
	self.y2 = y2

	self:update()
end

function CollisionSegment:update()
	local r = math.sqrt((self.x2-self.x1)^2 + (self.y2-self.y1)^2)
	self.ex, self.ey = (self.x2-self.x1)/r, (self.y2-self.y1)/r
	self.nx, self.ny = self.ey, -self.ex
end

function CollisionSegment:draw(off_x, off_y)
	love.graphics.line(off_x+self.x1, off_y+self.y1, off_x+self.x2, off_y+self.y2)
	local cx = (self.x1 + self.x2) / 2
	local cy = (self.y1 + self.y2) / 2
	love.graphics.line(off_x+cx, off_y+cy, off_x+cx+self.nx*5, off_y+cy+self.ny*5)
end

function CollisionSegment:collideDot(x, y, ox, oy, dx, dy, sox, soy)
	sox = sox or 0
	soy = soy or 0

	x = x + ox
	y = y + oy

	local d = (x - (sox+self.x1))*self.nx + (y - (soy+self.y1))*self.ny
	local nd = ((x+dx) - (sox+self.x1))*self.nx + ((y+dy) - (soy+self.y1))*self.ny

	if d > -eps and nd < 0 then
		local toi = d / (d - nd)
		local cx, cy = x + dx*toi, y + dy*toi

		if cx+eps > math.min(sox+self.x1, sox+self.x2) and cx-eps < math.max(sox+self.x1, sox+self.x2)
		and cy+eps > math.min(soy+self.y1, soy+self.y2) and cy-eps < math.max(soy+self.y1, soy+self.y2) then
			return toi, self.nx, self.ny, cx, cy
		end
	end

	return nil, 0, 0, 0, 0
end

function CollisionSegment:collideSegment(other, ox, oy, dx, dy, sox, soy)
	sox = sox or 0
	soy = soy or 0

	if self.nx*other.nx + self.ny*other.ny >= 0 then return nil, 0, 0, 0, 0 end

	local toi, cnx, cny, cx, cy = self:collideDot(other.x1, other.y1, ox, oy, dx, dy, sox, soy)

	local toi2, cnx2, cny2, cx2, cy2 = self:collideDot(other.x2, other.y2, ox, oy, dx, dy, sox, soy)
	if not toi or (toi2 and toi2 < toi) then toi, cnx, cny, cx, cy = toi2, cnx2, cny2, cx2, cy2 end

	local toi2, cnx2, cny2, cx2, cy2 = other:collideDot(self.x1, self.y1, sox, soy, -dx, -dy, ox, oy)
	if not toi or (toi2 and toi2 < toi) then toi, cnx, cny, cx, cy = toi2, -cnx2, -cny2, sox+self.x1, soy+self.y1 end

	local toi2, cnx2, cny2, cx2, cy2 = other:collideDot(self.x2, self.y2, sox, soy, -dx, -dy, ox, oy)
	if not toi or (toi2 and toi2 < toi) then toi, cnx, cny, cx, cy = toi2, -cnx2, -cny2, sox+self.x2, soy+self.y2 end

	return toi, cnx, cny, cx, cy
end

function CollisionSegment:collidePolygon(poly, ox, oy, dx, dy, sox, soy)
	local toi, cnx, cny, cx, cy

	for _,seg in ipairs(poly.list) do
		local toi2, cnx2, cny2, cx2, cy2 = self:collideSegment(seg, ox, oy, dx, dy, sox, soy)
		if not toi or (toi2 and toi2 < toi) then toi, cnx, cny, cx, cy = toi2, cnx2, cny2, cx2, cy2 end
	end

	return toi, cnx, cny, cx, cy
end

CollisionPolygon = inherits(nil)

function CollisionPolygon:init(list)
	self.list = list
end

function CollisionPolygon:draw(off_x, off_y)
	off_x = off_x or 0
	off_y = off_y or 0
	for _,obj in ipairs(self.list) do
		obj:draw(off_x, off_y)
	end
end

function love.load()

	col1 = CollisionSegment:new(0, 0, 100, 0)
	ox1, oy1 = 400, 300

	col2 = CollisionSegment:new(0, 0, -100, 0)
	ox2, oy2 = 530, 150

	col = CollisionPolygon:new({
		CollisionSegment:new(0, -50, 20, -50),
		CollisionSegment:new(20, -50, 20, 0),
		CollisionSegment:new(20, 0, -20, 0),
		CollisionSegment:new(-20, 0, -20, -30),
		CollisionSegment:new(-20, -30, 0, -50)
	})
	ox, oy = 400, 300

	xv = 0
	yv = 300

	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setBackgroundColor(0, 0, 0)

	font = love.graphics.newFont(20)
	love.graphics.setFont(font)

	sel = ""
end

function love.keypressed(key)
	if key == "1" then sel = "col1_1"
	elseif key == "2" then sel = "col1_2"
	elseif key == "3" then sel = "col2_1"
	elseif key == "4" then sel = "col2_2"
	elseif key == "5" then sel = "v"
	elseif key == "6" then sel = "o1"
	elseif key == "7" then sel = "o2"
	elseif key == "8" then sel = "o"
	end
end

function love.keyreleased(key)
	if key == "escape" then love.event.quit() end
end

function love.update(dt)

	if love.mouse.isDown("l") then
		if sel == "col1_1" then
			col1.x1 = love.mouse.getX() - ox1
			col1.y1 = love.mouse.getY() - oy1
			col1:update()
		elseif sel == "col1_2" then
			col1.x2 = love.mouse.getX() - ox1
			col1.y2 = love.mouse.getY() - oy1
			col1:update()
		-- elseif sel == "col2_1" then
			-- col2.x1 = love.mouse.getX() - ox2
			-- col2.y1 = love.mouse.getY() - oy2
			-- col2:update()
		-- elseif sel == "col2_2" then
			-- col2.x2 = love.mouse.getX() - ox2
			-- col2.y2 = love.mouse.getY() - oy2
			-- col2:update()
		elseif sel == "v" then
			xv = love.mouse.getX() - col2.x1 - ox2
			yv = love.mouse.getY() - col2.y1 - oy2
		elseif sel == "o1" then
			ox1 = love.mouse.getX()
			oy1 = love.mouse.getY()
		elseif sel == "o2" then
			ox2 = love.mouse.getX()
			oy2 = love.mouse.getY()
		elseif sel == "o" then
			ox = love.mouse.getX()
			oy = love.mouse.getY()
		end
	end
end

function love.draw()

	love.graphics.setColor(255, 0, 0)
	col1:draw(ox1, oy1)

	love.graphics.setColor(0, 96, 128)
	col:draw(ox2, oy2)

	love.graphics.setColor(0, 192, 255)
	col:draw(ox2+xv, oy2+yv)

	local nx, ny = 0, 0

	local toi, cnx, cny, cx, cy = col1:collidePolygon(col, ox2, oy2, xv, yv, ox1, oy1)

	if toi then
		nx = xv * toi
		ny = yv * toi

		love.graphics.setColor(0, 192, 0)
		col:draw(ox2 + nx, oy2 + ny)

		love.graphics.setColor(0, 128, 128)
		love.graphics.line(cx, cy, cx + cnx*10, cy + cny*10)
	end

	local cx, cy = -1000, -1000
	love.graphics.setColor(255, 255, 0)
	if sel == "col1_1" then cx, cy = col1.x1+ox1, col1.y1+oy1
	elseif sel == "col1_2" then cx, cy = col1.x2+ox1, col1.y2+oy1
	elseif sel == "col2_1" then cx, cy = col2.x1+ox2, col2.y1+oy2
	elseif sel == "col2_2" then cx, cy = col2.x2+ox2, col2.y2+oy2
	elseif sel == "v" then cx, cy = col2.x1+ox2 + xv, col2.y1+oy2 + yv
	elseif sel == "o1" then cx, cy = ox1, oy1
	elseif sel == "o2" then cx, cy = ox2, oy2
	end
	love.graphics.circle("line", cx, cy, 5)

	love.graphics.setColor(255, 255, 255)
	love.graphics.print("hello")
end
