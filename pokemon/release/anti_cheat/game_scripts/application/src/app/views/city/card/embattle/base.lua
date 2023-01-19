

local ViewBase = cc.load("mvc").ViewBase
local CardEmbattleView = class("CardEmbattleView", ViewBase)

local ITEM_SIZES_POS = {
	[1] = {pos = cc.p(0, 50), size = cc.size(450, 250)},
	[2] = {pos = cc.p(0, 20), size = cc.size(500, 250)},
	[3] = {pos = cc.p(0, 20), size = cc.size(500, 250)},
	[4] = {pos = cc.p(0, 50), size = cc.size(450, 250)},
	[5] = {pos = cc.p(0, 20), size = cc.size(500, 250)},
	[6] = {pos = cc.p(0, 20), size = cc.size(500, 250)},
}
local ZORDER = {2, 4, 6, 1, 3, 5}

local FROM_TABLE_FUNC = {
	[game.EMBATTLE_FROM_TABLE.default] = {
		initModelFunc = function(self)
			return gGameModel.role:getIdler("battle_cards")
		end,
		getSendRequest = function(self)
			-- 空阵容返回直接关闭界面
			if self.clientBattleCards:size() == 0 then
				return
			end
			return gGameApp:requestServerCustom("/game/battle/card"):params(self.clientBattleCards)
		end,
	},
	[game.EMBATTLE_FROM_TABLE.arena] = {
		initModelFunc = function(self)
			local battleCards = idlertable.new({})
			idlereasy.when(gGameModel.arena:getIdler("record"), function (_, record)
				local battleCard = {}
				local cards = self.fightCb and record.cards or record.defence_cards
				battleCards:set(cards)
			end)
			return battleCards
		end,
		getSendRequest = function(self)
			if self.fightCb then
				return gGameApp:requestServerCustom("/game/pw/battle/deploy"):params(self.clientBattleCards)
			else
				return gGameApp:requestServerCustom("/game/pw/battle/deploy"):params(nil, self.clientBattleCards)
			end
		end,
	},
	[game.EMBATTLE_FROM_TABLE.huodong] = {
		initModelFunc = function(self)
			local battleCards = idlertable.new({})
			idlereasy.when(gGameModel.role:getIdler("huodong_cards"), function (_, huodong_cards)
				if not huodong_cards[self.fromId] then
					-- 如果阵容空，则上阵主阵容
					local originBattleCards = gGameModel.role:read("battle_cards")
					local cardsTb = {}
					for k, dbid in pairs(originBattleCards) do
						local card = gGameModel.cards:find(dbid)
						if card then
							local cardDatas = card:read("card_id", "skin_id","fighting_point", "level", "star", "advance", "created_time")
							local rTb = self:limtFunc(dbid, cardDatas.card_id,cardDatas.skin_id, cardDatas.fighting_point, cardDatas.level, cardDatas.star, cardDatas.advance, cardDatas.created_time, 1)
							if rTb then
								cardsTb[k] = dbid		-- 就算是默认阵容 也要求上阵卡牌符合本次阵容的限制
							end
						end
					end
					battleCards:set(cardsTb)
				else
					battleCards:set(huodong_cards[self.fromId])
				end
			end)
			return battleCards
		end,
		getSendRequest = function(self)
			return gGameApp:requestServerCustom("/game/huodong/card"):params(self.fromId, self.clientBattleCards)
		end,
	},
	[game.EMBATTLE_FROM_TABLE.input] = {
		initModelFunc = function(self)
			return self.inputCards
		end,
		getSendRequest = function(self)
			-- do nothing
		end
	},
	[game.EMBATTLE_FROM_TABLE.gymChallenge] = {
		initModelFunc = function(self)
			local gymbattleCards = userDefault.getForeverLocalKey("gym_emabttle"..self.gymId, {})
			local function checkError()
				local hash = {}
				for _, id in pairs(gymbattleCards) do
					if hash[id] then
						return true
					end
					hash[id] = true
				end
				return false
			end
			if itertools.size(gymbattleCards) == 0 or checkError() then
				--没有缓存则取主场景布阵
				local cardDatas = gGameModel.role:read("battle_cards")
				return idlertable.new(table.shallowcopy(cardDatas))
			else
				local myCards = gGameModel.role:read("cards")--判断自己是否有这张卡 以防卡片被分解
				local cardDatas = {}
				local hash = itertools.map(myCards, function(k, v) return v, k end)
				for k, hexdbid in pairs(gymbattleCards) do
					local dbid = stringz.hextobin(hexdbid)
					if hash[dbid] then
						cardDatas[k] = dbid
					end
				end
				return idlertable.new(cardDatas)
			end
			return battleCards
		end,
		getSendRequest = function(self)
			-- do nothing
		end
	},
	[game.EMBATTLE_FROM_TABLE.onekey] = {
		initModelFunc = function(self)
			return idlertable.new({})
		end,
		getSendRequest = function(self)
			-- do nothing
		end
	},
	[game.EMBATTLE_FROM_TABLE.onlineFight] = {
		initModelFunc = function(self)
			return gGameModel.cross_online_fight:getIdler("cards")
		end,
		getSendRequest = function(self)
			return gGameApp:requestServerCustom("/game/cross/online/deploy"):params(self.clientBattleCards, 1)
		end,
	},
	[game.EMBATTLE_FROM_TABLE.huodongBoss] = {
		initModelFunc = function(self)
			local huodongBossBattleCards = userDefault.getForeverLocalKey("huodongboss_emabttle", {})
			if huodongBossBattleCards == nil or itertools.size(huodongBossBattleCards) == 0 then
				--没有缓存则取主场景布阵
				local cardDatas = gGameModel.role:read("battle_cards")
				return idlertable.new(table.shallowcopy(cardDatas))
			else
				local myCards = gGameModel.role:read("cards")--判断自己是否有这张卡 以防卡片被分解
				local cardDatas = {}
				local hash = itertools.map(myCards, function(k, v) return v, k end)
				for k, hexdbid in pairs(huodongBossBattleCards) do
					local dbid = stringz.hextobin(hexdbid)
					if hash[dbid] then
						cardDatas[k] = dbid
					end
				end
				return idlertable.new(cardDatas)
			end
		end,
		getSendRequest = function(self)
			-- do nothing
		end
	},
	[game.EMBATTLE_FROM_TABLE.ready] = {
		initModelFunc = function(self)
			return self.inputCards
		end,
		getSendRequest = function(self)
			-- do nothing
		end
	},
	[game.EMBATTLE_FROM_TABLE.hunting] = {
		initModelFunc = function(self)
			local battleCards = gGameModel.hunting:read("hunting_route")[self.route].cards or {}
			local cardStates = gGameModel.hunting:read("hunting_route")[self.route].card_states or {}
			if itertools.size(cardStates) == 0 then
				--没有缓存则取主场景布阵
				local cardDatas = table.deepcopy(gGameModel.role:read("battle_cards"), true)
				for k, dbid in pairs(cardDatas) do
					local card = gGameModel.cards:find(dbid)
					if card and card:read("level") < 10 then
						cardDatas[k] = nil
					end
				end
				return idlertable.new(table.shallowcopy(cardDatas))
			else
				local myCards = gGameModel.role:read("cards")--判断自己是否有这张卡 以防卡片被分解
				local cardDatas = {}
				local hash = itertools.map(myCards, function(k, v) return v, k end)
				for k, dbid in pairs(battleCards) do
					if hash[dbid] then
						cardDatas[k] = dbid
					end
				end
				return idlertable.new(cardDatas)
			end
		end,
		getSendRequest = function(self)
			local node = gGameModel.hunting:read("hunting_route")[self.route].node or 1
			return gGameApp:requestServerCustom("/game/hunting/battle/deploy"):params(self.route, node, self.clientBattleCards)
		end
	},
}

