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
	collision_objects = {} -- 1..n => CollisionObject, static collision shapes

}

function world:getWidth() return self.tilewidth * self.width end
function world:getHeight() return self.tileheight * self.width end

function world:load(file)
	self.level = Layer:new(32, 32, 4, 4)

	table.insert(self.spawn_points, {x=0, y=0})
	self.level.tiles = {
		{ 1, 2, 3, 4 },
		{ 5, 6, 7, 8 },
		{ 9, 10, 11, 12,},
		{ 13, 14, 15, 16 }
	}

	self.tileset = {
		Tile:new("tiles.png", 0, 0, 32, 32) 
	}

	self.tilewidth = self.level.tilewidth
	self.tileheight = self.level.tileheight
	self.width = self.level.width
	self.height = self.level.height
end

function world:draw()
end

function world:update()
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

	print_rek(world.tileset)
	os.exit(0)

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


