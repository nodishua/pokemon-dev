-- @date:   2019-02-26
-- @desc:   竞技场主界面

local STATETEXT = {
	gLanguageCsv.changeEnemy,
	gLanguageCsv.pvpResetTime,
	gLanguageCsv.pvpBuyTime,
}

local STATE = {
	NORMAL = 1,-- 正常
	COLDDOWN = 2, --冷却
	BUY = 3,  --购买
}

local function onInitItem(list, node, k, v)
	local panel = node:get("panel")
	panel:get("textName"):text(v.name)
	panel:get("textLv"):text(v.level)
	panel:get("textFightPoint"):text(v.fighting_point)
	panel:get("textRank2"):text(v.rank)
	panel:get("textRank2"):x(232 + 50)
	adapt.oneLinePos(panel:get("textRank2"), panel:get("textRankNote"), nil, "right")

	local w1 = panel:get("textLv"):size().width
	local w2 = panel:get("textLvNote"):size().width
	local centerPos = panel:get("textLvNote"):x() - w2 + (w1 + w2) / 2
	panel:get("textFightNode"):x(centerPos)


	local isShowLogo = v.rank <= 3
	if isShowLogo then
		panel:get("imgRank"):texture(ui.RANK_ICON[v.rank])
	else
		panel:get("textRank"):text(v.rank)
		panel:get("imgRank"):texture("common/icon/icon_four.png")
	end
	panel:get("imgRank"):visible(v.isTop)
	panel:get("textRank"):visible(v.isTop and not isShowLogo)

	local isSelf = v.role_db_id == list.record:read().role_db_id
	local isLowerRanking = v.rank > list.record:read().rank
	panel:get("btnChallenge"):hide()
	panel:get("passPanel.btnChallenge"):hide()
	panel:get("passPanel.btnPass"):hide()
	panel:get("textCostNum"):hide()
	panel:get("imgIcon"):hide()

	local function setPosY(node, diffY)
		node:y(node:y() + diffY)
	end
	local passMoveNode = {"textFightNode", "textLvNote", "textLv", "textFightPoint", "textName", "textRank2", "textRankNote"}
	local y = panel:get("textFightNode"):y()
	if math.abs(y - 170) > 1e-6 then
		for _, name in ipairs(passMoveNode) do
			setPosY(panel:get(name), 170 - y)
		end
	end
	local cost = v.cost
	if isSelf then
		list.myItemIdx:set(k)
		panel:get("textSelf"):show()

	elseif isLowerRanking and dataEasy.isUnlock(gUnlockCsv.pvpPass) then
		panel:get("passPanel.btnChallenge"):show()
		panel:get("passPanel.btnPass"):show()
		text.addEffect(panel:get("passPanel.btnChallenge.textNote"), {glow = {color = ui.COLORS.GLOW.WHITE}})
		text.addEffect(panel:get("passPanel.btnPass.textNote"), {glow = {color = ui.COLORS.GLOW.WHITE}})
		local needBuyDiamonds = needBuyCount
		panel:get("textCostNum"):text(cost):show()
		panel:get("imgIcon"):show()
		adapt.oneLineCenterPos(cc.p(325, 145), {panel:get("imgIcon"), panel:get("textCostNum")})
		for _, name in ipairs(passMoveNode) do
			setPosY(panel:get(name), 27)
		end
	else
		panel:get("btnChallenge"):show()
		text.addEffect(panel:get("btnChallenge.textNote"), {glow = {color = ui.COLORS.GLOW.WHITE}})
	end

	panel:removeChildByName("spineNode")

	local unitId = dataEasy.getUnitIdForJJC( v.display)
	local unit = csv.unit[unitId]

	local size = panel:size()
	local cardSprite = widget.addAnimationByKey(panel, unit.unitRes, "spineNode", "standby_loop", 3)
		:xy(size.width / 2, size.height / 2 - 40)
		:scale(unit.scale * 0.85)
	cardSprite:setSkin(unit.skin)
end

local MonthCardView = require "app.views.city.activity.month_card"
local ArenaView = class("ArenaView", cc.load("mvc").ViewBase)



