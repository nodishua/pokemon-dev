-- @date 2020-7-28
-- @desc 实时匹配主界面

local STATE_TYPE = {
	normal = 1,
	matching = 2,
	enemy = 3,
}

local SERVER_STEP = 10

local function getServersShow(servers)
	local lastId
	local firstStr, lastStr
	local t = {}
	local step = 0
	for _, server in ipairs(servers) do
		local id = getServerId(server, true)
		if not firstStr then
			lastId = id
			firstStr = getServerArea(server, nil, true)
			step = step + 1
		else
			if id ~= lastId + 1 or step >= SERVER_STEP then
				if not lastStr then
					table.insert(t, string.format(gLanguageCsv.brackets, firstStr))
				else
					table.insert(t, string.format(gLanguageCsv.brackets, string.format("%s ~ %s", firstStr, lastStr)))
				end
				lastStr = nil
				firstStr = getServerArea(server, nil, true)
				step = 0
			else
				lastStr = getServerArea(server, nil, true)
			end
			lastId = id
			step = step + 1
		end
	end
	if lastId then
		if not lastStr then
			table.insert(t, string.format(gLanguageCsv.brackets, firstStr))
		else
			table.insert(t, string.format(gLanguageCsv.brackets, string.format("%s ~ %s", firstStr, lastStr)))
		end
	end
	return t
end

local OnlineFightView = class("OnlineFightView", cc.load("mvc").ViewBase)

OnlineFightView.RESOURCE_FILENAME = "online_fight.json"
OnlineFightView.RESOURCE_BINDING = {
	["firstPanel"] = "firstPanel",
	["firstPanel.tipTime"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(50, 18, 6, 255)}},
		},
	},
	["firstPanel.item"] = "serverItem",
	["firstPanel.subList"] = "serverSubList",
	["firstPanel.list"] = {
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("servers"),
				item = bindHelper.self("serverSubList"),
				cell = bindHelper.self("serverItem"),
				columnSize = 2,
				onCell = function(list, node, k, v)
					node:get("name"):text(v)
				end,
			},
		},
	},
	["mainPanel"] = "mainPanel",
	["mainPanel.startBtn"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onStartBtnClick")
		},
	},
	["mainPanel.startBtn.longtimePanel"] = {
		varname = "longtimePanel",
		binds = {
			event = "click",
			method = bindHelper.self("onLongtimeModelClick")
		},
	},
	["mainPanel.startBtn.longtimePanel.tip"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(50, 18, 6, 255)}},
		},
	},
	["mainPanel.rankBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRankClick")}
		},
	},
	["mainPanel.rankRewardBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRankRewardClick")}
		},
	},
	["mainPanel.awardPanel.awardBtn"] = {
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onTargetAwardClick")}
			}, {
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "onlineFightAward",
				}
			}
		},
	},
	["mainPanel.awardPanel.awardBtn.barTxt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(50, 18, 6, 255)}},
		},
	},
	["mainPanel.awardPanel.time"] = {
		varname = "awardPanelTime",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(50, 18, 6, 255)}},
		},
	},
	["mainPanel.rightPanel.switchBtn"] = {
		binds = {
			event = "touch",
			scaletype = 0,
			methods = {ended = bindHelper.self("onSwitchModelClick")}
		},
	},
	["mainPanel.rightPanel.descPanel.tip"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onModelTipClick")}
		},
	},
	["mainPanel.rightPanel.descPanel.title"] = {
		varname = "modelDescTitle",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(83, 54, 6, 255)}},
		},
	},
	["mainPanel.rightPanel.descPanel.list"] = "modelDescList",
	["mainPanel.timePanel.time"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(83, 54, 6, 255)}},
		},
	},

	["mainPanel.rightPanel.unlimitedPanel.tip"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onModelUnlimitedTipClick")}
		},
	},
	["mainPanel.rightPanel.unlimitedPanel.title"] = {
		varname = "modelUnlimitTitle",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(83, 54, 6, 255)}},
		},
	},
	["mainPanel.rightPanel.unlimitedPanel.item"] = "unlimtItem",
	["mainPanel.rightPanel.unlimitedPanel.list"] = {
		varname = "unlimitedBanList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("unlimitedBanCards"),
				item = bindHelper.self("unlimtItem"),
				onItem = function(list, node, k, v)
					local unitCsv = csv.unit[v.unitID]
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							unitId = v.unitID,
							rarity = unitCsv.rarity,
							onNode = function(panel)
								panel:scale(0.7)
							end,
						}
					})
				end,
				onAfterBuild = function (list)
					list:setItemAlignCenter()
				end
			},
		}
	},
	["mainPanel.timePanel.time"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(83, 54, 6, 255)}},
		},
	},



	["mainPanel.startBtn.tip"] = {
		varname = "startTip",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(50, 18, 6, 255)}},
		},
	},
	["matchingPanel"] = "matchingPanel",
	["matchingPanel.time"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(50, 18, 6, 255)}},
		},
	},
	["displayPanel"] = "displayPanel",
	["leftBtn"] = "leftBtn",
	["leftBtn.rule.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(50, 18, 6, 255)}},
		},
	},
	["leftBtn.shop.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(50, 18, 6, 255)}},
		},
	},
	["leftBtn.record.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(50, 18, 6, 255)}},
		},
	},
	["leftBtn.embattle.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(50, 18, 6, 255)}},
		},
	},
	["leftBtn.rank.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(50, 18, 6, 255)}},
		},
	},
	["leftBtn.rule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleClick")}
		},
	},
	["leftBtn.shop"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShopClick")}
		},
	},
	["leftBtn.record"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRecordClick")}
		},
	},
	["leftBtn.embattle"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onEmbattleClick")}
		},
	},
	["leftBtn.rank"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRankClick")}
		},
	},
	["enemyPanel"] = "enemyPanel",
	["banTipPanel"] = {
		varname = "banTipPanel",
		binds = {
			event = "click",
			method = bindHelper.self("onBanTipPanelClick"),
		},
	},
	["banUnlimitedTipPanel"] = {
		varname = "banUnlimitedTipPanel",
		binds = {
			event = "click",
			method = bindHelper.self("onBanUnlimitedTipPanelClick"),
		},
	},

	["rightBtn"] = "rightBtn",
	["displayPanel.tip"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(41, 20, 9, 255)}},
		},
	},
	["rightBtn.limitedRank"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onLimitedRankClick")}
		},
	},
	["rightBtn.unlimitedRank"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onUnlimitedRankClick")}
		},
	},
}

