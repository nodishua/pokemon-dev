--[[

Copyright (c) 2014-2017 Chukong Technologies Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

lua_type = type
lua_tostring = tostring
lua_pairs = pairs
lua_ipairs = ipairs
lua_next = next
lua_print = print

tj = {}

CONSOLE_COLOR = {
	Dark_black 			= 0,
	Dark_Blue 			= 1,
	Dark_Green 			= 2,
	Dark_Blue_Green 	= 3,
	Dark_Red 			= 4,
	Dark_Purple 		= 5,
	Dark_Yellow 		= 6,
	Default 			= 7,
	Light_Black 		= 8,
	Light_Blue 			= 9,
	Light_Green 		= 10,
	Light_Blue_Green 	= 11,
	Light_Red 			= 12,
	Light_Purple 		= 13,
	Light_Yellow 		= 14,
	Light_White 		= 15,
}

local lua_type = type
local lua_tostring = tostring
local lua_pairs = pairs
local lua_ipairs = ipairs
local format = string.format
local strsub = string.sub
local tonumber = tonumber
local tolua_type = tolua and tolua.type or lua_type
local tolua_getpeer = tolua and tolua.getpeer

function printLog(tag, fmt, ...)
	local t = {
		"[",
		string.upper(lua_tostring(tag)),
		"] ",
		format(lua_tostring(fmt), ...)
	}
	print(table.concat(t))
end

function printError(fmt, ...)
	setLogColor(CONSOLE_COLOR.Light_Red)
	printLog("ERR", fmt, ...)
	print(debug.traceback("", 2))
	setLogColor(CONSOLE_COLOR.Default)
end

function printWarn(fmt, ...)
	if DEBUG < 1 then return end
	setLogColor(CONSOLE_COLOR.Light_Yellow)
	printLog("WARN", fmt, ...)
	setLogColor(CONSOLE_COLOR.Default)
end

function printWarnStack(fmt, ...)
	if DEBUG < 1 then return end
	setLogColor(CONSOLE_COLOR.Light_Yellow)
	printLog("WARN", fmt, ...)
	print(debug.traceback("", 2))
	setLogColor(CONSOLE_COLOR.Default)
end

function printInfo(fmt, ...)
	if DEBUG < 1 then return end
	setLogColor(CONSOLE_COLOR.Light_Green)
	printLog("INFO", fmt, ...)
	setLogColor(CONSOLE_COLOR.Default)
end

function printDebug(fmt, ...)
	if DEBUG < 2 then return end
	setLogColor(CONSOLE_COLOR.Light_Blue_Green)
	printLog("DBG", fmt, ...)
	setLogColor(CONSOLE_COLOR.Default)
end

function setLogColor(nColor)
	if not display or not device or device.platform ~= "windows"then
		return
	end
	display.director:setLogColor(nColor)
end

local function dump_value_(v, quot)
	if lua_type(v) == "string" then
		quot = quot or true
		if quot then
			v = "\"" .. v .. "\""
		end
	end
	return lua_tostring(v)
end

function dump(value, description, nesting)
	if lua_type(nesting) ~= "number" then nesting = 3 end

	local lookupTable = {}
	local result = {}

	local traceback = string.split(debug.traceback("", 2), "\n")
	print("dump from: " .. string.trim(traceback[3]))

	local function dump_(value, description, indent, nest, keylen)
		description = description or "<var>"
		local spc = ""
		if lua_type(keylen) == "number" then
			spc = string.rep(" ", keylen - string.len(dump_value_(description)))
		end
		if lua_type(value) ~= "table" then
			result[#result +1 ] = format("%s%s%s = %s", indent, dump_value_(description), spc, dump_value_(value))
		elseif lookupTable[lua_tostring(value)] then
			result[#result +1 ] = format("%s%s%s = *REF*", indent, dump_value_(description), spc)
		else
			lookupTable[lua_tostring(value)] = true
			if nest > nesting then
				result[#result +1 ] = format("%s%s = *MAX NESTING*", indent, dump_value_(description))
			else
				result[#result +1 ] = format("%s%s = {", indent, dump_value_(description))
				local indent2 = indent.."    "
				local keys = {}
				local keylen = 0
				local values = {}
				for k, v in pairs(value) do
					keys[#keys + 1] = k
					local vk = dump_value_(k, false)
					local vkl = string.len(vk)
					if vkl > keylen then keylen = vkl end
					values[k] = v
				end
				table.sort(keys, function(a, b)
					if lua_type(a) == "number" and lua_type(b) == "number" then
						return a < b
					else
						return lua_tostring(a) < lua_tostring(b)
					end
				end)
				for i, k in ipairs(keys) do
					dump_(values[k], k, indent2, nest + 1, keylen)
				end
				result[#result +1] = format("%s}", indent)
			end
		end
	end
	dump_(value, description, "- ", 1)

	for i, line in ipairs(result) do
		print(line)
	end
end

function printf(fmt, ...)
	print(format(lua_tostring(fmt), ...))
end

function checknumber(value, base)
	return tonumber(value, base) or 0
end

function checkint(value)
	return math.round(checknumber(value))
end

function checkbool(value)
	return (value ~= nil and value ~= false)
end

function checktable(value)
	if lua_type(value) ~= "table" then value = {} end
	return value
end

function isset(hashtable, key)
	local t = lua_type(hashtable)
	return (t == "table" or t == "userdata") and hashtable[key] ~= nil
end

local setmetatableindex_
setmetatableindex_ = function(t, index)
	if lua_type(t) == "userdata" then
		local peer = tolua.getpeer(t)
		if not peer then
			peer = {}
			tolua.setpeer(t, peer)
		end
		setmetatableindex_(peer, index)
	else
		local mt = getmetatable(t)
		if not mt then
			-- if mt is nil, and index is table
			-- mt(t) = index ~ mt(t).__index = index
			if lua_type(index) == "table" and rawget(index, "__index") == index then
				setmetatable(t, index)
				return
			end
			mt = {}
		end
		-- mt will be DIRTY!!!
		if not mt.__index then
			mt.__index = index
			setmetatable(t, mt)
		elseif mt.__index ~= index then
			setmetatableindex_(mt, index)
		end
	end
end
setmetatableindex = setmetatableindex_

function clone(object)
	local lookup_table = {}
	local function _copy(object)
		if lua_type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local newObject = {}
		lookup_table[object] = newObject
		for key, value in pairs(object) do
			newObject[_copy(key)] = _copy(value)
		end
		return setmetatable(newObject, getmetatable(object))
	end
	return _copy(object)
end

-- pairs
local objInternalFields = {
	__cid = true,
	__class = true,
	__tostring = true,
}
local function pairs_func(t)
	-- return lua_pairs(t)
	return function (t, idx)
		local nk, nv = next(t, idx)
		while nk and objInternalFields[nk] do
			nk, nv = next(t, nk)
		end
		return nk, nv
	end, t, nil
end

-- rawset
local function rawset_func(t, k, v)
	rawset(t, k, v)
end

-- rawget
local function rawget_func(t, k, v)
	return rawget(t, k)
end

local function tostring_func(t)
	return format("%s: 0x%08X", type(t), t.__cid)
end

function class(classname, ...)
	local cls = {
		__cname = classname,
		-- __tostring = tostring_func,
		-- pairs = pairs_func,
		-- rawset = rawset_func,
		-- rawget = rawget_func,
	}

	local supers = {...}
	for _, super in ipairs(supers) do
		local superType = lua_type(super)
		assert(superType == "nil" or superType == "table" or superType == "function",
			format("class() - create class \"%s\" with invalid super class type \"%s\"",
				classname, superType))

		if superType == "function" then
			assert(cls.__create == nil,
				format("class() - create class \"%s\" with more than one creating function",
					classname));
			-- if super is function, set it to __create
			cls.__create = super
		elseif superType == "table" then
			if super[".isclass"] then
				-- super is native class
				assert(cls.__create == nil,
					format("class() - create class \"%s\" with more than one creating function or native class",
						classname));
				cls.__create = function() return super:create() end
			else
				-- super is pure lua class
				cls.__supers = cls.__supers or {}
				cls.__supers[#cls.__supers + 1] = super
				if not cls.__super then
					-- set first super pure lua class as class.super
					cls.__super = super
				end
			end
		else
			error(format("class() - create class \"%s\" with invalid super type",
						classname), 0)
		end
	end

	cls.__index = cls
	if not cls.__supers or #cls.__supers == 1 then
		setmetatable(cls, {__index = cls.__super})
	else
		printWarn("dont use multiple supers !")
		setmetatable(cls, {__index = function(_, key)
			local supers = cls.__supers
			for i = 1, #supers do
				local super = supers[i]
				if super[key] then return super[key] end
			end
		end})
	end

	-- -- like c++ constructor
	-- if not cls.ctor then
	-- 	-- add default constructor
	-- 	cls.ctor = function(...)
	-- 		if cls.__super then
	-- 			return cls.__super.ctor(...)
	-- 		end
	-- 	end
	-- end
	cls.new = function(...)
		local instance
		if cls.__create then
			-- create when superType is function or [.isclass]
			instance = cls.__create(...)
		else
			instance = {}
		end
		local ty = lua_type(instance)
		instance.__cid = tonumber(strsub(lua_tostring(instance), #ty+2), 16)
		instance.__class = cls
		setmetatableindex_(instance, cls)
		-- no super.ctor like python __init__
		local ctor = instance.ctor
		if ctor then
			ctor(instance, ...)
		end
		-- do
		-- 	-- create like c++ constructor
		-- 	local create
		-- 	create = function(c, ...)
		-- 		if rawget(c, "__super") then
		-- 			create(c.__super, ...)
		-- 		end
		-- 		if rawget(c, "ctor") then
		-- 			c.ctor(instance, ...)
		-- 		end
		-- 	end
		-- 	create(cls, ...)
		-- end
		return instance
	end
	-- like native's create export function
	cls.create = function(_, ...)
		return cls.new(...)
	end

	return cls
end

local iskindof_
iskindof_ = function(cls, name)
	local __index = rawget(cls, "__index")
	if type(__index) == "table" and rawget(__index, "__cname") == name then return true end
	if type(__index) ~= "table" then return false end -- readOnlyProxy, __index is function

	if rawget(cls, "__cname") == name then return true end
	local __supers = rawget(__index, "__supers")
	if not __supers then return false end
	for _, super in ipairs(__supers) do
		if iskindof_(super, name) then return true end
	end
	return false
end

function iskindof(obj, classname)
	local t = type(obj)
	if t ~= "table" and t ~= "userdata" then return false end

	local mt
	if t == "userdata" then
		if tolua.iskindof(obj, classname) then return true end
		mt = getmetatable(tolua.getpeer(obj))
	else
		mt = getmetatable(obj)
	end
	if mt then
		return iskindof_(mt, classname)
	end
	return false
end

-- NOT NECESSARY!!!
-- support relative path require
local function import(moduleName, currentModuleName)
	local currentModuleNameParts
	local moduleFullName = moduleName
	local offset = 1

	while true do
		if string.byte(moduleName, offset) ~= 46 then -- .
			moduleFullName = string.sub(moduleName, offset)
			if currentModuleNameParts and #currentModuleNameParts > 0 then
				moduleFullName = table.concat(currentModuleNameParts, ".") .. "." .. moduleFullName
			end
			break
		end
		offset = offset + 1

		if not currentModuleNameParts then
			if not currentModuleName then
				local n,v = debug.getlocal(3, 1)
				currentModuleName = v
			end

			currentModuleNameParts = string.split(currentModuleName, ".")
		end
		table.remove(currentModuleNameParts, #currentModuleNameParts)
	end

	return require(moduleFullName)
end

function handler(obj, method)
	if type(method) == "string" then
		method = obj[method]
	end
	return function(...)
		return method(obj, ...)
	end
end

function math.newrandomseed()
	local ok, socket = pcall(function()
		return require("socket")
	end)

	math.randomseed(os.time())
	if ok then
		math.randomseed(socket.gettime() * 1000 + math.random())
	else
		math.randomseed(os.time() + math.random())
	end
	math.random()
	math.random()
	math.random()
	math.random()
end

function math.round(value)
	value = checknumber(value)
	return math.floor(value + 0.5)
end

local pi_div_180 = math.pi / 180
function math.angle2radian(angle)
	return angle * pi_div_180
end

function math.radian2angle(radian)
	return radian * 180 / math.pi
end

function io.exists(path)
	local file = io.open(path, "r")
	if file then
		io.close(file)
		return true
	end
	return false
end

function io.readfile(path)
	local file = io.open(path, "r")
	if file then
		local content = file:read("*a")
		io.close(file)
		return content
	end
	return nil
end

function io.writefile(path, content, mode)
	mode = mode or "w+b"
	local file = io.open(path, mode)
	if file then
		if file:write(content) == nil then return false end
		io.close(file)
		return true
	else
		return false
	end
end

function io.pathinfo(path)
	local pos = string.len(path)
	local extpos = pos + 1
	while pos > 0 do
		local b = string.byte(path, pos)
		if b == 46 then -- 46 = char "."
			extpos = pos
		elseif b == 47 then -- 47 = char "/"
			break
		end
		pos = pos - 1
	end

	local dirname = string.sub(path, 1, pos)
	local filename = string.sub(path, pos + 1)
	extpos = extpos - pos
	local basename = string.sub(filename, 1, extpos - 1)
	local extname = string.sub(filename, extpos)
	return {
		dirname = dirname,
		filename = filename,
		basename = basename,
		extname = extname
	}
end

function io.filesize(path)
	local size = false
	local file = io.open(path, "r")
	if file then
		local current = file:seek()
		size = file:seek("end")
		file:seek("set", current)
		io.close(file)
	end
	return size
end

-- map size
function table.nums(t)
	t = table.getraw(t)
	local count = 0
	for k, v in pairs(t) do
		count = count + 1
	end
	return count
end

function table.keys(hashtable)
	local i, keys = 1, {}
	for k, v in pairs(hashtable) do
		keys[i] = k
		i = i + 1
	end
	return keys
end

function table.values(hashtable)
	local i, values = 1, {}
	for k, v in pairs(hashtable) do
		values[i] = v
		i = i + 1
	end
	return values
end

function table.merge(dest, src)
	for k, v in pairs(src) do
		dest[k] = v
	end
end

function table.insertto(dest, src, begin)
	begin = checkint(begin)
	if begin <= 0 then
		begin = #dest + 1
	end

	local len = #src
	for i = 0, len - 1 do
		dest[i + begin] = src[i + 1]
	end
end

function table.indexof(array, value, begin)
	for i = begin or 1, table.length(array) do
		if array[i] == value then return i end
	end
	return false
end

function table.keyof(hashtable, value)
	for k, v in pairs(hashtable) do
		if v == value then return k end
	end
	return nil
end

function table.removebyvalue(array, value, removeall)
	local c, i, max = 0, 1, table.length(array)
	while i <= max do
		if array[i] == value then
			table.remove(array, i)
			c = c + 1
			i = i - 1
			max = max - 1
			if not removeall then break end
		end
		i = i + 1
	end
	return c
end

function table.map(t, fn)
	for k, v in pairs(t) do
		t[k] = fn(v, k)
	end
end

function table.walk(t, fn)
	for k,v in pairs(t) do
		fn(v, k)
	end
end

function table.filter(t, fn)
	for k, v in pairs(t) do
		if not fn(v, k) then t[k] = nil end
	end
end

function table.unique(t, bArray)
	local check = {}
	local n = {}
	local idx = 1
	for k, v in pairs(t) do
		if not check[v] then
			if bArray then
				n[idx] = v
				idx = idx + 1
			else
				n[k] = v
			end
			check[v] = true
		end
	end
	return n
end

string._htmlspecialchars_set = {}
string._htmlspecialchars_set["&"] = "&amp;"
string._htmlspecialchars_set["\""] = "&quot;"
string._htmlspecialchars_set["'"] = "&#039;"
string._htmlspecialchars_set["<"] = "&lt;"
string._htmlspecialchars_set[">"] = "&gt;"

function string.htmlspecialchars(input)
	for k, v in pairs(string._htmlspecialchars_set) do
		input = string.gsub(input, k, v)
	end
	return input
end

function string.restorehtmlspecialchars(input)
	for k, v in pairs(string._htmlspecialchars_set) do
		input = string.gsub(input, v, k)
	end
	return input
end

function string.nl2br(input)
	return string.gsub(input, "\n", "<br />")
end

function string.text2html(input)
	input = string.gsub(input, "\t", "    ")
	input = string.htmlspecialchars(input)
	input = string.gsub(input, " ", "&nbsp;")
	input = string.nl2br(input)
	return input
end

function string.split(input, delimiter)
	input = lua_tostring(input)
	delimiter = lua_tostring(delimiter)
	if (delimiter=='') then return false end
	local pos,arr = 0, {}
	-- for each divider found
	for st,sp in function() return string.find(input, delimiter, pos, true) end do
		table.insert(arr, string.sub(input, pos, st - 1))
		pos = sp + 1
	end
	table.insert(arr, string.sub(input, pos))
	return arr
end

function string.ltrim(input)
	return string.gsub(input, "^[ \t\n\r]+", "")
end

function string.rtrim(input)
	return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.trim(input)
	input = string.gsub(input, "^[ \t\n\r]+", "")
	return string.gsub(input, "[ \t\n\r]+$", "")
end

-- 首字母大写
function string.ucfirst(input)
	return string.upper(string.sub(input, 1, 1)) .. string.sub(input, 2)
end
string.caption = string.ucfirst

local function urlencodechar(char)
	return "%" .. format("%02X", string.byte(char))
end
function string.urlencode(input)
	-- convert line endings
	input = string.gsub(lua_tostring(input), "\n", "\r\n")
	-- escape all characters but alphanumeric, '.' and '-'
	input = string.gsub(input, "([^%w%.%- ])", urlencodechar)
	-- convert spaces to "+" symbols
	return string.gsub(input, " ", "+")
end

function string.urldecode(input)
	input = string.gsub (input, "+", " ")
	input = string.gsub (input, "%%(%x%x)", function(h) return string.char(checknumber(h,16)) end)
	input = string.gsub (input, "\r\n", "\n")
	return input
end

function string.utf8len(input)
	local len  = string.len(input)
	local left = len
	local cnt  = 0
	local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
	while left > 0 do
		local tmp = string.byte(input, -left)
		local i   = #arr
		while arr[i] do
			if tmp >= arr[i] then
				left = left - i
				break
			end
			i = i - 1
		end
		cnt = cnt + 1
	end
	return cnt, left
end

function string.utf8charlen(char)
	if not char then
		return 0
	elseif char >= 240 then
		return 4
	elseif char >= 224 then
		return 3
	elseif char >= 192 then
		return 2
	else
		return 1
	end
end

-- 123123.44 -> "123,123.44"
function string.formatnumberthousands(num)
	local formatted = lua_tostring(checknumber(num))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return formatted
end

function string.findlastof(s, ch)
	local pos, i = 0, 0
	while true do
		i = string.find(s, ch, i+1)
		if i == nil then break end
		pos = i
	end
	return pos
end

------------------------------
-- override system functions

function tostring(t)
	-- local ok, ret = pcall(function()
		local ty = lua_type(t)
		local tty
		if ty == "userdata" then
			tty = tolua_type(t)
			if tty == "userdata" then
				return lua_tostring(t)
			end
		end

		if ty == "table" or ty == "userdata" then
		-- print(lua_tostring(t), ty, tolua.type(t), tolua.getpeer(t))
			if t.__tostring then
				return lua_tostring(t:__tostring())
			elseif t.__class and t.__cid then
				return format("%s: 0x%x", t.__class.__cname, t.__cid)
			elseif tty then
				return format("%s%s", tty, lua_tostring(t):sub(9))
			elseif t.__cname then
				-- return format("class %s", t.__cname)
				return t.__cname
			end
		end
		return lua_tostring(t)
	-- end)
	-- return ok and ret or lua_tostring(t)
end

-- for table.proxytable
function pairs(t)
	local mt = getmetatable(t)
	if mt and mt.__pairs then
		return mt.__pairs(t)
	end
	return lua_pairs(t)
end

-- for table.proxytable
function ipairs(t)
	local mt = getmetatable(t)
	if mt and mt.__ipairs then
		return mt.__ipairs(t)
	end
	return lua_ipairs(t)
end

-- for table.proxytable
function next(t, k)
	local mt = getmetatable(t)
	if mt and mt.__next then
		return mt.__next(t, k)
	end
	return lua_next(t, k)
end

function tj.type(t)
	local ty = lua_type(t)
	if ty == "table" or ty == "userdata" then
		if t.__class then return t.__class.__cname end
		-- elseif t.__cname then return _strfmt("meta-%s", t.__cname) end
	end
	return tolua_type(t)
end

------------------------------
-- extend function

function super(instance)
	return instance.__class.__super
end

function isCCObject(obj)
	return obj.getReferenceCount ~= nil
end

function isRef(obj)
	local otype = lua_type(obj)
	if otype ~= "table" and otype ~= "userdata" then return false end
	return (obj.release ~= nil) or isCCObject(obj)
end

function isObject(obj)
	return (rawget(obj, "__cid") and rawget(obj, "__class")) ~= nil
end

function isClass(cls)
	return rawget(cls, "__cname") ~= nil
end

function isCallable(obj)
	local otype = lua_type(obj)
	if otype == "function" then return true end
	if otype == "table" then
		local mt = getmetatable(obj)
		return (mt and mt.__call) ~= nil
	end
	return false
end