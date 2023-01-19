-- @date:   2019-03-06
-- @desc:   选择关卡界面

local REWARD_TYPE = {
	-- 双倍奖励
	gLanguageCsv.doubleReward,
	-- 增加次数
	gLanguageCsv.additionalNumber
}

local BTN_TITLE = {
	gLanguageCsv.mopUp,
	gLanguageCsv.spaceChallenge
}

local BTN_STATE = {
	-- 扫荡
	MOPUP = 1,
	-- 挑战
	CHALLENGE = 2,
	-- 未解锁
	NOT_UNLOCK = 3
}

local function createRichTxt(str, x, y, parent, lineWidth)
	return rich.createWithWidth(str, 40, nil, lineWidth)
		:anchorPoint(0, 1)
		:xy(x, y)
		:addTo(parent, 6)
end

local function setGiftTips(parent, typ, isEnBattle)
	local strTyp = typ == 1 and gLanguageCsv.attrDamage or gLanguageCsv.attrSpecialDamage
	if isEnBattle then
		parent:show()
		createRichTxt(gLanguageCsv.todayCharacteristics, 0, 10, parent, 400)
		createRichTxt(string.format(gLanguageCsv.immuneInjury, strTyp), 0, -50, parent, 400)
	else
		createRichTxt(gLanguageCsv.todayCharacteristics..string.format(gLanguageCsv.immuneInjury, strTyp), 0, 10, parent, 1400)
	end
end

local function setFragsTips(view, parent, markIDs, isEnBattle)
	local nodeY = isEnBattle and 2 or -20
	createRichTxt(gLanguageCsv.recommendedToday, 0, nodeY, parent, 1400)
	local cardDatas = {}
	for k,v in orderCsvPairs(markIDs) do
		local cardCsv = csv.cards[v]
		local unitCsv = csv.unit[cardCsv.unitID]
		table.insert(cardDatas, {id = v, rarity = unitCsv.rarity})
	end
	table.sort(cardDatas, function(a,b)
		return a.rarity > b.rarity
	end)
	local starX = 0
	if matchLanguage({"en"}) then
		starX = 300
	elseif matchLanguage({"kr"}) then
		starX = 150
	else
		starX = 110
	end
	for k,v in ipairs(cardDatas) do
		local x, y = starX + k*160, -120
		if isEnBattle then
			parent:show()
			if k <= 3 then
				x, y = (k - 1)*170, -190
			else
				x, y = (k - 4)*170, -330
			end
			parent:get("bg"):size(560, 390)
		end
		local item = ccui.Layout:create()
			:size(0, 0)
			:addTo(parent, 6)
			:xy(x, y)
		bind.extend(view, item, {
			class = "card_icon",
			props = {
				cardId = v.id,
				rarity = v.rarity,
				onNode = function (panel)
					panel:setTouchEnabled(false)
						:scale(0.7)
					panel:get("imgBG"):texture(ui.QUALITY_BOX[v.rarity + 2])
				end,
			}
		})
	end