ArenaView.RESOURCE_FILENAME = "arena.json"
ArenaView.RESOURCE_BINDING = {
	["top.imgBg"] = "imgBg",
	["top.imgLeftBG"] = "imgLeftBG",
	["top.imgRightBG"] = "imgRightBG",
	["top.leftUp.textFightPoint"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("fightPoint"),
		},
	},
	["top.leftUp.head.imgTouxiang"] = {
		binds = {
			event = "texture",
			idler = bindHelper.self("logoId"),
			method = function(logoId)

				local unitId = dataEasy.getUnitIdForJJC(logoId)
				local unit = csv.unit[unitId]

				return unit.cardIcon
			end
		},
	},
	["top.leftUp.head"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowHeadIcon")}
		},
	},
	["top.leftUp.textRank"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("myRank"),
		},
	},
	["top.rightUp.btnRankReward"] = {
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onShowRankReward")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					state = bindHelper.self("hasRankReward"),
				}
			},
		},
	},
	["top.rightUp.btnRankReward.textNote"] = {
		varname = "txtBtnRankReward",
		binds = {
			event = "effect",
			data = {shadow = {color = cc.c4b(255,237,174,255), offset = cc.size(0,-4), size = 4}}
		},
	},
	["top.rightUp.btnScoreReward"] = {
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onShowPointReward")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					state = bindHelper.self("hasScoreReward"),
				},
			},
		},
	},
	["top.rightUp.btnScoreReward.textNote"] = {
		varname = "txtBtnScoreReward",
		binds = {
			event = "effect",
			data = {shadow = {color = cc.c4b(255,237,174,255), offset = cc.size(0,-4), size = 4}}
		},
	},
	["top.rightUp.btnHonourReward"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowShop")}
		},
	},
	["top.rightUp.btnHonourReward.textNote"] = {
		varname = "txtBtnHonourReward",
		binds = {
			event = "effect",
			data = {shadow = {color = cc.c4b(255,237,174,255), offset = cc.size(0,-4), size = 4}}
		},
	},
	["top.rightUp.btnFightReport"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowFightReport")}
		},
	},
	["top.rightUp.btnFightReport.textNote"] = {
		varname = "txtBtnFightReport",
		binds = {
			event = "effect",
			data = {shadow = {color = cc.c4b(255,237,174,255), offset = cc.size(0,-4), size = 4}}
		},
	},
	["top.rightUp.btnRank"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowRank")}
		},
	},
	["top.rightUp.btnRank.textNote"] = {
		varname = "txtBtnRank",
		binds = {
			event = "effect",
			data = {shadow = {color = cc.c4b(255,237,174,255), offset = cc.size(0,-4), size = 4}}
		},
	},
	["top.rightUp.btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowRule")}
		},
	},
	["top.rightUp.btnRule.textNote"] = {
		varname = "txtBtnRule",
		binds = {
			event = "effect",
			data = {shadow = {color = cc.c4b(255,237,174,255), offset = cc.size(0,-4), size = 4}}
		},
	},
	["rightDown.ticket"] = "ticketPanel",
	["rightDown.leftTime"] = "leftTimePanel",
	-- ["rightDown.leftTime.textNoteNum"] = {
	-- 	binds = {
	-- 		event = "effect",
	-- 		data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
	-- 	},
	-- },
	["rightDown.leftTime.textNum"] = {
		binds = {
			-- {
			-- 	event = "effect",
			-- 	data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
			-- },
			{
				event = "text",
				idler = bindHelper.self("leftTime"),
			},
		},
	},
	["rightDown.schedule"] = "schedulePanel",
	-- ["rightDown.schedule.textNote"] = {
		-- binds = {
		-- 	event = "effect",
		-- 	data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		-- },
	-- },
	["rightDown.schedule.textTime"] = {
		binds = {
			-- {
			-- 	event = "effect",
			-- 	data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
			-- },
			{
				event = "text",
				idler = bindHelper.self("timeSchedule"),
				method = function(val)
					local min = math.floor(val / 60)
					local sec = val % 60

					return string.format("%02d:%02d", min, sec)
				end
			}
		},
	},
	["rightDown.costInfo"] = "costInfo",
	["rightDown.costInfo.imgIcon"] = "imgCostIcon",
	["rightDown.costInfo.textCostNum"] = "textCost",
	["rightDown.textNote"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("btnText"),
		},
	},
	["leftDown.btnReset"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onResetRole")}
		},
	},
	["rightDown.btnThree"] = {
		varname = "doubleBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBuyOrResetTime")}
		},
	},
	["item"] = "item",
	["item.panel.textLv"] = "textLvItem",
	["item.panel.textName"] = "textNameItem",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("myEnemys"),
				item = bindHelper.self("item"),
				-- 进入要定位到最后 异步加载会闪一下
				asyncPreload = 6,
				record = bindHelper.self("record"),
				myItemIdx = bindHelper.self("myItemIdx"),
				itemAction = {isAction = true},
				dataOrderCmp = function(a, b)
					if a.isTop == b.isTop then
						return a.rank < b.rank
					end
					if a.isTop then
						return true
					end

					if b.isTop then
						return false
					end
				end,
				onItem = function(list, node, k, v)
					node:name("item" .. list:getIdx(k))
					onInitItem(list, node, k, v)
					local panel = node:get("panel")
					bind.touch(list, panel, {methods = {
						ended = functools.partial(list.clickCell, v, panel)
					}})
					bind.touch(list, panel:get("btnChallenge"), {methods = {
						ended = functools.partial(list.clickBtn, v)
					}})

					bind.touch(list, panel:get("passPanel.btnChallenge"), {methods = {
						ended = functools.partial(list.clickBtn, v)
					}})
					bind.touch(list, panel:get("passPanel.btnPass"), {methods = {
						ended = functools.partial(list.clickPassBtn, v)
					}})

				end,
				preloadCenter = bindHelper.self("lastIdx"),
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
				clickBtn = bindHelper.self("onItemBtnClick"),
				clickPassBtn = bindHelper.self("onPassClick")
			},
		},
	},
	["ruleRankItem"] = "ruleRankItem",
	["marqueePanel"] = {
		varname = "marqueePanel",
		binds = {
			event = "extend",
			class = "marquee",
		}
	}
}

