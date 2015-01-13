function print_rek(t, max_depth, depth)
	depth = depth or 0
	if max_depth and depth > max_depth then return end

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
			elseif type(v) == "userdata" then
				print(' '..ident..k.." = ("..type(v)..")")
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

local setColor = love.graphics.setColor
local _r, _g, _b, _a

function love.graphics.setColor(r, g, b, a)
	a = a or 255

	_r, _g, _b, _a = love.graphics.getColor()
	setColor(r, g, b, a)
end

function love.graphics.lastColor()
	setColor(_r, _g, _b, _a)
end