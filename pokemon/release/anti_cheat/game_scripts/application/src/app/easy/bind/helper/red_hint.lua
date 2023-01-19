-- @Date:   2019-02-22
-- @Desc:
-- @Last Modified time: 2019-09-18
local unionTools = require "app.views.city.union.tools"
local zawakeTools = require "app.views.city.zawake.tools"
local dailyAssistantTools = require "app.views.city.daily_assistant.tools"

local redHintHelper = {}

local SHOW_TYPE = {
	CARD = 1,
	FRAGMENT = 2,
}
local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE
local YY_TYPE_HASH = itertools.map(YY_TYPE, function(k, v) return v, k end)

local function checkFinishTask(tb)
	for _,v in ipairs(tb) do
		-- 1:可领取
		if v.state == 1 then
			return true
		end
	end
	return false
end

local function commonTaskRedHintJudge(t, tag)
	local tagT = t[tag]
	for k,v in pairs(tagT) do
		if v.flag and v.flag ~= 2 and v.flag == 1 then
			return true
		end
	end
	if t.stageAward then
		if itertools.first(t.stageAward, 1) ~= nil then
			return true
		end
	end
	return false
end

local function isCardInBattleCards(dbId)
	local h = cache.queryRedHint("isCardInBattleCards", function()
		local h = {}
		local cards = gGameModel.role:read("battle_cards") or {}
		return itertools.map(cards, function(_, v) return v, true end)
	end)
	return h[dbId]
end

redHintHelper.isCardInBattleCards = isCardInBattleCards
redHintHelper.mustInBattleCards = {
	nvalue = true,
	advance = true,
	star = true,
	skill = true,
	effortValue = true,
	cardDevelop = true,
	cardFeel = true,
	equipStrengthen = true,
	equipStar = true,
	equipAwake = true,
	equipSignet = true,
	equip = true,
	heldItems = true,
	specialCardIcon = true,
	gemFreeExtract = true,
	canZawake = true,
}

local function getCardDBID(t)
	local cardData = t.cardData or {}
	return t.selectDbId or cardData.dbid
end
redHintHelper.getCardDBID = getCardDBID

local FieldNameToDataName = {
	card_id = "id",
	nvalue_locked = "nvalueLocked",
	nvalue = "realNValue",
	effort_values = "effortValue",
}

local function checkAndGetCardFields(t, checkf, ...)
	local cardData = t.cardData or {}
	local dbid = t.selectDbId or cardData.dbid or t.curDbId
	if checkf and not checkf(dbid) then
		return false
	end

	local card
	if dbid then
		card = gGameModel.cards:find(dbid)
		if not card then
			return false
		end
	end

	local ret = {...}
	local n = #ret
	for i, k in ipairs(ret) do
		ret[i] = cardData[FieldNameToDataName[k] or k] or card:read(k)
	end

	return true, unpack(ret, 1, n)
end

-- @desc:直购礼包(限时活动内部)
-- @t:{direcBuy} 每日显示，点击进入界面后取消
function redHintHelper.activityBuyGift(t)
	if not t.directBuy then
		return true
	end
	for _,id in ipairs(t.yyOpen) do
		local cfg = csv.yunying.yyhuodong[id]
		if cfg.type == YY_TYPE.directBuyGift and cfg.independent == 0 then
			t.id = id
			t.huodongID = cfg.huodongID
			if redHintHelper.activityDirectBuyGiftExternal(t) then
				return true
			end
		end
	end
	return false
end

-- @desc:直购礼包（外部）
-- --@t:{direcBuy} 每日显示，点击进入界面后取消
function redHintHelper.activityDirectBuyGift(t)
	if not t.directBuy then
		return true
	end
	for _,id in ipairs(t.yyOpen) do
		local cfg = csv.yunying.yyhuodong[id]
		if cfg.type == YY_TYPE.directBuyGift and (cfg.independent == 1 or cfg.independent == 2) then
			t.id = id
			t.huodongID = cfg.huodongID
			if redHintHelper.activityDirectBuyGiftExternal(t) then
				return true
			end
		end
	end
	return false
end

-- @desv直购礼包页签红点
-- --@t:{id, huodongID}
function redHintHelper.activityDirectBuyGiftExternal(t)
	local huodong = t.yyHuodongs[t.id]

	for k, v in csvPairs(csv.yunying.directbuygift) do
		if v.huodongID == t.huodongID and v.rmbCost == 0 then
			if not huodong or not huodong.stamps or not huodong.stamps[k] then
				return true
			end
			if huodong.stamps[k] < v.limit then
				return true
			end
		end
	end
	return false
end

-- @desc:道具兑换
-- @t:{id, yyHuodongs} id:活动id yyHuodongs：运营活动数据
function redHintHelper.activityItemExchange(t)
	local activityId = t.activityId
	if t.yyHuodongs[activityId] then
		local yyCfg = csv.yunying.yyhuodong[activityId]
		local huodongID = yyCfg.huodongID
		local data = t.notifyShow or {}
		local stamps = t.yyHuodongs[activityId].stamps or {}
		local remindData = data[activityId] or {}
		for k, v in csvPairs(csv.yunying.itemexchange) do
			local cnt = stamps[k] or 0		-- 已兑换完的道具不显示红点
			if v.huodongID == huodongID and remindData[k] ~= true and cnt < v.exchangeTimes then
				local ok = true
				for k, v in csvMapPairs(v.costMap) do
					local num = dataEasy.getNumByKey(k)
					if num < v then
						ok = false
						break
					end
				end

				if ok then
					return true
				end
			end
		end
	end
	return false
end

-- @desc:连续充值
-- @t:{id, yyHuodongs} id:活动id yyHuodongs：运营活动数据
function redHintHelper.activityRechargeGift(t)
	local activityId = t.activityId
	if t.yyHuodongs[activityId] then
		local stamps = t.yyHuodongs[activityId].stamps or {}
		local yyCfg = csv.yunying.yyhuodong[activityId]
		local huodongID = yyCfg.huodongID
		for k, v in csvPairs(csv.yunying.rechargegift) do
			if v.huodongID == huodongID then
				-- yydata.stamps[k] : 1:可领取，0：已领取，其他：不可领取
				if stamps[k] == 1 then
					return true
				end
			end
		end
	end
	return false
end

-- @desc:成长基金
-- @t:{id, yyHuodongs} id:活动id yyHuodongs：运营活动数据
function redHintHelper.activityLevelFund(t)
	local activityId = t.activityId
	if t.yyHuodongs[activityId] then
		local stamps = t.yyHuodongs[activityId].stamps or {}
		local yyCfg = csv.yunying.yyhuodong[activityId]
		local huodongID = yyCfg.huodongID
		for k, v in csvPairs(csv.yunying.levelfund) do
			if v.huodongID == huodongID then
				-- yydata.stamps[k] : 1:可领取，0：已领取，其他：不可领取
				if stamps[k] == 1 then
					return true
				end
			end
		end
	end
	return false
end



-- @desc:资源找回红点
-- @t:{id, yyHuodongs} id:活动id yyHuodongs：运营活动数据
function redHintHelper.activityRetrieve(t)
	local retrieve = t.yyHuodongs[t.activityId]
	-- TODO: 服务器需要在符合条件时构造好数据，现在客户端先加保护
	if retrieve == nil then return false end
	if retrieve.lastday ~= tonumber(time.getTodayStrInClock()) then
		return false
	end
	if retrieve.retrieve_award == nil then -- 没领取过
		return true
	end
	local retrieveSize = 6
	local rmbRetrieve = 0
	for k, v in pairs(retrieve.retrieve_award) do
		if v.rmb == 1 then
			rmbRetrieve = rmbRetrieve + 1
		end
	end
	return rmbRetrieve < retrieveSize
end

-- @desc:资源周卡红点
-- --@t:{id, yyHuodongs} id:活动id yyHuodongs：运营活动数据
function redHintHelper.activityWeeklyCard(t)
	local weeklyCard = t.yyHuodongs[t.activityId] or {}
	if weeklyCard == nil then return false end
	if weeklyCard.buy == nil then return false end
	if weeklyCard.stamps == nil then return false end

	for k, v in pairs(weeklyCard.stamps) do
		if v == 1 then
			return true
		end
	end
	return false
end

-- @desc:世界Boss红点
-- --@t:{activityId, bossGateBuy, bossGatePlay}
function redHintHelper.activityWorldBoss(t)
	local yyCfg = csv.yunying.yyhuodong[t.activityId]
	local freeTimes = yyCfg.paramMap.freeCount
	local leftTimes = freeTimes + t.bossGateBuy - t.bossGatePlay
	return leftTimes > 0
end

-- @desc:月卡
-- @t:{yyHuodongs} yyHuodongs:运营活动数据
function redHintHelper.activityMonthlyCard(t)
	local notShow = userDefault.getCurrDayKey("notShowMonthCardRedhint",false)
	if notShow == true then
		return false
	end
	local activityIds = {}
	for _, id in ipairs(t.yyOpen) do
		local cfg = csv.yunying.yyhuodong[id]
		if cfg.type == YY_TYPE.monthlyCard then
			activityIds[cfg.paramMap.rechargeID] = id
		end
	end
	local bought = false
	for i,v in pairs(activityIds) do
		if t.yyHuodongs[v] then
			bought = true
			local enddate = t.yyHuodongs[v].enddate
			local today = tonumber(time.getTodayStrInClock())
			if today > enddate  then
				bought = false
			end
		end
	end
	return not bought
end

-- @desc:体力领取
-- @t: {yyHuodongs} yyHuodongs:运营活动数据
function redHintHelper.activityRegainStamina(t)
	local activityId = t.activityId
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local hour, min = time.getHourAndMin(yyCfg.beginTime, true)
	local refreshT = {hour = hour, min = min}
	for id, v in orderCsvPairs(csv.yunying.yyhuodong) do
		if v.type == YY_TYPE.dinnerTime and matchLanguage(v.languages) then
			local beginHour, beginMin = time.getHourAndMin(v.beginTime, true)
			local data = t.yyHuodongs[id] or {}
			local eat = false
			if data.lastday then
				eat = tostring(data.lastday) == time.getTodayStrInClock(hour, min)
			end
			if not eat then
				local beginHour, beginMin = time.getHourAndMin(v.beginTime, true)
				local beginKey = time.getCmpKey({hour = beginHour, min = beginMin}, refreshT)
				local nowKey = time.getCmpKey(time.getNowDate(), refreshT)
				if nowKey >= beginKey then
					return true
				end
			end
		end
	end
	return false
end

-- @desc:任务 (等级礼包)
-- @t:{id, yyHuodongs} id:活动id, yyHuodongs:运营活动数据
function redHintHelper.activityGeneralTask(t)
	local activityId = t.activityId
	if t.yyHuodongs[activityId] then
		local stamps = t.yyHuodongs[activityId].stamps or {}
		local yyCfg = csv.yunying.yyhuodong[activityId]
		local huodongID = yyCfg.huodongID
		for k, v in csvPairs(csv.yunying.generaltask) do
			if v.huodongID == huodongID then
				-- yydata.stamps[k] : 1:可领取，0：已领取，其他：不可领取
				if stamps[k] == 1 then
					return true
				end
			end
		end
	end
	return false
end

-- @desc:主界面活动红点
-- @t:{yyOpen, independent} yyOpen:运营活动开启
function redHintHelper.totalActivityShow(t)
	local function isOK(tInd, cfgInd)
		if not tInd then
			return cfgInd == 0 or cfgInd == 3 or cfgInd == 4 or cfgInd == 5
		end
		return tInd == cfgInd
	end
	for _,id in ipairs(t.yyOpen) do
		local cfg = csv.yunying.yyhuodong[id]
		if YY_TYPE_HASH[cfg.type] and isOK(t.independent, cfg.independent) then
			local funcName = "activity" .. string.caption(YY_TYPE_HASH[cfg.type])
			t.activityId = id
			if redHintHelper[funcName] and redHintHelper[funcName](t) then
				return true
			end
		end
	end
	return false
end

-- @desc:日常任务红点
-- @t: {stageAward, daily} stageAward:活跃度礼包 daily:日常任务状态
function redHintHelper.cityTaskDaily(t)
	return commonTaskRedHintJudge(t, "daily")
end

-- @desc:主线任务红点
-- @t: {main} main:主线任务状态
function redHintHelper.cityTaskMain(t)
	return commonTaskRedHintJudge(t, "main")
end

function redHintHelper.achievementTask(t)
	local curType = t.curType
	if not curType then
		curType = {0, 1, 2, 3, 4, 5, 6, 7}
	end
	if type(curType) ~= "table" then
		curType = {curType}
	end
	local aTaskCsv = csv.achievement.achievement_task
	local tb = {}
	local taksTypes = {}
	if not t.curType or t.curType == 0 then
		for csvId, data in pairs(t.tasks or {}) do
			local cfg = aTaskCsv[csvId]
			if cfg == nil then
				error("no such achievement_task " .. csvId)
			end
			local taskType = cfg.targetType2
			if not tb[taskType] then
				tb[taskType] = {}
				table.insert(taksTypes, taskType)
			end
			table.insert(tb[taskType], {csvId = csvId, cfg = cfg, state = data[1], finishTime = data[2]})
		end
		table.sort(taksTypes, function(a, b)
			return a < b
		end)
		for _,v in pairs(tb) do
			table.sort(v, function(a, b)
				-- 1:可领取
				if a.state == b.state and a.state == 1 then
					return a.cfg.sort < b.cfg.sort
				end
				if a.state ~= b.state then
					return a.state == 1
				end
				if a.finishTime ~= b.finishTime then
					return a.finishTime > b.finishTime
				end
				return a.csvId < b.csvId
			end)
		end
	end
	local datas = {}
	local count = 0
	for _,taskType in ipairs(taksTypes) do
		table.insert(datas, tb[taskType][1])
	end
	table.sort(datas, function(a, b)
		return a.finishTime > b.finishTime
	end)
	local threeDatas = {}
	for i,v in ipairs(datas) do
		table.insert(threeDatas, v)
		count = count + 1
		if count >= 3 then
			break
		end
	end

	if t.curType and t.curType == 0 then
		return checkFinishTask(threeDatas)
	end
	-- 1 可领取 0 已领取
	for csvId, data in pairs(t.tasks or {}) do
		if data[1] == 1 and itertools.include(curType, aTaskCsv[csvId].type) then
			return true
		end
	end
	if not t.curType then
		return checkFinishTask(threeDatas)
	end

	return false
end

