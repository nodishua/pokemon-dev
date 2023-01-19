--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

local _isRef = isRef

local CSTLBase = require("luastl.stlbase")
local CMap = class("CMap", CSTLBase)
globals.CMap = CMap

--map的key最好不要是table，常规的就是number以及string
function CMap:ctor(ordercmp, weak)
	CSTLBase.ctor(self)

	self:clear(ordercmp, weak)
end

function CMap:clear(ordercmp, weak)
	if self.m then
		for k, v in pairs(self.m) do
			if _isRef(v) then
				v:autorelease()
			end
		end
	end

	self.m = weak and setmetatable({}, {__mode = weak}) or {}
	self.msize = weak and -1 or 0
	self.order = nil
	self.ordercmp = ordercmp
end

function CMap:size()
	if self.msize < 0 then
		-- weak table may auto erase
		local ret = 0
		for k, v in pairs(self.m) do
			ret = ret + 1
		end
		return ret
	end
	return self.msize
end

function CMap:empty()
	return self:size() == 0
end

function CMap:insert(key, value)
	if _isRef(value) then
		value:retain()
	end
	local oldVal = self.m[key]
	if oldVal ~= nil then
		if _isRef(oldVal) then
			oldVal:autorelease()
		end
	end
	if self.msize >= 0 and oldVal == nil then
		self.msize = self.msize + 1
	end
	self.m[key] = value
	self.order = nil
end

function CMap:assign(t)
	self:clear()
	if type(t) ~= "table" then
		-- allow nil to assign, equal clear
		-- error("CMap:assign need table")
		return
	end
	for k, v in pairs(t) do
		if _isRef(v) then
			v:retain()
		end
		self.m[k] = v
		self.msize = self.msize + 1
	end
end

-- notice the value's life time
function CMap:erase(key)
	if self.m[key] ~= nil then
		local ret = self.m[key]
		if _isRef(ret) then
			ret:autorelease()
		end
		self.m[key] = nil
		if self.msize >= 0 then self.msize = self.msize - 1 end
		self.order = nil
		return ret
	end
	return nil
end
CMap.pop = CMap.erase

function CMap:count(key)
	if self.m[key] ~= nil then
		return 1
	end
	return 0
end

function CMap:find(key, defval)
	if self.m[key] ~= nil then
		return self.m[key]
	end
	return defval
end

function CMap:data()
	return self.m
end

function CMap:pairs()
	return pairs(self.m)
end

-- function CMap:__eq(rhs)
function CMap:equal(rhs)
	if self.msize ~= rhs.msize then
		return false
	end
	for k, v in pairs(self.m) do
		if v ~= rhs:find(k) then
			return false
		end
	end
	return true
end

-- @param cmp: temporary compare, use by one-off
function CMap:order_pairs(cmp)
	local order = self.order
	local data = self.m

	if order == nil or cmp then
		order = {}
		-- may be k is CMap or table
		for k, v in pairs(self.m) do
			table.insert(order, k)
		end
		-- ordercmp is default
		local f = cmp or self.ordercmp
		if type(f) == "string" then
			local key = f
			f = function(v1, v2)
				return v1[key] < v2[key]
			end
		end
		if f then
			local ff = f
			f = function(k1, k2)
				return ff(data[k1], data[k2])
			end
		end
		table.sort(order, f)
		if cmp == nil then
			-- view有不合理调用model接口的地方, vmproxy使用ProtectWritePass忽略order保护
			-- http://172.81.227.66:1104/crashinfo?_id=13176&type=1
			self.order = order
		end
	end

	local i, k, v = 0, nil, nil
	local n = table.length(order)
	return function()
		while i < n do
			i = i + 1
			k = order[i]
			v = data[k]
			-- may be v is nil, it be deleted
			if v ~= nil then
				return k, v
			end
		end
	end
end

return CMap