-- @date 2020-8-25
-- @desc 实时匹配ban选界面

local RECORD_STEP_TIME = 3
local BAN_MAX = 6

local STATE_TYPE = {
	empty = 1,
	ban = 2,
	pick = 3,
	deploy = 4,
}

local function initBanData(flag, list, node, k, v)
	if flag == 1 then
		node:scale(-1, 1)
	end
	local dbid = v.dbid
	node:get("flag"):hide()
	node:removeChildByName("effect")
	if dbid == -1 then
		bind.extend(list, node, {
			class = "card_icon",
			props = {
				cardId = -1,
				onNode = function(panel)
					panel:scale(0.6)
					local bound = panel:box()
					panel:alignCenter(bound)
					node:size(bound)
					if flag == 2 then
						panel:get("icon"):scale(-1, 1)
					end
				end,
			}
		})
	else
		local banpickCards = v.banpickCards
		local cardId = banpickCards.card_id
		local cardCfg = csv.cards[cardId]
		local unitCfg = csv.unit[cardCfg.unitID]
		local unitId = dataEasy.getUnitId(cardId, banpickCards.skin_id)
		bind.extend(list, node, {
			class = "card_icon",
			props = {
				unitId = unitId,
				rarity = unitCfg.rarity,
				star = banpickCards.star,
				advance = banpickCards.advance,
				levelProps = {
					data = banpickCards.level,
				},
				onNode = function(panel)
					panel:scale(0.6)
					local bound = panel:box()
					panel:alignCenter(bound)
					node:size(bound)
					if v.new then
						panel:hide()
						performWithDelay(node, function()
							panel:show()
						end, 8/30)
						widget.addAnimationByKey(node, "battlearena/ban1.skel", "effect", "tx_ban_effect", 10)
							:alignCenter(node:size())
							:scale(2)
					else
						panel:show()
						node:get("flag"):show()
					end
				end,
			}
		})
	end
end

local function onBanAfterBuild(list)
	list:refreshView()
	local count = 0
	for _, v in pairs(list.data) do
		if v:read().dbid ~= -1 then
			count = count + 1
		end
	end
	count = cc.clampf(count - 1, 0, itertools.size(list.data) - 1)
	list:jumpToItem(count, cc.p(0.5, 0.5), cc.p(0.5, 0.5))
end

local ViewBase = cc.load("mvc").ViewBase
local OnlineFightBanEmbattleView = class("OnlineFightBanEmbattleView", ViewBase)

OnlineFightBanEmbattleView.RESOURCE_FILENAME = "online_fight_ban_embattle.json"
OnlineFightBanEmbattleView.RESOURCE_BINDING = {
	["btnClose"] = {
		varname = "btnClose",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBackClick")}
		},
	},
	["titlePanel"] = "titlePanel",
	["titlePanel.item"] = "titleItem",
	["titlePanel.leftList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("leftBanData"),
				item = bindHelper.self("titleItem"),
				onItem = functools.partial(initBanData, 1),
				onAfterBuild = onBanAfterBuild,
			},
		},
	},
	["titlePanel.rightList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rightBanData"),
				item = bindHelper.self("titleItem"),
				onItem = functools.partial(initBanData, 2),
				onAfterBuild = onBanAfterBuild,
			},
		},
	},
	["leftRolePanel"] = "leftRolePanel",
	["rightRolePanel"] = "rightRolePanel",
	["rightDown"] = "rightDown",
	["rightDown.btnFilter"] = "btnFilter",
	["rightDown.btnOK"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnOKClick")}
		},
	},
	["battlePanel1"] = "battlePanel1",
	["battlePanel1.btnGHimg"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onTeamBuffClick1")}
		}
	},
	["battlePanel2"] = "battlePanel2",
	["battlePanel2.btnGHimg"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onTeamBuffClick2")}
		}
	},
	["banPanel"] = "banPanel",
	["spritePanel"] = "spriteItem",
	["bottomPanel"] = "bottomPanel",
	["bottomPanel.textNotRole"] = "bottomEmptyTxt",
	["bottomPanel.item"] = "bottomItem",
	["bottomPanel.subList"] = "bottomSubList",
	["bottomPanel.list"] = {
		varname = "cardList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("allCardDatas"),
				columnSize = 2,
				item = bindHelper.self("bottomSubList"),
				cell = bindHelper.self("bottomItem"),
				emptyTxt = bindHelper.self("bottomEmptyTxt"),
				dataFilterGen = bindHelper.self("onFilterCards", true),
				dataOrderCmp = function(a, b)
					if a.isBan ~= b.isBan then
						return a.isBan == true
					end
					if a.isPick ~= b.isPick then
						return a.isPick == true
					end
					if a.battle ~= b.battle then
						return a.battle > b.battle
					end
					if a.rarity ~= b.rarity then
						return a.rarity > b.rarity
					end
					return a.card_id < b.card_id
				end,
				asyncPreload = 24,
				onCell = function(list, node, k, v)
					local textNote = node:get("textNote"):hide()
					local grayState = 0
					if v.isBan then
						grayState = 1
						textNote:show():text(gLanguageCsv.onlineFightBanIsBan)
						text.addEffect(textNote, {color = cc.c4b(255, 81, 103, 255), outline = {color = cc.c4b(119, 2, 35, 255)}})

					elseif v.isPick then
						grayState = 1
						textNote:show():text(gLanguageCsv.onlineFightBanIsPick)
						text.addEffect(textNote, {color = cc.c4b(254, 235, 156, 255), outline = {color = cc.c4b(236, 75, 0, 255)}})

					elseif v.battle > 0 then
						grayState = 1
						textNote:show():text(gLanguageCsv.onlineFightBanIsBattle)
						text.addEffect(textNote, {color = cc.c4b(155, 242, 62, 255), outline = {color = cc.c4b(5, 115, 39, 255)}})
					end

					bind.extend(list, node, {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							rarity = v.rarity,
							star = v.star,
							grayState = grayState,
							levelProps = {
								data = v.level,
							},
							onNode = function(panel)
								panel:xy(-4, -4)
							end,
						}
					})
					node:onTouch(functools.partial(list.clickCell, v))
				end,
				onBeforeBuild = function(list)
					list.emptyTxt:hide()
				end,
				onAfterBuild = function(list)
					local cardDatas = itertools.values(list.data)
					if #cardDatas == 0 then
						list.emptyTxt:show()
					else
						list.emptyTxt:hide()
					end
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onCardItemTouch", true),
			},
		},
	},
	["stepOK"] = "stepOK",
	["stepChange"] = "stepChange",
	["recordMask"] = "recordMask",
}


