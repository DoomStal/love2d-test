require("oop")
require("image_man")
require("loadxml")
require("collision")
require("utils")

Tile = inherits(nil)

function Tile:init(image_name, x, y, w, h)
	self.image = ImageManager:get(image_name)
	self.x = x or 0
	self.y = y or 0
	local iw,ih = self.image:getDimensions()
	self.w = w or iw
	self.h = h or ih
	self.quad = love.graphics.newQuad(self.x, self.y, self.w, self.h, iw, ih)
end

function Tile:draw(off_x, off_y, flip_x, flip_y, flip_diag)
	love.graphics.draw(self.image, self.quad, off_x, off_y)
end

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
	self.tiles = {}
end

function Layer:draw(tileset, off_x, off_y)
	local sw = love.graphics.getWidth()
	local sh = love.graphics.getHeight()

	local minx = math.max(1, math.floor(-off_x/self.tilewidth))
	local maxx = math.min(self.width, math.ceil( (sw-off_x)/self.tilewidth ))
	local miny = math.max(1, math.floor(-off_y/self.tileheight))
	local maxy = math.min(self.height, math.ceil( (sh-off_y)/self.tileheight ))

	for y = miny, maxy do
		for x = minx, maxx do
			local t = tileset[self.tiles[y][x]]
			if t then
				t:draw(
					(x-1)*self.tilewidth + off_x,
					(y-1)*self.tileheight + off_y
				)
			end
		end
	end
end

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

function Layer:collideEntity(tileset, entity, dx, dy, sox, soy)
	sox = sox or 0
	soy = soy or 0

	local minx = math.max(1, math.floor( (entity.x-entity.width/2-sox)/self.tilewidth ))
	local maxx = math.min(self.width, math.ceil( (entity.x+entity.width/2-sox)/self.tilewidth ) + 1)
	local miny = math.max(1, math.floor( (entity.y-entity.height-soy)/self.tileheight ))
	local maxy = math.min(self.height, math.ceil( (entity.y-soy) / self.tileheight ) + 1)

	if self == map.level then
		entity.col_minx = minx
		entity.col_maxx = maxx
		entity.col_miny = miny
		entity.col_maxy = maxy
	end

	local toi, cnx, cny, cx, cy

	for y = miny, maxy do
		for x = minx, maxx do
			local t = tileset[self.tiles[y][x]]
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

Map = inherits(nil)

Map.tilewidth = 32
Map.tileheight = 32
Map.width = 0
Map.height = 0

Map.tiles = {}

Map.bg_layers = {}
Map.level = nil
Map.fg_layers = {}

Map.spawn_points = {}
Map.collision_objects = {}

function Map:getWidth() return self.tilewidth * self.width end
function Map:getHeight() return self.tileheight * self.height end

function Map.load(file)
	local xml = LoadXML(love.filesystem.read(file))

	local map = Map:new()

	local nmap = xml[2]

	map.tilewidth = tonumber(nmap.xarg.tilewidth)
	map.tileheight = tonumber(nmap.xarg.tileheight)
	map.width = tonumber(nmap.xarg.width)
	map.height = tonumber(nmap.xarg.height)

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
					map.tiles[firstgid + iw*j + i] = Tile:new(imagefile, qx, qy, tw, th)
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
						map.tiles[firstgid + id].collision_objects = tile_collisions
					end
				end
			end
		end
		if sub.label == "layer" then
			local lw = tonumber(sub.xarg.width)
			local lh = tonumber(sub.xarg.height)

			local layer = Layer:new(map.tilewidth, map.tileheight, lw, lh)

			local ndata = sub[1]
			for j=1, lh do
				for i=1, lw do
					local ntile = ndata[(j-1)*lw + i]
					if not ntile then error("broken tmx") end
					if not layer.tiles[j] then layer.tiles[j] = {} end
					layer.tiles[j][i] = tonumber(ntile.xarg.gid)
				end
			end

			if not map.level then
				if sub.xarg.name == "level" then
					map.level = layer
				else
					table.insert(map.bg_layers, layer)
				end
			else
				table.insert(map.fg_layers, layer)
			end
		end
		if sub.label == "objectgroup" then
			if sub.xarg.name == "collision" then
				loadCollisionObjects(sub, map.collision_objects)
			else
				for _, nobj in ipairs(sub) do
					if nobj.xarg.type == "spawn" then
						table.insert(map.spawn_points, {
							x = tonumber(nobj.xarg.x)+tonumber(nobj.xarg.width)/2,
							y = tonumber(nobj.xarg.y)+tonumber(nobj.xarg.height)
						})
					end
				end
			end
		end
	end

	return map
end
