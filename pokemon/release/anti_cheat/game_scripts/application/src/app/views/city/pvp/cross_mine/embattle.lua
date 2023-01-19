--公会战布阵界面
local ViewBase = cc.load("mvc").ViewBase
local CardEmbattleView = require "app.views.city.card.embattle.base"
local CrossMineEmbattleView = class("CrossMineEmbattleView", CardEmbattleView)

--做多上阵12张卡牌
local CARD_MAX = 12
local CARD_UP_MAX = 4

local PANEL_POS = {[1] = {cc.p(630,425),cc.p(1350,425)}, [2] = {cc.p(500,425),cc.p(1140,425),cc.p(1780,425)}}

local PANEL_IMG = {
	[1] =
	{
		"city/pvp/cross_mine/txt_red_1st.png",
		"city/pvp/cross_mine/txt_red_2nd.png",
		"city/pvp/cross_mine/txt_red_3rd.png"
	},
	[2] =
	{
		"city/pvp/cross_mine/txt_blue_1st.png",
		"city/pvp/cross_mine/txt_blue_2nd.png",
		"city/pvp/cross_mine/txt_blue_3rd.png"
	},
}

CrossMineEmbattleView.RESOURCE_FILENAME = "cross_mine_embattle.json"
CrossMineEmbattleView.RESOURCE_BINDING = {
	["rightDown"] = "rightDown",
	["rightDown.btnOneKeySet"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("oneKeyEmbattleBtn")}
		},
	},
	["bottomPanel"] = "bottomPanel",
	["upPosition"] = "upPosition",
	["movecard"] = "movecard",
	["battlePanel"] = "battlePanel",
	["btnFight"] = {
		varname = "btnFight",
		binds = {
			event = "touch",
			clicksafe = true,
			methods = {ended = bindHelper.self("onbtnFight")}
		}
	},
	["btnGuard"] = {
		varname = "btnGuard",
		binds = {
			event = "touch",
			clicksafe = true,
			methods = {ended = bindHelper.self("onbtnGuard")}
		}
	},
	["movePanel"] = "movePanelCell",
	["battlePanel.movePanelDi"] = "movePanelLast"
}
CrossMineEmbattleView.RESOURCE_STYLES = {
	full = true,
}

function CrossMineEmbattleView:onCreate()
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.formation, subTitle = "FORMATION"})

	adapt.centerWithScreen("left", "right", nil, {
		{self.rightDown, "pos", "right"},
	})
	self.heroSprite = {}
	self.panelTab = {}

	self:initUI()
	self:initModel()
	self.showTab = idler.new(1)


	self.battle =
	{
		{
			name = "cards",
			data = self.attackCardData,
			sign = "cards",
		},
		{
			name = "defenceCards",
			data = self.defenceCardData,
			sign = "defence_cards"
		}
	}

	self:initBottomList()
	self:initAllCards()
	self.showTab:addListener(function(val, oldval)
		self:updateData(val)
		self:initShowTab(val)
	end)

	idlereasy.when(self.clientBattleCards, function (_, battle)
		for index, data in ipairs(battle) do
			self:initHeroSprite(index)
		end
	end)

end

function CrossMineEmbattleView:initModel()
	self.cards = gGameModel.role:getIdler("cards")
	self.clientBattleCards = idlertable.new({{}, {},{}})
	self.battleCardsData = idlertable.new({})
	self.allCardDatas = idlers.newWithMap({})
	self.selectIndex = idlertable.new({})
end

function CrossMineEmbattleView:updateData(val)
	local tempData = gGameModel.cross_mine:read("record")[self.battle[val].sign]

	local battleCards = {{}, {}, {}}
	for k1, v1 in pairs(tempData) do
		for k2, data in pairs(v1) do
			battleCards[k1] = battleCards[k1] or {}
			battleCards[k1][k2] = data
		end
	end

	self.battleCardsData:set(battleCards)
	self.clientBattleCards:set(battleCards)
end