function redHintHelper.achievementBox(t)
	local curType = t.curType
	if not curType then
		curType = {0, 1, 2, 3, 4, 5, 6, 7}
	end
	if type(curType) ~= "table" then
		curType = {curType}
	end
	-- 1 可领取 0 已领取
	local levelCsvTab = csv.achievement.achievement_level
	for csvId,v in pairs(t.box or {}) do
		if v == 1 and itertools.include(curType, levelCsvTab[csvId].type) then
			return true
		end
	end
	return false
end

-- @desc:图鉴突破
-- @t: {pokedexAdvance} pokedexAdvance:突破数据
function redHintHelper.handbookAdvance(t)
	return itertools.first(t.pokedexAdvance, 1) ~= nil
end

-- 个体值红点
function redHintHelper.nvalue(t)
	local dbid = getCardDBID(t)
	if dataEasy.isTodayCheck("nvalue", dbid) then
		return false
	end
	return cache.queryRedHint({"nvalue", dbid}, function()
		local ret, cardId, nvalueLocked, realNValue = checkAndGetCardFields(t, isCardInBattleCards, "card_id", "nvalue_locked", "nvalue")
		if not ret then
			return false
		end

		local lockNum = 0
		for i,v in ipairs(game.ATTRDEF_SIMPLE_TABLE) do
			if nvalueLocked[v] then
				lockNum = lockNum + 1
			end
		end
		local csvItems = csv.card_recast
		local tmpRecastData = {}
		for k,v in ipairs(csvItems) do
			tmpRecastData[v.lockNum] = v.costItems
		end
		for key,num in csvMapPairs(tmpRecastData[lockNum]) do
			local myItemNum = dataEasy.getNumByKey(key) or 0
			if myItemNum < num then
				return false
			end
		end
		local perfectNum = 0
		for typ, num in pairs(realNValue) do
			if num >= game.NVALUE_ATTR_LIMIT then
				perfectNum = perfectNum + 1
			end
		end
		if perfectNum >= #game.ATTRDEF_SIMPLE_TABLE then
			return false
		end
		return true
	end)
end

-- @desc:精灵养成突破红点
-- @t:{selectDbId, items} selectDbId：卡牌dbId, items:背包物品
--@cardData:卡牌数据
function redHintHelper.advance(t)
	local dbid = getCardDBID(t)
	return cache.queryRedHint({"advance", dbid}, function()
		local ret, cardId, advance, level = checkAndGetCardFields(t, isCardInBattleCards, "card_id", "advance", "level")
		if not ret then
			return false
		end

		local csvCards = csv.cards[cardId]
		local advanceMax = csvCards.advanceMax
		--已满级
		if advance >= advanceMax then
			return false
		end
		local csvAdvance = gCardAdvanceCsv[csvCards.advanceTypeID][advance]
		--等级不足
		local needLevel = csvCards.advanceLevelReq[advance]
		if level < needLevel then
			return false
		end
		--金币不足
		if dataEasy.getNumByKey("gold") < csvAdvance.gold then
			return false
		end
		--材料不足
		for id,count in csvPairs(csvAdvance.itemMap) do
			local myItemNum = t.items[id] or 0
			if myItemNum < count then
				return false
			end
		end
		return true
	end)
end

-- @desc:精灵星级升级红点
-- @t:{selectDbId, items, frags} selectDbId：卡牌dbId, items:背包物品, frags:碎片
-- @cardData:卡牌数据
function redHintHelper.star(t)
	local dbid = getCardDBID(t)
	return cache.queryRedHint({"star", dbid}, function()
		local ret, cardId, star = checkAndGetCardFields(t, isCardInBattleCards, "card_id", "star")
		--未上阵的精灵
		if not ret then
			local data = gGameModel.cards:find(dbid)
			if data then
				local selectCardId = data:read("card_id")
				local selectStar = data:read("star")
				local selectFight = data:read("fighting_point")
				local csvCards = csv.cards[selectCardId]
				local cardMarkID = csvCards.cardMarkID
				local csvStar = gStarCsv[csvCards.starTypeID][selectStar]
				local maxStar = table.length(gStarCsv[csvCards.starTypeID])
				local hash = dataEasy.inUsingCardsHash()
				if selectStar >= maxStar then
					return false
				end
				if dataEasy.getNumByKey("gold") < csvStar.gold then
					return false
				end
				for k,v in csvMapPairs(csvStar.costItems) do
					if dataEasy.getNumByKey(k) < v then
						return false
					end
				end
				local num = 0
				for i,v in pairs(t.cards or {}) do
					local card = gGameModel.cards:find(v)
					if card then
						local cardId = card:read("card_id")
						local cardCsv = csv.cards[cardId]
						local unitCsv = csv.unit[cardCsv.unitID]
						if cardCsv.cardMarkID == cardMarkID and dbid ~= v then
							if card:read("star") > selectStar then
								return false
							elseif card:read("star") == selectStar and card:read("fighting_point") > selectFight then
								return false
							end
							if not (card:read("locked") or hash[v]) then
								num = num + 1
							end
						end
					end
				end
				--碎片数量
				local fragCsv = csv.fragments[csvCards.fragID]
				num = num + math.floor(dataEasy.getNumByKey(csvCards.fragID) / fragCsv.combCount)
				if num < csvStar.costCardNum then
					return false
				end
				return true
			end
			return false
		end

		local csvCards = csv.cards[cardId]
		local cardMarkID = csvCards.cardMarkID
		--已满级
		local maxStar = table.length(gStarCsv[csvCards.starTypeID])
		if star >= maxStar then
			return false
		end
		local csvStar = gStarCsv[csvCards.starTypeID][star]
		--金币不足
		if dataEasy.getNumByKey("gold") < csvStar.gold then
			return false
		end
		--卡牌不足
		local cardNum = 0
		for i,v in pairs(t.cards or {}) do
			local card = gGameModel.cards:find(v)
			if card then
				local cardId = card:read("card_id")
				local cardCsv = csv.cards[cardId]
				local unitCsv = csv.unit[cardCsv.unitID]
				if cardCsv.cardMarkID == cardMarkID and dbid ~= v then
					cardNum = cardNum + 1
				end
			end
		end
		if cardNum < csvStar.costCardNum then
			return false
		end
		--材料不足
		for k,v in csvMapPairs(csvStar.costItems) do
			if dataEasy.getNumByKey(k) < v then
				return false
			end
		end
		return true
	end)
end

function redHintHelper.skill(t)
	local dbid = getCardDBID(t)
	return cache.queryRedHint({"skill", dbid}, function()
		local ret, cardLv, skills, cardId, skinId,star, advance = checkAndGetCardFields(t, isCardInBattleCards, "level", "skills", "card_id", "skin_id","star", "star", "advance")
		if not ret then
			return false
		end

		local function isSkillUnlock(cfg)
			if cfg.activeType == 1 then
				return star >= cfg.activeCondition
			elseif cfg.activeType == 2 then
				return advance >= cfg.activeCondition
			end
		end

		if t.skillPoint <= 0 then
			return false
		end
		local list = dataEasy.getCardSkillList(cardId,skinId)
		if list == nil then
			return false
		end
		for _,skillId in csvPairs(list) do
			local skillInfo = csv.skill[skillId]
			local skillLv = skills[skillId] or 1
			local skillGold = csv.base_attribute.skill_level[skillLv]["gold" .. skillInfo.costID]
			if skillLv < cardLv and t.gold >= skillGold and isSkillUnlock(skillInfo) then
				return true
			end
		end
		return false
	end)
end

-- @desc:努力值红点
-- @t:{selectDbId, items} selectDbId：卡牌dbId, items:背包物品
function redHintHelper.effortValue(t)
	local dbid = getCardDBID(t)
	return cache.queryRedHint({"effortValue", dbid}, function()
		local ret, cardId, effortValue, effort_advance, level = checkAndGetCardFields(t, isCardInBattleCards, "card_id", "effort_values", "effort_advance", "level")
		if not ret then
			return false
		end

		local normal, special, isNotMaxAdvance, isCanLevelUp
		local isNotAllMax = false
		for i,v in orderCsvPairs(csv.card_effort) do
			if v.advance == 1 then
				normal = v.cost1
				special = v.cost2
				local attrType = game.ATTRDEF_TABLE[v.attrType]
				local maxVal, total
				maxVal, total, isNotMaxAdvance, isCanLevelUp = dataEasy.getCardEffortMax(i, cardId, attrType, effort_advance, level)
				local currVal = effortValue[attrType] or 0
				if maxVal > (currVal - total) then
					isNotAllMax = true
				end
			end
		end
		if not isNotAllMax then
			-- 已经全满级 检查晋升条件
			return isCanLevelUp
		end
		-- 还有努力值可以提升
		-- 检查努力币是否足够
		local normalT = {}
		local specialT = {}
		for i,v in csvMapPairs(normal) do
			table.insert(normalT, {id = i, num = v})
		end
		for i,v in csvMapPairs(special) do
			table.insert(specialT, {id = i, num = v})
		end
		local isNormal = true
		for i,v in ipairs(normalT) do
			if v.id ~= "gold" then
				local currNum = t.items[v.id] or 0
				if isNormal then
					isNormal = v.num <= currNum
				end
			end
		end
		local isSpecial = true
		for i,v in ipairs(specialT) do
			if v.id ~= "gold" then
				local currNum = t.items[v.id] or 0
				if isSpecial then
					isSpecial = v.num <= currNum
				end
			end
		end
		return isNormal or isSpecial
	end)
end

local function isCardCanDevelop(t, cardId, args)
	local level, advance, star = args.level, args.advance, args.star
	local base = csv.base_attribute.develop_level[cardId]
	for k, v in csvMapPairs(base.cost) do
		if k ~= "gold" then
			local currNum = t.items[k] or 0
			if v > currNum then
				return false
			end
		end
	end
	if base.needLevel and base.needLevel ~= 0 and level < base.needLevel then
		return false
	end
	if base.needStar and base.needStar ~= 0 and star < base.needStar then
		return false
	end
	if base.needAdvance and base.needAdvance ~= 0 and advance < base.needAdvance then
		return false
	end
	return true
end

-- @desc:进化红点
-- @t:{selectDbId, items, gold} selectDbId：卡牌dbId, items:背包物品, gold:金币
function redHintHelper.cardDevelop(t)
	local dbid = getCardDBID(t)
	return cache.queryRedHint({"cardDevelop", dbid}, function()
		local ret, cardId, level, advance, star = checkAndGetCardFields(t, isCardInBattleCards, "card_id", "level", "advance", "star")
		if not ret then
			return false
		end

		local cfg = csv.cards[cardId]
		local currMarkID = cfg.cardMarkID
		local currDevelop = cfg.develop
		local currBranch = cfg.branch
		local args = {level = level, advance = advance, star = star}
		local function searchData(data)
			for i,v in pairs(data) do
				if v.canDevelop and v.develop > currDevelop and v.megaIndex == 0 then
					if isCardCanDevelop(t, v.id, args) then
						return true
					end
				end
			end
			return false
		end
		-- 已选择分支
		if currBranch ~= 0 then
			if gCardsCsv[currMarkID][currBranch] then
				return searchData(gCardsCsv[currMarkID][currBranch])
			end
		else
			for i,v in pairs(gCardsCsv[currMarkID]) do
				if searchData(v) then
					return true
				end
			end
		end
		return false
	end)
end

function redHintHelper.cardFeel(t)
	local dbid = getCardDBID(t)
	return cache.queryRedHint({"cardFeel", dbid}, function()
		local ret, cardId = checkAndGetCardFields(t, isCardInBattleCards, "card_id")
		if not ret then
			return false
		end

		local cardCsv = csv.cards[cardId]
		local feelCsv = gGoodFeelCsv[cardCsv.feelType]
		local cardFeel = t.cardFeels[cardCsv.cardMarkID] or {}
		local level = cardFeel.level or 0
		local clientCurLvExp = cardFeel.level_exp or 0
		local maxLimitLv = table.length(gGoodFeelCsv[cardCsv.feelType])
		local feelExp = feelCsv[math.min(level + 1, maxLimitLv)].needExp
		local itemCsv = csv.items
		if level >= maxLimitLv then
			return false
		end
		local allExp = 0
		for _,v in orderCsvPairs(cardCsv.feelItems) do
			local num = t.items[v] or 0
			allExp = num * itemCsv[v].specialArgsMap.feel_exp + allExp
			if clientCurLvExp + allExp >= feelExp then
				return true
			end
		end
		return false
	end)
end

-- @desc:饰品强化红点
-- @t:{selectDbId, items, gold, level} selectDbId：卡牌dbId, items:背包物品, gold:金币, level:角色等级
function redHintHelper.equipStrengthen(t)
	local dbid = getCardDBID(t)
	return cache.queryRedHint({"equipStrengthen", dbid}, function()
		local ret, equips = checkAndGetCardFields(t, isCardInBattleCards, "equips")
		if not ret then
			return false
		end

		for i,v in ipairs(equips) do
			local cfg = csv.equips[v.equip_id]
			local currLevelLimit = cfg.strengthMax[v.advance]
			local newGold = t.gold
			local upLevel = 0
			if v.level < currLevelLimit then
				for i = v.level, currLevelLimit do
					local cost = csv.base_attribute.equip_strength[i]["costGold"..cfg.strengthSeqID]
					newGold = newGold - cost
					if newGold < 0 then
						upLevel = i
						break
					elseif i == currLevelLimit then
						upLevel = currLevelLimit
					end
				end
				if upLevel > v.level then
					return true
				end
			else
				local newT = {}
				local isEnoughItem = true
				local advanceCsv = gEquipAdvanceCsv[v.equip_id][v.advance]
				local currRoleLimitLevel = cfg.roleLevelMax[v.advance]
				if advanceCsv.costGold > t.gold then
					isEnoughItem = false
				end
				for k,num in csvMapPairs(advanceCsv.costItemMap) do
					local hasNum = dataEasy.getNumByKey(k)
					if num > hasNum and isEnoughItem then
						isEnoughItem = false
					end
				end
				if isEnoughItem and t.level >= currRoleLimitLevel then
					return true
				end
			end
		end
		return false
	end)
end

