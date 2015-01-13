function Layer:drawCollisions(tileset, off_x, off_y, draw_all)
	local sw = love.graphics.getWidth()
	local sh = love.graphics.getHeight()

	local minx = math.max(player.col_minx, math.floor(-off_x/self.tilewidth))
	local maxx = math.min(player.col_maxx, math.ceil( (sw-off_x)/self.tilewidth ))
	local miny = math.max(player.col_miny, math.floor(-off_y/self.tileheight))
	local maxy = math.min(player.col_maxy, math.ceil( (sh-off_y)/self.tileheight ))

	if draw_all then
		minx = 1
		maxx = self.width
		miny = 1
		maxy = self.height
	end

	for y = miny, maxy do
		for x = minx, maxx do
			local t = tileset[self.tiles[y][x]]
			if t then
				drawCollisions(t.collision_objects,
					(x-1)*self.tilewidth + off_x,
					(y-1)*self.tileheight + off_y
				)
			end
		end
	end
end

