--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- conifg.csv数据转换处理
--

require "util.lazy_require"

-- 正常开启, 反作弊封闭动态加载索引
local DYNAMIC_INDEX_ENABLE = not ANTI_AGENT
print('DYNAMIC_INDEX_ENABLE', DYNAMIC_INDEX_ENABLE)

local strsub = string.sub
local strfind = string.find
local strformat = string.format
local tinsert = table.insert

if not ANTI_AGENT then
	-- resist gg searchNumber
	-- the memory in front of the csv
	-- -14 #define LJ_TNUMX		(~13u)
	-- -5 #define LJ_TSTR			(~4u)
	-- -1 #define LJ_TNIL			(~0u)
	-- -12 #define LJ_TTAB			(~11u)
	local t = {
		{10000, -14, -5, 1, 3400},
		{-5, -1, -1, -5, -14, -12, -5, 3400},
		{-5, -5, -1, -1, -12, -5, -14, -5, -12, -5, 3400},
		{1.2, 1.8, 11, 1.1, 10000, -14, -5, -1, 1, -1},
	}
	local ts = {}
	for i = 1, #t do
		ts[i] = csvNumSum(t[i])
	end
	globals._gg_cheat_ = table.salttable(ts)
	globals._gg_ = {}
	for i = 1, #t*5 do
		local r = math.random(1, #t)
		local tt = t[r]
		local tc = {}
		for j = 1, #tt do
			tinsert(tc, tt[j])
		end
		tinsert(tc, r)
		tinsert(globals._gg_, tc)
	end
end

printInfo("config_defines - loadfile %f KB", collectgarbage("count"))

require "config.csv"

local PreloadCsv = {
	"csv.zawake.levels",
}
for _, name in ipairs(PreloadCsv) do
	local t = loadstring('return ' .. name)()
	local nums = table.nums(t)
	printDebug("preload %s %s %s", name, t, nums)
end

printInfo("config_defines - csv loaded %f KB", collectgarbage("count"))

-- 默认是简体中文
-- 现在只有内网才有多语言，发布版本通过csv2lua直接覆盖无需再转换
-- if LOCAL_LANGUAGE ~= 'cn' then
-- 	setL10nConfig(csv)
-- end

local function _readonly(name, t)
	-- csv in protect mode when in windows
	if device.platform == "windows" then
		globals[name] = csvReadOnlyInWindows(t, name)
		printDebug("config_defines - proxy index %s", name)
	end
end

local function _load(t)
	local initFunc = rawget(t, "__initfunc")
	if initFunc then
		local name = rawget(t, "__name")
		t.__initfunc = nil
		t.__name = nil
		printDebug("config_defines - index %s", name)

		setmetatable(t, nil)
		initFunc(t)
		_readonly(name, t)
	end
end

local _dynamicLoadingMT = {
	__index = function(t, key)
		_load(t)
		return t[key]
	end,
	__pairs = function(t)
		_load(t)
		return lua_pairs(t)
	end,
	__ipairs = function(t)
		_load(t)
		return lua_ipairs(t)
	end,
	__next = function(t)
		_load(t)
		return lua_next(t)
	end,
	__len = function(t)
		_load(t)
		return itertools.size(t)
	end
}
local function _genGlobalDynamicIndex(name, initFunc)
	if not DYNAMIC_INDEX_ENABLE then
		globals[name] = {}
		initFunc(globals[name])
		return
	end
	globals[name] = setmetatable({__initfunc = initFunc, __name = name}, _dynamicLoadingMT)
end

-- -- 引导表 {stage = {begin, specialName}}
_genGlobalDynamicIndex("gGuideStageCsv", function(t)
	local lastStage
	for k, v in orderCsvPairs(csv.new_guide) do
		if lastStage ~= v.stage and not t[v.stage] then
			lastStage = v.stage
			t[v.stage] = {
				begin = k,
				specialName = v.specialName,
			}
		end
	end
end)


-- 常量配置转换表
_genGlobalDynamicIndex("gCommonConfigCsv", function(t1)
	for k, v in csvPairs(csv.common_config) do
		if table.length(v.valueArray) == 0 then
			t1[v.name] = v.value
		end
	end
end)

_genGlobalDynamicIndex("gCommonConfigArrayCsv", function(t2)
	for k, v in csvPairs(csv.common_config) do
		if table.length(v.valueArray) > 0 then
			t2[v.name] = v.valueArray
		end
	end
end)

_genGlobalDynamicIndex("gEffectByEventCsv", function(t)
	for k, v in csvPairs(csv.effect_event) do
		t[v.eventID] = k
	end
end)

-- 怪物表数据
_genGlobalDynamicIndex("gMonsterCsv", function(t)
	for k,v in csvPairs(csv.monster_scenes) do
		if t[v.scene_id] == nil then t[v.scene_id] = {} end
		v.hpMaxC = v.hpC
		v.mp1MaxC = v.mp1C
		if v.scene_id and v.round then
			t[v.scene_id][v.round] = v
		end
	end
end)

-- 获得当前语言等级上限
_genGlobalDynamicIndex("gRoleLevelCsv", function(t)
	for i,v in orderCsvPairs(csv.base_attribute.role_level) do
		if not matchLanguage(v.languages) then
			break
		end
		t[i] = v
	end
end)

-- vip表 gVipCsv[0] 表示0级vip配置
_genGlobalDynamicIndex("gVipCsv", function(t)
	for i,v in orderCsvPairs(csv.vip) do
		t[i-1] = v
	end
end)

-- 卡牌id, 星级对应的属性配置
_genGlobalDynamicIndex("gStarCsv", function(t)
	for k,v in csvPairs(csv.card_star) do
		if t[v.typeID] == nil then t[v.typeID] = {} end
		t[v.typeID][v.star] = v
	end
end)

-- 卡牌id, 星级对应的属性配置
_genGlobalDynamicIndex("gStar2FragCsv", function(t)
	for k,v in orderCsvPairs(csv.card_star2frag) do
		if t[v.type] == nil then t[v.type] = {} end
		t[v.type][v.getStar] = v
	end
end)

-- 卡牌id, 星级对应的属性加成配置
_genGlobalDynamicIndex("gStarEffectCsv", function(t)
	for k,v in csvPairs(csv.card_star_effect) do
		if t[v.typeID] == nil then t[v.typeID] = {} end
		t[v.typeID][v.star] = v
	end
end)

-- 卡牌id, 进化形态对应的 card 配置
_genGlobalDynamicIndex("gCardsCsv", function(t)
	for k,v in orderCsvPairs(csv.cards) do
		if matchLanguage(v.languages) then
			if v.canDevelop then
				if t[v.cardMarkID] == nil then t[v.cardMarkID] = {} end
				if t[v.cardMarkID][v.develop] == nil then t[v.cardMarkID][v.develop] = {} end
				if t[v.cardMarkID][v.develop][v.branch] then
					printError("cards id(%d), develop(%d), branch(%d) 与 id(%d) 重复，检查配置", k, v.develop, v.branch, t[v.cardMarkID][v.develop][v.branch].id)
					return
				end
				t[v.cardMarkID][v.develop][v.branch] = v
			end
		end
	end
end)

_genGlobalDynamicIndex("gCardsMega", function(t)
	for k,v in orderCsvPairs(csv.cards) do
		if matchLanguage(v.languages) then
			if v.megaIndex > 0 then
				if t[v.megaIndex] == nil then t[v.megaIndex] = {} end
				t[v.megaIndex] = {key = k, canDevelop = v.canDevelop}
			end
		end
	end
end)

_genGlobalDynamicIndex("gCardsMarkCsv", function(t)
	for k,v in orderCsvPairs(csv.cards) do
		if matchLanguage(v.languages) then
			if t[v.cardMarkID] == nil then t[v.cardMarkID] = {num = 0, data = {}} end
			t[v.cardMarkID].num = t[v.cardMarkID].num + 1
			t[v.cardMarkID].data[t[v.cardMarkID].num] = k
		end
	end
end)

_genGlobalDynamicIndex("gCardsZawake", function(t)
	for k,v in orderCsvPairs(csv.cards) do
		if v.zawakeID > 0 then
			if t[v.zawakeID] == nil then t[v.zawakeID] = {} end
			t[v.zawakeID][k] = v
		end
	end
end)


-- 卡牌品质配置
_genGlobalDynamicIndex("gCardAdvanceCsv", function(t)
	for k,v in csvPairs(csv.base_attribute.advance_level) do
		if t[v.typeID] == nil then t[v.typeID] = {} end
		t[v.typeID][v.stage] = v
	end
end)

-- csv.language使用key字段做索引
-- 忽略指定key
local textDuplicateTest = {}
local ignoreDuplicateKey = arraytools.hash({"iconNumNormal", "rarity0", "monthCardPrivilege11", "shopTab1", "shopTab2", "rarityFrag0", "rarityFrag1", "rarityFrag2", "rarityFrag3", "rarityFrag4"})

globals.gLanguageCsv = (function(t)
	for k, v in orderCsvPairs(csv.language) do
		if t[v.key] then
			error(string.format("gLanguageCsv key duplicate! 【%d】: %s(%s)", k, v.key, v.text))
		end
		if v.text ~= "" and textDuplicateTest[v.text] then
			local duplicate = textDuplicateTest[v.text]
			-- 忽略服务器的文本重复
			if k > 5000 and duplicate.id > 5000 and not (ignoreDuplicateKey[v.key] or ignoreDuplicateKey[duplicate.key]) then
				-- printWarn("gLanguageCsv text duplicate! 【%d】: %s in 【%d】: %s(%s)", k, v.key, duplicate.id, duplicate.key, v.text)
			end
		end
		t[v.key] = v.text
		textDuplicateTest[v.text] = {id = k, key = v.key}
	end
	return t
end)({})

-- @desc 获得gLanguageCsv的Gender的文本，没有返回nil
function globals.getLanguageGender(keyOrIndex)
	local key = keyOrIndex
	if type(keyOrIndex) == "number" then
		key = game.GENDER_TABLE[keyOrIndex]
	end
	return gLanguageCsv[key]
end

-- @desc 获得gLanguageCsv的Attr的文本，没有返回nil
function globals.getLanguageAttr(keyOrIndex)
	local key = keyOrIndex
	if type(keyOrIndex) == "number" then
		key = game.ATTRDEF_TABLE[keyOrIndex]
	end
	return gLanguageCsv["attr" .. string.caption(key)]
end

-- 稀有度文本内容
_genGlobalDynamicIndex("gLanguageRarity", function(t)
	for k,v in pairs(ui.RARITY_ICON) do
		t[k] = gLanguageCsv["rarity" .. k]
	end
end)

-- 噩梦关卡要开启时需要的前置副本
_genGlobalDynamicIndex("gNightmareForCsv", function(t)
	for k,v in csvMapPairs(csv.world_map) do
		local id = v.nightmareMapId or v.heroMapId
		if id then
			t[id] = k
		end
	end
end)

-- 花费序列，使用服务器key
_genGlobalDynamicIndex("gCostCsv", function(t)
	for k,v in csvPairs(csv.cost) do
		t[v.service] = v.seqParam
	end
end)

-- 表情配置
_genGlobalDynamicIndex("gEmojiCsv", function(t)
	for k,v in csvPairs(csv.chat_emoji) do
		t[v.key] = v
	end
end)

-- 卡牌经验药水
_genGlobalDynamicIndex("gCardExpItemCsv", function(t)
	for k,v in orderCsvPairs(csv.items) do
		if v.type == game.ITEM_TYPE_ENUM_TABLE.cardExp then
			tinsert(t, v)
		end
	end
end)

-- 自动售卖道具
_genGlobalDynamicIndex("gAutoSellItemsCsv", function(t)
	for k,v in orderCsvPairs(csv.items) do
		if v.autoSell == game.SELL_TYPE.auto and v.sellPrice > 0 then
			tinsert(t, v)
		end
	end
end)

-- 携带道具基础消耗
_genGlobalDynamicIndex("gHeldItemExpCsv", function(t)
	for k,v in orderCsvPairs(csv.items) do
		if v.specialArgsMap.heldItemExp then
			tinsert(t, v)
		end
	end
end)

-- 芯片基础强化材料
_genGlobalDynamicIndex("gChipExpCsv", function(t)
	for k,v in orderCsvPairs(csv.items) do
		if v.specialArgsMap.chipExp then
			tinsert(t, v)
		end
	end
end)

-- 图鉴
_genGlobalDynamicIndex("gHandbookCsv", function(t1)
	for i,v in orderCsvPairs(csv.pokedex) do
		if matchLanguage(v.languages) then
			t1[v.cardID] = v
		end
	end
end)

_genGlobalDynamicIndex("gHandbookArrayCsv", function(t2)
	for i,v in orderCsvPairs(csv.pokedex) do
		if matchLanguage(v.languages) then
			tinsert(t2, v)
		end
	end
end)


-- 图鉴拓展表
_genGlobalDynamicIndex("gPokedexDevelop", function(t)
	for i,v in orderCsvPairs(csv.pokedex_develop) do
		if t[v.markID] == nil then t[v.markID] = {} end
		t[v.markID][v.star] = v
	end
end)

-- 角色头像
_genGlobalDynamicIndex("gRoleLogoCsv", function(t)
	for i,v in orderCsvPairs(csv.role_logo) do
		if matchLanguage(v.languages) then
			t[i] = v
		end
	end
end)

-- 角色头像框
_genGlobalDynamicIndex("gRoleFrameCsv", function(t)
	for i,v in orderCsvPairs(csv.role_frame) do
		if matchLanguage(v.languages) then
			t[i] = v
		end
	end
end)

-- 角色形象
_genGlobalDynamicIndex("gRoleFigureCsv", function(t)
	for i,v in orderCsvPairs(csv.role_figure) do
		if matchLanguage(v.languages) then
			t[i] = v
		end
	end
end)


-- 称号
_genGlobalDynamicIndex("gTitleCsv", function(t)
	for i,v in orderCsvPairs(csv.title) do
		if matchLanguage(v.languages) then
			t[i] = v
		end
	end
end)

-- 抽取展示
_genGlobalDynamicIndex("gDrawPreviewCsv", function(t)
	for _,v in orderCsvPairs(csv.draw_preview) do
		t[v.type] = t[v.type] or {}
		tinsert(t[v.type],v)
	end
end)

-- 抽取展示
_genGlobalDynamicIndex("gDrawPreviewMap", function(t)
	for _,v in orderCsvPairs(csv.draw_preview) do
		if v.item then
			for _, id in csvPairs(v.item) do
				t[id] = true
			end
		end
		if v.card then
			for _, id in csvPairs(v.card) do
				local cardCfg = csv.cards[id]
				if cardCfg then
					t[cardCfg.fragID] = true
				end
			end
		end
	end
end)

-- unlock
_genGlobalDynamicIndex("gUnlockCsv", function(t)
	for k,v in csvPairs(csv.unlock) do
		if matchLanguage(v.languages) then
			t[v.feature] = k
		end
	end
end)

-- 皮肤
_genGlobalDynamicIndex("gSkinCsv", function(t)
	for i, v in orderCsvPairs(csv.card_skin) do
		if matchLanguage(v.languages) then
			t[i] = v
		end
	end
end)

-- 皮肤商城
_genGlobalDynamicIndex("gSkinShopCsv", function(t)
	for i, v in orderCsvPairs(csv.card_skin_shop) do
		if matchLanguage(v.languages) then
			t[i] = v
		end
	end
end)

-- 日常小助手
_genGlobalDynamicIndex("gDailyAssistantCsv", function(t)
	for k, v in orderCsvPairs(csv.daily_assistant) do
		if matchLanguage(v.languages) then
			t[v.features] = {csvId = k, cfg = v}
		end
	end
end)

-- 公会修炼配置
_genGlobalDynamicIndex("gUnionSkillCsv", function(t)
	for k,v in csvPairs(csv.union.union_skill_level) do
		if t[v.skillID] == nil then t[v.skillID] = {} end
		t[v.skillID][v.level] = v
	end
end)

-- 公会功能对应的开放等级
_genGlobalDynamicIndex("gUnionFeatureCsv", function(t)
	for k,v in orderCsvPairs(csv.union.union_level) do
		for _,key in ipairs(v.openFeature) do
			t[key] = k
		end
	end
end)

-- 饰品突破
_genGlobalDynamicIndex("gEquipAdvanceCsv", function(t)
	for i,v in orderCsvPairs(csv.base_attribute.equip_advance) do
		t[v.equip_id] = t[v.equip_id] or {}
		t[v.equip_id][v.stage] = v
	end
end)

-- 好感度等级
_genGlobalDynamicIndex("gGoodFeelCsv", function(t)
	for i,v in orderCsvPairs(csv.good_feel) do
		t[v.feelType] = t[v.feelType] or {}
		t[v.feelType][v.level] = v
	end
end)

-- 好感度属性加成
_genGlobalDynamicIndex("gGoodFeelEffectCsv", function(t)
	for i,v in orderCsvPairs(csv.good_feel_effect) do
		t[v.markID] = t[v.markID] or {}
		t[v.markID][v.level] = v
	end
end)

-- 主城精灵
_genGlobalDynamicIndex("gCitySpritesCsv", function(t)
	for i,v in orderCsvPairs(csv.city_sprites) do
		if not t[v.group] then
			t[v.group] = {}
		end
		tinsert(t[v.group], v)
	end
end)

globals.gRandomTowerFloorMax = (function(t)
	local roomIdx = 0
	local floor = 1
	for i,v in orderCsvPairs(csv.random_tower.tower) do
		if floor ~= v.floor then
			floor = v.floor
			roomIdx = 0
		end

		v.roomIdx = roomIdx

		t[floor] = roomIdx
		roomIdx = roomIdx + 1
	end
	return t
end)({})

-- 努力值
_genGlobalDynamicIndex("gCardEffortAdvance", function(t)
	for i,v in csvPairs(csv.card_effort_advance) do
		t[v.effortSeqID] = t[v.effortSeqID] or {}
		t[v.effortSeqID][v.advance] = v
	end
end)

-- 精灵特性
_genGlobalDynamicIndex("gCardAbilityCsv", function(t)
	for i,v in orderCsvPairs(csv.card_ability) do
		if not t[v.abilitySeqID] then
			t[v.abilitySeqID] = {}
		end
		t[v.abilitySeqID][v.position] = v
	end
end)

-- 各个关卡可捕捉的精灵表
_genGlobalDynamicIndex("gGateCaptureCsv", function(t)
	for i,v in orderCsvPairs(csv.capture.sprite) do
		if v.type == 1 then
			if v.gate ~= 0 then
				t[v.gate] = i
			end
		end
	end
end)

_genGlobalDynamicIndex("gAchievementLevelCsv", function(t)
	for i, v in orderCsvPairs(csv.achievement.achievement_level) do
		if not t[v.type] then
			t[v.type] = {}
		end
		t[v.type][v.level] = v
	end
end)

-- VIP限制
if gUnlockCsv.vipLevel18 then
	game.VIP_LIMIT = 18
end

_genGlobalDynamicIndex("gUnionLogoCsv", function(t)
	for id, v in orderCsvPairs(csv.union.union_logo) do
		t[id] = v.icon
	end
end)

_genGlobalDynamicIndex("gCraftSpecialRules", function(t)
	for id, v in orderCsvPairs(csv.craft.craft_special_rule) do
		if v.isOpen then
			t[v.markID] = v.buffType
		end
	end
end)

-- 符石卡牌槽解锁条件
_genGlobalDynamicIndex("gGemPosCsv", function(t)
	for id, v in orderCsvPairs(csv.gem.pos) do
		if not t[v.gemPosSeqID] then
			t[v.gemPosSeqID] = {}
		end
		t[v.gemPosSeqID][v.gemPosNo] = v
	end
end)

--spine音效
_genGlobalDynamicIndex("gSoundCsv", function(t)
	for k,v in csvPairs(csv.sound_config) do
		t[v.spineName] = t[v.spineName] or {}
		t[v.spineName][v.action] = v
	end
end)

-- 符石套装
_genGlobalDynamicIndex("gGemSuitCsv", function(t)
	for id, v in orderCsvPairs(csv.gem.suit) do
		t[v.suitID] = t[v.suitID] or {}
		t[v.suitID][v.suitQuality] = t[v.suitID][v.suitQuality] or {}
		t[v.suitID][v.suitQuality][v.suitNum] = v
	end
end)

--芯片主属性
_genGlobalDynamicIndex("gChipMainAttrCsv", function(t)
	for _, v in orderCsvPairs(csv.chip.main_attr) do
		t[v.seq] = t[v.seq] or {}
		t[v.seq][v.level] = v
	end
end)

-- 芯片套装
_genGlobalDynamicIndex("gChipSuitCsv", function(t)
	for id, v in orderCsvPairs(csv.chip.suits) do
		t[v.suitID] = t[v.suitID] or {}
		t[v.suitID][v.suitQuality] = t[v.suitID][v.suitQuality] or {}
		t[v.suitID][v.suitQuality][v.suitNum] = v
	end
end)

-- 芯片共鸣
_genGlobalDynamicIndex("gChipResonanceCsv", function(t)
	for id, v in orderCsvPairs(csv.chip.resonance) do
		t[v.type] = t[v.type] or {}
		t[v.type][v.groupID] = t[v.type][v.groupID] or {}
		tinsert(t[v.type][v.groupID], v)
	end
	for _type, groupData in pairs(t) do
		for _, data in pairs(groupData) do
			table.sort(data, function(v1, v2) return v1.priority > v2.priority end)
		end
	end
end)

-- 不同品质强化所需经验不同
_genGlobalDynamicIndex("gChipLevelSumExpCsv", function(t)
	for id, v in orderCsvPairs(csv.chip.strength_cost) do
		for i = 1, math.huge do
			local exp = v["levelExp" .. i]
			if exp then
				t[i] = t[i] or {[0] = 0}
				t[i][id] = t[i][id - 1] + exp
			else
				break
			end
		end
	end
end)

-- 成长向导
_genGlobalDynamicIndex("gGrowGuideCsv", function(t)
	for id, v in orderCsvPairs(csv.grow_guide) do
		if gUnlockCsv[v.feature] then
			tinsert(t, v)
		end
	end
end)

-- 由控制率属性影响的buff类型
_genGlobalDynamicIndex("gControlPerType", function(t)
	for i,v in csvPairs(csv.base_attribute.controllbufftype) do
		if v.unlock then
			t[v.controllBuffType] = true
		end
	end
end)

_genGlobalDynamicIndex("gOnlineFightCards", function(t)
	for id, v in orderCsvPairs(csv.cross.online_fight.cards) do
		t[v.cardId] = v
	end
end)

-- 实时匹配天赋加成
globals.gOnlineFightTalentAttrs = nil
-- 前后排 {1: {attr: {const, percent}}, 2: {attr: {const, percent}}}
globals.gOnlineFightTalentPositions = {
	[game.TALENT_TYPE.battleFront] = {},
	[game.TALENT_TYPE.battleBack] = {},
}
-- 自然属性 {nature: {attr: {const, percent}}}
globals.gOnlineFightTalentNatures = {}
(function(t)
	for _, v in pairs(game.NATURE_ENUM_TABLE) do
		t[v] = {}
	end
end)(globals.gOnlineFightTalentNatures)

globals.initOnlineFightTalent = function( ... )
	if gOnlineFightTalentAttrs ~= nil then
		return
	end
	globals.gOnlineFightTalentAttrs = {}
	for i, cfg in csvPairs(csv.cross.online_fight.talent) do
		local t = nil
		if cfg.addType == game.TALENT_TYPE.battleFront then
			t = {gOnlineFightTalentPositions[game.TALENT_TYPE.battleFront]}

		elseif cfg.addType == game.TALENT_TYPE.battleBack then
			t = {gOnlineFightTalentPositions[game.TALENT_TYPE.battleBack]}

		elseif cfg.addType == game.TALENT_TYPE.cardsAll then
			t = gOnlineFightTalentNatures -- 全体

		elseif cfg.addType == game.TALENT_TYPE.cardNatureType then
			t = {gOnlineFightTalentNatures[cfg.natureType]}

		else
			-- 实时匹配天赋表没有场景加成类型
			error('not support addType' .. cfg.addType)
		end

		local attr = cfg.attrType
		if gOnlineFightTalentAttrs[attr] == nil then
			gOnlineFightTalentAttrs[attr] = true
		end
		local num, numtype = dataEasy.parsePercentStr(cfg.attrNum)
		for _, v in pairs(t) do
			if v[attr] == nil then
				v[attr] = {0, 0} -- {const, percent}
			end
			if numtype == game.NUM_TYPE.number then
				v[attr][1] = v[attr][1] + num
			else
				v[attr][2] = v[attr][2] + num
			end
		end
	end
end

globals.gShopType = {
	[1] = csv.fix_shop,
	[2] = csv.union.union_shop,
	[3] = csv.frag_shop,
	[4] = csv.pwshop,
	[5] = csv.explorer.explorer_shop,
	[6] = csv.random_tower.shop,
	[7] = csv.craft.shop,
	[8] = csv.equip_shop,
	[9] = csv.union_fight.shop,
	[10] = csv.cross.craft.shop,
	[11] = csv.cross.arena.shop,
	[12] = csv.fishing.shop,
	[13] = csv.cross.online_fight.shop,
	[15] = csv.cross.mine.shop,
	[16] = csv.cross.hunting.shop,
}
-- 判别可以从商店中获取的道具
-- 固定的就是 itemMap, 随机的就是 itemWeightMap
_genGlobalDynamicIndex("gShopGainMap", function(t)
	for _, shop in pairs(gShopType) do
		for _, v in orderCsvPairs(shop) do
			if v.itemMap then
				for k, _ in csvMapPairs(v.itemMap) do
					t[k] = true
				end
			end
			if v.itemWeightMap then
				for k, _ in csvMapPairs(v.itemWeightMap) do
					t[k] = true
				end
			end
		end
	end
end)

-- 合服索引配置
-- 记录所有已合并的服务器直属的合并表ID, 可递归判定最终目的服务器合并表ID
-- {"game.cn.1" = 101, "gamemerge.cn.1" = 102} -- 有二次合服
local serverKeys = {}
-- 记录所有目的服务器，serverKeys中非destServerKey的key则为原始服务器
-- {"gamemerge.cn.1" = 101, "gamemerge.cn.2" = 102}
local destServerKey = {}
for k, v in orderCsvPairs(csv.server.merge) do
	if destServerKey[v.destServer] then
		error(string.format("csv.server.merge: (%s) can't exist in (%d) and (%d) at the same time", v.destServer, destServerKey[v.destServer], k))
	end
	destServerKey[v.destServer] = k
	for _, key in ipairs(v.servers) do
		if serverKeys[key] then
			error(string.format("csv.server.merge: (%s) can't exist in (%d) and (%d) at the same time", key, serverKeys[key], k))
		end
		serverKeys[key] = k
	end
end
local function getDestServerID(id)
	local destServer = csv.server.merge[id].destServer
	local newId = serverKeys[destServer]
	if not newId then
		return id
	end
	return getDestServerID(newId)
end
local function getServers(tb, id)
	local cfg = csv.server.merge[id]
	local destServer = cfg.destServer
	if tb[destServer] then
		return tb[destServer].servers
	end
	local t = {}
	for _, key in ipairs(cfg.servers) do
		local mergeId = destServerKey[key]
		if mergeId then
			local servers = getServers(tb, mergeId)
			for _,server in ipairs(servers) do
				tinsert(t, server)
			end
		else
			tinsert(t, key)
		end
	end
	tb[destServer] = {servers = t, id = cfg.serverID}
	return t
end
-- 源服务器对应的最终目的服务器合并表ID
-- {["game.cn.1"] = 102, ["game.cn.2"] = 102, ["game.cn.6"] = 102}

_genGlobalDynamicIndex("gServersMergeID", function(t1)
	for k,v in orderCsvPairs(csv.server.merge) do
		local id = getDestServerID(k)
		for _, key in ipairs(v.servers) do
			if not destServerKey[key] then
				t1[key] = id
			end
		end
	end
end)

-- 目的服务器对应的所有源服务器
-- {
-- 	["gamemerge.cn.1"] = {servers = {"game.cn.1", "game.cn.2"}, id = 1},
-- 	["gamemerge.cn.2"] = {servers = {"game.cn.1", "game.cn.2", "game.cn.6"}, id = 1}
-- }

_genGlobalDynamicIndex("gDestServer", function(t2)
	for k,v in orderCsvPairs(csv.server.merge) do
		getServers(t2, k)
	end
end)

_genGlobalDynamicIndex("gZawakeLevelsCsv", function(t)
	for _, v in orderCsvPairs(csv.zawake.levels) do
		t[v.zawakeID] = t[v.zawakeID] or {}
		t[v.zawakeID][v.awakeSeqID] = t[v.zawakeID][v.awakeSeqID] or {}
		t[v.zawakeID][v.awakeSeqID][v.level] = v
	end
end)

_genGlobalDynamicIndex("gZawakeStagesCsv", function(t)
	for _, v in orderCsvPairs(csv.zawake.stages) do
		t[v.zawakeID] = t[v.zawakeID] or {}
		t[v.zawakeID][v.awakeSeqID] = v
	end
end)

-- gTownBuildingCsv[buildID][level]
_genGlobalDynamicIndex("gTownBuildingCsv", function(t)
	for _, v in orderCsvPairs(csv.town.building) do
		t[v.buildID] = t[v.buildID] or {}
		t[v.buildID][v.level] = v
	end
end)

-- 反作弊器修改配表内存，主要针对战斗，暂时只对unit数值型
-- 比如修改了怪物的unit.hitC
local function getAntiAndCsvByPath(path)
	local anti, config, lastName
	if type(path) == "table" then
		anti = gAntiCheat
		config = csv
		for _, n in ipairs(path) do
			anti = anti[n]
			config = config[n]
			lastName = n
		end
	else
		anti = gAntiCheat[path]
		config = csv[path]
		lastName = path
	end
	return anti, config, lastName
end

if false and not ANTI_AGENT then
	globals.gAntiCheat = {
		unit = {},
		buff = {},
		skill = {},
		skill_process = {},
		effect_event = {},
		base_attribute = {
			nature_matrix = {},
		},
	}

	local function record(path)
		local anti, config, lastName = getAntiAndCsvByPath(path)
		local t = {}
		for k, v in csvPairs(config) do
			t[k] = csvNumSum(v)
		end
		t.__default = csvNumSum(config.__default.__index)
		return table.salttable(t)
	end

	gAntiCheat.unit = record("unit")
	gAntiCheat.skill = record("skill")
	gAntiCheat.skill_process = record("skill_process")
	gAntiCheat.buff = record("buff")
	gAntiCheat.effect_event = record("effect_event")
	gAntiCheat.base_attribute.nature_matrix = record({"base_attribute", "nature_matrix"})

	printInfo("config_defines - anti cheat %f KB", collectgarbage("count"))
end

function globals.checkGGCheat()
	if ANTI_AGENT then return end

	-- check _gg_
	for i, t in ipairs(_gg_) do
		local num = csvNumSum(t)
		local idx = t[#t]
		num = num - idx
		local antiCheatNum = _gg_cheat_[idx]
		if antiCheatNum == nil or math.abs(antiCheatNum - num) > 1e-5 then
			errorInWindows('checkGGCheat %d %s %s', i, antiCheatNum, num)
			exitApp("close your cheating software")
		end
	end

	-- check csv
	checkSpecificCsvCheat("unit")
	checkSpecificCsvCheat("skill")
	checkSpecificCsvCheat("skill_process")
	checkSpecificCsvCheat("buff")
	checkSpecificCsvCheat("effect_event")
	checkSpecificCsvCheat({"base_attribute", "nature_matrix"})
end

function globals.checkSpecificCsvCheat(path, iter)
	-- TODO: 动态加载测试,临时关闭
	do return end

	if ANTI_AGENT then return end

	local anti, config, lastName = getAntiAndCsvByPath(path)
	if iter == nil then
		iter = itertools.ikeys(csvPairs(config))
	end

	local num = csvNumSum(config.__default.__index)
	local antiCheatNum = anti.__default
	if math.abs(antiCheatNum - num) > 1e-5 then
		errorInWindows('checkSpecificCsvCheat %s default %s %s', lastName, antiCheatNum, num)
		exitApp("close your cheating software")
	end

	itertools.each(iter, function(_, k)
		local antiCheatNum = anti[k] or 0
		local num = csvNumSum(config[k]) or 0
		if math.abs(antiCheatNum - num) > 1e-5 then
			errorInWindows('checkSpecificCsvCheat %s %s %s %s', lastName, k, antiCheatNum, num)
			exitApp("close your cheating software")
		end
	end)
end


printInfo("config_defines - index and cache %f KB", collectgarbage("count"))
collectgarbage("collect")
printInfo("config_defines - after collect %f KB", collectgarbage("count"))


-- do some csv check in windows
if device.platform == "windows" then
	-- 检测图鉴中的卡牌是否包含在cards表中是否开放
	for cardId, _ in pairs(gHandbookCsv) do
		if not csv.cards[cardId] then
			error(string.format("图鉴中有%d, 但cards表未开放", cardId))
			break
		end
	end
	local itemTable = csv.items
	local unitTable = csv.unit
	for k, v in orderCsvPairs(csv.cards) do
		local feelType = v.feelType
		if feelType <= 3 then
			if itertools.include(v.feelItems, 604) or itertools.include(v.feelItems, 605) then
				error(string.format("csv.cards[%d].feelItems 好感度道具有不合法的配置, 品质不对应", k))
			end
		else
			if itertools.include(v.feelItems, 601) or itertools.include(v.feelItems, 602) or itertools.include(v.feelItems, 603) then
				error(string.format("csv.cards[%d].feelItems 好感度道具有不合法的配置, 品质不对应", k))
			end
		end
	end
end