local function getFuncFormTableResult(self, key, ...)
	local tb = FROM_TABLE_FUNC[self.from]
	local defaultTb = FROM_TABLE_FUNC[game.EMBATTLE_FROM_TABLE.default]
	local func = tb[key] or defaultTb[key]
	return func(self, ...)
end

CardEmbattleView.RESOURCE_FILENAME = "card_embattle.json"
CardEmbattleView.RESOURCE_BINDING = {
	["btnGHimg"] = {
		varname = "btnGHimg",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onTeamBuffClick")}
		}
	},
	["battlePanel"] = "battlePanel",
	["spritePanel"] = "spriteItem",
	["dailyGateTipsPos"] = "dailyGateTipsPos",
	["btnJump"] = {
		varname = "btnJump",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("cardBagBtn")}
		},
	},

	["textNotRole"] = "emptyTxt",
	["btnChallenge"] = {
		varname = "btnChallenge",
		binds = {
			event = "touch",
			clicksafe = true,
			methods = {ended = bindHelper.self("fightBtn")}
		},
	},
	["fightNote"] = "fightNote",
	["fightNote.textFightPoint"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("fightSumNum"),
		},
	},
	["ahead.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["back.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["btnJump.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["btnChallenge.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["rightDown"] = "rightDown",
	["rightDown.btnOneKeySet"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("oneKeyEmbattleBtn")}
		},
	},
	["rightDown.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("battleNum"),
		},
	},
	["rightDown.btnOneKeySet.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["textLimit"] = "textLimit",
	["bottomMask"] = "bottomMask",
	["bottomPanel"] = "bottomPanel",
	["btnReady"] = {
		varname = "btnReady",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("oneReadyBtn")}
		},
	},
	["btnReady.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["rightDown.btnSaveReady"] = {
		varname = "btnSaveReady",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("oneSaveReadyBtn")}
		},
	},
	["rightDown.btnSaveReady.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
}

