--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2020 TianJi Information Technology Inc.
--

local _isRef = isRef

local CSTLBase = require("luastl.stlbase")
local CCollection = class("CCollection", CSTLBase)
globals.CCollection = CCollection

CCollection.debugMode = false

globals.CCollectionStats = {
	order_index = {
		count = 0,
		sort = 0,
		sort_load = 0,
		get = 0,
		delete = 0,
	},
	hash_index = {
		count = 0,
		update = 0,
		index = 0,
		delete = 0,
	},
	filter = {
		count = 0,
		miss = 0,
	},
	update = {},
	query = {},
}

require "luastl.collection_index"
require "luastl.collection_query"
require "luastl.collection_result"


local function key_cmp(k1, k2)
	return k1 < k2
end

--
-- CCollection
-- support CMap-like api
--
function CCollection:ctor()
	CSTLBase.ctor(self)

	-- indexs init
	self.indexs = {}

	-- default key index
	self:add_index(CCollection.index.new("_default_key_index_"):order_bykey(key_cmp))
	self.defaultindex = self.indexs._default_key_index_

	-- fast for cow_proxy
	-- tempquery and tempresult no need be proxy and revert
	-- both of them were volatility
	-- and which objs be return need be cow proxy
	local tempquery = CCollection.query.new(self)
	local tempresult = CCollection.inner_result.new()
	self.single_result_ = function(_, single)
		return tempresult:resetSingle(single)
	end
	self.hash_result_ = function(_, hash, hashsize)
		return tempresult:resetHash(hash, hashsize)
	end
	self.self_hash_result_ = function(_)
		return tempresult:resetHash(self.m, self.msize)
	end
	self.getQuery = function(rawOrCow)
		tempresult:resetSingle()
		return tempquery:reset(rawOrCow)
	end

	self:clear()
end

function CCollection:clear()
	if self.m then
		for k, v in pairs(self.m) do
			if _isRef(v) then
				v:autorelease()
			end
		end
	end

	self.m = {}
	self.msize = 0
	self:clear_indexs_()
end

function CCollection:size()
	return self.msize
end

function CCollection:empty()
	return self:size() == 0
end

function CCollection:insert(key, value)
	assert(type(key) == "number" or type(key) == "string", "only number or string key")
	assert(value ~= nil, "value is nil")

	if _isRef(value) then
		value:retain()
	end
	local oldVal = self.m[key]
	if oldVal ~= nil then
		if _isRef(oldVal) then
			oldVal:autorelease()
		end
		self:update_indexs_("erase", key, oldVal)
	end
	if oldVal == nil then
		self.msize = self.msize + 1
	end
	self.m[key] = value

	assert(self.msize == table.nums(self.m), "size error")

	self:update_indexs_("insert", key, value)
end

-- notice the value's life time
function CCollection:erase(key)
	local value = self.m[key]
	if value ~= nil then
		if _isRef(value) then
			value:autorelease()
		end
		self.m[key] = nil
		self.msize = self.msize - 1

		assert(self.msize == table.nums(self.m), string.format("erase size error %s %s", self.msize, table.nums(self.m)))

		self:update_indexs_("erase", key, value)
		return value
	end
	return nil
end
CCollection.pop = CCollection.erase

function CCollection:count(key)
	if self.m[key] ~= nil then
		return 1
	end
	return 0
end

function CCollection:find(key, defval)
	local val = self.m[key]
	if val ~= nil then
		return val
	end
	return defval
end

function CCollection:data()
	return self.m
end

function CCollection:pairs()
	return pairs(self.m)
end

function CCollection:equal(rhs)
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

-- diff with CMap
-- use add_index for cmp
-- TODO: remove it, and use order_pairs_byindex explicitly
function CCollection:order_pairs(cmp)
	assert(cmp == nil, "cmp must be nil")

	local order = self.defaultindex:get_order()
	return maptools.pairs_with_order(self.m, order)
end

function CCollection:order_pairs_byindex(name)
	local index = self.indexs[name]
	assert(index, "no such index " .. name)
	assert(index:is_order(), "the index no order " .. name)

end

--
-- CCollection index api
-- faster find/order_pairs
--

function CCollection:on_value_change(key)
	local value = self.m[key]
	if value == nil then return end

	self:update_indexs_("change", key, value)
end

function CCollection:add_index(index)
	self.indexs[index.name] = index:build_(self)
end

function CCollection:delete_index(index)
	self.indexs[index.name] = nil
end

function CCollection:update_indexs_(reason, key, value)
	for name, index in pairs(self.indexs) do
		index:update(reason, key, value)
	end
end

function CCollection:clear_indexs_()
	for name, index in pairs(self.indexs) do
		index:clear()
	end
end

function CCollection:fill_values_(keys)
	for i, k in ipairs(keys) do
		local v = self.m[k]
		assert(v, "CCollection lost key " .. k)
		keys[i] = v
	end
	return keys
end

function CCollection:customQuery()
	return CCollection.query.new(self)
end


return CCollection

--[[
	local ret = CCollection.new()
	ret:add_index(CCollection.index.new("typ_index")
		:hash("typ"))

	local o
	o = {id = 1, typ = "o1"}
	ret:insert(o.id, o)
	o = {id = 2, typ = "o2"}
	ret:insert(o.id, o)
	o = {id = 3, typ = "o3"}
	ret:insert(o.id, o)
	o = {id = 11, typ = "o1"}
	ret:insert(o.id, o)
	o = {id = 12, typ = "o2"}
	ret:insert(o.id, o)
	o = {id = 21, typ = "o1"}
	ret:insert(o.id, o)

	local q = ret:getQuery()
	q:groups_init_with_all()
		:groups_sub_array("-", "typ_index", "+", {"o2", "o3"})

	-- 1, 11, 21
	for k, v in q:order_pairs() do
		print('!!! k1v', k, dumps(v))
	end

	local q = ret:getQuery()
	q:groups_init_with_all()
		:groups_sub_array("-", "typ_index", "+", {"o2"})

	-- 1, 3, 11, 21
	for k, v in q:order_pairs() do
		print('!!! k2v', k, dumps(v))
	end

	local q = ret:getQuery()
	q:groups_init_with_all()
		:groups_sub_array("+", "typ_index", "+", {"o2"})

	-- 1, 2, 3, 11, 12, 21
	for k, v in q:order_pairs() do
		print('!!! k3v', k, dumps(v))
	end

	local q = ret:getQuery()
	q:groups_sub_array("+", "typ_index", "+", {"o2"})
	q:groups_sub_array("&", "typ_index", "+", {"o3"})

	--
	for k, v in q:order_pairs() do
		print('!!! k4v', k, dumps(v))
	end

	local q = ret:getQuery()
	q:groups_sub_array("+", "typ_index", "+", {"o2"})
	q:groups_sub_array("^", "typ_index", "+", {"o3"})

	-- 2, 3, 12
	for k, v in q:order_pairs() do
		print('!!! k5v', k, dumps(v))
	end

]]--