function OnlineFightBanEmbattleView:onCreate(params)
	local isFirst = true
	self.startFighting = params.startFighting
	self.isRecord = params.recordData ~= nil
	self.recordData = params.recordData
	self.btnClose:hide()
	self.stepOK:hide()
	self.titlePanel:get("countdown"):hide()
	self.recordMask:visible(self.isRecord)
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onBackClick")})
		:init()

	if self.isRecord then
		self:disableUpdate()
	end
	self.clientStep = 0
	self:initModel()
	self.banCount = self:getBanCount()

	self.leftBanData = idlers.newWithMap({})
	self.rightBanData = idlers.newWithMap({})
	self.allCardDatas = idlers.newWithMap({})

	self.state = idler.new(STATE_TYPE.empty)
	self.step = idler.new(self.clientStep)
	self.clientBanCards = idlertable.new({})
	self.clientBattleCards = idlertable.new({})
	self.remoteDone = idlertable.new({})
	self.remoteOffline = idlertable.new({})
	self.countdown = idler.new(0)
	self.btnOKStep = 0
	self.titleDesc = idler.new("")

	self:initRolePanel(1)
	self:initRolePanel(2)
	self:initBattlePanel()
	self:initFilterBtn()

	widget.addAnimationByKey(self.stepChange, "battlearena/ban1.skel", "effect", "quantou_effect", 1)
		:alignCenter(self.stepChange:size())
		:scale(2)
		:hide()

	self.goBattle = false
	-- 实时匹配中等待 game.SYNC_SCENE_STATE.waitloading 这个状态才可以进战斗
	self.waitForBattle = idler.new(false)
	idlereasy.when(self.waitForBattle, function()
		if self.isRecord or self.goBattle then
			-- 展示3秒后进战斗
			performWithDelay(self, function()
				local startFighting = self.startFighting
				self:onClose()
				startFighting()
			end, 3)
			return
		end
		-- 若 20 秒后状态也没改变，弹框提示玩家点击确认重试
		performWithDelay(self, function()
			local cb = function()
				if not gGameUI:goBackInStackUI("city.adventure.pvp") then
					gGameUI:goBackInStackUI("city.view")
				end
				if gGameModel.role:read("in_cross_online_fight_battle") then
					dataEasy.onlineFightLoginServer()
				end
			end
			gGameUI:showDialog({
				content = gLanguageCsv.onlineFightWaitForBattle,
				cb = cb,
				closeCb = cb,
				btnType = 1,
				clearFast = true,
				dialogParams = {clickClose = false},
			})
		end, 20)
	end, true)

	idlereasy.when(self.step, function(_, step)
		-- 会有网络断连的情况，重新获取数据
		self:initModel()
		-- 服务器数据到了，状态为已确定状态
		self.btnOKStep = step
		self:deleteMovingItem()
		self.titlePanel:get("countdown"):hide()
		local inputsteps = self.banpick_input_steps
		local nextDelay = 0.3
		if inputsteps[step] and inputsteps[step][1] then
			-- action 1.ban 2.pick 3.deploy
			local action = inputsteps[step][1].action
			if action == 1 then
				self.state:set(STATE_TYPE.ban, true)
				self.stepOK:show()
				nextDelay = 3

			elseif action == 2 then
				self.state:set(STATE_TYPE.pick, true)
				self.stepOK:show()
				nextDelay = 3

			elseif action == 3 then
				self.clientStep = step
				self.state:set(STATE_TYPE.deploy, true)
				self.stepOK:show()
				self.stepOK:get("img"):hide()
				local effect = self.stepOK:getChildByName("effect")
				if effect then
					effect:hide()
				end
				nextDelay = 3
				-- 空卡牌数据则等待下一步数据
				if itertools.isempty(inputsteps[step][1].cards) then
					self:onSendData(step + 1, true)
					if self.isRecord then
						performWithDelay(self, function()
							self.step:set(step+1)
						end, RECORD_STEP_TIME)
					end
					return
				end
				self.waitForBattle:set(true)
			else
				self.state:set(STATE_TYPE.empty, true)
			end
		elseif step > 0 then
			nextDelay = 3
			self.waitForBattle:set(true)
		end
		-- stepOK 展示
		local effect = self.stepOK:getChildByName("effect")
		if not effect then
			self.stepOK:get("img"):hide()
			effect = widget.addAnimationByKey(self.stepOK, "battlearena/ban1.skel", "effect", "queren_effect", 1)
				:xy(self.stepOK:get("img"):xy())
				:scale(2)
		end
		effect:show()
		effect:play("queren_effect")
		if isFirst then
			nextDelay = 0.3
		end

		performWithDelay(self, function()
			if self.waitForBattle:read() then
				return
			else
				-- next step
				local banpicks = self.banpicks[step + 1]
				local nextState, imgs
				if banpicks then
					if banpicks.ban then
						imgs = {"txt_jinxuan.png", "txt_jingling.png"}
						nextState = STATE_TYPE.ban

					elseif banpicks.pick then
						imgs = {"txt_xuanze.png", "txt_jingling.png"}
						nextState = STATE_TYPE.pick
					end
				else
					imgs = {"txt_tiaozheng.png", "txt_zhenrong.png"}
					nextState = STATE_TYPE.deploy
				end
				if nextState then
					self.clientStep = step + 1
					self.stepOK:hide()
					self.stepChange:show()
					self.stepChange:setBackGroundColorType(0)
					self.stepChange:getChildByName("effect"):show():play("quantou_effect")
					local img1 = self.stepChange:get("img1"):opacity(0):texture("city/pvp/online_fight/ban/" .. imgs[1])
					local img2 = self.stepChange:get("img2"):opacity(0):texture("city/pvp/online_fight/ban/" .. imgs[2])
					performWithDelay(self.stepChange, function()
						transition.executeSequence(img1, true)
							:fadeIn(0.2)
							:delay(0.4)
							:fadeOut(0.2)
							:done()
						transition.executeSequence(img2, true)
							:fadeIn(0.2)
							:delay(0.4)
							:fadeOut(0.2)
							:done()
					end, 0.5)
					performWithDelay(self.stepChange, function()
						self.stepChange:hide()
						self.clientBanCards:set({})
						self.state:set(nextState, true)
						if self.isRecord then
							performWithDelay(self, function()
								self.step:set(step+1)
							end, RECORD_STEP_TIME)
						end
					end, 30/30)
				end
			end
		end, nextDelay)
	end)

	idlereasy.when(self.clientBanCards, function()
		self.selectIndex:set(0)
		self.draggingIndex:set(0)
		self:refreshDownData()
		for i = 1, BAN_MAX do
			self:refreshBattleSprite(i)
		end
		dataEasy.tryCallFunc(self.cardList, "filterSortItems", true)
		self:onSendData(self.clientStep, false, true)
	end, true)

	idlereasy.when(self.clientBattleCards, function()
		self.selectIndex:set(0)
		self.draggingIndex:set(0)
		self:refreshTeamBuff(1)
		self:refreshTeamBuff(2)
		self:refreshDownData()
		for i = 1, 12 do
			self:refreshBattleSprite(i)
		end
		dataEasy.tryCallFunc(self.cardList, "filterSortItems", true)
		self:onSendData(self.clientStep, false, true)
	end, true)

	idlereasy.when(self.state, functools.partial(self.refreshPanel, self))

	local countdownPanel = self.titlePanel:get("countdown")
	idlereasy.when(self.countdown, function(_, countdown)
		countdownPanel:text(countdown)
	end)

	idlereasy.when(self.remoteDone, function(_, done)
		if done and done[self.swapFlag and 1 or 2] == true then
			self.titleDesc:set(gLanguageCsv.onlineFightBanEnemySure)
		end
	end)

	idlereasy.when(self.remoteOffline, function(_, offline)
		self:initRolePanel(2)
	end)

	local descNode = self.titlePanel:get("desc"):text("")
	local descBgNode = self.titlePanel:get("descBg")
	text.addEffect(descNode, {outline = {color = cc.c4b(239, 69, 96, 255)}})
	idlereasy.when(self.titleDesc, function(_, desc)
		descNode:stopAllActions()
		if desc == "" then
			descNode:hide()
			descBgNode:hide()
		else
			transition.executeSequence(descNode, true)
				:easeBegin("IN")
					:scaleXTo(0.2, 1.5)
				:easeEnd()
				:func(function()
					descNode:show():text(desc)
					descBgNode:show()
				end)
				:easeBegin("IN")
					:scaleXTo(0.2, 1)
				:easeEnd()
				:done()
		end
	end)

	self:onListenResult()

	isFirst = false