-- @params: {from, [fromId], [limitInfo], [checkBattleArr], startCb, fightCb}
-- from: default(nil), arena, huodong
-- checkBattleArr: 检测阵容是否合理（保存阵容前做的操作）
function CardEmbattleView:onCreate(params)
	params = params or {}
	self.spriteItem:get("attrBg"):hide()
	self:initDefine()
	self.btnJump:z(5)
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose", true)})
		:init({title = params.readyIdx and gLanguageCsv.presetFormation or gLanguageCsv.formation, subTitle = "FORMATION"})

	self:initParams(params)
	self:initModel(params)
	self:initReadTeam(params)
	self:checkTeamBuffOpen()

	self:initHeroSprite()
	self:initBottomList()
	self:initRoundUIPanel()
	if self.startCb then
		local battleCards = self.startCb(self)
		if battleCards then
			self.clientBattleCards:set(battleCards)
		end
	end
end

function CardEmbattleView:initDefine()
	self.embattleMax = 6 --最大可上阵数
	self.panelNum = 6    --布阵底座数量
end

function CardEmbattleView:initParams(params)
	self.route = params.route
	self.inputCards = params.inputCards
	self.sceneType = params.sceneType or -1
	self.from = params.from or game.EMBATTLE_FROM_TABLE.default
	self.fightCb = params.fightCb
	self.fromId = params.fromId
	self.startCb = params.startCb
	self.checkBattleArr = params.checkBattleArr or function()
		return true
	end
end

-- 底部所有卡牌
function CardEmbattleView:initBottomList(  )
	self.cardListView = gGameUI:createView("city.card.embattle.embattle_card_list", self.bottomPanel):init({
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
	}, true)
end

function CardEmbattleView:getCardAttr(cardId, attrString)
	return gGameModel.cards:find(cardId):read(attrString)
end

function CardEmbattleView:getCardAttrIdler(cardId, attrString)
	return gGameModel.cards:find(cardId):getIdler(attrString)
end

function CardEmbattleView:resetBattleCardsCallBack()
	local cardIdlers = {}
	for k, dbid in pairs(self.clientBattleCards:read()) do
		-- 当监听的这条属性变动时 触发布阵中的精灵们UI更新
		table.insert(cardIdlers, self:getCardAttrIdler(dbid, "nature_choose"))
	end
	idlereasy.any(cardIdlers, function( ... )
		self.clientBattleCards:notify()
	end):anonyOnly(self, "BattleCardsChangeCallback")
end

