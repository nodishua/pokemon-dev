local CardEmbattleView = require "app.views.city.card.embattle.base"
local GymChallengeEmbattleView = class("GymChallengeEmbattleView", CardEmbattleView)

GymChallengeEmbattleView.RESOURCE_FILENAME = "gym_embattle3.json"
GymChallengeEmbattleView.RESOURCE_BINDING = {
	["battlePanel"] = "battlePanel",
	["spritePanel"] = "spriteItem",
	["textNotRole"] = "emptyTxt",
	["battlePanel.ahead.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["battlePanel.back.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},

	["rightDown"] = "rightDown",
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
	["rightDown.btnOneKeySet"] = {
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
	["bottomPanel"] = "bottomPanel",

	["attrItem"] = "attrItem",
	["rightTop"] = "rightTop",
	["rightTop.textNote"] = "textNote",
	["rightTop.imgBg"] = "attrBg",
	["rightTop.arrList"] = {
		varname = "arrList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("limitInfo"),
				item = bindHelper.self("attrItem"),
				textNote = bindHelper.self("textNote"),
				attrBg = bindHelper.self("attrBg"),
				onItem = function(list, node, k, v)
					node:get("imgIcon"):texture(ui.ATTR_ICON[v])
				end,
				onAfterBuild = function(list)
					-- --右对齐
					local size = list.item:size()
					local count = csvSize(list.data)
					local width = size.width * count  + list:getItemsMargin() * (count - 1)
					list:setAnchorPoint(cc.p(1,0.5))
					list:width(width)
					list:xy(cc.p(600,50))
					adapt.oneLinePos(list, list.textNote, cc.p(0,0), "right")
					list.attrBg:width(width + list.textNote:width() + 40)
					list.attrBg:x(list.textNote:x() -40)
				end
			}
		},
	},
	["upItem"] = "upItem"
}


function GymChallengeEmbattleView:onCreate(params)
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose", false)})
		:init({title = gLanguageCsv.formation, subTitle = "FORMATION"})

	self:initDefine(params)
	self:initParams(params)
	self:initModel(params)
	self:initRoundUIPanel()
	self:initHeroSprite()
	self:initBottomList()
	self.battleCardsData:set(self:getOneKeyCardDatas())
end

function GymChallengeEmbattleView:initDefine(params)
	self.deployNum = csv.gym.gate[params.gateId].deployNum --队伍数量
	self.oneTeamNum = csv.gym.gate[params.gateId].deployCardNumLimit--单阵容精灵数量
	self.embattleMax = self.deployNum *	self.oneTeamNum		--最大可上阵数
	self.panelNum = self.deployNum * 6    --布阵底座数量
	self.gymId = params.gymId
	self.k = params.k
end

function GymChallengeEmbattleView:initParams(params)
	params = params or {}
	self.from = game.EMBATTLE_FROM_TABLE.onekey
	self.sceneType = game.SCENE_TYPE.gym
	self.fightCb = params.fightCb
	self.limitInfo = csv.gym.gate[params.gateId].deployNatureLimit
	self.checkBattleArr = params.checkBattleArr or function()
		return true
	end
end

-- 边缘UI初始化
function GymChallengeEmbattleView:initRoundUIPanel()
	adapt.centerWithScreen("left", "right", nil, {
		{self.rightDown, "pos", "right"},
		{self.rightTop, "pos", "right"},
	})
	if itertools.size(self.limitInfo) == 0 then
		self.rightTop:hide()
	end
end

function GymChallengeEmbattleView:limtFunc(dbid, card_id,skin_id, fighting_point, level, star, advance, created_time, nature_choose, inBattle)
	local hashMap = itertools.map(self.limitInfo or {}, function(k, v) return v, 1 end)
	local cardCsv = csv.cards[card_id]
	local unitCsv = csv.unit[cardCsv.unitID]
	-- csvSize(self.limitInfo) == 0 不限制
	if csvSize(self.limitInfo) == 0 or hashMap[unitCsv.natureType] or hashMap[unitCsv.natureType2] then
		return CardEmbattleView.limtFunc(self, dbid, card_id,skin_id, fighting_point, level, star, advance, created_time, nature_choose, inBattle)
	else
		return nil
	end
end

