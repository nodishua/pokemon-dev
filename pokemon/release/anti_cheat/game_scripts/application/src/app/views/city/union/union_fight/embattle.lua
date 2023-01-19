--公会战布阵界面
local ViewBase = cc.load("mvc").ViewBase
local EmbattleView = class("EmbattleView", ViewBase)
local NUM_MAX = 6
--做多上阵12张卡牌
local CARD_MAX = 12
local roundQuotaSize = {{1,2,3,4,5,6},{1,2,3,4,5,6}}
--不同轮次上阵的限额
local roundQuota = {6, 6, 6, 8, 12}

--战斗力字体适配
--# node1是左边描述 node2是战斗力
local fightingfontAdaptiveFunc = function(node1, node2)
	local nodeX1 = node1:x()
	local nodeX2 = node2:x()
	local nodeW1 = node1:width()
	local nodeW2 = node2:width()
	node1:x(nodeX1-(nodeW2 - nodeW1)/2+30)
	node2:x(nodeX2-(nodeW2 - nodeW1)/2+40)
end

local panelPos = {[1] = {cc.p(630,425),cc.p(1350,425)}, [2] = {cc.p(570,425),cc.p(1210,425),cc.p(1850,425)}}
EmbattleView.RESOURCE_FILENAME = "union_embattle.json"
EmbattleView.RESOURCE_BINDING = {
	["btnOneKeySet"] = {
		varname = "rightDown",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("oneKeyEmbattleBtn")}
		},
	},
	["bottomPanel"] = "bottomPanel",
	["upPosition"] = "upPosition",
	["leftitem"] = "leftitem",
	["leftList"] = {
		varname = "leftList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("leftData"),
				item = bindHelper.self("leftitem"),
				padding = 4,
				onItem = function(list, node, k, v)
					local childs = node:multiget("name", "btn")
					if v.select then
						childs.btn:visible(true)
						childs.btn:get("title"):text(v.text)
						text.addEffect(childs.btn:get("title"), {outline={color=(cc.c4b(59, 51, 59, 255))}})
					else
						childs.btn:visible(false)
					end
					childs.name:text(v.text)
					childs.name:setOpacity(178)
					text.addEffect(childs.name, {outline={color=(cc.c4b(255, 252, 237, 255)), size = 2}})
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("clickBtn"),
			},
		},
	},
	["upPosition.icon.title"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.NORMAL.BLACK}}
			},
		}
	},
	["upPosition.icon.title1"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.NORMAL.BLACK}}
			},
		}
	},
	["upPosition.title"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.NORMAL.BLACK}}
			},
		}
	},
	["upPosition.count"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.NORMAL.BLACK}}
			},
		}
	},
	["upPosition.strength"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.NORMAL.BROWN}}
			},
		}
	},
	["upPosition.strengthNum"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.NORMAL.BROWN}}
			},
		}
	},
	["rightPanel.text1"] = {
		varname = "text",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		},
	},
	["rightPanel"] = "rightPanel",
	["rightPanel.item"] = "natureLimitItem",
	["rightPanel.list"] = {
		varname = "natureLimitList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("natureLimitData"),
				item = bindHelper.self("natureLimitItem"),
				onItem = function(list, node, k, v)
					node:texture(ui.ATTR_ICON[v])
				end,
			},
		},
	},
	["movecard"] = "movecard",
	["battlePanel"] = "battlePanel",
	["right"] = "right",
	["title"] = {
		varname = "title",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(133, 82, 15, 255)}},
		},
	},
}

function EmbattleView:onCreate()
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.formation, subTitle = "FORMATION"})

	self.text:getVirtualRenderer():setLineSpacing(-15)
	adapt.setAutoText(self.text, nil, 800)

	self.dbidData = {}

	--类型限制
	self.nature_limit = {}

	self:initModel()
	self:initStartInfo()
	self:updateData()
	self:initHeroSprite()
	self:initBottomList()
	self:initScreenView()

	self.btnTab:addListener(function(val, oldval, idler)
		self.leftData:atproxy(oldval).select = false
		self.leftData:atproxy(val).select = true
	end)

	idlereasy.when(gGameModel.union_fight:getIdler("round"), function(_, unionInfo)
		if self.wday == self.btnState + 1 and (unionInfo == "battle" or unionInfo == "prepare") then
			self.title:visible(true)
			self.title:text(gLanguageCsv.unionfightDeployLimit)
		end
	end)
