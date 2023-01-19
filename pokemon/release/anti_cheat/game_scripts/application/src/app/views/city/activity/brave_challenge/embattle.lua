local BCAdapt = require("app.views.city.activity.brave_challenge.adapt")

local PANEL_NUM = 6
local SPRITE_MAX   =  6

local ZORDER = {2, 4, 6, 1, 3, 5}

local BADGE_BELONG = {
    mine = 1, -- 我方勋章
    enemy = 2,  --敌方
}

local ViewBase = cc.load("mvc").ViewBase
local CardEmbattleView = require "app.views.city.card.embattle.base"
local BraveChallengleEmbattle = class("BraveChallengleEmbattle", CardEmbattleView)

BraveChallengleEmbattle.RESOURCE_FILENAME = "activity_brave_challenge_embattle.json"
BraveChallengleEmbattle.RESOURCE_BINDING = {
	["battlePanel1"] = "leftPanel",
	["battlePanel2"] = "rightPanel",

	["spritePanel"] = "spriteItem",
	["rightDown"] = "rightDown",

	["bottomPanel"] = "bottomPanel",

	["rightDown.btnChallenge"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("fightBtn")}
		}
	},
	["rightDown.textNote"] = "textNote",
	["rightDown.textNum"] = "textNum",
	["rightDown.btnOneKeySet.textNote"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.WHITE}},
		},
	},
	["battlePanel1.ahead.txt"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.WHITE}},
		},
	},
	["battlePanel1.back.txt"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.WHITE}},
		},
	},
	["battlePanel2.ahead.txt"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.WHITE}},
		},
	},
	["battlePanel2.back.txt"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.WHITE}},
		},
	},

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

	["panelTop.panelSelf"] = "panelSelfBadge",
	["panelTop.panelOpp"] = "panelOppBadge",
	["panelTop.panelSelf.txt02"] = {
		binds = {
			event = "effect",
			data = {outline={color=cc.c4b(63,178,239, 255)}},
		},
	},
	["panelTop.panelOpp.txt02"] = {
		binds = {
			event = "effect",
			data = {outline={color=cc.c4b(246,82,102, 255)}},
		},
	},
}


function BraveChallengleEmbattle:onCreate(params)
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose", true)})
		:init({title = gLanguageCsv.formation, subTitle = "FORMATION"})

	adapt.centerWithScreen("left", "right", nil, {
		{self.rightDown, "pos", "right"},
	})

	self:initModel()

	self.fightCb = params.fightCb
	self.newCards = params.newCards

	self.emenyDatas = {}
	self.heroSprite = {}
	self.emenySprite = {}
	self.teamSelfBuff = {}
	self.teamEnemyBuff = {}

	self.panel = {
		{
			parent = self.leftPanel,
			list = self.heroSprite,
		},
		{
			parent = self.rightPanel,
			list = self.emenySprite,
		}
	}

	self:updateData()
	self:initSpriteItem()
	self:initEnemyUI()
	self:initSelfBadge(self.panelSelfBadge, self.badges:read())
	self:initBottomList()
	self:refreshTeamBuff(self.emenyDatas, 2)

	idlereasy.when(self.clientBattleCards, function (_, battle)
		self:refreshTeamBuff(battle, 1)

		self:showBattleNum(battle)
		for index = 1, PANEL_NUM do
			self:initHeroSprite(index)
		end
	end)
end

-- idler初始化
function BraveChallengleEmbattle:initModel()
	self.game = gGameModel.brave_challenge:getIdler("game")
	self.id = gGameModel.brave_challenge:getIdler("yyID")
	self.badges = gGameModel.brave_challenge:getIdler("badges")

	self.clientBattleCards = idlertable.new({})
	self.battleCardsData = idlertable.new({})
	self.allCardDatas = idlers.newWithMap({})
	self.selectIndex = idler.new(0)
	self.draggingIndex = idler.new(0) -- 正在拖拽的节点的index