function CardEmbattleView:initModel()
	self.cards = gGameModel.role:getIdler("cards")
	self.allCardDatas = idlers.new({})							--所有卡牌数据
	self.battleCardsData = getFuncFormTableResult(self, "initModelFunc")
	self.clientBattleCards = idlertable.new({})					-- 界面上显示的阵容 {dbid, ...}
	self.fightSumNum = idler.new(0)								-- 总战力
	self.battleNum = idler.new("")
	self.selectIndex = idler.new()
	self.draggingIndex = idler.new(0) -- 正在拖拽的节点的index
	local datas = {}
	local datasCount = 0
	idlereasy.when(self.battleCardsData, function (_, battleCards)
		datas = {}
		datasCount = itertools.size(battleCards)
		-- 形态切换和皮肤变更时，db数据不变，布阵界面需要更新显示
		for i, v in pairs(battleCards) do
			local card = gGameModel.cards:find(v)
			if card then
				local cardData = card:multigetIdler("card_id")
				idlereasy.when(cardData, function(_, card_id)
					datas[i] = true
					if itertools.size(datas) == datasCount then
						-- clientBattleCards 的变更不能直接修改 model battle_cards 的 oldval
						self.clientBattleCards:set(clone(battleCards), true)
						self:resetBattleCardsCallBack()
					end
				end):anonyOnly(self, stringz.bintohex(v))
			end
		end
	end)
end

function CardEmbattleView:getFightSumNum(battle)
	local fightSumNum = 0
	for k,v in pairs(battle) do
		local fightPoint = self:getCardAttr(v, "fighting_point")
		fightSumNum = fightSumNum + fightPoint
	end
	return fightSumNum
end

-- 关闭或跳转前阵容变动检测和保存
function CardEmbattleView:sendRequeat(cb, isClose)
	local equality = itertools.equal(self.battleCardsData:read(), self.clientBattleCards:read())
	if not equality then
		local result = self.checkBattleArr(self.clientBattleCards:read())
		if not result then
			if isClose then
				cb()
			else
				gGameUI:showTip(gLanguageCsv.lineupInconsistency)
			end
			return
		end

		local req = getFuncFormTableResult(self, "getSendRequest")
		if not req then
			return cb()
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

-----------------------------RightDownPanel-----------------------------
-- 边缘UI初始化
function CardEmbattleView:initRoundUIPanel()
	adapt.centerWithScreen("left", "right", nil, {
		{self.fightNote, "pos", "right"},
		{self.btnChallenge, "pos", "right"},
		{self.btnJump, "pos", "right"},
		{self.rightDown, "pos", "right"},
	})

	local showFightBtn = self.fightCb and true or false
	self.rightDown:visible(not showFightBtn)
	self.btnChallenge:visible(showFightBtn)
	self.btnJump:visible(self.from == game.EMBATTLE_FROM_TABLE.default)
end

-- 队伍
function CardEmbattleView:initReadTeam(params)
	self.readyIdx = params.readyIdx
	if self.readyIdx then
		self.btnSaveReady:visible(true)
	end
	local showTeam = params.team and true or false
	local isUnlock = dataEasy.isShow(gUnlockCsv.readyTeam)
	self.btnReady:visible(isUnlock)
	if isUnlock then
		self.btnReady:visible(self.from == game.EMBATTLE_FROM_TABLE.default or self.from == game.EMBATTLE_FROM_TABLE.onlineFight or showTeam)
	end
	uiEasy.updateUnlockRes(gUnlockCsv.readyTeam, self.btnReady, {pos = cc.p(285, 102)})
end

-- 一键布阵的筛选按钮
function CardEmbattleView:embattleBtnFunc(hash, v)
	local cardID = self:getCardAttr(v.dbid, "card_id")
	local cardCsv = csv.cards[cardID]
	return not hash[cardCsv.cardMarkID]
end

-- 一键布阵
function CardEmbattleView:getOneKeyCardDatas()
	local cardDatas = itertools.values(self.allCardDatas)
	table.sort(cardDatas, function (a,b)
		a, b = a:read(), b:read()
		if a.fighting_point == b.fighting_point then
			return a.rarity > b.rarity
		else
			return a.fighting_point > b.fighting_point
		end
	end)
	local hash = {}
	local newBattleCards = {}
	local i = 0
	for _, v in pairs(cardDatas) do
		v = v:read()
		local cardID = self:getCardAttr(v.dbid, "card_id")
		local cardCsv = csv.cards[cardID]
		if self:embattleBtnFunc(hash, v) then
			i = i + 1
			newBattleCards[i] = v.dbid
			hash[cardCsv.cardMarkID] = {dbid = v.dbid, fighting_point = v.fighting_point, rarity = v.rarity}
			if i == self.embattleMax then
				break
			end
		end
	end
	return newBattleCards
