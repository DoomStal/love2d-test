camera = {}
camera.x = 0
camera.y = 0

function camera:setPosition(x, y)
  self.x = x or self.x
  self.y = y or self.y
  self.x = math.floor(self.x + 0.5)
  self.y = math.floor(self.y + 0.5)
end

