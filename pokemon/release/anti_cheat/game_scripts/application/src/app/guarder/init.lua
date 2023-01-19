--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2021 TianJi Information Technology Inc.
--

local fixEnKofiEntryID
local damageHitFuncs_2
local damageHitFuncs_3

local function fix_en_kofi()
	-- check kfoi file
	local ret, err = pcall(function()
		require("kofi")
	end)
	if err and string.find(err, "not found") == nil then
		display.director:endToLua()
	end

	-- check battleEasy.damageHitFuncs 2 3
	if tostring(battleEasy.damageHitFuncs[2]) ~= damageHitFuncs_2 then
		display.director:endToLua()
	end
	if tostring(battleEasy.damageHitFuncs[3]) ~= damageHitFuncs_3 then
		display.director:endToLua()
	end

	-- check gKofiParams
	if not fixEnKofiEntryID then
		local cnt = 1
		fixEnKofiEntryID = display.director:getScheduler():scheduleScriptFunc(function()
			if globals["gKofiParams"] ~= nil then
				display.director:endToLua()
			end

			if gGameUI.scene:getChildByName("kofi") ~= nil then
				display.director:endToLua()
			end

			cnt = cnt + 1
			if cnt > 10 then
				display.director:getScheduler():unscheduleScriptEntry(fixEnKofiEntryID)
			end
		end, 5, false)
	end
end

local function init()
	print("app guarder init")

	require "battle.easy.include"
	damageHitFuncs_2 = tostring(battleEasy.damageHitFuncs[2])
	damageHitFuncs_3 = tostring(battleEasy.damageHitFuncs[3])

	fix_en_kofi()

	local guarder = require("util.guarder")
	guarder.check_main_stack()
	guarder.check_proc_maps(function(maps)
		return string.find(maps, "kofi") or string.find(maps, "koofi")
	end)
end

local function check()
	print("app guarder check")

	fix_en_kofi()
end

init()

return check