function CrossMineEmbattleView:initShowTab(val)
	local sign = val == 1
	self.btnFight:get("img"):texture(sign and "city/pvp/cross_mine/btn_kfzy1@.png" or "city/pvp/cross_mine/btn_kfzy2@.png" )
	self.btnGuard:get("img"):texture(sign and "city/pvp/cross_mine/btn_kfzy2@.png" or "city/pvp/cross_mine/btn_kfzy1@.png" )

	local color1 =  ui.COLORS.NORMAL.WHITE
	local color2 =  ui.COLORS.NORMAL.RED
	local size1 = matchLanguage({"kr"}) and 44 or 54
	local size2 = matchLanguage({"kr"}) and 36 or 48
	local colorPanel = ui.COLORS.OUTLINE.ORANGE
	local imgPath = "city/pvp/cross_mine/img_jg_bg.png"

	if not sign then
		color1 = ui.COLORS.NORMAL.RED
		color2 = ui.COLORS.NORMAL.WHITE
		size1 = matchLanguage({"kr"}) and 36 or 48
		size2 = matchLanguage({"kr"}) and 44 or 54
		imgPath = "city/pvp/cross_mine/ing_fs_bg.png"
		colorPanel = ui.COLORS.OUTLINE.BLUE
	end

	text.addEffect(self.btnFight:get("txt"), {size = size1, color = color1})
	text.addEffect(self.btnGuard:get("txt"), {size = size2, color = color2})
	for index = 1,3 do
		local childs  = self.panelTab[index]:multiget("imgRank","imgBg","textInfo01", "textFight")
		childs.imgBg:texture(imgPath)
		-- text.addEffect(childs.textInfo02, {outline = {color=colorPanel}})
		childs.imgRank:texture(PANEL_IMG[val][index])
		text.addEffect(childs.textInfo01, {outline = {color=colorPanel}})
		text.addEffect(childs.textFight, {outline = {color=colorPanel}})
	end
end

function CrossMineEmbattleView:initUI()
	self.upPosition:visible(false)

	local dx, dy = adapt.dockWithScreen(self.btnGuard, "left", nil, true)
	adapt.dockWithScreen(self.btnFight, "left", nil, true)
	dx = dx/2
	self.btnGuard:x(self.btnGuard:x() - dx)
	self.btnFight:x(self.btnFight:x() - dx)

	for k=1, 3 do
		local panel = self.upPosition:clone():addTo(self.battlePanel, 999, "name"..k)
		panel:xy(PANEL_POS[2][k])
		panel:visible(true)

		self.panelTab[k] = panel
	end
	local dot = math.abs(dx)/2+40
	local x = self.panelTab[2]:x()
	adapt.oneLineCenterPos(cc.p(1410+math.abs(dx)/4, 425), {self.panelTab[1],self.panelTab[2],self.panelTab[3]}, cc.p(dot, 0))
end


-- 初始化所有cards
function CrossMineEmbattleView:initAllCards()
	local oneKeyAllCards = {}
	for index, data in self.allCardDatas:pairs() do
		table.insert(oneKeyAllCards, data:read())
		data:proxy().battle = 0
	end

	for index,  tempList in ipairs(self.clientBattleCards:read()) do
		for _, data in pairs(tempList) do
			self.allCardDatas:atproxy(data).battle = index
		end
	end

	-- -- 保存一键上阵的卡牌信息
	table.sort(oneKeyAllCards, function(a, b)
		if a.fighting_point ~= b.fighting_point then
			return a.fighting_point > b.fighting_point
		end
		return a.rarity > b.rarity
	end)
	self.oneKeyCards = {}
	local oneKeyHash = {}
	local count = 0
	local temp = {}
	for _, v in ipairs(oneKeyAllCards) do
		if not oneKeyHash[v.markId] then
			oneKeyHash[v.markId] = true
			if count%CARD_UP_MAX == 0  then
				if count >= CARD_UP_MAX then
					table.insert(self.oneKeyCards,temp)
				end
				temp = {}
			end
			table.insert(temp, v.dbid)
			count = count + 1
			if count == CARD_MAX then
				break
			end
		end
	end
	if #temp > 0 then
		table.insert(self.oneKeyCards,temp)
	end
end

