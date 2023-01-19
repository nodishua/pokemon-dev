--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2021 TianJi Information Technology Inc.
--


--
-- CCollection result inner implement
-- gc reduce and fast
--

CCollection.inner_result = {}
CCollection.inner_result.__index = CCollection.inner_result

function CCollection.inner_result.new()
	local ret = setmetatable({
		single = nil,
		hash = nil, -- {key: true}
		n = 0,
		own = false,
		ownstub = nil,
	}, CCollection.inner_result)
	return ret
end

function CCollection.inner_result:shallowcopy()
	local ret = setmetatable({
		single = self.single,
		hash = self.hash,
		n = self.n,
		own = false,
		ownstub = nil,
	}, CCollection.inner_result)
	-- ret:hash_copy_()
	return ret
end

function CCollection.inner_result:swallow(other)
	if self == other then
		return self
	end

	-- keep right result
	self.hash = other.hash
	self.single = other.single
	self.n = other.n
	-- swap stub may be own other.hash
	if other.ownstub then
		self.ownstub, other.ownstub = other.ownstub, self.ownstub
	end
	self.own = (self.ownstub and self.hash == self.ownstub)
	other.own = (other.ownstub and other.hash == other.ownstub)
	return self
end

function CCollection.inner_result:resetSingle(single)
	self.single = single
	self.hash = nil
	self.n = single == nil and 0 or 1
	self.own = false
	-- no change for ownstub
	return self
end

function CCollection.inner_result:resetHash(hash, size)
	self.single = nil
	self.hash = hash
	self.n = size
	self.own = (self.ownstub and hash == self.ownstub)
	-- no change for ownstub
	return self
end

function CCollection.inner_result:size()
	assert(not self.single or (self.n == 1), "result size error " .. self.n)
	-- -- TODO: remove it when stable
	-- assert(not self.hash or (self.n == table.nums(self.hash)), table.nums(self.hash or {}) .. " result size error " .. self.n)

	return self.n
end

function CCollection.inner_result:contain(key)
	if self.single == key then
		return true
	end
	if self.hash then
		return self.hash[key]
	end
	return false
end

function CCollection.inner_result:the_one()
	assert(self.n == 1, "result not single")

	if self.single then
		return self.single
	end
	local key = next(self.hash)
	return key
end

function CCollection.inner_result:pairs()
	if self.single then
		local first = true
		return function()
			if first then
				first = false
				return self.single, true
			end
		end
	end

	return pairs(self.hash)
end

-- @param array: may be dirty
function CCollection.inner_result:to_array(array)
	if self.single then
		table.clear(array)
		table.insert(array, self.single)
		return
	end
	if self.hash then
		local i = 0
		for k, _ in pairs(self.hash) do
			i = i + 1
			array[i] = k
		end
		local n = table.length(array)
		for j = 1, n - i do
			table.remove(array)
		end
		return
	end

	table.clear(array)
end

function CCollection.inner_result:isEmpty()
	return self.n == 0
end

function CCollection.inner_result:print()
	local c = ""
	if self.single then
		c = tostring(self.single)
	end
	if self.hash then
		c = table.concat(table.keys(self.hash), ", ")
	end
	print(self, string.format("{%s} %s %s", c, self.n, self.own and "own" or ""))
end

function CCollection.inner_result:saved_type_()
	if self.single then
		return 1
	end
	if self.hash then
		return 2
	end
	return 0
end

function CCollection.inner_result:hash_copy_()
	if self.hash and not self.own then
		self.own = true
		if self.ownstub then
			table.clear(self.ownstub)
			table.merge(self.ownstub, self.hash)
			self.hash = self.ownstub
		else
			self.hash = table.shallowcopy(self.hash)
			self.ownstub = self.hash
		end
	end
	return self.hash
end

function CCollection.inner_result:insert_one_(single)
	-- self had single
	if self.single then
		if self.single ~= single then
			self.own = true
			self.n = 2
			if self.ownstub then
				-- TODO: any other will ref the table?
				table.clear(self.ownstub)
				self.hash = self.ownstub
				self.hash[self.single] = true
				self.hash[single] = true
			else
				self.hash = {
					[self.single] = true,
					[single] = true,
				}
				self.ownstub = self.hash
			end
			self.single = nil
		end

	-- self had hash
	elseif self.hash then
		if not self.hash[single] then
			local h = self:hash_copy_()
			h[single] = true
			self.n = self.n + 1
		end

	-- self had nothing
	else
		self.single = single
	end
	return self
end

function CCollection.inner_result:erase_one_(single)
	-- self had single
	if self.single then
		if self.single == single then
			self:resetSingle()
		end

	-- self had hash
	elseif self.hash then
		if self.hash[single] then
			local h = self:hash_copy_()
			h[single] = nil
			self.n = self.n - 1
			return self
		end

	-- self had nothing
	end
	return self
