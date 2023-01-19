--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--


local _abs = math.abs
local _isRef = isRef

-- NOTICE !!!
-- cow_proxy in battle will replace table.XXX functions
-- local _tinsert = table.insert
-- local _tremove = table.remove
-- local _tsort = table.sort

local CSTLBase = require("luastl.stlbase")
local CVector = class("CVector", CSTLBase)
globals.CVector = CVector

function CVector:ctor()
	CSTLBase.ctor(self)

	self:clear()
end

function CVector:clear()
	if self.m then
		for i, v in ipairs(self.m) do
			if _isRef(v) then
				v:autorelease()
			end
		end
	end
	self.m = {}
end

function CVector:push_back(val)
	if _isRef(val) then
		val:retain()
	end
	table.insert(self.m, val)
end

function CVector:pop_back()
	local last = self:back()
	if _isRef(last) then
		last:autorelease()
	end
	return table.remove(self.m)
end

function CVector:push_front(val)
	if _isRef(val) then
		val:retain()
	end
	table.insert(self.m, 1, val)
end

function CVector:pop_front()
	if _isRef(self.m[1]) then
		self.m[1]:autorelease()
	end
	return table.remove(self.m, 1)
end

-- find
-- @param val 	need to find
-- @return 		table index
function CVector:find(val)
	for i, v in ipairs(self.m) do
		if v == val then
			return i
		end
	end
end

-- at
-- @param val 	table index
-- @return 		value
function CVector:at(index)
	return self.m[index]
end

function CVector:front()
	if self:empty() then return nil end
	return self.m[1]
end

function CVector:back()
	if self:empty() then return nil end
	return self.m[self:size()]
end

function CVector:size()
	return table.length(self.m)
end

function CVector:empty()
	return table.length(self.m) == 0
end

-- insert
-- @param index 	table index
-- @param val 		need to insert
-- @comment 		[1 .. index-1], val, [index .. #]
function CVector:insert(index, val)
	if _isRef(val) then
		val:retain()
	end
	table.insert(self.m,index,val)
end

function CVector:update(index, val)
	self.m[index] = val
end

function CVector:sort(sortFunc)
	table.sort(self.m, sortFunc)
end

function CVector:erase(index)
	if index < 1 or index > self:size() then
		return false
	end
	local ret = table.remove(self.m, index)
	if _isRef(ret) then
		ret:autorelease()
	end
	return ret
end
function CVector:eraseList(list)
	if list == nil then return end
	for k, v in pairs(list) do
		if self:size() >= v and self.m[v] then
			if _isRef(self.m[v]) then
				self.m[v]:autorelease()
			end
			self.m[v] = nil
		end
	end
	local idx = 1
	for k,v in pairs(self.m) do
		if v ~= nil then
			self.m[idx] = v
			if k ~= idx then self.m[k] = nil end
			idx = idx + 1
		end
	end
end

function CVector:assign(t)
	if type(t) ~= "table" then
		error("CVector:assign need table")
		return
	end
	self:clear()
	for k, v in pairs(t) do
		if _isRef(v) then
			v:retain()
		end
		table.insert(self.m, v)
	end
end

function CVector:pairs()
	return ipairs(self.m)
end

function CVector:ipairs()
	return ipairs(self.m)
end

function CVector:data()
	return self.m
end

function CVector:equal(rhs)
	if self:size() ~= rhs:size() then
		return false
	end
	for k, v in ipairs(self.m) do
		if v ~= rhs.m[k] then
			return false
		end
	end
	return true
end

-- slice
-- @param startIndex
-- @param endIndex
-- @param step
-- @return 		new CVector
-- @comment 	like python list slice
function CVector:slice(startIndex, endIndex, step)
	local ret = CVector.new()
	if self:empty() or step == 0 then
		return ret
	end
	if step == nil then
		step = (endIndex - startIndex >= 0) and 1 or -1
	end

	local n = self:size()
	-- reverse visit, change to forward visit
	if (endIndex - startIndex) * step < 0 then
		local len = _abs(endIndex - startIndex)
		len = n - len
		endIndex = (step > 0 and startIndex + len) or startIndex - len
		if startIndex * endIndex < 0 then
			--if 0 will be visited, walk one more
			endIndex = endIndex + ((step > 0 and 1) or -1)
		end
	end

	for i = startIndex, endIndex, step do
		if i < 0 then
			ret:push_back(self.m[1 + (i % n)])
		elseif i > 0 then
			ret:push_back(self.m[1 + ((i - 1) % n)])
		end
	end
	return ret
end

return CVector