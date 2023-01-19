--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2021 TianJi Information Technology Inc.
--
-- battle相关csv配置动态加载和卸载
--

local PreloadIndexFuncs = {}

local function _readonly(name, t)
	-- csv in protect mode when in windows
	if device.platform == "windows" then
		globals[name] = csvReadOnlyInWindows(t, name)
		printDebug("battle_config_defines - proxy index %s", name)
	end
end

local function _addPreloadGlobalIndex(name, initFunc)
	table.insert(PreloadIndexFuncs, {
		name = name,
		init = function()
			-- assert(globals[name] == nil, name .. " be loaded in other")

			if initFunc == nil then
				if globals[name] then
					-- must be _dynamicLoadingMT
					local size = itertools.size(globals[name])
				end
				return
			end

			-- preload content implement in here
			if globals[name] == nil then
				local t = {}
				globals[name] = t
				initFunc(t)
				-- gFormulaConst特殊
				if name ~= "gFormulaConst" then
					_readonly(name, t)
				end
			end
		end,
	})
end

-- 怪物表数据
-- define in config_defines
_addPreloadGlobalIndex("gMonsterCsv")

-- 场景属性修正表数据
_addPreloadGlobalIndex("gSceneDemonCorrectCsv", function(t)
	for k,v in csvPairs(csv.scene_demon_correct) do
		if t[v.index] == nil then t[v.index] = {} end
		t[v.index][v.wave] = v
	end
end)

-- 战斗结束特殊规则数据
_addPreloadGlobalIndex("gGameEndSpeRuleCsv", function(t)
	for k,v in csvPairs(csv.game_end_special_rule) do
		if t[v.markID] == nil then t[v.markID] = {} end
		t[v.markID] = v
	end
end)

_addPreloadGlobalIndex("gProcessEventCsv", function(t)
	for k, v in csvPairs(csv.skill_process) do
		if v.effectEventID then
			t[k] = csv.effect_event[v.effectEventID]
		end
	end
end)

-- define in config_defines
_addPreloadGlobalIndex("gEffectByEventCsv")

_addPreloadGlobalIndex("gEffectOptionCsv", function(t)
	for k, v in csvPairs(csv.effect_option) do
		t[v.resPath] = v
	end
end)


