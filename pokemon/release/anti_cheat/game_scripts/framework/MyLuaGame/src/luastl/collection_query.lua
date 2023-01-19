--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2021 TianJi Information Technology Inc.
--

--
-- CCollection query
-- create query chain style
--
CCollection.query = {}
CCollection.query.__index = CCollection.query

local query_stats = CCollectionStats.query

function CCollection.query.new(c)
	return setmetatable({
		_c = c,
		_ccow = c,
		_ngroups = 0,

		-- 战斗中使用, 必须有序
		_order = c.defaultindex,
	}, CCollection.query)
end

function CCollection.query.__tostring(t)
	local scheme = {}
	if t._group then
		table.insert(scheme, string.format("group(%s, %s)", t._group.name, t._groupkey))
	end
	if t._order ~= t._c.defaultindex then
		table.insert(scheme, string.format("order(%s)", t._order.name))
	end
	return table.concat(scheme, " ")
end

function CCollection.query.reset(t, rawOrCow)
	t._group = nil
	t._groupkey = nil
	t._ngroups = 0
	t._order = t._c.defaultindex
	t._ccow = rawOrCow or t._c
	return t
end

-- group = all & group(key)
function CCollection.query.group(t, indexname, key)
	t._group = t._c.indexs[indexname]
	t._groupkey = key

	assert(t._group, "no such index name")
	assert(t._ngroups == 0, "use groups or reset query")
	return t
end

-- result init with empty set
-- @param op: + union
--            - difference
--            & intersection
--            ^ symmetric_difference
function CCollection.query.groups_init_with_all(t)
	return t:groups("+", "_default_key_index_", "_all_")
end

function CCollection.query.groups(t, op, indexname, key)
	if t._groups == nil then
		t._groups = {}
	end
	local index = t._c.indexs[indexname]
	-- maybe _default_key_index_ replace by CCollection.index.default()
	if indexname == "_default_key_index_" then
		index = t._c.defaultindex
	end
	assert(index, "no such index name")

	if t._ngroups == 0 then
		table.clear(t._groups)
	end
	t._ngroups = t._ngroups + 1

	if indexname == "_default_key_index_" then
		table.insert(t._groups, 2)
		table.insert(t._groups, op)
		table.insert(t._groups, index)
		return t
	end

	table.insert(t._groups, 3)
	table.insert(t._groups, op)
	table.insert(t._groups, index)
	table.insert(t._groups, key)
	return t
end

function CCollection.query.groups_sub_array(t, op, indexname, subOp, array)
	if t._groups == nil then
		t._groups = {}
	end
	local index = t._c.indexs[indexname]
	assert(index, "no such index name")

	if t._ngroups == 0 then
		table.clear(t._groups)
	end
	t._ngroups = t._ngroups + 1

	table.insert(t._groups, 4)
	table.insert(t._groups, op)
	table.insert(t._groups, index)
	table.insert(t._groups, subOp)
	table.insert(t._groups, array)
	return t
end

function CCollection.query.groups_sub(t, op, indexname, subOp, ...)
	return t:groups_sub_array(op, indexname, subOp, {...})
end

function CCollection.query.order(t, indexname)
	t._order = t._c.indexs[indexname]

	assert(t._order, "no such index name")
	return t
end

--
-- CCollection query result
--

function CCollection.query:check_group_()
	if self._group then
		return true
	end
	if self._ngroups > 0 then
		return true
	end
	return false
end

-- TODO: doSetOp need clone inner_result, otherwise its bug
local function step_group_result_(groups, j, step)
	-- had subOp
	if step == 4 then
		local op, index, subOp, subKeys = unpack(groups, j, j + 4)
		local result = index:group(subKeys[1])
		local keysLen = table.length(subKeys)
		if keysLen > 1 then
			result = result:shallowcopy()
		end
		for i = 2, keysLen do
			local result2 = index:group(subKeys[i])
			result = result:doSetOp(subOp, result2)
		end
		return op, result

	elseif step == 3 then
		local op, index, key = unpack(groups, j, j + 3)
		local result = index:group(key)
		-- print('!!! step_group_result_', groups, step, op, index.name, key)
		-- result:print()
		return op, result

	-- special for all
	elseif step == 2 then
		local op, index = unpack(groups, j, j + 2)
		local c = index._c
		return op, c:self_hash_result_()
	end
