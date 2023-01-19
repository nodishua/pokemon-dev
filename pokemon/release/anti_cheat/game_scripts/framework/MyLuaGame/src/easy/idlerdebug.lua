--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- idler 调试
--

require "util.str"
require "util.debug"

local isobjectid = string.isobjectid
local getCallTrace = getCallTrace

local null_data = {}
local weakcache = setmetatable({}, {__mode="k"})
local lweakcache = setmetatable({}, {__mode="k"})
local lastset = setmetatable({}, {__mode="k"})
local lastsetdebug = setmetatable({}, {__mode="k"})
local nodebind = setmetatable({}, {__mode="k"})
local hash = {}
local debuglastset = false
local debuglastsettrace = false
local changingstack = {}

local function getIdlerCallTrace(level)
	return getCallTrace(level or 4, function(tb)
		local source, pos = tb.source
		if source:find("/[iep][da]") then
			pos = source:find("/idler")
			pos = pos or source:find("/easy/table")
			pos = pos or source:find("/easy/bind")
			pos = pos or source:find("/packages")
		end
		return not pos
	end)
end

globals.getIdlerCallTrace = getIdlerCallTrace

local function stringTrack(track, reverse)
	local t = {}
	local s, e, step = #track, 1, -1
	if reverse then
		s, e, step = 1, #track, 1
	end
	for i = s, e, step do
		local info, s = track[i]
		if info.from == "key" then
			s = "[]"
		elseif info.from == "value" then
			-- s = "["..info.key.."]"
			s = info.key
		elseif info.from == "up" then
			s = "("..tostring(info.i)..","..info.up..")"
		elseif info.from == "mt" then
			s = "{mt}"
		end
		table.insert(t, s)
	end
	return table.concat(t, ".")
end

function globals.printAllIdlers()
	collectgarbage()
	local cnt = 0
	local d = table.defaulttable(function() return {} end)
	for o, info in pairs(lweakcache) do
		table.insert(d[o.__cname], o)
	end
	for o, info in pairs(weakcache) do
		cnt = cnt + 1
		table.insert(d[o.__cname], o)
	end
	local nid, nids, nidt, nidc, nl = #d["idler"], #d["idlers"], #d["idlertable"], #d["idlercomputer"], #d["listenerkey"]
	-- for _, k in ipairs({"listenerkey", "idler", "idlers", "idlertable", "idlercomputer"}) do
	-- 	local debug = d[k]
	-- 	d[k] = nil
	-- 	table.sort(debug, function(t1, t2)
	-- 		local info1 = weakcache[t1] or lweakcache[t1]
	-- 		local info2 = weakcache[t2] or lweakcache[t2]
	-- 		if info1 == nil or info2 == nil then
	-- 			return tostring(t1) < tostring(t2)
	-- 		end
	-- 		if info1.desc ~= info2.desc then
	-- 			return info1.desc < info2.desc
	-- 		else
	-- 			return tostring(t1) < tostring(t2)
	-- 		end
	-- 	end)

	-- 	for i, o in ipairs(debug) do
	-- 		local info = weakcache[o] or lweakcache[o]
	-- 		if info then
	-- 			print(i, o, info.desc, dumps(o.listeners or null_data))
	-- 		end
	-- 	end

	-- 	-- for i, o in ipairs(debug) do
	-- 	-- 	local info = weakcache[o]
	-- 	-- 	print(o, 'ref:', findObjectInGlobal(o))
	-- 	-- end

	-- 	-- if k == "idlercomputer" then
	-- 	-- 	for i, o in ipairs(debug) do
	-- 	-- 		local info = weakcache[o] or lweakcache[o]
	-- 	-- 		if info then
	-- 	-- 			print(i, o, info.desc, dumps(o.listeners or null_data))
	-- 	-- 		end
	-- 	-- 	end

	-- 	-- 	-- for i, o in ipairs(debug) do
	-- 	-- 	-- 	local info = weakcache[o]
	-- 	-- 	-- 	print(o, 'ref:', findObjectInGlobal(o))
	-- 	-- 	-- end
	-- 	-- end
	-- end

	-- idlersystem.visitAllAnonymousOnlyIdlers(function(k, o)
	-- 	local info = weakcache[o]
	-- 	-- , info and info.desc
	-- 	print('anony ' .. tostring(o), k, dumps(o.listeners))
	-- end)

	printDebug('idler %d idlertable %d idlers %d idlercomputer %d = %d, anony %d, listenerkey %d', nid, nidt, nids, nidc, cnt, idlersystem.getAnonymousOnlyIdlersTotal(), nl)
