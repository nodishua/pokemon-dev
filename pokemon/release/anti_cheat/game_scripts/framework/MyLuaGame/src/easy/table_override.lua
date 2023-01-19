--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
-- 为proxytable和immutabletable的实现重载
-- win32下特殊使用，否则无需干扰系统函数
-- 只是为了掩盖win32下csv使用proxytable时的特殊处理
-- 正常使用proxytable的话，请查看easy/table.lua
--

globals = globals or _G

globals.lua_unpack = unpack
globals.lua_table_getn = table.getn
globals.lua_table_maxn = table.maxn
globals.lua_table_sort = table.sort
globals.lua_table_concat = table.concat
globals.lua_table_insert = table.insert
globals.lua_table_remove = table.remove

require "easy.table"

local getraw = table.getraw

print("table lib override for protected")

function unpack(t, ...)
	return lua_unpack(getraw(t), ...)
end

function table.getn(t)
	return lua_table_getn(getraw(t))
end

function table.maxn(t)
	return lua_table_maxn(getraw(t))
end

function table.concat(t, ...)
	return lua_table_concat(getraw(t), ...)
end

--
-- there are will be skip proxy or immutable
-- NO OVERRIDE
--

-- function table.sort(t, ...)
-- 	return lua_table_sort(getraw(t), ...)
-- end

-- function table.insert(t, ...)
-- 	return lua_table_insert(getraw(t), ...)
-- end

-- function table.remove(t, ...)
-- 	return lua_table_remove(getraw(t), ...)
-- end