-- 初始化界面
function CrossMineEmbattleView:initHeroSprite(index)
	self.heroSprite[index] = {}
	local unitCsv,unitId,cfg
	local fighting = 0
	local cardNum = 0
	local tab = self.clientBattleCards:read()[index]
	local panel = self.panelTab[index]

	for k1 = 1, 6 do
		local item = panel:get("icon"..k1)
		local bgIcon = panel:get("bgIcon0"..k1)
		local cardData = self:getCardAttrs(tab[k1])
		if cardData then

			cardNum  = cardNum + 1
			fighting = fighting +cardData.fighting_point

			cfg      = csv.cards[cardData.card_id]
			unitCsv  = csv.unit[cfg.unitID]
			bind.extend(self, item, {
				class = "card_icon",
				props = {
					unitId = cardData.unit_id,
					rarity = unitCsv.rarity,
					advance = cardData.advance,
					star = cardData.star,
					levelProps = {
						data = cardData.level,
					},
				}
			})
			item:show()
			bgIcon:hide()
		else
			item:hide()
			bgIcon:show()
		end
		item:onTouch(functools.partial(self.onBattleCardTouch, self, index, k1))
		self.heroSprite[index][k1] = {}
		self.heroSprite[index][k1] = {sprite = item, dbid = cardData and cardData.dbid or nil, markId = cfg and cfg.cardMarkID or nil}

	end
	panel:onTouch(functools.partial(self.onBattlePanelTouch, self, index))
	panel:get("textCount"):text(cardNum..'/'..CARD_UP_MAX)
	panel:get("textFight"):text(fighting)
	adapt.oneLineCenterPos(cc.p(300, 60), {panel:get("textInfo01"), panel:get("textFight")}, cc.p(6, 0))
end


