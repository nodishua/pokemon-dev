--[[

Copyright 2007 Jan Kneschke (jan@kneschke.de)

Licensed under the same license as Lua 5.1

$ lua lua-callgrind.lua <lua-script> [outputfile]

--]]
-- https://www.valgrind.org/docs/manual/cl-format.html

local tostring = lua_tostring or tostring
local pairs = lua_pairs or pairs
local ipairs = lua_ipairs or ipairs
local type = lua_type or type

local myself_filename = "lua%-callgrind.lua"
local cwd = io.popen("cd"):read()

local getTime = os.clock

if socket and socket.gettime then
	getTime = socket.gettime
end
if cc.utils and cc.utils.gettime then
	getTime = function()
		return cc.utils:getTimeInMilliseconds()
	end
end

local M = {}

local callstack = { }
local instr_count = 0
local last_line_instr_count = 0
local tracefile = nil

local functions = { }
local methods = { }
local method_id = 1
local call_indent = 0

local mainfunc = nil

local function luafilename(s)
	if s:find("%[string") then
		local path = s:sub(10, -3)
		return cwd .. "/" .. path
	end
	return s
end

local function getfuncname(f)
	return ("%s"):format(tostring(f.func))
end

local function ismyselffile(short_src)
	if short_src == "[C]" then return short_src end
	short_src = luafilename(short_src)
	local ignore = false
	if #short_src > #myself_filename then
		ignore = short_src:find(myself_filename)
	end
	return ignore, short_src
end