function ArenaView:onCreate()
	adapt.centerWithScreen("left", "right", nil, {
		{self.list, "width"},
		{self.list, "pos", "left"},
		{self.imgBg, "width"},
		{self.imgLeftBG, "pos", "left"},
		{self.imgRightBG, "pos", "right"},
	})
	self:initModel()
	local txtBtn = {self.txtBtnRankReward, self.txtBtnScoreReward, self.txtBtnHonourReward, self.txtBtnFightReport, self.txtBtnRank, self.txtBtnRule}
	for i=1,#txtBtn do
		txtBtn[i]:setTextVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_BOTTOM)
		txtBtn[i]:getVirtualRenderer():setLineSpacing(-15)
		txtBtn[i]:y(txtBtn[i]:y() + 25)
	end

	adapt.oneLinePos(self.textLvItem, self.textNameItem, cc.p(70, 0))
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.arena, subTitle = "Arena"})

	self.myItemIdx = idler.new(-1)
	self.lastIdx = idler.new(1)
	self.fightPoint = idler.new()
	self.myRank = idler.new()
	self.logoId = idler.new()
	self.hasRankReward = idler.new(false)
	self.hasScoreReward = idler.new(false)
	idlereasy.when(self.record, function(_, record)
		self.myRank:set(record.rank)
		self.logoId:set(record.display)
		local fightPoint = 0
		for _,v in pairs(record.defence_card_attrs) do
			fightPoint = fightPoint + v.fighting_point
		end
		self.fightPoint:set(fightPoint)
	end)

	idlereasy.any({self.resultPointAward, self.rankAward}, function(_, resultPointAward, rankAward)
		local scoreRedPoint = false
		for i,v in pairs(resultPointAward) do
			if v == 1 then
				scoreRedPoint = true
				break
			end
		end
		self.hasScoreReward:set(scoreRedPoint)
		local rankRedPoint = false
		for i,v in pairs(rankAward) do
			if v == 1 then
				local costId, costNum = csvNext(csv.pwrank_award[i].cost)
				if not costId or dataEasy.getNumByKey(costId) >= costNum then
					rankRedPoint = true
					break
				end
			end
		end
		self.hasRankReward:set(rankRedPoint)
	end)

	self.selectCardId = self.record:read().display
	self.btnText = idler.new("")
	self.state = idler.new(0)
	self.leftTime = idler.new()
	self.costNum = idler.new(0)
	self.timeSchedule = idler.new(0)

	local idlerTab = {self.pvpPwTimes, self.buyPwTimes, self.pvpPwLastTime, self.buyPwCdTimes, self.itemPwTimes, self.refreshEnemyTimes, self.items}
	idlereasy.any(idlerTab, function(_, pvpPwTimes, buyPwTimes, pvpPwLastTime, buyPwCdTimes, itemPwTimes, refreshEnemyTimes, items)
		-- 总次数是固定的 和策划确认过
		local baseCount = self.freePWTimes
		local canChallengeCount = math.max(0, buyPwTimes + baseCount + itemPwTimes - pvpPwTimes)
		self.leftTime:set(string.format("%s/%s", canChallengeCount, baseCount))
		--挑战劵的数量
		local ticketNum = items[game.ITEM_TICKET.pvpTicket] or 0
		self.ticketPanel:get("textNum"):text("1/"..ticketNum)
		--显示挑战劵
		local showTicket = (canChallengeCount == 0) and (ticketNum > 0)
		self.ticketPanel:visible(showTicket)
		self.leftTimePanel:visible(not showTicket)
		if canChallengeCount == 0 and ticketNum == 0 then
			local seq = gCostCsv.pvppw_buy_cost
			local idx = math.min(buyPwTimes + 1, table.length(seq))
			self.costNum:set(seq[idx])
			self:setCost(seq[idx])
			adapt.oneLinePos(self.textCost, self.imgCostIcon, cc.p(6, 0))
			self.state:set(STATE.BUY)
		else
			local noCD = MonthCardView.getPrivilegeAddition("pwNoCD")
			-- 挑战次数小于基数 （不是购买的次数）
			if not noCD and (pvpPwTimes < baseCount) then
				local delta = time.getTime() - pvpPwLastTime
				local resetTime = tonumber(self.pvpResetTime)
				-- 还没过冷却时间
				if delta < resetTime then
					local seq = gCostCsv.pvppw_cd_buy_cost
					local idx = math.min(buyPwCdTimes + 1, table.length(seq))
					self.costNum:set(seq[idx])
					self:setCost(seq[idx])
					adapt.oneLinePos(self.textCost, self.imgCostIcon, cc.p(6, 0))
					self.timeSchedule:set(resetTime - delta)
					self.state:set(STATE.COLDDOWN, true)
					return
				end
			end
			local seq = gCostCsv.pvp_enermys_fresh_cost
			local idx = math.min(refreshEnemyTimes + 1, table.length(seq))
			self.costNum:set(seq[idx])
			self:setCost(seq[idx])
			adapt.oneLinePos(self.textCost, self.imgCostIcon, cc.p(6, 0))
			self.state:set(STATE.NORMAL, true)
		end
	end)

	-- UI修改
	-- 1：正常 2：冷却 3：购买
	idlereasy.any({self.state, self.costNum}, function(_, state, curCost)
		self.costInfo:visible(not (state == STATE.NORMAL and curCost == 0))
		self.schedulePanel:visible(state == STATE.COLDDOWN)
		self.btnText:set(STATETEXT[state])
		if state == STATE.NORMAL then
			local x = 1000
			if curCost > 0 then
				x = 700
			end
			self.ticketPanel:x(x)
			self.leftTimePanel:x(x)
		elseif state == STATE.BUY then
			self.ticketPanel:x(700)
			self.leftTimePanel:x(700)
		elseif state == STATE.COLDDOWN then
			self.ticketPanel:x(246)
			self.leftTimePanel:x(246)
		end
	end)

	self:enableSchedule():schedule(function (dt)
		if self.state:read() == STATE.COLDDOWN then
			local ret = true
			self.timeSchedule:modify(function(oldval)
				local curval = oldval - 1
				if curval <= 0 then
					local seq = gCostCsv.pvp_enermys_fresh_cost
					local idx = math.min(self.refreshEnemyTimes:read() + 1, table.length(seq))
					self.costNum:set(seq[idx])
					self:setCost(seq[idx])
					adapt.oneLinePos(self.textCost, self.imgCostIcon, cc.p(6, 0))
					self.state:set(STATE.NORMAL)
					ret = false
				end
				return true, curval
			end)
			return ret
		end
	end, 1, 0, "pvpSchedule")

	self.myEnemys = idlers.newWithMap({})
	self.refreshPass = idler.new(false)
	idlereasy.any({self.top10, self.enemys, self.refreshPass}, function(_, top, enemys)
		self.lastIdx:set(#top + #enemys)
		local myEnemys = self:resetEnemys(top, enemys)
		self.myEnemys:update(myEnemys)
	end)
end

function ArenaView:initModel()
	self.rankAward = gGameModel.role:getIdler("pw_rank_award")
	self.cards = gGameModel.role:getIdler("cards")
	self.items = gGameModel.role:getIdler("items")
	local vipLv = gGameModel.role:read("vip_level")
	local arena = gGameModel.arena
	self.top10 = arena:getIdler("top10")
	self.enemys = arena:getIdler("enemys")
	self.record = arena:getIdler("record")
	local dailyRecord = gGameModel.daily_record
	self.resultPointAward = dailyRecord:getIdler("result_point_award")
	self.refreshEnemyTimes = dailyRecord:getIdler("pvp_enermys_refresh_times") -- 刷新对手次数
	self.buyPwTimes = dailyRecord:getIdler("buy_pw_times") -- 这个是购买的次数
	self.pvpPwTimes = dailyRecord:getIdler("pvp_pw_times") -- 今天挑战的次数
	self.pvpPwLastTime = dailyRecord:getIdler("pvp_pw_last_time") -- 这个是上一次战斗的时间
	self.buyPwCdTimes = dailyRecord:getIdler("buy_pw_cd_times") -- 冷却重置的次数
	self.itemPwTimes = dailyRecord:getIdler("item_pw_times") -- 道具使用次数
	local csvTab = gVipCsv[vipLv]
	self.freePWTimes = csvTab.freePWTimes -- vip免費次數(基础次数)
	self.pvpResetTime = csvTab.PWcoldTime
end

function ArenaView:resetEnemys(top, enemys)
	local cost = self:getPassCost()
	local myEnemys = {}
	for i,v in ipairs(top) do
		local d = clone(v)
		d.isTop = true
		d.cost = cost
		table.insert(myEnemys, d)
	end

	for i,v in ipairs(enemys) do
		local d = clone(v)
		d.isTop = false
		d.cost = cost
		table.insert(myEnemys, d)
	end

	return myEnemys
end

function ArenaView:onShowHeadIcon(node, event)
	gGameUI:stackUI("city.pvp.arena.head_icon", nil, nil, self:createHandler("onChangeLogoID"), self:createHandler("onChangeSpine"),self.selectCardId)
end

-- 1：正常 2：冷却 3：购买
function ArenaView:onItemBtnClick(list, data)
	if data.isTop and self.myRank:read() > 20 then
		gGameUI:showTip(gLanguageCsv.rankNotEnough)
		return
	end
	local function inEmbattle()
		gGameUI:stackUI("city.card.embattle.arena", nil, {full = true}, {from = "arena", team = true, fightCb = self:createHandler("startFighting", data)})
	end
	local state = self.state:read()
	if state ~= STATE.NORMAL then
		if state == STATE.COLDDOWN then
			gGameUI:showTip(gLanguageCsv.timeNotUp)
		else -- state == STATE.BUY
			self:onBuyOrResetTime(inEmbattle)
		end
		return
	end
	inEmbattle()
end
--battleCards 当前阵容
function ArenaView:startFighting(vData, view, battleCards)
	local myRank = self.record:read().rank
	local battleRank = vData.rank
	-- 防止schedule中有网络请求行为
	self:disableSchedule()
	battleEntrance.battleRequest("/game/pw/battle/start", myRank, battleRank, vData.role_db_id, vData.record_id)
		:onStartOK(function(data)
			-- 后续新增 类似preData等游戏内战斗数据 通过getData,getPreDataForEnd处理 不好处理的在start协议里直接发给服务器处理
			data.preData.rightRank = battleRank
			if view then
				view:onClose(false)
				view = nil
			end
		end)
		:run()
		:show()
end

function ArenaView:onItemClick(list, data, node)
	local isSelf = data.role_db_id == self.record:read().role_db_id
	if isSelf then
		return
	end
	gGameApp:requestServer("/game/pw/role/info", function(tb)
		gGameUI:stackUI("city.pvp.arena.personal_info", nil, nil, tb.view)
	end, data.record_id)
end

function ArenaView:getPassCost()
	local freePWTimes = self.freePWTimes
	local buyPwTimes = self.buyPwTimes:read()
	local itemPwTimes = self.itemPwTimes:read()
	local pvpPwTimes = self.pvpPwTimes:read()
	local canChallengeCount = math.max(0, freePWTimes + buyPwTimes + itemPwTimes - pvpPwTimes)
	--挑战劵的数量
	local ticketNum = self.items:read()[game.ITEM_TICKET.pvpTicket] or 0
	local needBuyCount = math.max(0, 5 - canChallengeCount - ticketNum)
	local cost = gCommonConfigCsv.pvpPassCostRmb
	local seq = gCostCsv.pvppw_buy_cost
	for i = 1, needBuyCount do
		cost = cost + seq[math.min(buyPwTimes + i, table.length(seq))]
	end
	return cost
end

-- 碾压5次
function ArenaView:onPassClick(list, data)
	local freePWTimes = self.freePWTimes
	local buyPwTimes = self.buyPwTimes:read()
	local itemPwTimes = self.itemPwTimes:read()
	local pvpPwTimes = self.pvpPwTimes:read()
	local canChallengeCount = math.max(0, freePWTimes + buyPwTimes + itemPwTimes - pvpPwTimes)
	--挑战劵的数量
	local ticketNum = self.items:read()[game.ITEM_TICKET.pvpTicket] or 0
	local needBuyCount = math.max(0, 5 - canChallengeCount - ticketNum)

	local cost = self:getPassCost()
	local function showPassView()
		if gGameModel.role:read("rmb") < cost then
			uiEasy.showDialog("rmb")
		else
			gGameApp:requestServer("/game/pw/battle/pass", function (tb)
				gGameUI:stackUI("city.pvp.arena.pass_reward", nil, nil, data, tb.view)
				self.refreshPass:notify()
			end, data.rank)
		end
	end
	-- 无消耗钻石直接碾压
	--if needBuyCount == 0 then
	--	showPassView()
	--	return
	--end
	local vipLv = gGameModel.role:read("vip_level")
	if buyPwTimes + needBuyCount >= gVipCsv[vipLv].buyPWTimes then
		gGameUI:showTip(gLanguageCsv.arenaPassLimit)
		return
	end
	gGameUI:showDialog({
		cb = showPassView,
		btnType = 2,
		isRich = true,
		content = string.format(gLanguageCsv.arenaPassTip, cost),
		clearFast = true,
		dialogParams = {clickClose = false},
	})
end

function ArenaView:onShowRankReward()
	gGameUI:stackUI("city.pvp.arena.rank_reward")
end

function ArenaView:onShowPointReward()
	gGameUI:stackUI("city.pvp.arena.point_reward")
end

function ArenaView:onShowFightReport()
	gGameUI:stackUI("city.pvp.arena.combat_record")
end

function ArenaView:onShowRank()
	gGameApp:requestServer("/game/pw/rank", function(tb)
		gGameUI:stackUI("city.pvp.arena.rank", nil, nil, tb.view)
	end, 0, 50)
end

function ArenaView:onShowRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function ArenaView:getRuleContext(view)
	local rank = self.record:read().rank
	local rankTop = self.record:read().rank_top
	local nowAwardData
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.arenaRule)
		end),
		c.clone(self.ruleRankItem, function(item)
			local childs = item:multiget("highest", "textNow1", "now", "textNow2", "list")
			childs.highest:text(rankTop)
			if not nowAwardData then
				nodetools.invoke(item, {"textNow1", "now", "textNow2", "list"}, "hide")
				setContentSizeOfAnchor(item, cc.size(self.ruleRankItem:size().width, nowAwardData and 370 or 100))
			else
				childs.now:text(rank)
				adapt.oneLinePos(childs.textNow1, {childs.now, childs.textNow2}, cc.p(5, 0))
				uiEasy.createItemsToList(view, childs.list, nowAwardData.periodAward)
				childs.list:setItemAlignCenter()
			end
		end),
		c.noteText(101),
		c.noteText(10001, 10100),
		c.noteText(102),
		c.noteText(10101, 10200),
		c.noteText(103),
	}
	local version = getVersionContainMerge("pwAwardVer")
	for k, v in orderCsvPairs(csv.pwaward) do
		if v.version == version then
			if rank >= v.range[1] and rank < v.range[2] then
				nowAwardData = v
			end
			table.insert(context, c.clone(view.awardItem, function(item)
				local childs = item:multiget("text", "list")
				if v.range[2] - v.range[1] == 1 then
					childs.text:text(string.format(gLanguageCsv.rankSingle, v.range[1]))
				else
					childs.text:text(string.format(gLanguageCsv.rankMulti, v.range[1], v.range[2] - 1))
				end
				uiEasy.createItemsToList(view, childs.list, v.periodAward)
			end))
		end
	end
	return context
