--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--

local tjdebug = {}
globals.tjdebug = tjdebug

local callPatterns, excludeCallPatterns = {}, {}
local filePatterns, excludeFilePatterns = {}, {}
local enable = false

local function exclude(s, patterns)
	for _, p in ipairs(patterns) do
		if s:match(p) then
			return false
		end
	end
	return true
end

local function filter(s, patterns, excludePatterns)
	if next(patterns) then
		for _, p in ipairs(patterns) do
			if s:match(p) then
				return exclude(s, excludePatterns)
			end
		end
		return false
	end

	return exclude(s, excludePatterns)
end

function tjdebug.enable()
	if enable then return end
	enable = true

	debug.sethook(function(typ, ...)
		local info = debug.getinfo(2)
		if filter(info.source, filePatterns, excludeFilePatterns) then
			if info.name and (typ == "call" or typ == "return") then
				if not filter(info.name, callPatterns, excludeCallPatterns) then return end
				local source = info.source
				if typ == "call" then
					local params, ups = {}, {}
					for i = 1, info.nparams do
						local k, v = debug.getlocal(2, i)
						table.insert(params, string.format("%s=%s", lua_tostring(k), lua_tostring(v)))
					end
					for i = 1, info.nups do
						local k, v = debug.getupvalue(info.func, 1, i)
						table.insert(ups, string.format("%s=%s", lua_tostring(k), lua_tostring(v)))
					end
					print("[HOOK]", typ, ":", string.format("%s(%s)", info.name, table.concat(params, ", ")), table.concat(ups, ", "), string.format("\t%s:%d", source, info.currentline))
				else
					print("[HOOK]", typ, ":", info.name, string.format("\t%s:%d", source, info.currentline))
				end
			end
		end
	end, "crl")
end

function tjdebug.custom(mask, call)
	if enable then return end
	enable = true

	debug.sethook(function(typ, ...)
		local info = debug.getinfo(2)
		if filter(info.source, filePatterns, excludeFilePatterns) then
			if info.name and (typ == "call" or typ == "return") then
				if not filter(info.name, callPatterns, excludeCallPatterns) then return end
				local callInfo = {
					source = info.source,
					typ = typ,
				}
				if typ == "call" then
					callInfo.params = {}
					for i = 1, info.nparams do
						local k, v = debug.getlocal(2, i)
						callInfo.params[lua_tostring(k)] = v
					end
				end
				call(info.name, callInfo)
			end
		end
	end, mask)
end

function tjdebug.record()
	if enable then return end
	enable = true

	local cur = nil
	local st = {}

	local function nextrecord()
		local info = debug.getinfo(3, "nSl")
		cur = {
			src = info.source,
			startline = info.currentline,
			endline = info.currentline,
			func = info.name,
		}
	end
	local function output(flush)
		if cur == nil then return end
		local c = cur
		cur = nil
		if c.src == "=[C]" then return end

		local s
		if c.startline == c.endline then
			s = string.format("%s:%s:%d", c.src, c.func or "", c.startline)
		else
			s = string.format("%s:%s:%d-%d", c.src, c.func or "", c.startline, c.endline)
		end
		print('[HOOK RECORD]', s)
	end

	debug.sethook(function(typ, ...)
		if typ == "line" then
			local line = ...
			if cur and line > cur.endline then
				cur.endline = line
			end

		elseif typ == "call" then
			output()
			nextrecord()

		elseif typ == "return" then
			output()
		end
	end, "crl")
end

function tjdebug.isenable()
	return enable
end

function tjdebug.disable()
	if not enable then return end
	enable = false

	callPatterns = {}
	filePatterns = {}
	excludeCallPatterns = {}
	excludeFilePatterns = {}

	debug.sethook(nil)
end

function tjdebug.includeCall(pattern)
	table.insert(callPatterns, pattern)
end

function tjdebug.includeFile(pattern)
	table.insert(filePatterns, pattern)
end

function tjdebug.excludeCall(pattern)
	table.insert(excludeCallPatterns, pattern)
end

function tjdebug.excludeFile(pattern)
	table.insert(excludeFilePatterns, pattern)
end


function globals.toDebugString(obj)
	local tp = type(obj)
	if tp ~= "table" and tp ~= "userdata" then
		return tostring(obj)
	end
	if tj.type(obj) == "ViewProxy" then
		obj = obj:raw()
	end
	if obj.debugString then
		return obj:debugString()
	end
	return tostring(obj)
end

local null_data = {}
function globals.getCallTrace(level, filter)
	level = level or 1
	local tb
	repeat
		tb = debug.getinfo(level, "nSl")
		-- print_r(tb)
		if tb then
			if filter(tb) then
				return {
					src = tb.source,
					line = tb.currentline,
					func = tb.name,
					level = level,
					desc = string.format("%s:%s:%d %d", tb.source, tb.name or "", tb.currentline, level),
				}
				-- print_r(info)
			end
		end
		level = level + 1
	until not tb
	return null_data
end

local function getCodeLines(src, info)
	local startline = math.max(info.linedefined, info.currentline - 2)
	local endline = math.min(info.lastlinedefined, info.currentline + 2)

	local lines = string.split(src, "\n")
	for i = startline, endline do
		if #string.trim(lines[i]) == 0 then
			startline = i + 1
		else
			break
		end
	end
	for i = endline, startline, -1 do
		if #string.trim(lines[i]) == 0 then
			endline = i - 1
		else
			break
		end
	end
	for i = startline, endline do
		local prefix = "|   "
		if i == info.currentline then
			prefix = "|*  "
		end
		lines[i] = prefix .. lines[i]
	end
	return table.concat(lines, "\n", startline, endline)
end

function globals.tracebackWithCode()
	local guarder = require("util.guarder")
	for i = 3, 99 do
		local info = debug.getinfo(i, "nSl")
		if info == nil then break end
		if i % 2 == 1 then
			setLogColor(CONSOLE_COLOR.Light_Purple)
		else
			setLogColor(CONSOLE_COLOR.Light_Yellow)
		end

		-- print(dumps(info))
		release_print(string.format("%02d %s:%d: in '%s'", i, info.short_src, info.currentline, info.name or info.what))

		local src, path = ""
		if info.currentline ~= -1 then
			src, path = guarder.get_file_content(info.source)
		end
		if #src > 0 then
			-- release_print 有的会崩溃
			print("\n" .. getCodeLines(src, info))
		end
		release_print()
	end
end

--------------------------------
-- test
--------------------------------

-- require "util.debug"
-- tjdebug.includeFile("buff/buff.lua")
-- tjdebug.excludeCall("exist")
-- tjdebug.excludeCall("ctor")
-- tjdebug.excludeCall("init")
-- tjdebug.excludeCall("funcStr2Value")
-- tjdebug.enable()