end

local function findObject(obj, g, track)
	if g == nil or hash[g] then
		return false
	end
	hash[g] = true

	local destType = type(g)
	if destType == "table" then
		local mt = getmetatable(g)
		-- ignore weak table
		if mt and mt.__mode then
			return false
		end

		for key, value in pairs(g) do
			if key == obj or value == obj then
				if key == obj then
					table.insert(track, {from="key"})
				else
					table.insert(track, {from="value", key=tostring(key)})
				end
				return true
			end
			if findObject(obj, key, track) then
				table.insert(track, {from="key"})
				return true
			end
			if findObject(obj, value, track) then
				table.insert(track, {from="value", key=tostring(key)})
				return true
			end
		end
		if findObject(obj, mt, track) then
			table.insert(track, {from="mt"})
			return true
		end

	elseif destType == "function" then
		local uvIndex = 1
		while true do
			local name, value = debug.getupvalue(g, uvIndex)
			if name == nil then
				break
			end
			if value == obj or findObject(obj, value, track) then
				table.insert(track, {from="up", i=uvIndex, up=tostring(name)})
				return true
			end
			uvIndex = uvIndex + 1
		end
	end
	return false
end


local function printObjectAllRef(obj, g, track)
	if g == nil or hash[g] then
		return
	end
	hash[g] = true

	local destType = type(g)
	if destType == "table" then
		local mt = getmetatable(g)
		-- ignore weak table
		if mt and rawget(mt, "__mode") then
			return
		end

		for key, value in lua_pairs(g) do
			if key == obj or value == obj then
				if key == obj then
					table.insert(track, {from="key"})
				else
					table.insert(track, {from="value", key=tostring(key)})
				end
				print(stringTrack(track, true))
				table.remove(track)
			end

			table.insert(track, {from="key"})
			printObjectAllRef(obj, key, track)
			table.remove(track)

			table.insert(track, {from="value", key=tostring(key)})
			printObjectAllRef(obj, value, track)
			table.remove(track)
		end

		table.insert(track, {from="mt"})
		printObjectAllRef(obj, mt, track)
		table.remove(track)

	elseif destType == "function" then
		local uvIndex = 1
		while true do
			local name, value = debug.getupvalue(g, uvIndex)
			if name == nil then
				break
			end
			table.insert(track, {from="up", i=uvIndex, up=tostring(name)})
			if value == obj then
				print(stringTrack(track, true))
			else
				printObjectAllRef(obj, value, track)
			end
			table.remove(track)
			uvIndex = uvIndex + 1
		end
	end
end

function globals.findObjectInGlobal(obj)
	hash = setmetatable({
		[weakcache] = true,
		[lweakcache] = true,
	}, {__mode = "k"})
	local track = {}
	local ret, ret2 = findObject(obj, _G, track), nil
	if ret then
		ret2 = stringTrack(track)
	end
	hash = nil
	return ret, ret2
end

function globals.printObjectAllRefInGlobal(obj)
	hash = setmetatable({
		[weakcache] = true,
		[lweakcache] = true,
	}, {__mode = "k"})
	printObjectAllRef(obj, _G, {})
	hash = nil
end

function globals.printIdlerBackChain(obj, prefix)
	if obj == nil then return end
	prefix = prefix or ""
	local info = weakcache[obj]
	if info == nil then return end
	print(string.format("%s[%s] %s", prefix, tostring(obj), info.desc))
	if obj.tickets then
		for k, key in pairs(obj.tickets) do
			print(string.format("%s    %s.%s", prefix, tostring(k), tostring(key)))
			local prefix2 = prefix .. string.rep(" ", 8)
			printIdlerBackChain(key:speaker(), prefix2)
		end
	end
