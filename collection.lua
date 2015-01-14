Collection = inherits(nil)

function Collection:insert(value)
	self[#self + 1] = value
	return value
end

function Collection:remove(index)
	if index>0 and index<=#self then
		self[index] = self[#self]
		self[#self] = nil
	end
end

Set = inherits(nil)
Set.elements = {}

function Set:insert(value)
	self.elements[value] = value
	return value
end

function Set:contains(value)
	return nil ~= self.elements[value]
end

function Set:remove(value)
	self.elements[value] = nil
end
