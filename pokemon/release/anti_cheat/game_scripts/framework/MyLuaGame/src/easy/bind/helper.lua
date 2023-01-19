--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- bind辅助函数
--

local insert = table.insert

--------------------------------
-- helper为bind内部使用
local helper = {}

-- @return partial(method, view, node)
function helper.method(view, node, b, name, raw)
	local f
	if b.methods then
		local fOrName = b.methods[name]
		if fOrName == nil then return end

		if isCallable(fOrName) then
			f = fOrName
		else
			f = view[fOrName]
		end
	else
		if isCallable(b.method) then
			f = b.method
		else
			f = view[b.method]
		end
	end

	if f then
		return raw and f or functools.partial(f, view, node)
	end
end

-- bind内部listen转换封装
function helper.listen(view, node, b, method)
	local f = helper.method(view, node, b, nil, true)
	local idler = b.idler
	if idler then
		-- 有b.method是对idler结果做处理
		if f then
			bind.listen(view, node, {idler=idler, method=function(view, node, val, ...)
				return method(view, node, f(val), ...)
			end})
		else
			bind.listen(view, node, {idler=idler, method=method})
		end
	end
end

function helper.isHelper(t)
	return type(t) == "table" and t.__bindHelper == true
end

helper.isIdler = isIdler
helper.isIdlers = isIdlers

function helper.propVal(prop)
	if type(prop) ~= "table" then
		return prop
	elseif helper.isIdler(prop) then
		return prop()
	end
	return prop
end

-- unfold the bindHelper wrap
local function arrayHelperUnfold(view, node, t)
	if t == nil then return nil end
	if #t == 0 then return t end
	local ret = {}
	for i, v in ipairs(t) do
		if helper.isHelper(v) then
			v = v(view, node)
		end
		insert(ret, v)
	end
	return ret
end

local function mapHelperUnfold(view, node, t)
	if t == nil then return nil end
	if itertools.isempty(t) then return t end
	local ret = {}
	for k, v in pairs(t) do
		if helper.isHelper(v) then
			v = v(view, node)
		end
		ret[k] = v
	end
	return ret
end

local function mapHelperHandlerBound(view, node, t)
	if t == nil then return nil end
	if itertools.isempty(t) then return t end
	local ret = {}
	for k, v in pairs(t) do
		-- if type(v) == "function" or helper.isHelper(v) then
		-- 	-- bound view
		-- 	v = functools.partial(v, view, node)
		if helper.isHelper(v) then
			v = v:handler(view, node)
		else
			error(string.format("handler not bindHelper, %s=%s", k, tostring(v)))
		end
		ret[k] = v
	end
	return ret
end

-- 转换作为args参数的bindHelper
function helper.args(view, node, args)
	return unpack(arrayHelperUnfold(args))
end

-- props属性为变量的值
helper.props = mapHelperUnfold
-- handlers行为是createHandler创建的
helper.handlers = mapHelperHandlerBound

-- @return: data, idler, idlers
function helper.dataOrIdler(t)
	if helper.isIdlers(t) then
		return nil, nil, t
	elseif helper.isIdler(t) then
		return nil, t
	end
	return t
end

-- @param idler: 如果是isHelper，则为惰性求值器，否则直接设置对应的f
-- @param f: 对idler触发时进行数据处理
function helper.bindData(view, node, b, f)
	local protectedf = f
	if dev.DEBUG_MODE then
		local viewStr, nodeStr = tostring(view), tostring(node)
		local bindTrace = debug.traceback()
		protectedf = function(node, data)
			xpcall(function()
				return f(node, data)
			end, function(msg)
				__G__TRACKBACK__(msg)
				print("err in bindData:", tostring(view), tostring(node), tostring(data))
				sendExceptionInMobile('[string "bind.helper"]:150:err in bindData:\n\nstack traceback:\n'..viewStr..'\n'..nodeStr..'\n'..dumps(b)..'\n'..bindTrace)
			end)
		end
	end

	-- b.data can set false
	if b.data ~= nil then
		if helper.isHelper(b.data) then
			view:deferUntilCreated(function()
				local func = helper.method(view, node, b, nil, true)
				if func then
					protectedf(node, func(b.data(view)))
				else
					protectedf(node, b.data(view))
				end
			end)
		else
			local func = helper.method(view, node, b, nil, true)
			if func then
				protectedf(node, func(b.data))
			else
				protectedf(node, b.data)
			end
		end

	elseif b.idler then
		helper.listen(view, node, b, function(view, node, val)
			protectedf(node, val)
		end)
	end
