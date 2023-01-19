--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2018 TianJi Information Technology Inc.
--
-- idler管理
--

local strfmt = string.format
local idlerdebug = idlerdebug

local IdlerListenerCnt = 1
local IdlerWeakCache = setmetatable({}, {__mode="v"})
local IdlerAnonyOnlyKeyMap = setmetatable({}, {__mode="v"})
local ViewIdlersMap = table.defaulttable(function() return setmetatable({}, {__mode="v"}) end)
local CleanUpViewIdlersMap = {}
local ViewStack = {}
local CurrentViewMap
local CurrentViewKey
local CurrentCoroutineViewKey
local Intercept = false
local InterceptMap = {}
local SkipAddMark = 0

cc.load("components")
local messageComponent = cc.load("message")

--------------------------------
--
-- listenerkey 监听者key
-- 方便外部detach
--

local listenerkey = {__listenerkey = true, __cname = "listenerkey"}
globals.listenerkey = listenerkey
listenerkey.__index = listenerkey

function listenerkey.new(idler)
	local id = IdlerListenerCnt
	IdlerListenerCnt = IdlerListenerCnt + 1
	local self = setmetatable({
		id = id,
		idlerID = idler.__cid,
	}, listenerkey)

	idlerdebug.addIdlerListener(self)
	return self
end

-- internal usage
function listenerkey:detach_()
	self.idlerID = nil
end

-- external usage
function listenerkey:detach()
	local idler = IdlerWeakCache[self.idlerID]
	if idler then
		idler:delListener(self)
	end
	self.idlerID = nil
end

function listenerkey:isdetach()
	return self.idlerID == nil
end

function listenerkey:speaker()
	return self.idlerID and IdlerWeakCache[self.idlerID]
end

function listenerkey.__tostring(self)
	local idler = self.idlerID and IdlerWeakCache[self.idlerID]
	if idler then
		return strfmt("listenerkey: 0x%x (attach %s)", self.id, tostring(idler))
	end
	if self.idlerID then
		return strfmt("listenerkey: 0x%x (? 0x%x)", self.id, self.idlerID)
	end
	return strfmt("listenerkey: 0x%x (detach)", self.id)
end

--------------------------------
--
-- idlersystem
-- idler几种解绑机制
-- 1. Node:listenIdler在node exit的时候进行解绑。 bind.listen机制
-- 2. 对ViewBase:onCreate里创建的idler进行监控。 cleanup时主动destroy
-- 3. 对协程加载里创建的idler进行监控。 cleanup时主动destroy
--
-- 2、3 默认onCreate和协程不会创建其它view的idler
--
-- TODO：
-- shutup时对downstream的listenerkey里的idlerID有清理，但不保证listenerkey就被回收
-- 毕竟下游的tickets里还持有相关引用
--
-- 1. anonyOnly进行的替换
--

local idlersystem = {}
globals.idlersystem = idlersystem


function idlersystem.onViewBaseBegin(view)
	local s = tostring(view)

	table.insert(ViewStack, s)
	CurrentViewMap = ViewIdlersMap[s]
	CurrentViewKey = s
end

