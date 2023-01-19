--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- idler
--

local type = type
local lua_type = lua_type
local strfmt = string.format
local tinsert = table.insert
local tremove = table.remove

local idlersystem = idlersystem

local IdlerCnt = 1
local function newid()
	local ret = IdlerCnt
	IdlerCnt = IdlerCnt + 1
	return ret
end

local function getSafeListenersForAdd(self)
	local listeners = self.newListeners or self.listeners
	if self.working and not self.newListeners then
		listeners = {}
		self.newListeners = listeners
	end
	return listeners
end

local function safeAddListenersForCall(self)
	if self.newListeners then
		local listeners = self.newListeners
		self.newListeners = nil
		table.merge(self.listeners, listeners)
	end
end

-- local function print_r(t)
-- 	for i, tt in ipairs(t) do
-- 		print('-------------', i)
-- 		for k, v in pairs(tt) do
-- 			if v > 1 then
-- 				print('  ', k, v, getIdlerCreatedSource(k), getIdlerLastChanged(k))
-- 			else
-- 				print('  ', k, v)
-- 			end
-- 		end
-- 	end
-- end

--------------------------------
--
-- idler 监听器
--

local idler = {__idler = true, __cname = "idler"}
globals.idler = idler
idler.__class = idler
idler.__index = idler
idler.newid = newid

local function isIdler(t)
	return lua_type(t) == "table" and t.__idler == true
end
globals.isIdler = isIdler

-- @param init: inited value
-- @param name: for debug show
function idler.new(init, name)
	assert(not isIdler(init), "init value already was idler yet")
	assert(type(init) ~= "table", "use idlertable.new is better")

	local self = setmetatable({
		listeners = {}, -- downstream
		oldval = init,
		name = name,
		working = false,
		__cid = newid(),
	}, idler)

	idlersystem.addIdler(self)
	return self
end

-- write
function idler:set(val, force)
	if isIdler(val) then
		val = val:get_()
	end
	return self:changed_(val, force)
end

-- read/write
-- got it, process and set to self's value
function idler:modify(f, force)
	local val = self.oldval
	local setit, newval = f(val)
	if setit then
		return self:changed_(newval, force)
	end
	return self:changed_(val, force)
end

-- read
-- only read for get value
function idler:read(f)
	local val = self.oldval
	-- immutable in windows for debug
	if device.platform == "windows" then
		if lua_type(val) == "table" then
			val = table.immutabletable(val)
		end
	end
	if f == nil then
		return val
	end
	return f(val)
end

-- @param callback: callback(val, oldval, idler)
-- @notice: the callback dont invoke any cc.Node, if you want it, use Node:listenIdler
function idler:addListener(callback, noInit)
	local key = listenerkey.new(self)
	local listeners = getSafeListenersForAdd(self)
	listeners[key] = callback
	if not noInit then
		-- 1. from Node:listenIdler
		callback(self.oldval, self.oldval, self)
	end
	return key
end

-- clean other's listeners which listen by self
function idler:delListener(key)
	local exist = self.listeners[key]
	local inOld = exist ~= nil
	if not inOld and self.newListeners then
		exist = self.newListeners[key]
	end
	if exist == nil then
		printWarnStack(strfmt("%s no such listener key %s", tostring(self), tostring(key)))
		print(dumps(itertools.keys(self.listeners)))
	end
	if inOld then
		self.listeners[key] = nil
	end
	if self.newListeners then
		self.newListeners[key] = nil
	end
	-- keep listenerkey valid state
	key:detach_()
end

-- shutup will cut the downstream which link to self
function idler:shutup()
	if self.listeners == nil then return end
	local listeners = self.listeners
	local newListeners = self.newListeners
	self.listeners = {}
	self.newListeners = nil
	for key, _ in pairs(listeners) do
		key:detach_()
	end
	if newListeners then
		for key, _ in pairs(newListeners) do
			key:detach_()
		end
	end
end

-- destroy will cut the downstream and upstream
function idler:destroy()
	if self.listeners == nil then return end
	-- idler is source, so it only had downstream
	local listeners = self.listeners
	local newListeners = self.newListeners
	self.listeners = nil
	self.newListeners = nil
	self.oldval = nil
	for key, _ in pairs(listeners) do
		key:detach_()
	end
	if newListeners then
		for key, _ in pairs(newListeners) do
			key:detach_()
		end
	end
end

function idler:notify()
	return self:changed_(self.oldval, true)
end