end

-- 一键布阵
function CardEmbattleView:oneKeyEmbattleBtn()
	local onekeyDatas = self:getOneKeyCardDatas()
	--更新精灵上阵属性
	for k, dbid in self.clientBattleCards:pairs() do
		self:getCardAttrs(dbid).battle = 0
	end
	for i, dbid in pairs(onekeyDatas) do
		self:getCardAttrs(dbid).battle = self:getBattle(i)
	end
	self.clientBattleCards:set(onekeyDatas)
end

-----------------------------DragItem-----------------------------
-- 给界面上的精灵添加拖拽功能
function CardEmbattleView:initHeroSprite()
	local worldPos = self:convertToWorldSpace(cc.p(self.battlePanel:x(), self.battlePanel:y()))
	self.offsetX = self.battlePanel:x()-worldPos.x
	self.offsetY = self.battlePanel:y()-worldPos.y

	self.heroSprite = {}
	--初始化精灵容器
	for i = 1, self.panelNum do
		local tmpPanel = self.spriteItem:clone():addTo(self.battlePanel, 10 + ZORDER[i], "panel"..i)
		tmpPanel:show()
		tmpPanel:get("imgBg"):hide()
		local posx, posy = self.battlePanel:get("item"..i):xy()
		local box = self.battlePanel:get("item"..i):box()
		box.x = box.x - self.offsetX
		box.y = box.y - self.offsetY
		self.heroSprite[i] = {sprite = tmpPanel, dbid = nil, posx = posx, posy = posy, box = box, idx = i}
	end

	for i = 1, self.panelNum do
		local itemPos = self.battlePanel:get("item"..i, "pos")
		if ITEM_SIZES_POS[i] then
			local size = ITEM_SIZES_POS[i].size
			local pos = ITEM_SIZES_POS[i].pos
			local widthRatio = display.sizeInView.width/display.size.width
			local heightRatio = display.sizeInView.height/display.size.height
			local newSize = cc.size(widthRatio * size.width, heightRatio * size.height)
			local newPos = cc.p(widthRatio * pos.x, heightRatio * pos.y)
			local item = self.battlePanel:get("item"..i)
			itemPos:size(newSize):xy(item:size().width/2 + newPos.x, item:size().height/2 + newPos.y)
		end
		itemPos:onTouch(functools.partial(self.onBattleCardTouch, self, i))
	end


	--上阵下阵操作
	local oldBattleHash = {}
	idlereasy.when(self.clientBattleCards,function (_, battle)
		self:refreshTeamBuff(battle)
		local battleNum = 0
		local equal = true
		for i = 1, self.panelNum do
			local spriteTb = self.heroSprite[i]
			local idx = spriteTb.idx
			spriteTb.sprite:xy(spriteTb.posx, spriteTb.posy):z(10 + ZORDER[i])
			local fightPointText = spriteTb.sprite:get("fightPoint")
			local attrPanel = spriteTb.sprite:get("attrBg")
			attrPanel:hide()
			if battle[i] then
				battleNum = battleNum + 1
				local dbid = battle[i]
				if dbid and self:getCardAttrs(dbid) then
					self:getCardAttrs(dbid).battle = self:getBattle(i)
				end

				local card_id = self:getCardAttr(dbid, "card_id")
				local skin_id = self:getCardAttr(dbid, "skin_id")
				local unitCsv = dataEasy.getUnitCsv(card_id,skin_id)

				local dbdata = {dbid = dbid, card_id = card_id, skin_id = skin_id}

				if not (spriteTb.dbdata and itertools.equal(spriteTb.dbdata, dbdata)) then
					spriteTb.sprite:get("icon"):removeAllChildren()
					local cardSprite = widget.addAnimation(spriteTb.sprite:get("icon"), unitCsv.unitRes, "standby_loop", 11)
						:scale(unitCsv.scale)
						:xy(50,50)
					cardSprite:setSkin(unitCsv.skin)
					spriteTb.dbdata = dbdata
					if self.showItemFightPoint then
						self:showItemFightPoint(fightPointText, unitCsv, dbid)
					end
				end

				if self.buffOpen then
					local flags = self.teamBuffs and self.teamBuffs.flags or {1, 1, 1, 1, 1, 1}
					uiEasy.setTeamBuffItem(spriteTb.sprite, card_id, flags[i])
				end

			elseif spriteTb.dbdata then
				spriteTb.sprite:get("icon"):removeAllChildren()
				spriteTb.dbdata = nil
				fightPointText:hide()
			end
			if not oldBattleHash[battle[i]] and battle[i] then
				equal = false
			end
		end
		if not equal or (itertools.size(oldBattleHash) ~= battleNum) then
			oldBattleHash = itertools.map(battle, function(k, v) return v, k end)
		end
		self.battleNum:set(battleNum.."/"..self.embattleMax)
		self.fightSumNum:set(self:getFightSumNum(battle))
	end)

	idlereasy.when(self.draggingIndex, function (_, index)
		-- index - 1 全透明  0 全不透明
		for i = 1, self.panelNum do
			local heroSprite = self.heroSprite[i].sprite:get("icon"):getChildren()
			if heroSprite[1] then
				heroSprite[1]:setCascadeOpacityEnabled(true)
				if index == 0 then
					heroSprite[1]:opacity(255)
				elseif index == -1 then
					heroSprite[1]:opacity(155)
				elseif index == i then
					heroSprite[1]:opacity(255)
				else
					heroSprite[1]:opacity(155)
				end
			end
		end
	end)
	self:initSelectHalo()