end
local DailyActivityGateSelectView = class("DailyActivityGateSelectView", cc.load("mvc").ViewBase)
DailyActivityGateSelectView.RESOURCE_FILENAME = "daily_activity_gate_select.json"
DailyActivityGateSelectView.RESOURCE_BINDING = {
	["left.imgBg"] = "background",
	["left.imgIcon"] = "imgIcon",
	["left.textName"] = "title",
	["left.imgEffect"] = "imgEffect",
	["left.flagIcon"] = "flagIcon",
	["left.timeInfo.textTime"] = "openTime",
	["left.textDesc"] = "desc",
	["left.leftUp.textTimes"] = "times",
	["left.doubleFlag"] = "doubleFlag",
	["right.textNote"] = "topTxt",
	["right.btnRank"] = {
		varname = "btnRank",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRankBtn")}
		},
	},
	["right.pos"] = "pos",
	["item"] = "item",
	["right.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("gates"),
				item = bindHelper.self("item"),
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				-- 需要跳到指定位置如果加协程会闪一下
				asyncPreload = 5,
				preloadCenterIndex = bindHelper.self("jumpPos"),
				itemAction = {isAction = true},
				backupCached = false,
				onItem = function(list, node, k, v)
					node:setName("item" .. list:getIdx(k))
					local childs = node:multiget(
						"imgIcon",
						"textLv",
						"textLvNum",
						"list",
						"btnChallenge",
						"unLock",
						"imgLvBg",
						"imgJxBg",
						"btnJxWipe",
						"btnJxNext",
						"imgJxLogo"
					)

					if v.limitGate then
						childs.unLock:hide()
						childs.imgJxBg:show()
						childs.imgJxLogo:show()
						childs.btnJxWipe:visible(not v.isLastGate)
						childs.btnJxWipe:get("textNote"):setFontSize(50)
						childs.btnJxNext:visible(not v.isLastGate)
						childs.btnJxNext:get("textNote"):setFontSize(50)
						childs.btnChallenge:visible(v.isLastGate)
						childs.btnChallenge:setTouchEnabled(v.isLastGate)
						childs.imgJxLogo:get("textNote"):text(string.format(gLanguageCsv.nextLimitGate,v.gateLimitNum))
						childs.btnJxNext:get("textNote"):text(gLanguageCsv.nextGate)
						if v.gateLimitNum == 0 then
							cache.setShader(childs.btnJxWipe, false,"hsl_gray")
							childs.btnJxNext:get("textNote"):text(gLanguageCsv.challenage)
						end
						text.addEffect(childs.imgJxLogo:get("textNote"),{outline = {color = cc.c4b(209, 50,18, 255), size = 5}})
						text.addEffect(childs.btnChallenge:get("textNote"), {glow={color=ui.COLORS.GLOW.WHITE}})
						text.addEffect(childs.btnJxNext:get("textNote"), {glow={color=ui.COLORS.GLOW.WHITE}})
						text.addEffect(childs.btnJxWipe:get("textNote"), {glow={color=ui.COLORS.GLOW.WHITE}})
						bind.touch(list, childs.btnChallenge, {methods = {ended = functools.partial(list.clickCell, k, v)}})
						bind.touch(list, childs.btnJxWipe, {methods = {ended = functools.partial(list.clickCell, k, v)}})
						bind.touch(list, childs.btnJxNext, {methods = {ended = functools.partial(list.clickLimitNext, k, v.gateNextId)}})
					else
						childs.imgJxBg:hide()
						childs.btnJxWipe:hide()
						childs.btnJxNext:hide()
						childs.imgJxLogo:hide()

						--挑战和扫荡按钮
						childs.btnChallenge:get("textNote"):text(BTN_TITLE[v.btnState == BTN_STATE.MOPUP and 1 or 2])
						text.addEffect(childs.btnChallenge:get("textNote"), {glow={color=ui.COLORS.GLOW.WHITE}})
						childs.btnChallenge:get("textNote"):visible(v.btnState ~= BTN_STATE.NOT_UNLOCK)
						childs.btnChallenge:visible(v.btnState == BTN_STATE.CHALLENGE or v.btnState == BTN_STATE.MOPUP)
						--未解锁按钮
						childs.unLock:get("textNote"):text(v.unlockBtnTitle)
						childs.unLock:visible(v.btnState == BTN_STATE.NOT_UNLOCK)
						--如果可以扫荡点击node进入布阵
						-- node:setTouchEnabled(v.btnState == BTN_STATE.MOPUP)
						bind.touch(list, childs.btnChallenge, {methods = {ended = functools.partial(list.clickCell, k, v)}})
						bind.touch(list, childs.unLock, {methods = {ended = functools.partial(list.clickCell, k, v)}})

					end

					bind.touch(list, node, {methods = {ended = functools.partial(list.clickNode, k, v)}})
					childs.imgIcon:texture(v.icon)
					childs.textLvNum:text(v.openLevel)
					childs.imgLvBg:anchorPoint(0, 0.5)
							:x(childs.textLv:box().x - 30)
							:width(math.max(145, childs.textLv:width() + childs.textLvNum:width() + 60))

					uiEasy.createItemsToList(list, childs.list, v.dropIds, {scale = 0.8, margin = 20, onAfterBuild = function()
							local innerItemSize = childs.list:getInnerItemSize(childs.list)
							local width = childs.list:width()
							if innerItemSize.width < width then
								childs.list:x(childs.list:x() + width - innerItemSize.width)
							end
						end})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
				clickNode = bindHelper.self("onNodeClick"),
				clickLimitNext = bindHelper.self("onSkipBattle"),
			},
		},
	},
}

