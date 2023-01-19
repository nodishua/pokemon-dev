--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2021 TianJi Information Technology Inc.
--

--
-- CCollection index
-- create index chain style
--
CCollection.index = {}
CCollection.index.__index = CCollection.index

local IDCounter = 0

local order_stats = CCollectionStats.order_index
local hash_stats = CCollectionStats.hash_index
local filter_stats = CCollectionStats.filter
local update_stats = CCollectionStats.update

function CCollection.index.new(name)
	IDCounter = IDCounter + 1
	return setmetatable({
		id = IDCounter,
		name = name,
		keyhash = nil, -- {key: true} if index had filter
		order = nil, -- the order for application was immutable table
		realtimeorder = nil, -- the order was newest
		hash = nil, -- {hkey: key} or {hkey: {key: true}}
		changedcount = 0,

		_immutably = true,
	}, CCollection.index)
end

-- v[ field[1] ][ field[2] ] == val
function CCollection.index.hash(t, field)
	if type(field) == "table" then
		t._fields = field
		t._hashf = function(k, v)
			local h = v
			for _, name in ipairs(field) do
				h = h[name]
			end
			return h
		end
	else
		t._field = field
		t._hashf = function(k, v)
			return v[field]
		end
	end
	return t
end

-- f(k, v) == val
function CCollection.index.hash_byfunc(t, f)
	t._hashf = f
	return t
end

-- filter(k, v)
function CCollection.index.filter(t, f)
	t._filter = f
	return t
end

-- cmp(v1, v2)
function CCollection.index.order(t, cmp)
	t._cmp = cmp
	return t
end

-- cmp(k1, k2)
function CCollection.index.order_bykey(t, cmp)
	t._keycmp = cmp
	return t
end

-- reason=change no effect
-- reduce irrelevant values change
function CCollection.index.value_immutably(t)
	t._immutably = true
	return t
end

-- replace with c.keyindex when use order_pairs
-- default index must ensure definitive order
function CCollection.index.default(t)
	t._default = true
	return t
end

function CCollection.index.build_(t, c)
	t._c = c
	t = setmetatable(t, CCollection.index_impl)

	if t._filter then
		t.keyhash = {}
	end

	if t._cmp then
		assert(not t._keycmp, "only one between order or order_bykey")
		order_stats.count = order_stats.count + 1

		-- _cmp -> _keycmp
		local cmp = t._cmp
		-- m was cache, carefully when c.m = {}
		local m = c.m
		t._keycmp = function(k1, k2)
			return cmp(m[k1], m[k2])
		end
	end

	if t._hashf then
		hash_stats.count = hash_stats.count + 1

		t.hash = {}
		t.hashsize = {}
		for k, v in c:pairs() do
			t:update_hash_(c, "insert", k, v)
		end
	end

	if t._default then
		assert(t._keycmp, "CCollection no order index")

		if c.defaultindex then
			c:delete_index(c.defaultindex)
		end
		c.defaultindex = t
	end

	return t
end

--
-- CCollection index implement
--
-- index basic type:
-- 1. hash
-- 2. order
--

CCollection.index_impl = {}
CCollection.index_impl.__index = CCollection.index_impl

function CCollection.index_impl:is_order()
	return self._keycmp ~= nil
end

function CCollection.index_impl:is_hash()
	return self._hashf ~= nil
end

function CCollection.index_impl:size()
	assert(self._filter == nil, "filter size not implement")

	-- CCollection size
	return self._c:size()
end

-- 2. order
function CCollection.index_impl:get_order()
	if self._keycmp then
		return self:get_order_()
	end
	error("CCollection index no order")
end

-- 2. order
function CCollection.index_impl:sort_for(keys)
	if self._keycmp then
		table.sort(keys, self._keycmp)
		return keys
	end
	error("CCollection index no order")
end

-- 1. hash
function CCollection.index_impl:group(key)
	if self.hash then
		hash_stats.index = hash_stats.index + 1

		-- key is hash key
		local h = self.hash[key]
		if h == nil then
			return self._c:single_result_()
		end
		if type(h) == "table" then
			local first = next(h)
			if first == nil then
				return self._c:single_result_()
			end
			return self._c:hash_result_(h, self.hashsize[key] or 0)
		end
		return self._c:single_result_(h)
	end
	error(string.fotmat("CCollection index no hash group(%s)", key))
end

function CCollection.index_impl:update(reason, key, value)
	local keyhash = self.keyhash
	local inset = true
	if self._filter then
		inset = self._filter(key, value)

		filter_stats.count = filter_stats.count + 1
		filter_stats.miss = filter_stats.miss + (inset and 0 or 1)
	end

	local changed = true
	if inset then
		-- update keyhash
		if reason == "insert" or reason == "change" then
			-- may be value changed
			if keyhash then
				keyhash[key] = true
			end
		else -- erase
			if keyhash then
				changed = keyhash[key] ~= nil
				keyhash[key] = nil
			end
		end

	else
		-- like erase in index
		if keyhash and keyhash[key] then
			reason = "erase"
			keyhash[key] = nil
		end
	end

	update_stats[reason] = (update_stats[reason] or 0) + 1

	-- update custom index
	if changed then
		if self._hashf then
			self:update_hash_(reason, key, value)
		end
		if self._keycmp then
			self:update_order_(reason, key, value)
		end
	end