end


function OnlineFightBanEmbattleView:onBackClick()
	if self.isRecord then
		self:onClose()
		return
	end
	-- 1小时内逃跑超过3次，不允许再逃跑
	local onlineFightFleeTime = userDefault.getForeverLocalKey("onlineFightFleeTime", {})
	if #onlineFightFleeTime >= 3 and (time.getTime() - onlineFightFleeTime[1] < 3600) then
		gGameUI:showTip(gLanguageCsv.onlineFightNoFlee)
	else
		gGameUI:showDialog({
			content = gLanguageCsv.onlineFightBanGiveUp,
			isRich = true,
			cb = function()
				self:disableUpdate()
				gGameModel.battle:flee()
			end,
			btnType = 2,
			clearFast = true,
		})
	end
end

function OnlineFightBanEmbattleView:onListenResult()
	if self.isRecord then
		return
	end
	local hasResult = false
	idlereasy.when(self.battleError, function(_, err)
		if err and err ~= "" then
			self:onClose()
			gGameUI:showTip(gLanguageCsv.onlineFightBanError)
		end
	end)
	idlereasy.when(self.battleState, function(_, state)
		if not hasResult then
			performWithDelay(self, function()
				if state == game.SYNC_SCENE_STATE.waitloading or state == game.SYNC_SCENE_STATE.attack then
					hasResult = true
					self:disableUpdate()
					self.goBattle = true
					self.waitForBattle:notify()

				elseif state == game.SYNC_SCENE_STATE.battleover then
					hasResult = true
					self:disableUpdate()
					gGameApp.net:doRealtimeEnd()
					gGameApp:requestServer("/game/cross/online/battle/end", function(tb)
						if tb.view.pattern == 1 then
							tb.view.score = tb.view.unlimited_score
							-- tb.view.rank = tb.unlimited_rank
							tb.view.topRank = tb.view.unlimited_top_score
						elseif tb.view.pattern == 2 then
							tb.view.score = tb.view.limited_score
							-- tb.view.rank = tb.limited_rank
							tb.view.topRank = tb.view.limited_top_score
						end
						-- 适应pvp_win
						tb.view.rank_move = tb.view.delta
						tb.view.rank = tb.view.score
						tb.view.top_move = tb.view.top_move and 1 or 0

						local endInfos = {
							from = "ban_embattle",
							result = tb.view.result,
							awardRemainTime = 3,
							recordType = "jf", -- default:rank
							showReward =  tb.view.award ~= nil,--dailyRecord:getIdler("cross_online_fight_times") <= csv.cross.online_fight.base[1].matchTimeMax,
						}
						endInfos.serverData = tb
						self:showResultView(endInfos)
					end)
				end
			end, 1/60)
		end
	end)
end

function OnlineFightBanEmbattleView:showResultView(results)
	if results.showReward then
		gGameUI:stackUI("battle.battle_end.reward", nil, nil, self:createHandler("showResultView", results), results)
		return
	end
	gGameUI:stackUI("battle.battle_end.jf", nil, nil, nil, nil, results, self:createHandler("onClose"))
end

function OnlineFightBanEmbattleView:onUpdate(delta)
	local remote = gGameModel.cross_online_fight_banpick.remote
	local dt = math.ceil(math.max(remote.countdown - (time.getTime() - remote.countdown_timestamp), 0))
	self.countdown:set(dt)

	self.remoteDone:set(remote.done)
	self.remoteOffline:set(remote.offline)
	self.step:set(remote.step)
end

-- 当前步骤已确认
function OnlineFightBanEmbattleView:isStepSure()
	return self.btnOKStep >= self.clientStep
end

function OnlineFightBanEmbattleView:getCardsAndNatureChoose()
	local data = self.clientBattleCards:read()
	local cards = {}
	local nature_choose = {}
	local flags = self.teamBuffs1 and self.teamBuffs1.flags or {1, 1, 1, 1, 1, 1}
	for i = 1, 6 do
		if data[i] then
			table.insert(cards, data[i])
			nature_choose[data[i]] = flags[i]
		end
	end
	return cards, nature_choose
end

function OnlineFightBanEmbattleView:onSendData(step, done, clientChange)
	if self.isRecord then
		return
	end
	local banpicks = self.banpicks[step]
	if step <= self.step:read()then
		return
	end
	if clientChange and self:isStepSure() then
		return
	end
	if not banpicks then
		local cards, nature_choose = self:getCardsAndNatureChoose()
		if itertools.size(cards) > 0 then
			gGameModel.cross_online_fight_banpick:deploy(step, cards, done, nature_choose)
		end

	elseif banpicks.ban then
		local data = self.clientBanCards:read()
		local cards = {}
		for i = 1, BAN_MAX do
			local dbid = data[i]
			table.insert(cards, dbid)
		end
		gGameModel.cross_online_fight_banpick:ban(step, cards, done)

	elseif banpicks.pick then
		local data = self.clientBattleCards:read()
		local cards = {}
		for i = 1, 6 do
			local dbid = data[i]
			if not self.hashPickCards[dbid] then
				table.insert(cards, dbid)
			end
		end
		gGameModel.cross_online_fight_banpick:pick(step, cards, done)
	end
end

function OnlineFightBanEmbattleView:onBtnOKClick()
	if self.isRecord then
		return
	end
	if self:isStepSure() then
		gGameUI:showTip(gLanguageCsv.onlineFightBanBtnAlreadySure)

	elseif self.btnNum == self.btnTargetNum then
		if self.state:read() ~= STATE_TYPE.ban then
			gGameUI:showTip(gLanguageCsv.onlineFightBanBtnSure)
		end
		self.btnOKStep = self.clientStep
		local banpicks = self.banpicks[self.clientStep]
		if not banpicks then
			self.clientBattleCards:notify()
			self:onSendData(self.clientStep, true)

		elseif banpicks.ban then
			self.clientBanCards:notify()
			self:onSendData(self.clientStep, true)

		elseif banpicks.pick then
			self.clientBattleCards:notify()
			self:onSendData(self.clientStep, true)
		end
	else
		 gGameUI:showTip(string.format(gLanguageCsv.onlineFightBanNeed, self.btnTargetNum))
	end
end

function OnlineFightBanEmbattleView:initModel()
	if not self.isRecord then
		-- 若右侧数据是自己，则界面表现交换
		self.swapFlag = gGameModel.cross_online_fight_banpick.role2.role_db_id == gGameModel.role:read('id')
		self.clientStep = gGameModel.cross_online_fight_banpick.remote.step
		self.banpicks = gGameModel.cross_online_fight_banpick.banpicks
		self.banpick_cards = gGameModel.cross_online_fight_banpick.cards
		self.banpick_card_deck1 = gGameModel.cross_online_fight_banpick.card_deck1
		self.banpick_card_deck2 = gGameModel.cross_online_fight_banpick.card_deck2
		self.banpick_input_steps = gGameModel.cross_online_fight_banpick.remote.inputsteps
		self.rarityLimit = gGameModel.cross_online_fight_banpick.rarityLimit or {}
		self.battleState = idlereasy.assign(gGameModel.battle and gGameModel.battle.state, self.battleState)
		self.battleError = idlereasy.assign(gGameModel.battle and gGameModel.battle.error, self.battleError)
	else
		self.swapFlag = self.recordData.operateForce == 2
		self.banpick_cards = self.recordData.limited_card_deck.cards
		self.banpick_card_deck1 = self.recordData.limited_card_deck.card_deck1
		self.banpick_card_deck2 = self.recordData.limited_card_deck.card_deck2
		self.banpick_input_steps = self.recordData.banpick_input_steps

		self.banpicks = {}
		for _, steps in ipairs(self.banpick_input_steps) do
			if steps[1] then
				if steps[1].action == 1 then
					table.insert(self.banpicks, {ban = itertools.size(steps[1].cards)})

				elseif steps[1].action == 2 then
					table.insert(self.banpicks, {pick = itertools.size(steps[1].cards)})
				end
			end
		end
		self.rarityLimit = {}
	end
