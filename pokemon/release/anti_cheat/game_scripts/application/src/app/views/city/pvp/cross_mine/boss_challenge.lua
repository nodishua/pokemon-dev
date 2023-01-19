-- @desc:   公会副本界面

require "battle.models.scene"
-- local unionTools = require "app.views.city.union.tools"
local CrossMineBossChallengeView = class("CrossMineBossChallengeView", Dialog)
CrossMineBossChallengeView.RESOURCE_FILENAME = "cross_mine_boss_challenge.json"
CrossMineBossChallengeView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["title.textTitle1"] = "textTitle1",
	["centerPanel"] = "centerPanel",
	["centerPanel.btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleBtn")}
		},
	},
	["centerPanel.btnRule.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["rewardItem"] = "rewardItem",
	["buffItem"] = {
		varname = "buffItem",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBuffItem")}
		},
	},
	["buffItem.label"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(91, 84, 91), size = 4}},
		},
	},
	["centerPanel.listReward"] = "rewardList",
	["rankItem"] = "rankItem",
	["rightPanel.killedPanel"] = "killedPanel",
	["rightPanel.killedPanel.label1"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(244, 104, 78), size = 4}},
		},
	},
	["rightPanel.maskPanel"] = "maskPanel",
	["rightPanel.panelRank.rankList"] = {
		varname = "rankList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rankDatas"),
				item = bindHelper.self("rankItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"iconRank",
						"textRank1",
						"textRank2",
						"textName",
						"textDamage",
						"textServer"
					)
					childs.textName:text(v.name)
					childs.textDamage:text(v.damage)
					childs.textServer:text(getServerArea(v.game_key))
					uiEasy.setRankIcon(k, childs.iconRank, childs.textRank1, childs.textRank2)
				end,
			},
		},
	},
	["rightPanel.challengePanel"] = "challengePanel",
	["rightPanel.challengePanel.textTime"] = "textTime",
	["rightPanel.challengePanel.textCount"] = "textNum",
	["rightPanel.challengePanel.btnAdd"] = {
		varname = "btnAdd",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBuyTimes")}
		},
	},
	["rightPanel.challengePanel.btnFight"] = {
		varname = "btnFight",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnFight")}
		},
	},
	["rightPanel.challengePanel.btnFight.title"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		}
	},
	["rightPanel.empty"] = "empty",
	["rightPanel.panelRank"] = "rightPanel",
	["rightPanel.panelRank.listTitlePanel"] = "listTitlePanel",
	["rightPanel.down"] = "rightDown",
}

function CrossMineBossChallengeView:onCreate(id)
	Dialog.onCreate(self)
	self:initModel()
	self.bossID = id

	if self.bossInfo:read()[self.bossID] == nil or self.bossInfo:read()[self.bossID].csv_id == nil then
		self:hide()
		performWithDelay(self, function()
			gGameUI:showTip(gLanguageCsv.crossMineBossTimeout)
			self:onClose()
		end, 1/60)
		return
	end

	local cfg = csv.cross.mine.boss[self.bossInfo:read()[self.bossID].csv_id]
	-- buff
	local time = cfg.buffTime/60 .. "H"
	local buffItem = self.buffItem:clone():show()
	buffItem:get("label"):text(time)
	buffItem:get("img"):texture(cfg.buffIcon)
	self.rewardList:pushBackCustomItem(buffItem)

	for _, itemData in csvPairs(dataEasy.getItemData(cfg.killAward)) do
		local item = self.rewardItem:clone():show()
		local key = itemData.key
		local num = itemData.num
		local size = item:size()
		bind.extend(self, item, {
			class = "icon_key",
			props = {
				data = {
					key = key,
					num = num,
				},
				onNode = function(node)
					node:scale(0.9)
					node:xy(size.width/2, size.height/2)
				end,
			},
		})
		self.rewardList:pushBackCustomItem(item)
	end
	self.rewardList:setScrollBarEnabled(false)

	local container = self.rankList:getInnerContainer()
	self.rankList:onScroll(function(event)
		local y = container:getPositionY()
		if y >= -10 and self.isCanDown then
			self.isCanDown = false
			local offset = #self.rankInfo
			local size = 10
			gGameApp:requestServer("/game/cross/mine/boss/rank", function (tb)
				if tolua.isnull(self) then
					return
				end
				self:updateRankList(tb.view.rank.ranks, offset)
			end, self.bossID, offset, size)
		end
	end)

	idlereasy.any({self.bossBuyTimes, self.bossTimes}, function(_, bossBuyTimes, bossTimes)
		local allCount = csv.cross.mine.base[1].bossFreeTimes
		local times = bossTimes[self.bossID] or 0
		local buyTimes = bossBuyTimes[self.bossID] or 0
		self.leftTimes = allCount - times + buyTimes
		self.leftTimes = math.max(self.leftTimes, 0)
		self.textNum:text(string.format("%s:%s/%s", gLanguageCsv.changeTimes, self.leftTimes, allCount))
		if self.leftTimes > 0 then
			self.btnAdd:hide()
			self.textNum:x(self.btnAdd:x())
			self.textNum:color(cc.c3b(96, 196, 86))
		else
			-- 显示购买
			self.btnAdd:show()
			adapt.oneLinePos(self.btnAdd, self.textNum, cc.p(20, 0), "right")
			self.textNum:color(cc.c3b(91, 84, 91))
		end
	end)

	idlereasy.when(self.bossInfo, function(_, bossInfo)
		if bossInfo[self.bossID] then
			self:initBossInfo(bossInfo[self.bossID])
		end
	end)