-- internal read
-- only for internal usage, like idlers:add
function idler:get_()
	return self.oldval
end

function idler:changed_(val, force)
	if self.listeners == nil then return end

	local oldval = self.oldval
	if not force then
		if val == oldval then
			return val
		end
	end
	self.oldval = val

	if idlersystem.onIntercepting(self) then return val end

	idlersystem.pushChangingCallStack(self)
	if self.working then return idlersystem.errorChangingCallStack(self) end

	self.working = true
	-- maybe delete and insert in callback
	for k, callback in pairs(self.listeners) do
		callback(val, oldval, self)
	end
	self.working = false
	safeAddListenersForCall(self)
	idlersystem.popChangingCallStack(self)
	return val
end

function idler:__tostring()
	return strfmt("%s: 0x%x%s", self.__cname, self.__cid, self.name and string.format("(%s)", tostring(self.name)) or "")
end

--------------------------------
--
-- idlertable table监听器
--

local idlertable = clone(idler)
globals.idlertable = idlertable
idlertable.__idlertable = true
idlertable.__class = idlertable
idlertable.__index = idlertable
idlertable.__cname = "idlertable"

function globals.isIdlertable(t)
	return lua_type(t) == "table" and t.__idlertable == true
end

-- @param t: inited table
-- idlertable:proxy() --> proxy -- proxy:idler() --> idlertable
function idlertable.new(t, name)
	assert(not isIdler(t), "init value already was idler yet")
	assert(not table.isproxy(t), "init value already was proxy")
	assert(not table.isimmutable(t), "init value already was immutable")

	local self = setmetatable({
		listeners = {},
		oldval = t,
		proxyval = nil,
		name = name,
		working = false,
		__cid = newid(),
	}, idlertable)
	self.proxyval = self:proxytable_(t)

	idlersystem.addIdler(self)
	return self
end

function idlertable:proxytable_(t)
	local proxy = {
		idler = function(p)
			-- no sub-tables recursively
			-- all changed in sub-tables impact to root table
			if p == self.proxyval then
				return self
			end
		end
	}
	return table.proxytable(t, proxy, nil, function(_, k, v)
		-- print('!!! proxy write', self, t, k)
		self:changed_(t, true)
	end)
end

-- diff with idler:modify
-- it support the table which same address but content be changed
function idlertable:modify(f, force)
	local val = self.oldval
	local setit, newval = f(val)
	if setit then
		return self:changed_(newval, true)
	end
	return self:changed_(val, force)
end

-- diff with :read()
-- it can be read and write
function idlertable:proxy()
	return self.proxyval
end

function idlertable:size()
	return itertools.size(self.oldval)
end

function idlertable:ipairs()
	return ipairs(self.oldval)
end

function idlertable:pairs()
	return pairs(self.oldval)
end

function idlertable:changed_(val, force)
	if self.listeners == nil then return end

	local oldval = self.oldval
	if not force then
		if itertools.equal(val, oldval) then
			return val
		end
	end
	self.oldval = val
	self.proxyval = self:proxytable_(val)

	if idlersystem.onIntercepting(self) then return val end

	idlersystem.pushChangingCallStack(self)
	if self.working then return idlersystem.errorChangingCallStack(self) end

	self.working = true
	-- maybe delete and insert in callback
	for k, callback in pairs(self.listeners) do
		callback(val, oldval, self)
	end
	self.working = false
	safeAddListenersForCall(self)
	idlersystem.popChangingCallStack(self)
	return val
end

function idlertable:destroy()
	self.proxyval = nil
	-- idlertable is source, so it only had downstream
	return idler.destroy(self)
end

--------------------------------
--
-- idlers 监听器集合管理
--

local idlers = {__idler = true, __idlers = true, __cname = "idlers"}
globals.idlers = idlers
idlers.__class = idlers
idlers.__index = idlers
idlers.newid = newid

function globals.isIdlers(t)
	return lua_type(t) == "table" and t.__idlers == true
end

-- @return idler, val
local function getValue(o)
	if isIdler(o) then
		return o, o:get_()
	end
	return nil, o
end

local function vForKey(v)
	return v
end

function idlers.new(name)
	-- if audience == nil then audience = true end
	local self = setmetatable({
		listeners = {}, -- downstream
		speakers = {}, -- upstream
		tickets = {}, -- upstream listen key
		name = name,
		working = false,
		-- audience = audience, -- allow the speakers's value is not idler
		__cid = newid(),
	}, idlers)

	idlersystem.addIdler(self)
	return self