-- @desc:饰品升星红点
-- @t:{selectDbId, items, gold} selectDbId：卡牌dbId, items:背包物品, gold:金币
function redHintHelper.equipStar(t)
	local dbid = getCardDBID(t)
	return cache.queryRedHint({"equipStar", dbid}, function()
		local ret, equips = checkAndGetCardFields(t, isCardInBattleCards, "equips")
		if not ret then
			return false
		end

		for i,v in ipairs(equips) do
			local cfg = csv.equips[v.equip_id]
			local isEnoughItems = true
			for key,num in csvMapPairs(csv.base_attribute.equip_star[v.star]["costItemMap"..cfg.starSeqID]) do
				if key ~= "gold" then
					local hasNum = dataEasy.getNumByKey(key)
					if hasNum < num and isEnoughItems then
						isEnoughItems = false
					end
				else
					if t.gold < num and isEnoughItems then
						isEnoughItems = false
					end
				end
			end
			if isEnoughItems and v.star ~= cfg.starMax then
				return true
			end
		end
		return false
	end)
end

-- @desc:饰品觉醒红点
-- @t:{selectDbId, items} selectDbId：卡牌dbId, items:背包物品
function redHintHelper.equipAwake(t)
	local dbid = getCardDBID(t)
	return cache.queryRedHint({"equipAwake", dbid}, function()
		local ret, equips = checkAndGetCardFields(t, isCardInBattleCards, "equips")
		if not ret then
			return false
		end

		for i,v in ipairs(equips) do
			local cfg = csv.equips[v.equip_id]
			local isEnoughItems = true 	-- 觉醒道具是否足够
			for key,num in csvMapPairs(csv.base_attribute.equip_awake[v.awake]["costItemMap"..cfg.awakeSeqID]) do
				if key ~= "gold" then
					local hasNum = dataEasy.getNumByKey(key)
					if hasNum < num and isEnoughItems then
						isEnoughItems = false
					end
				end
			end

			local isMax = v.awake >= cfg.awakeMax -- 是否达到觉醒上限
			local isLevel =  gGameModel.role:read("level") >= cfg.awakeRoleLevelMax[v.awake + 1] -- 是否达到觉醒等级
			local isAwakeStar = v.star >= cfg.awakeStar[v.awake + 1] 	-- 是否达到觉醒星级
			if isEnoughItems and isLevel and isAwakeStar and not isMax then 	-- 一共四个饰品，只要有一个饰品满足觉醒，则外层显示觉醒红点
				return true
			end
		end
		return false
	end)
end

--饰品刻印红点
function redHintHelper.equipSignet(t)
	local dbid = getCardDBID(t)
	return cache.queryRedHint({"equipSignet", dbid}, function()
		local ret, equips = checkAndGetCardFields(t, isCardInBattleCards, "equips")
		if not ret then
			return false
		end

		for k,val in ipairs(equips) do
			local cfg = csv.equips[val.equip_id]
			local isEnoughItems = true --刻印道具是否足够
			local signet = val.signet or 0
			local signetAdvance = val.signet_advance or 0
			if signet == (signetAdvance + 1) * 5 and signetAdvance < cfg.signetAdvanceMax then
				for i,v in csvPairs(csv.base_attribute.equip_signet_advance) do
					if v.advanceIndex == cfg.advanceIndex and v.advanceLevel == signetAdvance + 1 then
						for key,value in csvMapPairs(csv.base_attribute.equip_signet_advance_cost[signetAdvance]["costItemMap"..v.advanceSeqID]) do
							if key ~= "gold" then
								local hasNum = dataEasy.getNumByKey(key)
								if hasNum < value and isEnoughItems then
									isEnoughItems = false
								end
							else
								if t.gold < value and isEnoughItems then
									isEnoughItems = false
								end
							end
						end
					end
				end
			elseif signet == signetAdvance * 5 and signetAdvance == cfg.signetAdvanceMax then
			else
				for key,value in csvMapPairs(csv.base_attribute.equip_signet[signet]["costItemMap"..cfg.signetStrengthSeqID]) do
					if key ~= "gold" then
						local hasNum = dataEasy.getNumByKey(key)
						if hasNum < value and isEnoughItems then
							isEnoughItems = false
						end
					else
						if t.gold < value and isEnoughItems then
							isEnoughItems = false
						end
					end
				end
			end
			if isEnoughItems and signetAdvance ~= cfg.signetAdvanceMax then
				return true
			end
		end
		return false
	end)
end

local function isMapStarAward(chapterId, mapStar, LorR)
	if not LorR then
		if not mapStar or not mapStar[chapterId] then return false end
		return itertools.first(mapStar[chapterId].star_award, 1) ~= nil
	else
		local isLeft = LorR == "left"
		local targetNum = isLeft and 0 or 999
		local addNum = isLeft and -1 or 1
		local worldMapCsv = csv.world_map
		for i = chapterId, targetNum, addNum do
			if i ~= chapterId and isMapStarAward(i,mapStar) then
				return true
			end
			if not worldMapCsv[i] then
				break
			end
		end
	end
	return false
end
local function isGateStarAward(chapterId, gateStar, LorR, mapType)
	if not LorR then return false end
	local isLeft = LorR == "left"
	local sceneConfig = csv.scene_conf
	for sceneId, value in pairs(gateStar) do
		local config = sceneConfig[sceneId]
		local curChapterId = config and config.ownerId
		if curChapterId and value.chest == 1 then
			local curChapterType = csv.world_map[curChapterId].chapterType		-- 难度要对应
			if isLeft and curChapterId < chapterId and curChapterType == mapType then
				return true
			elseif not isLeft and curChapterId > chapterId and curChapterType == mapType then
				return true
			end
		end
	end
	return false
end

-- @desc:章节礼包红点 右下宝箱
-- @t: {chapterId, mapStar, mapType}mapStar:章节星星信息, chapterId:当前章节id, mapType 1:剧情 2:困难, gateStar:关卡宝箱信息
function redHintHelper.levelRightDownGift(t)
	return isMapStarAward(t.chapterId, t.mapStar)
end

-- @desc:章节礼包红点 右箭头
-- @t: {chapterId, mapStar, mapType}mapStar:章节星星信息, chapterId:当前章节id, mapType 1:剧情 2:困难, gateStar:关卡宝箱信息
function redHintHelper.levelRightBtnGift(t)
	return isMapStarAward(t.chapterId, t.mapStar, "right") or isGateStarAward(t.chapterId, t.gateStar, "right", t.mapType)
end

-- @desc:章节礼包红点 左箭头
-- @t: {chapterId, mapStar, mapType}mapStar:章节星星信息, chapterId:当前章节id, mapType 1:剧情 2:困难, gateStar:关卡宝箱信息
function redHintHelper.levelLeftBtnGift(t)
	return isMapStarAward(t.chapterId, t.mapStar, "left") or isGateStarAward(t.chapterId, t.gateStar, "left", t.mapType)
end

-- @desc:章节礼包红点 剧情按钮
-- @t: {chapterId, mapStar, mapType}mapStar:章节星星信息, chapterId:当前章节id, mapType 1:剧情 2:困难, gateStar:关卡宝箱信息
function redHintHelper.levelBtnJuQingGift(t)
	if t.mapType == 1 then return false end
	if t.mapStar then
		for chapterId, award in pairs(t.mapStar) do
			if chapterId < 100 then
				if itertools.first(award.star_award, 1) ~= nil then
					return true
				end
			end
		end
	end
	if t.gateStar then
		local sceneConfig = csv.scene_conf
		for sceneId, value in pairs(t.gateStar) do
			local config = sceneConfig[sceneId]
			local curChapterId = config and config.ownerId
			if curChapterId and value.chest == 1 then
				if curChapterId < 100 then
					return true
				end
			end
		end
	end
	return false
end

-- @desc:章节礼包红点 困难按钮
-- @t: {chapterId, mapStar, mapType}mapStar:章节星星信息, chapterId:当前章节id, mapType 1:剧情 2:困难, gateStar:关卡宝箱信息
function redHintHelper.levelBtnKunNanGift(t)
	if t.mapType == 2 then return false end
	if t.mapStar then
		for chapterId, award in pairs(t.mapStar) do
			if chapterId > 100 and chapterId < 200 then
				if itertools.first(award.star_award, 1) ~= nil then
					return true
				end
			end
		end
	end
	if t.gateStar then
		local sceneConfig = csv.scene_conf
		for sceneId, value in pairs(t.gateStar) do
			local config = sceneConfig[sceneId]
			local curChapterId = config and config.ownerId
			if curChapterId and value.chest == 1 then
				if curChapterId > 100 and curChapterId < 200 then
					return true
				end
			end
		end
	end
	return false
end

-- @desc:章节礼包红点 噩梦按钮
-- @t: {chapterId, mapStar, mapType}mapStar:章节星星信息, chapterId:当前章节id, mapType 1:剧情 2:困难, gateStar:关卡宝箱信息
function redHintHelper.levelBtnNightMareGift(t)
	if t.mapType == 3 then return false end
	if t.mapStar then
		for chapterId, award in pairs(t.mapStar) do
			if chapterId > 200 then
				if itertools.first(award.star_award, 1) ~= nil then
					return true
				end
			end
		end
	end
	if t.gateStar then
		local sceneConfig = csv.scene_conf
		for sceneId, value in pairs(t.gateStar) do
			local config = sceneConfig[sceneId]
			local curChapterId = config and config.ownerId
			if curChapterId and value.chest == 1 then
				if curChapterId > 200 then
					return true
				end
			end
		end
	end
	return false
end

-- @desc: 天赋的tabList的红点显示
-- @t:{talentTree, talentPoint} talentTree:天赋树, talentPoint:天赋点
--@tabId: 天赋树id
local function specialTalentView(t, tabId)
	local pointMin = 0
	local baseTree = t.talentTree[tabId]
	local state = true
	if baseTree and baseTree['talent'] then
		for k,v in pairs(baseTree['talent']) do
			local cfgCost = csv.talent_cost[v]
			state = state and v == 10
			local costID = csv.talent[k].costID
			local costTalent = cfgCost["costTalent" .. costID]
			if pointMin == 0 then
				pointMin = costTalent
			else
				pointMin = math.min(pointMin, costTalent)
			end
		end
	end
	if t.talentPoint >= pointMin and pointMin > 0 and not state then
		return true
	end
	return false
end

-- @desc:主界面天赋红点
-- @t: {talentTree, talentPoint} talentTree:天赋树, talentPoint:天赋点
function redHintHelper.cityTalent(t)
	local level = gGameModel.role:read("level")
	for tabId, v in orderCsvPairs(csv.talent_tree) do
		if matchLanguage(v.languages) and level >= v.showLevel then
			local state = specialTalentView(t, tabId)
			if state then
				return true
			end
		end
	end
	return false
end

-- @desc:主界面关卡红点
-- @t:{gateStar, mapStar} gateStar:gate_star, mapStar:map_star
function redHintHelper.pve(t)
	for k,v in pairs(t.gateStar) do
		if v.chest and v.chest == 1 then
			return true
		end
	end

	for k,v in pairs(t.mapStar) do
		if itertools.first(v.star_award, 1) ~= nil then
			return true
		end
	end
	return false
end

--派遣任务红点
-- @t:{dispatchTasks, dispatchTasksRefresh} dispatchTasks:派遣任务数据，dispatchTasksNextAutoTime:记录的最近一次打开派遣任务界面时，派遣任务下次自动属性时间
function redHintHelper.dispatchTask(t)
	for k,v in ipairs(t.dispatchTasks) do
		-- 客户端status1可领取 2可接取 3进行中 4已领取
		-- 服务器1已完成 2可接取 3进行中
		local subTime = (v.ending_time or 0) - time.getTime()
		if v.status == 3 and subTime <= 0 then
			return true
		end
	end

	if time.getTime() >= t.dispatchTasksNextAutoTime then 	-- 当前时间大于派遣任务记录的下次自动刷新时间，表示派遣任务已自动刷新过，需要显示红点
		return true
	end

	return false
end

-- @desc:主界面签到红点
-- @t:{roleSignInGift, signInGift, vipLevel, signInBuyAwards, signIn, lastSignInAward}
function redHintHelper.signIn(t)
	local state = t.roleSignInGift[2] == 1
	if state then
		return state
	end
	for i = 1, 3 do
		if type(t.signInGift[100+i]) == "number" and t.signInGift[100+i] == 1 then
			return true
		end
	end
	local currDay = t.currDay

	if currDay == tonumber(time.getDate(time.getTime()).day) then
		local function vipStateChange(csvID, isDouble, vipLevel)
			local vipDouble = csv.signin[csvID].vipDouble
			vipDouble = vipDouble ~= 9999 and vipDouble
			return isDouble == 1 and vipDouble and vipLevel >= vipDouble
		end
		if t.signInAwards and t.signInAwards[currDay] then
			for csvID, isDouble in pairs(t.signInAwards[currDay]) do
				if vipStateChange(csvID, isDouble, t.vipLevel) then
					return true
				end
			end
		end
	end
	return false
end

-- @desc:精灵背包下方卡牌红点
-- @t:{items, frags} items:背包物品, frags:碎片
function redHintHelper.totalCard(t)
	if t.type and t.type == SHOW_TYPE.CARD then
		return false
	end

	local unlockTb = {}
	local unlockKeys = {
		advance = 0,
		effortValue = gUnlockCsv.cardEffort,
		equipAwake = gUnlockCsv.equipAwak,
		equipStar = gUnlockCsv.equipStarAdd,
		equipStrengthen = gUnlockCsv.equip,
		equipSignet = gUnlockCsv.equipSignet,
		star = 0,
		skill = 0,
		nvalue = gUnlockCsv.cardNValueRecast,
		cardFeel = gUnlockCsv.cardLike,
		cardDevelop = 0,
		gemFreeExtract = gUnlockCsv.gem,
		canZawake = gUnlockCsv.zawake,
	}


	for i, dbid in ipairs(t.cards) do
		local card = gGameModel.cards:find(dbid)
		if card and isCardInBattleCards(dbid) then
			local dt = clone(t)
			dt.selectDbId = dbid
			-- 特殊逻辑特殊处理 在外部检测unlock
			for key, unlockKey in pairs(unlockKeys) do
				local isUnlock = true
				if unlockKey ~= 0 then
					if unlockTb[unlockKey] == nil then
						unlockTb[unlockKey] = dataEasy.isUnlock(unlockKey)
					end
					isUnlock = unlockTb[unlockKey]
				end

				if isUnlock and redHintHelper[key](dt) then
					return true
				end
			end
		end
	end
	return false
end

-- @desc:精灵养成碎片红点
-- @t:{type, frags} frags:碎片 type展示类型
function redHintHelper.bottomFragment(t)
	if t.type and t.type == SHOW_TYPE.FRAGMENT then
		return false
	end
	for k,v in pairs(t.frags) do
		local fragCsv = csv.fragments[k]
		-- 筛选碎片类型，只能是精灵碎片
		if fragCsv.type == 1 and v >= fragCsv.combCount then
			return true
		end
	end
	return false
