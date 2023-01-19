local ViewBase = cc.load("mvc").ViewBase
local CardEmbattleView = require "app.views.city.card.embattle.base"
local CrossAreanEmbattleView = class("CrossAreanEmbattleView", CardEmbattleView)

CrossAreanEmbattleView.RESOURCE_FILENAME = "cross_arena_embattle.json"
CrossAreanEmbattleView.RESOURCE_BINDING = {
	["battlePanel1.fightNote.btnGHimg"] = {
		varname = "btnGHimg1",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onTeamBuffClick1")}
		}
	},
	["battlePanel2.fightNote.btnGHimg"] = {
		varname = "btnGHimg2",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onTeamBuffClick2")}
		}
	},
	["battlePanel1"] = "battlePanel1",
	["battlePanel2"] = "battlePanel2",

	["spritePanel"] = "spriteItem",
	["rightDown"] = "rightDown",
	["rightDown.btnOneKeySet"] = {
		varname = "btnOneKeySet",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("oneKeyEmbattleBtn")}
		},
	},
	["rightDown.btnOneKeySet.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},

	["rightDown.btnChallenge"] = {
		varname = "btnChallenge",
		binds = {
			event = "touch",
			clicksafe = true,
			methods = {ended = bindHelper.self("fightBtn")}
		},
	},
	["rightDown.btnChallenge.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["battlePanel1.ahead.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["battlePanel1.back.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["battlePanel2.ahead.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["battlePanel2.back.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["battlePanel1.imgDuiwu.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["battlePanel2.imgDuiwu.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["rightDown"] = "rightDown",
	["btnChange"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeBattle")}
		},
	},
	["battlePanel1.fightNote.textFightPoint"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("fightSumNum1"),
		},
	},
	["battlePanel2.fightNote.textFightPoint"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("fightSumNum2"),
		},
	},
	["bottomPanel"] = "bottomPanel",
}

function CrossAreanEmbattleView:onCreate(params)
	self:initDefine()
	adapt.centerWithScreen("left", "right", nil, {
		{self.rightDown, "pos", "right"},
	})
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose", true)})
		:init({title = gLanguageCsv.crossArena, subTitle = "WORLD ARENA"})
	self:initModel(params)
	self:initBattlePanel()
	self:initBottomList()
	self:initRoundUIPanel()
	idlereasy.when(self.clientBattleCards, function (_, battle)
		self.fightSumNum1:set(self:getFightSumNum(1))
		self.fightSumNum2:set(self:getFightSumNum(2))
		self:refreshTeamBuff(1)
		self:refreshTeamBuff(2)
		self.rightDown:get("textNum"):text(self.clientBattleCards:size() .."/".. self.embattleMax)
		adapt.oneLineCenterPos(cc.p(163, 152), {self.rightDown:get("textNote"), self.rightDown:get("textNum")}, cc.p(5, 0))

		for i = 1, self.panelNum do
			self:refreshBattleSprite(i)
		end
	end)
end

function CrossAreanEmbattleView:initDefine()
	self.embattleMax = 12--最大可上阵数
	self.panelNum = 12    --布阵底座数量
end

-- 初始化所有cards
function CrossAreanEmbattleView:initAllCards()
	local cards = gGameModel.role:read("cards")
	local hash = itertools.map(self.clientBattleCards:read(), function(k, v) return v, k end)

	local all = {}
	local oneKeyAllCards = {}
	for _, dbid in ipairs(cards) do
		local card = gGameModel.cards:find(dbid)
		local inBattle = self:getBattle(hash[dbid])
		local cardDatas = card:read("card_id", "skin_id", "fighting_point", "level", "star", "advance", "created_time", "nature_choose")
		all[dbid] =  self.limtFunc(self, dbid, cardDatas.card_id,cardDatas.skin_id, cardDatas.fighting_point, cardDatas.level, cardDatas.star, cardDatas.advance, cardDatas.created_time, cardDatas.nature_choose, inBattle)
		if all[dbid] then
			table.insert(oneKeyAllCards, all[dbid])
		end
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
			if count == self.embattleMax then
				break
			end
		end
	end
	--精灵少于6只 把最后一只放到队伍二
	local cardNum = itertools.size(self.oneKeyCards)
	if cardNum <= 6 then
		self.oneKeyCards[7] = clone(self.oneKeyCards[cardNum])
		self.oneKeyCards[cardNum] = nil
	end
end
-- 初始化精灵布阵
function CrossAreanEmbattleView:initBattlePanel()
	self.battleCardsRect = {}
	self.battleCards = {}
	for i = 1, 2 do
		for j = 1, 6 do
			local item = self["battlePanel"..i]:get("item"..j)
			local rect = item:box()
			local pos = item:getParent():convertToWorldSpace(cc.p(rect.x, rect.y))
			rect.x, rect.y = pos.x, pos.y
			local idx = (i - 1) * 6 + j

			self.battleCardsRect[idx] = rect
			self.battleCards[idx] = item
			item:onTouch(functools.partial(self.onBattleCardTouch, self, idx))
		end
	end

	for i = 1, self.panelNum do
		local imgBg = self.battleCards[i]:get("imgBg")
		local imgSel = imgBg:get("imgSel")
		local size = imgBg:size()
		if not imgSel then
			imgSel = widget.addAnimationByKey(imgBg, "effect/buzhen2.skel", "imgSel", "effect_loop", 2)
				:xy(size.width/2, size.height/2 + 15)
		end
	end

	idlereasy.when(self.selectIndex, function (_, selectIndex)
		for i = 1, self.panelNum do
			local imgSel = self.battleCards[i]:get("imgBg.imgSel")
			imgSel:visible(selectIndex == i)
		end
	end)

	self.draggingIndex = idler.new(0) -- 正在拖拽的节点的index
	idlereasy.when(self.draggingIndex, function (_, index)
		-- index - 1 全透明  0 全不透明
		for i = 1, self.panelNum do
			local sprite = self.battleCards[i]:get("sprite")
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
	end)
end
-- 底部所有卡牌
function CrossAreanEmbattleView:initBottomList(  )
	self.cardListView = gGameUI:createView("city.card.embattle.cross_arena_card_list", self.bottomPanel):init({
		base = self,
		clientBattleCards = self.clientBattleCards,
		battleCardsData = self.battleCardsData,
		selectIndex = self.selectIndex,
		deleteMovingItem = self.deleteMovingItem,
		createMovePanel = self.createMovePanel,
		moveMovePanel = self.moveMovePanel,
		isMovePanelExist = self.isMovePanelExist,
		onCardClick = self.onCardClick,
		allCardDatas = self.allCardDatas,
		moveEndMovePanel = self.moveEndMovePanel,
		limtFunc = self.limtFunc,
	}, true)
end

function CrossAreanEmbattleView:getCardAttrIdler(cardId, attrString)
	return gGameModel.cards:find(cardId):getIdler(attrString)
end

-- 获取战斗力
function CrossAreanEmbattleView:getFightSumNum(battle)
	local fightSumNum = 0
	local startIndex = battle == 1 and 1 or 7
	for i = startIndex, startIndex + 5 do
		if self.clientBattleCards:read()[i] then
			fightSumNum = fightSumNum + self:getCardAttrs(self.clientBattleCards:read()[i]).fighting_point
		end
	end
	return fightSumNum
end

function CrossAreanEmbattleView:getCardNum(battle)
	local cardNum = 0
	local startIndex = battle == 1 and 1 or 7
	for i = startIndex, startIndex + 5 do
		if self.clientBattleCards:read()[i] then
			cardNum = cardNum + 1
		end
	end
	return cardNum
end

-- 刷新buf
function CrossAreanEmbattleView:refreshTeamBuff(battle)
	local attrs = {}
	local startIndex = battle == 1 and 1 or 7
	for i = startIndex, startIndex + 5 do
		local data = self:getCardAttrs(self.clientBattleCards:read()[i])
		if data then
			local cardCfg = csv.cards[data.card_id]
			local unitCfg = csv.unit[cardCfg.unitID]
			attrs[i - startIndex + 1] = {unitCfg.natureType, unitCfg.natureType2}
		end
	end
	local result = dataEasy.getTeamBuffBest(attrs)
	self["btnGHimg"..battle]:texture(result.buf.imgPath)
	self["teamBuffs"..battle] = result
end


function CrossAreanEmbattleView:initModel(params)
	self.type = params.type
	self.fightCb = params.fightCb
	self.allCardDatas = idlers.newWithMap({})
	self.selectIndex = idler.new(0)
	local battleCardsData1 = {}
	if self.type == "defence" then
		battleCardsData1 = gGameModel.cross_arena:read("record").defence_cards
	else
		battleCardsData1 = gGameModel.cross_arena:read("record").cards
	end
	local battleCardsData = {}
	for i = 1, 2 do
		for j = 1, 6 do
			battleCardsData[(i -1) * 6 + j] = battleCardsData1[i][j]
		end
	end
	self.battleCardsData = idlertable.new(battleCardsData)
	self.clientBattleCards =  idlertable.new(battleCardsData)
	self.cards = gGameModel.role:getIdler("cards")
	self.fightSumNum1 = idler.new(0)
	self.fightSumNum2 = idler.new(0)
	self:initAllCards()
end
-----------------------------RightDownPanel-----------------------------
-- 边缘UI初始化
function CrossAreanEmbattleView:initRoundUIPanel()
	self.btnOneKeySet:visible(self.type == "defence")
	self.btnChallenge:visible(self.type ~= "defence")
end

-- 一键布阵
function CrossAreanEmbattleView:oneKeyEmbattleBtn()
	if not self.clientBattleCards:read() then
		return
	end
	if itertools.equal(self.oneKeyCards, self.clientBattleCards:read()) then
		gGameUI:showTip(gLanguageCsv.embattleNotChange)
		return
	end
	for idx = 1, self.panelNum do
		if self.clientBattleCards:read()[idx] then
			self:getCardAttrs(self.clientBattleCards:read()[idx]).battle = 0
		end
	end
	self.clientBattleCards:set(clone(self.oneKeyCards), true)
	for idx = 1, self.panelNum do
		local dbid = self.clientBattleCards:read()[idx]
		if dbid then
			self:getCardAttrs(dbid).battle = self:getBattle(idx)
		end
	end
	gGameUI:showTip(gLanguageCsv.oneKeySuccess)
end

-- 交换阵容
function CrossAreanEmbattleView:onChangeBattle()
	self.clientBattleCards:modify(function(oldval)
		for i = 1, 6 do
			oldval[i], oldval[i + 6] = oldval[i + 6], oldval[i]
		end
		for idx = 1, self.panelNum do
			local dbid = self.clientBattleCards:read()[idx]
			if self:getCardAttrs(dbid) then
				self:getCardAttrs(dbid).battle = self:getBattle(idx)
			end
		end
	end, true)
end

-- 挑战
function CrossAreanEmbattleView:fightBtn()
	local cards = self.clientBattleCards:read()
	if not next(cards) then
		gGameUI:showTip(gLanguageCsv.noSpriteAvailable)
		return
	end
	self:sendRequeat(function()
		self.fightCb(self, self.clientBattleCards)
	end)
end

-- 光环
function CrossAreanEmbattleView:onTeamBuffClick1()
	local teamBuffs = self.teamBuffs1 and self.teamBuffs1.buf.teamBuffs or {}
	gGameUI:stackUI("city.card.embattle.attr_dialog",nil, {}, teamBuffs)
end
-- 光环
function CrossAreanEmbattleView:onTeamBuffClick2()
	local teamBuffs = self.teamBuffs2 and self.teamBuffs2.buf.teamBuffs or {}
	gGameUI:stackUI("city.card.embattle.attr_dialog",nil, {}, teamBuffs)
end
-----------------------------DragItem-----------------------------

function CrossAreanEmbattleView:refreshBattleSprite(index)
	local panel = self.battleCards[index]

	local data = self:getCardAttrs(self.clientBattleCards:read()[index])
	if not data then
		if panel:getChildByName("sprite") then
			panel:getChildByName("sprite"):hide()
		end
		panel:get("attrBg"):hide()
		return
	end
	local spriteId = data.card_id
	local unitCsv = csv.unit[data.unit_id]
	local imgBg = self.battleCards[index]:get("imgBg")
	if panel.spriteId == spriteId and panel:getChildByName("sprite") then
		panel:getChildByName("sprite"):show()
	else
		panel:removeChildByName("sprite")
		local cardSprite = widget.addAnimationByKey(panel, unitCsv.unitRes, "sprite", "standby_loop", 4)
			:scale(unitCsv.scale * 0.8)
			:xy(imgBg:x(), imgBg:y() + 15)
		cardSprite:setSkin(unitCsv.skin)
		panel.spriteId = spriteId
	end

	local battle = index > 6 and 2 or 1
	local flags = self["teamBuffs"..battle] and self["teamBuffs"..battle].flags or {1, 1, 1, 1, 1, 1}
	local flag = flags[index] or flags[index - 6]
	uiEasy.setTeamBuffItem(panel, spriteId, flag)
end

function CrossAreanEmbattleView:onBattleCardTouch(idx, event)
	if not self.clientBattleCards:read()[idx] then
		return
	end
	local data = self:getCardAttrs(self.clientBattleCards:read()[idx])
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
		if event.y < 340 then
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
function CrossAreanEmbattleView:onCardMove(data, targetIdx, isShowTip)
	local tip
	local dbid = data.dbid
	local idx = self:getIdxByDbId(dbid)
	local targetDbid = self.clientBattleCards:read()[targetIdx]
	local targetData= self:getCardAttrs(targetDbid)

	local battle = self:getBattle(idx)
	if not targetIdx then
		-- self:onCardClick(data, isShowTip)
	else
		local targetBattle = self:getBattle(targetIdx)
		if data.battle > 0 then
			if targetBattle ~= data.battle and (self:getCardNum(data.battle) == 1 and targetDbid == nil) then
				tip = gLanguageCsv.battleNumberNo
				self:refreshBattleSprite(idx)
			else
				-- 在阵容上 互换
				if self:getCardAttrs(targetDbid) then
					self:getCardAttrs(targetDbid).battle = self:getBattle(idx)
				end
				if self:getCardAttrs(dbid) then
					self:getCardAttrs(dbid).battle = self:getBattle(targetIdx)
				end
				self.clientBattleCards:modify(function(oldval)
					oldval[idx], oldval[targetIdx] = oldval[targetIdx], oldval[idx]
					return true, oldval
				end, true)
			end
		else
			local commonIdx = self:hasSameMarkIDCard(data)
			if commonIdx and commonIdx ~= targetIdx then
				tip = gLanguageCsv.alreadyHaveSameSprite
			else
				if targetDbid then-- 到阵容已有对象上，阵容上的下阵，拖动对象上阵
					self:getCardAttrs(targetDbid).battle = 0
				end
				self:getCardAttrs(dbid).battle = self:getBattle(targetIdx)
				self.clientBattleCards:modify(function(oldval)
					oldval[targetIdx] = dbid
					return true, oldval
				end, true)
				tip = gLanguageCsv.addToEmbattle
			end
		end
	end
	if isShowTip and tip then
		gGameUI:showTip(tip)
	end
end

function CrossAreanEmbattleView:canBattleDown(battle)
	return self:getCardNum(battle) > 1
end

-- 下阵
function CrossAreanEmbattleView:downBattle(dbid)
	self.allCardDatas:atproxy(dbid).battle = 0
	local idx = self:getIdxByDbId(dbid)
	self.clientBattleCards:modify(function(oldval)
		oldval[idx] = nil
		return true, oldval
	end, true)
end

-- 上阵
function CrossAreanEmbattleView:upBattle(dbid, idx)
	self:getCardAttrs(dbid).battle = self:getBattle(idx)
	self.clientBattleCards:modify(function(oldval)
		oldval[idx] = dbid
		return true, oldval
	end, true)
end


--重载
function CrossAreanEmbattleView:whichEmbattleTargetPos(pos)
	-- 精灵交互区域可以存在覆盖，从最前面开始
	for i = self.panelNum, 1, -1 do
		local rect = self.battleCardsRect[i]
		if cc.rectContainsPoint(rect, pos) then
			return i
		end
	end
end

--重载 是否有相同markid的精灵
function CrossAreanEmbattleView:hasSameMarkIDCard(data)
	for i = 1, self.panelNum do
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
-- 关闭或跳转前阵容变动检测和保存
function CrossAreanEmbattleView:sendRequeat(cb, isClose)
	local equality = itertools.equal(self.battleCardsData:read(), self.clientBattleCards:read())
	if not equality then
		local req = nil
		if self.type == "defence" then
			req = gGameApp:requestServerCustom("/game/cross/arena/battle/deploy"):params(nil, self.clientBattleCards:read())
		else
			req = gGameApp:requestServerCustom("/game/cross/arena/battle/deploy"):params(self.clientBattleCards:read(), nil)
		end
		if isClose then
			req:onBeforeSync(cb):doit()
		else
			req:doit(cb)
		end
	else
		cb()
	end
end

function CrossAreanEmbattleView:getBattle(i)
	if i and i~= 0 then
		return i <= 6 and 1 or 2
	else
		return 0
	end
end

return CrossAreanEmbattleView