-- csv.base_attribute.formula_const
-- 战斗用常数值
_addPreloadGlobalIndex("gFormulaConst", function(t)
	local formulaConst = {}
	for _, v in csvPairs(csv.base_attribute.formula_const) do
		if #v.key > 0 then
			formulaConst[v.key] = v.value
		end
	end

	local function evalData(key)
		local s = formulaConst[key]
		assert(s, "no formula const " .. key)
		return cache.createFormula(s)()
	end

	setmetatable(t, {
		__index = function(_, k)
			if k == "__proxy" or k == "__immutable" then return end

			local keys = string.split(k, "_")
			-- 特殊情况 只有一个参数且不是table
			if #keys == 1 then
				local ret = evalData(keys[1])
				if type(ret) ~= 'table' then
					return function() return ret end
				end
			end

			local isUnpack = keys[#keys] == "oc"
			local ret = {}
			for _, key in ipairs(keys) do
				if key == "oc" then break end
				arraytools.merge_two_inplace(ret, evalData(key))
			end

			local retf = function()
				-- print("---------------", isUnpack)
				-- dump(ret)
				if isUnpack then
					return unpack(ret)
				else
					return ret
				end
			end
			rawset(t, k, retf)
			return retf
		end,
		__newindex = function(_, k, v)
			error("could not write in here " .. k)
		end,
	})
end)

-- buff_group_relation支持调用formula_const的公式
local buffGroupEnv
local function buffGroupDoFormula(strOrTable)
	if not buffGroupEnv then
		assert(gFormulaConst, "gFormulaConst is nil")
		buffGroupEnv = {
			c = gFormulaConst,
			list = function(...)
				return {...}
			end
		}
		buffGroupEnv.__index = buffGroupEnv
		setmetatable(buffGroupEnv, {
			__newindex = function(_, k, v)
				error("you could not write in buffGroupEnv with " .. k)
			end,
		})
	end


	local ret
	if type(strOrTable) == "table" then
		ret = {}
		for i, v in ipairs(strOrTable) do
			local data = eval.doFormula(v, buffGroupEnv)
			if type(data) == "table" then
				-- ret = arraytools.merge({ret, data})
				ret = arraytools.merge_two_inplace(ret, data)
			else
				table.insert(ret, data)
			end
		end
	else
		ret = eval.doFormula(strOrTable, buffGroupEnv)
	end
	return ret
end

-- 免疫、驱散组关系表 buff_group_relation
_addPreloadGlobalIndex("gBuffGroupRelationCsv", function(t)
	for k, v in csvPairs(csv.buff_group_relation) do
		-- array to hashmap
		local _immuneGroup = {}
		for _,v2 in ipairs(v.immuneGroup) do
			_immuneGroup[#_immuneGroup + 1] = arraytools.hash(buffGroupDoFormula(v2))
		end

		local _dispelGroup = {}
		for _,v2 in ipairs(v.dispelGroup) do
			_dispelGroup[#_dispelGroup + 1] = arraytools.hash(buffGroupDoFormula(v2))
		end

		local _powerGroup = {}
		for _,v2 in ipairs(v.powerGroup) do
			_powerGroup[#_powerGroup + 1] = arraytools.hash(buffGroupDoFormula(v2))
		end

		t[k] = {
			immuneGroup = _immuneGroup,
			dispelGroup = _dispelGroup,
			powerGroup = _powerGroup,
			immuneEffect = v.immuneEffect,
		}
	end
end)

_addPreloadGlobalIndex("gBuffEffect", function(t)
	for k, v in csvPairs(csv.buff_effect) do
		t[v.easyEffectFunc] = v
	end
end)

-- 场景修正表csv.base_attribute.scene_attr_correct
_addPreloadGlobalIndex("gSceneAttrCorrect", function(t)
	for k, v in csvPairs(csv.base_attribute.scene_attr_correct) do
		t[v.sceneID] = v
		v.hpMaxC = v.hpC
		v.mp1MaxC = v.mp1C
	end
	return t
end)

_addPreloadGlobalIndex("gCPCorrectionGroups", function(t)
	for k, v in csvPairs(csv.combat_power_correction) do
		t[k] = arraytools.hash(buffGroupDoFormula(v.groupKey))
	end
end)

_addPreloadGlobalIndex("gExtraRoundTrigger", function(t)
	for k, v in csvPairs(csv.extra_round_trigger) do
		t[k] = {
			limitBuff = arraytools.hash(v.limitBuff),
			forbiddenBuff = arraytools.hash(v.forbiddenBuff),
			forbiddenPassiveSkill = arraytools.hash(v.forbiddenPassiveSkill),
			cfgIds = arraytools.hash(v.cfgIds),
			disableBattleState = v.disableBattleState,
		}
	end
end)

-- function globals.battleConfigBegin(key)

-- 	if dev.DYNAMIC_CONFIG_DEFINES_CLOSED then
-- 		lazy_require_begin(key or "__battle__")

-- 		for _, func in ipairs(preload_globals) do
-- 			func(false)
-- 		end
-- 	end

-- 	if not ANTI_AGENT and not gAntiCheat then
-- 		globals.gAntiCheat = {
-- 			unit = {},
-- 			buff = {},
-- 			skill = {},
-- 			skill_process = {},
-- 			effect_event = {},
-- 			base_attribute = {
-- 				nature_matrix = {},
-- 			},
-- 		}

-- 		local function record(path)
-- 			local anti, config, lastName = getAntiAndCsvByPath(path)
-- 			local t = {}
-- 			for k, v in csvPairs(config) do
-- 				t[k] = csvNumSum(v)
-- 			end
-- 			t.__default = csvNumSum(config.__default.__index)
-- 			return table.salttable(t)
-- 		end

-- 		gAntiCheat.unit = record("unit")
-- 		gAntiCheat.skill = record("skill")
-- 		gAntiCheat.skill_process = record("skill_process")
-- 		gAntiCheat.buff = record("buff")
-- 		gAntiCheat.effect_event = record("effect_event")
-- 		gAntiCheat.base_attribute.nature_matrix = record({"base_attribute", "nature_matrix"})

-- 		printInfo("config_defines - anti cheat %f KB", collectgarbage("count"))
-- 	end

-- 	collectgarbage("collect")
-- 	printInfo("battleConfigBegin %s, luaCount:%s", BATTLE_KEY, collectgarbage("count"))
-- end

-- function globals.battleConfigEnd(key, anti_holde)
-- 	if dev.DYNAMIC_CONFIG_DEFINES_CLOSED then

-- 		lazy_require_end(key or "__battle__")

-- 		for _, func in ipairs(preload_globals) do
-- 			func(true)
-- 		end

-- 		if not anti_holde then
-- 			gAntiCheat = nil
-- 		end
-- 	end

-- 	collectgarbage("collect")
-- 	printInfo("battleConfigEnd %s, luaCount:%s", BATTLE_KEY, collectgarbage("count"))
-- end


return PreloadIndexFuncs