end

-- @desc:特权礼包
-- @t:{vipGift} vipGift:今天是否已经点击过
function redHintHelper.vipGift(t)
	return t.vipGiftClick ~= true
end

-- @desc:招财猫
-- @t:{luckyCat} luckyCat:今天是否已经点击过
function redHintHelper.luckyCat(t)
	local activityId = t.activityId
	if not activityId then
		return false
	end
	return t.luckyCatClick ~= true
end

-- @desc:金币招财猫
-- @t:{goldLuckyCat} goldLuckyCat:今天是否已经点击过
function redHintHelper.goldLuckyCat(t)
	local activityId = t.activityId
	if not activityId then
		return false
	end
	return t.goldLuckyCatClick ~= true
end


-- @desc:限时通行证
-- @t:{currdayPassport} currdayPassport:今天是否已经点击过
function redHintHelper.passportCurrDay(t)
	local activityId = t.activityId
	if not activityId then
		return false
	end
	local awardCfg = {}  -- 奖励表
	local yyCfg = csv.yunying.yyhuodong[activityId]
	for k,v in orderCsvPairs(csv.yunying.passport_award) do
		if v.huodongID == yyCfg.huodongID then
			table.insert(awardCfg, {cfg = v, custom = {csvId = k}}) -- cfg为表原始数据，custom为添加的自定义数据
		end
	end
	local max = #awardCfg
	local isMaxLv = max == t.rolePassport.level
	if isMaxLv then
		return false
	end
	return t.currdayPassport ~= true
end

-- @desc:限时通行证奖励tab
-- @t:{passporto} passport:通行证信息
function redHintHelper.passportReward(t)
	local activityId = t.activityId
	if not activityId then
		return false
	end
	-- 是否有奖励可领取
	-- 1、普通奖励
	for _, normalState in pairs(t.rolePassport.normal_award or {}) do
		if normalState == 1 then -- 1可领取
			return true
		end
	end
	-- 2、进阶奖励
	for _, eliteState in pairs(t.rolePassport.elite_award or {}) do
		if eliteState == 1 then
			return true
		end
	end

	return false
end
-- @desc:限时通行证任务tab
-- @t:{passport} passport:通行证信息
function redHintHelper.passportTask(t)
	local activityId = t.activityId
	if not activityId then
		return false
	end
	-- 任务奖励
	local buyMaster = itertools.size(t.rolePassport.buy) > 0
	local awardCfg = {}  -- 奖励表
	local yyCfg = csv.yunying.yyhuodong[activityId]
	for k,v in orderCsvPairs(csv.yunying.passport_award) do
		if v.huodongID == yyCfg.huodongID then
			table.insert(awardCfg, {cfg = v, custom = {csvId = k}}) -- cfg为表原始数据，custom为添加的自定义数据
		end
	end
	local max = #awardCfg
	local isMaxLv = max == t.rolePassport.level
	if isMaxLv then
		return false
	end
	for csvID, info in pairs(t.rolePassport.task or {}) do
		if info[2] == 1 then -- 任务参数 info[2] == 1 表示该任务可领取奖励
			local cfg = csv.yunying.passport_task[csvID]
			if cfg.taskAttribute == 3 or buyMaster then
				return true
			end
		end
	end
	return false
end


-- @desc: 好友体力领取红点
-- @t: {staminaRecv} staminaRecv:体力领取列表
function redHintHelper.friendStaminaRecv(t)
	if t.staminaGain >= game.FRIEND_STAMINA_GET_TIMES then
		return false
	end
	local hash = arraytools.hash(t.staminaRecv)
	for _, friend in ipairs(t.friends) do
		if hash[friend] then
			return true
		end
	end
	return false
end

-- @desc:好友申请红点
-- @t: {friendReqs} friendReqs:申请列表
function redHintHelper.friendReqs(t)
	return itertools.size(t.friendAddReqs) > 0
end

-- @desc:主界面邮件红点
-- @t:{mailBox} mailBox:未读邮件们
function redHintHelper.mail(t)
	return itertools.size(t.mailBox) > 0
end

-- 嘉年华当天是否还存在道具贩卖
local function serverOpenDayItemBuyExist(t, id, cfg, curDay)
	local activityId = t.id or t.activityId
	local detail = t.yyHuodongs[activityId]
	local valinfo = detail.valinfo or {}
	local _, startTime = time.getActivityOpenDate(activityId)
	if not startTime then
		return false
	end
	local countdown = time.getTime() - startTime
	-- day 从0开始表示第一个，上层定义
	local day = tonumber(time.getCutDown(countdown).day)
	local dt = valinfo[id] or {}
	local hasBuy = dt.times and dt.times > 0
	local hasIn = t.serverOpenItemBuy and t.serverOpenItemBuy[id]
	if not hasBuy and not hasIn then
		-- countType 任务计数类型 (1-强制计数; 2-只有当天计数; 3-当天开始后计数)
		if cfg.countType == 2 and day == curDay then
			return true
		end
		if cfg.countType ~= 2 and day >= curDay then
			return true
		end
	end
	return false
end

-- @desc:主界面嘉年华红点
-- @t:{yyOpen, rmb} yyOpen:开启活动 rmb:钻石
function redHintHelper.serverOpen(t)
	local activityId = t.activityId
	if t.yyHuodongs[activityId] then
		local detail = t.yyHuodongs[activityId]
		if detail.stamps then
			for k,v in pairs(detail.stamps) do
				if v == 1 then
					return true
				end
			end
		end

		local _, startTime = time.getActivityOpenDate(activityId)
		if not startTime then
			return false
		end

		local huodongID = csv.yunying.yyhuodong[activityId].huodongID
		for id, cfg in orderCsvPairs(csv.yunying.serveropen) do
			if cfg.huodongID  == huodongID and cfg.taskType == game.TARGET_TYPE.ItemBuy then
				t.id = activityId
				if serverOpenDayItemBuyExist(t, id, cfg, cfg.daySum - 1) then
					return true
				end
			end
		end
	end

	return false
end

-- @desc:嘉年华上方天数红点
-- @t:{yyHuodongs, rmb, originData, id} yyHuodongs:活动 rmb:钻石 originData:嘉年华组装数据, id:嘉年华id
function redHintHelper.serverOpenDay(t, index)
	if t.yyHuodongs[t.id] then
		local detail = t.yyHuodongs[t.id]
		local stamps = detail.stamps or {}
		local discount
		for k,v in pairs(t.originData[index]) do
			for i,data in ipairs(v) do
				if stamps[data.id] == 1 then
					return true
				end
				if data.cfg.taskType == game.TARGET_TYPE.ItemBuy then
					discount = data
				end
			end
		end
		if discount then
			return serverOpenDayItemBuyExist(t, discount.id, discount.cfg, index)
		end
	end
	return false
end

-- @desc:探险器主界面下方红点
-- @t:{explorers, items} explorers:探险器数据 items:背包物品
function redHintHelper.explorerShow(t, id)
	id = id or t.id
	local newT = {}
	local cfg = csv.explorer.explorer[id]
	newT.cfg = cfg
	for index, component in ipairs(newT.cfg.componentIDs) do
		local componentCfg = csv.explorer.component[component]
		local level = 0
		if t.explorers[id] and t.explorers[id].components and t.explorers[id].components[component] then
			level = t.explorers[id].components[component]
		end
		local count = 0
		if t.items[componentCfg.itemID] then
			count = t.items[componentCfg.itemID]
		end
		newT.components = newT.components or {}
		newT.components[componentCfg.componentPosID] = {
			id = component,
			count = count,
			level = level,
		}

	end
	local advance = 0
	if t.explorers[id] and t.explorers[id].advance then
		advance = t.explorers[id].advance
	end
	newT.advance = advance
	if newT.advance == newT.cfg.levelMax then
		return false
	else
		local minLevel = 100
		--组件升级
		for i, v in ipairs(newT.components) do
			minLevel = math.min(minLevel, v.level)
			if v.level == 0 and v.count > 0 then
				return true
			elseif v.level ~= newT.cfg.levelMax then
				local t = {}
				local cfg = csv.explorer.component[v.id]
				local isCanUp = true
				for k, v in csvMapPairs(csv.explorer.component_level[v.level + 1]["costItemMap"..cfg.strengthCostSeq]) do
					if isCanUp then
						isCanUp = dataEasy.getNumByKey(k) >= v
					end
				end
				if isCanUp then
					return true
				end
			end
		end
		--探险器进阶
		if newT.advance < minLevel then
			local t = {}
			local isCanUp = true
			for k, v in csvMapPairs(csv.explorer.explorer_advance[newT.advance + 1]["costItemMap"..newT.cfg.advanceCostSeq]) do
				table.insert(t, {id = k, targetNum = v, num = dataEasy.getNumByKey(k)})
				if isCanUp then
					isCanUp = dataEasy.getNumByKey(k) >= v
				end
			end
			if isCanUp then
				return true
			end
		end
	end
	return false
end

-- @desc:主界面探险器红点
-- @t:{explorers, items} explorers:探险器数据 items:背包物品
function redHintHelper.explorerTotal(t)
	for k,v in orderCsvPairs(csv.explorer.explorer) do
		if redHintHelper.explorerShow(t, k) then
			return true
		end
	end
	return false
end

-- @desc:探险器寻宝红点
-- @t:{itemDC1FreeCounter} itemDC1FreeCounter: 免费寻宝已使用次数
function redHintHelper.explorerFind(t)
	local val = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.DrawItemFreeTimes)
	-- 总次数小于免费次数+特权次数
	if t.itemDC1FreeCounter < val + 1 then
		return true
	end
	return false
end

-- @desc:训练家红点
--@t:{trainerGiftTimes} trainerGiftTimes: 训练家每日礼包次数
function redHintHelper.cityTrainer(t)
	return t.trainerGiftTimes == 0
end

-- @desc:嘉年华左侧tab红点
-- @t:{yyHuodongs, rmb, originData, id, day, serverOpenItemBuy} yyHuodongs:活动 rmb:钻石 originData:嘉年华组装数据, id:嘉年华id, day:当前天数, serverOpenItemBuy:开服活动是否点击过记录集合
function redHintHelper.serverOpenCurrDay(t)
	if not (t.originData and t.day and t.id) then
		return false
	end

	local index = math.min(t.index, itertools.size(t.originData[t.day]) - 1)

	if t.yyHuodongs[t.id] then
		local detail = t.yyHuodongs[t.id] or {}
		local stamps = detail.stamps or {}
		local discount
		for i,data in ipairs(t.originData[t.day][index]) do
			if stamps[data.id] == 1 then -- 存在可领取的礼包
				return true
			end
			if data.cfg.taskType == game.TARGET_TYPE.ItemBuy then
				discount = data
			end
		end
		if discount then
			return serverOpenDayItemBuyExist(t, discount.id, discount.cfg, t.day)
		end
	end
	return false
end

-- @desc:首冲红点
-- @t:{firstRecharge} firstRecharge:今天是否点击
function redHintHelper.firstRecharge(t)
	local activityId = t.activityId
	if not activityId then
		return false
	end
	local isAllAwardGet = true
	for _, id in pairs(t.yyOpen) do
		local cfg = csv.yunying.yyhuodong[id]
		if (cfg.independent == 1) and cfg.type == YY_TYPE.firstRecharge then
			local huodong = t.yyHuodongs[id] or {}
			if huodong.flag == 1 then
				return true
			end
			if huodong.flag ~= 2 then
				isAllAwardGet = false
			end
		end
	end
	return not t.firstRechargeClick and not isAllAwardGet
end

-- @desc:每日充值活动
function redHintHelper.firstRechargeDaily(t)
	local activityId = t.activityId
	if activityId and not t.firstRechargeDailyClick[activityId] then
		return true
	end
	if t.yyHuodongs[activityId] then
		local stamps = t.yyHuodongs[activityId].stamps or {}
		local yyCfg = csv.yunying.yyhuodong[activityId]
		local huodongID = yyCfg.huodongID
		for k, v in csvPairs(csv.yunying.generaltask) do
			if v.huodongID == huodongID then
				-- yydata.stamps[k] : 1:可领取，0：已领取，其他：不可领取
				if stamps[k] == 1 then
					return true
				end
			end
		end
	end
	return false
end

function redHintHelper.exclusiveLimit(t)
	return t.exclusiveLimitClick ~= true
end

function redHintHelper.customizeGift(t)
	return t.customizeGiftClick ~= true
end

-- @desc:公会红包红点
-- --@t:{systemRedPacket,memberRedPacket,sendedRedPacket,redPacketRobCount,unionRedpackets,unionLevel}
-- --@t:systemRedPacket:是否有系统红包可领，memberRedPacket:是否有成员红包可领，sendedRedPacket:今天是否有点击发红包页签
-- --@t:redPacketRobCount:今天领取成员红包的数量，unionRedpackets:可发红包的数具，unionLevel:公会等级
local function isUnionRedpacketUnlock(t)
	local unLockLv = gUnionFeatureCsv.redpacket or 0
	local isLock = unLockLv == 0 or unLockLv > t.unionLevel
	return not (isLock or dataEasy.notUseUnionBuild())
end

--系统红包
function redHintHelper.unionSystemRedPacket(t)
	if not t.unionId then return false end
	if not isUnionRedpacketUnlock(t) then return false end
	if not dataEasy.canSystemRedPacket() then
		return false
	end
	return t.systemRedPacket
end
--成员红包
function redHintHelper.unionMemberRedPacket(t)
	if not t.unionId then return false end
	if not isUnionRedpacketUnlock(t) then return false end
	local maxNum = gCommonConfigCsv.unionRobRedpacketDailyLimit
	--有可领红包并且抢红包数量没达到上限
	return t.memberRedPacket and maxNum > t.redPacketRobCount
end
--发红包
function redHintHelper.unionSendedRedPacket(t)
	if not t.unionId then return false end
	if not isUnionRedpacketUnlock(t) then return false end
	--今天没点击过并且有可发红包
	return not t.sendedRedPacket and itertools.size(t.unionRedpackets) > 0
end

function redHintHelper.unionDailyGift(t)
	if not t.unionId then return false end
	local unLockLv = gUnionFeatureCsv.dailygift or 0
	local isLock = unLockLv == 0 or unLockLv > t.unionLevel
	if dataEasy.notUseUnionBuild() or isLock then
		return false
	end

	return t.unionDailyGiftTimes <= 0
end

function redHintHelper.unionLobby(t)
	if not t.unionId then return false end
	local roleId = t.roleId
	if (t.chairmanId == roleId or itertools.include(t.viceChairmans, roleId))
			and itertools.size(t.joinNotes) > 0 then
		return true
	end
	return false