function OnlineFightView:onCreate()
	self.topuiView = gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.onlineFight, subTitle = "BATTLE ARENA"})
	self:initModel()
	self:enableSchedule()
	self.startTip:text(gLanguageCsv.onlineFightGameTime)
	self.switchEffect = widget.addAnimationByKey(self.mainPanel, "battlearena/shishipipei.skel", "switchEffect", "kaimen_effect", 0)
		:alignCenter(self.mainPanel:size())
		:scale(2)
	self.rightIconEffect = widget.addAnimationByKey(self.mainPanel, "battlearena/shishipipei.skel", "rightIconEffect", "fanpai_1_effect", 1)
		:alignCenter(self.mainPanel:size())
		:scale(2)
	self.startBtnEffect = widget.addAnimationByKey(self.mainPanel, "battlearena/shishipipei.skel", "startBtnEffect", "shanzi_loop", 11)
		:alignCenter(self.mainPanel:size())
		:scale(2)
	local embattlePanel = self.leftBtn:get("embattle")
	embattlePanel:get("bg"):hide()
	embattlePanel:get("icon"):hide()
	self.embattleBtnEffect = widget.addAnimationByKey(embattlePanel, "battlearena/shishipipei.skel", "embattleBtnEffect", "denglong_loop", 1)
		:xy(90, 135)
		:scale(2)
	self.sceneEffect = widget.addAnimationByKey(self:getResourceNode(), "battlearena/shishipipei.skel", "sceneEffect", "kspp_wxzs_effect", 100)
		:xy(display.sizeInView.width/2, display.sizeInView.height/2)
		:scale(2)
		:z(100)
		:hide()
	self.longtimePanel:get("tip"):text(gLanguageCsv.onlineFightLongtimeText)
	adapt.oneLineCenterPos(cc.p(140, 40), {self.longtimePanel:get("btn"), self.longtimePanel:get("tip")}, cc.p(20, 0))
	self.longtimePanel:get("bg"):width(self.longtimePanel:get("btn"):width() + self.longtimePanel:get("tip"):width() + 50)

	self.mainPanel:get("rightPanel.name"):setOpacity(0)
	self:setRolePanel()
	self.servers = idlers.newWithMap({})
	local baseCfg = csv.cross.online_fight.base[1]
	local isFirst = true
	self.hasBanCard = true	-- 无限制本周有禁用精灵
	self.banCardInBattle = false	-- 阵容中有禁用卡牌

	self.switchModel = idler.new(userDefault.getForeverLocalKey("onlineFightSwitchModel", "limited")) -- 1、限制模式 公平赛； 2、无限制模式
	self.switchDisplayRank = idler.new(userDefault.getForeverLocalKey("onlineFightSwitchDisplayRank", "limited")) -- 1、限制模式 公平赛； 2、无限制模式
	self.matchState = idler.new(STATE_TYPE.normal)
	self.longtimeoutModel = idler.new(userDefault.getForeverLocalKey("onlineFightLongtimeout", false))
	self.unlimitedBanCards = idlers.newWithMap({})
	self:refreshUnlimitedCards()
	local inExpandServers = false
	local gameKey = userDefault.getForeverLocalKey("serverKey", nil, {rawKey = true})
	local tag = getServerTag(gameKey)
	for _, v in csvPairs(csv.cross.online_fight.expand_servers) do
		if tag == v.cross then
			for _, server in csvMapPairs(v.servers) do
				if gameKey == server then
					inExpandServers = true
					break
				end
	 		end
		end
		if inExpandServers then
			break
		end
	end
	idlereasy.when(self.longtimeoutModel, function(_, longtimeoutModel)
		self.longtimePanel:get("btn"):texture(longtimeoutModel and "common/icon/radio_selected.png" or "common/icon/radio_normal.png")
	end)

	idlereasy.when(self.matchResult, function(_, matchResult)
		self.matchingPanel:stopAllActions()
		self:unSchedule("matching")
		if type(matchResult) == "table" then
			if not itertools.isempty(matchResult.enemy) then
				self:showEnemy()
				return
			end
			if matchResult.matching and matchResult.matching > 0 then
				local longtimeout = userDefault.getForeverLocalKey("onlineFightLongtimeout", false)
				local passTime = math.floor(time.getTime() - matchResult.matching)
				local limitedTime = longtimeout and baseCfg.longMatchTimeout or baseCfg.normalMatchTimeout
				local leftTime = cc.clampf(limitedTime - passTime, 0, limitedTime)
				local maxTime = time.getTime() + leftTime + 10
				local matchAdapt = false
				local str = gLanguageCsv.onlineFightInMatching
				if inExpandServers then
					if self.switchModel:read() == "limited" then
						if baseCfg.expandLimitedOpen and self.limitedScore:read() >= baseCfg.expandLimitedOpenScore then
							str = gLanguageCsv.onlineFightExpandServers
						end
					else
						if baseCfg.expandUnlimitedOpen and self.unlimitedScore:read() >= baseCfg.expandUnlimitedOpenScore then
							str = gLanguageCsv.onlineFightExpandServers
						end
					end
				end

				local function setLabel(sec)
					sec = math.max(sec, 0)
					self.matchingPanel:get("time"):text(string.format("%s %s s", str, sec))
					if not matchAdapt then
						matchAdapt = true
						adapt.oneLineCenterPos(cc.p(1540, 530), {self.matchingPanel:get("icon"), self.matchingPanel:get("time")}, cc.p(20, 0))
					end
				end
				setLabel(passTime)
				-- 界面倒计时比服务器倒计时多10s, 还未收到服务器返回，则关闭回到普通状态
				local hasSendCancel
				self:schedule(function(dt)
					local passTime = math.floor(time.getTime() - matchResult.matching)
					setLabel(passTime)
					if not hasSendCancel and time.getTime() > maxTime then
						hasSendCancel = true
						gGameApp:requestServer("/game/cross/online/cancel")
					end
				end, 1, 1, "matching")
				self.matchState:set(STATE_TYPE.matching)
				return
			end
		end
		self.matchState:set(STATE_TYPE.normal)
	end)

	self.leftBtn:show()
	idlereasy.any({self.round, self.matchState}, function(_, round, matchState)
		-- start 开赛中，over 开赛不能打
		itertools.invoke({self.firstPanel, self.mainPanel, self.matchingPanel, self.displayPanel, self.enemyPanel, self.banTipPanel, self.banUnlimitedTipPanel, self.rightBtn}, "hide")
		self.firstPanel:stopAllActions()
		self.leftBtn:get("embattle"):show()
		self.leftBtn:get("rank"):hide()
		if round == "closed" then
			local state, cfg = self:getCloseState()
			if state == "display" then
				self.switchDisplayRank:notify()
				self.displayPanel:show()
				self.rightBtn:show()
				self.leftBtn:show()
				self.leftBtn:get("embattle"):hide()
				self.leftBtn:get("rank"):show()
			else
				itertools.invoke({self.firstPanel, self.leftBtn}, "show")
				local tipTime = self.firstPanel:get("tipTime")
				local emptyPanel = self.firstPanel:get("emptyPanel")
				tipTime:hide()
				emptyPanel:hide()
				if state == "notice" then
					local t = getServersShow(getMergeServers(cfg.servers))
					self.servers:update(t)
					local year, month, day = time.getYearMonthDay(cfg.date, true)
					local startDate = string.formatex(gLanguageCsv.timeMonthDay, {month = month, day = day})
					local year, month, day = time.getYearMonthDay(cfg.endDate, true)
					local endDate = string.formatex(gLanguageCsv.timeMonthDay, {month = month, day = day})
					tipTime:show():text(string.format(gLanguageCsv.onlineFightNoticeTime, startDate, endDate))
				else
					emptyPanel:show()
				end
			end
		else
			local awardTime = csv.cross.online_fight.base[1].awardTime
			local endDate = time.getNumTimestamp(gGameModel.cross_online_fight:read("end_date"), time.getHourAndMin(awardTime, true))
			bind.extend(self, self.mainPanel:get("timePanel.time"), {
				class = 'cutdown_label',
				props = {
					delay = 1,
					endTime = endDate,
					strFunc = function(t)
						return gLanguageCsv.onlineFightSceneLeft .. " " .. t.str
					end,
				}
			})
			-- 设置结束后刷新
			self:setRoundTimer(endDate, "closed")
			self.mainPanel:show()
			self.topuiView:hide()
			local function showState()
				nodetools.invoke(self.mainPanel, {"rankDesk", "rankBtn", "rankRewardBtn", "leftBtnBg", "timePanel", "awardPanel"}, "visible", matchState == STATE_TYPE.normal)
				nodetools.invoke(self.mainPanel:get("rightPanel"), {"switchBtn"}, "visible", matchState == STATE_TYPE.normal)
				self.leftBtn:visible(matchState == STATE_TYPE.normal)
				self.matchingPanel:visible(matchState == STATE_TYPE.matching)
				self.enemyPanel:visible(matchState == STATE_TYPE.enemy)
				self.topuiView:visible(matchState == STATE_TYPE.normal)
				self.mainPanel:get("rightPanel.descPanel"):visible(matchState == STATE_TYPE.normal and self.switchModel:read() == "limited")
				self.mainPanel:get("rightPanel.unlimitedPanel"):visible(self.hasBanCard and matchState == STATE_TYPE.normal and self.switchModel:read() ~= "limited")
				self:resetRankPointSprite()
			end
			if isFirst then
				showState()
			else
				performWithDelay(self, showState, 35/30)
			end

			local themeId = gGameModel.cross_online_fight:read("theme_id")
			local lastThemeId = userDefault.getForeverLocalKey("onlineFightLastThemeId")
			if lastThemeId ~= themeId then
				userDefault.setForeverLocalKey("onlineFightLastThemeId", themeId)
				if themeId ~= 0 then
					gGameUI:stackUI("city.pvp.online_fight.theme", nil, {full = false, clickClose = true, blackLayer = true})
				end
				userDefault.setForeverLocalKey("onlineFightSwitchModel", "limited")
				self.switchModel:set("limited")
			end
			self:refreshRightPanel()
		end
	end)
	idlereasy.when(self.matchState, function(_, matchState)
		self.rightIconEffect:play(self:getRightIconEffectName())
		if not isFirst then
			if matchState == STATE_TYPE.normal or matchState == STATE_TYPE.matching then
				self.startBtnEffect:play("shanzi_effect")
				local effectName = "kspp_wxzs_effect"
				if self.switchModel:read() == "limited" then
					effectName = "kspp_gps2_effect"
					if self.limitedScore:read() >= baseCfg.limitedBanScore then
						effectName = "kspp_gps1_effect"
					end
				end
				self.sceneEffect:show():play(effectName)
				-- 动画表现时间屏蔽点击
				gGameUI:disableTouchDispatch(70/30)
				transition.executeSequence(self.mainPanel:get("startBtn.name"), true)
					:spawnBegin()
						:fadeOut(6/30)
						:scaleTo(6/30, 0.5, 1)
					:spawnEnd()
					:func(function()
						self.mainPanel:get("startBtn.name"):texture(matchState == STATE_TYPE.normal and "city/pvp/online_fight/txt_kspp.png" or "city/pvp/online_fight/txt_qx.png")
					end)
					:delay(60/30)
					:spawnBegin()
						:fadeIn(6/30)
						:scaleTo(6/30, 1, 1)
					:spawnEnd()
					:done()
			end
		else
			self.mainPanel:get("startBtn.name"):texture(matchState == STATE_TYPE.normal and "city/pvp/online_fight/txt_kspp.png" or "city/pvp/online_fight/txt_qx.png")
		end
	end)

	idlereasy.when(self.switchModel, function(_, switchModel)
		transition.executeSequence(self.mainPanel:get("rightPanel.name"), true)
			:fadeOut(6/30)
			:func(function()
				self.mainPanel:get("rightPanel.name"):texture(switchModel == "limited" and "city/pvp/online_fight/txt_gps.png" or "city/pvp/online_fight/txt_wxzs.png")
			end)
			:delay(18/30)
			:fadeIn(6/30)
			:done()
		self.mainPanel:get("rightPanel.descPanel"):visible(switchModel == "limited")
		self.mainPanel:get("rightPanel.unlimitedPanel"):visible(switchModel == "unlimited" and self.hasBanCard)
		if switchModel == "limited" then
			self.switchEffect:play("kaimen_effect")
			if not isFirst then
				self.embattleBtnEffect:play("denglong_effect")
			end
		else
			self.switchEffect:play("guanmen_effect")
		end

		self.rightIconEffect:play(self:getRightIconEffectName())
	end)

	local iconRes = {"common/btn/btn_normal.png", "common/btn/btn_recharge.png"}
	local nameColor = {ui.COLORS.NORMAL.WHITE, ui.COLORS.NORMAL.RED}
	idlereasy.when(self.switchDisplayRank, function(_, switchDisplayRank)
		if self.round:read() == "closed" then
			userDefault.setForeverLocalKey("onlineFightSwitchDisplayRank", switchDisplayRank)
			local flag = switchDisplayRank == "limited" and 1 or 2
			self.rightBtn:get("limitedRank.icon"):texture(iconRes[flag])
			text.addEffect(self.rightBtn:get("limitedRank.name"), {color = nameColor[flag]})
			self.rightBtn:get("unlimitedRank.icon"):texture(iconRes[3 - flag])
			text.addEffect(self.rightBtn:get("unlimitedRank.name"), {color = nameColor[3 - flag]})
			self:resetDisplayTop()
		end
	end)

	-- # 周目标奖励，flag: 0-已领取,1-可领取
	local weeklyTargetData = {}
	for k, v in orderCsvPairs(csv.cross.online_fight.weekly_target) do
		if v.type == baseCfg.weeklyTarget then
			table.insert(weeklyTargetData, {csvId = k, cfg = v})
		end
	end
	table.sort(weeklyTargetData, function(a, b)
		return a.cfg.count < b.cfg.count
	end)
	local awardPanel = self.mainPanel:get("awardPanel")
	idlereasy.any({self.onlineFightInfo}, function(_, onlineFightInfo)
		local weeklyTarget = onlineFightInfo.weekly_target or {}
		local winTimes = onlineFightInfo.weekly_win_times or 0 -- # 本周胜场次数
		local battleTimes = onlineFightInfo.weekly_battle_times or 0 -- # 本周战斗次数
		local showIdx = #weeklyTargetData
		for i, v in ipairs(weeklyTargetData) do
			if not weeklyTarget[v.csvId] or weeklyTarget[v.csvId] == 1 then
				showIdx = i
				break
			end
		end
		local data = weeklyTargetData[showIdx]
		local times = (baseCfg.weeklyTarget == 1) and winTimes or battleTimes or 0
		awardPanel:get("awardBtn.barTxt"):text(times .. "/" .. data.cfg.count)
		awardPanel:get("awardBtn.bar"):setPercent(math.min(times/data.cfg.count*100, 100))
		awardPanel:removeChildByName("effect")
		if weeklyTarget[data.csvId] == 1 then
			widget.addAnimationByKey(awardPanel, "effect/jiedianjiangli.skel", "effect", "effect_loop", 1)
				:scale(0.8)
				:xy(150, 100)
		end
		uiEasy.addVibrateToNode(self, awardPanel:get("awardBtn"), weeklyTarget[data.csvId] == 1, "weeklyTarget")

		self.weeklyTargetState = {
			flag = weeklyTarget[data.csvId],
			cfg = data.cfg,
			csvId = data.csvId,
		}
	end)
	-- 每周一5点重置周目标
	self:setWeeklyTargetTimer()

	local list, itemHeight = beauty.textScroll({
		list = self.banTipPanel:get("list"),
		strs = {
			{str = "#C0x5B545B#" ..  string.format(gLanguageCsv.onlineFightBanTip1, baseCfg.limitedBanScore)},
			{str = "#C0x5B545B#" ..  gLanguageCsv.onlineFightBanTip2},
		},
		isRich = true,
		margin = 20,
	})
	list:height(itemHeight)
	self.banTipPanel:get("bg"):height(itemHeight+90)

	--无限制
	local nulimitedList, itemHeight = beauty.textScroll({
		list = self.banUnlimitedTipPanel:get("list"),
		strs = {
			{str = "#C0x5B545B#" ..  gLanguageCsv.onlineFightBanTip3},
			{str = "#C0x5B545B#" ..  gLanguageCsv.onlineFightBanTip4},
		},
		isRich = true,
		margin = 20,
	})
	nulimitedList:height(itemHeight)
	self.banUnlimitedTipPanel:get("bg"):height(itemHeight+90)

	isFirst = false