function idlersystem.onViewBaseEnd(view)
	local s = tostring(view)
	if s == ViewStack[#ViewStack] then
		table.remove(ViewStack)
	else
		printWarn("%s end not same with begin %s", s, tostring(ViewStack[#ViewStack]))

		-- auto fix stack
		local index = table.indexof(ViewStack, s)
		if index then
			for i = index, #ViewStack do
				table.remove(ViewStack)
			end
		end
	end

	CurrentViewMap = nil
	CurrentViewKey = nil
	if #ViewStack > 0 then
		CurrentViewKey = ViewStack[#ViewStack]
		CurrentViewMap = ViewIdlersMap[CurrentViewKey]
	end
end

function idlersystem.onViewBaseCreateBegin(view)
	local s = tostring(view)
	local gc = s:match("ccui.") == nil
	if gc then
		printDebug('gc count %s KB before create %s', collectgarbage('count'), s)
	end

	idlersystem.onViewBaseBegin(view)
end

function idlersystem.onViewBaseCreateEnd(view)
	local s = tostring(view)
	assert(s == ViewStack[#ViewStack], string.format("%s end not same with begin %s", s, tostring(ViewStack[#ViewStack])))
	-- print('idler after created', s, itertools.size(ViewIdlersMap[s]))

	idlersystem.onViewBaseEnd(view)

	-- if gc then
	-- 	print('gc count', collectgarbage('count'), 'KB', 'after create', s)
	-- end
end

function idlersystem.onViewBaseCoroutineBegin(view)
	local s = tostring(view)
	assert(nil == CurrentCoroutineViewKey, string.format("%s begin when %s coroutine not over", s, tostring(CurrentCoroutineViewKey)))

	CurrentCoroutineViewKey = s
end

function idlersystem.onViewBaseCoroutineEnd(view)
	local s = tostring(view)
	assert(s == CurrentCoroutineViewKey, string.format("%s end not same with begin %s", s, CurrentCoroutineViewKey))

	CurrentCoroutineViewKey = nil
end

function idlersystem.onViewBaseScheduleBegin(view)
	idlersystem.onViewBaseBegin(view)
end

function idlersystem.onViewBaseScheduleEnd(view)
	idlersystem.onViewBaseEnd(view)
end

function idlersystem.onViewBaseCleanup(view)
	local s = tostring(view)
	local weak = ViewIdlersMap[s]
	ViewIdlersMap[s] = nil
	if weak == nil then return end

	for k, v in pairs(weak) do
		v:destroy()
	end
	CleanUpViewIdlersMap[s] = weak

	local gc = s:match("ccui.") == nil and s:match("simpleView") == nil
	if gc then
		-- step gc, full gc may be too long
		collectgarbage("step", 100)

		for k, t in pairs(ViewIdlersMap) do
			if not next(t) then
				ViewIdlersMap[k] = nil
			end
		end

		for k, t in pairs(CleanUpViewIdlersMap) do
			if next(t) then
				-- printWarn('idler after cleanup: %s %d', k, itertools.size(t))

				-- if k:find("ShopView") then
				-- 	local cnt = 0
				-- 	for kk, vv in pairs(t) do
				-- 		cnt = cnt + 1
				-- 		print(cnt, kk, vv, getIdlerCreatedSource(vv), getIdlerLastChanged(vv))
				-- 		if cnt < 5 then
				-- 			printObjectAllRefInGlobal(vv)
				-- 		end
				-- 	end
				-- end
			else
				CleanUpViewIdlersMap[k] = nil
				-- printWarn('idler released: %s', k)
			end
		end
		-- printAllIdlers()

		printDebug('gc count %s KB after cleanup %s', collectgarbage('count'), s)
		-- print(display.director:getTextureCache():getCachedTextureInfo())
	end
end

function idlersystem.skipAddIdlerMark(cnt)
	SkipAddMark = SkipAddMark + cnt
end

local missidx = 1
function idlersystem.addIdler(o)
	-- mark in global
	IdlerWeakCache[o.__cid] = o
	idlerdebug.addIdler(o)

	-- mark for viewbase
	if SkipAddMark > 0 then
		SkipAddMark = SkipAddMark - 1
		return
	end

	local viewKey
	-- 协程优先级最高，一般是创建完View之后开始协程加载
	if CurrentCoroutineViewKey then
		viewKey = CurrentCoroutineViewKey
		ViewIdlersMap[CurrentCoroutineViewKey][o.__cid] = o

	else
		-- performWithDelay / Schedule:onScheduleUpdate_
		-- GameUI:doViewDelayCall
		-- ViewBase:onCreate
		if CurrentViewMap then
			viewKey = CurrentViewKey
			CurrentViewMap[o.__cid] = o
		else
			-- missidx = missidx + 1
			-- if globals.syncFromServerOK then
			-- 	printWarn("idler not in view or coroutine, %s %d", tostring(o), missidx)
			-- 	printWarnStack('stack')
			-- end
		end
	end
end

function idlersystem.addAnonymousOnlyIdler(o, view, key)
	local viewKey = tostring(view)
	local k = getIdlerCallTrace(4)
	local desc = k.desc or ""
	-- src/app/views/city/card/bag.lua:onItem:288 7[cardRedHint5]
	if desc:match("^src/app/views/") then
		desc = desc:sub(15)
	end
	desc = desc .. viewKey
	key = key and strfmt("%s[%s]", desc, key) or desc
	local old = IdlerAnonyOnlyKeyMap[key]
	if old then
		old:destroy()
	end
	IdlerAnonyOnlyKeyMap[key] = o

	-- assign old view key for o when o be created not in control
	if ViewIdlersMap[viewKey] then
		ViewIdlersMap[viewKey][o.__cid] = o
	end
end

function idlersystem.getAnonymousOnlyIdlersTotal()
	return itertools.size(IdlerAnonyOnlyKeyMap)
end

function idlersystem.visitAllAnonymousOnlyIdlers(f)
	for k, o in pairs(IdlerAnonyOnlyKeyMap) do
		f(k, o)
	end
end

function idlersystem.pushChangingCallStack(o)
	return idlerdebug.pushChangingCallStack(o)
end

function idlersystem.popChangingCallStack(o)
	return idlerdebug.popChangingCallStack(o)
end

function idlersystem.errorChangingCallStack(o)
	idlerdebug.errorChangingCallStack(o)
	errorInWindows('%s call in loop', tostring(o))
end

function idlersystem.beginIntercept()
	Intercept = true
	-- support delay endIntercept
	-- may be beginIntercept more than once
	-- InterceptMap = {}
end

function idlersystem.endIntercept()
	messageComponent.sendMessage("idlersystem.endIntercept/begin")

	Intercept = false
	for obj, msgs in pairs(InterceptMap) do
		if msgs then
			for _, msg in ipairs(msgs) do
				obj:notify_(msg)
			end
		else
			obj:changed_(obj:get_(), true)
		end
	end
	InterceptMap = {}

	messageComponent.sendMessage("idlersystem.endIntercept/end")
end

function idlersystem.onIntercepting(obj, msg)
	if not Intercept then return false end
	if InterceptMap[obj] then
		printWarn("%s old msg %s, new msg %s", tostring(obj), dumps(InterceptMap[obj]), dumps(msg))
	end
	if msg then
		if InterceptMap[obj] then
			table.insert(InterceptMap[obj], msg)
		else
			InterceptMap[obj] = {msg}
		end
	else
		InterceptMap[obj] = false
	end
	return true
end

function idlersystem.onBindNode(node, idlerName)
	return idlerdebug.addBindIdler(node, idlerName)
end

function idlersystem.onUpdate()
end

function idlersystem.destroyAll()
	ViewIdlersMap = table.defaulttable(function() return setmetatable({}, {__mode="v"}) end)
	ViewStack = {}
	CurrentViewMap = nil
	CurrentViewKey = nil
	CurrentCoroutineViewKey = nil
	Intercept = false
	InterceptMap = {}
	SkipAddMark = 0

	for k, o in pairs(IdlerWeakCache) do
		o:destroy()
	end
	for k, o in pairs(IdlerAnonyOnlyKeyMap) do
		o:destroy()
	end

	collectgarbage()
	if device.platform == "windows" then
		for k, o in pairs(IdlerWeakCache) do
			printIdlerBackChain(o)
			-- printObjectAllRefInGlobal(o)
		end
	end
	printInfo("IdlerWeakCache %d IdlerAnonyOnlyKeyMap %d", itertools.size(IdlerWeakCache), itertools.size(IdlerAnonyOnlyKeyMap))
	printInfo('gc count %s KB after destroyAll', collectgarbage('count'))
end