-- 一键布阵
function GymChallengeEmbattleView:getOneKeyCardDatas()
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
	local battleCards = {}
	local i = 0
	for _, v in pairs(cardDatas) do
		v = v:read()
		local cardID = self:getCardAttr(v.dbid, "card_id")
		local cardCsv = csv.cards[cardID]
		if self:embattleBtnFunc(hash, v) then
			i = i + 1
			battleCards[i] = v.dbid
			hash[cardCsv.cardMarkID] = {dbid = v.dbid, fighting_point = v.fighting_point, rarity = v.rarity}
			if i == self.oneTeamNum * self.deployNum then
				break
			end
		end
	end

	local cardNum = itertools.size(battleCards)
	local newBattleCards = {}
	local index = 0
	local notEnough = false
	for i = 1, self.deployNum do
		for j = 1, self.oneTeamNum do
			index = index + 1
			newBattleCards[6 * (i - 1) + j] = clone(battleCards[index])
			local needCount = self.deployNum - i --至少还需要多少
			local remainCount = cardNum - index  --还剩多少
			if cardNum - index == self.deployNum - i and (cardNum - index ~= 0)then
				notEnough = true
				break
			end
		end
		if notEnough == true then
			break
		end
	end
	--不足剩下的每组放一个
	if notEnough then
		for i = 1, self.deployNum do
			if not newBattleCards[6 * (i - 1) + 1] then
				index = index + 1
				newBattleCards[6 * (i - 1) + 1] = clone(battleCards[index])
			end
		end
	end
	return newBattleCards
end