end

function OnlineFightView:initModel()
	self.matchResult = gGameModel.cross_online_fight:getIdler("match_result")
	self.round = gGameModel.cross_online_fight:getIdler("round")
	self.unlimitedRank = gGameModel.cross_online_fight:getIdler("unlimited_rank") -- # 无限制排名
	self.unlimitedScore = gGameModel.cross_online_fight:getIdler("unlimited_score") -- # 无限制积分
	self.limitedRank = gGameModel.cross_online_fight:getIdler("limited_rank") -- # 公平赛排名
	self.limitedScore = gGameModel.cross_online_fight:getIdler("limited_score") -- # 公平赛积分
	self.onlineFightInfo = gGameModel.role:getIdler("cross_online_fight_info") -- # weekly_target 周目标奖励，flag: 0-已领取,1-可领取
	self.startDate = gGameModel.cross_online_fight:getIdler("start_date") -- 开始日期
end

function OnlineFightView:getCloseState()
	local id = dataEasy.getCrossServiceData("onlinefight")
	if id then
		local cfg = csv.cross.service[id]
		local startTime = time.getNumTimestamp(cfg.date, 5) -- 开赛前两天预告
		local curTime = time.getTime()
		if curTime >= startTime - 2 * 24 * 3600 then
			self:setRoundTimer(startTime - curTime + 1, "over")
			return "notice", cfg
		end
	end
	local data = gGameModel.cross_online_fight:read("limited_history_top") or gGameModel.cross_online_fight:read("unlimited_history_top")
	if not itertools.isempty(data) then
		-- 有上期数据显示展示界面
		return "display"
	end