end

function EmbattleView:initModel()
	self.cards = gGameModel.role:getIdler("cards")
	self.clientBattleCards = idlertable.new({{}, {},{}})					--界面上显示的阵容 {dbid, ...}
	self.battleCardsData = idlertable.new({})
	self.allCardDatas = idlers.new({})							--所有卡牌数据
	self.natureLimitData = idlers.new({})						--上阵卡牌数据

	self.selectIndex = idlertable.new({})

	self.btnTab = idler.new(1)

	self.leftData = idlers.newWithMap({
		{text = gLanguageCsv.firstRound, card_id = 1},
		{text = gLanguageCsv.theSecondRound, card_id = 2},
		{text = gLanguageCsv.thridRound, card_id = 3},
		{text = gLanguageCsv.theFourthRoundOf, card_id =4},
		{text = gLanguageCsv.BattleLine, card_id = 5},
	})
end

function EmbattleView:initStartInfo()

	for k,v in orderCsvPairs(csv.union_fight.nature_limit) do
		self.nature_limit[v.weekDay] = v.natureLimit
	end
	local wday = time.getNowDate().wday
	self.wday = wday == 1 and 7 or wday - 1
	self.unionCombet = self.wday == 7 and true
	self.wday = self.wday == 7 and 2 or self.wday
	self.btnState = self.wday - 1

	self.natureLimitData:update(self.nature_limit[self.wday])
	self.btnTab:set(self.btnState)
end

--卡牌数据
function EmbattleView:updateData()
	local orignBattleCards = gGameModel.union_fight:read("role_info").cards
	local battleCardsTab = {{}, {} ,{}}
	--# self.cardsNumAll为true时，卡牌不足无法上阵
	self.cardsNumAll = false
	local troopNum = self.btnState < 5 and 2 or 3
	for i=1, troopNum do
		if itertools.size(orignBattleCards[self.btnState+1][i]) <= 0 then
			self.cardsNumAll = true
		end
	end
	for k, tab in pairs(orignBattleCards[self.btnState+1]) do
		battleCardsTab[k] = {}
		for k1=1, NUM_MAX do
			local v1 = tab[k1]
			if v1 and csvSize(v1) >= 1 then
				battleCardsTab[k][k1] = {dbid = v1[1], fighting_point = v1[4], level = v1[5], star = v1[6], advance = v1[7], card_id = v1[2],skin_id = v1[3]}
				--1没有特殊特意上只是将上阵卡牌保存起来后续在一键上阵中做筛选
				self.dbidData[v1[1]] = 1
			end
		end
	end
	self.battleCardsData:set(battleCardsTab)
	self.clientBattleCards:set(battleCardsTab)
	--list数据刷新

	-- 一键布阵待处理
	local cards = self.cards:read()
	local all = {}
	local oneKeyAllCards = {}
	local clock = os.clock()
	for _, dbid in ipairs(cards) do
		local natureVaild = true
		local card = gGameModel.cards:find(dbid)
		local cardDatas = card:read("card_id","skin_id", "fighting_point", "level", "star", "advance", "created_time", "nature_choose")
		local cardCfg = csv.cards[cardDatas.card_id]
		local unitCfg = csv.unit[cardCfg.unitID]
		local natureLimit = self.nature_limit[self.btnState+1]
		if itertools.size(natureLimit) > 0 then
			natureVaild = itertools.include(natureLimit, unitCfg.natureType) or itertools.include(natureLimit, unitCfg.natureType2)
		end
		if natureVaild then
			all[dbid] = self:limtFunc(dbid, cardDatas.card_id,cardDatas.skin_id, cardDatas.fighting_point, cardDatas.level, cardDatas.star, cardDatas.advance, cardDatas.created_time, cardDatas.nature_choose, self.dbidData[dbid] and 1 or 0)
			table.insert(oneKeyAllCards, all[dbid])
		end
	end
	-- self.allCardDatas:update(all)

	self.oneKeyAllCards = oneKeyAllCards
end