end

function CCollection.inner_result:get_order_byindex(index)
	assert(index:is_order(), "the index no order")

	local order = table.keys(self.hash)
	table.sort(order, index._keycmp)
	return order
end

-- @param op: + union
--            - difference
--            & intersection
--            ^ symmetric_difference
-- @param self: the lifetime same with query invoke
-- @param other: may be the tempresult, and it volatility.
-- NOTICE: param other will be broken when invoke done!!!
local SetOpFuncMap = {
	["+"] = false,
	["-"] = false,
	["&"] = false,
	["^"] = false,
}
function CCollection.inner_result:doSetOp(op, other)
	local f = SetOpFuncMap[op]
	assert(f, "nu such set op " .. op)
	assert(self ~= other, "self same with other, may be all are tempresult")

	return f(self, other)
end

-- both dest and other were temp result
-- so you could use anyone to store the new result
-- only - difference no commutative property
local function op_result_hash_with(dest, other, f, keepOrder)
	if not keepOrder and other.own then
		dest, other = other, dest
	end
	dest:hash_copy_()
	f(dest.hash, other.hash)
	dest.n = table.nums(dest.hash)
	return dest
end

-- union: a + b
-- ex. {1,2} + {2,3} = {1,2,3}
function CCollection.inner_result.setUnion(self, other)
	local type_, type2_ = self:saved_type_(), other:saved_type_()
	if type2_ == 0 then return self end
	if type_ == 0 then return self:swallow(other) end

	if type_ == type2_ then
		-- 1 single
		if type_ == 1 then
			if self.single == other.single then
				return self
			end
			return self:insert_one_(other.single)
		end
		-- 2 hash
		return self:swallow(op_result_hash_with(self, other, maptools.union_with))
	end

	-- a hash, b single
	local a, b = self, other
	if type_ == 1 then
		a, b = other, self
	end
	return self:swallow(a:insert_one_(b.single))
end
SetOpFuncMap["+"] = CCollection.inner_result.setUnion

-- intersection: a & b
-- ex. {1,2} & {2,3} = {2}
function CCollection.inner_result.setIntersection(self, other)
	local type_, type2_ = self:saved_type_(), other:saved_type_()
	if type_ == 0 or type2_ == 0 then return self:resetSingle() end

	if type_ == type2_ then
		-- 1 single
		if type_ == 1 then
			if self.single == other.single then
				return self
			end
			return self:resetSingle()
		end
		-- 2 hash
		return self:swallow(op_result_hash_with(self, other, maptools.intersection_with))
	end

	-- a hash, b single
	local a, b = self, other
	if type_ == 1 then
		a, b = other, self
	end
	-- TODO: here will be free table if a.own
	return self:swallow(a:resetSingle(a.hash[b.single] and b.single))
end
SetOpFuncMap["&"] = CCollection.inner_result.setIntersection

-- symmetric_difference: a ^ b
-- ex. {1,2} ^ {2,3} = {1,3}
function CCollection.inner_result.setSymmetricDifference(self, other)
	local type_, type2_ = self:saved_type_(), other:saved_type_()
	if type_ == 0 or type2_ == 0 then return self:resetSingle() end

	if type_ == type2_ then
		-- 1 single
		if type_ == 1 then
			if self.single == other.single then
				return self:resetSingle()
			end
			return self:insert_one_(other.single)
		end
		-- 2 hash
		return self:swallow(op_result_hash_with(self, other, maptools.xor_with))
	end

	-- a hash, b single
	local a, b = self, other
	if type_ == 1 then
		a, b = other, self
	end
	if a.hash[b.single] then
		-- TODO: here will be free table if a.own
		return self:swallow(a:erase_one_(b.single))
	else
		-- TODO: here will be free table if a.own
		return self:swallow(a:insert_one_(b.single))
	end
end
SetOpFuncMap["^"] = CCollection.inner_result.setSymmetricDifference

-- difference: a - b
-- ex. {1,2} - {2,3} = {1}
function CCollection.inner_result.setDifference(self, other)
	local type_, type2_ = self:saved_type_(), other:saved_type_()
	if type_ == 0 or type2_ == 0 then return self end

	if type_ == type2_ then
		-- 1 single
		if type_ == 1 then
			if self.single == other.single then
				return self:resetSingle()
			end
			return self
		end
		-- 2 hash
		return self:swallow(op_result_hash_with(self, other, maptools.minus_with, true))
	end

	-- NOTICE: could not swap self and other
	if type_ == 1 then
		if other.hash[self.single] then
			return self:resetSingle()
		end
		return self
	end
	return self:erase_one_(other.single)
end
SetOpFuncMap["-"] = CCollection.inner_result.setDifference