end

-- @desc listview, tableview, pageview 数据转换处理
-- @param data: table or function
function helper.extendDataIter(data, size, pos)
	local left, right = pos, pos
	local function kv(k, cnt)
		if type(data) == "function" then return data(k, cnt) end
		local v = data[k]
		return k, v
	end
	local cnt = -1
	return function ()
		cnt = cnt + 1
		if cnt >= size then return end
		left = left - cnt % 2
		right = right + (cnt+1) % 2
		if 1 <= left and right <= size then
			return kv(cnt % 2 == 0 and left or right, cnt)
		end
		if left < 1 then
			return kv(right - left, cnt)
		end
		if size < right then
			return kv(left - (right-size-1), cnt)
		end
	end
end

function helper.callOrWhen(data, f, view, key)
	if data == nil then
		return
	end
	if helper.isHelper(data) then
		data = data(view)
	end
	if helper.isIdler(data) then
		local t = idlereasy.when(data, function (_, val)
			f(val)
		end)
		if view then
			t:anonyOnly(view, key)
		end
	else
		f(data)
	end
end

--------------------------------
-- bind时候view和node都没有创建
-- bindHelper就是为了再创建onCreate后进行延迟绑定的
-- bindHelper为应用上层使用

local bindHelper = {}
globals.bindHelper = bindHelper

local function bindHelperToString(t)
	local first = t.__id or t.__name
	local second
	if t.__id then
		second = t.__name
	end
	return string.format("%s(%s%s%s)", t.__raw and "bindraw" or "bind", t.__method, first and ("." .. first) or "", second and ("." .. second) or "")
end

--
-- bindHelper.parent
-- @param raw: 是否原值返回，针对function
--
local parentMeta = {
	__call = function(t, view, node, ...)
		local parent = view.parent_
		local val = parent[t.__name]
		if val == nil then
			printWarn("%s is nil, self is %s, parent is %s", tostring(t), tostring(view), tostring(parent))
		end
		if isCallable(val) then
			if t.__raw then
				return parent:createHandler(t.__name, node)
			else
				-- 如果是函数，则先运行获取返回值
				return val(parent, node, ...)
			end
		end
		-- 延迟获取self的变量
		return val
	end,
	handler = function(t, view, node)
		return view:createHandler(t.__name, node)
	end,
	__tostring = bindHelperToString,
}
parentMeta.__index = parentMeta
function bindHelper.parent(methodOrVar, raw)
	return setmetatable({__bindHelper = true, __method = "parent", __name = methodOrVar, __raw = raw}, parentMeta)
end

--
-- bindHelper.self
-- @param raw: 是否原值返回，针对function
--
local selfMeta = {
	__call = function(t, view, node, ...)
		local val = view[t.__name]
		if val == nil then
			printWarn("%s is nil, self is %s", tostring(t), tostring(view))
		end
		if isCallable(val) then
			if t.__raw then
				return view:createHandler(t.__name, node)
			else
				-- 如果是函数，则先运行获取返回值
				return val(view, node, ...)
			end
		end
		-- 延迟获取self的变量
		return val
	end,
	handler = function(t, view, node)
		return view:createHandler(t.__name, node)
	end,
	__tostring = bindHelperToString,
}
selfMeta.__index = selfMeta
function bindHelper.self(methodOrVar, raw)
	return setmetatable({__bindHelper = true, __method = "self", __name = methodOrVar, __raw = raw}, selfMeta)
end

--
-- bindHelper.model
-- @param model: string, model名字
--
local modelMeta = {
	__call = function(t, view, ...)
		local model = gGameModel[t.__method]
		return model:getIdler(t.__id, t.__name)
	end,
	__tostring = bindHelperToString,
}
function bindHelper.model(model, ...)
	local id, name = ...
	return setmetatable({__bindHelper = true, __method = model, __id = id, __name = name}, modelMeta)
end

--
-- bindHelper.defer
--
local deferMeta = {__call = function(t, view, ...)
	return t.__f(view, ...)
end, __tostring = bindHelperToString}
function bindHelper.defer(f, ...)
	return setmetatable({__bindHelper = true, __method = "defer", __f = f}, deferMeta)
end

return helper