end

function CrossMineBossChallengeView:initModel()
	self.bossInfo = gGameModel.cross_mine:getIdler("boss")
	self.bossBuyTimes = gGameModel.daily_record:getIdler("cross_mine_boss_buy_times")
	self.bossTimes = gGameModel.daily_record:getIdler("cross_mine_boss_times")
	self.role = gGameModel.cross_mine:getIdler("role")
	self.leftTimes = 0
	self.rankDatas = idlers.newWithMap({})
end

function CrossMineBossChallengeView:initBossInfo(bossInfo)
	local bossInfo = bossInfo or self.bossInfo:read()[self.bossID]
	-- print_r(bossInfo)
	local childs = self.centerPanel:multiget("textName", "iconAttr1", "iconAttr2", "bar", "textHp", "icon", "jifenLabel")
	local csvBoss = csv.cross.mine.boss[bossInfo.csv_id]
	local cfg = csv.scene_conf[csvBoss.gateID]
	local csvUnit = csv.unit[cfg.boss[1].unitId]

	childs.textName:text(csvUnit.name)
	local hp = 0
	local damage = 0
	local damageTable = bossInfo.damage or {}
	for k, val in pairs(bossInfo.hp) do
		hp = hp + val
		if damageTable[k] then
			-- 伤害不能超过血量
			damage = damage + math.min(damageTable[k], val)
		end
	end

	local percent = mathEasy.getPreciseDecimal((hp - damage)/hp*100, 1)
	percent = math.max(0, percent)
	if bossInfo.kill_role then
		percent = 0
		self.killedPanel:show()
		local label = self.killedPanel:get("label")
		local str = string.format("%s %s [ %s ]", gLanguageCsv.hasBeen, bossInfo.kill_role.name, getServerArea(bossInfo.kill_role.game_key))
		adapt.setTextScaleWithWidth(label, str, 900)
		self.challengePanel:hide()
	else
		self.killedPanel:hide()
		self.challengePanel:show()
	end
	childs.bar:percent(percent)
	childs.textHp:text(percent.."%")
	childs.icon:texture(csvUnit.show)

	childs.jifenLabel:text(csvBoss.serverKillPoint)

	childs.iconAttr1:texture(ui.ATTR_ICON[csvUnit.natureType])
	if csvUnit.natureType2 then
		childs.iconAttr2:texture(ui.ATTR_ICON[csvUnit.natureType2])
	else
		childs.iconAttr2:hide()
	end

	-- 倒计时
	local cfg = csv.cross.mine.boss[self.bossInfo:read()[self.bossID].csv_id]
	local endTime = cfg.duration*60 + self.bossInfo:read()[self.bossID].open_time
	local countdown =  endTime - time.getTime()
	self:setBossCountdown(countdown, self.textTime)

	self.rankInfo = {}
	local rankInfo = bossInfo.rank.ranks or {}
	self:updateRankList(rankInfo)
	local myInfo = bossInfo.rank.myInfo or {}
	self:updateMyInfo(myInfo)
end

-- 刷新排行榜
function CrossMineBossChallengeView:updateRankList(ranks, offset)
	local offset = offset or #self.rankInfo
	for k, val in pairs(ranks) do
		self.rankInfo[val.rank] = val
	end
	self.isCanDown = #ranks == 10
	if #self.rankInfo > 0 then
		self.empty:hide()
	else
		self.empty:show()
	end
	table.sort(self.rankInfo, function(a, b)
		return a.rank < b.rank
	end)
	self.rankDatas:update(self.rankInfo)
	-- self.rankList:jumpToItem(offset, cc.p(0, 1), cc.p(0, 1))
end

-- 刷新自己排行榜数据
function CrossMineBossChallengeView:updateMyInfo(myInfo)
	-- print_r(myInfo)
	local myInfo = myInfo or {}
	local childs = self.rightDown:multiget("textRank", "textName", "textDamage")
	if myInfo.rank > 0 then
		childs.textRank:text(myInfo.rank)
	end
	childs.textName:text(self.role:read().name)
	if myInfo.damage then
		childs.textDamage:text(myInfo.damage)
	end
end

--开始战斗
function CrossMineBossChallengeView:startFighting(view, battleCards)
	-- 防止schedule中有网络请求行为
	self:disableSchedule()
	battleEntrance.battleRequest("/game/cross/mine/boss/battle/start", self.bossID)
		:onStartOK(function(data)
			if view then
				view:onClose(false)
				view = nil
			end
		end)
		:show()
end