end

function OnlineFightView:setRoundTimer(endTime, state)
	local round = self.round:read()
	if round == state then
		return
	end
	if endTime < 0 then
		endTime = 10
	end
	performWithDelay(self.firstPanel, function()
		gGameApp:requestServer("/game/cross/online/main", functools.handler(self, "setRoundTimer", 10, state))
	end, endTime)
end

function OnlineFightView:setRolePanel()
	local rolePanel = self.mainPanel:get("rolePanel")
	rolePanel:removeAllChildren()

	local size = rolePanel:size()
	local figure = gGameModel.role:read("figure")
	local figureCfg = gRoleFigureCsv[figure]
	if figureCfg.resSpine ~= "" then
		widget.addAnimationByKey(rolePanel, figureCfg.resSpine, "figure", "standby_loop1", 4)
			:xy(size.width / 2, 30)
			:scale(1.6)
	end
	local title = gGameModel.role:read('title_id')
	if title > 0 then
		bind.extend(self, rolePanel, {
			event = "extend",
			class = "role_title",
			props = {
				data = title,
				onNode = function(node)
					node:xy(size.width / 2, size.height - 100)
						:scale(1.3)
						:z(5)
				end
			}
		})
	end
end

function OnlineFightView:setWeeklyTargetTimer()
	local curTime = time.getTime()
	local targetTime = time.getNumTimestamp(time.getWeekStrInClock(0))
	if targetTime <= curTime then
		targetTime = targetTime + 7 * 24 * 3600
	end
	if targetTime < curTime then
		self.mainPanel:get("awardPanel.time"):text("")
		performWithDelay(self, function()
			self:setWeeklyTargetTimer()
		end, 10)
		return
	end
	bind.extend(self, self.mainPanel:get("awardPanel.time"), {
		class = 'cutdown_label',
		props = {
			delay = 1,
			endTime = targetTime,
			strFunc = function(t)
				return t.str .. " " .. gLanguageCsv.onlineFightWeeklyTargetReset
			end,
			endFunc = function()
				gGameApp:requestServer("/game/cross/online/main", functools.partial(self.setWeeklyTargetTimer, self))
			end,
		}
	})