end

function redHintHelper.unionFragDonate(t)
	if not t.unionId then return false end
	local unLockLv = gUnionFeatureCsv.fragdonate or 0
	local isLock = unLockLv == 0 or unLockLv > t.unionLevel
	if dataEasy.notUseUnionBuild() or isLock then
		return false
	end
	local cache = {}
	for _,v in pairs(t.unionFragDonateAwards) do
		if v == 1 then
			return true
		end
	end

	-- 是否可以许愿
	if t.unionFragDonateStartTimes == 0 then
		return true
	end

	return false
end
function redHintHelper.unionContribute(t)
	if not t.unionId then return false end
	local unLockLv = gUnionFeatureCsv.contribute or 0
	local isLock = unLockLv == 0 or unLockLv > t.unionLevel
	if dataEasy.notUseUnionBuild() or isLock then
		return false
	end
	local contribMax = csv.union.union_level[t.unionLevel].ContribMax
	if t.unionTimes < contribMax then
		return true
	end
	local cache = {} -- 记录所有任务的领取状态
	for k,v in pairs(t.allUnionTask) do
		local value = v[1] -- 完成进度
		local state = v[2] -- 0 不可领取 1 可领取 2 已领取
		cache[k] = state
		if state == 1 then
			return true
		end
	end

	for k,v in pairs(t.unionTask) do
		local value = v[1]
		local state = v[2] -- 0 不可领取 1 可领取 2 已领取(unionTask 中不会有2)
		if v[2] == 1 and (cache[k] ~= 2) then
			return true
		end
	end

	return false
	-- 去掉每日任务没完成有红点的逻辑
	-- if hasFinishedTask then
	-- 	return true
	-- end
	-- local hasTask = false
	-- for k,v in orderCsvPairs(csv.union.union_task) do
	-- 	-- 每日任务
	-- 	if v.type == 1 and not cache[k] then
	-- 		hasTask = true
	-- 		break
	-- 	end
	-- end
	-- return hasTask
end

function redHintHelper.unionFuben(t)
	if not t.unionId then return false end
	local unLockLv = gUnionFeatureCsv.fuben or 0
	local isLock = unLockLv == 0 or unLockLv > t.unionLevel
	if dataEasy.notUseUnionBuild() or isLock then
		return false
	end
	-- 是否有可领取的奖励
	if dataEasy.haveUnionFubenReward() then
		return true
	end

	-- 判断是否在开启时间
	local ct = time.getTimeTable()
	local t1 = ct.hour * 100 + ct.min
	if ct.wday == 1 or t1 < 930 or t1 > 2330 then
		return false
	end

	-- 是否有剩余挑战次数
	return math.max(3 - t.unionFbTime, 0) > 0
end


function redHintHelper.unionTraining(t)
	if not t.unionId or
			(not gUnionFeatureCsv.training or gUnionFeatureCsv.training > t.unionLevel) or -- 训练中心特写
			dataEasy.notUseUnionBuild() then
		return false
	end
	local unionTraining = gGameModel.union_training
	if unionTraining then
		local trainSpeedUp = gGameModel.daily_record:read("union_training_speedup")
		if trainSpeedUp < 6 then
			return true
		end
		for k,v in csvPairs(csv.union.training) do
			-- 栏位有空
			if t.opened[k] and not t.slots[k] then
				return true
			end
			if t.slots[k] and t.slots[k].level >= t.level then
				return true
			end
		end
	end

	return false
end

function redHintHelper.heldItemLevelUp(t)
	local heldItem
	if t.selectDbId then
		local card = gGameModel.cards:find(t.selectDbId)
		local dbId = card:read("held_item")
		heldItem = gGameModel.held_items:find(dbId)
	elseif t.curDbId then
		local dbId = t.curDbId
		if type(t.curDbId) == "table" then
			dbId = t.curDbId[1]
		end
		heldItem = gGameModel.held_items:find(dbId)
	end
	if not heldItem then
		return false
	end
	if t.checkDress then
		local data = heldItem:read("exist_flag", "card_db_id")
		if not data.exist_flag or not data.card_db_id then
			return false
		end
	end
	local data = heldItem:read("level", "advance", "held_item_id")
	local cfg = csv.held_item.items[data.held_item_id]
	-- 是否可升级
	if data.level < cfg.strengthMax then
		local nextExp = csv.held_item.level[data.level]["levelExp" .. cfg.strengthSeqID]
		local all = 0
		for _, v in ipairs(gHeldItemExpCsv) do
			local myNum = dataEasy.getNumByKey(v.id)
			local cfg2 = dataEasy.getCfgByKey(v.id)
			local single = cfg2.specialArgsMap.heldItemExp
			all = all + single * myNum
			if all >= nextExp then
				return true
			end
		end
		-- 不需要判断其他携带道具的转化
		-- for _,dbId in ipairs(t.heldItems) do
		-- 	local heldItemData = gGameModel.held_items:find(dbId):read("exist_flag", "advance", "level", "sum_exp", "card_db_id", "held_item_id")
		-- 	if heldItemData.advance == 0 and heldItemData.sum_exp == 0 and not heldItemData.card_db_id and heldItemData.exist_flag and dbId ~= t.selectDbId then
		-- 		local cfg = csv.held_item.items[heldItemData.held_item_id]
		-- 		all = all + cfg.heldItemExp
		-- 		if all >= nextExp then
		-- 			return true
		-- 		end
		-- 	end
		-- end
	end

	return false
end

function redHintHelper.heldItemAdvanceUp(t)
	local heldItem
	if t.selectDbId then
		local card = gGameModel.cards:find(t.selectDbId)
		local dbId = card:read("held_item")
		heldItem = gGameModel.held_items:find(dbId)
	elseif t.curDbId then
		local dbId = t.curDbId
		if type(t.curDbId) == "table" then
			dbId = t.curDbId[1]
		end
		heldItem = gGameModel.held_items:find(dbId)
	end
	if not heldItem then
		return false
	end
	if t.checkDress then
		local data = heldItem:read("exist_flag", "card_db_id")
		if not data.exist_flag or not data.card_db_id then
			return false
		end
	end
	local data = heldItem:read("level", "advance", "held_item_id", "card_db_id")
	local cfg = csv.held_item.items[data.held_item_id]
	-- 是否可进阶
	if data.advance < cfg.advanceMax and data.level >= cfg.advanceLvLimit[data.advance + 1] then
		-- 未穿戴的数量
		local myItems = {}
		for _,v in pairs(t.heldItems) do
			local heldItem = gGameModel.held_items:find(v)
			if heldItem then
				local itemData = heldItem:read("held_item_id", "card_db_id", "exist_flag")
				if itemData.exist_flag and not itemData.card_db_id then
					myItems[itemData.held_item_id] = (myItems[itemData.held_item_id] or 0) + 1
				end
			end
		end
		local nextCost = csv.held_item.advance[data.advance]["costItemMap" .. cfg.advanceSeqID]
		-- 减去当前选中的数量
		if not data.card_db_id then
			myItems[data.held_item_id] = math.max(0, (myItems[data.held_item_id] or 0) - 1)
		end
		for k,v in csvMapPairs(nextCost) do
			if (myItems[k] or 0) < v then
				return false
			end
		end
		return true
	end

	return false
end

function redHintHelper.heldItem(t)
	if not isCardInBattleCards(t.selectDbId) then
		return false
	end
	local ret, heldItem = checkAndGetCardFields(t, isCardInBattleCards, "held_item")
	if not ret then
		return false
	end
	if not heldItem then
		for _,dbId in ipairs(t.heldItems) do
			local heldItemData = gGameModel.held_items:find(dbId):read("exist_flag", "card_db_id")
			if heldItemData.exist_flag and not heldItemData.card_db_id then
				return true
			end
		end
	end
	return false
end

-- @desc:随机塔
-- @t:{randomTowerClick, randomTowerPointAward} randomTowerClick:今天是否点击
function redHintHelper.randomTower(t)
	if not t.randomTowerClick then
		return true
	end
	return redHintHelper.randomTowerPoint(t)
end

-- @desc:随机塔 有累积积分奖励可以领
-- @t:{randomTowerPointAward}
function redHintHelper.randomTowerPoint(t)
	for _, v in pairs(t.randomTowerPointAward or {}) do
		if v == 1 then
			return true
		end
	end
	return false
end

-- @desc:限时捕捉精灵
-- @t:{limitSprites}
function redHintHelper.limitCapture(t)
	for _, v in pairs(t.limitSprites or {}) do
		if csv.capture.sprite[v.csv_id] then
			local endTime = v.find_time + csv.capture.sprite[v.csv_id].time
			local totalTimes = csv.capture.sprite[v.csv_id].totalTimes
			--状态 1 可捕捉 0 不可捕捉
			if v.state == 1 and (endTime > time.getTime()) and totalTimes - v.total_times > 0 then
				return true
			end
		end
	end
	return false
end

function redHintHelper.drawcardDiamondFree(t)
	return t.rmbFreeCount < 1
end

function redHintHelper.drawcardGoldFree(t)
	local result = false
	if gCommonConfigCsv.drawGoldFreeLimit > t.goldFreeCount then
		result = (time.getTime() - t.lastDrawTime) >= gCommonConfigCsv.drawGoldFreeRefreshDuration
	end

	if result then
		return result
	end
	local addNum = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.FreeGoldDrawCardTimes)

	return addNum > t.trainerCount
end

function redHintHelper.drawcardEquipFree(t)
	return t.equipFreeCount < 1
end

function redHintHelper.drawcardOnece(t)
	if t.curType == "diamond" then
		return redHintHelper.drawcardDiamondFree(t)
	elseif t.curType == "gold" then
		return redHintHelper.drawcardGoldFree(t)
	elseif t.curType == "equip" then
		return redHintHelper.drawcardEquipFree(t)
	end

	return false
end

-- 限时神兽是否有免费票
function redHintHelper.limitSpritesHasFreeDrawCard(t)
	local activityId = t.activityId
	local endTime = t.yyEndTime[activityId]
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local endTime = time.getNumTimestamp(yyCfg.beginDate,21,30) + 2*24*60*60
	if endTime <= time.getTime() then
		return false
	end

	return t.limitBoxFreeCounter < 1
end

-- 限时神兽是否有积分箱子未领取
function redHintHelper.limitSpritesHasBoxAward(t)
	local yyhuodongs = t.yyHuodongs
	for _, id in ipairs(t.yyOpen) do
		local cfg = csv.yunying.yyhuodong[id]
		if cfg.type == YY_TYPE.timeLimitBox then
			local tb = yyhuodongs[id] or {}
			for _, state in pairs(tb.stamps or {}) do
				if state == 1 then
					return true
				end
			end
			break
		end
	end
	return false
end

-- 充值回馈 新手活动红点
function redHintHelper.loginWealRedHint(t)
	local GET_TYPE = {
		GOTTEN = 0, 	--已领取
		CAN_GOTTEN = 1, --可领取
		CAN_NOT_GOTTEN = 2, --未完成
	}
	local id = t.activityId
	local yydata = t.yyHuodongs[id]
	local stamps = yydata.stamps or {}
	for actId, state in pairs(stamps) do
		if state == GET_TYPE.CAN_GOTTEN then
			return true
		end
	end
	return false
end
-- -- 充值回馈 七天登陆红点
function redHintHelper.loginGiftRedHint(t)
	local GET_TYPE = {
		GOTTEN = 0, 	--已领取
		CAN_GOTTEN = 1, --可领取
		CAN_NOT_GOTTEN = 2, --未完成
	}
	local id = t.activityId
	local yydata = t.yyHuodongs[id] or {}
	local stamps = yydata.stamps or {}
	for actId, state in pairs(stamps) do
		if state == GET_TYPE.CAN_GOTTEN then
			return true
		end
	end
	return false
end

--充值回馈 充值大转盘红点
function redHintHelper.rechargeWheel(t)
	local yyhuodong = t.yyHuodongs[t.activityId]
	local paramMap = csv.yunying.yyhuodong[t.activityId].paramMap
	local scoreDrawTimes = 0
	if yyhuodong and yyhuodong.info then
		local info = yyhuodong.info
		local totalScore = info.total_score or 0
		scoreDrawTimes = math.floor(totalScore/paramMap.costScore)
	end
	return scoreDrawTimes > 0
end

--充值回馈 充值大转盘-免费红点
function redHintHelper.rechargeWheelFree(t)
	local yyhuodong = t.yyHuodongs[t.activityId]
	local paramMap = csv.yunying.yyhuodong[t.activityId].paramMap
	local freeDrawTimes = 0
	if yyhuodong and yyhuodong.info then
		local info = yyhuodong.info
		local freeCounter = info.free_counter or 0
		freeDrawTimes = paramMap.free - freeCounter
	end
	return freeDrawTimes > 0
end

--# 春节红包红点
--# 有发红包次数有红点
--# 有抢红包次数有红点
function redHintHelper.festivalRedHint(t)
	local getVipNum = gVipCsv[t.vipLevel].huodongRedPacketRob
	local sendVipNum = gVipCsv[t.vipLevel].huodongRedPacketSend
	if t.sendredPacket < sendVipNum then
		return true
	elseif t.getredPacket < getVipNum then
		return true
	end
	return false
end

function redHintHelper.crossFestivalRedHint(t)
	local getVipNum = gVipCsv[t.vipLevel].huodongRedPacketRob
	local sendVipNum = gVipCsv[t.vipLevel].huodongRedPacketSend
	if t.sendredCrossPacket < sendVipNum then
		return true
	elseif t.getredCrossPacket < getVipNum then
		return true
	end
	return false
end

--充值回馈 活跃夺宝红点
function redHintHelper.livenessWheel(t)
	local yyhuodong = t.yyHuodongs[t.activityId]
	local paramMap = csv.yunying.yyhuodong[t.activityId].paramMap
	local drawTimes = 0
	local freeDrawTimes = 1  -- 免费上限固定1次(已和策划确认，不会更改，故写死在这里)
	if yyhuodong and yyhuodong.info then
		local info = yyhuodong.info
		local freeCounter = info.free_counter or 0
		drawTimes = info.total_times or 0
		freeDrawTimes = 1 - freeCounter
	end
	if freeDrawTimes > 0 or drawTimes > 0 then
		return true
	end
	return false
end