local function trace(class)
	-- print("calling tracer: "..class)
	if class == "count" then
		instr_count = instr_count + 1

	elseif class == "line" then
		-- check if we know this function already
		local f = debug.getinfo(2, "lSf")

		if not functions[f.func] then
			functions[f.func] = {
				meta = f,
				lines = {}, -- myself lines
				funcs = {},
				last_line = nil,
			}
		end
		local lines = functions[f.func].lines
		-- lines[#lines + 1] =("%d %d"):format(f.currentline, instr_count - last_line_instr_count)
		lines[f.currentline] = instr_count - last_line_instr_count + (lines[f.currentline] or 0)
		functions[f.func].last_line = f.currentline

		if not mainfunc then mainfunc = f.func end

		last_line_instr_count = instr_count 

	elseif class == "call" then
		-- add the function info to the stack
		--
		local f = debug.getinfo(2, "lSfn")
		local ignore, short_src = ismyselffile(f.short_src)

		callstack[#callstack + 1] = {
			short_src   = short_src,
			func        = f.func,
			linedefined = f.linedefined,
			name        = f.name,
			instr_count = instr_count,
			cpu_start   = getTime(),
			ignore      = ignore,
		}

		if not functions[f.func] then
			functions[f.func] = {
				meta = f,
				lines = {}, -- myself lines
				funcs = {},
				last_line = nil,
			}
		end

		if not functions[f.func].meta.name then
			functions[f.func].meta.name = f.name
		end

		-- is this method already known ?
		if f.name then
			methods[tostring(f.func)] = { name = f.name }
		end

		-- print((" "):rep(call_indent)..">>"..tostring(f.func).." (".. tostring(f.name)..")")
		call_indent = call_indent + 1
		-- call_time = getTime()

	elseif class == "return" then
		if #callstack > 0 then
			-- pop the function from the stack and
			-- add the instr-count to the its caller
			local ret = table.remove(callstack)

			local f = debug.getinfo(2, "lSfn")
			-- if lua wants to return from a pcall() after a assert(),
			-- error() or runtime-error we have to cleanup our stack
			if ret.func ~= f.func then
				-- print("handling error()")
				-- the error() is already removed
				-- removed every thing up to pcall()
				while #callstack > 1 and callstack[#callstack].func ~= f.func do
					table.remove(callstack)

					call_indent = call_indent - 1
				end
				-- remove the pcall() too
				ret = table.remove(callstack)
				call_indent = call_indent - 1
			end

			local prev
			if #callstack > 0 then
				prev = callstack[#callstack].func
			else
				prev = mainfunc
			end

			local prev_info = functions[prev]
			local lines = prev_info.lines
			local funcs = prev_info.funcs
			local last_line = prev_info.last_line

			call_indent = call_indent - 1

			if not ret.ignore then
				-- in case the assert below fails, enable this print and the one in the "call" handling
				-- print((" "):rep(call_indent).."<<"..tostring(ret.name).." "..tostring(f.name).. " =? " .. tostring(f.func == ret.func))
				assert(ret.func == f.func)

				local key = string.format("%s:%s", ret.short_src, ret.linedefined)
				if funcs[key] == nil then
					funcs[key] = {
						cfl = ("cfl=%s"):format(ret.short_src),
						cfn = ("cfn=%s"):format(tostring(ret.func)),
						ncalls = 1,
						linedefined = ret.linedefined,
						instrs = {},
						cycles = {},
					}
				end
				local cf_info = funcs[key]

				local costms = getTime() - ret.cpu_start
				-- print('cpu_start', tostring(ret.func), ret.name, ret.cpu_start, costms)

				local lno = last_line and last_line or -1
				cf_info.instrs[lno] = instr_count - ret.instr_count + (cf_info.instrs[lno] or 0)
				cf_info.cycles[lno] = costms + (cf_info.cycles[lno] or 0)

				-- lines[#lines + 1] = ("cfl=%s"):format(ret.short_src)
				-- lines[#lines + 1] = ("cfn=%s"):format(tostring(ret.func))
				-- lines[#lines + 1] = ("calls=1 %d"):format(ret.linedefined); ret.parent_lines_index = #lines
				-- lines[#lines + 1] = ("%d %d %f"):format(last_line and last_line or -1, instr_count - ret.instr_count, costms)
			end
		end
		-- tracefile:write("# --callstack: " .. #callstack .. "\n")
	else
		-- print("class = " .. class)
	end
end

-- local main = assert(loadfile(arg[1]))
-- debug.sethook(trace, "crl", 1)
-- main()
-- debug.sethook()

-- try to build a reverse mapping of all functions pointers
-- string.sub() should not just be sub(), but the full name
--
-- scan all tables in _G for functions

local function func2name(m, tbl, prefix)
	prefix = prefix and prefix .. "." or ""

	-- print(prefix)

	for name, func in pairs(tbl) do
		if func == _G then
			-- ignore
		elseif m[tostring(func)] and type(m[tostring(func)]) == "table" and m[tostring(func)].id then
			-- already mapped
		elseif type(func) == "function" then
			-- remove the package.loaded. prefix from the loaded methods
			local key = prefix..tostring(name)
			m[tostring(func)] = { name = key:gsub("^package\\.loaded\\.", ""), id = method_id }
			method_id = method_id + 1
		elseif type(func) == "table" and type(name) == "string" then
			-- a package, class, ...
			--
			-- make sure we don't look endlessly
			if m[tostring(func)] ~= "*stop*" then
				m[tostring(func)] = "*stop*"
				func2name(m, func, prefix..name)
			end
		end
	end
end


function M.start(name)
	-- init
	callstack = { }
	instr_count = 0
	last_line_instr_count = 0
	tracefile = nil

	functions = { }
	methods = { }
	method_id = 1
	call_indent = 0

	-- tracefile = io.open(arg[2] or "callgrind.txt", "w+")
	tracefile = io.open(string.format("callgrind.%s.txt", name or ""), "w+")
	-- tracefile:write("events: Instructions\n")
	tracefile:write("events: Instructions Cycles\n")

	-- local main = assert(loadfile(arg[1]))
	debug.sethook(trace, "crl", 1)
	-- main()
	-- debug.sethook()

	func2name(methods, _G)
end

function M.stop()
	debug.sethook()

	-- resolve the function pointers
	func2name(methods, _G)

	for key, func in pairs(functions) do
		local f = func.meta

		if (not f.name) and f.linedefined == 0 then
			f.name = "(test-wrapper)"
		end

		local func_name = getfuncname(f)
		if methods[tostring(f.func)] then
			func_name = methods[tostring(f.func)].name
		end

		-- fl=[string "src/editor/battle.lua"]
		-- fn=playBattle
		local ignore, short_src = ismyselffile(f.short_src)
		if not ignore then
			tracefile:write("fl="..short_src.."\n")
			tracefile:write("fn="..func_name.."\n")
			for line, instr in pairs(func.lines) do
				tracefile:write(string.format("%d %d\n", line, instr))
			end

			for i, info in pairs(func.funcs) do
				if methods[info.cfn:sub(5)] then
					info.cfn = ("cfn=%s"):format(methods[info.cfn:sub(5)].name)
				end

				tracefile:write(info.cfl.."\n")
				tracefile:write(info.cfn.."\n")
				tracefile:write(("calls=%d %d\n"):format(info.ncalls, info.linedefined))
				for lno, instr in pairs(info.instrs) do
					tracefile:write(("%d %d %d\n"):format(lno, instr, info.cycles[lno] or 0))
				end
			end

			tracefile:write("\n")
		end
	end

	tracefile:close()
end

if arg then
	local main = assert(loadfile(arg[1]))

	M.start()
	main()
	M.stop()
end

return M