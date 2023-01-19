
local MonthCardView = require "app.views.city.activity.month_card"
local dailyAssistantTools = {}

-- 报名状态(1=可报名，2=已报名，3=不可报名)
local STATE_SIGN_UP = {
	canSignUp = 1,
	hadSignUp = 2,
	cantSignUp = 3,
}

-- 公会建筑映射表
dailyAssistantTools.UNION_BUILDINGS = {
	["unionDailyGift"] = "dailygift",  --每日礼包
	["unionRedpacket"] = "redpacket",  --红包中心
	["unionTrainingSpeedup"] = "training",   --训练中心
	-- "unionskill", --修炼中心
	["unionFuben"] = "fuben",      --副本
	["unionFight"] = "unionFight", --公会战
	["unionContrib"] = "contribute", -- 捐献中心
	["unionFragDonate"] = "fragdonate", -- 许愿中心
	-- "unionqa", -- 精灵问答
}

-- 获取聚宝免费次数
function dailyAssistantTools.getGainGoldTimes(lianjinTimes, lianjinFreeTimes, onlyLeftTimes)
	local lianjinFreeTimesTotal = (MonthCardView.getPrivilegeAddition("lianjinFreeTimes") or 0) + dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.LianjinFreeTimes)
	local maxFree = 1
	for k, val in pairs(gCostCsv.lianjin_cost) do
		if val == 0 then
			maxFree = k
		end
	end
	maxFree = maxFree + lianjinFreeTimesTotal
	local leftTimes = math.max(maxFree - lianjinTimes, 0)
	if leftTimes == 0 and lianjinFreeTimes < lianjinFreeTimesTotal then
		leftTimes = lianjinFreeTimesTotal - lianjinFreeTimes
	end
	if onlyLeftTimes then
		return leftTimes
	end
	local showLeft = string.format("%s/%s", leftTimes, maxFree)
	if leftTimes == 0 then
		showLeft = "#C0xFB6023#" .. showLeft
	end
	return string.format(gLanguageCsv.dailyAssistantFreeGainGold, showLeft), leftTimes
end

-- 获取碎片名
function dailyAssistantTools.getCardFragmentsName(cardId)
	if cardId then
		for _, card in gGameModel.cards:pairs() do
			local id = card:read("card_id")
			if cardId == id then
				local cardCsv = csv.cards[id]
				return cardCsv.name .. gLanguageCsv.fragment
			end
		end
	end
	return nil
end

function dailyAssistantTools.getHuodongTypeFlag(hType)
	local isShow = false
	-- 副本次数增加的查询string
	local tb = {
		[1] = "goldActivity",
		[2] = "expActivity",
		[3] = "giftActivity",
		[4] = "fragActivity",
	}
	local str = tb[hType]
	if not str then return false end
	local isDouble, paramMaps, count = dataEasy.isDoubleHuodong(str)
	return isDouble, 2, paramMaps, count
end

function dailyAssistantTools.getIsDoubleAward(hType)
	local isDouble, paramMaps, count = dataEasy.isDoubleHuodong("gateDrop")
	if not isDouble then return false end
	local sceneConf = csv.scene_conf
	for _, paramMap in pairs(paramMaps) do
		local startId= tonumber(paramMap["start"])
		local startConf = sceneConf[startId]
		local gateType = startConf.gateType
		if (gateType == game.GATE_TYPE.dailyGold and hType == 1) or 	-- 金币本
			(gateType == game.GATE_TYPE.dailyExp and hType == 2) or 	-- 经验本
			(gateType == game.GATE_TYPE.gift and hType == 3) or 	-- 礼物本
			(gateType == game.GATE_TYPE.fragment and hType == 4) then -- 碎片本
			return true, hType
		end
	end
	return false
end

