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

	local x1 = self.x1 + sox
	local y1 = self.y1 + soy
	local x2 = self.x2 + sox
	local y2 = self.y2 + soy

	local d = (x - x1)*self.nx + (y - y1)*self.ny
	local nd = ((x+dx) - x1)*self.nx + ((y+dy) - y1)*self.ny

	if d > -eps and nd < 0 then
		local toi = d / (d - nd)
		local cx, cy = x + dx*toi, y + dy*toi

		if (x1==x2 or (cx > math.min(x1, x2) and cx < math.max(x1, x2)) )
		and (y1==y2 or (cy > math.min(y1, y2) and cy < math.max(y1, y2)) ) then
			return toi, self.nx, self.ny, cx, cy
		end
	end

	return nil, 0, 0, 0, 0
end

function CollisionSegment:collideSegment(other, ox, oy, dx, dy, sox, soy)
	sox = sox or 0
	soy = soy or 0

	if self.nx*other.nx + self.ny*other.ny >= 0
	or dx*other.nx + dy*other.ny <= 0 then return nil, 0, 0, 0, 0 end

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

function CollisionPolygon:collide(poly, ox, oy, dx, dy, sox, soy)
	if not poly or not poly:instanceOf(CollisionPolygon) then error("only CollisionPolygon currently has collide method, sorry(") end

	local toi, cnx, cny, cx, cy

	for _,seg in ipairs(self.list) do
		local toi2, cnx2, cny2, cx2, cy2 = seg:collidePolygon(poly, ox, oy, dx, dy, sox, soy)
		if not toi or (toi2 and toi2 < toi) then toi, cnx, cny, cx, cy = toi2, cnx2, cny2, cx2, cy2 end
	end

	return toi, cnx, cny, cx, cy
end

function CollisionPolygon:AABB()
	local minx, maxx, miny, maxy
	for _, seg in ipairs(self.list) do
		if not minx then
			minx, maxx = seg.x1, seg.x1
			miny, maxy = seg.y1, seg.y1
		end
		if seg.x1 < minx then minx = seg.x1 end
		if seg.x2 < minx then minx = seg.x2 end
		if seg.y1 < miny then miny = seg.y1 end
		if seg.y2 < miny then miny = seg.y2 end
		if seg.x1 > maxx then maxx = seg.x1 end
		if seg.x2 > maxx then maxx = seg.x2 end
		if seg.y1 > maxy then maxy = seg.y1 end
		if seg.y2 > maxy then maxy = seg.y2 end
	end

	return minx, maxx, miny, maxy
end

function drawCollisions(list, off_x, off_y)
	if not list then return end

	for _, cobj in ipairs(list) do
		cobj:draw(off_x, off_y)
	end
end

function collideList(cobj, ox, oy, dx, dy, list, sox, soy)
	if not list then return end

	local toi, cnx, cny, cx, cy

	for _,obj in ipairs(list) do
		local toi2, cnx2, cny2, cx2, cy2 = obj:collide(cobj, ox, oy, dx, dy, sox, soy)
		if not toi or (toi2 and toi2 < toi) then toi, cnx, cny, cx, cy = toi2, cnx2, cny2, cx2, cy2 end
	end

	return toi, cnx, cny, cx, cy
end