function DailyActivityGateSelectView:onCreate(csvId, flagInfo)
	self:initModel()
	self.csvId = csvId
	local csvHuodong = csv.huodong[csvId]
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = csvHuodong.name, subTitle = "TRANSCRIPT"})

	--左侧面板
	self:setFeltPanel(csvHuodong, flagInfo)
	self.jumpPos = 0
	self.gates = idlers.new()
	self.gateIds = idlertable.new(table.deepcopy(csvHuodong.gateSeq, true))
	self.gateDatas = idlertable.new({})
	self.imgEffect:hide()
	--礼物本数据
	self.btnRank:visible(csvId == 1 or csvId == 2)
	idlereasy.any({self.giftImmuneType, self.giftGroup},function(_, giftImmuneType, giftGroup)
		if csvId == 3 then
			self.list:size(1772, 960)
			local icon = "city/adventure/selectgate/txt_tgmy.png"
			if giftImmuneType == 1 then
				icon = "city/adventure/selectgate/txt_wgmy.png"
			end
			self.imgEffect:show():texture(icon)
			setGiftTips(self.pos, giftImmuneType, false)
			local gateIds = giftGroup == 1 and csvHuodong.gateSeq or csvHuodong.gateSeq2
			self.gateIds:set(table.deepcopy(gateIds, true))
		end
	end)
	--碎片本数据
	idlereasy.when(self.fragGroup,function(_, fragGroup)
		if csvId == 4 then
			self.list:size(1772, 880)
			local csvGateFragment = csv.huodong_gate_fragment[fragGroup]
			setFragsTips(self, self.pos, csvGateFragment.markIDs, false)
			local gateIds = csvGateFragment.gateGroup
			self.gateIds:set(gateIds)
		end
	end)
	idlereasy.when(self.gateIds, function(_, gateIds)
		local gateDatas = {}
		for k,gateId in orderCsvPairs(gateIds) do
			local csvGate = csv.scene_conf[gateId]
			--等级不足提示
			local unlockBtnTitle = gLanguageCsv.currentLevelNotAvailable
			if self.roleLv:read() >= csvGate.openLevel then
				--上一关未完美通关提示
				unlockBtnTitle = gLanguageCsv.notPerfectClearanceNextLevel
			end
			--如果是第一关 等级够了就可以挑战
			local btnState = ((k == 1) and (self.roleLv:read() >= csvGate.openLevel)) and BTN_STATE.CHALLENGE or BTN_STATE.NOT_UNLOCK
			gateDatas[k] = {
				gateId = gateId,
				icon = csvGate.icon,
				dropIds = csvGate.dropIds,
				openLevel = csvGate.openLevel,
				btnState = btnState,
				unlockBtnTitle = unlockBtnTitle,
				limitGate = false,
			}
		end
		self.gateDatas:set(gateDatas)
	end)
	idlereasy.any({self.huodongsGate, self.roleLv, self.gateDatas, self.huodongsIndex},function(_, huodongsGate, roleLv, gateDatas, huodongsIndex)
		local gates = clone(gateDatas)
		local gate = {}
		for k,v in pairs(huodongsIndex) do
			gate[k] = v
		end

		if 	gate[self.csvId] and gate[self.csvId] >= #gates - 1
			and ((self.csvId == 1 and dataEasy.isUnlock(gUnlockCsv.goldLimitMode))
			or (self.csvId == 2 and dataEasy.isUnlock(gUnlockCsv.expLimitMode))) then
				local limitGateNum = gate[self.csvId] + 1 - #gates
				local gateId = limitGateNum == 0 and csvHuodong.gateLimitSeq[1] or csvHuodong.gateLimitSeq[limitGateNum]
				local isLastGate = limitGateNum == csvSize(csvHuodong.gateLimitSeq)
				local nextGateId = isLastGate and gateId or csvHuodong.gateLimitSeq[limitGateNum + 1]
				local csvGate = csv.scene_conf[gateId]
				gates[#gates+1] ={
					gateId = gateId,
					gateNextId = nextGateId,
					icon = csvGate.icon,
					dropIds = csvGate.dropIds,
					openLevel = csvGate.openLevel,
					gateLimitNum = limitGateNum , --0表示第一关
					isLastGate = isLastGate,
					btnState = BTN_STATE.MOPUP,
					limitGate = true,
				}
		end

		if huodongsGate[csvId] then
			for i,v in ipairs(gates) do
				if not v.limitGate then
					local canMopUp = false
					-- 如果是礼物本和碎片本 下一关等级足够 当前关卡才可以扫荡 最后一关不能扫荡
					if csvHuodong.type == "gold" or csvHuodong.type == "exp" or csvHuodong.type == "event" then
						local starNum = huodongsGate[csvId][v.gateId] or 0
						if starNum == 3 then
							canMopUp = true
						end
					else
						if huodongsIndex then
							--记录礼物碎片本 进度 从0开始 默认为空
							local canMopUpIndex = (huodongsIndex[csvId] or -1) + 1
							if canMopUpIndex >= i then
								if (csvHuodong.type == "gift" and dataEasy.isUnlock(gUnlockCsv.dailyGiftGate)) or (gates[i+1] and (roleLv >= gates[i+1].openLevel)) then
									canMopUp = true
								end
							end
						end
					end
					if roleLv < v.openLevel then
						gates[i].btnState = BTN_STATE.NOT_UNLOCK
					elseif canMopUp then
						gates[i].btnState = BTN_STATE.MOPUP
						if gates[i+1] and roleLv >= gates[i+1].openLevel then
							gates[i+1].btnState = BTN_STATE.CHALLENGE
							--跳到可挑战最大等级
							self.jumpPos = self.jumpPos + 1
						end
					end
				end
			end
		end
		self.gates:update(gates)
	end)
	local huodongType = {
		{game.PRIVILEGE_TYPE.HuodongTypeGoldTimes, game.PRIVILEGE_TYPE.HuodongTypeGoldDropRate, gLanguageCsv.gold},
		{game.PRIVILEGE_TYPE.HuodongTypeExpTimes, game.PRIVILEGE_TYPE.HuodongTypeExpDropRate, gLanguageCsv.expLiquid},
		{game.PRIVILEGE_TYPE.HuodongTypeGiftTimes, game.PRIVILEGE_TYPE.HuodongTypeGiftDropRate, gLanguageCsv.favouriteGift},
		{game.PRIVILEGE_TYPE.HuodongTypeFragTimes, game.PRIVILEGE_TYPE.HuodongTypeFragDropRate, gLanguageCsv.spriteFrags},
	}

	--副本次数
	idlereasy.when(self.huodongs,function(_, huodongs)
		local currType = huodongType[csvHuodong.huodongType] or {}
		local addTime =  currType[1] and dataEasy.getPrivilegeVal(currType[1]) or 0

		if flagInfo and flagInfo.show and flagInfo.type == 2 then
			addTime = addTime + flagInfo.paramMap.count or 0
		end

		local surplusTimes = csvHuodong.times + addTime
		local curDate = tonumber(time.getTodayStrInClock())
		if huodongs[curDate] and huodongs[curDate][csvId] then
			surplusTimes = surplusTimes - huodongs[curDate][csvId].times
		end
		surplusTimes = math.max(surplusTimes, 0)
		self.surplusTimes = surplusTimes
		self.times:text(surplusTimes.."/"..(csvHuodong.times + addTime))
		self.topTxt:removeAllChildren()
		if currType[2] then
			local pos = cc.p(self.topTxt:size().width, self.topTxt:size().height)
			uiEasy.setPrivilegeRichText(currType[2], self.topTxt, huodongType[csvHuodong.huodongType][3], pos, true)
		end
	end)

