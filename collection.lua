require("oop")

Collection = inherits(nil)

function Collection:insert(value)
	self[#self + 1] = value
	return value
end

function Collection:remove(index)
	if index>0 and index<=#self then
		self[index] = self[#self]
		print(#self)
		self[#self] = nil
		print(#self)
	end
end