end

function ArenaView:onChangeLogoID(logoId)
	self.logoId:set(logoId)
end

function ArenaView:onChangeSpine(cardId)
	local hasSelf = false
	self.selectCardId = cardId
	for i,v in self.myEnemys:ipairs() do
		if v:proxy().role_db_id == self.record:read().role_db_id then
			hasSelf = true
			break
		end
	end
	if hasSelf and self.myItemIdx:read() > 0 then
		local item = self.list:getItem(self.myItemIdx:read() - 1)
		item:get("panel"):removeChildByName("spineNode")

		local unitId = dataEasy.getUnitIdForJJC(cardId)
		local unit = csv.unit[unitId]
		local size = item:size()
		local cardSprite = widget.addAnimationByKey(item:get("panel"), unit.unitRes, "spineNode", "standby_loop", 3)
			:xy(size.width / 2, size.height / 2 - 40)
			:scale(unit.scale * 0.85)
		cardSprite:setSkin(unit.skin)
	end
end

function ArenaView:onShowShop(node, event)
	if not gGameUI:goBackInStackUI("city.shop") then
		gGameApp:requestServer("/game/fixshop/get", function(tb)
			gGameUI:stackUI("city.shop", nil, {full = true}, game.SHOP_INIT.PVP_SHOP)
		end)
	end