end

function CardEmbattleView:initSelectHalo()
	for i = 1, self.panelNum do
		local panel = self.battlePanel:get("item"..i)
		local size = panel:size()
		local scale = ((i > 3 and i - 3 or i) + 7)/10
		local anchorPoint = panel:anchorPoint()
		local imgSel = widget.addAnimationByKey(panel, "effect/buzhen2.skel", "imgSel", "effect_loop", 2)
			:xy(panel:width() * anchorPoint.x, panel:height() * anchorPoint.y)
			:scale(scale)
			:hide()
	end

	idlereasy.when(self.selectIndex, function (_, selectIndex)
		for i = 1, self.panelNum do
			local panel = self.battlePanel:get("item"..i)
			panel:get("imgSel"):visible(selectIndex == i)
			panel:get("imgBg"):visible(selectIndex ~= i)
		end
	end)
end

function CardEmbattleView:createMovePanel(data)
	if self.movePanel then
		self.movePanel:removeSelf()
	end
	local unitCsv = csv.unit[data.unit_id]
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

function CardEmbattleView:deleteMovingItem()
	self.selectIndex:set(0)
	if self.movePanel then
		self.movePanel:removeSelf()
		self.movePanel = nil
	end
	self.draggingIndex:set(0)
end

function CardEmbattleView:moveMovePanel(event)
	if self.movePanel then
		self.movePanel:xy(event)
		self.selectIndex:set(self:whichEmbattleTargetPos(event))
	end
end

function CardEmbattleView:moveEndMovePanel(data)
	if not self.movePanel then
		return
	end
	local index = self.selectIndex:read()
	self:onCardMove(data, index, true)
	self:deleteMovingItem()
end

function CardEmbattleView:isMovePanelExist()
	return self.movePanel ~= nil
end

-- 点击卡牌，上阵或下阵
function CardEmbattleView:onCardClick(data, isShowTip)
	local tip
	local dbid = data.dbid
	local idx = self:getIdxByDbId(dbid)
	-- 在阵容上
	if data.battle > 0 then
		if self:canBattleDown(data.battle) then
			self:downBattle(dbid)
			tip = gLanguageCsv.downToEmbattle
		else
			-- self:refreshBattleSprite(idx)
			tip = gLanguageCsv.battleCannotEmpty
		end
	else
		local idx = self:getIdxByDbId()
		if not self:canBattleUp() then
			tip = gLanguageCsv.battleCardCountEnough
		elseif self:hasSameMarkIDCard(data) then
			tip = gLanguageCsv.alreadyHaveSameSprite
		else
			self:upBattle(dbid, idx)
			tip = gLanguageCsv.addToEmbattle
		end
	end
	if isShowTip and tip then
		gGameUI:showTip(tip)
	end
end

function CardEmbattleView:canBattleDown()
	local leftCount = self.readyIdx and 0 or 1
	return self.clientBattleCards:size() > leftCount
end

function CardEmbattleView:canBattleUp()
	return self.clientBattleCards:size() < self.embattleMax