function dailyAssistantTools.getActivityGateInfo()
	local huodongs = gGameModel.role:read("huodongs")
	local level = gGameModel.role:read("level")
	local allTimes = 0
	local leftTimes = 0
	-- 日常副本 文本次数
	local huodongType = {
		game.PRIVILEGE_TYPE.HuodongTypeGoldTimes,
		game.PRIVILEGE_TYPE.HuodongTypeExpTimes,
		game.PRIVILEGE_TYPE.HuodongTypeGiftTimes,
		game.PRIVILEGE_TYPE.HuodongTypeFragTimes
	}
	local tb = {
		[1] = "goldActivity",
		[2] = "expActivity",
		[3] = "giftActivity",
		[4] = "fragActivity",
	}
	local DoubleActivityTxt = {}
	local isDoubleActivity = {}
	local haveReunion = false
	for k,v in orderCsvPairs(csv.huodong) do
		-- 若是一次性活动并且未开放期间，不显示界面
		local currType = huodongType[v.huodongType]
		if v.openType ~= 0 and currType and level > v.openLevel then
			local addTime = dataEasy.getPrivilegeVal(currType)
			local flagShow, flagType, paramMaps, count = dailyAssistantTools.getHuodongTypeFlag(v.huodongType)
			local isDoubleReward = dailyAssistantTools.getIsDoubleAward(v.huodongType)
			if flagType == 2 and flagShow then
				-- 增加次数要在外部显示
				addTime = addTime + paramMaps[1].count or 0 -- 只读取一个
				table.insert(isDoubleActivity, v.huodongType)
				local str, isReunion = dailyAssistantTools.getActiveText(tb[v.huodongType])
				if str then
					table.insert(DoubleActivityTxt, str)
				end
				if isReunion then
					haveReunion = isReunion
				end
			end
			if isDoubleReward then
				table.insert(isDoubleActivity, v.huodongType)
				table.insert(DoubleActivityTxt, csv.huodong[v.huodongType].name .. gLanguageCsv.doubleReward)
			end
			local surplusTimes = v.times + addTime
			local curDate = tonumber(time.getTodayStrInClock())
			if huodongs[curDate] and huodongs[curDate][k] then
				surplusTimes = surplusTimes - huodongs[curDate][k].times
			end
			surplusTimes = math.max(surplusTimes, 0)

			allTimes = allTimes + v.times + addTime
			leftTimes = leftTimes + surplusTimes
		end
	end
	return leftTimes, allTimes, DoubleActivityTxt, #isDoubleActivity > 0, haveReunion
end

function dailyAssistantTools.getActiveText(typeIdorStr)
	local typeId = typeIdorStr
	if type(typeIdorStr) == "string" then
		typeId = game.DOUBLE_HUODONG[typeIdorStr]
	end
	if not typeId then return false end
	for _, yyId in ipairs(gGameModel.role:read("yy_open")) do
		local cfg = csv.yunying.yyhuodong[yyId]
		if game.YYHUODONG_TYPE_ENUM_TABLE.doubleDrop == cfg.type then
			local paramMap = cfg.paramMap
			if paramMap.type and paramMap.type == typeId then
				local str = cfg.desc
				local reunionState, reunionParamMaps, count = dataEasy.isReunionDoubleHuodong(typeId)
				return str, reunionState
			end
		end
	end
	return false
end

-- 公会副本是否能进
function dailyAssistantTools.getUnionFubenIsOpen()
	local unionId = gGameModel.role:read("union_db_id")
	local isLock = dailyAssistantTools.getUnionLockAndText("unionFuben")
	if unionId and not isLock then
		return true
	end
	return false
end

-- 公会lock判断
function dailyAssistantTools.getUnionLockAndText(features)
	local unionLevel = gGameModel.role:read("union_level")
	local unLockLv = gUnionFeatureCsv[dailyAssistantTools.UNION_BUILDINGS[features]] or 0
	local isLock = unLockLv == 0 or unLockLv > unionLevel
	if isLock then
		return isLock, string.format(gLanguageCsv.unionUnlockLevel, unLockLv)
	end
	-- 判断是否可以使用公会
	isLock = dataEasy.notUseUnionBuild()
	if isLock then
		return isLock, gLanguageCsv.cantUseFeaturesByChangeUnion
	end
	if features == "unionRedpacket" then
		-- 公会系统红包判断是否可领取
		isLock = not dataEasy.canSystemRedPacket()
		if isLock then
			return isLock, gLanguageCsv.unionRedPacketSysTimeL
		end
	elseif features == "unionFight" then
		local state, day = dataEasy.judgeServerOpen(features)
		if not state and day then
			return true, string.format(gLanguageCsv.unlockServerOpen, day)
		end
	end
	return isLock