-- 底部所有卡牌
function CrossMineEmbattleView:initBottomList( )
	self.cardListView = gGameUI:createView("city.card.embattle.cross_mine_card_list", self.bottomPanel):init({
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

-- move时创建item
function CrossMineEmbattleView:createMovePanel(data)
	if not data then return end
	if not gGameModel.cards:find(data.dbid) then return end
	if self.moveItem then
		self.moveItem:removeSelf()
	end
	local movePanel = self.movecard:clone():addTo(self:getResourceNode(), 1000)
	movePanel:scale(0.9)
	self.moveItem = movePanel
	return self:itemSkin(movePanel, data.dbid)
end

-- move时创建item
function CrossMineEmbattleView:deleteMovingItem()
	self.selectIndex:set({0, 0})
	if self.moveItem then
		self.moveItem:removeSelf()
		self.moveItem = nil
	end
end

function CrossMineEmbattleView:moveMovePanel(event)
	if self.moveItem then
		self.moveItem:xy(event)
		local dbid, site1, site2 = self:whichEmbattleTargetPos(event)
		self.selectIndex:set({site1, site2})
	end
end

function CrossMineEmbattleView:isMovePanelExist()
	return self.moveItem ~= nil
end

function CrossMineEmbattleView:moveEndMovePanel(data)
	if not self.moveItem then
		return
	end
	local index = self.selectIndex:read()
	if index[1] and index[2] then
		self:resetBattle(index[1], index[2],  data)
	end
	self:deleteMovingItem()
end

function CrossMineEmbattleView:onBattleCardTouch(k, k1, event)

	local dbid = self.clientBattleCards:read()[k][k1]
	local dbidInfo = self:getCardAttrs(dbid)
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

--是否跟换panel
function CrossMineEmbattleView:getDistance(index, p)
	local x,y = self.panelTab[index]:xy()
	local pos = self.panelTab[index]:getParent():convertToWorldSpace(cc.p(x, y))
	return cc.p(p.x - pos.x , p.y - pos.y)
end

-- move时创建item
function CrossMineEmbattleView:createMovePanelBlock(index,p)
	if self.movePanel then
		self.movePanel:removeSelf()
	end
	self.distance = self:getDistance(index, p)
	self.selectPanelIndex = index

	local movePanel = self.movePanelCell:clone():addTo(self:getResourceNode(), 1000)
	self.movePanel = movePanel
	local size = self.movePanelCell:size()
	local clonePanel = self.panelTab[index]:clone():addTo(movePanel):alignCenter(size)
	local showTab = self.showTab:read()
	local sign = showTab == 1

	clonePanel:get("imgBg"):texture( sign and "city/pvp/cross_mine/img_jg_bg.png" or  "city/pvp/cross_mine/ing_fs_bg.png")
	clonePanel:get("imgRank"):texture(PANEL_IMG[showTab][index])

	self.movePanel:xy(cc.p(p.x - self.distance.x, p.y - self.distance.y))

	self.panelTab[index]:hide()
	self.movePanelLast:xy(self.panelTab[index]:xy())
	self.movePanelLast:get("imgBg"):texture( sign and "city/pvp/cross_mine/img_jg_bg.png" or  "city/pvp/cross_mine/ing_fs_bg.png")
	self.movePanelLast:show()

	return movePanel

end

-- move时创建item
function CrossMineEmbattleView:deleteMovingPanelBlock()
	if self.movePanel then
		self.movePanel:removeSelf()
		self.movePanel = nil
	end

	if self.selectPanelIndex then
		self.panelTab[self.selectPanelIndex]:show()
		self.movePanelLast:hide()
		self.selectPanelIndex = nil
	end
end

function CrossMineEmbattleView:moveMovePanelBlock(event)

	if self.movePanel then
		self.movePanel:xy(cc.p(event.x - self.distance.x, event.y - self.distance.y))
	end
end

function CrossMineEmbattleView:isMovePanelBlockExist()
	return self.movePanel ~= nil
end


function CrossMineEmbattleView:onBattlePanelTouch(k, event)
	if event.name == "began" then
		self.moved = false
		self:createMovePanelBlock(k, event)
	elseif event.name == "moved" then
		self.moved = true
		self:moveMovePanelBlock(event)
	elseif (event.name == "ended" or event.name == "cancelled") then

		self:deleteMovingPanelBlock()

		if not k then
			return
		end

		local k2 = self:whichPanelTargetPos(event)
		if k2 then
			self.clientBattleCards:modify(function(oldval)
				for index =1, 6 do
					if oldval[k][index] then
						self.allCardDatas:atproxy(oldval[k][index]).battle = k2
					end
					if oldval[k2][index] then
						self.allCardDatas:atproxy(oldval[k2][index]).battle = k
					end
				end

				oldval[k], oldval[k2] = oldval[k2], oldval[k]
				return true, oldval
			end, true)
		end

		-- self:deleteMovingPanelBlock()
	end
end



-- 一键布阵
function CrossMineEmbattleView:oneKeyEmbattleBtn()
	if not self.clientBattleCards:read() then
		return
	end

	if itertools.equal(self.oneKeyCards, self.clientBattleCards:read()) then
		gGameUI:showTip(gLanguageCsv.embattleNotChange)
		return
	end
	for i = 1, 3 do
		for j = 1,6 do
			local dbid = self.clientBattleCards:read()[i][j]
			if dbid then
				self:getCardAttrs(dbid).battle = 0
			end
		end
	end

	for i = 1, 3 do
		for j = 1,6 do
			local dbidUp = self.oneKeyCards[i][j]
			if dbidUp then
				self:getCardAttrs(dbidUp).battle = i
			end
		end
	end

	self.clientBattleCards:set(clone(self.oneKeyCards), true)

	gGameUI:showTip(gLanguageCsv.oneKeySuccess)
end

-- 点击卡牌，上阵或下阵
function CrossMineEmbattleView:onCardClick(data, isShowTip)

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

--是否跟换panel
function CrossMineEmbattleView:whichPanelTargetPos(p)
	for i,panel in pairs(self.panelTab) do
		local rect = panel:box()
		local pos = panel:getParent():convertToWorldSpace(cc.p(rect.x, rect.y))
		rect.x, rect.y = pos.x, pos.y
		if cc.rectContainsPoint(rect, p) then
			return i
		end
	end

	return nil
end

--是否跟换
function CrossMineEmbattleView:whichEmbattleTargetPos(p)
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

--move时给item穿上衣服
function CrossMineEmbattleView:itemSkin(item, dbid, star)
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

--统计上阵数量
function CrossMineEmbattleView:spriteNumber(dbid)
	--itemNum上阵数量，itemNumAll总共的位置
	local itemNum, downBattle, itemNumAll = 0, 0, 0
	local downBattleK

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
	return downBattle, itemNum, CARD_MAX, downBattleK
end

--下阵
function CrossMineEmbattleView:downHero(dbid, isShowTip)
	if dbid then
		if self.allCardDatas:atproxy(dbid) then
			self.allCardDatas:atproxy(dbid).battle = 0
		end
		local k1, k2 = self:getIdxByDbId(dbid)
		self.clientBattleCards:modify(function(showDatas)
			showDatas[k1][k2] = nil
			return true, showDatas
		end)

		if isShowTip then
			gGameUI:showTip(gLanguageCsv.downToEmbattle)
		end
	end
end


--判断点击的精灵是否已上阵
function CrossMineEmbattleView:getIdxByDbId(dbid)
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
--点击上阵
--isShowTip是true是拖动的，false是点击
function CrossMineEmbattleView:upHero(dbid, isShowTip, k1, k2)
	--点击补位上阵时判断上阵数量
	local upArrayFunc = function(k)

		local downBattle = 0
		for i,v in pairs(self.heroSprite[k]) do
			if v.dbid then
				downBattle = downBattle + 1
			end
		end
		if CARD_UP_MAX <= downBattle then
			return false
		end
		return true
	end

	--判断是点击还是拖动(点击部位)
	--已经排除个数和同属性
	local idx1, idx2
	local flag = false
	-- local itemLength =3
	--组装数据
	if not isShowTip then
		for i=1,6 do
			for k=1, 3 do
				if not self.clientBattleCards:read()[k][i] and not flag then
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
			self.allCardDatas:atproxy(dbid).battle = idx1
		end

		oldval[idx1][idx2] = dbid

		return true, oldval
	end, true)
	audio.playEffectWithWeekBGM("formation.mp3")
	gGameUI:showTip(gLanguageCsv.addToEmbattle)
	-- self:initHeroSprite()
end

--拖动上阵判断人数是否达到
function CrossMineEmbattleView:cardNumberFunc(idx)
	local existNum = 0
	for k,v in pairs(self.heroSprite[idx]) do
		if v.dbid then
			existNum = existNum + 1
		end
	end
	if existNum >= CARD_UP_MAX then
		return false
	end
	return true
end


--判断上下交换的精灵是否是相同cardMarkID
function CrossMineEmbattleView:equalCardMarkView(id1, id2)
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

--dbid1自己dbid2要交换的卡牌
-- site1, site2表示将拖到的位置(site1:队伍， site2具体位置)
function CrossMineEmbattleView:changeHero(dbid1, dbid2, site1, site2)
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
		for k,v in pairs(self.heroSprite[site1]) do
			if v.dbid then
				battleNumer = battleNumer + 1
			end
		end
		if battleNumer == CARD_UP_MAX and dataK ~= site1 then
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
		if self.allCardDatas:atproxy(showDatas[x1][y1]) then
			self.allCardDatas:atproxy(showDatas[x1][y1]).battle = x1
		end

		if self.allCardDatas:atproxy(showDatas[x2][y2]) then
			self.allCardDatas:atproxy(showDatas[x2][y2]).battle = x2
		end

		-- self:initHeroSprite()
		return true, showDatas
	end)