end

-- 1：正常 2：冷却 3：购买
function ArenaView:onBuyOrResetTime(inEmbattle)
	local state = self.state:read()
	local curCost = self.costNum:read()
	if state == 1 then
		local resetEnemyFunc = function()
			gGameApp:requestServer("/game/pw/battle/get", function(tb)
				local arena = gGameModel.arena
				self.top10 = idlereasy.assign(arena:getIdler("top10"), self.top10)
				self.enemys = idlereasy.assign(arena:getIdler("enemys"), self.enemys)
			end, 1)
		end
		if curCost > 0 then
			local params = {
				cb = resetEnemyFunc,
				isRich = true,
				btnType = 2,
				content = string.format(gLanguageCsv.richCostDiamond, curCost) .. gLanguageCsv.changeEnemy,
				dialogParams = {clickClose = false},
			}
			gGameUI:showDialog(params)
		else
			resetEnemyFunc()
		end

		return
	end
	local requestUrl = "/game/pw/battle/cd/buy"
	local contentStr = string.format(gLanguageCsv.richCostDiamond, curCost) .. gLanguageCsv.buyTime
	if state == 3 then
		requestUrl = "/game/pw/battle/buy"
		contentStr = string.format(gLanguageCsv.richCostDiamond, curCost) .. gLanguageCsv.pvpBuyTime
		local vipLv = gGameModel.role:read("vip_level")
		if self.buyPwTimes:read() >= gVipCsv[vipLv].buyPWTimes then
			gGameUI:showTip(gLanguageCsv.pwBuyMax)
			return
		end
	end
	if curCost > 0 then
		local params = {
			cb = function()
				gGameApp:requestServer(requestUrl, function(tb)
					self.state:set(STATE.NORMAL)
					if state == 3 and type(inEmbattle) == "function" then
						inEmbattle()
					end
				end)
			end,
			isRich = true,
			btnType = 2,
			content = contentStr,
			dialogParams = {clickClose = false},
		}
		gGameUI:showDialog(params)
	else
		gGameApp:requestServer(requestUrl, function(tb)
			self.state:set(STATE.NORMAL)
		end)
	end
end

function ArenaView:onResetRole(node, event)
	gGameUI:stackUI("city.card.embattle.arena", nil, {full = true}, {from = "arena", team = true})
end

function ArenaView:setCost(cost)
	self.textCost:text(cost)
	idlereasy.when(gGameModel.role:getIdler('rmb'), function(_, rmb)
		self.textCost:setTextColor(cost > 0 and cost > rmb and ui.COLORS.NORMAL.RED or ui.COLORS.NORMAL.DEFAULT)
	end):anonyOnly(self, 'cost')
end

return ArenaView