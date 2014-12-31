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