end

function idlers.newWithMap(t, name)
	local obj = idlers.new(name)
	for k, v in pairs(t) do
		obj:rawAdd_(k, v)
	end
	return obj
end

function idlers:convertValue_(k, v)
	-- if not self.audience then return v end
	if isIdler(v) then
		return v
	else
		return idlereasy.new(v, strfmt("#%s[%s]", tostring(self.name or ""), tostring(k)))
	end
end

function idlers:get_()
	return self.speakers
end

function idlers:assign(t)
	assert(not isIdler(t), "t already was idler yet, you want add or assign?")

	-- remove
	self:notify_({event="remove_all"})
	for k, v in pairs(self.speakers) do
		self:remove(k)
	end
	self.speakers = {}
	self.tickets = {}
	-- add
	for k, v in pairs(t) do
		self:rawAdd_(k, v)
	end
	self:notify_({event="init"})
end

local function hashWithDuplicate(t, key)
	local hash = {}
	for k, v in pairs(t) do
		if isIdler(v) then v = v:get_() end
		local kk = key(v)
		if hash[kk] == nil then
			hash[kk] = k
		elseif type(hash[kk]) == "table" then
			hash[kk][k] = k
		else
			hash[kk] = {[hash[kk]]=hash[kk], [k]=k}
		end
	end
	return hash
end