end

-- 数据处理
function BraveChallengleEmbattle:initBadge(panel, badges, idx)
	local csvBadge = csv.brave_challenge.badge
	local rarityTable = {}

	for index, badge in pairs(badges) do
		local info = csvBadge[badge]
		if info then
			if rarityTable[info.rarity] == nil then
				rarityTable[info.rarity] = 1
			else
				rarityTable[info.rarity] = rarityTable[info.rarity] + 1
			end
		end
	end

	local childs = panel:multiget("txtRate","txtCommon","btnSelfBadges")
	childs.txtCommon:text(rarityTable[1] or 0)
	childs.txtRate:text(rarityTable[2] or 0)

	panel:onClick(functools.partial(self.onClickBadges, self, badges, idx))
end

-- 初始化自己的徽章数据
function BraveChallengleEmbattle:initSelfBadge(panel, badges)
	local tempBadges = {}
	for tp, childBadges in pairs(badges) do
		for index, badge in pairs(childBadges) do
			table.insert(tempBadges, badge)
		end
	end
	self:initBadge(panel, tempBadges, BADGE_BELONG.mine)
end

-- 初始化数据
function BraveChallengleEmbattle:updateData()
	local gameInfo = self.game:read()
	local cardDatas = gameInfo.cards
	local deployments = gameInfo.deployments
	local hash = {}

	local tempBattleCardsData = {}
	local tempClientBattleCards = {}
	for index, id in ipairs(deployments) do
		if id > 0 then
			hash[id] = true
		end
		tempBattleCardsData[index] = id
		tempClientBattleCards[index] = id
	end

	self.clientBattleCards:set(tempClientBattleCards)
	self.battleCardsData:set(tempBattleCardsData)

	local tempAllCardDatas = {}
	local csvCards = csv.brave_challenge.cards
	for csvID, status in pairs(cardDatas) do
		local csvCard = csvCards[csvID]
		local cardInfo = csv.cards[csvCard.cardID]
		local csvUnit  = csv.unit[cardInfo.unitID]

		tempAllCardDatas[csvID] = {
			csvID = csvID,
			card_id = csvCard.cardID,
			unit_id = cardInfo.unitID,
			level = csvCard.level,
			star = csvCard.star,
			advance = csvCard.advance,
			rarity = csvUnit.rarity,
			attr1 = csvUnit.natureType,
			attr2 = csvUnit.natureType2,
			markId = cardInfo.cardMarkID,
			states = status,
			battle = hash[csvID] and 1 or 0,
			isNew = self.newCards[csvID] or false
		}
	end
	self.allCardDatas:update(tempAllCardDatas)
end

function BraveChallengleEmbattle:showBattleNum(battle)
	local num = 0
	for index, id in pairs(battle) do
		if id ~= 0 then
			num = num + 1
		end
	end

	self.textNum:text(string.format("%d/%d", num, PANEL_NUM))
	adapt.oneLineCenterPos(cc.p(163, 152), {self.textNote, self.textNum}, cc.p(5, 0))
end

