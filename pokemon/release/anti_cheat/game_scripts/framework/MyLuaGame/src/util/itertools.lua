--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

local insert = table.insert
local sort = table.sort
local min = math.min
local max = math.max
local iskindof = iskindof

-- 参考Python相关库函数
local itertools = {}
globals.itertools = itertools

local function argsIter(args)
	local it, tb, init

	-- itertools.iXXX()
	if type(args) == 'function' then
		it = args
	-- custom pairs and ipairs
	elseif args.pairs then
		it, tb, init = args:pairs()
	elseif args.ipairs then
		it, tb, init = args:ipairs()
	-- {a=1, b=2, 3, ...}
	else
		it, tb, init = pairs(args)
	end
	return it, tb, init
end

local function returnV(k, v)
	return v
end

-- @comment: cycle can not used with chain
function itertools.cycle(t, n)
	if n and n == 0 then return function () return end end
	local idx = 0
	return function ()
		local nk = idx + 1
		local nv = t[nk]
		if nv == nil then
			n = n and n - 1
			if n == nil or n <= 0 then return end
			nk, nv = 1, t[1]
		end
		idx = nk
		return nk, nv
	end
end

-- for k, v in chain({{1,2}, {k1=1, k2=2}, function}) do print(k, v) end
function itertools.chain(t)
	local tn = table.length(t)
	if tn == 0 then return function () return end end
	local tidx = 1
	local idx = nil
	return function ()
		local nt = t[tidx]
		local nk, nv
		if type(nt) == "function" then
			nk, nv = nt()
		else
			nk, nv = next(nt, idx)
		end
		if nk == nil then
			if tidx >= tn then
				return
			end
			tidx = tidx + 1
			nt = t[tidx]
			if type(nt) == "function" then
				nk, nv = nt()
			else
				nk, nv = next(nt, nil)
			end
		end
		idx = nk
		return nk, nv
	end
end

function itertools.keys(t)
	local ret = {}
	for k, _ in argsIter(t) do
		insert(ret, k)
	end
	return ret
end

function itertools.ikeys(t)
	local it, tb, init = argsIter(t)
	local cnt, k, v = 0, init, nil
	return function ()
		k = it(tb, k)
		cnt = cnt + 1
		return (k ~= nil) and cnt or nil, k
	end
end

function itertools.values(t)
	local ret = {}
	for _, v in argsIter(t) do
		insert(ret, v)
	end
	return ret
end

function itertools.ivalues(t)
	local it, tb, init = argsIter(t)
	local cnt, k, v = 0, init, nil
	return function ()
		k, v = it(tb, k)
		cnt = cnt + 1
		return (k ~= nil) and cnt or nil, v
	end
end

function itertools.items(t)
	local ret = {}
	for k, v in argsIter(t) do
		insert(ret, {k, v})
	end
	return ret
end

function itertools.iitems(t)
	local it, tb, init = argsIter(t)
	local cnt, k, v = 0, init, nil
	return function ()
		-- k, v = next(t, k)
		k, v = it(tb, k)
		cnt = cnt + 1
		return (k ~= nil) and cnt or nil, {k, v}
	end
end

-- iterator, like `next`
-- return nil, the iter will stop
-- tb, init are not necessary, just for pairs or ipairs
function itertools.iter(next, tb, init, f)
	local k, v = init, nil
	-- pairs or ipairs, next is lua next
	if tb then
		next = functools.partial(next, tb)
	end
	if f then
		return function()
			k, v = f(next(k))
			return k, v
		end
	else
		return function()
			k, v = next(k)
			return k, v
		end
	end
end

function itertools.size(t)
	local ret = 0
	for _ in argsIter(t) do
		ret = ret + 1
	end
	return ret
end

-- for k, v in range(10,5,-2) do print(k, v) end
-- => 10 10
--    8 8
--    6 6
function itertools.range(slen, e, step)
	local i = e and slen or 1
	e = e or slen
	step = step or 1
	return function ()
		if (step > 0 and i > e) or (step < 0 and i < e) then return end
		local ret = i
		i = i + step
		return ret, ret
	end
end


-- map(function(k, v) return v*2 end, {1,2,3})
-- => { 2,4,6 }
-- map(function(k, v) return k, v*2 end, {k1=1, k2=2})
-- => { k1=1, k2=4 }
function itertools.map(t, f)
	local ret, i = {}, 1
	for k, v in argsIter(t) do
		local kk, vv = f(k, v)
		-- map
		if vv ~= nil then
			ret[kk] = vv
		-- array
		else
			ret[i] = kk
			i = i + 1
		end
	end
	return ret
end

