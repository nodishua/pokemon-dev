--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

local insert = table.insert

-- 参考Python相关库函数
local functools = {}
globals.functools = functools

-- NOTICE !!!
-- local a,b = ...
-- local nargs = select("#", ...)
-- local nargs = #{...}
-- time cost 1:3:8
-- select('#', ...) != #args when ... had nil tail

-- function f(p1,p2) return {p1,p2} end
-- g = partial(f, "a")
-- g("b")
-- => {"a","b"}
function functools.partial(f, ...)
	local nargs = select('#', ...)
	if nargs <= 4 then
		local upv1, upv2, upv3, upv4 = select(1, ...)
		if nargs == 1 then
			return function(...)
				return f(upv1, ...)
			end
		elseif nargs == 2 then
			return function(...)
				return f(upv1, upv2, ...)
			end
		elseif nargs == 3 then
			return function(...)
				return f(upv1, upv2, upv3, ...)
			end
		elseif nargs == 4 then
			return function(...)
				return f(upv1, upv2, upv3, upv4, ...)
			end
		end
		return f
	end
	local vargs = {...}
	local ff = f
	for i = 1, nargs do
		local f, upv = ff, vargs[i]
		ff = function(...)
			return f(upv, ...)
		end
	end
	return ff
end

-- easy for object member function when use functools.partial
function functools.handler(obj, method, ...)
	if type(method) == "string" then
		method = obj[method]
	end
	if type(method) ~= "function" then
		error(string.format("obj no handler %s", method))
	end
	local nargs = select('#', ...)
	if nargs == 0 then
		return function(...)
			return method(obj, ...)
		end
	end
	return functools.partial(method, obj, ...)
end

-- function f(p1,p2) return {p1,p2} end
-- g = functools.shrink(f, 1)
-- g(1,2,3)
-- => {2,3}
function functools.shrink(f, left, right)
	right = right or 0
	return function(...)
		if right == 0 then
			return f(select(left + 1, ...))
		end
		local nargs = select('#', ...)
		local vargs, part, partlen = {...}, {}, 0
		right = nargs - right
		for i = left + 1, right do
			partlen = partlen + 1
			part[partlen] = vargs[i]
		end
		return f(unpack(part, 1, partlen))
	end
end

-- hello = function(name)
--   return "hello: "..name
-- end
-- hello = wrap(hello, function(func, ...)
--   return "before, "..func(...)..", after"
-- end)
-- hello('moe')
-- => before, hello: moe, after
function functools.wrap(f, w)
	return function(...)
		return w(f, ...)
	end
end

-- @comment:  In math terms, composing the functions f(), g(), and h() produces f(g(h())).
-- greet = function(name)
--   return "hi: "..name
-- end
-- exclaim = function(statement)
--   return statement.."!"
-- end
-- welcome = compose(print, greet, exclaim)
-- welcome('moe')
-- => hi: moe!
function functools.compose(...)
	local nargs = select('#', ...)
	local vargs = {...}
	local ff = function(...)
		return ...
	end
	-- use nargs, avoid case like {nil, 1, nil} paramters
	for i = 1, nargs do
		local f, upv = ff, vargs[i]
		ff = function(...)
			return f(upv(...))
		end
	end
	return ff
end

-- touch = function(ui, arg)
--   print(ui, "touch "..arg)
-- end
-- text = function(ui, arg)
--   print(ui, "text "..arg)
-- end
-- chaincall({touch=touch, text=text}, ui):touch("123"):text("abc"):touch("456")
-- => touch 123
-- text abc
-- touch 456
function functools.chaincall(m, ...)
	local t = {}
	local nargs = select('#', ...)
	local vargs = {...}
	return setmetatable(t, {
		__index = function(t, k)
			local pf = m[k]
			if nargs > 0 then
				pf = functools.partial(m[k], unpack(args, 1, nargs))
			end
			local function cf(t, ...)
				pf(...)
				return t
			end
			t[k] = cf
			return cf
		end
	})
end

-- chainself(ui):touch("123"):text("abc"):touch("456")
function functools.chainself(self)
	local t = {}
	return setmetatable(t, {
		__index = function(t, k)
			local pf = self[k]
			local function cf(t, ...)
				pf(self, ...)
				return t
			end
			t[k] = cf
			return cf
		end
	})
end

-- the last param can be explicit nil
-- local add = curry(function (a,b,c)
-- 	return a+b+c
-- end)
-- print(add(1,2,3))
-- print(add(11))
-- print(add(11)(22))
-- print(add(11)(22)(33))
-- => 6
-- function 0x0CAFC090
-- function 0x0CAFC5F0
-- 66
function functools.curry(f, nparams)
	if nparams == nil then
		local info = debug.getinfo(f)
		-- nparams, isvararg in lua5.2
		if info.isvararg then
			error("curry not support varg function")
		end
		nparams = info.nparams
	end

	return function(...)
		local nargs = select('#', ...)
		if nargs >= nparams then
			return f(...)
		end
		local ff = functools.partial(f, ...)
		return functools.curry(ff, nparams - nargs)
	end
end


local argsMeta = {
	at = function(t, i)
		return t.v[i]
	end,
	size = function(t)
		return t.n
	end,
	table = function(t)
		return t.v
	end,
	append = function(t, ...)
		local nargs = select('#', ...)
		for i, v in ipairs({...}) do
			t[t.n+i] = v
		end
		t.n = t.n + nargs
		return t
	end,
	merge = function(t, tb)
		local nargs = table.length(tb)
		for i, v in ipairs(tb) do
			t[t.n+i] = v
		end
		t.n = t.n + nargs
		return t
	end,
	unpack = function(t)
		return unpack(t.v, 1, t.n)
	end,
}
argsMeta.__index = argsMeta
argsMeta.__add = function(t, args)
	local v = {}
	for i = 1, t.n do
		v[i] = t.v[i]
	end
	for i = 1, args.n do
		v[i+t.n] = args.v[i]
	end
	return setmetatable({n=t.n+args.n, v=v, __args=true}, argsMeta)
end

-- support nil arg in the tail
function functools.args(...)
	return setmetatable({n=select('#', ...), v={...}, __args=true}, argsMeta)
end

function functools.tablefunc(t, f, onlyCall)
	if onlyCall == nil then onlyCall = true end
	local id = string.format("tablefunc: 0%s", lua_tostring(t):sub(9))
	if onlyCall then
		return setmetatable(t, {
			__call = function(t, ...)
				return f(t, ...)
			end,
			__index = function(t, k)
			end,
			__newindex = function()
				error("its tablefunc, no __newindex")
			end,
			__tostring = function()
				return id
			end,
		})
	else
		return setmetatable(t, {
		__call = function(t, ...)
			return f(t, ...)
		end,
		__tostring = function()
			return id
		end,})
	end
end

return functools