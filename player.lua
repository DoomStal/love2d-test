require("oop")
require("entity")

Player = inherits(EntityLiving)

Player.color_r = 0
Player.color_g = 255
Player.color_b = 0

Player.width = 40
Player.height = 56

Player.flip_x = false

local pw, ph, ph1 = Player.width/2, Player.height, Player.height - Player.width/2
Player.collision_object_r = CollisionPolygon:new({
	CollisionSegment:new(-pw, -ph1, 0, -ph),
	CollisionSegment:new(0, -ph, pw, -ph1),
	CollisionSegment:new(pw, -ph, pw, 0),
	CollisionSegment:new(pw, 0, -pw, 0),
	CollisionSegment:new(-pw, 0, -pw, -ph1),
	CollisionSegment:new(0, -ph, pw, -ph)
})

Player.collision_object_l = CollisionPolygon:new({
	CollisionSegment:new(-pw, -ph1, 0, -ph),
	CollisionSegment:new(0, -ph, pw, -ph1),
	CollisionSegment:new(pw, -ph1, pw, 0),
	CollisionSegment:new(pw, 0, -pw, 0),
	CollisionSegment:new(-pw, 0, -pw, -ph),
	CollisionSegment:new(-pw, -ph, 0, -ph)
})

Player.collision_object = Player.collision_object_r

local a = Animation:new()
a.rate = 0
a.frames = {
	Frame:new("stand.png", 48, 83)
}
Player.animations["stand"] = a

a = Animation:new()
a.rate = 15
a.loop = true
a.frames = {
	Frame:new("run.png", 48, 81, 0, 0, 96),
	Frame:new("run.png", 48, 81, 96, 0, 96),
	Frame:new("run.png", 48, 81, 192, 0, 96),
	Frame:new("run.png", 48, 81, 288, 0, 96),
	Frame:new("run.png", 48, 81, 384, 0, 96),
	Frame:new("run.png", 48, 81, 480, 0, 96),
}
Player.animations["run"] = a

a = Animation:new()
a.rate = 0
a.frames = {
	Frame:new("jump.png", 48, 79)
}
Player.animations["jump"] = a

Player:setAnimation("stand")

function Player:update(dt)
	EntityLiving.update(self, dt)
	if self.flip_x then
		self.collision_object = self.collision_object_l
	else
		self.collision_object = self.collision_object_r
	end
end