function CrossMineBossChallengeView:onBtnFight()
	local function fight()
		gGameUI:stackUI("city.card.embattle.base", nil, {full = true}, {
			fightCb = self:createHandler("startFighting"),
			from = game.EMBATTLE_FROM_TABLE.huodong,
			fromId = game.EMBATTLE_HOUDONG_ID.crossMineBoss,
		})
	end
	if self.bossInfo:read()[self.bossID] == nil then
		gGameUI:showTip(gLanguageCsv.gameIsOver)
		return
	end
	if self.leftTimes > 0 then
		fight()
	else
		self:onBuyTimes(fight)
	end
end

function CrossMineBossChallengeView:onRuleBtn()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
end

function CrossMineBossChallengeView:getRuleContext(view)
	local cfg = csv.cross.mine.boss[self.bossInfo:read()[self.bossID].csv_id]
	local serverVersion = cfg.rankAwardVersion
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(158),
		c.noteText(114001, 114020),
		c.noteText(159),
	}
	local rankAward = {}
	local rankScore = {}
	for k, v in orderCsvPairs(csv.cross.mine.boss_rank_award) do
		if v.version == serverVersion then
			table.insert(rankAward, {rank = v.rank, award = v.award})
			if v.score > 0 then
				table.insert(rankScore, {rank = v.rank, score = v.score})
			end
		end
	end
	local rank = 0
	for k, v in pairs(rankScore) do
		local str = string.format("%s +%s", gLanguageCsv.score, v.score)
		if v.rank - rank == 1 then
			str = " " .. string.format(gLanguageCsv.rankSingle, v.rank) .. " " .. str
		else
			str = " " .. string.format(gLanguageCsv.rankMulti, rank + 1, v.rank) .. " " .. str
		end
		table.insert(context, str)
		rank = v.rank
	end
	table.insert(context, c.noteText(160))
	rank = 0
	for k, v in pairs(rankAward) do
		table.insert(context, c.clone(view.awardItem, function(item)
			local childs = item:multiget("text", "list")
			if v.rank - rank == 1 then
				childs.text:text(string.format(gLanguageCsv.rankSingle, v.rank))
			else
				childs.text:text(string.format(gLanguageCsv.rankMulti, rank + 1, v.rank))
			end
			uiEasy.createItemsToList(view, childs.list, v.award)
			rank = v.rank
		end))
	end
	return context
end

function CrossMineBossChallengeView:onBuffItem()
	local rect = self.rewardList:box()
	local pos = self.rewardList:parent():convertToWorldSpace(cc.p(rect.x, rect.y))
	local params = {data = csv.cross.mine.boss[self.bossInfo:read()[self.bossID].csv_id], pos = {pos.x + self.buffItem:width()/2, pos.y + 200}}
	gGameUI:createView("city.pvp.cross_mine.buff_info", self):init(params)
end

function CrossMineBossChallengeView:onBuyTimes(callBack)
	-- 每个boss最多可挑战次数
	local bossMaxTimes = csv.cross.mine.base[1].bossMaxTimes
	local bossTimes = self.bossTimes:read()[self.bossID] or 0
	if bossTimes >= bossMaxTimes then
		gGameUI:showTip(gLanguageCsv.crossMineChallengeBossMaxTimes)
		return
	end
	local bossBuyTimes = self.bossBuyTimes:read()[self.bossID] or 0
	local times = math.min(itertools.size(gCostCsv.cross_mine_boss_buy_cost), bossBuyTimes+1)
	local curCost = gCostCsv.cross_mine_boss_buy_cost[times]
	local params = {
		cb = function()
			gGameApp:requestServer("/cross/mine/boss/times/buy", function()
					if type(callBack) == "function" then
						callBack()
					end
				end, self.bossID)
		end,
		isRich = true,
		btnType = 2,
		content = string.format(gLanguageCsv.richCostDiamond, curCost) .. gLanguageCsv.pvpBuyTime,
		dialogParams = {clickClose = false},
	}
	gGameUI:showDialog(params)
end

function CrossMineBossChallengeView:setBossCountdown(countdown, uiTime)
	self:enableSchedule():unSchedule(88)
	countdown = math.max(countdown, 0)
	if countdown == 0 then return end
	bind.extend(self, uiTime, {
		class = 'cutdown_label',
		props = {
			time = countdown,
			tag = 88,
			strFunc = function(t)
				return t.str
			end,
			callFunc = function()
			end,
			endFunc = function()
				if self.bossInfo:read()[self.bossID] then
					local cfg = csv.cross.mine.boss[self.bossInfo:read()[self.bossID].csv_id]
					local endTime = cfg.duration*60 + self.bossInfo:read()[self.bossID].open_time
					countdown =  endTime - time.getTime()
					if countdown > 0 then
						performWithDelay(self, function()
							self:setBossCountdown(countdown, uiTime)
						end, 1)
					else
						self:enableSchedule():unSchedule(88)
					end
				else
					self:enableSchedule():unSchedule(88)
				end
			end
		}
	})
end

return CrossMineBossChallengeView