end

-- data 数据移动到 targetIdx 位置上，targetIdx nil 为点击
function CardEmbattleView:onCardMove(data, targetIdx, isShowTip)
	local tip
	local dbid = data.dbid
	local idx = self:getIdxByDbId(dbid)
	local targetDbid = self.clientBattleCards:read()[targetIdx]
	local targetData= self:getCardAttrs(targetDbid)
	local battle = (idx == nil) and 0 or 1
	if targetIdx then
		if data.battle > 0 then
			-- 在阵容上 互换
			self.clientBattleCards:modify(function(oldval)
				oldval[idx], oldval[targetIdx] = oldval[targetIdx], oldval[idx]
				return true, oldval
			end, true)
		else
			local commonIdx = self:hasSameMarkIDCard(data)
			if commonIdx and commonIdx ~= targetIdx then
				tip = gLanguageCsv.alreadyHaveSameSprite
			else
				if not targetDbid and not self:canBattleUp() then
					--目标位置没有精灵 且上阵精灵已满
					tip = gLanguageCsv.battleCardCountEnough
				else
					self:upBattle(dbid,targetIdx)
					tip = gLanguageCsv.addToEmbattle
				end
			end
		end
	end
	if isShowTip and tip then
		gGameUI:showTip(tip)
	end
end

function CardEmbattleView:onBattleCardTouch(i, event)
	local dbid = self.clientBattleCards:read()[i]
	if not dbid then
		return
	end
	local data = self:getCardAttrs(dbid)
	if event.name == "began" then
		self:createMovePanel(data)
		self.selectIndex:set(i)
		self.heroSprite[i].sprite:hide()
		self.movePanel:xy(event.x, event.y)
	elseif event.name == "moved" then
		self:moveMovePanel(event)
	elseif (event.name == "ended" or event.name == "cancelled") then
		self.heroSprite[i].sprite:show()
		self:deleteMovingItem()
		if event.y < 340 then
			-- 下阵
			self:onCardClick(data, true)
		else
			local targetIdx = self:whichEmbattleTargetPos(event)
			if targetIdx  then
				if targetIdx ~= i then
					self:onCardMove(data, targetIdx, true)
					audio.playEffectWithWeekBGM("formation.mp3")
				else
					self:onCardMove(data, targetIdx, false)
				end
			else
				self:onCardMove(data, i, false)
			end
		end
	end
end

function CardEmbattleView:getIdxByDbId(dbid)
	for i = 1, self.panelNum do
		if self.clientBattleCards:read()[i] == dbid then
			return i
		end
	end
end

function CardEmbattleView:getCardAttrs(dbid)
	return self.allCardDatas:atproxy(dbid)
end

--下阵
function CardEmbattleView:downBattle(dbid)
	self:getCardAttrs(dbid).battle = 0
	local idx = self:getIdxByDbId(dbid)
	self.clientBattleCards:modify(function(oldval)
		oldval[idx] = nil
		return true, oldval
	end, true)
end

-- 上阵
function CardEmbattleView:upBattle(dbid, idx)
	if self.clientBattleCards:read()[idx] then
		self:getCardAttrs(self.clientBattleCards:read()[idx]).battle = 0
	end
	self.clientBattleCards:modify(function(oldval)
		oldval[idx] = dbid
		self:getCardAttrs(dbid).battle = self:getBattle(idx)
		return true, oldval
	end, true)
end

--是否有相同markid的精灵
function CardEmbattleView:hasSameMarkIDCard(data)
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

function CardEmbattleView:whichEmbattleTargetPos(p)
	-- 精灵交互区域可以存在覆盖，从最前面开始
	for i = self.panelNum, 1, -1 do
		local box = self.heroSprite[i].box
		if cc.rectContainsPoint(box, p) then
			return i
		end
	end
end

function CardEmbattleView:checkTeamBuffOpen()
	self.buffOpen = true
	for _, cfg in csvPairs(csv.battle_card_halo) do
		for _, sceneType in csvPairs(cfg.invalidScenes) do
			if sceneType == self.sceneType then
				self.buffOpen = false
				break
			end
		end
		break
	end
	self.btnGHimg:visible(self.buffOpen)
end