-- 单笔充钻石返还红点
function redHintHelper.onceRechargeAward(t)
	-- 单笔充值商品状态
	local RECHARGE_STATE = {
		got = 0,  	 -- 已领取
		get = 1, 	 -- 可领取
		none = 2, 	-- 不可领取
	}

	local yydata = t.yyHuodongs[t.activityId] or {}
	local stamps = yydata.stamps or {}
	for k, v in pairs(stamps) do
		if v == RECHARGE_STATE.get then
			return true
		end
	end
	return false
end

function redHintHelper.luckyEggDrawCardFree(t)
	return t.luckyEggFreeCount < 1
end

function redHintHelper.luckyEggScoreShop(t)
	local activityId = t.activityId
	if not activityId then return false end
	local yyhuodong = t.yyHuodongs[activityId] or {}
	local steps = yyhuodong.stamps or {}
	local huodongID = csv.yunying.yyhuodong[activityId].huodongID
	local minScore = math.huge
	for k, cfg in csvPairs(csv.yunying.itemexchange) do
		if cfg.huodongID == huodongID then
			local key, num = csvNext(cfg.items)
			local cKey, cNum = csvNext(cfg.costMap)
			local step = steps[k] or 0
			if cfg.exchangeTimes - step > 0 then
				minScore = math.min(minScore, cNum)
			end
		end
	end

	return minScore <= dataEasy.getNumByKey(game.ITEM_TICKET.luckyEggScore)
end

function redHintHelper.unionFightSignUp(t)
	if not t.unionId then
		return false
	end

	local key = "unionFight"
	if not dataEasy.isInServer(key) then
		return false
	end

	local cfg
	for id, v in csvPairs(csv.pvpandpve) do
		if v.unlockFeature == key then
			cfg = v
			break
		end
	end

	if not cfg then return false end

	local day = getCsv(cfg.serverDayInfo.sevCsv)
	if dataEasy.serverOpenDaysLess(day) then
		return false
	end

	local unLockLv = gUnionFeatureCsv[key] or 0
	local isLock = unLockLv == 0 or unLockLv > t.unionLevel
	if isLock or dataEasy.notUseUnionBuild() then
		return false
	end

	if t.unionFightRoleRound == "over" or t.unionFightRoleRound == "closed" then
		return false
	end

	return not t.unionFightSignUpState
end

function redHintHelper.unionTrainPosition(t)
	local result = false
	for k,v in csvPairs(csv.union.training) do
		-- 栏位有空
		if t.opened[k] and not t.slots[k] then
			result = true
			break
		end
		if t.slots[k] and t.slots[k].level >= t.level then
			result = true
			break
		end
	end

	local unionCanUnlockIdx = t.unionCanUnlockIdx
	local maxIdx = 0
	for k,v in csvPairs(csv.union.training) do
		if t.opened[k] and not t.slots[k] and k > maxIdx then
			maxIdx = k
		end
	end

	return result or maxIdx > unionCanUnlockIdx
end

function redHintHelper.unionTrainSpeedUp(t)
	local canUseTrain = unionTools.canEnterBuilding('training', nil, true)
	local state = false
	if canUseTrain and t.unionTrainingSpeedup < 6 and (t.count or 0) > 0 then
		state = true
	end
	return state
end

--符石抽取
function redHintHelper.cityGemFreeExtract()
	if not dataEasy.isUnlock(gUnlockCsv.gem) then
		return false
	end
	local freeGold = gGameModel.daily_record:read('gem_gold_dc1_free_count')
	local freeRmb = gGameModel.daily_record:read('gem_rmb_dc1_free_count')
	if freeGold == 0 or freeRmb == 0 then
		return true
	end
	return false
end

function redHintHelper.gemFreeExtract(t)
	local dbid = getCardDBID(t)
	return cache.queryRedHint({"gemFreeExtract", dbid}, function()
		local ret = checkAndGetCardFields(t, isCardInBattleCards)
		if not ret then
			return false
		end

		if redHintHelper.cityGemFreeExtract() then
			return true
		end
		return false
	end)
end

-- 战斗手册
function redHintHelper.battleManuals(t)
	return t.battleManualsClick ~= true
end

function redHintHelper.crossArenaPointAward(t)
	local pointAward = t.crossArenaPointAwardData or {}
	for k,v in csvPairs(csv.cross.arena.daily_award) do
		if pointAward[k] == 1 then
			return true
		end
	end
	return false
end

function redHintHelper.crossArenaRankAward(t)
	local datas = t.crossArenaDatas or {}
	local stageAwards = datas.stage_awards or {}
	local csvId = gGameModel.cross_arena:read("csvID")
	local cfg = csv.cross.service[csvId]
	if not cfg then
		return false
	end
	for k,v in csvPairs(csv.cross.arena.stage) do
		if v.version == cfg.version then
			if stageAwards[k] == 1 then
				return true
			end
		end
	end
	return false
end

function redHintHelper.gemUp(t)
	return t.gemUpRmbFree == 0
end

--# 2有可领取奖励
function redHintHelper.zongZiAward(t)
	local activityId = t.activityId
	if not activityId then return false end
	local yyhuodongs = t.yyHuodongs
	if yyhuodongs[activityId] and yyhuodongs[activityId].stamps then
		for k,v in pairs(yyhuodongs[activityId].stamps) do
			if v == 1 then
				return true
			end
		end
	end
	return false
end

--# 3有未使用的粽子
function redHintHelper.zongziUnused(t)
	local items = t.items
	for i=6358, 6363 do
		if items[i] then
			return true
		end
	end
	return false
end

--# 端午粽子活动
--# 1可合成粽子 2有可领取奖励 3有未使用的粽子
function redHintHelper.zongZiActivity(t)
	local activityId = t.activityId
	if not activityId then return false end

	local stapleData = {6352, 6353, 6354} 		--主食材itemID
	local nonStapleData = {6355, 6356, 6357}	--副食材itemID
	local items = t.items
	local staple, nonStaple = false, false
	for i=1, 3 do
		if items[stapleData[i]] then
			staple = true
		end
		if items[nonStapleData[i]] then
			nonStaple = true
		end
	end

	if staple and nonStaple then
		return true
	end

	if redHintHelper.zongZiAward(t) then
		return true
	end

	if redHintHelper.zongziUnused(t) then
		return true
	end
	return false
end
--幸运乐翻天活动
function redHintHelper.flipCardActivity(t)
	local activityId = t.activityId
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local yyData = t.yyHuodongs[activityId]
	if not activityId then return false end
	local roundMax = 0
	for i,v in csvPairs(csv.yunying.flop_rounds) do
		if v.huodongID == yyCfg.huodongID and v.type == 1 then
			roundMax = roundMax + 1
		end
	end

	if yyData.info.roundID > roundMax then
		return false
	end

	if yyCfg.paramMap.free - yyData.info.cost_free_times > 0 or yyData.info.task_times - yyData.info.cost_task_times > 0 then
		return true
	end

	-- local taskSum = 0
	-- local taskFinishedTimes = 0
	-- local finishedTime = yyData.valinfo or {}
	-- for k, v in csvPairs(csv.yunying.flop_task) do
	-- 	if v.huodongID == yyCfg.huodongID then
	-- 		local finishedTimes = finishedTime[k] and finishedTime[k].count or 0
	-- 		taskSum = taskSum + v.times
	-- 		taskFinishedTimes = taskFinishedTimes + finishedTimes
	-- 	end
	-- end
	-- if taskFinishedTimes < taskSum then
	-- 	return true
	-- end


	return false
end

--节日Boss
function redHintHelper.activityBoss(t)
	local activityId = t.activityId
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongId = yyCfg.huodongID
	local yyData = t.yyHuodongs[activityId]
	if not activityId then return false end
	local challengeTime = gGameModel.daily_record:read("huodong_boss_times")
	local dailyChallengeLimit = 0
	for _, v in ipairs(csv.yunying.huodongboss_config) do
		if v.huodongID == huodongId then
			dailyChallengeLimit = v.dailyChallengeLimit
			break
		end
	end
	if challengeTime and challengeTime < dailyChallengeLimit then
		return true
	end
	return false
end

--	圣诞雪球游戏
function redHintHelper.snowBall(t)
	local activityId = t.activityId
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local yyData = t.yyHuodongs[activityId]
	if not yyData then
		return true
	end
	if not activityId then return false end
	local paramMap = csv.yunying.yyhuodong[activityId].paramMap
	if yyData and yyData.info and yyData.info.times then
		if paramMap.times + yyData.info.buy_times - yyData.info.times > 0 then
			return true
		end
	end
	if yyData and yyData.stamps then
		for _,v in pairs(yyData.stamps) do
			if v == 1 then
				return true
			end
		end
	end
	return false
end
function redHintHelper.snowballDailyCheck(t)
	local activityId = t.id
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local yyData = t.yyHuodongs[activityId]
	local huodongID = yyCfg.huodongID
	for i, v in csvPairs(csv.yunying.snowball_award) do
		if v.huodongID == huodongID then
			local stamps = yyData.stamps or {}
			if v.type == 1 and stamps[i] == 1 then
				return true
			end
		end
	end
	return false
end
function redHintHelper.snowballAwarding(t)
	local activityId = t.id
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local yyData = t.yyHuodongs[activityId]
	local huodongID = yyCfg.huodongID
	for i, v in csvPairs(csv.yunying.snowball_award) do
		if v.huodongID == huodongID then
			local stamps = yyData.stamps or {}
			if v.type == 2 and stamps[i] == 1 then
				return true
			end
		end
	end
	return false
end

--摩天高楼
function redHintHelper.skyScraper(t)
	if redHintHelper.skyScraperTask(t) then
		return true
	end
	return false
end
function redHintHelper.skyScraperTask(t)
	local yycfg = csv.yunying.yyhuodong[t.activityId] or {}
	local paramMap = yycfg.paramMap or {}
	local yyData = t.yyHuodongs[t.activityId] or {}
	local info = yyData.info or {}
	local stamps = yyData.stamps or {}
	for _,v in pairs(stamps) do
		if v == 1 then
			return true
		end
	end
	return false
end
function redHintHelper.skyScraperSetTask(t)
	local activityId = t.id
	local yyCfg = csv.yunying.yyhuodong[activityId] or {}
	local yyData = t.yyHuodongs[activityId] or {}
	local huodongID = yyCfg.huodongID
	for i, v in csvPairs(csv.yunying.skyscraper_tasks) do
		if v.huodongID == huodongID then
			local stamps = yyData.stamps or {}
			if v.type == 1 and stamps[i] == 1 then
				return true
			end
		end
	end
	return false
end

function redHintHelper.skyScraperScoreTask(t)
	local activityId = t.id
	local yyCfg = csv.yunying.yyhuodong[activityId] or {}
	local yyData = t.yyHuodongs[activityId] or {}
	local huodongID = yyCfg.huodongID
	for i, v in csvPairs(csv.yunying.skyscraper_tasks) do
		if v.huodongID == huodongID then
			local stamps = yyData.stamps or {}
			if v.type == 2 and stamps[i] == 1 then
				return true
			end
		end
	end
	return false
end

function redHintHelper.skyScraperPerfectStructures(t)
	local activityId = t.id
	local yyCfg = csv.yunying.yyhuodong[activityId] or {}
	local yyData = t.yyHuodongs[activityId] or {}
	local huodongID = yyCfg.huodongID
	for i, v in csvPairs(csv.yunying.skyscraper_tasks) do
		if v.huodongID == huodongID then
			local stamps = yyData.stamps or {}
			if v.type == 3 and stamps[i] == 1 then
				return true
			end
		end
	end
	return false
end

local function isCardMegeCardNum(cfg, cardDatas, cardCfg, unitCfg)
	if cfg.costCards.star and cardDatas.star < cfg.costCards.star then
		return false
	end
	if unitCfg.rarity == cfg.costCards.rarity then
		return true
	end
	if cardCfg.cardMarkID == cfg.costCards.markID then
		return true
	end
	return false
end

local function isCardMegaOK(cards, cfg, t)
	for key, num in csvMapPairs(cfg.costItems) do
		if dataEasy.getNumByKey(key) < num then
			return false
		end
	end
	local hash = dataEasy.inUsingCardsHash()
	local cardCondition, conditionLevel = false, false
	local cardNum = 0
	for _, dbid in ipairs(cards) do
		local cards = gGameModel.cards:find(dbid)
		if cards then
			local cardDatas = cards:read("card_id", "level", "star")
			local cardCfg = csv.cards[cardDatas.card_id]
			local unitCfg = csv.unit[cardCfg.unitID]
			if cfg.card[1] == cardDatas.card_id and cfg.card[2] <= cardDatas.star then
				if cfg.condition[1] == 2 then
					if cardDatas.level >= cfg.condition[2] then
						cardCondition = true
						conditionLevel = true
					end
				else
					cardCondition = true
				end
			end
			local battleType = hash[dbid]
			if not ui.CARD_USING_TXTS[battleType] and isCardMegeCardNum(cfg, cardDatas, cardCfg, unitCfg) then
				cardNum = cardNum + 1
			end
		end
	end
	if cfg.costCards.num and cardNum < cfg.costCards.num then
		return false
	end
	if cfg.condition[1] == 1 and t.level >= cfg.condition[2] then
		conditionLevel = true
	end
	return cardCondition and conditionLevel
end

--超进化
function redHintHelper.cardMega(t)
	local cardData = {}
	if t.megaId then
		local cfg = csv.cards[t.megaId]
		cardData[cfg.megaIndex] = {key = t.megaId, canDevelop = cfg.canDevelop}
	else
		cardData = gCardsMega
	end
	local cards = t.cards
	local items = t.items
	for i,v in pairs(cardData) do
		local cfg = csv.card_mega[i]
		if v.canDevelop and cfg then
			if isCardMegaOK(cards, cfg, t) then
				return true
			end
		end
	end
	return false
end


function redHintHelper.braveChallengeAch(t)
	local activityId = nil
	local yyData = nil

	if t.sign == game.BRAVE_CHALLENGE_TYPE.anniversary then
		activityId = t.activityId
		local yyCfg = csv.yunying.yyhuodong[activityId]
		yyData = t.yyHuodongs[activityId] or {}
	else
		if not dataEasy.isUnlock(gUnlockCsv.normalBraveChallenge) then
			return false
		end

		local gCommonBraveChallenge = t.gCommonBraveChallenge or {}
		local endTime = gCommonBraveChallenge.endTime or 0

		--循环勇者挑战周期玩法，每期开启的时候一次性红点提示
		if endTime ~= t.braveChallengeEachClick then
			return true
		end

		-- 玩法活动关闭期间不显示红点
		endTime = time.getNumTimestamp(endTime, time.getRefreshHour())
		if math.floor(endTime - time.getTime()) <= 0 then
			return false
		end


		-- 循环勇者挑战周期玩法，每期开启的时候一次性红点提示
		yyData = t.commonBraveChallenge or {}
	end

	local stamps = yyData.stamps or {}
	for i, v in csvPairs(csv.brave_challenge.achievement) do
		if stamps[i] == 1 and (not t.type or v.type == t.type)then
			return true
		end
	end
	return false
