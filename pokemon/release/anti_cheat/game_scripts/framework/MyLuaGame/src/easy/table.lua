--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- table的扩展
--

-- t = defaulttable(defaulttable(function() return "123" end))
-- print(t[1], t[1][2])
-- =>
-- table "123"
function table.defaulttable(default)
	return setmetatable({}, {
		__index = function(t, k)
			local v = default()
			rawset(t, k, v)
			return v
		end,
		__call = function()
			return table.defaulttable(default)
		end
	})
end

local function convert2proxy(proxy, onRead, onWrite, v)
	if type(v) == "table" then v = table.proxytable(v, proxy, onRead, onWrite) end
	return v
end

local function convertkv2proxy(proxy, onRead, onWrite, t, k, v)
	if onRead then onRead(t, k, v) end
	if type(v) == "table" then v = table.proxytable(v, proxy, onRead, onWrite) end
	return k, v
end

function table.isproxy(t)
	return t and type(t) == "table" and t.__proxy
end

-- t = proxytable({a=1}, {m_name=2}, function)
function table.proxytable(t, proxy, onRead, onWrite)
	proxy = proxy or {}
	local rawmt = getmetatable(t) or {}
	local wrap = functools.partial(convertkv2proxy, proxy, onRead, onWrite, t)
	local mt = {
		__index = function(_, k)
			local v = t[k]
			if onRead then onRead(t, k, v) end
			if v == nil then return proxy[k] end
			return convert2proxy(proxy, onRead, onWrite, v)
		end,
		__newindex = function(_, k, v)
			-- unfold proxy by auto
			if table.isproxy(v) then
				error("do not save proxy in proxy, you could do this when get raw table")
			end
			t[k] = v
			if onWrite then onWrite(t, k, v) end
		end,
		__call = function(...)
			-- special for saltnumber
			if rawmt.__call then
				return rawmt.__call(t, ...)
			end
			return t
		end,
		__pairs = function(_)
			local it, tb, init = pairs(t)
			return itertools.iter(it, tb, init, wrap)
		end,
		__ipairs = function(_)
			local it, tb, init = ipairs(t)
			return itertools.iter(it, tb, init, wrap)
		end,
		__next = function(_, k)
			return wrap(next(t, k))
		end,
		__len = function(_)
			return itertools.size(t)
		end,
		__eq = proxy.__eq or rawmt.__eq,
		__lt = proxy.__lt or rawmt.__lt,
		__le = proxy.__le or rawmt.__le,
		__tostring = proxy.__tostring or rawmt.__tostring,
	}
	local ret = {
		__proxy = true,
		__raw = t,
		-- for isObject
		__class = t and rawget(t, '__class'),
		__cid = t and rawget(t, '__cid'),
		-- for isClass
		__cname = t and rawget(t, '__cname'),
	}
	return setmetatable(ret, mt)
end

local function convert2immutable(v)
	if type(v) == "table" then v = table.immutabletable(v) end
	return v
end

local function convertkv2immutable(k, v)
	if type(v) == "table" then v = table.immutabletable(v) end
	return k, v
end

function table.isimmutable(t)
	return t and type(t) == "table" and t.__immutable
end

function table.immutabletable(t)
	local rawmt = getmetatable(t) or {}
	local mt = {
		__index = function(_, k)
			return convert2immutable(t[k])
		end,
		__newindex = function(_, k, v)
			error(string.format("this is immutable table, you can not set %s in here", tostring(k)))
		end,
		__call = function()
			return t
		end,
		__pairs = function(_)
			local it, tb, init = pairs(t)
			return itertools.iter(it, tb, init, convertkv2immutable)
		end,
		__ipairs = function(_)
			local it, tb, init = ipairs(t)
			return itertools.iter(it, tb, init, convertkv2immutable)
		end,
		__next = function(_, k)
			return convertkv2immutable(next(t, k))
		end,
		__eq = rawmt.__eq,
		__lt = rawmt.__lt,
		__le = rawmt.__le,
		__tostring = rawmt.__tostring,
	}
	local ret = {
		__immutable = true,
		__raw = t,
		-- for isObject
		__class = t and rawget(t, '__class'),
		__cid = t and rawget(t, '__cid'),
		-- for isClass
		__cname = t and rawget(t, '__cname'),
	}
	return setmetatable(ret, mt)
end

-- table.getraw return raw or t
-- immutabletable and proxytable use in win32 for protected csv mostly
-- KEEP IT SAFE!!!
-- DONT USE IN APPLICATION
local getraw
function table.getraw(t)
	local ttype = lua_type(t)
	if ttype == "table" then
		local raw = rawget(t, "__raw")
		local rtype = lua_type(raw)
		if rtype == "table" or rtype == "userdata" then
			return raw
			-- return getraw(raw)
		end
		return t

	elseif ttype == "userdata" then
		-- raw is itself
		-- we only set __raw in table
		return t
	end
end
getraw = table.getraw

--
-- NOTICE!!!
--
-- because immutabletable/proxytable could not reload Lua's # and unpack
-- if you want to use other table.XXX functions like table.maxn with raw table
-- found it in table_override.lua
-- normally, you should known the diff between table and proxytable/immutabletable
-- and make difference code expicity
--

