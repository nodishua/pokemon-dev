--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

local min = math.min
local max = math.max

-- array table相关库函数
local arraytools = {}
globals.arraytools = arraytools

-- merge({{1, 2}, {3, 4}, ...})
-- => {1, 2, 3, 4}
function arraytools.merge(t)
	local ret = {}
	for _, targ in ipairs(t) do
		for _, v in ipairs(targ) do
			table.insert(ret, v)
		end
	end
	return ret
end

-- merge_inplace({1, 2}, {{3, 4}, ...})
-- => {1, 2, 3, 4}
function arraytools.merge_inplace(t, t2)
	for _, targ in ipairs(t2) do
		for _, v in ipairs(targ) do
			table.insert(t, v)
		end
	end
	return t
end

function arraytools.merge_two_inplace(t, t2)
	for _, v in ipairs(t2) do
		table.insert(t, v)
	end
	return t
end

-- first({1,2,3}, 2)
-- => {1,2}
function arraytools.first(t, n)
	if n == nil then return t[1] end
	n = min(table.length(t), n or 1)
	local ret = {}
	for i = 1, n do
		table.insert(ret, t[i])
	end
	return ret
end

-- last({1,2,3}, 2)
-- => {2,3}
function arraytools.last(t, n)
	local tn = table.length(t)
	if n == nil then return t[tn] end
	n = min(tn, n or 1)
	local ret = {}
	for i = 1 + tn - n, tn do
		table.insert(ret, t[i])
	end
	return ret
end

-- slice({ 1, 2, 3, 4, 5 }, 2, 3)
-- => { 2, 3, 4 }
function arraytools.slice(t, s, l)
	local tn = table.length(t)
	local ret = {}
	s = max(s, 1)
	local e = min(s + l - 1, tn)
	for i = s, e do
		table.insert(ret, t[i])
	end
	return ret
end

-- push
function arraytools.push(t, v)
	return table.insert(t, v)
end

-- pop
function arraytools.pop(t)
	return table.remove(t)
end

-- push_front
function arraytools.push_front(t, v)
	return table.insert(t, 1, v)
end

-- pop_front
function arraytools.pop_front(t)
	return table.remove(t, 1)
end

-- hash({1,3,5}) = map({1,3,4}, function(k,v) return v, true end)
-- => {1=true, 3=true, 5=true}
-- hash({1,3,5}, true)
-- => {1=1, 3=2, 5=3}
function arraytools.hash(t, setIdx)
	local ret = {}
	for i, k in ipairs(t) do
		ret[k] = setIdx and i or true
	end
	return ret
end

-- default sort by value
-- different with order_pairs
-- return new index, not original index
-- for i, v in sort_ipairs({3, 2, 1}) do print(i, v) end
-- => 1 1
--    2 2
--    3 3
function arraytools.sort_ipairs(t, cmp)
	local order = {}
	for i, v in ipairs(t) do
		table.insert(order, v)
	end
	local f = cmp
	if type(f) == "string" then
		f = function(v1, v2)
			return v1[cmp] < v2[cmp]
		end
	end
	table.sort(order, f)
	return ipairs(order)
end

--
-- diff with itertools, only use for array
-- ipairs guarantee numeric order
--

local inext = ipairs({})

function arraytools.map(t, f)
	local ret = {}
	for k, v in ipairs(t) do
		ret[k] = f(k, v)
	end
	return ret
end

function arraytools.reduce(t, f, init)
	local ret = init
	for k, v in ipairs(t) do
		if ret ~= nil then
			ret = f(ret, v)
		else
			ret = v
		end
	end
	return ret
end

function arraytools.filter(t, f)
	local ret = {}
	for k, v in ipairs(t) do
		if f(k, v) then
			table.insert(ret, v)
		end
	end
	return ret
end

function arraytools.each(t, f)
	for k, v in ipairs(t) do
		f(k, v)
	end
end

function arraytools.invoke(t, fname)
	for k, v in ipairs(t) do
		v[fname](k, v)
	end
end

function arraytools.values(t)
	local ret = {}
	for _, v in ipairs(t) do
		table.insert(ret, v)
	end
	return ret
end

function arraytools.ivalues(t)
	local k, v = 0
	return function()
		k, v = inext(t, k)
		return k, v
	end
end

function arraytools.items(t)
	local ret = {}
	for k, v in ipairs(t) do
		table.insert(ret, {k, v})
	end
	return ret
end

function arraytools.iitems(t)
	local k, v = 0
	return function()
		k, v = inext(t, k)
		return k, {k, v}
	end
end

--
-- more array function
--

function arraytools.filter_inplace(t, f)
	local k2, len = 1, table.length(t)
	for k, v in ipairs(t) do
		if f(k, v) then
			if k ~= k2 then t[k2] = t[k] end
			k2 = k2 + 1
		end
	end
	for i = k2, len do
		table.remove(t)
	end
	return t
end

arraytools.join = table.concat

-- remove nil value
function arraytools.compact(t)
	local len = table.length(t)
	for i = len, 1, -1 do
		if t[i] == nil then
			table.remove(t, i)
		end
	end
	return t
end
