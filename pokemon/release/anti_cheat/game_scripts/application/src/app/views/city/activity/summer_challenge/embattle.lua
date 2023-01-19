-- 夏日挑战布阵界面

local PANEL_NUM = 6

local ZORDER = {2, 4, 6, 1, 3, 5}

local ViewBase = cc.load("mvc").ViewBase
local CardEmbattleView = require "app.views.city.card.embattle.base"
local SummerChallengleEmbattle = class("SummerChallengleEmbattle", CardEmbattleView)

SummerChallengleEmbattle.RESOURCE_FILENAME = "summer_challenge_embattle.json"
SummerChallengleEmbattle.RESOURCE_BINDING = {
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
			methods = {ended = bindHelper.defer(function(view)
				view:onTeamBuffClick(1)
			end)}
		}
	},
	["battlePanel2.fightNote.btnGHimg"] = {
		varname = "btnGHimg2",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:onTeamBuffClick(2)
			end)}
		}
	},
}

function SummerChallengleEmbattle:onCreate(params)
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose", true)})
		:init({title = gLanguageCsv.summerChallenge, subTitle = "SUMMERCHALLENGE"})

	adapt.centerWithScreen("left", "right", nil, {
		{self.rightDown, "pos", "right"},
	})

	self:initModel()

	self.fightCb = params.fightCb
	self.gateCfg = params.gateCfg
	self.gateID = params.gateID

	self.emenyDatas = {}
	self.heroSprite = {}
	self.enemySprite = {}
	self.teamSelfBuff = {}
	self.teamEnemyBuff = {}

	self.panel = {
		{
			parent = self.leftPanel,
			list = self.heroSprite,
		},
		{
			parent = self.rightPanel,
			list = self.enemySprite,
		}
	}

	self:updateData()
	self:initSpriteItem()
	self:initEnemyUI()
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
function SummerChallengleEmbattle:initModel()
	self.clientBattleCards = idlertable.new({})
	self.battleCardsData = idlertable.new({})
	self.allCardDatas = idlers.newWithMap({})
	self.selectIndex = idler.new(0)
	self.draggingIndex = idler.new(0) -- 正在拖拽的节点的index
end

-- 精灵校验
function SummerChallengleEmbattle:checkBattleCards(battleCards)
	local defaultCards = {0, 0, 0, 0, 0, 0}
	if itertools.size(battleCards) ~= PANEL_NUM then
		return defaultCards
	end

	local deployLock = self.gateCfg.deployLock
	local autoCards = self.gateCfg.autoCards
	local cardsHash = arraytools.hash(self.gateCfg.cards)

	-- 精灵锁定校验
	for key, pos in csvMapPairs(autoCards) do
		if pos > 0 and battleCards[pos] ~= 0 and battleCards[pos] ~= key then
			battleCards[pos] = 0
		end
	end

	-- 位置锁定校验和可上阵精灵校验
	for i=1, PANEL_NUM do
		if battleCards[i] ~= 0 and (deployLock[i] == 1 or not cardsHash[battleCards[i]]) then
			battleCards[i] = 0
		end
	end

	return battleCards
end