end

function OnlineFightView:refreshRightPanel()
	local baseCfg = csv.cross.online_fight.base[1]
	local themeId = gGameModel.cross_online_fight:read("theme_id")
	local themeCfg = csv.cross.online_fight.theme[themeId]
	if not themeCfg or not themeCfg.desc or themeCfg.desc == "" then
		self.modelDescList:hide()
	else
		self.modelDescList:show()
		beauty.textScroll({
			list = self.modelDescList,
			strs = " " .. gLanguageCsv.onlineFightTheme .. themeCfg.desc,
			effect = {color = ui.COLORS.NORMAL.WHITE, outline = {color = cc.c4b(83, 54, 6, 255)}},
		})
	end
	idlereasy.any({self.unlimitedRank, self.unlimitedScore, self.limitedRank, self.limitedScore, self.switchModel}, function(_, unlimitedRank, unlimitedScore, limitedRank, limitedScore, switchModel)
		local rankPointPanel = self.mainPanel:get("rankPointPanel")
		if switchModel == "limited" then
			rankPointPanel:get("txt1"):text(gLanguageCsv.onlineFightMyRank .. (limitedRank == 0 and gLanguageCsv.onlineFightNoMatch or limitedRank))
			rankPointPanel:get("txt2"):text(gLanguageCsv.onlineFightMyPoint .. limitedScore)
		else
			rankPointPanel:get("txt1"):text(gLanguageCsv.onlineFightMyRank .. (unlimitedRank == 0 and gLanguageCsv.onlineFightNoMatch or unlimitedRank))
			rankPointPanel:get("txt2"):text(gLanguageCsv.onlineFightMyPoint .. unlimitedScore)
		end
		if limitedScore >= baseCfg.limitedBanScore then
			self.modelDescTitle:text(gLanguageCsv.onlineFightModelLimited2)
		else
			self.modelDescTitle:text(gLanguageCsv.onlineFightModelLimited1)
		end
		self.modelUnlimitTitle:text(gLanguageCsv.onlineFightUnlimitedBanCard)
	end):anonyOnly(self)
