require("oop")
require("image_man")
require("loadxml")
require("collision")
require("platform")
require("utils")

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
				layer.tiles[j] = {}
				for i=1, lw do
					local ntile = ndata[(j-1)*lw + i]
					if not ntile then error("broken tmx") end
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
			elseif sub.xarg.name == "platform" then
				local pls = {}
				local wps = {}
				for _, nobj in ipairs(sub) do
					if nobj.label ~= "object" then error("bad object") end
					if nobj.xarg.width and nobj.xarg.height then
						-- platform
						local x = math.max(0, math.min(map:getWidth(), tonumber(nobj.xarg.x)))
						local y = math.max(0, math.min(map:getHeight(), tonumber(nobj.xarg.y)))

						local w = math.ceil(tonumber(nobj.xarg.width) / map.level.tilewidth)
						local h = math.ceil(tonumber(nobj.xarg.height) / map.level.tileheight)

						local tx = math.ceil(x / map.level.tilewidth)
						local ty = math.ceil(y / map.level.tileheight)

						if tx + w > map.level.width then w = map.level.width - tx end
						if ty + h > map.level.height then h = map.level.height - ty end

						local til = {}
						for j = 1, w do
							til[j] = {}
							for i = 1, h do
								til[j][i] = map.level.tiles[ty + j][tx + i]
								map.level.tiles[ty + j][tx + i] = 0
							end
						end

						local lay = Layer:new(
							map.level.tilewidth, map.level.tileheight,
							w, h
						)
						lay.tiles = til
						local pl = Platform:new(lay, way)
						pl.x = x
						pl.y = y
						platforms:insert(pl)

						pls[#platforms] = pl
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
				end
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