end

--主界面竞技场奖励红点
function redHintHelper.arenaAward(t)
	for i,v in pairs(t.resultPointAward) do
		if v == 1 then
			return true
		end
	end
	for i,v in pairs(t.rankAward) do
		if v == 1 then
			local costId, costNum = csvNext(csv.pwrank_award[i].cost)
			if not costId or dataEasy.getNumByKey(costId) >= costNum then
				return true
			end
		end
	end
	return false
end

--主界面跨服竞技场奖励红点
function redHintHelper.crossArenaAward(t)
	local datas = t.crossArenaDatas or {}
	local stageAwards = datas.stage_awards or {}
	if not gGameModel.cross_arena then
		return false
	end
	local csvId = gGameModel.cross_arena:read("csvID")
	local cfg = csv.cross.service[csvId]
	local pointAward = t.crossArenaPointAwardData or {}
	for k,v in csvPairs(csv.cross.arena.daily_award) do
		if pointAward[k] == 1 then
			return true
		end
	end
	if not cfg then
		return false
	end
	for k,v in csvPairs(csv.cross.arena.stage) do
		if v.version == cfg.version then
			if stageAwards[k] == 1 then
				return true
			end
		end
	end
	return false
end

--主界面实时匹配奖励红点
function redHintHelper.onlineFightAward(t)
	local weeklyTarget = t.onlineFightInfo.weekly_target or {}
	for _, v in pairs(weeklyTarget) do
		if v == 1 then
			return true
		end
	end
	return false
end

-- 贵宾月礼包
function redHintHelper.onHonourableVip(t)
	local vipState = gGameModel.monthly_record:read("vip_gift") or {}
	local key, state = csvNext(vipState)
	local roleVip = gGameModel.monthly_record:read("vip")
	if state or state == 0 then
		return false
	end
	if csvSize(gVipCsv[roleVip].monthGift) == 0 then
		return false
	end
	return true
end

--道馆挑战红点
function redHintHelper.gymChallenge(t)
	for i, v in pairs(t.gymDatas.gym_pass_awards or {}) do
		if v == 1 then
			return true
		end
	end
	return false
end

--道馆挑战icon红点
function redHintHelper.gymBuffIcon(t)
	local allpoint = t.gymDatas.gym_talent_point
	local trees = t.gymDatas.gym_talent_trees or {}
	local id = t.id
	if t.round == "start" then
		local cfg = csv.gym.talent_buff[id]
		local tree = trees[cfg.treeID] or {}
		tree.talent = tree.talent or {}
		local lv = tree.talent[id] or 0
		local costPoint = csv.gym.talent_cost[lv]["cost"..cfg.costID].gym_talent_point
		if costPoint > allpoint then
			return false
		end
		if lv >= cfg.levelUp then
			return false
		end
		if cfg.depth == 1 then
			return true
		else
			local depthId = nil--这一层已经激活的id
			for _id, lv in pairs(tree.talent) do
				local depth = csv.gym.talent_buff[_id].depth
				if depth == cfg.depth then
					depthId = _id
					break
				end
			end
			local preIds = cfg.preTalentIDs
			for _, _id in ipairs(preIds or {}) do
				if depthId ~= id and depthId ~= nil then
					return false
				end
				local lv = tree.talent[_id] or 0
				if lv >= cfg.preLevel then
					return true
				end
			end
		end
	end
	return false
end

--道馆挑战标签页红点
function redHintHelper.gymBuffTab(t)
	if t.round == "start" then
		for id, cfg in orderCsvPairs(csv.gym.talent_buff) do
			if cfg.treeID == t.treeId then
				t.id = id
				if redHintHelper.gymBuffIcon(t) == true then
					return true
				end
			end
		end
	end
	return false
end

function redHintHelper.gymBuff(t)
	if t.round == "start" then
		for id, cfg in orderCsvPairs(csv.gym.talent_buff) do
			t.id = id
			if redHintHelper.gymBuffIcon(t) == true then
				return true
			end
		end
	end
	return false
end

function redHintHelper.gymAward(t)
	if t.gymDatas.gym_pass_awards then
		return t.gymDatas.gym_pass_awards[t.id] == 1
	end
	return false
end

--元素挑战红点
function redHintHelper.cloneBattle(t)
	if t and t.cloneRoomDbid and t.cloneRoomCreateTime then
		-- local cloneBattleRobot = userDefault.getForeverLocalKey("cloneBattleRobot", false)
		local canShow = false
		local today = time.getTodayStrInClock(12)
		local createTime = t.cloneRoomCreateTime
		local curTime = time.getTime()
		local timeSec = curTime - createTime
		local refreshStamp = time.getNumTimestamp(today, 12, 0) + 24 * 3600
		local refreshSec = refreshStamp - createTime
		local isCreateLongTime = timeSec >= (gCommonConfigCsv.cloneRobotTime * 60) 					-- 是否超时
		local isRefreshInComming = refreshSec <= (gCommonConfigCsv.cloneRobotRefreshTime * 60) 		-- 是否即将刷新
		if t.cloneBattleLookRobot then
			canShow = t.cloneBattleLookRobot
		end
		if canShow == false and t.cloneBattleKickNum < 3 then
			return isCreateLongTime or isRefreshInComming
		else
			return false
		end
	end
	return false
end

function redHintHelper.cloneBattleHistory(t)
	local cloneRoomHistory = t.cloneRoomHistory
	local cloneBattleHistory = userDefault.getForeverLocalKey("cloneBattleHistory", {})
	if itertools.isempty(cloneBattleHistory) or #cloneRoomHistory > #cloneBattleHistory then
		return true
	else
		return false
	end
end

--# 训练家重聚活动
-- 有礼包可领取
function redHintHelper.reunionGift(t)
	local reunion = t.reunion
	if not reunion then return false end

	local cfg = csv.yunying.yyhuodong[reunion.info.yyID]
	for k, v in pairs(cfg.paramMap.huodong) do
		if v == "gift" then
			--继续判断gift礼包是否可领取
			if reunion.gift and reunion.gift.reunion and reunion.gift.reunion[2] == 1 then
				return true
			end
			break
		end
	end

	return false
end

-- 签到
function redHintHelper.reunionSign(t)
	local reunion = t.reunion
	if not reunion then return false end

	local cfg = csv.yunying.yyhuodong[reunion.info.yyID]
	local huodongID = cfg.huodongID
	local stamps = reunion.stamps or {}
	local canReceive = false
	for k, v in csvPairs(csv.yunying.reunion_task) do
		if v.huodongID == huodongID and v.themeType == 1 then
			if stamps[k] and stamps[k] == 1 then
				canReceive = true
			end
		end
	end

	for k, v in pairs(cfg.paramMap.huodong) do
		if v == "sign" then
			--继续判断sign是否有签到奖励可以领取
			if canReceive then
				return true
			end
			break
		end
	end

	return false
end

--绑定礼包
function redHintHelper.reunionBindGift(t)
	local reunion = t.reunion
	local reunionBindPlayer = t.reunionBindPlayer

	if not reunion then return false end
	local cfg = csv.yunying.yyhuodong[reunion.info.yyID]
	for k, v in pairs(cfg.paramMap.huodong) do
		if v == "reunion" then
			--判断gift礼包是否可领取
			if reunion.gift and reunion.gift.bind and reunion.gift.bind[2] == 1 then
				return true
			elseif reunion.gift and (not reunion.gift.bind or reunion.gift.bind[2] == 0) then
				if reunionBindPlayer ~= reunion.info.yyID then
					return true
				else
					return false, true
				end
			end
			break
		end
	end
	return false
end

-- 相聚有时任务领取
function redHintHelper.reunionTask(t)
	local reunion = t.reunion
	if not reunion then return false end

	local cfg = csv.yunying.yyhuodong[reunion.info.yyID]
	local role_type = reunion.role_type
	local huodongID = cfg.huodongID
	local stamps =  reunion.stamps or {}
	local point_box = reunion.point_box or {}
	local showRedIcon = false
	if role_type == 1 then
		local reunionBindGift, b = redHintHelper.reunionBindGift(t)
		if b then
			return reunionBindGift
		elseif reunionBindGift then
			return true
		end
		for k, v in csvPairs(csv.yunying.reunion_task) do
			if v.huodongID == huodongID and v.themeType == 2 then
				if stamps[k] and stamps[k] == 1 then
					showRedIcon = true
				end
			end
		end
	end
	for k, v in csvPairs(csv.yunying.reunion_point_box) do
		if v.huodongID == huodongID then
			if point_box[k] and point_box[k] == 1 then
				showRedIcon = true
			end
		end
	end
	for k, v in pairs(cfg.paramMap.huodong) do
		if v == "reunion" then
			--继续判断相聚有时是否有任务奖励可以领取
			if showRedIcon then
				return true
			end
			break
		end
	end
	return false
end

function redHintHelper.reunionActivity(t)
	local reunion = t.reunion
	if not reunion or reunion.role_type == 0 then return false end

	if reunion.role_type == 1 and redHintHelper.reunionGift(t) then
		return true
	end

	if reunion.role_type == 1 and redHintHelper.reunionSign(t) then
		return true
	end

	if redHintHelper.reunionBindGift(t) then
		return true
	end

	if redHintHelper.reunionTask(t) then
		return true
	end
	return false
end

function redHintHelper.doubleTicket(t)
	local activityId = t.activityId
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongId = yyCfg.huodongID
	local yyData = t.yyHuodongs[activityId]
	if not yyData then
		return false
	end
	if yyData and not yyData.double11 then
		return false
	end
	if not yyData.double11[t.index] then
		return false
	end
	return yyData.double11[t.index].card_status == 1
end

function redHintHelper.doublePlayGame(t)
	return t.canPlay
end


function redHintHelper.double11(t)
	local activityId = t.activityId
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongId = yyCfg.huodongID
	local yyData = t.yyHuodongs[activityId]
	if not yyData then
		return false
	end
	if yyData and not yyData.double11 then
		return false
	end

	for i, v in pairs(yyData.double11) do
		if v.card_status == 1 then
			return true
		end
	end
	return false
end

function redHintHelper.gymLogs(t)
	local lastLogs = t.gymLogs.last_logs or {}
	local curLogs = t.gymLogs.logs or {}
	local curTime = time.getTime()
	local lastTime = t.lastTime
	local closeInfo = gGameModel.gym:read("record").gym_close_info or {}
	local lastCloseInfo = gGameModel.gym:read("record").last_gym_close_info or {}

	for i, log in pairs(lastLogs) do
		if log.time > lastTime and log.time < curTime then
			return true
		end
	end

	for i, log in pairs(curLogs) do
		if log.time > lastTime and log.time < curTime then
			return true
		end
	end

	--重置日志
	if itertools.size(lastLogs) > 0 then
		local time1 = time.getNumTimestamp(time.getWeekStrInClock(0), 0) + 5 * 3600 - 7 * 24 * 3600
		if time1 > lastTime then
			return true
		end
	end
	local time2 = time.getNumTimestamp(time.getWeekStrInClock(0), 0) + 5 * 3600
	if time2 > lastTime then
		return true
	end
	--结束日志
	if next(lastCloseInfo) and itertools.size(lastLogs) > 0 then
		local time1 = time.getNumTimestamp(time.getWeekStrInClock(0), 0) - 2 * 3600
		if time1 > lastTime then
			return true
		end
	end
	if next(closeInfo) then
		local time1 = time.getNumTimestamp(time.getWeekStrInClock(0), 0) + 7 * 24 * 3600 - 2 * 3600
		if time1 > lastTime then
			return true
		end
	end
	return false
end

function redHintHelper.unionAnswer(t)
	if gUnionFeatureCsv["fragdonate"] > t.unionLevel then
		return false
	end
	--判断unlock
	if not dataEasy.isUnlock(gUnlockCsv.unionQA) then
		return false
	end
	local day = csv.cross.union_qa.base[1].servOpenDays
	local isUnionAnswerDay = dataEasy.serverOpenDaysLess(day)
	if isUnionAnswerDay then
		return false
	end
	if t.qaround ~= "start" then
		return false
	end
	if gCommonConfigCsv.unionQATimes + t.qaBuyTimes - t.qaTimes > 0 then
		return true
	end
	return false
end

function redHintHelper.flipNewYear(t)
	local activityId = t.activityId
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongId = yyCfg.huodongID
	local yyData = t.yyHuodongs[activityId]
	if yyData.stamps then
		for k, v in pairs(yyData.stamps) do
			if v == 1 then
				return true
			end
		end
	end
	if yyData.link_award then
		for k, v in pairs(yyData.link_award) do
			if v == 1 then
				return true
			end
		end
	end
	return false
end

function redHintHelper.rmbgoldReward(t)
	local activityId = t.activityId
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongId = yyCfg.huodongID
	local yyData = t.yyHuodongs[activityId]
	if yyData then
		if yyData.stamps then
			for k, v in pairs(yyData.stamps) do
				if v == 1 then
					return true
				end
			end
		end
		local curTime = time.getTime()
		local endTime = time.getNumTimestamp(yyCfg.endDate,time.getHourAndMin(yyCfg.endTime, true))
		local lessTime = endTime - curTime
		if yyData.info and yyData.info.flag ~= 1 and lessTime < 86400 * yyCfg.paramMap.returnDays and ((yyCfg.paramMap.type == "rmb" and yyData.info.rmb_used ~= 0) or (yyCfg.paramMap.type == "gold" and yyData.info.gold_used ~= 0)) then  -- 3天时间戳
			return true
		end
	end
	return false
end

function redHintHelper.dailyAssistant(t)
	if not dailyAssistantTools.isUnlock("dailyAssistant") then
		return false
	end
	if redHintHelper.dailyAssistantReward(t)
		or redHintHelper.dailyAssistantDrawCard(t)
		or redHintHelper.dailyAssistantSignup(t)
		or redHintHelper.dailyAssistantAdventure(t)
		or redHintHelper.dailyAssistantUnion(t) then
		return true
	end
	return false
end