end

function OnlineFightView:onRuleClick()
	local rulePanel = self.leftBtn:get("rule")
	if not rulePanel:get("ruleItem") then
		ccui.Layout:create():hide():addTo(rulePanel, 1, "ruleItem")
	end
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
end

function OnlineFightView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(144),
		c.noteText(98001, 98010),
		c.noteText(145),
		c.noteText(99001, 99010),
		c.noteText(146),
		c.noteText(100001, 100010),
	}
	if self.round:read() ~= "closed" then
		local servers = gGameModel.cross_online_fight:read("servers")
		if servers then
			local t = getServersShow(servers)
			table.insert(context, 2, "#C0x5B545B#" .. gLanguageCsv.currentServers .. table.concat(t, ","))
		end
		local limitedScore = gGameModel.cross_online_fight:read("limited_top_score") -- # 公平赛积分
		local unlimitedScore = gGameModel.cross_online_fight:read("unlimited_top_score") -- # 无限制积分
		local ruleItem = self.leftBtn:get("rule.ruleItem")
		local width = view.list:width()
		table.insert(context, 2, c.clone(ruleItem, function(item)
			local highestItem, height = beauty.textScroll({
				size = cc.size(width, 0),
				strs = string.format(gLanguageCsv.onlineFightRuleTitle, limitedScore, unlimitedScore),
				isRich = true,
				align = "center",
			})
			highestItem:height(height)
			item:size(width, height):add(highestItem)
		end))
	end
	return context
end

function OnlineFightView:onShopClick()
	if not gGameUI:goBackInStackUI("city.shop") then
		gGameUI:stackUI("city.shop", nil, {full = true}, game.SHOP_INIT.ONLINE_FIGHT_SHOP)
	end
end

function OnlineFightView:onRecordClick()
	local index = self.switchModel:read() == "limited" and 1 or 2
	if self.round:read() == "closed" then
		index = self.switchDisplayRank:read() == "limited" and 1 or 2
	end
	gGameUI:stackUI("city.pvp.online_fight.record", nil, nil, index)
end

function OnlineFightView:onEmbattleClick(show)
	if self.round:read() == "closed" then
		gGameUI:showTip(gLanguageCsv.notStartFighting)
		return
	end
	if self.switchModel:read() == "limited" then
		gGameUI:stackUI("city.pvp.online_fight.limited_embattle")
	else
		gGameUI:stackUI("city.card.embattle.online_fight", nil, {full = true}, {from = "onlineFight", tip = show == true})
	end
end

function OnlineFightView:onRankClick()
	local index = self.switchModel:read() == "limited" and 2 or 1
	if self.round:read() == "closed" then
		index = self.switchDisplayRank:read() == "limited" and 2 or 1
	end
	gGameApp:requestServer("/game/cross/online/rank",function (tb)
		gGameUI:stackUI("city.pvp.online_fight.rank", nil, nil, index, tb.view.rank)
	end, index, 0, 10)
end

function OnlineFightView:onRankRewardClick()
	gGameUI:stackUI("city.pvp.online_fight.reward", nil, {clickClose = true})
end

function OnlineFightView:onTargetAwardClick()
	-- 可领取
	if self.weeklyTargetState.flag == 0 then
		gGameUI:showTip(gLanguageCsv.onlineFightAwardAll)

	elseif self.weeklyTargetState.flag == 1 then
		gGameApp:requestServer("/game/cross/online/weekly/target", function(tb)
			gGameUI:showGainDisplay(tb)
		end, self.weeklyTargetState.csvId)
	else
		gGameUI:showBoxDetail({
			data = self.weeklyTargetState.cfg.award,
			content = string.format(gLanguageCsv.onlineFightWeeklyTargetTip, gLanguageCsv["onlineFightWeeklyTarget" .. self.weeklyTargetState.cfg.type], self.weeklyTargetState.cfg.count),
			state = self.weeklyTargetState.flag,
		})
	end
end

function OnlineFightView:onSwitchModelClick()
	self.switchModel:modify(function(val)
		local newval = val == "limited" and "unlimited" or "limited"
		userDefault.setForeverLocalKey("onlineFightSwitchModel", newval)
		return true, newval
	end)
end

function OnlineFightView:onModelTipClick()
	self.banTipPanel:show()
end


function OnlineFightView:onModelUnlimitedTipClick()
	self.banUnlimitedTipPanel:show()
end


function OnlineFightView:onBanTipPanelClick()
	self.banTipPanel:hide()
end

function OnlineFightView:onBanUnlimitedTipPanelClick()
	self.banUnlimitedTipPanel:hide()
end

function OnlineFightView:onLimitedRankClick()
	self.switchDisplayRank:set("limited")
end

function OnlineFightView:onUnlimitedRankClick()
	self.switchDisplayRank:set("unlimited")
end

function OnlineFightView:onLongtimeModelClick()
	if self.matchState:read() == STATE_TYPE.normal then
		local longtimeout = userDefault.getForeverLocalKey("onlineFightLongtimeout", false)
		longtimeout = not longtimeout
		userDefault.setForeverLocalKey("onlineFightLongtimeout", longtimeout)
		self.longtimeoutModel:set(longtimeout)
		if longtimeout then
			gGameUI:showTip(gLanguageCsv.onlineFightLongtimeTip)
		end
	end