--切页
function EmbattleView:clickBtn(list, k, v)
	if self.btnTab:read() ~= v.card_id then
		self:sendRequeat(function( ... )
		end, true, true)

		self.btnTab:set(v.card_id)
		self.btnState = v.card_id
		self:initScreenView()
		self.natureLimitData:update(self.nature_limit[v.card_id + 1]) --类型限制
		self.dbidData = {}
		self:updateData()
		self:initHeroSprite()
	end
end

--切页是初始化筛选的数据
function EmbattleView:initScreenView()
	local state = self:unionState()
	cache.setShader(self.cardListView.bagFilter, false, state and "normal" or "hsl_gray")
	self.cardListView.bagFilter.selBtn:setTouchEnabled(state)
	self.cardListView.bagFilter:initData()
end

-- 底部所有卡牌
function EmbattleView:initBottomList(  )
	self.cardListView = gGameUI:createView("city.card.embattle.union_fight_card_list", self.bottomPanel):init({
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
end

-- move时创建item
function EmbattleView:createMovePanel(data)
	if not self:unionState() then
		return
	end
	if not data then return end
	if not gGameModel.cards:find(data.dbid) then return end
	if self.movePanel then
		self.movePanel:removeSelf()
	end
	local movePanel = self.movecard:clone():addTo(self:getResourceNode(), 1000)
	movePanel:scale(0.9)
	self.movePanel = movePanel
	return self:itemSkin(movePanel, data.dbid)
end

-- move时创建item
function EmbattleView:deleteMovingItem()
	if not self:unionState() then
		return
	end
	self.selectIndex:set({0, 0})
	if self.movePanel then
		self.movePanel:removeSelf()
		self.movePanel = nil
	end
end

function EmbattleView:moveMovePanel(event)
	if not self:unionState() then
		return
	end
	if self.movePanel then
		self.movePanel:xy(event)
		local dbid, site1, site2 = self:whichEmbattleTargetPos(event)
		self.selectIndex:set({site1, site2})
	end
end

function EmbattleView:isMovePanelExist()
	return self.movePanel ~= nil
end

function EmbattleView:moveEndMovePanel(data)
	if not self.movePanel then
		return
	end
	local index = self.selectIndex:read()
	if index[1] and index[2] then
		self:resetBattle(index[1], index[2],  data)
	end
	self:deleteMovingItem()
end

-- 点击卡牌，上阵或下阵
function EmbattleView:onCardClick(data, isShowTip)
	if not self:unionState() then
		return
	end
	local tip
	local dbid = data.dbid
	local idx = self:getIdxByDbId(dbid)
	-- 在阵容上
	if data.battle > 0 then
		local downBattle = self:spriteNumber(dbid)
		if downBattle > 1 then
			self:downHero(dbid, true)
		else
			tip = gLanguageCsv.battleCannotEmpty
		end
	else
		local downBattle, itemNum, itemNumAll = self:spriteNumber(dbid)
		if itemNum >= itemNumAll then
			tip = gLanguageCsv.battleCardCountEnough
		elseif self:hasSameMarkIDCard(data.card_id) then
			tip = gLanguageCsv.alreadyHaveSameSprite
		else
			self:upHero(dbid, false) --上阵
		end
	end
	if isShowTip and tip then
		gGameUI:showTip(tip)
	end
end

--move时给item穿上衣服
function EmbattleView:itemSkin(item, dbid, star)
	local card = gGameModel.cards:find(dbid)
	local card_id = card:read("card_id")
	local skin_id = card:read("skin_id")
	local advance = card:read("advance")
	local level = card:read("level")
	local cardCsv = csv.cards[card_id]
	local unitCsv = csv.unit[cardCsv.unitID]
	local unitId = dataEasy.getUnitId(card_id, skin_id)
	bind.extend(self, item, {
		class = "card_icon",
		props = {
			unitId = unitId,
			rarity = unitCsv.rarity,
			advance = advance,
			star = star,
			levelProps = {
				data = level,
			},
		}
	})
	return item
end

--布阵状态
--#prepare准备 battle战斗中 over结束
function EmbattleView:unionState()
	local combat = gGameModel.union_fight:read("round")
	if self.cardsNumAll then
		return false
	end
	if self.wday > self.btnState+1 or self.wday == 7 then
		-- gGameUI:showTip(gLanguageCsv.combatFinish)
		return false
	end
	if self.wday == self.btnState+1 and combat == "over" then
		return false
	end
	if (combat == "battle" or combat == "prepare") and self.wday == self.btnState+1 then
		gGameUI:showTip(gLanguageCsv.unionfightDeployLimit)
		return false
	end
	if self.unionCombet then
		return false
	end
	return true
end

-- 给界面上的精灵添加拖拽功能
function EmbattleView:initHeroSprite()
	local combat = gGameModel.union_fight:read("round")
	self.title:visible(false)
	if self.wday > self.btnState+1 or self.wday == 7 then
		self.title:visible(true)
		self.title:text(gLanguageCsv.combatFinish)
	end
	if self.wday == self.btnState+1 and (combat == "battle" or combat == "prepare") then
		self.title:visible(true)
		self.title:text(gLanguageCsv.unionfightDeployLimit)
	end
	if self.wday == self.btnState+1 and combat == "over" then
		self.title:visible(true)
		self.title:text(gLanguageCsv.combatFinish)
	end
	if self.cardsNumAll then
		self.title:visible(true)
		self.title:text(gLanguageCsv.cardsNotNum)
	end
	if self.unionCombet then
		self.title:visible(true)
		self.title:text(gLanguageCsv.combatFinish)
	end
	self.battlePanel:removeAllChildren()
	self.heroSprite = {}
	self.upPosition:visible(false)
	local data = self.btnState < 5 and 1 or 2
	local data2 = self.btnState < 4 and 1 or 2
	local itemLength = self.btnState < 5 and 2 or 3
	self.rightPanel:visible(data2 ~= 2)
	local cardsSize = self.btnState <= 4 and 3 or 4
	self.fightingTab = {}
	self.panelTab = {}
	local fighting, cardId, cfg, advance, unitCsv, cardNum,unitId
	for k=1, itemLength do
		fighting = 0
		cardNum = 0
		local tab = self.clientBattleCards:read()[k]
		local panel = self.upPosition:clone():addTo(self.battlePanel, 999, "name"..k)
		adapt.setAutoText(panel:get("behind"), nil, 120)
		adapt.setAutoText(panel:get("front"), nil, 120)
		panel:xy(panelPos[data][k])
		panel:visible(true)
		panel:get("icon"):get("title1"):text(k)
		self.heroSprite[k] = {}
		self.panelTab[k] = {}
		self.panelTab[k].panel = panel
		if not tab then return false end
		for k1 = 1, NUM_MAX do
			local item = panel:get("icon"..k1)
			if tab[k1] and csvSize(tab[k1]) > 1 then
				cardNum = cardNum + 1
				cardId = tab[k1].card_id
				fighting = fighting + tab[k1].fighting_point
				advance = tab[k1].advance
				cfg = csv.cards[cardId]
				unitCsv = csv.unit[cfg.unitID]
				unitId = dataEasy.getUnitId(tab[k1].card_id, tab[k1].skin_id)
				bind.extend(self, item, {
					class = "card_icon",
					props = {
						unitId = unitId,
						rarity = unitCsv.rarity,
						advance = advance,
						star = tab[k1].star,
						levelProps = {
							data = tab[k1].level,
						},
					}
				})
				item:scale(0.9)
				item:show()
			end
			item:onTouch(functools.partial(self.onBattleCardTouch, self, k, k1))
			self.heroSprite[k][k1] = {}
			self.heroSprite[k][k1] = {sprite = item, dbid = tab[k1] and tab[k1].dbid or nil, markId = cfg and cfg.cardMarkID or nil}
			-- item:setTouchEnabled(not self.cardsNumAll)
		end
		self.fightingTab[k] = fighting
		panel:get("count"):text(cardNum..'/'..cardsSize)
		panel:get("strengthNum"):text(fighting)
		fightingfontAdaptiveFunc(panel:get("strength"), panel:get("strengthNum"))
	end
end

function EmbattleView:onBattleCardTouch(k, k1, event)
	if not self:unionState() then
		return
	end
	local dbidInfo = self.clientBattleCards:read()[k][k1]
	if itertools.isempty(dbidInfo) then
		return
	end
	if event.name == "began" then
		self.moved = false
		self:createMovePanel(dbidInfo)
	elseif event.name == "moved" then
		self.moved = true
		self:moveMovePanel(event)
	elseif (event.name == "ended" or event.name == "cancelled") then
		if not dbidInfo then
			self:deleteMovingItem()
			return
		end
		if self.moved == false or event.y < 340  then
			--点击下阵 拖拽下阵
			local downBattle = self:spriteNumber(dbidInfo.dbid)
			if downBattle > 1 then
				self:downHero(dbidInfo.dbid, true)
			else
				gGameUI:showTip(gLanguageCsv.battleCannotEmpty)
			end
		else
			--交换位置
			local dbid2, site1, site2 = self:whichEmbattleTargetPos(event)
			self:changeHero(dbidInfo.dbid, dbid2, site1, site2)
		end
		self:deleteMovingItem()
	end
end

-- 一键布阵
function EmbattleView:oneKeyEmbattleBtn()
	if not self:unionState() then
		return
	end
	if self.cardsNumAll then
		return
	end
	local itemSize, itemQuantity
	if self.btnState <= 4 then
		itemSize = 3
		itemQuantity = 6
	else
		itemSize = 4
		itemQuantity = 12
	end

	local sign = 0
	local itemLength = self.btnState < 5 and 2 or 3
	for i=1,itemLength do
		for k=1,6 do
			self.clientBattleCards:modify(function(oldval)
				if oldval[i][k] and self.allCardDatas:atproxy(oldval[i][k].dbid) then
					self.allCardDatas:atproxy(oldval[i][k].dbid).battle = 0
				end
				return true, oldval
			end)
		end
	end

	if self.oneKeyAllCards then
		-- 保存一键上阵的卡牌信息
		table.sort(self.oneKeyAllCards, function(a, b)
			if a.fighting_point ~= b.fighting_point then
				return a.fighting_point > b.fighting_point
			end
			return a.rarity > b.rarity
		end)
		self.oneKeyCards = {}
		local oneKeyHash = {}
		local count = 0
		for _, v in ipairs(self.oneKeyAllCards) do
			if not oneKeyHash[v.markId] then
				oneKeyHash[v.markId] = true
				table.insert(self.oneKeyCards, v.dbid)
				count = count + 1
				if count == CARD_MAX then
					break
				end
			end
		end
		self.oneKeyAllCards = nil
	end
	for i=1,NUM_MAX do
		for k=1, itemLength do
			self.clientBattleCards:modify(function(oldval)
				if i <= itemSize then
					sign = sign + 1
					if self.oneKeyCards[sign] then
						if self.allCardDatas:atproxy(self.oneKeyCards[sign]) then
							self.allCardDatas:atproxy(self.oneKeyCards[sign]).battle = 1
						end
						local cardDataProperty = gGameModel.cards:find(self.oneKeyCards[sign])
						local cardId = cardDataProperty:read("card_id")
						local skinId = cardDataProperty:read("skin_id")
						local cfg = csv.cards[cardId]
						local level = cardDataProperty:read("level")
						local star = cardDataProperty:read("star")
						local fighting_point = cardDataProperty:read("fighting_point")
						local advance = cardDataProperty:read("advance")
						oldval[k][i] = {dbid = self.oneKeyCards[sign], fighting_point = fighting_point, level = level, star = star, advance = advance, card_id = cardId,skin_id = skinId}
					else
						oldval[k][i] = {}
					end
				else
					oldval[k][i] = {}
				end
				return true, oldval
			end)
		end
	end
	gGameUI:showTip(gLanguageCsv.addToEmbattle)
	self:initHeroSprite()
end

--是否跟换
function EmbattleView:whichEmbattleTargetPos(p)
	for i,cards in pairs(self.heroSprite) do
		for k,v in pairs(cards) do
			local item = v.sprite
			local rect = item:box()
			local pos = item:getParent():convertToWorldSpace(cc.p(rect.x, rect.y))
			rect.x, rect.y = pos.x, pos.y
			if cc.rectContainsPoint(rect, p) then
				return v.dbid, i, k
			end
		end
	end
end

--统计上阵数量
function EmbattleView:spriteNumber(dbid)
	--itemNum上阵数量，itemNumAll总共的位置
	local itemNum, downBattle, itemNumAll = 0, 0, 0
	local downBattleK
	if self.btnState <= 4 then
		itemNumAll = 6
	else
		itemNumAll = 12
	end
	for k,data in pairs(self.heroSprite) do
		for k1,v1 in pairs(data) do
			if v1.dbid then
				itemNum = itemNum + 1
			end
			if v1.dbid == dbid then
				downBattleK = k
			end
		end
	end
	--判断次数能否下阵
	if downBattleK then
		for k1,v1 in pairs(self.heroSprite[downBattleK]) do
			if v1.dbid then
				downBattle = downBattle + 1
			end
		end
	end
	return downBattle, itemNum, itemNumAll, downBattleK
end

--判断点击的精灵是否已上阵
function EmbattleView:getIdxByDbId(dbid)
	if not dbid then
		return
	end
	for k,v in pairs(self.heroSprite) do
		for k1,v1 in pairs(v) do
			if v1.dbid == dbid then
				return k, k1
			end
		end
	end
end
--相同和属性
function EmbattleView:hasSameMarkIDCard(card_id)
	local markId = csv.cards[card_id].cardMarkID
	for k,v in pairs(self.heroSprite) do
		for k1,v1 in pairs(v) do
			if v1.markId == markId then
				return true
			end
		end
	end
	return false
end
--下阵
function EmbattleView:downHero(dbid, isShowTip)
	if dbid then
		if self.allCardDatas:atproxy(dbid) then
			self.allCardDatas:atproxy(dbid).battle = 0
		end
		local k1, k2 = self:getIdxByDbId(dbid)
		self.clientBattleCards:modify(function(showDatas)
			self.dbidData[dbid] = nil
			showDatas[k1][k2] = nil
			self.heroSprite[k1][k2].sprite:hide()
			self.heroSprite[k1][k2].dbid = nil
			self.heroSprite[k1][k2].markId = nil
			local fightingTab = self.fightingTab[k1] - gGameModel.cards:find(dbid):read("fighting_point")
			self.panelTab[k1].panel:get("strengthNum"):text(fightingTab)
			fightingfontAdaptiveFunc(self.panelTab[k1].panel:get("strength"), self.panelTab[k1].panel:get("strengthNum"))
			self.fightingTab[k1] = fightingTab
			return true, showDatas
		end)
		self:initHeroSprite()
		if isShowTip then
			gGameUI:showTip(gLanguageCsv.downToEmbattle)
		end
	end
end

--点击上阵
--isShowTip是true是拖动的，false是点击
function EmbattleView:upHero(dbid, isShowTip, k1, k2)
	--点击补位上阵时判断上阵数量
	local upArrayFunc = function(k)
		local itemNumAll = self.btnState <= 4 and 3 or 4
		local downBattle = 0
		for i,v in pairs(self.heroSprite[k]) do
			if v.dbid then
				downBattle = downBattle + 1
			end
		end
		if itemNumAll <= downBattle then
			return false
		end
		return true
	end

	--判断是点击还是拖动(点击部位)
	--已经排除个数和同属性
	local idx1, idx2
	local flag = false
	local itemLength = self.btnState < 5 and 2 or 3
	--组装数据
	if not isShowTip then
		for i=1,NUM_MAX do
			for k=1, itemLength do
				if itertools.isempty(self.clientBattleCards:read()[k][i]) and not flag then
					if upArrayFunc(k) then
						idx1, idx2 = k, i
						flag = true
						break
					end
				end
			end
			if flag then
				break
			end
		end
	else
		idx1, idx2 = k1, k2
	end

	self.clientBattleCards:modify(function(oldval)
		if self.allCardDatas:atproxy(dbid) then
			self.allCardDatas:atproxy(dbid).battle = 1
		end
		self.dbidData[dbid] = 1
		local cardData = gGameModel.cards:find(dbid)
		local cardId = cardData:read("card_id")
		local skinId = cardData:read("skin_id")
		local advance = cardData:read("advance")
		local cfg = csv.cards[cardId]
		local level = cardData:read("level")
		local star =  cardData:read("star")
		local fighting_point = cardData:read("fighting_point")
		oldval[idx1][idx2] = {dbid = dbid, fighting_point = fighting_point, level = level, star = star, advance = advance, card_id = cardId,skin_id = skinId}
		local item = self.panelTab[idx1].panel:get("icon"..idx2)
		self.heroSprite[idx1][idx2] = {sprite = item, dbid = dbid, markId = cfg.cardMarkID}
		self:itemSkin(item, dbid)
		item:show()
		--#更换计算战斗力
		local fightingTab = self.fightingTab[idx1] + fighting_point
		self.fightingTab[idx1] = fightingTab
		self.panelTab[idx1].panel:get("strengthNum"):text(fightingTab)
		fightingfontAdaptiveFunc(self.panelTab[idx1].panel:get("strength"), self.panelTab[idx1].panel:get("strengthNum"))
		return true, oldval
	end, true)
	audio.playEffectWithWeekBGM("formation.mp3")
	gGameUI:showTip(gLanguageCsv.addToEmbattle)
	self:initHeroSprite()
end

--拖动上阵判断人数是否达到
function EmbattleView:cardNumberFunc(idx)
	local numAll = self.btnState <= 4 and 3 or 4
	local existNum = 0
	for k,v in pairs(self.heroSprite[idx]) do
		if v.dbid then
			existNum = existNum + 1
		end
	end
	if existNum >= numAll then
		return false
	end
	return true
end

--判断上下交换的精灵是否是相同cardMarkID
function EmbattleView:equalCardMarkView(id1, id2)
	if not id1 or not id2 then
		return false
	end
	local cardMask1 = csv.cards[id1].cardMarkID
	local cardMask2 = csv.cards[id2].cardMarkID
	if cardMask1 == cardMask2 then
		return true
	end
	return false
end

function EmbattleView:resetBattle(idx1, idx2, data)
	local dbid = self.clientBattleCards:read()[idx1][idx2] and self.clientBattleCards:read()[idx1][idx2].dbid or nil
	if data.battle == 0 then
		--拖动未上阵且拖动到的地方没有卡牌判断上阵的数量和属性
		if not dbid then
			if self:hasSameMarkIDCard(data.card_id) then
				gGameUI:showTip(gLanguageCsv.alreadyHaveSameSprite)
				return
			elseif not self:cardNumberFunc(idx1) then
				gGameUI:showTip(gLanguageCsv.battleCardCountEnough)
				return
			end
		else
			local card_id = gGameModel.cards:find(dbid):read("card_id")
			if self:equalCardMarkView(card_id, data.card_id) then
				self:downHero(dbid, false)
				self:upHero(data.dbid, true, idx1, idx2)
				return
			end
		end

		if self:hasSameMarkIDCard(data.card_id) then
			gGameUI:showTip(gLanguageCsv.alreadyHaveSameSprite)
			return
		else
			self:downHero(dbid, false)
			self:upHero(data.dbid, true, idx1, idx2)
		end
	else
		-- change 选中的精灵再队伍中 并且拖动到了已上阵精灵的位子
		if dbid then
			if dbid == data.dbid then
				return
			end
			self:changeHero(dbid, data.dbid)
		else
			self:changeHero(data.dbid, nil, idx1, idx2)
		end
	end
end

--dbid1自己dbid2要交换的卡牌
-- site1, site2表示将拖到的位置(site1:队伍， site2具体位置)
function EmbattleView:changeHero(dbid1, dbid2, site1, site2)
	if not dbid2 and not site1  then return end
	if not dbid2 then
		--跟换阵容时不能为空
		local downBattle, data1, data2, dataK = self:spriteNumber(dbid1)
		local battleNumer = 0
		if downBattle == 1 and dataK ~= site1 then
			gGameUI:showTip(gLanguageCsv.battleNumberNo)
			return
		end
		--跟换阵容时不能超过限制数量
		local num = self.btnState < 5 and 3 or 4
		for k,v in pairs(self.heroSprite[site1]) do
			if v.dbid then
				battleNumer = battleNumer + 1
			end
		end
		if battleNumer == num and dataK ~= site1 then
			gGameUI:showTip(gLanguageCsv.battleCardCountEnough)
			return
		end
	end

	local x1, y1, x2, y2
	local dataInfo1, dataInfo2 = true, true
	for k,v in pairs(self.heroSprite) do
		for k1,v1 in pairs(v) do
			if v1.dbid == dbid1 and dataInfo1 then
				x1 = k
				y1 = k1
				dataInfo1 = false
			end
			if dbid2 and v1.dbid == dbid2 and dataInfo2 then
				x2 = k
				y2 = k1
				dataInfo2 = false
			end
		end
	end

	x2 = not x2 and site1 or x2
	y2 = not y2 and site2 or y2
	self.clientBattleCards:modify(function(showDatas)
		showDatas[x1][y1], showDatas[x2][y2] = showDatas[x2][y2], showDatas[x1][y1]
		self:initHeroSprite()
		return true, showDatas
	end)
end

function EmbattleView:onClose()
	self:sendRequeat(functools.partial(ViewBase.onClose, self), true)
end

-- 卡牌过滤 待继承
function EmbattleView:limtFunc(dbid, card_id,skin_id, fighting_point, level, star, advance, created_time, nature_choose, inBattle)
	local cardCsv = csv.cards[card_id]
	local unitCsv = csv.unit[cardCsv.unitID]
	local natureLimit = self.nature_limit[self.btnState+1]
	local natureVaild = true
	if itertools.size(natureLimit) > 0 then
		local unitCfg = csv.unit[cardCsv.unitID]
		natureVaild = itertools.include(natureLimit, unitCfg.natureType) or itertools.include(natureLimit, unitCfg.natureType2)
	end
	if not natureVaild then
		return nil
	end
	local cardCsv = csv.cards[card_id]
	local unitCsv = csv.unit[cardCsv.unitID]
	local unitId = dataEasy.getUnitId(card_id, skin_id)
	return {
		card_id = card_id,
		unit_id  = unitId,
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
		markId = cardCsv.cardMarkID,
		atkType = cardCsv.atkType,
		nature_choose = nature_choose,
	}
end


-- 关闭或切页阵容变动检测和保存
function EmbattleView:sendRequeat(cb, isClose, paging)
	local battleCardsTab1, battleCardsTab2 = {}, {}
	local datashow1, datashow2 = {}, {}
	local num = self.btnState < 5 and 2 or 3
	local sizeNum = self.btnState > 4 and 4 or 3
	--上阵数据（可能改动）
	local itemLength = self.btnState < 5 and 2 or 3
	for k=1, itemLength do
		battleCardsTab1[k] = {}
		for i=1,NUM_MAX do
			if self.clientBattleCards:read()[k][i] and self.clientBattleCards:read()[k][i].dbid then
				battleCardsTab1[k][i] = self.clientBattleCards:read()[k][i].dbid
			else
				battleCardsTab1[k][i] = ""
			end
		end
	end
	local battleCards = gGameModel.union_fight:read("role_info")["cards"]
	--上阵卡牌数据
	--服务器给的上阵数据
	for k,tab in pairs(battleCards[self.btnState+1]) do
		battleCardsTab2[k] = {}
		for i=1,NUM_MAX do
			if tab[i] and csvSize(tab[i]) >= 1 then
				battleCardsTab2[k][i] = tab[i][1]
			else
				battleCardsTab2[k][i] = ""
			end
		end
	end

	local equality = itertools.equal(battleCardsTab1, battleCardsTab2)
	if paging then
		if not equality then
			gGameApp:requestServer("/game/union/fight/battle/deploy", function(data)
				gGameUI:showTip(gLanguageCsv.positionSave)
			end, self.btnState+1, battleCardsTab1)
			return
		end
	else
		if not equality then
			local result = self.clientBattleCards:read()
			if not result then
				if isClose then
					cb()
				else
					gGameUI:showTip(gLanguageCsv.lineupInconsistency)
				end
				return
			end
				gGameApp:requestServer("/game/union/fight/battle/deploy", function(data)
					ViewBase.onClose(self)
					gGameUI:showTip(gLanguageCsv.positionSave)
				end, self.btnState+1, battleCardsTab1)
		else
			cb()
		end
	end

end

return EmbattleView