function idlers:update(t, key)
	assert(not isIdler(t), "t already was idler yet, you want add or assign?")
	local sign = key or false
	key = key or vForKey
	-- local equal = equal or itertools.equal

	-- diff
	local diff = {}
	local adds, rems, swaps, upds = {}, {}, {},{}
	local hash = hashWithDuplicate(self.speakers, key)
	local hash2 = hashWithDuplicate(t, key)

	local function diffWithHash(key, idx)
		local k2 = hash2[key]
		if k2 then
			if type(k2) == "table" then
				local tmp = k2
				k2 = tmp[idx] or next(tmp) -- same position first
				tmp[k2] = nil
				if not next(tmp) then
					hash2[key] = nil
				end
			else
				hash2[key] = nil
			end

			if idx ~= k2 then
				if self.speakers[k2] then
					diff[idx] = "swap " .. tostring(k2)
					swaps[idx] = k2
				else
					-- may be k2 not in self.speakers
					diff[idx] = "remove"
					diff[k2] = "add"
					tinsert(rems, idx)
					tinsert(adds, k2)
				end
			else
				tinsert(upds, idx)
				diff[idx] = "keep"
			end
		else
			diff[idx] = "remove"
			tinsert(rems, idx)
		end
	end

	for kk, k in pairs(hash) do
		if type(k) == "table" then
			for _, k2 in pairs(k) do
				diffWithHash(kk, k2)
			end
		else
			diffWithHash(kk, k)
		end
	end

	for kk, k in pairs(hash2) do
		if type(k) == "table" then
			for _, k2 in pairs(k) do
				diff[k2] = "add"
				tinsert(adds, k2)
			end
		else
			diff[k] = "add"
			tinsert(adds, k)
		end
	end

	-- print('---- diff:', #rems, #adds, itertools.size(swaps), self:size())
	-- print_r(diff)
	-- print('---- swaps:')
	-- print_r(swaps)
	-- print('---- rems:')
	-- print_r(rems)
	-- print('---- adds:')
	-- print_r(adds)

	if #rems + #adds >= self:size() then
		return self:assign(t)
	end

	self:notify_({event="update_all_begin"})
	local map = {} -- old -> new
	local invmap = {} -- new -> old
	if next(swaps) then
		-- k1 is relative position
		-- k2 is absolute position
		for k1, k2 in pairs(swaps) do
			local old = map[k1] or k1
			-- print('swap', k1, k2, 'map', old, k2)
			if old ~= k2 then
				self:swap(old, k2)

				local k2new = invmap[k2] or k2
				map[k1] = k2
				map[k2new] = old

				invmap[k2] = k1
				invmap[old] = k2new
			end
		end
	end
	-- print('---- map:')
	-- print_r(map)
	-- print_r(invmap)
	if next(map) then
		rems = itertools.map(rems, function(i, k)
			return map[k] or k
		end)
	end
	table.sort(rems)
	for i = #rems, 1, -1 do
		-- print('remove', rems[i])
		self:remove(rems[i])
	end
	table.sort(adds)
	for _, k in ipairs(adds) do
		-- print('add', k)
		self:add(k, t[k])
	end

	if sign then
		for _, k in ipairs(upds) do
			self:at(k):set(t[k])
		end
	end
	-- print('speakers size', #self.speakers, self:size())
	self:notify_({event="update_all_end"})
end

function idlers:rawAdd_(k, v)
	local o = self:convertValue_(k, v)
	self.speakers[k] = o
	-- if self.audience then
		-- only idler had update event now
		local key = o:addListener(functools.partial(self.notify_, self, {event="update", key=k, idler=o}), true)
		self.tickets[k] = key
	-- end
	return o
end

function idlers:add(k, v)
	self:remove(k)
	local o, val = getValue(self:rawAdd_(k, v))
	self:notify_({event="add", key=k, val=val, idler=o})
end

function idlers:remove(k)
	local old, oldkey = self.speakers[k], self.tickets[k]
	self.speakers[k] = nil
	self.tickets[k] = nil
	if oldkey then oldkey:detach() end
	if old then
		local o, val = getValue(old)
		self:notify_({event="remove", key=k, val=val, idler=o})
	end
end

function idlers:swap(k1, k2)
	local old1, oldkey1 = self.speakers[k1], self.tickets[k1]
	local old2, oldkey2 = self.speakers[k2], self.tickets[k2]
	if old1 == nil or old2 == nil then
		printWarn('k1=%s or k2=%s is nil', tostring(k1), tostring(k2))
		return
	end
	self.speakers[k1], self.tickets[k1] = old2, oldkey2
	self.speakers[k2], self.tickets[k2] = old1, oldkey1
	local o1, val1 = getValue(old1)
	local o2, val2 = getValue(old2)
	self:notify_({event="swap", key1=k1, val1=val1, idler1=o1, key2=k2, val2=val2, idler2=o2})
end

function idlers:at(k)
	if isIdler(k) then k = k:get_() end
	return self.speakers[k]
end

-- only for value is idlertable
function idlers:atproxy(k)
	local o = self:at(k)
	if o then
		return o:proxy()
	end
end

function idlers:size()
	return itertools.size(self.speakers)
end

function idlers:ipairs()
	return ipairs(self.speakers)
end

function idlers:pairs()
	return pairs(self.speakers)
end

-- @param callback: callback(msg, idlers)
function idlers:addListener(callback, noInit)
	local key = listenerkey.new(self)
	local listeners = getSafeListenersForAdd(self)
	listeners[key] = callback
	if not noInit then
		callback({event="init"}, self)
	end
	return key
end

function idlers:delListener(key)
	idler.delListener(self, key)
end

function idlers:notify_(msg)
	assert(msg, "msg is nil")
	if self.listeners == nil then return end

	if idlersystem.onIntercepting(self, msg) then return end

	idlersystem.pushChangingCallStack(self)
	if self.working then return idlersystem.errorChangingCallStack(self) end

	self.working = true
	for k, callback in pairs(self.listeners) do
		callback(msg, self)
	end
	self.working = false
	safeAddListenersForCall(self)
	idlersystem.popChangingCallStack(self)
end

-- @param ...: nil or keys
function idlers:notify(...)
	local keys = {...}
	if #keys == 0 then keys = nil end
	return self:notify_({event="refresh", keys=keys})
end

function idlers:shutup()
	idler.shutup(self)
end

function idlers:destroy()
	if self.listeners == nil then return end
	local tickets = self.tickets
	self.tickets = nil
	self.speakers = nil
	for k, key in pairs(tickets) do
		key:detach()
	end

	return idler.destroy(self)
end

function idlers:__tostring()
	return strfmt("%s: 0x%x%s", self.__cname, self.__cid, self.name and string.format("(%s)", tostring(self.name)) or "")
end


-- local t = {{val=1},{val=2},{val=3},{val=4},{val=5}}
-- local ii = idlers.newWithMap(t)
-- -- local tt = {t[4], t[2], t[5], t[3], t[1]} -- swap circle
-- -- local tt = {t[2], t[3], t[4], t[5], {val=6}} -- erase front and append
-- -- local tt = {t[2], t[3], t[1], {val=6}, t[5], t[4]} -- swap and insert
-- -- local tt = {t[2], t[3], {val=6}, t[1], t[2]} -- duplicate
-- -- local tt = {t[2], t[3], {val=6}, t[1], t[2], t[2]} -- duplicate
-- ii:update(tt)
-- print_r(ii:get_())