-- reduce({1,2,3}, function(memo, i) return memo+i end, 0)
-- => 6
function itertools.reduce(t, f, init)
	local ret = init
	for k, v in argsIter(t) do
		if ret ~= nil then
			ret = f(ret, k, v)
		else
			ret = v
		end
	end
	return ret
end

-- filter(function(k, v) return v%2==0 end, {1,2,3})
-- => { 2 }
-- filter(function(k, v) return v%2==0, k end, {k1=1, k2=2})
-- => { k2=2 }
function itertools.filter(t, f)
	local ret = {}
	for k, v in argsIter(t) do
		local ok, kk = f(k, v)
		if ok then
			-- map
			if kk ~= nil then
				ret[kk] = v
			-- array
			else
				insert(ret, v)
			end
		end
	end
	return ret
end

-- each({1,2,3}, print)
-- => 1, 1
--    2, 2
--    3, 3
function itertools.each(t, f)
	for k, v in argsIter(t) do
		f(k, v)
	end
end

-- Calls a self's function with specified name on each item using the colon operator
-- invoke({btn1, btn2}, "setVisible", true)
function itertools.invoke(t, fname, ...)
	for k, v in argsIter(t) do
		v[fname](v, ...)
	end
end

-- first({1,2,3,4}, function(v) return v%2 == 0 end)
-- => 2, 2
function itertools.first(t, val)
	local exist = val
	if type(val) ~= "function" then
		exist = function(v)
			return v == val
		end
	end
	for k, v in argsIter(t) do
		if exist(v) then
			return k, v
		end
	end
end

-- include({1,2,3,4}, function(i) return i%2 == 0 end)
-- => true
function itertools.include(t, val)
	return itertools.first(t, val) ~= nil
end

-- count({1,2,3,4}, function(i) return i%2 == 0 end)
-- => 2
function itertools.count(t, val)
	local eq = val
	if type(val) ~= "function" then
		eq = function(k, v)
			return v == val
		end
	end
	local cnt = 0
	for k, v in argsIter(t) do
		if eq(k, v) then
			cnt = cnt + 1
		end
	end
	return cnt
end

-- all({2,4,8}, function(i) return i%2 == 0 end)
-- => true
function itertools.all(t, val)
	local eq = val
	if type(val) ~= "function" then
		eq = function(v)
			return v == val
		end
	end
	for k, v in argsIter(t) do
		if not eq(v) then
			return false
		end
	end
	return true
end

itertools.any = itertools.include

function itertools.to_array(t)
	local array = {}
	for k, v in argsIter(t) do
		insert(array, v)
	end
	return array
end

-- inplace
function itertools.sort(t, comp)
	local array = t
	if type(array) == "function" then
		array = itertools.to_array(t)
	end
	sort(array, comp)
	return array
end

-- inplace
-- reverse({ 1, 2, 3})
-- => { 3, 2, 1 }
function itertools.reverse(t)
	local array = t
	if type(array) == "function" then
		array = itertools.to_array(t)
	end
	local i, j = 1, table.length(array)
	while i < j do
		array[i], array[j] = array[j], array[i]
		i, j = i + 1, j - 1
	end
	return array
end

function itertools.min(t, f)
	f = f or returnV
	local vmin -- nil is default
	for k, v in argsIter(t) do
		if vmin ~= nil then
			vmin = min(vmin, f(k, v))
		else
			vmin = f(k, v)
		end
	end
	return vmin
end

function itertools.max(t, f)
	f = f or returnV
	local vmax -- nil is default
	for k, v in argsIter(t) do
		if vmax ~= nil then
			vmax = max(vmax, f(k, v))
		else
			vmax = f(k, v)
		end
	end
	return vmax
end

function itertools.sum(t, f)
	f = f or returnV
	local s = 0 -- 0 is default
	for k, v in argsIter(t) do
		local vv = f(k, v)
		s = s + vv
	end
	return s
end

function itertools.isempty(t)
	return type(t) ~= "table" or next(t) == nil
end

function itertools.isarray(t)
	local i = 0
	for _ in pairs(t) do
		i = i + 1
		if t[i] == nil then
			return false
		end
	end
	return true
end

function itertools.ismap(t)
	return not itertools.isarray(t)
end

function itertools.equal(t1, t2)
	if t1 == t2 then return true end
	if type(t1) ~= type(t2) then return false end
	if type(t1) ~= "table" then return false end
	if itertools.size(t1) ~= itertools.size(t2) then return false end

	for k, v in pairs(t1) do
		if type(v) == "table" then
			if not itertools.equal(v, t2[k]) then
				return false
			end
		elseif v ~= t2[k] then
			return false
		end
	end
	return true
end

return itertools