end

function DailyActivityGateSelectView:initModel()
	--huodongs  -- {date: {huodong_id: {times: 0, last_time: 123455}}}
	self.huodongs = gGameModel.role:getIdler("huodongs")
	--huodongs_gate -- {huodong_id:{gateID:star}}
	self.huodongsGate = gGameModel.role:getIdler("huodongs_gate")
	self.roleLv = gGameModel.role:getIdler("level")
	-- 1-2 礼物副本关卡
	self.giftGroup = gGameModel.global_record:getIdler("huodong_gift_group")
	-- 1-6 碎片本关卡
	self.fragGroup = gGameModel.global_record:getIdler("huodong_frag_group")
	-- physical special
	self.giftImmuneType = gGameModel.global_record:getIdler("huodong_gift_immune_type")

	self.huodongsIndex = gGameModel.role:getIdler("huodongs_index")
end
--左侧面板
function DailyActivityGateSelectView:setFeltPanel(csvHuodong, flagInfo)
	self.background:texture(csvHuodong.background)
	self.imgIcon:texture(csvHuodong.icon)
	self.title:text(csvHuodong.name)
	self.doubleFlag:visible(flagInfo.isDoubleAward)

	if flagInfo then
		self.flagIcon:visible(flagInfo.show)
		self.flagIcon:get("textNote"):text(REWARD_TYPE[flagInfo.type])
	end

	self.openTime:text(csvHuodong.openTimeDesc)
	self.desc:text(csvHuodong.desc)
	self.topTxt:text(csvHuodong.desc)
