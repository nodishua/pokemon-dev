--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2021 TianJi Information Technology Inc.
--
-- battle相关csv配置动态加载和卸载
--

local PreloadCsv = {
	"csv.common_config",
	"csv.monster_scenes",
	"csv.skill",
	"csv.skill_process",
	"csv.scene_conf",
	"csv.effect_event",
	"csv.effect_power",
	"csv.buff",
	"csv.buff_group_power",
	"csv.buff_group_relation",
	"csv.explorer.explorer",
	"csv.buff_effect",
	"csv.effect_option",
	"csv.damage_process",
	"csv.base_attribute.nature_matrix",
	"csv.game_end_special_rule",
}

local PreloadIndexFuncs = require "battle.battle_config_defines"
local IsPreload = false
local CsvPreloadBefore
local CsvPreloadAfter

function battleEntrance.preloadConfig()
	if IsPreload then
		return
	end

	collectgarbage()
	local mem = collectgarbage("count")
	local clock = os.clock()

	CsvPreloadBefore = getLoadedCsvPathSet()
	printDebug('before battleEntrance.preloadConfig %s', itertools.size(CsvPreloadBefore))

	for _, index in ipairs(PreloadIndexFuncs) do
		index.init()
		printDebug("battle preload %s %s", index.name, globals[index.name])
	end

	for _, name in ipairs(PreloadCsv) do
		local t = loadstring('return ' .. name)()
		local nums = table.nums(t)
		printDebug("battle preload %s %s %s", name, t, nums)
	end

	CsvPreloadAfter = getLoadedCsvPathSet()
	-- print_r(CsvPreloadAfter)
	printDebug('after battleEntrance.preloadConfig %s', itertools.size(CsvPreloadAfter))

	collectgarbage()
	local curMem = collectgarbage("count")
	printDebug('battleEntrance.preloadConfig over mem %.2fKB cost %.2fKB %.3fs', curMem, curMem - mem, os.clock() - clock)

	IsPreload = true
end

function battleEntrance.unloadConfig()
	if not IsPreload then
		return
	end

	local mem = collectgarbage("count")
	local clock = os.clock()

	local afterSet = getLoadedCsvPathSet()
	-- print_r(afterSet)
	local size = itertools.size(afterSet)

	-- afterSet - beforeSet
	for k, v in pairs(CsvPreloadBefore) do
		afterSet[k] = nil
	end
	for k, v in pairs(CsvPreloadAfter) do
		if afterSet[k] then
			afterSet[k] = "preload"
		end
	end
	-- print_r(afterSet)
	printDebug('battleEntrance.unloadConfig before %s end %s loaded in battle %s', itertools.size(CsvPreloadBefore), size, itertools.size(afterSet))

	-- unload csv in lua package
	-- configUnload(itertools.keys(afterSet))
	-- printCsvLoadState()

	collectgarbage()
	local curMem = collectgarbage("count")
	printDebug('battleEntrance.unloadConfig over mem %.2fKB cost %.2fKB %.3fs', curMem, curMem - mem, os.clock() - clock)

	CsvPreloadBefore = nil
	CsvPreloadAfter = nil
	IsPreload = false
end