-- 初始化数据
function SummerChallengleEmbattle:updateData()
	local cardDatas = table.deepcopy(self.gateCfg.cards)
	-- 锁定标记
	local deployLock = self.gateCfg.deployLock
	-- 可上阵数
	local battleNum = 0
	for _, v in pairs(deployLock) do
		if v == 0 then
			battleNum  = battleNum + 1
		end
	end
	self.battleNum = battleNum

	-- 自动上阵卡牌
	local autoCards = self.gateCfg.autoCards
	local hash = {}
	local tempDefaultBattleCards = {}

	local localKey = string.format("summerChallengeEmbattle%d", self.gateID)
	local defaultBattleCards = userDefault.getForeverLocalKey(localKey, {0, 0, 0, 0, 0, 0})
	-- 精灵校验
	defaultBattleCards = self:checkBattleCards(defaultBattleCards)

	local tempBattleCardsData = defaultBattleCards
	local tempClientBattleCards = defaultBattleCards

	for _, id in ipairs(defaultBattleCards) do
		hash[id] = true
	end

	local tempCards = {}
	for id, lockPos in csvPairs(autoCards) do
		if not hash[id] then
			if lockPos == 0 then
				table.insert(tempCards, id)
			else
				-- 阵容位置锁定，又强制上阵位置
				if deployLock[lockPos] == 1 then
					printError("pos(%s) was lock, gateID(%s)", lockPos, self.gateID)
				else
					tempBattleCardsData[lockPos] = id
					tempClientBattleCards[lockPos] = id
				end
			end
			hash[id] = true
		end
		table.insert(cardDatas, id)
	end

	for i=1, PANEL_NUM do
		if tempBattleCardsData[i] == 0 and deployLock[i] == 0 and tempCards[1] then
			local id = tempCards[1]
			tempBattleCardsData[i] = id
			tempClientBattleCards[i] = id
			table.remove(tempCards, 1)
		end
	end

	self.clientBattleCards:set(tempClientBattleCards)
	self.battleCardsData:set(tempBattleCardsData)

	local tempAllCardDatas = {}
	local csvCards = csv.summer_challenge.cards
	for _, csvID in pairs(cardDatas) do
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
			battle = hash[csvID] and 1 or 0,
			lock = autoCards[csvID] or -1,
			isNew = false
		}
	end
	self.allCardDatas:update(tempAllCardDatas)
end

function SummerChallengleEmbattle:showBattleNum(battle)
	local num = 0
	for index, id in pairs(battle) do
		if id ~= 0 then
			num = num + 1
		end
	end

	self.textNum:text(string.format("%d/%d", num, self.battleNum))
	adapt.oneLineCenterPos(cc.p(163, 152), {self.textNote, self.textNum}, cc.p(5, 0))
end

-- 初始化控件
function SummerChallengleEmbattle:initSpriteItem()
	-- 锁定标记
	local deployLock = self.gateCfg.deployLock

	for i = 1, 2 do
		local panel = self.panel[i].parent
		local list = self.panel[i].list
		for j = 1, PANEL_NUM do
			local item = panel:get("item"..j)
			local rect = item:box()
			local pos = item:getParent():convertToWorldSpace(cc.p(rect.x, rect.y))
			rect.x, rect.y = pos.x, pos.y
			list[j] = {item = item, rect = rect, idx = j}
			if i == 1 then
				item:get("posLockPanel"):visible(deployLock[j] == 1)
				list[j].lock = deployLock[j] == 1
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
function SummerChallengleEmbattle:initEnemyUI()
	local list = self.gateCfg.monsterIDs
	local monsterID = list[table.length(list)]
	local csvMonster = csv.summer_challenge.monsters[monsterID]
	local csvCards = csv.summer_challenge.cards

	self.emenyDatas = {}
	for index, id in csvPairs(csvMonster.cards) do
		self.emenyDatas[index] = id
	end

	for index = 1, PANEL_NUM do
		local csvID = self.emenyDatas[index]
		local spriteTb = self.enemySprite[index]
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
function SummerChallengleEmbattle:initHeroSprite(index)

	local panel = self.heroSprite[index].item
	local data = self:getCardAttrs(self.clientBattleCards:read()[index])

	if not data then
		if panel:getChildByName("sprite") then
			panel:getChildByName("sprite"):hide()
		end
		panel:get("attrBg"):hide()
		return
	end

	local csvUnit = csv.unit[data.unit_id]

	local imgBg = panel:get("imgBg")
	if panel.csvID == data.csvID and panel:getChildByName("sprite") then
		panel:getChildByName("sprite"):show()
	else
		panel:removeChildByName("sprite")
		panel:removeChildByName("lock")
		panel:removeChildByName("lock1")
		local cardSprite = widget.addAnimationByKey(panel, csvUnit.unitRes, "sprite", "standby_loop", 4)
			:scale(csvUnit.scale * (0.8+(index - 1)%3*0.1))
			:xy(imgBg:x(), imgBg:y() + 15)
		cardSprite:setSkin(csvUnit.skin)
		panel.csvID = data.csvID
		if data.lock > 0 then
			self:createLockEffect(panel, index)
		end
	end

	local spriteId = data.card_id
	local flags = self.teamSelfBuff and self.teamSelfBuff.flags or {1, 1, 1, 1, 1, 1}
	local flag = flags[index]
	uiEasy.setTeamBuffItem(panel, data.card_id, flag)