end

function OnlineFightBanEmbattleView:initRolePanel(index)
	local node = index == 1 and self.leftRolePanel or self.rightRolePanel
	local dataIndex = self.swapFlag and (3-index) or index
	local data
	if not self.isRecord then
		data = dataIndex == 1 and gGameModel.cross_online_fight_banpick.role1 or gGameModel.cross_online_fight_banpick.role2
	else
		-- 战报数据里已经转换了
		data = {
			logo = self.recordData.logos[index],
			frame = self.recordData.role_frames[index],
			level = self.recordData.levels[index],
			name = self.recordData.names[index],
			game_key = self.recordData.game_keys[index],
		}
	end
	local offline = false
	local remoteOffline = self.remoteOffline:read()
	if remoteOffline and remoteOffline[dataIndex] == true then
		offline = true
	end
	local childs = node:multiget("head", "name", "server")
	childs.head:removeChildByName("offlineText")
	bind.extend(self, childs.head, {
		class = "role_logo",
		props = {
			logoId = data.logo,
			frameId = data.frame,
			-- level = data.level,
			level = false,
			vip = false,
			isGray = offline == true,
			onNode = function(panel)
				panel:scale(0.7)
				if offline == true then
					label.create(gLanguageCsv.onlineFightOffline, {
						fontPath = "font/youmi1.ttf",
						fontSize = 50,
						effect = {color = ui.COLORS.NORMAL.WHITE, outline = {color = ui.COLORS.NORMAL.DEFAULT}},
					}):xy(panel:xy())
						:addTo(childs.head, 10, "offlineText")
						:scale(0.7)
				end
			end,
		}
	})
	childs.name:text(data.name)
	childs.server:text(string.format(gLanguageCsv.brackets, getServerArea(data.game_key, true)))
end

function OnlineFightBanEmbattleView:refreshTitleData()
	local effect = self.titlePanel:getChildByName("effect")
	if not effect then
		effect = widget.addAnimationByKey(self.titlePanel, "battlearena/ban1.skel", "effect", "top_ban_effect", 1)
			:xy(self.titlePanel:width()/2, self.titlePanel:height() - 720 + 4)
			:scale(2)
		effect:setTimeScale(0)
	end
	if self.clientStep > self.step:read() then
		performWithDelay(self, function()
			effect:setTimeScale(1)
			effect:play("top_ban_effect")
		end, 0.1)
		if not self.isRecord then
			self.titlePanel:get("countdown"):show()
		end
	end

	local banpicks = self.banpicks[self.clientStep]
	local title
	local desc
	if banpicks then
		if banpicks.ban then
			title = gLanguageCsv.onlineFightBanTitleBan
			desc = gLanguageCsv.onlineFightBanDescBan

		elseif banpicks.pick then
			title = gLanguageCsv.onlineFightBanTitlePick
			desc = gLanguageCsv.onlineFightBanDescPick
		end
	else
		title = gLanguageCsv.onlineFightBanTitleDeploy
		desc = gLanguageCsv.onlineFightBanDescDeploy
	end
	-- 对方已确定
	local done = self.remoteDone:read()[self.swapFlag and 2 or 1]
	if done then
		desc = gLanguageCsv.onlineFightBanEnemySure
	end
	if self.clientStep <= self.step:read() then
		desc = gLanguageCsv.onlineFightBanEnemySure
	end
	self.titleDesc:set(desc)
	local childs = self.titlePanel:multiget("title", "descBg", "desc", "countdown")
	if title then
		childs.title:show():text(title)
	else
		childs.title:hide()
	end
end

function OnlineFightBanEmbattleView:refreshPanel()
	self:refreshTitleData()
	self:deleteMovingItem()
	itertools.invoke({self.battlePanel1, self.battlePanel2, self.banPanel, self.stepChange}, "hide")
	local state = self.state:read()
	if state == STATE_TYPE.ban then
		itertools.invoke({self.banPanel}, "show")
		local banpicks = self.banpicks[self.clientStep]
		local len = banpicks and banpicks.ban or 0
		local distance = math.min(375, 1250/len)
		local stPosX = 1000 - distance * (len-1)
		for i = 1, BAN_MAX do -- todo
			local item = self.banCards[i]
			item:visible(i <= len):x(stPosX + 2 * distance * (i - 1))
		end

	elseif state == STATE_TYPE.pick or state == STATE_TYPE.deploy then
		itertools.invoke({self.battlePanel1, self.battlePanel2}, "show")
	end

	self.leftBanData:update(self:getBanData(self.swapFlag and 1 or 2))
	self.rightBanData:update(self:getBanData(self.swapFlag and 2 or 1))
	self.allCardDatas:update(self:getAllCardDatas(self.swapFlag and 2 or 1))
end

function OnlineFightBanEmbattleView:getOrderData(cards)
	local data = {}
	for _, dbid in ipairs(cards) do
		local banpickCards = self.banpick_cards[dbid]
		local cardCfg = csv.cards[banpickCards.card_id]
		local unitCfg = csv.unit[cardCfg.unitID]
		table.insert(data, {
			dbid = dbid,
			cardId = banpickCards.card_id,
			rarity = unitCfg.rarity,
		})
	end
	table.sort(data, function(a, b)
		if a.rarity ~= b.rarity then
			return a.rarity > b.rarity
		end
		return a.cardId < b.cardId
	end)
	return data
end

-- action 1.ban 2.pick 3.deploy
function OnlineFightBanEmbattleView:getCards(step, action, index)
	local cards = {}
	for i = 1, step do
		local inputs = self.banpick_input_steps[i]
		if inputs and inputs[index] and inputs[index].action == action then
			arraytools.merge_inplace(cards, {inputs[index].cards})
		end
	end
	return cards
end

function OnlineFightBanEmbattleView:getBanCount()
	local count = 0
	for _, banpick in ipairs(self.banpicks) do
		count = count + (banpick.ban or 0)
	end
	return count
end