-- 底部所有卡牌
function GymChallengeEmbattleView:initBottomList(  )
	self.cardListView = gGameUI:createView("city.adventure.gym_challenge.card_list3", self.bottomPanel):init({
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


-- 给界面上的精灵添加拖拽功能
function GymChallengeEmbattleView:initHeroSprite()
	self.heroSprite = {}
	--初始化精灵容器
	local intervalX = 50
	local itemWidth = self.upItem:width()
	local battleSize = self.battlePanel:size()
	local posXStart = 0
	local width = (itemWidth + intervalX) * (self.deployNum- 1)
	posXStart =  battleSize.width / 2 - width / 2

	for i = 1, self.deployNum  do
		local tmpPanel = self.upItem:clone()
			:show()
			:addTo(self.battlePanel, 2, "panel"..i)
			:xy(posXStart + (i - 1) * (itemWidth + intervalX), battleSize.height/2 + 110)
			tmpPanel:get("imgOrangeBg.textNote"):text(string.format(gLanguageCsv.unionFightTeam, gLanguageCsv["symbolNumber".. i]))
		for j = 1, 6 do
			local index = (i - 1) * 6 + j
			self.heroSprite[index] = {sprite = tmpPanel:get("panel"..j), dbid = nil, idx = index}
		end
	end


	--上阵下阵操作
	local oldBattleHash = {}
	idlereasy.when(self.clientBattleCards,function (_, battle)
		local equal = true
		local battleNum = {}
		local battles = {}
		for i = 1, self.deployNum  do
			battleNum[i] = 0
			battles[i] = {}
			for j = 1, 6 do
				local index = (i - 1) * 6 + j
				local spriteTb = self.heroSprite[index]
				local item = spriteTb.sprite
				local dbid = battle[index]
				battles[i][j] = dbid
				item:get("head"):onTouch(functools.partial(self.onBattleCardTouch, self, index))
				if dbid then
					local data = gGameModel.cards:find(dbid)
					local card_id = data:read("card_id")
					local skin_id = data:read("skin_id")
					local unitId = dataEasy.getUnitId(card_id, skin_id)
					item:get("imgEmpty"):hide()
					bind.extend(self, item:get("head"):show(), {
						class = "card_icon",
						props = {
							unitId = unitId,
							cardId = card_id,
							rarity = data:read("rarity"),
							advance = data:read("advance"),
							star = data:read("star"),
							levelProps = {
								data = data:read("level"),
							},
							onNode = function(panel)
								panel:xy(-6, -6)
							end,
						},
					})
					battleNum[i] = battleNum[i] + 1
				else
					item:get("head"):hide()
					item:get("imgEmpty"):show()
				end
				if not oldBattleHash[battle[i]] and battle[i] then
					equal = false
				end
			end
		end
		if not equal or (itertools.size(oldBattleHash) ~= battleNum) then
			oldBattleHash = itertools.map(battle, function(k, v) return v, k end)
			for i = 1, self.deployNum  do
				self.battlePanel:get("panel"..i):get("textNum"):get():text(battleNum[i] .. "/"..self.oneTeamNum)
				self:refreshTeamBuff(battles[i], i)
				self:refreshFightPoint(battles[i], i)
			end
		end
	end)
end

-- 根据布阵信息刷新队伍光环效果
function GymChallengeEmbattleView:refreshTeamBuff(battleCards, index)
	local attrs = {}
	local showBuff = true
	for i = 1, 6 do
		local dbid = battleCards[i]
		local data = self:getCardAttrs(dbid)
		if data then
			local cardCfg = csv.cards[data.card_id]
			local unitCfg = csv.unit[cardCfg.unitID]
			attrs[i] = {unitCfg.natureType, unitCfg.natureType2}
		end
	end
	if not showBuff then
		attrs = {}
	end
	local result = dataEasy.getTeamBuffBest(attrs)
	self.battlePanel:get("panel"..index):get("imgBuf"):texture(result.buf.imgPath)
end

function GymChallengeEmbattleView:refreshFightPoint(battleCards, index)
	local fightSumNum = 0
	for k,v in pairs(battleCards) do
		local fightPoint = self:getCardAttr(v, "fighting_point")
		fightSumNum = fightSumNum + fightPoint
	end
	self.battlePanel:get("panel"..index):get("textZl"):text(fightSumNum)
end


function GymChallengeEmbattleView:createMovePanel(data)
	if self.movePanel then
		self.movePanel:removeSelf()
	end
	local movePanel = self.spriteItem:clone():addTo(self:getResourceNode(), 1000)
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
	self.movePanel = movePanel
	return movePanel
end


function GymChallengeEmbattleView:onBattleCardTouch(i, event)
	local dbid = self.clientBattleCards:read()[i]
	if not dbid then
		return
	end
	local data = self:getCardAttrs(dbid)
	if event.name == "began" then
		self:createMovePanel(data)
		self.selectIndex:set(i)
		self.heroSprite[i].sprite:get("head"):hide()
		self.heroSprite[i].sprite:get("imgEmpty"):show()
		self.movePanel:xy(event.x, event.y)
	elseif event.name == "moved" then
		self:moveMovePanel(event)
	elseif (event.name == "ended" or event.name == "cancelled") then
		self.heroSprite[i].sprite:get("head"):show()
		self.heroSprite[i].sprite:get("imgEmpty"):hide()
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

function GymChallengeEmbattleView:getIdxByDbId(dbid)
	if dbid then
		for i = 1, self.panelNum do
			if self.clientBattleCards:read()[i] == dbid then
				return i
			end
		end
	end
	for k = 1, self.deployNum do
		local cardNum = 0
		local startIndex = (k - 1) * 6 + 1
		for i = startIndex, startIndex + 5 do
			if self.clientBattleCards:read()[i] then
				cardNum = cardNum + 1
			end
		end
		if cardNum < self.oneTeamNum then
			for i = startIndex, startIndex + 5 do
				if not self.clientBattleCards:read()[i] then
					return i
				end
			end
		end
	end
end

--是否跟换
function GymChallengeEmbattleView:whichEmbattleTargetPos(p)
	for i, v in pairs(self.heroSprite) do
		local item = v.sprite
		local rect = item:box()
		local pos = item:getParent():convertToWorldSpace(cc.p(rect.x, rect.y))
		rect.x, rect.y = pos.x, pos.y
		if cc.rectContainsPoint(rect, p) then
			return i
		end
	end
end

-- data 数据移动到 targetIdx 位置上，targetIdx nil 为点击
function GymChallengeEmbattleView:onCardMove(data, targetIdx, isShowTip)
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
			elseif targetBattle ~= data.battle and (self:getCardNum(targetBattle) == self.oneTeamNum and targetDbid == nil) then
				tip = gLanguageCsv.battleCardCountEnough
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
				if not targetDbid and not self:canBattleUp(targetBattle) then
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

function GymChallengeEmbattleView:canBattleDown(battle)
	local cardNum = 0
	local startIndex = (battle - 1) * 6 + 1
	for i = startIndex, startIndex + 5 do
		if self.clientBattleCards:read()[i] then
			cardNum = cardNum + 1
		end
	end
	return cardNum > 1
end

function GymChallengeEmbattleView:canBattleUp(battle)

	if battle == nil then
		for k = 1, self.deployNum do
			local cardNum = 0
			local startIndex = (k - 1) * 6 + 1
			for i = startIndex, startIndex + 5 do
				if self.clientBattleCards:read()[i] then
					cardNum = cardNum + 1
				end
			end
			if cardNum < self.oneTeamNum then
				return true
			end
		end
		return false
	else
		local cardNum = 0
		local startIndex = (battle - 1) * 6 + 1
		for i = startIndex, startIndex + 5 do
			if self.clientBattleCards:read()[i] then
				cardNum = cardNum + 1
			end
		end
		return cardNum < self.oneTeamNum
	end
end

function GymChallengeEmbattleView:getCardNum(battle)
	local cardNum = 0
	local startIndex = (battle - 1) * 6 + 1
	for i = startIndex, startIndex + 5 do
		if self.clientBattleCards:read()[i] then
			cardNum = cardNum + 1
		end
	end
	return cardNum
end

function GymChallengeEmbattleView:onClose()
	local date = gGameModel.gym:read("date")
	local battleCards = self.clientBattleCards:read()
	local battleCardsHex = {}
	for k, v in pairs(battleCards) do
		battleCardsHex[k] = stringz.bintohex(v)
	end
	local ViewBase = cc.load("mvc").ViewBase
	ViewBase.onClose(self)
end

return GymChallengeEmbattleView