end

function SummerChallengleEmbattle:createLockEffect(parent, index)
	local offsetYTab = {-40, 0, 5, -40, 0, 5}
	local scaleTab = {1.8, 2, 2.5, 1.8, 2, 2.5}
	local effectName = "effect_hou_loop"
	local effect = widget.addAnimationByKey(parent, "summer_challenge/jld.skel", "lock", effectName, 2)
	effect:scale(scaleTab[index])
	effect:play(effectName)
	effect:xy(parent:width()/2, parent:height()/2 + offsetYTab[index])

	effectName = "effect_qian_loop"
	local effect1 = widget.addAnimationByKey(parent, "summer_challenge/jld.skel", "lock1", effectName, 50)
	effect1:scale(scaleTab[index])
	effect1:play(effectName)
	effect1:xy(parent:width()/2, parent:height()/2 + offsetYTab[index])
end

function SummerChallengleEmbattle:onBattleCardTouch(idx, event)
	if self.clientBattleCards:read()[idx] == 0 then
		return
	end
	local data = self:getCardAttrs(self.clientBattleCards:read()[idx])
	-- 锁定的精灵不能移动
	if data.lock > 0 then
		gGameUI:showTip(gLanguageCsv.cardCantMove)
		return
	end
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
function SummerChallengleEmbattle:initBottomList()
	self.cardListView = gGameUI:createView("city.card.embattle.summer_challenge_card_list", self.bottomPanel):init({
		base = self,
		clientBattleCards = self.clientBattleCards,
		battleCardsData = self.battleCardsData,
		-- selectIndex = self.selectIndex,
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

function SummerChallengleEmbattle:canBattleDown()
	return self.clientBattleCards:size() > 1
end

function SummerChallengleEmbattle:canBattleUp()
	local sum = 0
	for index, data in self.clientBattleCards:pairs() do
		if data > 0 then
			sum = sum + 1
		end
	end
	return sum < self.battleNum
end

--重载
function SummerChallengleEmbattle:whichEmbattleTargetPos(pos)
	-- 精灵交互区域可以存在覆盖，从最前面开始
	for i = PANEL_NUM, 1, -1 do
		local rect = self.heroSprite[i].rect
		if cc.rectContainsPoint(rect, pos) then
			return i
		end
	end
end

function SummerChallengleEmbattle:deleteMovingItem()
	self.selectIndex:set(0)
	if self.movePanel then
		self.movePanel:removeSelf()
		self.movePanel = nil
	end
	self.draggingIndex:set(0)
end

function SummerChallengleEmbattle:moveMovePanel(event)
	if self.movePanel then
		self.movePanel:xy(event)
		self.selectIndex:set(self:whichEmbattleTargetPos(event))
	end
end

function SummerChallengleEmbattle:moveEndMovePanel(data)
	if not self.movePanel then
		return
	end
	local index = self.selectIndex:read()
	self:onCardMove(data, index, true)
	self:deleteMovingItem()
end

function SummerChallengleEmbattle:isMovePanelExist()
	return self.movePanel ~= nil
end

--判断点击的精灵是否已上阵
function SummerChallengleEmbattle:getIdxByDbId(csvID)
	for i = 1,  PANEL_NUM do
		local id = self.clientBattleCards:read()[i] or 0
		if id == csvID then
			return i
		end
	end
end

-- data 数据移动到 targetIdx 位置上，targetIdx nil 为点击
function SummerChallengleEmbattle:onCardMove(data, targetIdx, isShowTip)
	local tip
	local csvID = data.csvID
	local idx = self:getIdxByDbId(csvID)
	local targetCsvID = self.clientBattleCards:read()[targetIdx]
	local targetData = self:getCardAttrs(targetCsvID)
	local battle = (idx == nil) and 0 or 1
	if targetIdx then
		-- 锁定的位置不能放置精灵
		if self.gateCfg.deployLock[targetIdx] == 1 then
			gGameUI:showTip(gLanguageCsv.posLock)
			return
		end
		if data.battle > 0 then
			-- 锁定的精灵不能移动
			if targetData and targetData.lock > 0 then
				gGameUI:showTip(gLanguageCsv.cardCantMove)
				return
			end
			-- 在阵容上 互换
			self.clientBattleCards:modify(function(oldval)
				oldval[idx], oldval[targetIdx] = oldval[targetIdx], oldval[idx]
				return true, oldval
			end, true)
		else
			-- 锁定的精灵不能下阵
			if targetData and targetData.lock >= 0 then
				gGameUI:showTip(gLanguageCsv.cardCantDown)
				return
			end
			local commonIdx = self:hasSameMarkIDCard(data)
			if commonIdx and commonIdx ~= targetIdx then
				tip = gLanguageCsv.alreadyHaveSameSprite
			else
				if not targetCsvID and not self:canBattleUp() then
					--目标位置没有精灵 且上阵精灵已满
					tip = gLanguageCsv.battleCardCountEnough
				else
					self:upBattle(csvID, targetIdx)
					tip = gLanguageCsv.addToEmbattle
				end
			end
		end
	end
	if isShowTip and tip then
		gGameUI:showTip(tip)
	end
end

function SummerChallengleEmbattle:onCardClick(data, isShowTip)
	local tip
	local csvID = data.csvID
	local idx = self:getIdxByDbId(csvID)
	-- 在阵容上
	if data.battle > 0 then
		-- 锁定的精灵不能下阵
		if data.lock >= 0 then
			gGameUI:showTip(gLanguageCsv.cardCantDown)
			return
		end
		if self:canBattleDown() then
			self:downBattle(csvID, true)
		else
			tip = gLanguageCsv.battleCannotEmpty
		end
	else
		-- 获取下个可上阵位置
		local idx = self:getBattleIdx()--self:getIdxByDbId(0)
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

-- 获取下个可上阵位置
function SummerChallengleEmbattle:getBattleIdx()
	for i = 1,  PANEL_NUM do
		local id = self.clientBattleCards:read()[i] or 0
		if id == 0 and self.gateCfg.deployLock[i] == 0 then
			return i
		end
	end
end

--下阵
function SummerChallengleEmbattle:downBattle(csvID)
	self:getCardAttrs(csvID).battle = 0
	local idx = self:getIdxByDbId(csvID)
	self.clientBattleCards:modify(function(oldval)
		oldval[idx] = 0
		return true, oldval
	end, true)
end

-- 上阵
function SummerChallengleEmbattle:upBattle(csvID, idx)
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
function SummerChallengleEmbattle:hasSameMarkIDCard(data)
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

function SummerChallengleEmbattle:createMovePanel(data)
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
function SummerChallengleEmbattle:refreshTeamBuff(battle, typ)

	local attrs = {}
	local csvCards = csv.summer_challenge.cards

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

-- 光环
function SummerChallengleEmbattle:onTeamBuffClick(type)
	local teamBuffs = {
		[1] = self.teamSelfBuff and self.teamSelfBuff.buf.teamBuffs or {},
		[2] = self.teamEnemyBuff and self.teamEnemyBuff.buf.teamBuffs or {},
	}
	gGameUI:stackUI("city.card.embattle.attr_dialog",nil, {}, teamBuffs[type])
end

-- 关闭或跳转前阵容变动检测和保存
function SummerChallengleEmbattle:sendRequeat(cb)
	local localKey = string.format("summerChallengeEmbattle%d", self.gateID)
	userDefault.setForeverLocalKey(localKey, self.clientBattleCards:read(), {new = true})
	cb()
end

-- 挑战
function SummerChallengleEmbattle:fightBtn()

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


function SummerChallengleEmbattle:getCardAttrs(csvID)
	return self.allCardDatas:atproxy(csvID)
end

function SummerChallengleEmbattle:onClose()
	self:sendRequeat(function()
		ViewBase.onClose(self)
	end)
end

return SummerChallengleEmbattle