end

-- @param key: unique in CCollection
-- hkey: may be multiple in hash index
function CCollection.index_impl:update_hash_(reason, key, value)
	hash_stats.update = hash_stats.update + 1

	local hkey = self._hashf(key, value)
	local h = self.hash[hkey]

	-- NOTICE: hash key must not be change in the object
	local setit = reason == "insert"
	setit = setit or (reason == "change" and not self._immutably)
	if setit then
		if h == nil then
			self.hash[hkey] = key
			self.hashsize[hkey] = 1
			self.changedcount = self.changedcount + 1
		else
			if type(h) == "table" then
				local num = h[key] and 0 or 1
				h[key] = true
				self.hashsize[hkey] = self.hashsize[hkey] + num
				self.changedcount = self.changedcount + num

			else
				if h ~= key then
					self.hash[hkey] = {
						[key] = true,
						[h] = true,
					}
					self.hashsize[hkey] = 2
					self.changedcount = self.changedcount + 1
				end
			end
		end

	else -- erase
		if h ~= nil then
			if type(h) == "table" then
				local idx = h[key]
				assert(idx, "hash index could not find the key, may be had diff hash key")
				h[key] = nil
				if idx then
					self.hashsize[hkey] = self.hashsize[hkey] - 1
				end

			else
				assert(h == key, "hash index had diff hash key with the same value")
				self.hash[hkey] = nil
				self.hashsize[hkey] = 0
			end
			self.changedcount = self.changedcount + 1
		end
	end
end

function CCollection.index_impl:lower_bound_(arr, n, val)
	local cmp = self._keycmp
	local l, r = 1, n + 1
	while l < r do
		local mid = math.floor((l + r) / 2)
		-- [mid] < val
		if cmp(arr[mid], val) then
			l = mid + 1
		else
			r = mid
		end
	end
	return l
end

function CCollection.index_impl:get_order_()
	order_stats.get = order_stats.get + 1

	if self.order == nil then
		if self.realtimeorder then
			self.order = self.realtimeorder
			self.realtimeorder = nil
		else
			-- use index.keyhash if had index._filter
			-- otherwise use CCollection.m
			local keys = table.keys(self.keyhash or self._c.m)
			table.sort(keys, self._keycmp)
			self.order = keys

			order_stats.sort = order_stats.sort + 1
			if #keys > 0 then
				order_stats.sort_load = order_stats.sort_load + (math.log(#keys)*#keys)
			end
		end
	end
	return self.order
end

function CCollection.index_impl:update_order_(reason, key, value)
	if reason == "change" then
		-- its order_bykey
		if self._cmp == nil or self._immutably then
			return
		end
		-- refresh realtime order
		self.realtimeorder = nil
	end

	-- TODO: cow_proxy not cover all cases (BuffModel.new, ObjectMode.new)
	--       maintain relatime order will raise error like `buff1 was nil` or `order size error`
	-- maybe update in order_pairs iterating, must keep self.order was immutable
	if false and (reason == "insert" or reason == "erase") then
		-- optimize in big table
		local n = self:size()
		if n > 24 and self.order then
			self.realtimeorder = arraytools.values(self.order)
		end

		if self.realtimeorder then
			local order = self.realtimeorder
			n = n + (reason == "insert" and -1 or 1)
			assert(n == table.length(order), "order size error")

			-- temporary recover erase for lower_bound_
			if reason == "erase" then
				self._c.m[key] = value
			end

			local index = self:lower_bound_(order, n, key)
			if reason == "insert" then
				table.insert(order, index, key)
			else
				assert(order[index] == key, "lower_bound_ error")

				self._c.m[key] = nil
				table.remove(order, index)
			end
		end
	end

	self.order = nil
	self.changedcount = self.changedcount + 1

	order_stats.delete = order_stats.delete + 1
end

function CCollection.index_impl:clear()
	self.order = nil
	self.realtimeorder = nil

	if self.hash then
		hash_stats.delete = hash_stats.delete + 1

		self.hash = {}
		self.hashsize = {}
	end

	if self._cmp then
		order_stats.delete = order_stats.delete + 1

		-- _cmp -> _keycmp
		local cmp = self._cmp
		-- m was cache, carefully when c.m = {}
		local m = self._c.m
		self._keycmp = function(k1, k2)
			return cmp(m[k1], m[k2])
		end
	end

	self.changedcount = self.changedcount + 1
end
