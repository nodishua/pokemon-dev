--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--


local _isRef = isRef

local CSTLBase = require("luastl.stlbase")
local CList = class("CList", CSTLBase)
globals.CList = CList

function CList:ctor()
	CSTLBase.ctor(self)

	self:clear()
end

function CList:clear()
	if self.m then
		for _, v in pairs(self.m) do
			if _isRef(v) then
				v:autorelease()
			end
		end
	end

	self.m = {}
	self.msize = 0
	self.counter = 0
	self.head = nil
	self.tail = nil
end

function CList:push_back(val)
	if _isRef(val) then
		val:retain()
	end
	self.counter = self.counter + 1
	self.msize = self.msize + 1

	local idx = self.counter
	self.m[idx] = {
		prev = self.tail,
		data = val,
	}
	if self.tail then
		self.m[self.tail].next = idx
	end
	self.tail = idx
	self.head = self.head or idx
end

function CList:pop_back()
	if self.tail == nil then
		return nil
	end

	local tail = self.m[self.tail]
	local ret = tail.data
	if _isRef(ret) then
		ret:autorelease()
	end

	self.msize = self.msize - 1
	self.tail = tail.prev
	if self.tail == nil then
		self.head = nil
	else
		self.m[self.tail].next = nil
	end
	return ret
end

function CList:push_front(val)
	if _isRef(val) then
		val:retain()
	end

	self.counter = self.counter + 1
	self.msize = self.msize + 1

	local idx = self.counter
	self.m[idx] = {
		next = self.head,
		data = val,
	}
	if self.head then
		self.m[self.head].prev = idx
	end
	self.head = idx
	self.tail = self.tail or idx
end

function CList:pop_front()
	if self.head == nil then
		return nil
	end

	local head = self.m[self.head]
	local ret = head.data
	if _isRef(ret) then
		ret:autorelease()
	end

	self.msize = self.msize - 1
	self.head = head.next
	if self.head == nil then
		self.tail = nil
	else
		self.m[self.head].prev = nil
	end
	return ret
end

-- find
-- @param val 	need to find
-- @return 		table index
function CList:find(val)
	for k, v in pairs(self.m) do
		if v.data == val then
			return k
		end
	end
end

-- index
-- @param val 	table index
-- @return 		value
function CList:index(index)
	local node = self.m[index]
	return node and node.data
end

function CList:front()
	local head = self.m[self.head]
	return head and head.data
end

function CList:back()
	local tail = self.m[self.tail]
	return tail and tail.data
end

function CList:size()
	return self.msize
end

function CList:empty()
	return self.msize == 0
end

-- insert
-- @param index 	table index
-- @param val 		need to insert
-- @comment 		insert the index before
function CList:insert(index, val)
	local node = self.m[index]
	if node == nil then return false end

	if _isRef(val) then
		val:retain()
	end

	self.counter = self.counter + 1
	self.msize = self.msize + 1

	local idx = self.counter
	self.m[idx] = {
		prev = node.prev,
		next = index,
		data = val,
	}
	if self.head == index then
		self.head = idx
	else
		self.m[node.prev].next = idx
	end
	node.prev = idx
	return true
end

function CList:erase(index)
	local node = self.m[index]
	if node == nil then return end
	self.m[index] = nil

	local ret = node.data
	if _isRef(ret) then
		ret:autorelease()
	end

	self.msize = self.msize - 1
	if self.head == index then
		self.head = node.next
	else
		self.m[node.prev].next = node.next
	end
	if self.tail == index then
		self.tail = node.prev
	else
		self.m[node.next].prev = node.prev
	end
	return ret
end

function CList:assign(t)
	if type(t) ~= "table" then
		error("CList:assign need table")
		return
	end
	self:clear()
	for k, v in ipairs(t) do
		if _isRef(v) then
			v:retain()
		end
		self:push_back(v)
	end
end

function CList:pairs()
	local idx = self.head
	return function()
		local retIdx, ret = idx
		if idx then
			ret = self.m[idx].data
			idx = ret and self.m[idx].next
		end
		return retIdx, ret
	end
end

return CList