end

function CCollection.query:get_group_result_()
	if self._group then
		return self._group:group(self._groupkey)
	end
	if self._ngroups > 0 then
		local groups, step = self._groups, self._groups[1]
		local _, result = step_group_result_(groups, 2, step)
		if self._ngroups > 1 then
			result = result:shallowcopy()
		end
		local j = 1
		for i = 2, self._ngroups do
			j = j + step + 1
			step = groups[j]
			result = result:doSetOp(step_group_result_(groups, j + 1, step))
		end
		return result
	end
end

function CCollection.query:get_values_()
	return self._ccow.m
end

-- @param filter: the object be return when filter return true
function CCollection.query:empty(filter)
	local result
	if self:check_group_() then
		result = self:get_group_result_()
	else
		result = self._c:self_hash_result_()
	end

	if filter == nil or result:isEmpty() then
		return result:isEmpty()
	end

	-- filter and result not empty
	-- reduce self._order:get_order()
	for key, _ in result:pairs() do
		local value = self:get_values_()[key]
		assert(value ~= nil, "no such value")
		if filter(key, value) then
			return false
		end
	end
	return true
end

-- TODO: filter
function CCollection.query:count()
	if self:check_group_() then
		local result = self:get_group_result_()
		return result:size()
	end
	return self._c:size()
end

function CCollection.query:first(filter)
	local result
	if self:check_group_() then
		result = self:get_group_result_()
		if result:isEmpty() then
			return nil
		end
	end

	-- fast for only one
	if result and result:size() == 1 then
		local key = result:the_one()
		local value = self:get_values_()[key]
		if filter == nil or filter(key, value) then
			return value
		end
		return nil
	end

	for _, key in ipairs(self._order:get_order()) do
		if result == nil or result:contain(key) then
			local value = self:get_values_()[key]
			assert(value ~= nil, "no such value")
			if filter == nil or filter(key, value) then
				return value
			end
		end
	end
end

local function nil_next()
end

function CCollection.query:order_pairs()
	local result
	if self:check_group_() then
		result = self:get_group_result_()
		if result:isEmpty() then
			return nil_next
		end
	end

	-- nil mean pairs for all
	if result == nil then
		local order = self._order:get_order()
		return maptools.pairs_with_order(self:get_values_(), order)
	end

	-- fast for only one
	if result:size() == 1 then
		local key = result:the_one()
		local value = self:get_values_()[key]
		return function()
			local k, v = key, value
			key, value = nil, nil
			return k, v
		end
	end

	-- group result size very small(1~5) in generally
	local keys = {}
	result:to_array(keys)
	self._order:sort_for(keys)
	return maptools.pairs_with_order(self:get_values_(), keys)
end

-- for debug
if CCollection.debugMode then
	local resultFuncNames = {
		"empty",
		"count",
		"first",
		"order_pairs",
	}
	for _, name in ipairs(resultFuncNames) do
		local f = CCollection.query[name]
		CCollection.query[name] = function(self, ...)
			query_stats[name] = (query_stats[name] or 0) + 1

			local cc = ""
			local scheme = ""
			if self:check_group_() then
				cc = cc .. self._group.changedcount .. " "
				scheme = scheme .. string.format("group(%s, %s) ", self._group.name, self._groupkey)
			end
			cc = cc .. self._order.changedcount
			if self._order ~= self._c.defaultindex then
				scheme = scheme .. string.format("order(%s) ", self._order.name)
			end
			scheme = scheme .. name
			print("query:", self._c, self, cc, "scheme:", scheme)
			return f(self, ...)
		end
	end
end