end


-- 获取石英状态
function dailyAssistantTools.getCraftState()
	local state = STATE_SIGN_UP.cantSignUp  --"不可报名"
	local craftRound = gGameModel.role:read("craft_round")
	local isSignup = gGameModel.daily_record:read("craft_sign_up")
	local signupSucc = isSignup and craftRound == "signup"
	if signupSucc then
		state = STATE_SIGN_UP.hadSignUp  --"已报名"
	elseif craftRound == "signup" then
		state = STATE_SIGN_UP.canSignUp  --"可报名"
	end
	return state
end

-- 获取公会战状态
function dailyAssistantTools.getUnionFightState()
	local state = STATE_SIGN_UP.cantSignUp  --"不可报名"
	local unionFightRound = gGameModel.role:read("union_fight_round")
	local inUnionTop8 = gGameModel.role:read("in_union_fight_top8")
	local isSignup = gGameModel.daily_record:read("union_fight_sign_up")
	local signupSucc = isSignup and unionFightRound == "signup"
	local wday = time.getNowDate().wday -- 星期
	wday = wday == 1 and 7 or wday - 1
	-- 判断当前公会是否符合报名要求（决赛）
	if signupSucc then
		state = STATE_SIGN_UP.hadSignUp  --"已报名"
	elseif (wday == 6 and unionFightRound == "signup" and inUnionTop8)
		or (wday > 1 and wday < 6 and unionFightRound == "signup") then
		state = STATE_SIGN_UP.canSignUp  --"可报名"
	end
	return state
end

-- 获取跨服公会战状态
function dailyAssistantTools.getCrossCraftState()
	local state = STATE_SIGN_UP.cantSignUp  --"不可报名"
	local isSignup = gGameModel.role:read("cross_craft_sign_up_date") ~= 0
	local crossCraftRound = gGameModel.role:read("cross_craft_round")
	local signupSucc = isSignup and crossCraftRound == "signup"
	if signupSucc then
		state = STATE_SIGN_UP.hadSignUp  --"已报名"
	elseif crossCraftRound == "signup" then
		state = STATE_SIGN_UP.canSignUp  --"可报名"
	end
	return state
end

-- 冒险之路获取剩余重置次数
function dailyAssistantTools.getEndlessLeftTimes(onlyLeftTimes)
	local vip = gGameModel.role:read("vip_level")
	local resetCount = gGameModel.daily_record:read("endless_tower_reset_times")
	local max = gVipCsv[vip].endlessTowerResetTimes
	local leftTimes = math.max(max - resetCount, 0)
	if onlyLeftTimes then
		return leftTimes
	end
	return string.format("%s %s/%s", gLanguageCsv.reset, leftTimes, max), leftTimes, max
end

-- 捕鱼获取文本和剩余次数
function dailyAssistantTools.getFishingText(onlyLeftTimes)
	local fishingCounter = gGameModel.daily_record:read('fishing_counter')
	local leftTimes = gCommonConfigCsv.fishingDailyTimes - fishingCounter
	if onlyLeftTimes then
		return leftTimes
	end
	local fishingSelectScene = gGameModel.fishing:read("select_scene")
	local selectScene = fishingSelectScene == 0 and 1 or fishingSelectScene
	local items = gGameModel.role:read("items")
	local selectBait = gGameModel.fishing:read("select_bait")
	local selectRod = gGameModel.fishing:read("select_rod")
	local sceneName = csv.fishing.scene[selectScene].name
	local baitNum
	-- 判断当前场景符合的鱼饵
	for k,v in csvPairs(csv.fishing.bait) do
		local map = itertools.map(csv.fishing.bait[k].scene, function(_, v) return v, true end)
		if map[selectScene] and selectBait == k then
			baitNum = items[v.itemId]
			break
		end
	end
	local minBait = baitNum or 0
	local minBait = math.min(leftTimes, minBait)
	local showMinBait = minBait
	if minBait == 0 then
		showMinBait = "#C0xFB6023#" .. minBait
	end
	local showLeft = leftTimes
	if leftTimes == 0 then
		showLeft = "#C0xFB6023#" .. leftTimes
	end
	local str = string.format(gLanguageCsv.dailyAssistantFishingText, sceneName, showMinBait, showLeft)
	if selectRod == 0 then
		str = string.format(gLanguageCsv.dailyAssistantFishingText1, sceneName)
	end
	return str, leftTimes, minBait
