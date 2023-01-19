--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2021 TianJi Information Technology Inc.
--

local file_signature = "Copyright_(c)_2021_TianJi_Information_Technology_Inc."

local ffi = require("ffi")

ffi.cdef [[
	int32_t getpid(void);
]]


local function trim(s)
	local from = s:match"^%s*()"
	return from > #s and "" or s:match(".*%S", from)
end

local function check_main_stack()
	local lastinfo
	for i = 1, 99 do
		local info = debug.getinfo(i, "nS")
		if info == nil then break end
		lastinfo = info
		-- print(i, dumps(info))
	end

	-- the func check_main_valid invoke in main
	if lastinfo.source ~= "require 'main'" then
		-- error(lastinfo.source)
		display.director:endToLua()
	end
end

local function get_file_content(path)
	local src = cc.FileUtils:getInstance():getStringFromFile(path)
	if #src == 0 then
		local luaPath, cnt = string.gsub(path, "%.", "/")
		if cnt ~= 0 then
			path = luaPath .. ".lua"
			src = cc.FileUtils:getInstance():getStringFromFile(path)
		end
	end
	return src, path
end

local function get_file_md5(path, md5str)
	require "3rd.stringzutils"
	require "3rd.MD5"

	local src
	src, path = get_file_content(path)

	md5str = (md5str or "") .. file_signature .. src
	local ret = md5(md5str)

	if device.platform == "windows" then
		printInfo('FILE_MD5 %s %s %s sign %s', path, #src, md5(src), ret)
	end
	return ret, #src
end

-- https://www.dazhuanlan.com/2020/04/01/5e846e62c6e07/
--[[
c74ef000-c768b000 r-xp 00000000 08:06 1281       /system/lib/libandroid_runtime.so
c768b000-c7693000 r--p 0019b000 08:06 1281       /system/lib/libandroid_runtime.so
c7693000-c769b000 rw-p 001a3000 08:06 1281       /system/lib/libandroid_runtime.so
c769b000-c769d000 rw-p 00000000 00:00 0
c769d000-c769e000 r--p 00000000 00:00 0
c769e000-c76a1000 r--p 00000000 00:00 0
c76a1000-c76dc000 r-xp 00000000 08:06 1302       /system/lib/libbinder.so
]]
local function andorid_read_proc_maps()
	local pid = ffi.C.getpid()
	local f, err = io.open(string.format("/proc/%s/maps", pid), "r")
	local str
	if f then
		str = f:read('*a')
		f:close()
	else
		printWarn('read proc maps err:', pid, err)
		return nil
	end
	return str
end

local function check_proc_maps(cb)
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	local maps

	if cc.PLATFORM_OS_ANDROID == targetPlatform then
		maps = andorid_read_proc_maps()
	end
	if maps == nil then
		return
	end

	local flag = string.find(maps, "frida")
	flag = flag or string.find(maps, "substrate")
	flag = flag or string.find(maps, "xposed")
	flag = flag or string.find(maps, "XposedBridge")
	flag = flag or (cb and cb(maps))

	if flag then
		display.director:endToLua()
	end
end


return {
	get_file_md5 = get_file_md5,
	get_file_content = get_file_content,

	check_main_stack = check_main_stack,
	check_proc_maps = check_proc_maps,
}