end
function DailyActivityGateSelectView:onRankBtn()
	gGameApp:requestServer("/game/rank", function(tb)
		gGameUI:stackUI("city.adventure.daily_activity.rank", nil, nil, tb.view)
	end, "huodong_" .. self.csvId, 0, 50)
end

function DailyActivityGateSelectView:onSkipBattle(list, k, gateId)
	if self.surplusTimes <= 0 then
		gGameUI:showTip(gLanguageCsv.timesLimitBreakBrick)
		return
	end
	self.gateId = gateId
	local closeTb = self:createHandler("onClose")
	gGameUI:stackUI("city.card.embattle.base", nil, {full = true}, {
		from = game.EMBATTLE_FROM_TABLE.huodong,
		fromId = self.csvId,
		fightCb = self:createHandler("startFighting"),
		startCb = self:createHandler("showTip"),
		team = true,
	})
end
--飘字提示
function DailyActivityGateSelectView:showTip(view)
	if self.csvId == 3 then
		setGiftTips(view.dailyGateTipsPos, self.giftImmuneType:read(), true)
	end
	if self.csvId == 4 then
		local csvGateFragment = csv.huodong_gate_fragment[self.fragGroup:read()]
		setFragsTips(self, view.dailyGateTipsPos, csvGateFragment.markIDs, true)
	end
end

--battleCards 当前阵容
function DailyActivityGateSelectView:startFighting(view, battleCards)
	battleEntrance.battleRequest("/game/huodong/start", battleCards, self.csvId, self.gateId)
		:onStartOK(function(data)
			if view then
				view:onClose(false)
				view = nil
			end
		end)
		:show()
end

function DailyActivityGateSelectView:onItemClick(list, k, v)
	self.gateId = v.gateId
	if v.limitGate and v.gateLimitNum == 0 then
		gGameUI:showTip(gLanguageCsv.notSwipe)
	elseif	v.limitGate or v.btnState == BTN_STATE.MOPUP then
		self:onSweepBtn()
	elseif v.btnState == BTN_STATE.CHALLENGE then
		self:onSkipBattle(list, k, v.gateId)
	elseif v.btnState == BTN_STATE.NOT_UNLOCK then
		local txt = gLanguageCsv[self.roleLv:read() >= v.openLevel and "notPerfectClearanceNextLevel" or "currentLevelNotAvailable"]
		gGameUI:showTip(txt)
	end
end

-- desc 整个item的点击响应，与按钮共存，但有区别：扫荡条件下，点击响应不同，按钮是直接扫荡，item是进入挑战流程
function DailyActivityGateSelectView:onNodeClick(list, k, v)
	self.gateId = v.gateId
	if v.limitGate and v.gateLimitNum == 0 then
		self.gateId = v.nextGateId
	end
	if v.btnState == BTN_STATE.MOPUP or  v.btnState == BTN_STATE.CHALLENGE then
		self:onSkipBattle(list, k, v.gateId)
	elseif v.btnState == BTN_STATE.NOT_UNLOCK then
		local txt = gLanguageCsv[self.roleLv:read() >= v.openLevel and "notPerfectClearanceNextLevel" or "currentLevelNotAvailable"]
		gGameUI:showTip(txt)
	end
end

function DailyActivityGateSelectView:onSweepBtn()
	if self.surplusTimes <= 0 then
		gGameUI:showTip(gLanguageCsv.saodangTimesNotEnough)
		return
	end
	local oldRoleLv = self.roleLv:read()
	gGameApp:requestServer("/game/huodong/saodang",function (tb)
		gGameUI:showGainDisplay(tb, {isDouble = dataEasy.isGateIdDoubleDrop(self.gateId)})
	end,self.csvId,self.gateId,1)
end

function DailyActivityGateSelectView:onAfterBuild()
	self.list:jumpToItem(self.jumpPos, cc.p(0, 1), cc.p(0, 1))
end

function DailyActivityGateSelectView:onSortCards(list)
	return function(a, b)
		if a.openLevel ~= b.openLevel then
			return a.openLevel < b.openLevel
		end
		return a.gateId < b.gateId
	end
end

return DailyActivityGateSelectView
