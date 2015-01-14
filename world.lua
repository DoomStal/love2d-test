require("loadxml")

world = {
	tilewidth = 32,
	tileheight = 32,
	width = 0, -- same as level's
	height = 0, -- same as level's

	tileset = {}, -- (tile gid) => Tile

	bg_layers = {}, -- [n] => Layer, background layers
	level = nil, -- Layer, used for collision
	fg_layers = {}, -- [n] => Layer, foreground layers

	spawn_points = {}, -- [n] => {x,y}
	collision_objects = {}, -- 1..n => CollisionObject, static collision shapes

	platforms = Collection:new(), -- Platform

	drawSet = Set:new(), -- Entity
	updateSet = Set:new(), -- Entity
	moveSet = Set:new(), -- EntityMoving
}

function world:getWidth() return self.tilewidth * self.width end
function world:getHeight() return self.tileheight * self.height end

function world:insert(entity)
	self.drawSet:insert(entity)
	self.updateSet:insert(entity)
	if entity:instanceOf(EntityMoving) then self.moveSet:insert(entity) end
	return entity
end

function world:remove(entity)
	self.drawSet:remove(entity)
	self.updateSet:remove(entity)
	self.moveSet:remove(entity)
end

function world:load(file)
	local xml = LoadXML(love.filesystem.read(file))

	local nmap = xml[2]
	self.tilewidth = tonumber(nmap.xarg.tilewidth)
	self.tileheight = tonumber(nmap.xarg.tileheight)
	self.width = tonumber(nmap.xarg.width)
	self.height = tonumber(nmap.xarg.height)

	-- load tilesets and layers
	for _, sub in ipairs(nmap) do
		if sub.label == "tileset" then
			local firstgid = tonumber(sub.xarg.firstgid)
			local ntileset = sub
			if sub.xarg.source then
				local xml_t = LoadXML(love.filesystem.read(sub.xarg.source))
				ntileset = xml_t[2]
			end
			local tw = tonumber(ntileset.xarg.tilewidth)
			local th = tonumber(ntileset.xarg.tileheight)
			local nimg = ntileset[1]
			local imagefile = nimg.xarg.source
			local iw = math.floor(tonumber(nimg.xarg.width) / tw)
			local ih = math.floor(tonumber(nimg.xarg.height) / th)
			local j = 0
			while j < ih do
				local qy = j * th

				local i = 0
				while i < iw do
					local qx = i * tw
					self.tileset[firstgid + iw*j + i] = Tile:new(imagefile, qx, qy, tw, th)
					i = i + 1
				end
				j = j + 1
			end
			for i=2, #ntileset do
				local ntile = ntileset[i]
				if ntile.label == "tile" then
					local id = tonumber(ntile.xarg.id)
					if ntile[1].label == "objectgroup" then
						local tile_collisions = {}
						loadCollisionObjects(ntile[1], tile_collisions)
						self.tileset[firstgid + id].collision_objects = tile_collisions
					end
				end
			end
		elseif sub.label == "layer" then
			local lw = tonumber(sub.xarg.width)
			local lh = tonumber(sub.xarg.height)

			local layer = Layer:new(self.tilewidth, self.tileheight, lw, lh)

			local ndata = sub[1]
			for j=1, lh do
				layer.tiles[j] = {}
				for i=1, lw do
					local ntile = ndata[(j-1)*lw + i]
					if not ntile then error("broken tmx") end
					layer.tiles[j][i] = tonumber(ntile.xarg.gid)
				end
			end

			if not self.level then
				if sub.xarg.name == "level" then
					self.level = layer
				else
					table.insert(self.bg_layers, layer)
				end
			else
				table.insert(self.fg_layers, layer)
			end
		elseif sub.label == "objectgroup" then
			if sub.xarg.name == "collision" then
				loadCollisionObjects(sub, self.collision_objects)
			elseif sub.xarg.name == "platform" then
				local pls = {}
				local wps = {}
				for _, nobj in ipairs(sub) do
					if nobj.label ~= "object" then error("bad object") end
					if nobj.xarg.width and nobj.xarg.height then
						-- platform
						local x = math.max(0, math.min(self:getWidth(), tonumber(nobj.xarg.x)))
						local y = math.max(0, math.min(self:getHeight(), tonumber(nobj.xarg.y)))

						local w = math.ceil(tonumber(nobj.xarg.width) / self.level.tilewidth)
						local h = math.ceil(tonumber(nobj.xarg.height) / self.level.tileheight)

						local tx = math.ceil(x / self.level.tilewidth)
						local ty = math.ceil(y / self.level.tileheight)

						if tx + w > self.level.width then w = self.level.width - tx end
						if ty + h > self.level.height then h = self.level.height - ty end

						local til = {}
						for j = 1, w do
							til[j] = {}
							for i = 1, h do
								til[j][i] = self.level.tiles[ty + j][tx + i]
								self.level.tiles[ty + j][tx + i] = 0
							end
						end

						local lay = Layer:new(
							self.level.tilewidth, self.level.tileheight,
							w, h
						)
						lay.tiles = til
						local pl = Platform:new(lay, way)
						pl.x = x
						pl.y = y
						self.platforms:insert(pl)

						pls[#self.platforms] = pl
						if nobj.xarg.name then
							pls["n_"..nobj.xarg.name] = pl
							if wps["n_"..nobj.xarg.name] then
								pl.waypoints = wps["n_"..nobj.xarg.name]
								adjustWaypoints(wps["n_"..nobj.xarg.name], pl)
							end
						else
							for k,vertices in pairs(wps) do
								if vertices[1].x >= pl.x and vertices[1].x <= pl.x + pl.width
								and vertices[1].y >= pl.y and vertices[1].y <= pl.y + pl.height then
									adjustWaypoints(vertices, pl)
									pl.waypoints = vertices
									break
								end
							end
						end
					else
						-- waypoints
						local nobjs = nobj[1]
						if not nobjs then error("bad object") end

						local vertices = parseObject(nobj)
						if nobjs.label == "polyline" or nobjs.label == "polygon" then
							if nobjs.label == "polygon" then vertices.loop = true end
							table.insert(wps, vertices)
							if nobj.xarg.name then
								wps["n_"..nobj.xarg.name] = vertices
								if pls["n_"..nobj.xarg.name] then
									pls["n_"..nobj.xarg.name].waypoints = vertices
									adjustWaypoints(vertices, pls["n_"..nobj.xarg.name])
								end
							else
								for k,pl in pairs(pls) do
									if vertices[1].x >= pl.x and vertices[1].x <= pl.x + pl.width
									and vertices[1].y >= pl.y and vertices[1].y <= pl.y + pl.height then
										adjustWaypoints(vertices, pl)
										pl.waypoints = vertices
										break
									end
								end
							end
						end
					end
				end -- nobj in sub
			else
				for _, nobj in ipairs(sub) do
					if nobj.xarg.type == "spawn" then
						table.insert(self.spawn_points, {
							x = tonumber(nobj.xarg.x)+tonumber(nobj.xarg.width)/2,
							y = tonumber(nobj.xarg.y)+tonumber(nobj.xarg.height)
						})
					end
				end
			end
		end -- sub.label
	end
end

function world:draw(off_x, off_y)
	for _,layer in ipairs(self.bg_layers) do
		layer:draw(off_x, off_y)
	end
	if self.level then self.level:draw(off_x, off_y) end

	for _,v in ipairs(self.platforms) do
		v:draw(off_x, off_y)
	end

	for v in pairs(self.drawSet.elements) do
		v:draw(off_x, off_y)
	end

	for _,layer in ipairs(self.fg_layers) do
		layer:draw(off_x, off_y)
	end
end

function world:update(dt)
	for v in pairs(self.updateSet.elements) do
		v:update(dt)
	end
	for v in ipairs(self.platforms) do
		v:update(dt)
	end
end

function world:move()
	for v in pairs(self.moveSet.elements) do
		v:move()
	end
end

function world:collide(entity, dx, dy)
end

-- classes

Tile = inherits(nil)

function Tile:init(image_name, x, y, w, h)
	self.image = ImageManager:get(image_name)
	self.x = x or 0
	self.y = y or 0
	local iw, ih = self.image:getDimensions()
	self.w = w or iw
	self.h = h or ih
	self.quad = love.graphics.newQuad(self.x, self.y, self.w, self.h, iw, ih)
end

function Tile:draw(off_x, off_y, flip_x, flip_y, flip_diag)
	love.graphics.draw(self.image, self.quad, off_x, off_y)
end

-- uses global world.tileset
Layer = inherits(nil)

function Layer:init(tw, th, w, h)
	tw = tw or 1
	th = th or 1
	w = w or 0
	h = h or 0

	self.tilewidth = tw
	self.tileheight = th
	self.width = w
	self.height = h
	self.tiles = {} -- [y][x] => (tile gid)
	for y = 1, h do self.tiles[y] = {} end
end

function Layer:draw(off_x, off_y)
	local sw = love.graphics.getWidth()
	local sh = love.graphics.getHeight()

	local minx = math.max(1, math.floor(-off_x/self.tilewidth))
	local maxx = math.min(self.width, math.ceil( (sw-off_x)/self.tilewidth ))
	local miny = math.max(1, math.floor(-off_y/self.tileheight))
	local maxy = math.min(self.height, math.ceil( (sh-off_y)/self.tileheight ))

	for y = miny, maxy do
		for x = minx, maxx do
			local t = world.tileset[self.tiles[y][x]]
			if t then
				t:draw(
					(x-1)*self.tilewidth + off_x,
					(y-1)*self.tileheight + off_y
				)
			end
		end
	end
end

function Layer:collide(entity, dx, dy, sox, soy)
	sox = sox or 0
	soy = soy or 0

	local minx = math.max(1, math.floor( (entity.x-entity.width/2-sox)/self.tilewidth ))
	local maxx = math.min(self.width, math.ceil( (entity.x+entity.width/2-sox)/self.tilewidth ) + 1)
	local miny = math.max(1, math.floor( (entity.y-entity.height-soy)/self.tileheight ))
	local maxy = math.min(self.height, math.ceil( (entity.y-soy) / self.tileheight ) + 1)

	local toi, cnx, cny, cx, cy

	for y = miny, maxy do
		for x = minx, maxx do
			local t = world.tileset[self.tiles[y][x]]
			if t then
				local toi2, cnx2, cny2, cx2, cy2 = collideList(
					entity.collision_object,
					entity.x,
					entity.y,
					dx,
					dy,
					t.collision_objects,
					(x-1)*self.tilewidth+sox,
					(y-1)*self.tileheight+soy
				)
				if not toi or (toi2 and toi2 < toi) then toi, cnx, cny, cx, cy = toi2, cnx2, cny2, cx2, cy2 end
			end
		end
	end

	return toi, cnx, cny, cx, cy
end

function Layer:getWidth() return self.tilewidth * self.width end
function Layer:getHeight() return self.tileheight * self.height end

-- utility functions

function parseObject(nobj)
	local nobjs = nobj[1]
	if not nobjs then error("bad object") end

	local vertices = nil

	if nobjs.label == "polyline" or nobjs.label == "polygon" then
		vertices = {}
		local x = tonumber(nobj.xarg.x)
		local y = tonumber(nobj.xarg.y)
		local i = 1
		while true do
			local ni, j, vx, vy = string.find(nobjs.xarg.points, "%s*(-?%d+),(-?%d+)%s*", i)
			if not ni then break end
			vx = vx + x
			vy = vy + y
			table.insert(vertices, {x=vx, y=vy})
			i = j + 1
		end
	end

	return vertices
end

function loadCollisionObjects(sub, collision_objects, ox, oy)
	ox = ox or 0
	oy = oy or 0
	for _, nobj in ipairs(sub) do
		if nobj.label ~= "object" then error("bad object") end
		if nobj.xarg.width and nobj.xarg.height then
			local x = tonumber(nobj.xarg.x)
			local y = tonumber(nobj.xarg.y)
			local w = tonumber(nobj.xarg.width)
			local h = tonumber(nobj.xarg.height)
			table.insert(collision_objects, CollisionPolygon:new({
				CollisionSegment:new(x, y, x+w, y),
				CollisionSegment:new(x+w, y, x+w, y+h),
				CollisionSegment:new(x+w, y+h, x, y+h),
				CollisionSegment:new(x, y+h, x, y)
			}))
		else
			local nobjs = nobj[1]
			if not nobjs then error("bad object") end

			local vertices = parseObject(nobj)
			if nobjs.label == "polyline" or nobjs.label == "polygon" then
				local seg_list = {}
				for i = 1, #vertices do
					if i>1 then
						table.insert(seg_list, CollisionSegment:new(
							vertices[i-1].x, vertices[i-1].y,
							vertices[i].x, vertices[i].y
						))
					end
				end
				if nobjs.label == "polygon" then
					table.insert(seg_list, CollisionSegment:new(
						vertices[#vertices].x, vertices[#vertices].y,
						vertices[1].x, vertices[1].y
					))
				end
				table.insert(collision_objects, CollisionPolygon:new(seg_list))
			end
		end
	end
end

function adjustWaypoints(vertices, pl)
--	local ox = vertices[1].x - pl.x
--	local oy = vertices[1].y - pl.y
	local ox = pl.width / 2
	local oy = pl.height / 2
	for k2,v in ipairs(vertices) do
		vertices[k2].x = v.x - ox
		vertices[k2].y = v.y - oy
	end
end

