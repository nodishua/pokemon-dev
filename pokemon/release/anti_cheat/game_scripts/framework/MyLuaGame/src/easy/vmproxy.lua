--
-- 代理对象
-- 用于连接model和view
-- 方便逻辑调用和隔离
--

--
-- ViewProxy
--
-- model -> view
-- 反作弊时屏蔽view操作
-- 也保护当view销毁时model处理不受影响
-- 但不保证返回值正常, 所以不要再model中使用proxy的返回值
--

require "battle.models.cow_proxy"

local defaultproxy
local proxyfunc
local proxymeta = {
	__index = function (t, k)
		return proxyfunc
	end,
	__newindex = function (t, k, v)
		-- write nil
	end
}

local checkmeta = {
	__index = function (t, k)
		local f = t.__raw[k]
		if type(f) == "function" then
			-- check:xxx(1,2,3) -> view.xxx(check,1,2,3)
			-- check.xxx(1,2,3) -> view.xxx(1,2,3)
			return function (self, ...)
				if self == t then
					self = cow.proxyView(tostring(t.__raw), t.__raw)
				end

				return f(self, ...)
			end
		end
		-- pass system call
		if k:sub(1, 2) == "__" then
			return f
		end
		error(string.format("ViewProxy could not access non-function member %s[%s] = %s", t.__raw, k, f))
	end,
	__newindex = function (t, k, v)
		-- write nil
	end
}

local ProxyObjs = setmetatable({}, {__mode = "kv"})
local ProxyResumeObjs = {}
globals.ViewProxy = class('ViewProxy')

function ViewProxy.allModelOnly()
	ProxyResumeObjs = {}
	for p, view in pairs(ProxyObjs) do
		local raw = p:raw()
		if p == gRootViewProxy then
			table.insert(ProxyResumeObjs, {p, view})
		end
		if raw and raw.modelOnly then
			raw:modelOnly()
		end
		p:modelOnly()
		ProxyObjs[p] = nil
	end
end

function ViewProxy.allModelResum()
	for _, data in ipairs(ProxyResumeObjs) do
		local p, view = data[1], data[2]
		local raw = p:raw()
		if raw and raw.modelOnly and raw.v then
			raw.vproxy = nil
		end
		if p.v then
			p.vproxy = nil
		end
		ProxyObjs[p] = view
	end
	ProxyResumeObjs = {}
end

function ViewProxy:ctor(view)
	-- compatible for table.isproxy
	self.__proxy = true

	self.v = view
	self.vproxy = nil
	if view == nil then
		self:modelOnly()
	else
		if device.platform == "windows" then
			self.v = setmetatable({__raw = view}, checkmeta)
		end
	end

	ProxyObjs[self] = view
end

function ViewProxy:modelOnly(proxy)
	self.vproxy = setmetatable(proxy or {}, proxymeta)
end

function ViewProxy:isModelOnly()
	return self.vproxy ~= nil
end

function ViewProxy:raw()
	-- if v is nil, vproxy could help to avoid error
	return self:cow() or self.vproxy
end

function ViewProxy:cow()
	if device.platform == "windows" then return self.v end
	return cow.proxyView(tostring(self.v), self.v)
end

if device.platform == "windows" then
	function ViewProxy:raw()
		return (self:cow() and self:cow().__raw) or self.vproxy
	end
end

-- @comment: 可以直接调用view的函数
function ViewProxy:proxy()
	return self.vproxy or self:cow()
end

-- @comment: 通过onViewProxyNotify来进行广播
function ViewProxy:notify(...)
	if self.vproxy == nil and self.v.onViewProxyNotify then
		return self:cow():onViewProxyNotify(...) -- for tail call, no return
	end
end

function ViewProxy:call(...)
	if self.vproxy == nil and self.v.onViewProxyCall then
		return self:cow():onViewProxyCall(...) -- for tail call, no return
	end
end

-- @comment: 通过onViewProxyCall来返回ViewProxy
-- @comment: 通过onViewProxyCallBeProxy来返回ViewProxy并建立View->Proxy关联
function ViewProxy:getProxy(...)
	if self.vproxy == nil and self.v.onViewProxyCall then
		local view = self:cow():onViewProxyCall(...)
		local proxy = ViewProxy.new(view)
		if self.v.onViewBeProxy then
			self:cow():onViewBeProxy(view, proxy)
		end
		return proxy
	end
	return defaultproxy
end

defaultproxy = ViewProxy.new()
proxyfunc = function( ... )
	return defaultproxy
end


--
-- readOnlyProxy
--
-- view -> model
-- 防止view修改model数据
-- 可用于object和table的readOnly保护
--

local isObject = isObject
local isClass = isClass

local ProtectWritePass = {
	order = true, -- CMap.order
	keyhash = true, -- CCollection
	hash = true, -- CCollection
}

local function _readOnlyObject(obj, proxy)
	-- read safe only in win for assert
	if device.platform ~= "windows" then
		if proxy == nil or itertools.isempty(proxy) then
			return obj
		end
	end

	proxy = proxy or {}
	if not proxy.__tostring then
		proxy.__tostring = function(tp)
			return string.format("readonly(%s)", tostring(table.getraw(tp)))
		end
	end

	return table.proxytable(obj, proxy, nil, function(t, k, v)
		if ProtectWritePass[k] then
			return true
		end
		error(string.format("%s read only! do not set %s!", tostring(t), k))
	end)
end

local function _readOnlyProxy(objOrTable, proxy)
	if objOrTable == nil then return nil end
	if type(objOrTable) == "table" then
		if table.isproxy(objOrTable) then
			return objOrTable
		end
		return _readOnlyObject(objOrTable, proxy)
	end
	return objOrTable
end

function globals.readOnlyProxy(objOrTable, proxy)
	local ret = _readOnlyProxy(objOrTable, proxy)
	if not ret then
		error(string.format("can not proxy with %s!", tostring(objOrTable)))
	end
	return ret
end


--------------------------------
-- test code
--------------------------------

-- local ttclass = class("tt")
-- function ttclass:ctor()
-- 	self.tb = {1,2,3, aaa="test", bbb={}}
-- 	print('self, tb=', self, self.tb, self.tb.bbb)
-- end

-- function ttclass:get()
-- 	return self.tb
-- end

-- local obj = ttclass.new()
-- local px = readOnlyProxy(obj)
-- local px2 = table.immutabletable(obj)
-- print('------------------- gettttt', px, px:get())
-- print(isObject(obj), isObject(px), isObject(px:get()))
-- print('------------------- gettttt2', px2, px2:get())
-- print(isObject(obj), isObject(px2), isObject(px2:get()))

-- print('!!!!', px:get()[1])
-- print('!!!!2', px2:get()[1])
-- for k,v in pairs(px:get()) do
-- 	print(k,v, table.getraw(v))
-- end
-- print('----------------- test')
-- for k,v in pairs(px2:get()) do
-- 	print(k,v, table.getraw(v))
-- end

-- -- px.hello = "test"
-- -- px:get().hello = "test"

-- print('----------------- over')