end

-- 获取公会捐献提示文本
function dailyAssistantTools.getUnionContribText(onlyLeftTimes)
	local unionLevel = gGameModel.role:read("union_level")
	local contribMax = csv.union.union_level[unionLevel].ContribMax
	local contribCount = gGameModel.daily_record:read("union_contrib_times")
	local leftTimes = contribMax - contribCount
	if onlyLeftTimes then
		return leftTimes
	end
	local id = gGameModel.role:read("daily_assistant").union_contrib or 1
	local contribName = gLanguageCsv[csv.union.contrib[id].title]
	local showLeft = leftTimes
	if leftTimes == 0 then
		showLeft = "#C0xFB6023#" .. showLeft
	end
	local str = string.format(gLanguageCsv.dailyAssistantUnionContribText, showLeft, contribName)
	return str, leftTimes
end

-- 获取公会碎片许愿提示文本
function dailyAssistantTools.getUnionFragDonateText(onlyLeftTimes)
	local unionFragDonateStartTimes = gGameModel.daily_record:read("union_frag_donate_start_times")
	local leftTimes = math.max(1 - unionFragDonateStartTimes, 0)
	if onlyLeftTimes then
		return leftTimes
	end
	local showLeft = leftTimes
	if leftTimes == 0 then
		showLeft = "#C0xFB6023#" .. showLeft
	end
	local str = string.format(gLanguageCsv.dailyAssistantUnionFragDonateText1, showLeft)
	local cardId = gGameModel.role:read("daily_assistant").union_frag_donate_card_id
	local name = dailyAssistantTools.getCardFragmentsName(cardId)
	if name then
		str = string.format(gLanguageCsv.dailyAssistantUnionFragDonateText, showLeft, name)
	end
	return str, leftTimes
end

-- 获取公会副本次数
function dailyAssistantTools.getUnionFubenTimes(onlyLeftTimes)
	local unionFbTimes = gGameModel.daily_record:read("union_fb_times")
	local unionFbSubTimes = math.max(3 - unionFbTimes, 0)
	if onlyLeftTimes then
		return unionFbSubTimes
	end
	return string.format("%s/3", unionFbSubTimes), unionFbSubTimes
end

function dailyAssistantTools.isUnlock(features)
	if dataEasy.isShow(features) and dataEasy.isUnlock(features) then
		return true
	end
	return false
end

-- 冒险之路红点状态
function dailyAssistantTools.getEndlessTowerRedHintState()
	if not dailyAssistantTools.isUnlock("endlessTower") then
		return false
	end
	local selected = gGameModel.role:read("daily_assistant").endless_buy_reset
	local curChallengeId = gGameModel.role:read("endless_tower_current")
	local maxGateId = gGameModel.role:read("endless_tower_max_gate")
	local leftTimes = dailyAssistantTools.getEndlessLeftTimes(true)
	if (selected == 0 and curChallengeId < maxGateId) or (selected == 1 and (leftTimes > 0 or curChallengeId < maxGateId)) then
		return true
	end
	return false
end

-- 捕鱼红点状态
function dailyAssistantTools.getFishingRedHintState()
	if (not dailyAssistantTools.isUnlock("fishing")) or (not dailyAssistantTools.isUnlock("catch")) then
		return false
	end
	local selected = gGameModel.role:read("daily_assistant").fishing_skip
	local leftTimes = dailyAssistantTools.getFishingText(true)
	if selected == 1 and leftTimes > 0 then
		return true
	end
	return false
end

return dailyAssistantTools