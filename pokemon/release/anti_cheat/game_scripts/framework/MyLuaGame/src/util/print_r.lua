--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

require "util.str"

local lua_type = type
local lua_print = print
local tconcat = table.concat
local tinsert = table.insert
local srep = string.rep
local type = type
local tostring = tostring
local next = next
local format = string.format
local isbin = string.isbin

local tapcnt = 0
function globals.print_(...)
	if tapcnt == 0 then
		lua_print(...)
	else
		lua_print(srep("| ", tapcnt), ...)
	end
end

function globals.print_begin(...)
	lua_print(srep("| ", tapcnt) .. '+------------------------------')
	tapcnt = tapcnt + 1
	print_(...)
end

function globals.print_end(...)
	print_(...)
	tapcnt = tapcnt - 1
	lua_print(srep("| ", tapcnt) .. '+------------------------------')
end

function globals.print_r(root, lvl, deep)
	lvl = lvl or 2 -- verbose
	if DEBUG < lvl then return end
	local tb = string.split(debug.traceback("", 2), "\n")
	local str = dumps(root, lua_type(root) == "table", deep)
	local str0 = '++++------------------------------'
	lua_print("\n" .. str0 .. "\n" .."dump from: " .. string.trim(tb[3]) .. "\n" .. str .. "\n" .. str0)
end

function globals.print_r_deep(root, deep)
	return print_r(root, 2, deep)
end

function globals.print_hex(s)
	local function hexadump(s)
		return (s:gsub('.', function (c) return format('%02X ', c:byte()) end))
	end
	lua_print(hexadump(s))
end