-- table.unpack implement it like unpack
function table.unpack(t, ...)
	return unpack(getraw(t), ...)
end

-- table.length implement it like #
-- array size
-- IMPORTANT: must be used in battle model and csv replace #
--
-- LUA DOCUMENT:
-- "len": the # operation.
--  function len_event (op)
--    if type(op) == "string" then
--      return strlen(op)         -- primitive string length
--    elseif type(op) == "table" then
--      return #op                -- primitive table length
--    else
--      local h = metatable(op).__len
--      if h then
--        -- call the handler with the operand
--        return (h(op))
--      else  -- no handler available: default behavior
--        error(···)
--      end
--    end
--  end
function table.length(t)
	t = getraw(t)
	local mt = getmetatable(t)
	if mt and mt.__len then
		return mt.__len(t)
	end
	return #t
end

function table.clear(t)
	for k, v in pairs(t) do
		t[k] = nil
	end
end

function table.swapvalue(t, k1, k2)
	t[k1], t[k2] = t[k2], t[k1]
end

-- @param : last is value
function table.set(t, k, ...)
	if t == nil then return end
	local n = select('#', ...)
	assert(k ~= nil and n >= 1, "must need one key and one value")
	if n == 1 then
		local v = ...
		t[k] = v
		return
	end
	if n == 2 then
		local k2, v = ...
		if t[k] == nil then
			if v ~= nil then
				t[k] = {[k2] = v}
			end
		else
			t[k][k2] = v
		end
		return
	end

	local keys = {k, ...}
	local v = keys[n + 1]
	-- may be v is nil, #keys = n
	if n + 1 == #keys then
		table.remove(keys)
	end
	return table.setWithKeys(t, keys, v)
end

-- @param: keys is table
function table.setWithKeys(t, keys, v)
	local n = table.length(keys)
	assert(n >= 1, "must need one key")
	for i = 1, n - 1 do
		if lua_type(t) ~= 'table' then
			error(string.format("%s is not table, it could not be set", t))
		end
		local k = keys[i]
		local tt = t[k]
		if tt == nil then
			if v == nil then
				return
			end
			tt = {}
			t[k] = tt
		end
		t = tt
	end
	t[keys[n]] = v
end

function table.get(t, ...)
	if t == nil then return end
	local n = select('#', ...)
	assert(n >= 1, "must need one key")
	if n == 1 then
		local k = ...
		return t[k]
	end
	if n == 2 then
		local k1, k2 = ...
		if lua_type(t[k1]) ~= "table" then return end
		return t[k1][k2]
	end

	return table.getWithKeys(t, {...})
end

function table.getWithKeys(t, keys)
	local n = table.length(keys)
	assert(n >= 1, "must need one key")
	for i = 1, n do
		local k = keys[i]
		if lua_type(t) ~= 'table' then
			if t ~= nil then
				printWarn("value of [%s] was %s, it could not be iter next", k, t)
			end
			return
		end
		t = t[k]
	end
	return t
end

-- shallow copy
function table.shallowcopy(t)
	local ret = {}
	for k, v in pairs(t) do
		ret[k] = v
	end
	return ret
end

-- diff with clone
-- no lookup_table, all table is new and standalone include metatable
function table.deepcopy(object, plain)
	local function _copy(o)
		if lua_type(o) ~= "table" then
			return o
		end
		if isIdler(o) then
			o = o:get_()
		else
			o = table.getraw(o) or o
		end
		local new = {}
		for key, value in pairs(o) do
			new[_copy(key)] = _copy(value)
		end
		if plain then return new end
		return setmetatable(new, _copy(getmetatable(o)))
	end
	return _copy(object)
end

table.emptytable = setmetatable({}, {
	__newindex = function(t, k, v)
		error(string.format("empty const table can not be write `%s`!", k))
	end}
)

local SaltMetaTable = {
	__index = function(t, k)
		-- SaltNumber keep data safe
		local salts = rawget(t, "__salts")
		local salt = salts[k]
		if salt == nil then return nil end
		return salt()
	end,
	__newindex = function(t, k, v)
		local salts = rawget(t, "__salts")
		local salt = salts[k]
		if salt == nil then
			assert(type(v) == "number", "salt only for number")
			salt = SaltNumber.new(v)
			salts[k] = salt
		end
		salt(v)
	end,
	__call = function(t)
		local salts = rawget(t, "__salts")
		return itertools.map(salts, function(k, salt)
			return k, salt()
		end)
	end,
}

function table.salttable(t)
	-- TODO: remove such return when cow.proxy bug be solved
	do return table.deepcopy(t) end

	-- no salt in anti agent
	if ANTI_AGENT then return table.deepcopy(t) end

	-- SaltNumber keep numeric data safe
	local salts = {}
	for k, v in pairs(t) do
		assert(type(v) == "number", "salt only for number")
		salts[k] = SaltNumber.new(v)
	end
	return setmetatable({__salt = true, __salts = salts}, SaltMetaTable)
end

function table.issalt(t)
	return t and type(t) == "table" and t.__salt
end

function table.flatArray(arr, narr)
	narr = narr or #arr
	for i = 1, narr do
		local v = arr[i]
		if isIdler(v) then
			arr[i] = v:get_()
		else
			arr[i] = table.getraw(v) or v
		end
	end
	return arr
end
