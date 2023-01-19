--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2020 TianJi Information Technology Inc.
--
-- kv缓存
--

local DELETE = {}

local KVCache = class("KVCache")

function KVCache:ctor()
	self:clean()
end

-- cache the intermediate or final result
-- speed up the complex compute
-- @param keys: any type, but table mean more dimensions
function KVCache:query(keys, setf)
	local c, ret = self.c, self.c
	local lastk
	if type(keys) == "table" then
		for _, key in ipairs(keys) do
			-- last is nil and the last is not end
			if ret == nil then
				-- push new table in internal path
				ret = {}
				c[lastk] = ret
			end
			c, lastk = ret, key
			ret = c[key]
		end
	else
		ret = c[keys]
		lastk = keys
	end

	if ret == DELETE then
		return nil
	end

	if ret ~= nil or setf == nil then
		return ret
	end

	ret = setf()
	c[lastk] = ret
	return ret
end

-- @param value: nil mean delete the key
function KVCache:update(keys, value)
	local c, ret = self.c, self.c
	local lastk
	if type(keys) == "table" then
		for _, key in ipairs(keys) do
			-- last is nil and the last is not end
			if ret == nil then
				-- push new table in internal path
				ret = {}
				c[lastk] = ret
			end
			c, lastk = ret, key
			ret = c[key]
		end
	else
		ret = c[keys]
		lastk = keys
	end

	c[lastk] = value or DELETE
	return value
end

function KVCache:clean()
	self.c = {}
end

return KVCache