end

function OnlineFightView:onStartBtnClick()
	-- 4.在匹配未开启时间内点击按钮，飘字：匹配未开放（每周XXXX，XX~XX开启）
	if self.round:read() ~= "start" then
		gGameUI:showTip(gLanguageCsv.onlineFightNotOpen)
		return
	end
	-- 5.无限制模式下点击匹配，需检测当前阵容是否全空，
	--   公平赛模式下点击匹配，需检测是否配置了20张备选精灵
	--   若阵容全空&备选精灵未设定成功时时，飘字提示：请准备好备选阵容再开始匹配！
	if self.switchModel:read() == "limited" then
		local baseCfg = csv.cross.online_fight.base[1]
		local cards = gGameModel.role:read("cross_online_fight_limited_cards")
		if itertools.size(cards) < baseCfg.leastCardNum then
			gGameUI:showTip(gLanguageCsv.onlineFightEmbattleNotReady)
			return
		end
		-- 记录配置可用的卡牌
		local allCardsHash = {}
		for _, v in orderCsvPairs(csv.cross.online_fight.cards) do
			allCardsHash[v.cardId] = true
		end
		local limitedCards = gGameModel.role:read("cross_online_fight_limited_cards")
		for _, cardId in ipairs(limitedCards) do
			if not allCardsHash[cardId] then
				gGameUI:showTip(gLanguageCsv.onlineFightEmbattleNotReady)
				return
			end
		end
	else
		local cards = gGameModel.cross_online_fight:read("cards")
		if itertools.size(cards) == 0 then
			gGameUI:showTip(gLanguageCsv.onlineFightEmbattleNotReady)
			return
		end
		self:refreshUnlimitedCards()
		if self.banCardInBattle then
			self:onEmbattleClick(true)
			return
		end
	end
	if self.matchState:read() == STATE_TYPE.normal then
		local versionPlist = cc.FileUtils:getInstance():getValueMapFromFile('res/version.plist')
		local pattern = self.switchModel:read() == "limited" and 2 or 1
		local longtimeout = userDefault.getForeverLocalKey("onlineFightLongtimeout", false)
		gGameApp:requestServer("/game/cross/online/matching", nil, pattern, tonumber(versionPlist.patch), longtimeout)

	elseif self.matchState:read() == STATE_TYPE.matching then
		gGameApp:requestServer("/game/cross/online/cancel")
	end
end

function OnlineFightView:getRightIconEffectName()
	if self.round:read() == "closed" then
		return ""
	end
	local switchModel = self.switchModel:read()
	local limitedScore = self.limitedScore:read()
	local matchState = self.matchState:read()
	local baseCfg = csv.cross.online_fight.base[1]
	if matchState == STATE_TYPE.normal then
		if limitedScore >= baseCfg.limitedBanScore then
			return switchModel == "limited" and "fanpai_1_effect" or "fanpai_2_effect"
		end
		return switchModel == "limited" and "fanpai_3_effect" or "fanpai_4_effect"
	end
	if switchModel == "limited" then
		if limitedScore >= baseCfg.limitedBanScore then
			return "gongpingsai1_loop"
		end
		return "gongpingsai2_loop"
	end
	return "wuxianzhisai_loop"
end

-- 赛季结算展示
function OnlineFightView:resetDisplayTop()
	local data
	if self.switchDisplayRank:read() == "limited" then
		data = gGameModel.cross_online_fight:read("limited_history_top")
	else
		data = gGameModel.cross_online_fight:read("unlimited_history_top")
	end
	data = data or {}
	local board = self.displayPanel:get("board")
	board:removeAllChildren()
	local pos = {cc.p(0, 0), cc.p(-640, 0), cc.p(640, 0)}
	for i = 1, 3 do
		if data[i] then
			local item = self.displayPanel:get("item1"):clone()
				:addTo(board)
				:xy(pos[i])
				:z(2)
			local childs = item:get("down"):multiget("bg", "rank", "name", "point", "server")
			childs.bg:texture("city/pvp/online_fight/display/img_dzjjc_" .. i .. ".png")
			childs.rank:texture("city/pvp/online_fight/display/icon_dzjjc_" .. i .. ".png")
			childs.name:text(data[i].name)
			childs.point:text(gLanguageCsv.score .. ": " .. data[i].score)
			childs.server:text(string.format(gLanguageCsv.brackets, getServerArea(data[i].game_key)))
			text.addEffect(childs.name, {outline = {color = cc.c4b(83, 54, 6, 255)}})
			text.addEffect(childs.point, {outline = {color = cc.c4b(83, 54, 6, 255)}})
			text.addEffect(childs.server, {outline = {color = cc.c4b(83, 54, 6, 255)}})

			local size = item:size()
			local figureCfg = gRoleFigureCsv[data[i].figure]
			if figureCfg.resSpine ~= "" then
				widget.addAnimationByKey(item, figureCfg.resSpine, "figure", "standby_loop1", 0)
					:xy(size.width / 2, 50)
					:scale(i == 1 and 1.4 or 1.3)
			end
			local title = data[i].title
			if title > 0 then
				bind.extend(self, item, {
					event = "extend",
					class = "role_title",
					props = {
						data = title,
						onNode = function(node)
							node:xy(size.width / 2, size.height - (i == 1 and 100 or 160))
								:scale(1.3)
								:z(5)
						end
					}
				})
			end
		end
	end
	for i = 4, 7 do
		if data[i] then
			local item = self.displayPanel:get("item2"):clone()
				:addTo(board)
				:xy(640 * (i - 5.5), 400)
				:z(1)
			local childs = item:get("down"):multiget("bg", "rank", "name", "point", "server")
			childs.rank:texture("city/pvp/online_fight/display/icon_dzjjc_" .. i .. ".png")
			childs.name:text(data[i].name)
			childs.point:text(gLanguageCsv.score .. ": " .. data[i].score)
			childs.server:text(string.format(gLanguageCsv.brackets, getServerArea(data[i].game_key)))
			text.addEffect(childs.name, {outline = {color = cc.c4b(83, 54, 6, 255)}})
			text.addEffect(childs.point, {outline = {color = cc.c4b(83, 54, 6, 255)}})
			text.addEffect(childs.server, {outline = {color = cc.c4b(83, 54, 6, 255)}})

			local size = item:size()
			local figureCfg = gRoleFigureCsv[data[i].figure]
			if figureCfg.resSpine ~= "" then
				widget.addAnimationByKey(item, figureCfg.resSpine, "figure", "standby_loop1", 0)
					:xy(size.width / 2, 50)
					:scale(1)
			end
		end
	end