-- ban: 对方卡牌，我方扳卡; pick:我方卡住，对方扳卡
function OnlineFightBanEmbattleView:getAllCardDatas(index)
	local step = self.clientStep
	local state = self.state:read()
	if state == STATE_TYPE.empty or state == STATE_TYPE.ban then
		index = 3 - index
	end
	local banCards = self:getCards(step, 1, 3 - index)
	local hashBanCards = arraytools.hash(banCards)
	local pickCards = self:getCards(step, 2, index)
	local hashPickCards = arraytools.hash(pickCards)
	local hashClientBattleCards = {}
	self.hashBanCards = hashBanCards
	self.hashPickCards = hashPickCards
	if state == STATE_TYPE.ban then
		local clientBanCards = table.deepcopy(self.clientBanCards:read(), true)
		if self.isRecord or self.step:read() >= step then
			local inputsteps = self.banpick_input_steps
			if inputsteps and inputsteps[step][1].action == 1 then
				clientBanCards = inputsteps[step][3 - index].cards
			end
		end
		self.clientBanCards:set(clientBanCards, true)
		hashClientBattleCards = arraytools.hash(clientBanCards)

	elseif state == STATE_TYPE.pick or state == STATE_TYPE.deploy then
		local clientBattleCards = table.deepcopy(self.clientBattleCards:read(), true)
		-- 收到服务器的布阵数据则按数据显示
		local getClientBattleCards = function()  -- 提取
			local inputsteps = self.banpick_input_steps
			if inputsteps and inputsteps[step][1] and inputsteps[step][2] and inputsteps[step][1].action == 3 then
				if not itertools.isempty(inputsteps[step][1].cards) and not itertools.isempty(inputsteps[step][2].cards) then
					return arraytools.merge({inputsteps[step][index].cards, inputsteps[step][3 - index].cards})
				end
			end
		end
		if state == STATE_TYPE.deploy and self.step:read() >= step then
			clientBattleCards = getClientBattleCards()
		else
			local pickCardCount = 0
			for i = 1, 6 do
				local dbid = clientBattleCards[i]
				if hashPickCards[dbid] then
					pickCardCount = pickCardCount + 1
				end
			end
			for i = 7, 12 do
				local dbid = clientBattleCards[i]
				if dbid then
					pickCardCount = pickCardCount + 1
				end
			end
			local pickCards2 = self:getCards(step, 2, 3 - index)
			if #pickCards + #pickCards2 > pickCardCount then
				local newCards = {}
				local pickData1 = self:getOrderData(pickCards)
				local hashPickCardsTmp = table.deepcopy(hashPickCards)
				for i = 1, 6 do
					local dbid = clientBattleCards[i]
					if hashPickCardsTmp[dbid] then
						newCards[i] = dbid
						hashPickCardsTmp[dbid] = nil
					end
				end

				for i, data in ipairs(pickData1) do
					local dbid = data.dbid
					if hashPickCardsTmp[dbid] then
						-- 顺序加入到空位上
						for j = 1, 6 do
							if not newCards[j] then
								newCards[j] = dbid
								break
							end
						end
						hashPickCardsTmp[dbid] = nil
					end
				end
				local pickData2 = self:getOrderData(pickCards2)
				for i, data in ipairs(pickData2) do
					newCards[i + 6] = data.dbid
				end
				clientBattleCards = newCards
			end
		end
		self.clientBattleCards:set(clientBattleCards, true)
		hashClientBattleCards = arraytools.hash(clientBattleCards)
	else
		return {}
	end
	local cards = self["banpick_card_deck" .. index]
	local data = {}
	for _, dbid in pairs(cards) do
		local banpickCards = self.banpick_cards[dbid]
		local cardId = banpickCards.card_id
		local skinId = banpickCards.skin_id
		local cardCfg = csv.cards[cardId]
		local unitCfg = csv.unit[cardCfg.unitID]
		local unitId = dataEasy.getUnitId(cardId, skinId)
		data[dbid] = {
			dbid = dbid,
			card_id = cardId,
			unitId = unitId,
			rarity = unitCfg.rarity,
			attr1 = unitCfg.natureType,
			attr2 = unitCfg.natureType2,
			atkType = cardCfg.atkType,
			level = banpickCards.level,
			star = banpickCards.star,
			advance = banpickCards.advance,
			battle = hashClientBattleCards[dbid] and 1 or 0,
			isBan = hashBanCards[dbid],
			isPick = hashPickCards[dbid],
			markId = cardCfg.cardMarkID,
		}
	end
	return data
end

function OnlineFightBanEmbattleView:getBanData(index)
	local step = self.clientStep
	local banCards = self:getCards(step, 1, index)
	local banpicks = self.banpicks[step]
	local allLen = #banCards
	local newLen = banpicks and banpicks.ban or 0
	local banData = {}
	for i = 1, self.banCount do
		local dbid = banCards[i] or -1
		table.insert(banData, {
			dbid = dbid,
			banpickCards = self.banpick_cards[dbid],
			new = i > allLen - newLen and  i <= allLen,
		})
	end
	return banData
end

-- 初始化精灵布阵
function OnlineFightBanEmbattleView:initBattlePanel()
	self.battleCardsRect = {}
	self.battleCards = {}
	for i = 1, 6 do
		local item = self.battlePanel1:get("item"..i)
		local rect = item:box()
		local pos = item:getParent():convertToWorldSpace(cc.p(rect.x, rect.y))
		rect.x, rect.y = pos.x, pos.y
		self.battleCardsRect[i] = rect
		self.battleCards[i] = item
		item:onTouch(functools.partial(self.onBattleCardTouch, self, i))

		local imgBg = self.battleCards[i]:get("imgBg")
		local imgSel = imgBg:get("imgSel")
		if not imgSel then
			local size = imgBg:size()
			widget.addAnimationByKey(imgBg, "effect/buzhen2.skel", "imgSel", "effect_loop", 2)
				:xy(size.width/2, size.height/2 + 15)
				:hide()
		end
	end
	for i = 1, 6 do
		local item = self.battlePanel2:get("item"..i)
		self.battleCards[6 + i] = item
	end

	self.banCards = {}
	for i = 1, BAN_MAX do
		if i > 3 then
			local item = self.banPanel:get("item1")
			item:clone()
				:addTo(self.banPanel, item:z(), "item" .. i)
		end
		local item = self.banPanel:get("item"..i)
		self.banCards[i] = item
		item:onTouch(functools.partial(self.onBanCardTouch, self, i))

		local imgBg = self.banCards[i]:get("imgBg")
		local imgSel = imgBg:get("imgSel")
		if not imgSel then
			local size = imgBg:size()
			widget.addAnimationByKey(imgBg, "effect/buzhen2.skel", "imgSel", "effect_loop", 2)
				:xy(size.width/2, size.height/2 + 15)
				:hide()
		end
	end

	self.selectIndex = idler.new(0)
	idlereasy.when(self.selectIndex, function (_, selectIndex)
		local state = self.state:read()
		if state == STATE_TYPE.pick or state == STATE_TYPE.deploy then
			for i = 1, 6 do
				self.battleCards[i]:get("imgBg.imgSel"):visible(selectIndex == i)
			end
		elseif state == STATE_TYPE.ban then
			for i = 1, BAN_MAX do
				self.banCards[i]:get("imgBg.imgSel"):visible(selectIndex == i)
			end
		end
	end, true)

	self.draggingIndex = idler.new(0) -- 正在拖拽的节点的index
	idlereasy.when(self.draggingIndex, function (_, index)
		-- index - 1 全透明  0 全不透明
		local state = self.state:read()
		local len = state == STATE_TYPE.ban and BAN_MAX or 6
		local data = state == STATE_TYPE.ban and self.banCards or self.battleCards
		for i = 1, len do
			local sprite = data[i]:get("sprite")
			if sprite then
				sprite:setCascadeOpacityEnabled(true)
				if index == 0 then
					sprite:opacity(255)
				elseif index == -1 then
					sprite:opacity(155)
				elseif index == i then
					sprite:opacity(255)
				else
					sprite:opacity(155)
				end
			end
		end
	end, true)
end

