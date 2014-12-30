require("oop")
require("image_man")
require("loadxml")

function print_rek(t, max_depth, depth)
	depth = depth or 0
	if depth > max_depth then return end

	if(type(t) ~= "table") then
		print('('..type(t)..") '"..t..'\'')
		return
	end
	if depth == 0 then print('(table) {') end
	local ident = string.rep(" ", depth)
	for k,v in pairs(t) do
		if type(v) ~= "table" then
			if nil == v then
				print(' '..ident..k.." = nil'")
			else
				print(' '..ident..k.." = ("..type(v)..") '"..v..'\'')
			end
		else
			print(' '..ident..k.." = (table) {")
			print_rek(v, max_depth, depth+1)
			print(' '..ident..'}')
		end
	end
	if depth == 0 then print('}') end
end

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
	local maxx = math.min(self.width, math.floor( (sw-off_x)/self.tilewidth ))
	local miny = math.max(1, math.floor(-off_y/self.tileheight))
	local maxy = math.min(self.height, math.floor( (sh-off_y)/self.tileheight ))

	for y = miny, maxy do
		for x = minx, maxx do
			local t = tileset[self.tiles[y][x]]
--			print(self.tiles[y][x])
			if t then
				t:draw(
					x*self.tilewidth + off_x,
					y*self.tileheight + off_y
				)
			end
		end
	end
--	os.exit(0)
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

function Map.load(file)
	local xml = LoadXML(love.filesystem.read(file))

	local map = Map:new()

	local nmap = xml[2]

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
	end

	return map
end

