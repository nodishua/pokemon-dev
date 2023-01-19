--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2018 TianJi Information Technology Inc.
--
-- idler easy
--

local type = type
local checkbool = checkbool
local insert = table.insert


--------------------------------

local idlerfilter = {}
globals.idlerfilter = idlerfilter

idlerfilter.size = {}

function idlerfilter.size.any(mark, changed, i, n)
	return true
end

function idlerfilter.size.select(select)
	return function(mark, changed, i, n)
		for idx, _ in pairs(select) do
			if not changed[idx] then
				return false
			end
		end
		return true
	end
end

idlerfilter.bool = {}

function idlerfilter.bool.all(mark, changed, i, n)
	if (not mark[i]) or n ~= itertools.size(mark) then return false end
	return itertools.all(mark, function(v)
		return checkbool(v)
	end)
end

function idlerfilter.bool.any(mark, changed, i, n)
	return checkbool(mark[i])
end


--------------------------------
local idlereasyArgs = {__idlereasyArgs=true}
globals.idlereasyArgs = idlereasyArgs
idlereasyArgs.__index = idlereasyArgs

local function isIdlereasyArgs(t)
	return type(t) == "table" and t.__idlereasyArgs == true
end
globals.isIdlereasyArgs = isIdlereasyArgs

function idlereasyArgs.new(obj, ...)
	local self = {array={}, map={}}
	local vargs = {...}
	for i, k in ipairs(vargs) do
		local v = obj[k]
		self.array[i] = v
		self.map[k] = v
		assert(v, "no such var "..k)
	end
	return setmetatable(self, idlereasyArgs)
end

function idlereasyArgs.newWithFunc(f, ...)
	local self = {array={}, map={}}
	local vargs = {...}
	for i, k in ipairs(vargs) do
		local v = f(i, k)
		self.array[i] = v
		self.map[k] = v
		assert(v, "no such var "..k)
	end
	return setmetatable(self, idlereasyArgs)
end

function idlereasyArgs:getArray_()
	local ret = {}
	for key, idler in ipairs(self.array) do
		ret[key] = idler:get_()
	end
	return ret
end

function idlereasyArgs:getMap_()
	local ret = {}
	for key, idler in pairs(self.map) do
		ret[key] = idler:get_()
	end
	return ret
end

--------------------------------

local idlereasy = {}
globals.idlereasy = idlereasy

function idlereasy.new(init, name)
	if type(init) == "table" then
		return idlertable.new(init, name)
	else
		return idler.new(init, name)
	end
end

-- when obj changed, call f
function idlereasy.when(obj, f, noInit)
	return idlercomputer.new(obj, f, noInit)
end

-- when any objs changed, call f
function idlereasy.any(objs, f)
	if isIdlereasyArgs(objs) then
		objs = objs.array
	end
	return idlercomputer.combine(idlerfilter.size.any, nil, f, objs)
end

-- when select(objs) changed, call f
function idlereasy.select(objs, selectObjs, f)
	if isIdlereasyArgs(objs) then
		objs = objs.array
	end
	local h = arraytools.hash(objs, true)
	local select = itertools.map(selectObjs, function(_, obj)
		return h[obj], true
	end)
	return idlercomputer.combine(idlerfilter.size.select(select), nil, f, objs)
end

-- when obj changed, if bool(obj) is true, call f
function idlereasy.if_(obj, f)
	return idlercomputer.new(obj, function(self, val)
		if checkbool(val) then
			return f(self, val)
		end
		return false
	end)
end

-- when obj changed, if bool(obj) is false, call f
function idlereasy.if_not(obj, f)
	return idlercomputer.new(obj, function(self, val)
		if not checkbool(val) then
			return f(self, val)
		end
		return false
	end)
end

-- when objs changed, if any(bool(obj)) is true, call f
function idlereasy.if_any(objs, f)
	if isIdlereasyArgs(objs) then
		objs = objs.array
	end
	return idlercomputer.combine(idlerfilter.bool.any, nil, f, objs)
end

-- when objs changed, if all(bool(obj)) is true, call f
function idlereasy.if_all(objs, f)
	if isIdlereasyArgs(objs) then
		objs = objs.array
	end
	return idlercomputer.combine(idlerfilter.bool.all, nil, f, objs)
end

-- if some idlercomputer be callback after view created finished
function idlereasy.view_defer(view, easyName, ...)
	local rawf, obj
	local tf = functools.tablefunc({created = false, args = false}, function(t, ...)
		if t.created then
			return rawf(...)
		else
			t.args = {...}
		end
	end)

	local easyf = idlereasy[easyName]
	if easyName == "any" then
		local objs, f = ...
		rawf = f
		obj = easyf(objs, tf)
	else
		error("view_defer no support for " .. easyName)
	end

	view:deferUntilCreated(function()
		local args = tf.args
		tf.created, tf.args = true, nil
		rawf(unpack(args))
	end)
	return obj
end

-- when all objs changed, call f
-- YOU CAN USE idlereasy.any, CHECK IT EVERYTIME WHEN CHANGED
-- function idlereasy.all(objs, f)
-- 	return idlercomputer.combine(idlerfilter.size.all, nil, f, objs)
-- end

-- new(idlercomputer) = idler
-- old(lhs) = rhs
function idlereasy.assign(rhs, lhs)
	-- new and assign
	if lhs == nil or lhs.tickets == nil then
		return idlercomputer.new(rhs, function(_, val)
			return true, val
		end)
	end

	-- assign with replace
	lhs:deafen()
	return idlercomputer.placeNew(lhs, rhs, function(_, val)
		return true, val
	end)
end

-- when you want get many idler value in one time
function idlereasy.do_(f, ...)
	local nargs = select("#", ...)
	local vargs = {...}
	for i, v in ipairs(vargs) do
		if isIdlereasyArgs(v) then
			vargs[i] = v:getMap_()
		else
			vargs[i] = v:get_()
		end
	end
	return f(unpack(vargs, 1, nargs))
end

function idlereasy.multiset(t, force)
	for k, v in pairs(t) do
		if isIdler(v) then
			k:set(v:get_(), force)
		else
			k:set(v, force)
		end
	end
end

--------------------------------

local idlerflow = {}
globals.idlerflow = idlerflow

local function idlerflow_new(t)
	return setmetatable(t, {__index = idlerflow})
end

-- 只适合[when|any|if_XXX]():do_
function idlerflow.when(obj)
	return idlerflow_new({predname="when", obj=obj})
end

function idlerflow.any(objs)
	return idlerflow_new({predname="any", obj=objs})
end

function idlerflow.if_(obj)
	return idlerflow_new({predname="if_", obj=obj})
end

function idlerflow.if_not(obj)
	return idlerflow_new({predname="if_not", obj=obj})
end

function idlerflow.do_(flow, f, ...)
	local pred = idlereasy[flow.predname]
	local nargs = select('#', ...)
	local vargs = {...}
	local vals = {...}
	return pred(flow.obj, function()
		for i, v in ipairs(vargs) do
			if isIdlereasyArgs(v) then
				vals[i] = v:getMap_()
			else
				vals[i] = v:get_()
			end
		end
		return f(unpack(vals, 1, nargs))
	end)
end