end

function globals.printUVInFunction(f)
	if type(f) ~= "function" then return end
	local uvIndex = 1
	while true do
		local name, value = debug.getupvalue(f, uvIndex)
		if name == nil then
			break
		end
		local desc = ""
		if type(value) == "function" then
			local tb = debug.getinfo(value, "nSl")
			desc = string.format("%s:%s:%d", tb.source, tb.name or "", tb.linedefined)
		end
		print(uvIndex, name, value, desc)
		uvIndex = uvIndex + 1
	end
end

function globals.getIdlerLastChanged(obj)
	local last = lastset[obj]
	return last and last.desc
end

function globals.printIdlerLastChanged(obj, prefix)
	local v = obj:get_()
	if isIdlers(obj) then
		v = string.format("size[%d]", obj:size())
	elseif type(v) == "table" then
		v = dumps(v)
	elseif type(v) == "string" then
		if isobjectid(v) then
			v = stringz.bintohex(v)
		end
	end
	if prefix then
		print(prefix, string.format("%s last modify: %s val: %s", obj, getIdlerLastChanged(obj) or "", v))
	else
		print(string.format("%s last modify: %s val: %s", obj, getIdlerLastChanged(obj) or "", v))
	end
end

function globals.debugIdlerLastChanged(obj, enableTag)
	if enableTag == nil then enableTag = true end
	if enableTag then
		lastsetdebug[obj] = enableTag
	else
		lastsetdebug[obj] = nil
	end
end

function globals.debugAllIdlersLastChanged(enable, trace)
	if enable == nil then enable = true end
	if trace == nil then trace = true end
	debuglastset = enable
	debuglastsettrace = trace
end

function globals.traverseBindNode(f)
	local topUI = gGameUI:getTopStackUI()
	local function checkInTopUI(node)
		if node == nil then
			return false
		end
		local parent = node:getParent()
		if parent == topUI then
			return true
		else
			return checkInTopUI(parent)
		end
		return false
	end
	for node, idlerName in pairs(nodebind) do
		if not tolua.isnull(node) and checkInTopUI(node) and node:isVisible() then
			f(node, idlerName)
		end
	end
end

function globals.getIdlerCreatedSource(obj)
	local info = weakcache[obj] or lweakcache[obj]
	return info and info.desc
end

--------------------------------------
-- idlerdebug
local idlerdebug = {}
globals.idlerdebug = idlerdebug

function idlerdebug.addIdler(o)
	weakcache[o] = getIdlerCallTrace()
end

function idlerdebug.addIdlerListener(o)
	lweakcache[o] = getIdlerCallTrace()
end

function idlerdebug.pushChangingCallStack(o)
	table.insert(changingstack, o)
	local last = getIdlerCallTrace()
	lastset[o] = last
	if debuglastset or lastsetdebug[o] then
		local prefix = lastsetdebug[o]
		if type(prefix) ~= "string" then
			prefix = nil
		end
		printIdlerLastChanged(o, prefix)
		if debuglastsettrace then
			print(debug.traceback())
		end
	end
end

function idlerdebug.popChangingCallStack(o)
	local n = #changingstack
	if o ~= changingstack[n] then
		print("stack top:", tostring(changingstack[n]))
		print("now pop:", tostring(o))
		error("pop unmatch idler")
	end
	table.remove(changingstack)
end

function idlerdebug.errorChangingCallStack(o)
	for i, obj in ipairs(changingstack) do
		printIdlerLastChanged(obj, i)
	end
	changingstack = {}
end

function idlerdebug.addBindIdler(node, idlerName)
	nodebind[node] = idlerName
end


-- debug only
local enable = device.platform == "windows"
printInfo('idlerdebug ' .. (enable and "enable" or "disable"))
if not enable then
	local function null_func() end
	for k, v in pairs(idlerdebug) do
		idlerdebug[k] = null_func
	end
end