-- 调整阵容过程中都只能看到友方的队伍光环，只有等双方都确认之后才会展示双方的队伍光环
-- 队伍光环会自动替换成最优解（队伍光环表加一个优先级字段）
function OnlineFightBanEmbattleView:refreshTeamBuff(battle)
	local attrs = {}
	local startIndex = battle == 1 and 1 or 7
	for i = startIndex, startIndex + 5 do
		local dbid = self.clientBattleCards:read()[i]
		local data = self.banpick_cards[dbid]
		if data then
			local cardCfg = csv.cards[data.card_id]
			local unitCfg = csv.unit[cardCfg.unitID]
			attrs[i - startIndex + 1] = {unitCfg.natureType, unitCfg.natureType2}
		end
	end
	local result = dataEasy.getTeamBuffBest(attrs)
	self["battlePanel" .. battle]:get("btnGHimg"):texture(result.buf.imgPath)
	self["teamBuffs"..battle] = result
end

function OnlineFightBanEmbattleView:refreshDownData()
	local banpicks = self.banpicks[self.clientStep]

	self.rightDown:removeChildByName("textNum")
	local str
	local num = 0
	local targetNum = 0
	local fontSize = 40
	if not banpicks then
		str = gLanguageCsv.onlineFightBanBtnDeploy
		fontSize = 35
	elseif banpicks.ban then
		num = self.clientBanCards:size()
		targetNum = banpicks.ban
		if self:isStepSure() then
			num = targetNum
		end
		str = string.format(gLanguageCsv.onlineFightBanBtnBan, num >= targetNum and "#C0x5B545B#" or "#C0xF13B54#", num, targetNum)

	elseif banpicks.pick then
		local clientBattleCards = self.clientBattleCards:read()
		local count = 0
		for i = 1, 6 do
			if clientBattleCards[i] then
				count = count + 1
			end
		end
		num = count - itertools.size(self.hashPickCards)
		targetNum = banpicks.pick
		if self:isStepSure() then
			num = targetNum
		end
		str = string.format(gLanguageCsv.onlineFightBanBtnPick, num >= targetNum and "#C0x5B545B#" or "#C0xF13B54#", num, targetNum)
	end
	if str then
		rich.createByStr("#C0x5B545B#" .. str, fontSize, nil, nil, cc.p(0, 0.5))
			:addTo(self.rightDown, 10, "textNum")
			:anchorPoint(cc.p(0, 0.5))
			:xy(20, 165)
			:formatText()
	end
	local btnState = num < targetNum and 3 or 1
	self.rightDown:get("btnOK.textNote"):text(self:isStepSure() and gLanguageCsv.commonAlreadyOk or gLanguageCsv.commonTextOk)
	uiEasy.setBtnShader(self.rightDown:get("btnOK"), self.rightDown:get("btnOK.textNote"), btnState)
	self.btnNum = num
	self.btnTargetNum = targetNum
end

function OnlineFightBanEmbattleView:initFilterBtn()
	-- 筛选UI按钮
	self.filterCondition = idlertable.new()
	idlereasy.any({self.filterCondition}, function()
		dataEasy.tryCallFunc(self.cardList, "filterSortItems", false)
	end)

	local pos = self.btnFilter:parent():convertToWorldSpace(self.btnFilter:box())
	pos = self:convertToNodeSpace(pos)
	local btnPos = gGameUI:getConvertPos(self.btnFilter, self:getResourceNode())
	gGameUI:createView("city.card.bag_filter", self.btnFilter):init({
		cb = self:createHandler("onBattleFilter"),
		others = {
			width = 190,
			height = 122,
			x = btnPos.x,
			y = btnPos.y,
			panelOrder = false,
		}
	}):z(19):xy(-pos.x, -pos.y)
end

-- 筛选
function OnlineFightBanEmbattleView:onBattleFilter(attr1, attr2, rarity, atkType)
	self.filterCondition:set({attr1 = attr1, attr2 = attr2, rarity = rarity, atkType = atkType}, true)
end

function OnlineFightBanEmbattleView:onFilterCards(list)
	local filterCondition = self.filterCondition:read()
	local condition = {}
	if not itertools.isempty(filterCondition) then
		condition = {
			{"rarity", (filterCondition.rarity < ui.RARITY_LAST_VAL) and filterCondition.rarity or nil},
			{"attr2", (filterCondition.attr2 < ui.ATTR_MAX) and filterCondition.attr2 or nil},
			{"attr1", (filterCondition.attr1 < ui.ATTR_MAX) and filterCondition.attr1 or nil},
			{"atkType", filterCondition.atkType},
		}
	end
	local function isOK(data, key, val)
		if data[key] == nil then
			if key ~= "attr2" or data.attr1 == val then
				return true
			end
		end
		if key == "atkType" then
			for k, v in ipairs(data.atkType) do
				if val[v] then
					return true
				end
			end
			return false
		end
		if data[key] == val then
			return true
		end
		return false
	end
	return function(dbid, card)
		for i = 1, #condition do
			local cond = condition[i]
			if cond[2] then
				if not isOK(card, cond[1], cond[2]) then
					return false
				end
			end
		end
		return true, dbid
	end
end

-- 按下
function OnlineFightBanEmbattleView:onCardItemTouch(list, v, event)
	if event.name == "began" then
		self.moved = false
		self.touchBeganPos = event
		self:deleteMovingItem()

	elseif event.name == "moved" then
		local deltaX = math.abs(event.x - self.touchBeganPos.x)
		local deltaY = math.abs(event.y - self.touchBeganPos.y)
		if not self.moved and not self:isMovePanelExist() and (deltaX >= ui.TOUCH_MOVED_THRESHOLD or deltaY >= ui.TOUCH_MOVED_THRESHOLD) then
			if deltaY > deltaX * 0.7 then
				local data = self.allCardDatas:atproxy(v.dbid)
				self:createMovePanel(data)
			end
			self.moved = true
		end
		self.cardList:setTouchEnabled(not self:isMovePanelExist())
		self:moveMovePanel(event)

	elseif event.name == "ended" or event.name == "cancelled" then
		if self:isMovePanelExist() == false and self.moved == false then --没有创建movePanel 说明是点击操作
			self:onCardClick(v, true)
			return
		end
		self:moveEndMovePanel(v)
	end
end

function OnlineFightBanEmbattleView:canMoveState(data, isShowTip)
	local state = self.state:read()
	if state == STATE_TYPE.ban then
		-- 已确认
		if self:isStepSure() then
			if isShowTip then
				gGameUI:showTip("当前已确定，无法操作")
			end
			return false
		end
		-- 已扳选
		if data.isBan then
			if isShowTip then
				gGameUI:showTip(gLanguageCsv.onlineFightBanTipBan)
			end
			return false
		end
		-- 已上阵
		if data.isPick then
			if isShowTip then
				gGameUI:showTip(gLanguageCsv.onlineFightBanTipPick)
			end
			return false
		end
	else
		if self:isStepSure() then
			if state == STATE_TYPE.deploy then
				if isShowTip then
					gGameUI:showTip(gLanguageCsv.onlineFightBanTipDeploy)
				end
				return false
			end
			if data.isPick or data.battle > 0 then
				return true
			end
		end
		-- 已扳选
		if data.isBan then
			if isShowTip then
				gGameUI:showTip(gLanguageCsv.onlineFightBanTipBan)
			end
			return false
		end
	end
	return true
end