-- 初始化控件
function BraveChallengleEmbattle:initSpriteItem()
	for i = 1, 2 do
		local panel = self.panel[i].parent
		local list = self.panel[i].list
		for j = 1, PANEL_NUM do
			local item = panel:get("item"..j)
			local rect = item:box()
			local pos = item:getParent():convertToWorldSpace(cc.p(rect.x, rect.y))
			rect.x, rect.y = pos.x, pos.y
			list[j] = {item = item,rect = rect, idx = j}
			if i == 1 then
				item:onTouch(functools.partial(self.onBattleCardTouch, self, j))
			end
		end
	end

	for i = 1, PANEL_NUM do
		local imgBg = self.heroSprite[i].item:get("imgBg")
		local imgSel = imgBg:get("imgSel")
		local size = imgBg:size()
		if not imgSel then
			imgSel = widget.addAnimationByKey(imgBg, "effect/buzhen2.skel", "imgSel", "effect_loop", 2)
				:xy(size.width/2, size.height/2 + 15)
		end
	end


	idlereasy.when(self.selectIndex, function (_, selectIndex)
		for i = 1, PANEL_NUM do
			local imgSel = self.heroSprite[i].item:get("imgBg.imgSel")
			imgSel:visible(selectIndex == i)
		end
	end)


	idlereasy.when(self.draggingIndex, function (_, index)
		-- index - 1 全透明  0 全不透明
		for i = 1, PANEL_NUM do
			local sprite = self.heroSprite[i].item:get("sprite")
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

-- 初始化敌方数据
function BraveChallengleEmbattle:initEnemyUI()
	local gameInfo = self.game:read()
	local list = gameInfo.monsters
	local monsterID = gameInfo.monsterID
	local csvMonster = csv.brave_challenge.monster[monsterID]
	local csvCards = csv.brave_challenge.cards

	self:initBadge(self.panelOppBadge, csvMonster.badges, BADGE_BELONG.enemy)

	self.emenyDatas = {}
	for index, id in csvPairs(csvMonster.cards) do
		if list[index] and list[index][1] ~= 0 then
			self.emenyDatas[index] = id
		end
	end

	for index = 1, PANEL_NUM do
		local csvID = self.emenyDatas[index]
		local spriteTb = self.emenySprite[index]
		local csvCard = csvCards[csvID]
		if csvCard then
			local unitID = csv.cards[csvCard.cardID].unitID
			local unitCsv  =  csv.unit[unitID]

			local imgBg = spriteTb.item:get("imgBg")
			local cardSprite = widget.addAnimationByKey(spriteTb.item, unitCsv.unitRes, "sprite", "standby_loop", 4)
				:scale(-unitCsv.scale * 0.8,unitCsv.scale * 0.8)
				:xy(imgBg:x(), imgBg:y() + 15)
			cardSprite:setSkin(unitCsv.skin)

			local flags = self.teamEnemyBuff and self.teamEnemyBuff.flags or {1, 1, 1, 1, 1, 1}
			local flag = flags[index]
			uiEasy.setTeamBuffItem(spriteTb.item, csvCard.cardID, flag)
		else
			spriteTb.item:get("attrBg"):hide()
		end
	end
end

--初始化我放数据
function BraveChallengleEmbattle:initHeroSprite(index)

	local panel = self.heroSprite[index].item

	local data = self:getCardAttrs(self.clientBattleCards:read()[index])

	if not data then
		if panel:getChildByName("sprite") then
			panel:getChildByName("sprite"):hide()
		end
		panel:get("attrBg"):hide()
		return
	end

	local csvUnit  =  csv.unit[data.unit_id]

	local imgBg = panel:get("imgBg")
	if panel.csvID == data.csvID and panel:getChildByName("sprite") then
		panel:getChildByName("sprite"):show()
	else
		panel:removeChildByName("sprite")
		local cardSprite = widget.addAnimationByKey(panel, csvUnit.unitRes, "sprite", "standby_loop", 4)
			:scale(csvUnit.scale * (0.8+(index - 1)%3*0.1))
			:xy(imgBg:x(), imgBg:y() + 15)
		cardSprite:setSkin(csvUnit.skin)
		panel.csvID = data.csvID
	end

	local spriteId = data.card_id
	local flags = self.teamSelfBuff and self.teamSelfBuff.flags or {1, 1, 1, 1, 1, 1}
	local flag = flags[index]
	uiEasy.setTeamBuffItem(panel, data.card_id, flag)
end

function BraveChallengleEmbattle:onBattleCardTouch(idx, event)
	if  self.clientBattleCards:read()[idx] == 0 then
		return
	end
	local data = self:getCardAttrs(self.clientBattleCards:read()[idx])
	if event.name == "began" then
		self:deleteMovingItem()
		self:createMovePanel(data)
		local panel = self.heroSprite[idx].item
		panel:get("sprite"):hide()
		panel:get("attrBg"):hide()
		self:moveMovePanel(event)

	elseif event.name == "moved" then
		self:moveMovePanel(event)

	elseif event.name == "ended" or event.name == "cancelled" then
		local panel = self.heroSprite[idx].item
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

-- 底部所有卡牌
function BraveChallengleEmbattle:initBottomList()
	self.cardListView = gGameUI:createView("city.card.embattle.brave_challenge_card_list", self.bottomPanel):init({
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

function BraveChallengleEmbattle:canBattleDown()
	return self.clientBattleCards:size() > 1
end

function BraveChallengleEmbattle:canBattleUp()
	local sum = 0
	for index, data in self.clientBattleCards:pairs() do
		if data > 0 then
			sum = sum + 1
		end
	end
	return sum < PANEL_NUM
end


--重载
function BraveChallengleEmbattle:whichEmbattleTargetPos(pos)
	-- 精灵交互区域可以存在覆盖，从最前面开始
	for i = PANEL_NUM, 1, -1 do
		local rect = self.heroSprite[i].rect
		if cc.rectContainsPoint(rect, pos) then
			return i
		end
	end
end


function BraveChallengleEmbattle:deleteMovingItem()
	self.selectIndex:set(0)
	if self.movePanel then
		self.movePanel:removeSelf()
		self.movePanel = nil
	end
	self.draggingIndex:set(0)
end

function BraveChallengleEmbattle:moveMovePanel(event)
	if self.movePanel then
		self.movePanel:xy(event)
		self.selectIndex:set(self:whichEmbattleTargetPos(event))
	end
end

function BraveChallengleEmbattle:moveEndMovePanel(data)
	if not self.movePanel then
		return
	end
	local index = self.selectIndex:read()
	self:onCardMove(data, index, true)
	self:deleteMovingItem()
end

function BraveChallengleEmbattle:isMovePanelExist()
	return self.movePanel ~= nil
end

--判断点击的精灵是否已上阵
function BraveChallengleEmbattle:getIdxByDbId(csvID)
	for i = 1,  PANEL_NUM do
		local id = self.clientBattleCards:read()[i] or 0
		if id == csvID then
			return i
		end
	end
end

-- data 数据移动到 targetIdx 位置上，targetIdx nil 为点击
function BraveChallengleEmbattle:onCardMove(data, targetIdx, isShowTip)
	local tip
	local csvID = data.csvID
	local idx = self:getIdxByDbId(csvID)
	local targetCsvID = self.clientBattleCards:read()[targetIdx]
	local targetData= self:getCardAttrs(targetCsvID)
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
				if not targetCsvID and not self:canBattleUp() then
					--目标位置没有精灵 且上阵精灵已满
					tip = gLanguageCsv.battleCardCountEnough
				else
					self:upBattle(csvID,targetIdx)
					tip = gLanguageCsv.addToEmbattle
				end
			end
		end
	end
	if isShowTip and tip then
		gGameUI:showTip(tip)
	end
end

function BraveChallengleEmbattle:onCardClick(data, isShowTip)

	local tip
	local csvID = data.csvID
	local idx = self:getIdxByDbId(csvID)
	-- 在阵容上
	if data.battle > 0 then
		if  self:canBattleDown() then
			self:downBattle(csvID, true)
		else
			tip = gLanguageCsv.battleCannotEmpty
		end
	else

		local idx = self:getIdxByDbId(0)
		if not self:canBattleUp() then
			tip = gLanguageCsv.battleCardCountEnough
		elseif self:hasSameMarkIDCard(data) then
			tip = gLanguageCsv.alreadyHaveSameSprite
		else
			self:upBattle(csvID, idx) --上阵
		end
	end
	if isShowTip and tip then
		gGameUI:showTip(tip)
	end
end

--下阵
function BraveChallengleEmbattle:downBattle(csvID)
	self:getCardAttrs(csvID).battle = 0
	local idx = self:getIdxByDbId(csvID)
	self.clientBattleCards:modify(function(oldval)
		oldval[idx] = 0
		return true, oldval
	end, true)
end

-- 上阵
function BraveChallengleEmbattle:upBattle(csvID, idx)
	local id = self.clientBattleCards:read()[idx]
	if id ~= 0 then
		self:getCardAttrs(id).battle = 0
	end
	self.clientBattleCards:modify(function(oldval)
		oldval[idx] = csvID
		self:getCardAttrs(csvID).battle = 1
		self:getCardAttrs(csvID).isNew = false
		return true, oldval
	end, true)
end


--是否有相同markid的精灵
function BraveChallengleEmbattle:hasSameMarkIDCard(data)
	for i = 1, PANEL_NUM do
		local csvID = self.clientBattleCards:read()[i]
		if csvID ~= 0 then
			local cardData = self:getCardAttrs(csvID)
			if cardData.markId == data.markId then
				return i
			end
		end
	end
	return false
end

function BraveChallengleEmbattle:createMovePanel(data)
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



-- 刷新buf
function BraveChallengleEmbattle:refreshTeamBuff(battle, typ)

	local attrs = {}
	local csvCards = csv.brave_challenge.cards

	for i = 1, PANEL_NUM do
		local csvID = battle[i]
		if csvID and csvID ~= 0 then
			local csvCard = csvCards[csvID]
			local cardCfg = csv.cards[csvCard.cardID]
			local unitCfg = csv.unit[cardCfg.unitID]
			attrs[i] = {unitCfg.natureType, unitCfg.natureType2}
		end
	end

	local result = dataEasy.getTeamBuffBest(attrs)
	self["btnGHimg"..typ]:texture(result.buf.imgPath)

	if typ == 1 then
		self.teamSelfBuff = result
	else
		self.teamEnemyBuff = result
	end
end

function BraveChallengleEmbattle:onClickBadges(badges, idx)
	gGameUI:stackUI("city.activity.brave_challenge.badge", nil, nil, badges, idx)
end

-- 光环
function BraveChallengleEmbattle:onTeamBuffClick1()
	local teamBuffs = self.teamSelfBuff and self.teamSelfBuff.buf.teamBuffs or {}
	gGameUI:stackUI("city.card.embattle.attr_dialog",nil, {}, teamBuffs)
end

-- 光环
function BraveChallengleEmbattle:onTeamBuffClick2()
	local teamBuffs = self.teamEnemyBuff and self.teamEnemyBuff.buf.teamBuffs or {}
	gGameUI:stackUI("city.card.embattle.attr_dialog",nil, {}, teamBuffs)
end

-- 关闭或跳转前阵容变动检测和保存
function BraveChallengleEmbattle:sendRequeat(cb, isClose)
	local equality = itertools.equal(self.battleCardsData:read(), self.clientBattleCards:read())
	if not equality then
		local req = nil
		req = gGameApp:requestServerCustom(BCAdapt.url("deploy")):params(self.clientBattleCards:read(), self.id:read())
		req:onBeforeSync(cb):doit()
	else
		cb()
	end
end


-- 挑战
function BraveChallengleEmbattle:fightBtn()

	local sign = false
	for index, id in pairs(self.clientBattleCards:read()) do
		if id ~= 0 then
			sign = true
			break
		end
	end

	if not sign then
		gGameUI:showTip(gLanguageCsv.noSpriteAvailable)
		return
	end
	self:sendRequeat(function()
		self.fightCb(self, self.clientBattleCards)
	end)
end


function BraveChallengleEmbattle:getCardAttrs(csvID)
	return self.allCardDatas:atproxy(csvID)
end


return BraveChallengleEmbattle