end
-- 本周禁用
function OnlineFightView:refreshUnlimitedCards()
	if self.round:read() == "closed" then
		return
	end
	local day = math.floor((time.getTime() - time.getNumTimestamp(self.startDate:read(), 5, 0, 0)) / 60 / 60 / 24) + 1
	local cfg = {}
	local unlimitedBanCards = {}
	for k, v in csvPairs(csv.cross.online_fight.theme_open) do
		if v.day == day then
			cfg = v
			break
		end
	end
	--无禁用精灵
	if itertools.size(cfg.invalidMarkIDs or {}) == 0 and itertools.size(cfg.invalidMegaCardIDs or {}) == 0 then
		self.hasBanCard = false
		self.unlimitedBanCards:update(unlimitedBanCards)
		return
	end
	-- 非mega
	for kk, vv in ipairs(cfg.invalidMarkIDs) do
		local max = 1
		local unitID
		local rarity
		for _, val in orderCsvPairs(csv.cards) do
			if val.cardMarkID == vv and val.megaIndex == 0 then
				unitID = val.develop >= max and val.unitID or unitID
				max =  val.develop >= max and val.develop or max
			end
		end
		unlimitedBanCards[kk] = {
			unitID = unitID,
		}
	end
	-- mega
	for _, id in ipairs(cfg.invalidMegaCardIDs) do
		for key, val in orderCsvPairs(csv.cards) do
			if key == id then
				unlimitedBanCards[#unlimitedBanCards + 1] = {
					unitID = val.unitID,
				}
			end
		end
	end
	self.unlimitedBanCards:update(unlimitedBanCards)
	-- 判断无限制赛阵容中是否有ban精灵
	self.banCardInBattle = false
	local cards = gGameModel.cross_online_fight:read("cards")
	for _, v in ipairs(cards) do
		local card = gGameModel.cards:find(v)
		local cardID = card:read("card_id")
		-- 非mega
		for _, v in ipairs(cfg.invalidMarkIDs) do
			if csv.cards[cardID].cardMarkID == v then
				self.banCardInBattle = true
				return
			end
		end
		-- mega
		for _, id in ipairs(cfg.invalidMegaCardIDs) do
			if cardID == id then
				self.banCardInBattle = true
				return
			end
		end
	end
end

-- 小精灵动画交互表现
function OnlineFightView:resetRankPointSprite(justAdd)
	local panel = self.mainPanel:get("rankPointPanel.sprite")
	panel:removeAllChildren()
	local effect = widget.addAnimation(panel, "battlearena/pp_ccz.skel", "standby_loop", 100)
	effect:xy(panel:width()/2, 0):scale(2)
	if justAdd then
		return
	end
	local isSleep = false
	local clickTimes = 0
	local function toSleep()
		isSleep = false
		panel:stopAllActions()
		performWithDelay(panel, function()
			effect:play("shuijiao_effect")
			effect:addPlay("shuijiao_loop")
			isSleep = true
		end, 10)
	end
	toSleep()
	panel:onClick(function(event)
		clickTimes = clickTimes + 1
		local pos = panel:convertToNodeSpace(event)
		if isSleep then
			effect:play("shuijiao2_effect")

		elseif clickTimes >= 10 then
			clickTimes = 0
			effect:play("standby_wanqiu")
		else
			if pos.y > 200 then
				effect:play("standby_effect")
			else
				effect:play("standby_body_effect")
			end
		end
		effect:addPlay("standby_loop")
		toSleep()
	end)
end

function OnlineFightView:showEnemy()
	if self.matchState:read() == STATE_TYPE.enemy then
		return
	end
	self.matchState:set(STATE_TYPE.enemy)
	local childs = self.enemyPanel:multiget("head", "name", "server", "point", "bg", "icon", "title", "pointTxt")
	itertools.invoke(childs, "hide")
	dataEasy.onlineFightLoginServer(self, function()
		gGameModel.cross_online_fight:getRawIdler_("match_result"):set(nil)
	end, function(cb)
		itertools.invoke(childs, "show")
		local matchResult = self.matchResult:read()
		local enemy = matchResult.enemy
		bind.extend(self, childs.head, {
			class = "role_logo",
			props = {
				logoId = enemy.logo,
				frameId = enemy.frame,
				-- level = enemy.level,
				level = false,
				vip = false,
			}
		})
		childs.name:text(enemy.name)
		childs.server:text(string.format(gLanguageCsv.brackets, getServerArea(enemy.game_key, true)))
		childs.point:text(enemy.score or 0)
		adapt.oneLinePos(childs.pointTxt, childs.point, cc.p(5, 0))
		performWithDelay(self, function()
			gGameModel.cross_online_fight:getRawIdler_("match_result"):set(nil)
			cb()
		end, 3)
	end)
end

return OnlineFightView