-- 公会每日红包，每日礼包，冒险执照，聚宝
function redHintHelper.dailyAssistantReward(t)
	if redHintHelper.unionDailyGift(t) or redHintHelper.unionSystemRedPacket(t) or redHintHelper.cityTrainer(t) then
		return true
	end
	local lianjinLeftTimes = dailyAssistantTools.getGainGoldTimes(t.lianjinTimes, t.lianjinFreeTimes, true)
	return lianjinLeftTimes > 0
end

-- 抽卡，钻石抽卡，金币抽卡，饰品抽卡，探险寻宝，符石抽取, 芯片抽取
function redHintHelper.dailyAssistantDrawCard(t)
	t.unlockKey = gUnlockCsv.drawEquip
	if redHintHelper.drawcardDiamondFree(t)
		or redHintHelper.drawcardGoldFree(t)
		or redHintHelper.drawcardEquipFree(t) then
		return true
	end
	t.unlockKey = gUnlockCsv.explorer
	if redHintHelper.explorerFind(t) then
		return true
	end
	if redHintHelper.cityGemFreeExtract()
		or redHintHelper.cityChipFreeExtract() then
		return true
	end
	return false
end

-- 签到
function redHintHelper.dailyAssistantSignup(t)
	local features = "craft"
	if dailyAssistantTools.isUnlock(features)
		and dataEasy.judgeServerOpen(features)
		and dailyAssistantTools.getCraftState() == 1 then
		return true
	end
	features = "crossCraft"
	if dailyAssistantTools.isUnlock(features)
		and dataEasy.judgeServerOpen(features)
		and dailyAssistantTools.getCrossCraftState() == 1 then
		return true
	end
	features ="unionFight"
	if gGameModel.role:read("union_db_id")
		and dailyAssistantTools.isUnlock(features)
		and not dailyAssistantTools.getUnionLockAndText(features)
		and dailyAssistantTools.getUnionFightState() == 1 then
		return true
	end
	return false
end

-- 冒险
function redHintHelper.dailyAssistantAdventure(t)
	local leftTimes = dailyAssistantTools.getActivityGateInfo()
	if leftTimes > 0 then
		return true
	end
	if dailyAssistantTools.getEndlessTowerRedHintState()
		or dailyAssistantTools.getFishingRedHintState() then
		return true
	end
	return false
end

-- 公会
function redHintHelper.dailyAssistantUnion(t)
	local unionId = t.unionId
	local unionLevel = t.unionLevel
	if not unionId or not unionLevel then
		return false
	end
	local features = "unionContrib"
	if not dailyAssistantTools.getUnionLockAndText(features)
		and dailyAssistantTools.getUnionContribText(true) > 0 then
		return true
	end

	local features = "unionFragDonate"
	if not dailyAssistantTools.getUnionLockAndText(features)
		and dailyAssistantTools.getUnionFragDonateText(true) > 0 then
		return true
	end

	local features = "unionTrainingSpeedup"
	local unionTrainingSpeedup = t.unionTrainingSpeedup
	local leftTimes = math.max(6 - unionTrainingSpeedup, 0)
	if not dailyAssistantTools.getUnionLockAndText(features)
		and leftTimes > 0 then
		return true
	end

	local features = "unionFuben"
	if not dailyAssistantTools.getUnionLockAndText(features)
		and (unionTools.currentOpenFuben() == "open" and dailyAssistantTools.getUnionFubenTimes(true) > 0)
		or dataEasy.haveUnionFubenReward() then
		return true
	end

	return false
end

function redHintHelper.playPassport(t)
	local activityId = t.activityId
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongId = yyCfg.huodongID
	local yyData = t.yyHuodongs[activityId]
	if yyData then
		for key, val in pairs(yyData.stamps) do
			if val == 1 then
				return true
			end
		end
		for key, val in pairs(yyData.stamps1) do
			if val == 1 then
				return true
			end
		end
	end
	return false
end

function redHintHelper.gridWalkMain(t)
	if redHintHelper.gridWalkTask(t) or redHintHelper.gridWalkAchievements(t) then
		return true
	end
	return false
end

function redHintHelper.gridWalkTask(t)
	local yyID = t.gridWalk.yy_id
	local yyCfg = csv.yunying.yyhuodong[yyID]
	local huodongID = yyCfg.huodongID
	local yyData = t.yyHuodongs[yyID]
	if yyData then
		local stamps = yyData.stamps or {}
		for i, v in csvPairs(csv.yunying.grid_walk_tasks) do
			if v.huodongID == huodongID and v.taskType > 0 and stamps[i] == 1 then
				return true
			end
		end
	end
	return false
end

function redHintHelper.gridWalkAchievements(t)
	local yyID = t.gridWalk.yy_id
	local yyCfg = csv.yunying.yyhuodong[yyID]
	local huodongID = yyCfg.huodongID
	local yyData = t.yyHuodongs[yyID]
	if yyData then
		local stamps = yyData.stamps or {}
		for i, v in csvPairs(csv.yunying.grid_walk_tasks) do
			if v.huodongID == huodongID and v.taskType == 0 and stamps[i] == 1 then
				return true
			end
		end
	end
	return false
end

function redHintHelper.horseRaceMain(t)
	if redHintHelper.horseRaceAward(t) or redHintHelper.horseRaceBetAward(t) or redHintHelper.horseRaceCanBet(t) then
		return true
	end
	return false
end

function redHintHelper.horseRaceAward(t)
	local yyID = t.activityId
	local yyCfg = csv.yunying.yyhuodong[yyID]
	local huodongID = yyCfg.huodongID
	local yyData = t.yyHuodongs[yyID]
	if yyData and yyData.horse_race then
		local pointAward = yyData.horse_race.point_award or {}
		for i, v in csvPairs(csv.yunying.horse_race_point_award) do
			if v.huodongID == huodongID and pointAward[i] == 1 then
				return true
			end
		end
	end
	return false
end

function redHintHelper.horseRaceBetAward(t)
	local yyID = t.activityId
	local yyCfg = csv.yunying.yyhuodong[yyID]
	local yyData = t.yyHuodongs[yyID]

	if yyData and yyData.horse_race then
		local pointAward = yyData.horse_race.bet_award or {}
		for i, v in pairs(pointAward) do
			for key, val in pairs(v) do
				if val[3] == 1 then
					return true
				end
			end
		end
	end
	return false
end

function redHintHelper.horseRaceCanBet(t)
	local yyID = t.activityId
	local yyData = t.yyHuodongs[yyID]

	local times = csv.cross.horse_race.base[1].time
	local today = tonumber(time.getTodayStr())
	local function getHorseRaceTurn()
		local turn = 1
		local nowTime = time.getTime()
		if nowTime > time.getNumTimestamp(today, times[3]) then
			turn = 2
		else
			turn = 1
		end
		return turn
	end
	local function timeCanBet()
		local nowTime = time.getTime()
		local dateTime = {{time.getNumTimestamp(today, times[1]), time.getNumTimestamp(today, times[2]) - 60*3}, {time.getNumTimestamp(today, times[3]), time.getNumTimestamp(today, times[4]) - 60*3}}
		for k, v in pairs(dateTime) do
			if v[1] < time.getTime() and v[2] > time.getTime() then
				return true
			end
		end
		return false
	end
	local horseRaceTurn = getHorseRaceTurn()
	if yyData and yyData.horse_race then
		local betAward = yyData.horse_race.bet_award or {}
		if timeCanBet() and (not betAward[today] or not betAward[today][horseRaceTurn]) then
			return true
		end
	end
	return false
end

function redHintHelper.dispatchTaskType(t)
	local RECHARGE_STATE = {
		got = 0,  	 -- 已领取
		get = 1, 	 -- 可领取
		none = 2, 	-- 不可领取
	}

	local activityId = t.activityId
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local yyData = t.yyHuodongs[activityId] or {}
	local huodongID = yyCfg.huodongID

	local stamps = yyData.stamps or {}
	for k, v in pairs(stamps) do
		if huodongID == csv.yunying.dispatch_task[k].huodongID then
			if (v == RECHARGE_STATE.get and t.type == csv.yunying.dispatch_task[k].type) or (v == RECHARGE_STATE.get and t.type == nil) then
				return true
			end
		end
	end

	return false
end

function redHintHelper.activityDispatch(t)
	local activityId = t.activityId
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local yyData = t.yyHuodongs[activityId] or {}
	local huodongID = yyCfg.huodongID

	local stamps = yyData.stamps or {}
	for k, v in pairs(stamps) do
		if huodongID == csv.yunying.dispatch_task[k].huodongID then
			if v == 1  then
				return true
			end
		end
	end

	for taskId, v in pairs(yyData.dispatch or {}) do
		if huodongID == csv.yunying.dispatch[taskId].huodongID then
			if  v.end_time < time.getTime() and v.status == 1 then
				return true
			end
		end
	end
	return false
end

function redHintHelper.canZawakeByStage(t)
	if not dataEasy.isUnlock(gUnlockCsv.zawake) then
		return false
	end
	local selectDbId = t.selectDbId
	local zawakeID = t.zawakeID
	if zawakeID then
		if zawakeID == 0 then return false end
		if not zawakeTools.isOpenByStage(zawakeID, t.stageID) then
			return false
		end
		for lv=1, zawakeTools.MAXLEVEL do
			if zawakeTools.canAwake(zawakeID, t.stageID, lv) then
				return true
			end
		end
	end
	if selectDbId then
		local card = gGameModel.cards:find(selectDbId)
		local cardId = card:read("card_id")
		zawakeID = csv.cards[cardId].zawakeID
		if zawakeID == 0 then return false end
		for lv=1, zawakeTools.MAXLEVEL do
			if zawakeTools.canAwake(zawakeID, t.stageID, lv) then
				return true
			end
		end
	end
	return false
end

function redHintHelper.canZawake(t)
	local dbid = getCardDBID(t)
	return cache.queryRedHint({"canZawake", dbid}, function()
		local ret = checkAndGetCardFields(t, isCardInBattleCards)
		if not ret then
			return false
		end
		for stageID=1, zawakeTools.MAXSTAGE do
			t.stageID = stageID
			if redHintHelper.canZawakeByStage(t) then
				return true
			end
		end
		return false
	end)
end


--芯片抽取
function redHintHelper.cityChipFreeExtract()
	return cache.queryRedHint("cityChipFreeExtract", function()
		if not dataEasy.isUnlock(gUnlockCsv.chip) then
			return false
		end
		local freeItem = gGameModel.daily_record:read('chip_item_dc1_free_count')
		local freeRmb = gGameModel.daily_record:read('chip_rmb_dc1_free_count')
		if freeItem == 0 or freeRmb == 0 then
			return true
		end
		return false
	end)
end

-- 夏日祭探险
function redHintHelper.summerChallenge(t)
	local activityId = t.activityId
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local yyData = t.yyHuodongs[activityId] or {}
	local info = yyData.info or {}
	local allPass = info.all_pass
	if allPass == 1 then return false end

	local beginTime = time.getNumTimestamp(yyCfg.beginDate, time.getHourAndMin(yyCfg.beginTime, true))
	local nowTime = time.getTime()
	local day = math.ceil((nowTime - beginTime)/86400)
	local stamps = yyData.stamps or {}
	-- 获取当前最大层数
	local maxFloor = 0
	for k, v in pairs(stamps) do
		maxFloor = math.max(csv.summer_challenge.gates[k].floor, maxFloor)
	end

	local baseID = yyCfg.paramMap.base
	local baseCsv = csv.summer_challenge.base[baseID]
	local gateSeqID = baseCsv.gateSeqID

	local gateCfgTab = {}
	for id, gateCfg in orderCsvPairs(csv.summer_challenge.gates) do
		if gateCfg.gateSeq == gateSeqID and gateCfg.floor == maxFloor+1 then
			return gateCfg.openDay <= day
		end
	end

	return false
end

-- 沙滩刨冰
function redHintHelper.shavedIce(t)
	local activityId = t.activityId
	if not activityId then return false end
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local yyData = t.yyHuodongs[activityId]
	local paramMap = csv.yunying.yyhuodong[activityId].paramMap
	if not yyData then
		return false
	end
	if yyData and yyData.info and yyData.info.times then
		if paramMap.times + yyData.info.buy_times - yyData.info.times > 0 then
			return true
		end
	end
	return false
end

-- 沙滩排球
function redHintHelper.volleyball(t)
	local activityId = t.activityId
	if not activityId then return false end
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local yyData = t.yyHuodongs[activityId]
	if not yyData then
		return false
	end
	if yyData and yyData.stamps then
		for _,v in pairs(yyData.stamps) do
			if v == 1 then
				return true
			end
		end
	end
	return false
end

function redHintHelper.volleyballDailyCheck(t)
	local activityId = t.id
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local yyData = t.yyHuodongs[activityId]
	local huodongID = yyCfg.huodongID
	for i, v in csvPairs(csv.yunying.volleyball_tasks) do
		if v.huodongID == huodongID then
			local stamps = yyData.stamps or {}
			if v.type == 1 and stamps[i] == 1 then
				return true
			end
		end
	end
	return false
end

function redHintHelper.volleyballAwarding(t)
	local activityId = t.id
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local yyData = t.yyHuodongs[activityId]
	local huodongID = yyCfg.huodongID
	for i, v in csvPairs(csv.yunying.volleyball_tasks) do
		if v.huodongID == huodongID then
			local stamps = yyData.stamps or {}
			if v.type == 2 and stamps[i] == 1 then
				return true
			end
		end
	end
	return false
end

function redHintHelper.midAutumnDraw(t)
	local activityId = t.activityId
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local yyData = t.yyHuodongs[activityId] or {}
	if yyData.info and yyData.info.round_counter and yyData.info.draw_times > 0 then
		return true
	end
	for i, v in pairs(yyData.stamps or {}) do
		if v == 1 then
			return true
		end
	end
	return false
end

function redHintHelper.midAutumnTaskAward(t)
	local activityId = t.activityId
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local yyData = t.yyHuodongs[activityId] or {}
	for i, v in pairs(yyData.stamps or {}) do
		if v == 1 then
			return true
		end
	end
	return false
end

function redHintHelper.crossUnionFight(t)
	if not t.unionId then
		return false
	end

	local key = "crossunionfight"
	if not dataEasy.isInServer(key) then
		return false
	end

	local unLockLv = gUnionFeatureCsv[key] or 0
	local isLock = unLockLv == 0 or unLockLv > t.unionLevel
	if isLock or dataEasy.notUseUnionBuild() then
		return false
	end

	local now = tonumber(time.getTodayStrInClock())
	if t.crossUnionFightStatus == "prePrepare" and t.crossUnionFightJoins and now - t.crossUnionFightTime > 5 then
		return true
	end
	return false
end


return redHintHelper