-- @date 2020-5-25
-- @desc 跨服竞技场挑战界面

local ViewBase = cc.load("mvc").ViewBase
local SelectEnemyView = class("SelectEnemyView", ViewBase)

local ENEMY_POS = {
	[1] = cc.p(560 + 250, 120 + 430),
	[2] = cc.p(1060 + 250, -50 + 430),
	[3] = cc.p(1560 + 250, 120 + 430),
	[4] = cc.p(2060 + 250, -50 + 430),
}
SelectEnemyView.RESOURCE_FILENAME = "cross_arena_enemy.json"
SelectEnemyView.RESOURCE_BINDING = {
	["textNoteTime"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["textTime"] = {
		varname = "textTime",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["centerPanel"] = "centerPanel",
	["centerPanel.selfPanel"] = "selfPanel",
	["centerPanel.selfPanel.textNoteRank"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["centerPanel.selfPanel.textRank"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["centerPanel.selfPanel.imgZlBg.textZl"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		},
	},

	["enemyPanel"] = "enemyPanel",
	["enemyPanel.textNoteRank"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["enemyPanel.textRank"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["enemyPanel.textName"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["enemyPanel.imgZlBg.textZl"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		},
	},

	-- 底部按钮
	["rightDownPanel.textNote1"] = "textNoteTimes",
	["rightDownPanel.textTimes"] = "textTimes",
	["rightDownPanel.textNote2"] = "textNoteChange",
	["rightDownPanel.textGold"] = "textGold",
	["rightDownPanel.imgGold"] = "imgGold",

	["rightDownPanel.btnAddTimes"] = {
		varname = "btnAdd",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClickAddTimes")}
		},
	},
	["rightDownPanel.btnChange"] = {
		varname = "btnChange",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClickChange")}
		},
	},
	["noteBg"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("sevenInfo")},
		},
	}
}

function SelectEnemyView:onCreate()
	self:initModel()
	self:initCountDown()

	idlereasy.any({self.vipLevel, self.pwTimes, self.buyPwTimes, self.refreshTimes}, function(_, vipLevel, pwTimes, buyPwTimes, refreshTimes)
		local freeTimes = gVipCsv[vipLevel].crossArenaFreePWTimes
		self.buyPWMaxTimes = gVipCsv[vipLevel].crossArenaBuyPWMaxTimes
		local canChallengeCount = math.max(0, freeTimes + buyPwTimes - pwTimes)
		self.textTimes:text(canChallengeCount .. "/".. freeTimes)
		if canChallengeCount < 1 then
			text.addEffect(self.textTimes, {color = ui.COLORS.NORMAL.ALERT_ORANGE})
		else
			text.addEffect(self.textTimes, {color = ui.COLORS.NORMAL.ALERT_GREEN})
		end

		local seq1 = gCostCsv.cross_arena_fresh_cost
		local idx1 = math.min(refreshTimes + 1, table.length(seq1))
		self.refreshCost = seq1[idx1]

		local seq2 = gCostCsv.cross_arena_pw_buy_cost
		local idx2 = math.min(buyPwTimes + 1, table.length(seq2))
		self.challengeCost = seq2[idx2]
		self.challenge5Cost = gCommonConfigCsv.crossArenaPassCostRmb
		if canChallengeCount < 5 then
			for i = 1,  5 - canChallengeCount do
				local idx = math.min(buyPwTimes + i, table.length(seq2))
				self.challenge5Cost = self.challenge5Cost + seq2[idx]
			end
		else
			self.challenge5Cost = gCommonConfigCsv.crossArenaPassCostRmb
		end
		self:refreshChallenge5Cost()

		local objs = {}
		local pos = {}
		if self.refreshCost > 0 then
			self.textGold:text(mathEasy.getShortNumber(self.refreshCost))
			idlereasy.when(gGameModel.role:getIdler('gold'), function(_, gold)
				self.textGold:setTextColor((self.refreshCost > 0 and self.refreshCost > gold) and ui.COLORS.NORMAL.RED or ui.COLORS.NORMAL.WHITE)
			end):anonyOnly(self, 'gold')
			table.insert(objs, self.imgGold:show())
			table.insert(objs, self.textGold:show())
			table.insert(objs, self.textNoteChange:show())
			pos = {cc.p(10, 0), cc.p(5, 0), cc.p(5, 0)}
		else
			self.imgGold:hide()
			self.textGold:hide()
			self.textNoteChange:hide()
		end
		if canChallengeCount > 0 then
			self.btnAdd:hide()
			table.insert(objs, self.textTimes)
			table.insert(objs, self.textNoteTimes)
			table.insert(pos, cc.p(40, 0))
			table.insert(pos, cc.p(5, 0))
		else
			table.insert(objs, self.btnAdd:show())
			table.insert(objs, self.textTimes)
			table.insert(objs, self.textNoteTimes)
			table.insert(pos, cc.p(40, 0))
			table.insert(pos, cc.p(5, 0))
			table.insert(pos, cc.p(5, 0))
		end
		adapt.oneLinePos(self.btnChange, objs, pos, "right")
		self.canChallengeCount = canChallengeCount
	end)

	idlereasy.any({self.role}, function(_, role)
		self:initSelfPanel(role)
	end)
	idlereasy.any({self.enemys}, function(_, enemys)
		self:initEnemyPanel(enemys)
	end)
	--彩带粒子特效
	local caidai = cc.ParticleSystemQuad:create("crossarena/caidai_1.plist")
	caidai:addTo(self:getResourceNode(), 10)
		:xy(self:getResourceNode():width()/2, self:getResourceNode():height())
		:scale(2)
end

function SelectEnemyView:initCountDown(  )
	local endTime = time.getNumTimestamp(self.date:read()) + 13 * 24 * 60 * 60 + 22 * 60 * 60
	-- 剩余时间
	local function setLabel()
		local remainTime = time.getCutDown(endTime - time.getTime())
		self.textTime:text(remainTime.str)
		if remainTime.hour < 1 and remainTime.day < 1 then
			text.addEffect(self.textTime, {color = ui.COLORS.NORMAL.ALERT_ORANGE})
		else
			text.addEffect(self.textTime, {color = ui.COLORS.NORMAL.ALERT_GREEN})
		end
		if endTime - time.getTime() <= 0 then
			-- self:onClose()
			return false
		end
		return true
	end
	setLabel()
	self:enableSchedule()
	self:schedule(function(dt)
		if not setLabel() then
			return false
		end
	end, 1, 0)
end


function SelectEnemyView:initSelfPanel(role)
	self.selfPanel:get("imgZlBg.textZl"):text(role.fighting_point)
	self.selfPanel:get("textRank"):text(dataEasy.getCrossArenaStageByRank(role.rank).rank)
	self.selfPanel:get("textName"):text(string.format(gLanguageCsv.brackets, getServerArea(role.game_key, true)) .. role.name)
	bind.extend(self, self.selfPanel:get("stagePanel"), {
		class = "stage_icon",
		props = {
			rank = role.rank,
			showStageBg = true,
			showStage = true,
			onNode = function(node)
				node:scale(0.9)
					:xy(60,50)
			end,
		},
	})
	adapt.oneLineCenterPos(cc.p(251,51), {self.selfPanel:get("imgZlBg.imgZl"),self.selfPanel:get("imgZlBg.textZl")}, cc.p(10,0))

	local unitId = dataEasy.getUnitIdForJJC(role.display)
	local unit = csv.unit[unitId]
	local cardSprite = widget.addAnimationByKey(self.selfPanel, unit.unitRes, "spineNode", "standby_loop", 1)
		:scale(unit.scale)
		:xy(250, 250)
	cardSprite:setSkin(unit.skin)

	bind.touch(self, self.selfPanel, {methods = {ended = function()
		self:onShowHeadIcon()
	end}})

	widget.addAnimationByKey(self.selfPanel, "crossarena/kfjjc_dizuo.skel", "kfjjc_bj", "effect_loop_lan", 0)
		:scale(2)
		:xy(250,250)
end

function SelectEnemyView:initEnemyPanel(enemys)
	table.sort(enemys, function(a,b)
		return a.rank < b.rank
	end)
	for i = 1, 4 do
		self.centerPanel:removeChildByName("enemy_"..i)
	end
	for i = 1, 4 do
		local enemy = enemys[i]
		if enemy == nil then
			break
		end
		local panel = self.enemyPanel:clone()
			:addTo(self.centerPanel)
			:xy(ENEMY_POS[i])
			:name("enemy_"..i)
		panel:get("imgZlBg.textZl"):text(enemy.fighting_point)
		panel:get("textRank"):text(dataEasy.getCrossArenaStageByRank(enemy.rank).rank)
		panel:get("textName"):text(string.format(gLanguageCsv.brackets, getServerArea(enemy.game_key, true)).. enemy.name)
		adapt.oneLineCenterPos(cc.p(250,711), {panel:get("stagePanel"), panel:get("textNoteRank"), panel:get("textRank")}, cc.p(10,0))
		bind.extend(self, panel:get("stagePanel"), {
			class = "stage_icon",
			props = {
				rank = enemy.rank,
				showStageBg = false,
				showStage = false,
				onNode = function(node)
					node:scale(0.9)
					:xy(60,0)
				end,
			},
		})
		adapt.oneLineCenterPos(cc.p(250,51), {panel:get("imgZlBg.imgZl"),panel:get("imgZlBg.textZl")}, cc.p(5,0))
		adapt.oneLinePos(panel:get("stagePanel"), panel:get("imgRankBg"), cc.p(-20,0))

		-- local unitId = csv.cards[enemy.display].unitID
		local unitId = dataEasy.getUnitIdForJJC(enemy.display)
		local unit = csv.unit[unitId]
		local cardSprite = widget.addAnimationByKey(panel, unit.unitRes, "spineNode", "standby_loop", 1)
			:scaleX(unit.scale * -1)
			:scaleY(unit.scale)
			:xy(250, 250)
		cardSprite:setSkin(unit.skin)
		local myRank = self.role:read().rank
		local enemyRank = enemy.rank
		local role_db_id = enemy.role_db_id
		local record_db_id = enemy.record_db_id
		bind.touch(self, panel:get("btnChallenge"), {methods = {ended = function()
			if table.length(self.cards:read()) < 2 then
				gGameUI:showTip(gLanguageCsv.crossArenaTwoSpritesTips)
			elseif self.canChallengeCount == 0 then
				if self.buyPwTimes:read() >= self.buyPWMaxTimes then
					gGameUI:showTip(gLanguageCsv.crossArenaBuyTimesMaxTips)
					return
				end
				gGameUI:showDialog({
					cb = function()
						if gGameModel.role:read("rmb") < self.challengeCost then
							gGameUI:showTip(gLanguageCsv.buyRMBNotEnough)
							return
						end
						gGameApp:requestServer("/game/cross/arena/battle/buy", function(tb)
							gGameUI:stackUI("city.pvp.cross_arena.embattle",nil,{full = true},
								{type = "attack", fightCb = self:createHandler("startFighting", enemy)})
						end)
					end,
					title = gLanguageCsv.spaceTips,
					content = string.format(gLanguageCsv.crossArenaBuyTimesTips, self.challengeCost),
					isRich = true,
					btnType = 2,
					clearFast = true,
					dialogParams = {clickClose = false},
				})
			else
				gGameUI:stackUI("city.pvp.cross_arena.embattle",nil,{full = true},
					{type = "attack", fightCb = self:createHandler("startFighting", enemy)})
			end
		end}})

		if enemy.rank < self.role:read().rank or (not dataEasy.isUnlock(gUnlockCsv.crossArenaPass)) then
			panel:get("btnChallenge5"):hide()
			panel:get("btnChallenge"):x(235)
		else
			panel:get("btnChallenge"):x(115)
			panel:get("btnChallenge5"):show()
			panel:get("btnChallenge5.textCost"):text(self.challenge5Cost)
			adapt.oneLineCenterPos(cc.p(133,100), {panel:get("btnChallenge5.imgDiamond"),panel:get("btnChallenge5.textCost")}, cc.p(10,0))
			bind.touch(self, panel:get("btnChallenge5"), {methods = {ended = function()
				if table.length(self.cards:read()) < 2 then
					gGameUI:showTip(gLanguageCsv.crossArenaTwoSpritesTips)
				else
					if gGameModel.role:read("rmb") < self.challenge5Cost then
						gGameUI:showTip(gLanguageCsv.buyRMBNotEnough)
						return
					end
					if self.challenge5Cost > 0 then
						gGameUI:showDialog({
							cb = function()
								gGameApp:requestServer("/game/cross/arena/battle/pass", function(tb)
									gGameUI:stackUI("city.pvp.cross_arena.pass", nil, {clickClose = true}, self.role:read(), enemy)
								end, enemy.rank)
							end,
							btnType = 2,
							isRich = true,
							content = string.format(gLanguageCsv.arenaPassTip, self.challenge5Cost),
							clearFast = true,
							dialogParams = {clickClose = false},
						})
					end
				end
			end}})
		end

		bind.touch(self, panel, {methods = {ended = function()
			gGameApp:requestServer("/game/cross/arena/role/info", function(tb)
				local view = gGameUI:stackUI("city.pvp.cross_arena.personal_info", nil, {clickClose = true, dispatchNodes = self.centerPanel}, tb.view)
				tip.adaptView(view, self, {relativeNode = panel, canvasDir = "horizontal", childsName = {"baseNode"}})
			end,enemy.record_db_id, enemy.game_key, enemy.rank)
		end}})
		widget.addAnimationByKey(panel, "crossarena/kfjjc_dizuo.skel", "kfjjc_bj", "effect_loop_huang", 0)
			:scale(2)
			:xy(250,250)
	end
end

function SelectEnemyView:refreshChallenge5Cost()
	for i = 1, 4 do
		local panel = self.centerPanel:get("enemy_"..i)
		if panel then
			panel:get("btnChallenge5.textCost"):text(self.challenge5Cost)
			adapt.oneLineCenterPos(cc.p(133,100), {panel:get("btnChallenge5.imgDiamond"),panel:get("btnChallenge5.textCost")}, cc.p(10,0))
		end
	end
end
function SelectEnemyView:initModel()
	self.date = gGameModel.cross_arena:getIdler("date")
	self.round = gGameModel.cross_arena:getIdler("round")
	self.servers = gGameModel.cross_arena:getIdler("servers")
	self.role = gGameModel.cross_arena:getIdler("role")
	self.enemys = gGameModel.cross_arena:getIdler("enemys")
	self.pwTimes = gGameModel.daily_record:getIdler("cross_arena_pw_times")--挑战次数
	self.buyPwTimes = gGameModel.daily_record:getIdler("cross_arena_buy_times") -- 购买的次数
	self.refreshTimes = gGameModel.daily_record:getIdler("cross_arena_refresh_times") -- 更换对手次数
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.cards = gGameModel.role:getIdler("cards")
end

--购买挑战次数
function SelectEnemyView:onClickAddTimes()
	gGameUI:showDialog({
		cb = function()
			if gGameModel.role:read("rmb") < self.challengeCost then
				gGameUI:showTip(gLanguageCsv.buyRMBNotEnough)
				return
			end
			gGameApp:requestServer("/game/cross/arena/battle/buy", function(tb)
				gGameUI:showTip(gLanguageCsv.buySuccess)
			end)
		end,
		title = gLanguageCsv.spaceTips,
		content = string.format(gLanguageCsv.crossArenaBuyTimesTips, self.challengeCost),
		isRich = true,
		btnType = 2,
		clearFast = true,
		dialogParams = {clickClose = false},
	})
end

--更换挑战玩家
function SelectEnemyView:onClickChange()
	gGameApp:requestServer("/game/cross/arena/battle/main", function(tb)
	end, 1)
end

function SelectEnemyView:onShowHeadIcon(node, event)
	gGameUI:stackUI("city.pvp.cross_arena.head_icon", nil, nil, self:createHandler("onChangeSpine"))
end

function SelectEnemyView:onChangeSpine(cardId)
	self.selfPanel:removeChildByName("spineNode")
	local unitId = dataEasy.getUnitIdForJJC(cardId)
	local unit = csv.unit[unitId]
	local cardSprite = widget.addAnimationByKey(self.selfPanel, unit.unitRes, "spineNode", "standby_loop", 1)
		:scale(unit.scale)
		:xy(250,250)
	cardSprite:setSkin(unit.skin)
end

function SelectEnemyView:startFighting(enemy, view, battleCards)
	local myRank = self.role:read().rank
	local battleRank = enemy.rank
	-- 防止schedule中有网络请求行为
	self:disableSchedule()
	battleEntrance.battleRequest("/game/cross/arena/battle/start", myRank, battleRank, enemy.role_db_id, enemy.record_db_id)
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

function SelectEnemyView:sevenInfo()
	gGameUI:stackUI("city.pvp.cross_arena.seven_info", nil, {clickClose = true, blackLayer = false}, nil)
end

return SelectEnemyView