-- 根据布阵信息刷新队伍光环效果
function CardEmbattleView:refreshTeamBuff(battleCards)
	if not self.buffOpen then return end
	local attrs = {}
	for i = 1, 6 do
		local dbid = self.clientBattleCards:read()[i]
		local data = self:getCardAttrs(dbid)
		if data then
			local cardCfg = csv.cards[data.card_id]
			local unitCfg = csv.unit[cardCfg.unitID]
			attrs[i] = {unitCfg.natureType, unitCfg.natureType2}
		end
	end
	local result = dataEasy.getTeamBuffBest(attrs)
	self.btnGHimg:texture(result.buf.imgPath)
	self.teamBuffs = result
end

-----------------------------BtnClick------------------------------
function CardEmbattleView:fightBtn()
	local cards = self.clientBattleCards:read()
	if not next(cards) then
		gGameUI:showTip(gLanguageCsv.noSpriteAvailable)
		return
	end
	self:sendRequeat(function()
		self.fightCb(self, self.clientBattleCards)
	end)
end

function CardEmbattleView:onClose(sendRequeat, isTeamSave)
	local function closeCb()
		if sendRequeat == true  then
			self:sendRequeat(functools.partial(ViewBase.onClose, self), true)
		else
			ViewBase.onClose(self)
		end
	end

	if self.readyIdx and isTeamSave ~= true and self:isChangeBattleCards() then
		self:teamNotSave(closeCb)
	else
		closeCb()
	end
end

-- 判断是否有改变阵容
function CardEmbattleView:isChangeBattleCards()
	local haveChange = false
	if self.inputCards then
		if self.inputCards:size() == self.clientBattleCards:size() then
			local inputCards = self.inputCards:read()
			for k, val in pairs(self.clientBattleCards:read()) do
				if inputCards[k] ~= val then
					haveChange = true
				end
			end
		else
			haveChange = true
		end
	end
	return haveChange
end

-- 背包跳转
function CardEmbattleView:cardBagBtn()
	self:sendRequeat(function()
		gGameUI:stackUI("city.card.bag", nil, {full = true})
	end)
end

function CardEmbattleView:onTeamBuffClick()
	if not self.buffOpen then return end
	local teamBuffs = self.teamBuffs and self.teamBuffs.buf.teamBuffs or {}
	gGameUI:stackUI("city.card.embattle.attr_dialog",nil, {}, teamBuffs)
end

-- 卡牌过滤 待继承
function CardEmbattleView:limtFunc(dbid, card_id,skin_id,fighting_point, level, star, advance, created_time, nature_choose,inBattle)
	local cardCsv = csv.cards[card_id]
	local unitCsv = csv.unit[cardCsv.unitID]
	local unitId = dataEasy.getUnitId(card_id, skin_id)
	return {
		card_id = card_id,
		unit_id = unitId,
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

function CardEmbattleView:getBattle(i)
	if i and i~= 0 then
		return math.ceil(i / 6)
	else
		return 0
	end
end

-- 预设队伍
function CardEmbattleView:oneReadyBtn()
	if not dataEasy.isUnlock(gUnlockCsv.readyTeam) then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.readyTeam))
		return
	end
	local function useTeamBattles(battleCards, cb)
		for k, dbid in self.clientBattleCards:pairs() do
			self:getCardAttrs(dbid).battle = 0
		end
		for idx = 1, 6 do
			if battleCards[idx] then
				self:getCardAttrs(battleCards[idx]).battle = 1
			end
		end
		self.clientBattleCards:set(battleCards)
		if cb then
			cb()
		end
	end
	gGameUI:stackUI("city.card.embattle.ready", nil, nil, {sceneType = self.sceneType, cb = useTeamBattles})
end

-- 预设队伍布阵保存
function CardEmbattleView:oneSaveReadyBtn()
	gGameApp:requestServer("/game/ready/card/deploy", function(tb)
		self:onClose(nil, true)
		gGameUI:showTip(gLanguageCsv.positionSave)
		end, self.readyIdx, self.clientBattleCards:read())
end

function CardEmbattleView:teamNotSave(cb)
	gGameUI:showDialog({
		content = gLanguageCsv.teamNotSave,
		btnType = 2,
		cb = function ()
			self:oneSaveReadyBtn()
		end,
		cancelCb = cb,
	})
end

return CardEmbattleView