function OnlineFightBanEmbattleView:createMovePanel(data)
	if self.movePanel then
		self.movePanel:removeSelf()
	end
	if not self:canMoveState(data) then
		return
	end
	local unitCsv = dataEasy.getUnitCsv(data.card_id, data.skin_id)
	local movePanel = self.spriteItem:clone():addTo(self:getResourceNode(), 1000)
	movePanel:show()

	local size = movePanel:get("icon"):size()
	-- 精灵
	local cardSprite = widget.addAnimationByKey(movePanel:get("icon"), unitCsv.unitRes, "hero", "run_loop", 1000)
		:scale(unitCsv.scale)
		:alignCenter(size)
	cardSprite:setSkin(unitCsv.skin)
	--光效
	widget.addAnimationByKey(movePanel:get("icon"), "effect/buzhen.skel", "effect", "effect_loop", 1002)
		:scale(1)
		:alignCenter(size)
	self.movePanel = movePanel
	self.draggingIndex:set(-1)
	return movePanel
end

function OnlineFightBanEmbattleView:deleteMovingItem()
	self.selectIndex:set(0)
	if self.movePanel then
		self.movePanel:removeSelf()
		self.movePanel = nil
	end
	self.draggingIndex:set(0)
end

function OnlineFightBanEmbattleView:moveMovePanel(event)
	if self.movePanel then
		self.movePanel:xy(event)
		self.selectIndex:set(self:whichEmbattleTargetPos(event))
	end
end

function OnlineFightBanEmbattleView:moveEndMovePanel(data)
	if not self.movePanel then
		return
	end
	local index = self.selectIndex:read()
	self:onCardMove(data, index, true)
	self:deleteMovingItem()
end

function OnlineFightBanEmbattleView:isMovePanelExist()
	return self.movePanel ~= nil
end

-- 点击卡牌，上阵或下阵
function OnlineFightBanEmbattleView:onCardClick(data, isShowTip)
	local tip
	local dbid = data.dbid
	local idx = self:getIdxByDbId(dbid)
	if not self:canMoveState(data, true) then
		-- do nothing

	elseif data.isPick or self:isStepSure() then
		tip = gLanguageCsv.onlineFightBanTipPickNoDown

	-- 在阵容上
	elseif data.battle > 0 then
		self:downBattle(dbid)
		-- tip = gLanguageCsv.downToEmbattle
	else
		local idx = self:getIdxByDbId()
		if not self:canBattleUp() then
			if self.state:read() == STATE_TYPE.deploy then
				tip = gLanguageCsv.onlineFightBanTipDeployFull
			else
				tip = string.format(gLanguageCsv.onlineFightBanTipFull, self.btnTargetNum)
			end

		-- ban 选无限制，上阵不能同 markID
		elseif self:hasSameMarkIDCard(data) then
			tip = gLanguageCsv.alreadyHaveSameSprite

		-- 稀有度限制
		elseif self:isRarityLimit(data, nil, true) then
			-- do nothing

		else
			self:upBattle(dbid, idx)
			-- tip = gLanguageCsv.addToEmbattle
		end
	end
	if isShowTip and tip then
		gGameUI:showTip(tip)
	end
end

-- rarityLimit = {[3] = 2, [4] = 0}
function OnlineFightBanEmbattleView:isRarityLimit(data, targetData, isShowTip)
	if self.state:read() == STATE_TYPE.pick then
		if not targetData or targetData.rarity ~= data.rarity then
			if self.rarityLimit[data.rarity] then
				local rarity = 1 -- data.rarity 计数 1
				local clientBattleCards = self.clientBattleCards:read()
				for i = 1, 6 do
					local dbid = clientBattleCards[i]
					local attrs = self:getCardAttrs(dbid)
					if attrs and attrs.rarity == data.rarity then
						rarity = rarity + 1
					end
				end
				if rarity > self.rarityLimit[data.rarity] then
					if isShowTip then
						local themeId = gGameModel.cross_online_fight:read("theme_id")
						local themeCfg = csv.cross.online_fight.theme[themeId]
						if themeCfg then
							gGameUI:showTip(themeCfg.desc)
						end
					end
					return true
				end
			end
		end
	end
end

function OnlineFightBanEmbattleView:canBattleUp()
	return self.btnNum < self.btnTargetNum
end

function OnlineFightBanEmbattleView:onTeamBuffClick1()
	local teamBuffs = self.teamBuffs1 and self.teamBuffs1.buf.teamBuffs or {}
	gGameUI:stackUI("city.card.embattle.attr_dialog",nil, {}, teamBuffs)

end
function OnlineFightBanEmbattleView:onTeamBuffClick2()
	local teamBuffs = self.teamBuffs2  and self.teamBuffs2.buf.teamBuffs or {}
	gGameUI:stackUI("city.card.embattle.attr_dialog",nil, {}, teamBuffs)
end

function OnlineFightBanEmbattleView:refreshBattleSprite(index, state)
	state = state or self.state:read()
	if state == STATE_TYPE.ban then
		local panel = self.banCards[index]
		panel:removeChildByName("sprite")
		local dbid = self.clientBanCards:read()[index]
		local data = self.banpick_cards[dbid]
		if not data then
			panel:removeChildByName("banEffect")
			return
		end
		local unitCsv = dataEasy.getUnitCsv(data.card_id, data.skin_id)
		local imgBg = panel:get("imgBg")
		local cardSprite = widget.addAnimationByKey(panel, unitCsv.unitRes, "sprite", "standby_loop", 4)
			:scale(unitCsv.scale * 1.5)
			:xy(imgBg:x(), imgBg:y() + 15)
		cardSprite:setSkin(unitCsv.skin)

		if self:isStepSure() then
			if not panel:getChildByName("banEffect") then
				widget.addAnimationByKey(panel, "battlearena/ban1.skel", "banEffect", "ban_effect", 100)
					:xy(imgBg:x(), imgBg:y())
					:scale(2)
			end
		else
			panel:removeChildByName("banEffect")
		end
	else
		local panel = self.battleCards[index]
		local dbid = self.clientBattleCards:read()[index]
		local data = self.banpick_cards[dbid]
		if not data then
			if panel:getChildByName("sprite") then
				panel:getChildByName("sprite"):hide()
			end
			panel:get("attrBg"):hide()
			return
		end
		local spriteId = data.card_id
		local unitCsv = dataEasy.getUnitCsv(spriteId, data.skin_id)
		if panel.spriteId == spriteId and panel:getChildByName("sprite") then
			panel:getChildByName("sprite"):show()
		else
			panel:removeChildByName("sprite")
			local imgBg = panel:get("imgBg")
			local cardSprite = widget.addAnimationByKey(panel, unitCsv.unitRes, "sprite", "standby_loop", 4)
				:scale(unitCsv.scale * 0.8)
				:xy(imgBg:x(), imgBg:y() + 15)
			if index > 6 then
				cardSprite:scale(-unitCsv.scale * 0.8, unitCsv.scale * 0.8)
			end
			cardSprite:setSkin(unitCsv.skin)
			panel.spriteId = spriteId
		end

		local battle = index > 6 and 2 or 1
		local flags = self["teamBuffs"..battle] and self["teamBuffs"..battle].flags or {1, 1, 1, 1, 1, 1}
		local flag = flags[index] or flags[index - 6]
		uiEasy.setTeamBuffItem(panel, spriteId, flag)
	end
end

