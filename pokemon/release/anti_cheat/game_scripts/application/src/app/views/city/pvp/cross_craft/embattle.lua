-- @date 2020-3-5
-- @desc 跨服石英大会布阵界面

local CrossCraftView = require("app.views.city.pvp.cross_craft.view")
local ViewBase = cc.load("mvc").ViewBase
local CrossCraftEmbattleView = class("CrossCraftEmbattleView", ViewBase)

local NEED_CARDS = 12

CrossCraftEmbattleView.RESOURCE_FILENAME = "cross_craft_embattle.json"
CrossCraftEmbattleView.RESOURCE_BINDING = {
	["item"] = "item",
	["item.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["up"] = "upPanel",
	["up.special"] = "upSpecialPanel",
	["up.text"] = {
		varname = "upText",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["up.countdown"] = {
		varname = "upCountdown",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["up.item"] = "upItem",
	["up.groupItem"] = "upGroupItem",
	["up.list"] = "upList",
	["down"] = "downPanel",
	["down.tip2"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["down.text1"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["down.num"] = {
		varname = "downNum",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["down.emptyTip"] = "downEmptyTip",
	["down.btnOneKey"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onOneKeyClick")}
		},
	},
	["down.btnSave"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSaveClick")}
		},
	},
	["down.btnSave.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["prepare"] = "preparePanel",
	["prepare.title"] = "prepareTitle",
	["prepare.round"] = "prepareRound",
	["prepare.tip"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["prepare.btnSave"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSaveClick")},
		},
	},
	["prepare.btnCancle"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["prepare.btnSave.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
}

function CrossCraftEmbattleView:onCreate()
	self.node = self:getResourceNode()
	widget.addAnimationByKey(self.node, "kuafushiying/bj.skel", "effect", "effect_loop", 0)
		:scale(2)
		:alignCenter(display.sizeInView)
	self.topuiView = gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.crossCraftMyTeam, subTitle = "MY TEAM"})
	self:enableSchedule()
	self:initModel()
	self:initUpPanel()
	self:initBottomList()

	self.showDownPanel = idler.new()
	idlereasy.when(self.showDownPanel, function(_, showDownPanel)
		self:onBoardChange(showDownPanel)
		if self.battleCardsObj then
			self.battleCardsRect = {}
			for i = 1, NEED_CARDS do
				local item = self.battleCardsObj[i]
				local rect = item:box()
				local pos = item:getParent():convertToWorldSpace(cc.p(rect.x, rect.y))
				rect.x, rect.y = pos.x, pos.y
				self.battleCardsRect[i] = rect
			end
		end
	end, true)
	local isRoundChange = false
	idlereasy.when(self.round, function(_, round)
		if isRoundChange and (round == "prepare" or string.find(round, "_lock$")) then
			--下一轮开始时，重置阵容
			self.ignoreCurMovingItem = true
			self:deleteMovingItem()

			if self:isCardChanged() then
				local originBattleCards = gGameModel.cross_craft:read("cards")
				self.battleCards = table.deepcopy(originBattleCards, true)
				self.clientBattleCards:set(self.battleCards)
				gGameUI:showTip(gLanguageCsv.crossCraftEmbattleBattleStart)
			end
		else
			isRoundChange = true
		end

		-- 底栏状态
		if round == "signup" then
			self.showDownPanel:set(true)
		else
			self.showDownPanel:set(false)
		end

		-- 倒计时状态
		self:setCountdownState(round)

		-- 设置标题状态
		self:setTileState(round)

		for i = 1, 4 do
			self:refreshUpPanelResult(i)
			self:refreshUpPanelTitle(i)
		end

		for idx = 1, NEED_CARDS do
			self:refreshBattleSprite(idx)
		end
		if round == "closed" then
			gGameUI:showTip(gLanguageCsv.crossCraftOver)
			performWithDelay(self, function()
				ViewBase.onClose(self)
			end, 0)
			return
		end
	end)

	idlereasy.when(self.clientBattleCards, function (_, battle)
		self.downNum:text(string.format("%d/%d", self.clientBattleCards:size(), NEED_CARDS))
	end)
end

function CrossCraftEmbattleView:initModel()
	self.round = gGameModel.cross_craft:getIdler("round")
	self.allCardDatas = idlers.newWithMap({})
	local originBattleCards = gGameModel.cross_craft:read("cards")
	-- 修改都是本地行为，最后保存是和原始数据做比较
	self.clientBattleCards =  idlertable.new(table.deepcopy(originBattleCards,true))
	self.selectIndex = idler.new(0)
end

-- 关闭前判断阵容是否变动，保存
function CrossCraftEmbattleView:onClose()
	if self:isCardChanged() then
		gGameUI:showDialog({
			cb = function()
				self:onSaveClick()
			end,
			cancelCb = function()
				ViewBase.onClose(self)
			end,
			btnType = 2,
			content = gLanguageCsv.isSaveCurBattle,
			clearFast = true,
		})
	else
		ViewBase.onClose(self)
	end
end

-- 面板状态变动
function CrossCraftEmbattleView:onBoardChange(showDownPanel)
	if showDownPanel then
		self.upPanel:y(676 + 140)
		self.preparePanel:hide()
		self.downPanel:show()
		local originBattleCards = gGameModel.cross_craft:read("cards")
		local cards = gGameModel.role:read("cards")
		local hash = itertools.map(originBattleCards, function(k, v) return v, k end)
		local all = {}
		local oneKeyAllCards = {}
		for _, dbid in ipairs(cards) do
			local card = gGameModel.cards:find(dbid)
			local cardDatas = card:read("card_id", "skin_id","fighting_point", "level", "star", "advance", "created_time")
			local cardCfg = csv.cards[cardDatas.card_id]
			local unitCfg = csv.unit[cardCfg.unitID]
			local unit_id = dataEasy.getUnitId(cardDatas.card_id, cardDatas.skin_id)
			all[dbid] = {
				dbid = dbid,
				unit_id = unit_id,
				card_id = cardDatas.card_id,
				fighting_point = cardDatas.fighting_point,
				level = cardDatas.level,
				star = cardDatas.star,
				created_time = cardDatas.created_time,
				advance = cardDatas.advance,
				rarity = unitCfg.rarity,
				attr1 = unitCfg.natureType,
				attr2 = unitCfg.natureType2,
				battle = hash[dbid] and 1 or 0,
				markId = cardCfg.cardMarkID,
				atkType = cardCfg.atkType,
			}
			table.insert(oneKeyAllCards, all[dbid])
		end
		self.allCardDatas:update(all)

		-- 保存一键上阵的卡牌信息
		table.sort(oneKeyAllCards, function(a, b)
			if a.fighting_point ~= b.fighting_point then
				return a.fighting_point > b.fighting_point
			end
			return a.rarity > b.rarity
		end)
		self.oneKeyCards = {}
		local oneKeyHash = {}
		local count = 0
		for _, v in ipairs(oneKeyAllCards) do
			if not oneKeyHash[v.markId] then
				oneKeyHash[v.markId] = true
				table.insert(self.oneKeyCards, v.dbid)
				count = count + 1
				if count == NEED_CARDS then
					break
				end
			end
		end
	else
		self.upPanel:y(676)
		self.preparePanel:show()
		self.downPanel:hide()

		self.allCardDatas:update({})
		-- 报名过后，读服务器数据
		local datas = gGameModel.cross_craft:read("card_attrs")
		self.cardAttrs = {}
		for _, v in pairs(datas) do
			local cardCfg = csv.cards[v.card_id]
			local unitCfg = csv.unit[cardCfg.unitID]
			local unit_id = dataEasy.getUnitId(v.card_id, v.skin_id)
			self.cardAttrs[v.id] = {
				dbid = v.id,
				unit_id = unit_id,
				card_id = v.card_id,
				fighting_point = v.fighting_point,
				level = v.level,
				star = v.star,
				created_time = v.created_time,
				advance = v.advance,
				rarity = unitCfg.rarity,
				attr1 = unitCfg.natureType,
				attr2 = unitCfg.natureType2,
				battle = 1,
				markId = cardCfg.cardMarkID,
				atkType = cardCfg.atkType,
			}
		end
	end
end



function CrossCraftEmbattleView:getCardAttrs(dbid)
	if self.showDownPanel:read() then
		return self.allCardDatas:atproxy(dbid)
	end
	return self.cardAttrs[dbid]
end

-- 设置第idx场的结果状态
function CrossCraftEmbattleView:refreshUpPanelResult(idx)
	local history = gGameModel.cross_craft:read("history")
	local result = CrossCraftView.getArrayRoundResult(idx, self.round:read(), history)
	local node = self.groupItemObj[idx]
	local groupChilds = node:multiget("bg", "result", "state", "title", "backup")
	local scale = matchLanguage({"en"})  and 0.7 or 0.8
	groupChilds.result:hide()
	groupChilds.state:hide()
	node:removeChildByName("stateEffect")
	local x, y = groupChilds.state:xy()
	if result == "inBattle" then
		-- groupChilds.state:texture("city/pvp/craft/myteam/txt_zdz.png"):show()
		widget.addAnimationByKey(node, "kuafushiying/wz.skel", "stateEffect", "effect_zdz_loop", 10)
			:scale(scale)
			:xy(80, 710)

	elseif result == "inPrepare" then
		-- groupChilds.state:texture("city/pvp/craft/myteam/txt_bzz.png"):show()
		widget.addAnimationByKey(node, "kuafushiying/wz.skel", "stateEffect", "effect_bzz_loop", 10)
			:scale(scale)
			:xy(80, 710)

	elseif result == "win" then
		groupChilds.result:texture("city/pvp/craft/icon_win.png"):show()

	elseif result == "fail" then
		groupChilds.result:texture("city/pvp/craft/icon_lose.png"):show()
	end
end

-- 设置第idx场的标题和底板
function CrossCraftEmbattleView:refreshUpPanelTitle(idx)
	local groupChilds = self.groupItemObj[idx]:multiget("bg", "result", "state", "title", "backup")
	groupChilds.title:show()
	groupChilds.backup:hide()
	local history = gGameModel.cross_craft:read("history")
	local res = CrossCraftView.getArrayRoundRes(idx, self.round:read(), history)
	if res then
		groupChilds.title:texture(res):show()
		groupChilds.bg:texture("city/pvp/cross_craft/myteam/box_wddw2.png")
	else
		groupChilds.title:hide()
		groupChilds.backup:show()
		groupChilds.bg:texture("city/pvp/cross_craft/myteam/box_wddw3.png")
	end
end

function CrossCraftEmbattleView:initUpPanel()
	self.upList:setScrollBarEnabled(false)
	self.upGroupItem:get("list"):setScrollBarEnabled(false)
	self.groupItemObj = {}
	self.battleCardsObj = {}
	for i = 1, 4 do
		local groupItem = self.upGroupItem:clone()
		self.upList:pushBackCustomItem(groupItem)
		self.groupItemObj[i] = groupItem
		for j = 1, 3 do
			local idx = j + (i - 1) * 3
			local item = self.upItem:clone()
			item:get("tagIdx"):text(j)
			item:show()
			groupItem:get("list"):pushBackCustomItem(item)
			self.battleCardsObj[idx] = item
			item:onTouch(functools.partial(self.onBattleCardTouch, self, idx))
		end
		groupItem:get("list"):refreshView()
		groupItem:show()
	end
	self.upList:refreshView()
end

-- 底部所有卡牌
function CrossCraftEmbattleView:initBottomList(  )
	self.cardListView = gGameUI:createView("city.card.embattle.embattle_card_list", self.downPanel):init({
		base = self,
		clientBattleCards = self.clientBattleCards,
		battleCardsData = self.battleCardsData,
		deleteMovingItem = self.deleteMovingItem,
		createMovePanel = self.createMovePanel,
		moveMovePanel = self.moveMovePanel,
		isMovePanelExist = self.isMovePanelExist,
		onCardClick = self.onCardClick,
		allCardDatas = self.allCardDatas,
		moveEndMovePanel = self.moveEndMovePanel,
		limtFunc = self.limtFunc,
	}, false)
	self.cardListView:xy(0, -34)
end

function CrossCraftEmbattleView:refreshBattleSprite(idx)
	local dbid = self.clientBattleCards:read()[idx]
	local item = self.battleCardsObj[idx]
	item:removeChildByName("starPanel")
	if not dbid then
		item:get("empty"):show()
		item:get("info"):hide()
		return
	end
	item:get("empty"):hide()
	item:get("info"):show()
	local data = self:getCardAttrs(dbid)
	local childs = item:get("info"):multiget("head", "level", "text", "fightPoint", "attr1", "attr2")
	childs.level:text("Lv" .. data.level)
	childs.fightPoint:text(data.fighting_point)
	adapt.oneLinePos(childs.text, childs.fightPoint, cc.p(5, 0))
	childs.attr1:texture(ui.ATTR_ICON[data.attr1])
	childs.attr2:visible(data.attr2 and true or false)
	if data.attr2 then
		childs.attr2:texture(ui.ATTR_ICON[data.attr2])
	end
	uiEasy.getStarPanel(data.star, {align = "left", interval = -5})
		:scale(0.35)
		:xy(230, 120)
		:addTo(item, 2)
	bind.extend(self, childs.head, {
		class = "card_icon",
		props = {
			unitId = data.unit_id,
			rarity = data.rarity,
			advance = data.advance,
			grayState = self:cardInBattle(idx) and 1 or 0,
			onNode = function(panel)
				panel:xy(-6, -6)
			end,
		},
	})
end

function CrossCraftEmbattleView:onBattleFilter(attr1, attr2, rarity, atkType)
	self.filterCondition:set({attr1 = attr1, attr2 = attr2, rarity = rarity, atkType = atkType}, true)
end

-- 上阵卡牌是否有变动
function CrossCraftEmbattleView:isCardChanged()
	local originBattleCards = gGameModel.cross_craft:read("cards")
	for i = 1, NEED_CARDS do
		if self.clientBattleCards:read()[i] ~= originBattleCards[i] then
			return true
		end
	end
	return false
end

-- 倒计时状态
function CrossCraftEmbattleView:setCountdownState(round)
	self:unSchedule(1)
	if self.upCountdownTip then
		self.upCountdownTip:removeSelf()
		self.upCountdownTip = nil
	end
	self.upCountdown:stopAllActions()
	local inPrepare = false
	local str = gLanguageCsv.crossCraftBattleCountdown
	if string.find(round, "_lock$") then
		str = gLanguageCsv.crossCraftInBattle .. ":"

	elseif string.find(round, "^pre%d") or string.find(round, "^top") or string.find(round, "^final") then
		str = gLanguageCsv.stateReady .. ":"
		inPrepare = true
	end
	self.upText:text(str)
	adapt.oneLineCenterPos(cc.p(self.upPanel:width()/2, 840), {self.upText, self.upCountdown}, cc.p(12, 0))
	local dt = 0
	local function setLabel()
		local dt = CrossCraftView.getNextStateTime(nil, true)
		if round == "signup" then
			dt = CrossCraftView.getNextStateTime("prepare", true)

		elseif round == "halftime" then
			dt = CrossCraftView.getNextStateTime("prepare2", true)
		end
		local t = time.getCutDown(dt)
		self.upCountdown:text(t.short_clock_str)
		if inPrepare and dt <= 10 then
			if not self.upCountdownTip then
				self.upCountdownTip = label.create(gLanguageCsv.crossCraftEmbattleAutoSave, {
					fontPath = "font/youmi1.ttf",
					fontSize = 36,
					color = ui.COLORS.NORMAL.RED,
					effect = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 2}},
				})
				self.upCountdown:runAction(cc.RepeatForever:create(
					cc.Sequence:create(
						cc.ScaleTo:create(0.2, 1),
						cc.DelayTime:create(0.6),
						cc.ScaleTo:create(0.2, 1.3)
					)
				))
				adapt.oneLineCenterPos(cc.p(self.upPanel:width()/2, 840 + 30), {self.upText, self.upCountdown}, cc.p(12, 0))
				self.upCountdownTip:addTo(self.upPanel, 5)
					:xy(self.upPanel:width()/2, 840 - 30)
			end
		end
	end
	setLabel()
	self:schedule(function()
		if dt < 0 then
			return false
		end
		setLabel()
	end, 1, 1, 1)
end

-- 设置标题状态
function CrossCraftEmbattleView:setTileState(round)
	local titleRes = nil
	local roundRes = nil
	if round == "prepare" or string.find(round, "^pre1") then
		titleRes = "txt_yxs"
		roundRes = "txt_1l"

	elseif string.find(round, "^pre2") then
		titleRes = "txt_yxs"
		roundRes = "txt_2l"

	elseif round == "halftime" or round == "prepare2" or string.find(round, "^pre3") then
		titleRes = "txt_yxs"
		roundRes = "txt_3l"

	elseif string.find(round, "^top") then
		titleRes = "txt_jjs"

	elseif string.find(round, "^final") then
		titleRes = "txt_dfs"
	end
	self.prepareTitle:hide()
	if titleRes then
		self.prepareTitle:show():texture("city/pvp/cross_craft/txt/" .. titleRes .. ".png")
	end
	self.prepareRound:hide()
	if roundRes then
		self.prepareRound:show()
		self.prepareRound:get("now"):texture("city/pvp/cross_craft/txt/" .. roundRes .. ".png")
	end
end

function CrossCraftEmbattleView:onOneKeyClick()
	local clientBattleCards = self.clientBattleCards:read()
	if not clientBattleCards then
		return
	end
	if itertools.equal(self.oneKeyCards, clientBattleCards) then
		gGameUI:showTip(gLanguageCsv.embattleNotChange)
		return
	end
	for idx = 1, NEED_CARDS do
		if clientBattleCards[idx] then
			self:getCardAttrs(clientBattleCards[idx]).battle = 0
		end
	end
	self.clientBattleCards:set(clone(self.oneKeyCards))
	for idx = 1, NEED_CARDS do
		self:getCardAttrs(self.clientBattleCards:read()[idx]).battle = 1
		self:refreshBattleSprite(idx)
	end
	gGameUI:showTip(gLanguageCsv.oneKeySuccess)
end

function CrossCraftEmbattleView:onSaveClick(cb)
	if self.clientBattleCards:size()< NEED_CARDS then
		gGameUI:showTip(gLanguageCsv.crossCraftEmbattleNotEnough)
		return
	end
	if not self:isCardChanged() then
		gGameUI:showTip(gLanguageCsv.embattleNotChange)
		return
	end

	if not CrossCraftView.isSigned() then
		gGameApp:requestServer("/game/cross/craft/signup", function()
			ViewBase.onClose(self)
			gGameUI:showTip(gLanguageCsv.signUpSuccess)
		end, self.clientBattleCards:read())
		return
	end
	gGameApp:requestServer("/game/cross/craft/battle/deploy", function()
		ViewBase.onClose(self)
		gGameUI:showTip(gLanguageCsv.battleResetSuccess)
	end, self.clientBattleCards:read())
end

function CrossCraftEmbattleView:onBattleCardTouch(idx, event)
	local dbid = self.clientBattleCards:read()[idx]
	if not self.clientBattleCards:read()[idx] then
		return
	end
	if self:cardInBattle(idx) then
		return
	end
	if event.name == "began" then
		self.touchBeganPos = event
		self.ignoreCurMovingItem = false
		self.hasMovingItem = nil
		self:deleteMovingItem()

	elseif event.name == "moved" then
		if self.ignoreCurMovingItem then
			return
		end

		local deltaX = math.abs(event.x - self.touchBeganPos.x)
		local deltaY = math.abs(event.y - self.touchBeganPos.y)
		if self.hasMovingItem == nil and (deltaX >= ui.TOUCH_MOVED_THRESHOLD or deltaY >= ui.TOUCH_MOVED_THRESHOLD) then
			self.hasMovingItem = true
			local data = self:getCardAttrs(dbid)
			self:createMovePanel(data)
		end
		self:moveMovePanel(event)

	elseif event.name == "ended" or event.name == "cancelled" then
		if self.ignoreCurMovingItem then
			return
		end
		local data = self:getCardAttrs(self.clientBattleCards:read()[idx])
		if self.hasMovingItem == nil then
			self:onCardClick(data, true)
		end
		self.hasMovingItem = nil
		if self:deleteMovingItem() then
			if event.y < 340 then
				-- 下阵
				self:onCardClick(data, true)
			else
				local targetIdx = self:whichEmbattleTargetPos(event)
				if targetIdx and targetIdx ~= idx then
					self:onCardMove(data, targetIdx, true)
					audio.playEffectWithWeekBGM("formation.mp3")
				end
			end
		end
	end
end

function CrossCraftEmbattleView:deleteMovingItem()
	self.selectIndex:set(0)
	if self.movePanel then
		self.movePanel:removeSelf()
		self.movePanel = nil
		return true
	end
end

function CrossCraftEmbattleView:createMovePanel(data)
	if self.movePanel then
		self.movePanel:removeSelf()
	end
	local movePanel = self.item:clone():addTo(self:getResourceNode(), 1000)
	bind.extend(self, movePanel, {
		class = "card_icon",
		props = {
			unitId = data.unit_id,
			advance = data.advance,
			rarity = data.rarity,
			star = data.star,
			levelProps = {
				data = data.level,
			},
			onNode = function(panel)
				panel:xy(-2, -2)
			end,
		}
	})
	movePanel:show()
	movePanel:get("txt"):hide()
	self.movePanel = movePanel
	return movePanel
end

function CrossCraftEmbattleView:moveMovePanel(event)
	if self.movePanel then
		self.movePanel:xy(event)
		self.selectIndex:set(self:whichEmbattleTargetPos(event))
	end
end

function CrossCraftEmbattleView:isMovePanelExist()
	return self.movePanel ~= nil
end

function CrossCraftEmbattleView:moveEndMovePanel(data)
	if not self.movePanel then
		return
	end
	local index = self.selectIndex:read()
	self:onCardMove(data, index, true)
	self:deleteMovingItem()
end

-- 点击卡牌，上阵或下阵
function CrossCraftEmbattleView:onCardClick(data, isShowTip)
	-- 若下边栏隐藏，则忽略进行点击操作
	if not self.showDownPanel:read() then
		return
	end
	local tip
	local dbid = data.dbid
	-- 在阵容上
	if data.battle == 1 then
		local idx = self:getIdxByDbId(dbid)
		if not self:cardInBattle(idx) then
			self:downBattle(dbid, idx)
			tip = gLanguageCsv.downToEmbattle
		else
			tip = gLanguageCsv.crossCraftEmbattleInBattle
		end
	else
		local idx = self:getIdxByDbId()
		if not self:cardInBattle(idx) then
			if self.clientBattleCards:size() == NEED_CARDS then
				tip = gLanguageCsv.battleCardCountEnough

			elseif self:hasSameMarkIDCard(data) then
				tip = gLanguageCsv.alreadyHaveSameSprite
			else
				self:upCard(dbid, idx)
				tip = gLanguageCsv.addToEmbattle
			end
		else
			tip = gLanguageCsv.crossCraftEmbattleInBattle
		end
	end
	if isShowTip and tip then
		gGameUI:showTip(tip)
	end
end

-- data 数据移动到 targetIdx 位置上，targetIdx nil 为点击
function CrossCraftEmbattleView:onCardMove(data, targetIdx, isShowTip)
	local tip
	local dbid = data.dbid
	local idx = self:getIdxByDbId(dbid)
	local targetData
	local targetDbid = self.clientBattleCards:read()[targetIdx]
	-- 有战斗中的无法交换
	if self:cardInBattle(idx) or self:cardInBattle(targetIdx) then
		tip = gLanguageCsv.crossCraftEmbattleInBattle
	elseif not targetIdx then
		self:onCardClick(data, isShowTip)
	else
		-- 在阵容上
		if data.battle == 1 then
			if targetDbid then
				-- 到阵容已有对象上，互换，不提示
			else
				-- 到阵容空位置，移动
				-- tip = gLanguageCsv.addToEmbattle
			end

			self.clientBattleCards:modify(function(oldval)
				oldval[idx], oldval[targetIdx] = oldval[targetIdx], oldval[idx]
				return true, oldval
			end, true)

			self:refreshBattleSprite(idx)
			self:refreshBattleSprite(targetIdx)
		else
			local commonIdx = self:hasSameMarkIDCard(data)
			if commonIdx and commonIdx ~= targetIdx then
				tip = gLanguageCsv.alreadyHaveSameSprite
			else
				if targetDbid then
					-- 到阵容已有对象上，阵容上的下阵，拖动对象上阵
					self:getCardAttrs(targetDbid).battle = 0
				else
					-- 到阵容空位置，上阵
				end
				self:upCard(dbid, targetIdx)
			end
		end
	end

	if isShowTip and tip then
		gGameUI:showTip(tip)
	end
end

-- pos在阵容上目标格子里，返回格子下标
function CrossCraftEmbattleView:whichEmbattleTargetPos(pos)
	for i = 1, NEED_CARDS do
		local rect = self.battleCardsRect[i]
		if cc.rectContainsPoint(rect, pos) then
			return i
		end
	end
end

function CrossCraftEmbattleView:getIdxByDbId(dbid)
	for i = 1, NEED_CARDS do
		if self.clientBattleCards:read()[i] == dbid then
			return i
		end
	end
end

function CrossCraftEmbattleView:hasSameMarkIDCard(data)
	for i = 1, NEED_CARDS do
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

-- 下阵
function CrossCraftEmbattleView:downBattle(dbid, idx)
	self:getCardAttrs(dbid).battle = 0
	self.clientBattleCards:modify(function(oldval)
		oldval[idx] = nil
		return true, oldval
	end, true)
	self:refreshBattleSprite(idx)
end

-- 上阵
function CrossCraftEmbattleView:upCard(dbid, idx)
	self.clientBattleCards:modify(function(oldval)
		oldval[idx] = dbid
		self:getCardAttrs(dbid).battle = 1
		return true, oldval
	end, true)
	self:refreshBattleSprite(idx)
end

-- 是否可以进行操作卡牌，在战斗中无法操作
function CrossCraftEmbattleView:cardInBattle(idx)
	if idx == nil then
		return false
	end
	local round = self.round:read()
	local roundIdx = CrossCraftView.getArrayRoundIdx(round)
	-- 非锁定状态该列可操作
	if not string.find(round, "_lock$") then
		roundIdx = roundIdx - 1
	end
	return idx <= roundIdx * 3
end

-- 卡牌过滤 待继承
function CrossCraftEmbattleView:limtFunc(dbid, card_id,skin_id, fighting_point, level, star, advance, created_time, nature_choose, inBattle)
	local cardCsv = csv.cards[card_id]
	local unitCsv = csv.unit[cardCsv.unitID]
	local unit_id = dataEasy.getUnitId(card_id, skin_id)
	return {
		card_id = card_id,
		unit_id = unit_id,
		rarity = unitCsv.rarity,
		attr1 = unitCsv.natureType,
		attr2 = unitCsv.natureType2,
		fighting_point = fighting_point,
		level = level,
		star = star,
		getTime = created_time,
		dbid = dbid,
		advance = advance,
		battle = inBattle,
		atkType = cardCsv.atkType,
		markId = cardCsv.cardMarkID,
		nature_choose = nature_choose,
	}
end

return CrossCraftEmbattleView