end

function CrossMineEmbattleView:resetBattle(idx1, idx2, data)
	local dbid = self.clientBattleCards:read()[idx1][idx2]
	-- print_r(data)
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

function CrossMineEmbattleView:onClose()
	self:sendRequeat(functools.partial(ViewBase.onClose, self), true)
end


--相同和属性
function CrossMineEmbattleView:hasSameMarkIDCard(card_id)
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

-- 卡牌过滤 待继承
function CrossMineEmbattleView:limtFunc(dbid, card_id, skin_id, fighting_point, level, star, advance, created_time, nature_choose, inBattle)

	-- print("CrossMineEmbattleView limtFunc",card_id,inBattle)
	local cardCsv = csv.cards[card_id]
	local unitCsv = csv.unit[cardCsv.unitID]

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
function CrossMineEmbattleView:sendRequeat(cb, isClose)

	local battleCards = self.battleCardsData:read()
	local clientCards = self.clientBattleCards:read()

	local equality = itertools.equal(battleCards, clientCards)

	if not equality then
		local battleCards = {}
		for i =  1, 3 do
			for j = 1, 6 do
				local count = (i -1)*6 + j
				battleCards[count] = clientCards[i][j]
			end
		end
		local tab =  self.showTab:read()
		gGameApp:requestServer("/game/cross/mine/battle/deploy", function(data)
				if isClose then
					ViewBase.onClose(self)
				else
					cb()
				end
		end, tab == 1 and battleCards or nil, tab == 2 and battleCards or nil)
		return
	else
		cb()
	end
end

function CrossMineEmbattleView:onBtnChange(val)
	if val == self.showTab:read() then
		return
	end

	self:sendRequeat(function() end, false)
	self.showTab:set(val)
end

function CrossMineEmbattleView:onbtnFight()
	self:onBtnChange(1)
end

function CrossMineEmbattleView:onbtnGuard()
	self:onBtnChange(2)
end


return CrossMineEmbattleView