function OnlineFightBanEmbattleView:onBattleCardTouch(idx, event)
	if not self.clientBattleCards:read()[idx] then
		return
	end
	local data = self:getCardAttrs(self.clientBattleCards:read()[idx])
	if not self:canMoveState(data, true) then
		return
	end
	if event.name == "began" then
		self:deleteMovingItem()
		self:createMovePanel(data)
		local panel = self.battleCards[idx]
		panel:get("sprite"):hide()
		panel:get("attrBg"):hide()

		self:moveMovePanel(event)
	elseif event.name == "moved" then
		self:moveMovePanel(event)

	elseif event.name == "ended" or event.name == "cancelled" then
		local panel = self.battleCards[idx]
		panel:get("sprite"):show()
		panel:get("attrBg"):show()
		self:deleteMovingItem()
		if event.y < 450 then
			-- 下阵
			self:onCardClick(data, true)
		else
			local targetIdx = self:whichEmbattleTargetPos(event)
			if targetIdx  then
				if targetIdx ~= idx then
					self:onCardMove(data, targetIdx, true)
					audio.playEffectWithWeekBGM("formation.mp3")
				else
					self:onCardMove(data, targetIdx, false)
				end
			else
				self:onCardMove(data, idx, false)
			end
		end
	end
end

function OnlineFightBanEmbattleView:onBanCardTouch(idx, event)
	if not self.clientBanCards:read()[idx] then
		return
	end
	local data = self:getCardAttrs(self.clientBanCards:read()[idx])
	if not self:canMoveState(data, true) then
		return
	end
	if event.name == "began" then
		self:deleteMovingItem()
		self:createMovePanel(data)
		local panel = self.banCards[idx]
		panel:get("sprite"):hide()
		self:moveMovePanel(event)

	elseif event.name == "moved" then
		self:moveMovePanel(event)

	elseif event.name == "ended" or event.name == "cancelled" then
		local panel = self.banCards[idx]
		panel:get("sprite"):show()
		self:deleteMovingItem()
		if event.y < 450 then
			-- 下阵
			self:onCardClick(data, true)
		else
			local targetIdx = self:whichEmbattleTargetPos(event)
			if targetIdx  then
				if targetIdx ~= idx then
					self:onCardMove(data, targetIdx, true)
					audio.playEffectWithWeekBGM("formation.mp3")
				else
					self:onCardMove(data, targetIdx, false)
				end
			else
				self:onCardMove(data, idx, false)
			end
		end
	end
end

-- data 数据移动到 targetIdx 位置上，targetIdx nil 为点击
function OnlineFightBanEmbattleView:onCardMove(data, targetIdx, isShowTip)
	local clientCards = self:getClientCards()
	local tip
	local dbid = data.dbid
	local idx = self:getIdxByDbId(dbid)
	local targetDbid = clientCards:read()[targetIdx]
	local targetData = self:getCardAttrs(targetDbid)

	if targetIdx then
		-- 在阵容上 互换
		if data.battle > 0 then
			if not targetData or self:canMoveState(targetData, true) then
				if self:getCardAttrs(targetDbid) then
					self:getCardAttrs(targetDbid).battle = self:getBattle(idx)
				end
				if self:getCardAttrs(dbid) then
					self:getCardAttrs(dbid).battle = self:getBattle(targetIdx)
				end
				clientCards:modify(function(oldval)
					oldval[idx], oldval[targetIdx] = oldval[targetIdx], oldval[idx]
					return true, oldval
				end, true)
			else
				self:refreshBattleSprite(idx)
			end
		else
			local commonIdx = self:hasSameMarkIDCard(data)
			if not targetData and not self:canBattleUp() then
				if self.state:read() == STATE_TYPE.deploy then
					tip = gLanguageCsv.onlineFightBanTipDeployFull
				else
					tip = string.format(gLanguageCsv.onlineFightBanTipFull, self.btnTargetNum)
				end

			elseif targetData and (targetData.isPick or (targetData.battle > 0 and self:isStepSure())) then
				tip = gLanguageCsv.onlineFightBanTipPickNoDown

			elseif commonIdx and commonIdx ~= targetIdx then
				tip = gLanguageCsv.alreadyHaveSameSprite

			-- 稀有度限制
			elseif self:isRarityLimit(data, targetData, true) then
				-- do nothing

			else
				if self:getCardAttrs(targetDbid) then-- 到阵容已有对象上，阵容上的下阵，拖动对象上阵
					self:getCardAttrs(targetDbid).battle = 0
				end
				if self:getCardAttrs(dbid) then
					self:getCardAttrs(dbid).battle = self:getBattle(targetIdx)
				end
				clientCards:modify(function(oldval)
					oldval[targetIdx] = dbid
					return true, oldval
				end, true)
				-- tip = gLanguageCsv.addToEmbattle
			end
		end
	end

	if isShowTip and tip then
		gGameUI:showTip(tip)
	end
end

function OnlineFightBanEmbattleView:getCardAttrs(dbid)
	return self.allCardDatas:atproxy(dbid)
end

function OnlineFightBanEmbattleView:getClientCards()
	return self.state:read() == STATE_TYPE.ban and self.clientBanCards or self.clientBattleCards
end

function OnlineFightBanEmbattleView:getIdxByDbId(dbid)
	local state = self.state:read()
	if state == STATE_TYPE.ban then
		local clientBanCards = self.clientBanCards:read()
		for i = 1, self.btnTargetNum do
			if clientBanCards[i] == dbid then
				return i
			end
		end
	else
		local clientBattleCards = self.clientBattleCards:read()
		for i = 1, 6 do
			if clientBattleCards[i] == dbid then
				return i
			end
		end
	end
end

-- 下阵
function OnlineFightBanEmbattleView:downBattle(dbid)
	local data = self:getCardAttrs(dbid)
	if data then
		-- 已上阵
		if data.isPick or self:isStepSure() then
			gGameUI:showTip(gLanguageCsv.onlineFightBanTipPickNoDown)
			return
		end
		self.allCardDatas:atproxy(dbid).battle = 0
		local idx = self:getIdxByDbId(dbid)
		if idx then
			local clientCards = self:getClientCards()
			clientCards:modify(function(oldval)
				oldval[idx] = nil
				return true, oldval
			end, true)
		end
	end
end

-- 上阵
function OnlineFightBanEmbattleView:upBattle(dbid, idx)
	local clientCards = self:getClientCards()
	self:getCardAttrs(dbid).battle = self:getBattle(idx)
	clientCards:modify(function(oldval)
		oldval[idx] = dbid
		return true, oldval
	end, true)
end

function OnlineFightBanEmbattleView:getBattle(i)
	if i and i ~= 0 then
		return 1
	else
		return 0
	end
end

function OnlineFightBanEmbattleView:whichEmbattleTargetPos(pos)
	-- 精灵交互区域可以存在覆盖，从最前面开始
	local state = self.state:read()
	if state == STATE_TYPE.ban then
		local banpicks = self.banpicks[self.clientStep]
		if banpicks and banpicks.ban then
			for i = 1, banpicks.ban do
				local item = self.banCards[i]
				local rect = item:box()
				local itemPos = item:getParent():convertToWorldSpace(cc.p(rect.x, rect.y))
				rect.x, rect.y = itemPos.x, itemPos.y
				if cc.rectContainsPoint(rect, pos) then
					return i
				end
			end
		end
	else
		for i = 6, 1, -1 do
			local rect = self.battleCardsRect[i]
			if cc.rectContainsPoint(rect, pos) then
				return i
			end
		end
	end
end

-- 是否有相同markid的精灵
function OnlineFightBanEmbattleView:hasSameMarkIDCard(data)
	-- ban 选无限制
	local state = self.state:read()
	if state == STATE_TYPE.ban then
		return false
	end
	for i = 1, 6 do
		local dbid = self.clientBattleCards:read()[i]
		if dbid then
			local cardData = self:getCardAttrs(dbid)
			if cardData.markId == data.markId then
				return i
			end
		end
	end
	return false
end

return OnlineFightBanEmbattleView