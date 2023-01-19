--公会战布阵界面
local ViewBase = cc.load("mvc").ViewBase
local CrossMineLineUpView = class("CrossMineLineUpView", ViewBase)

--做多上阵12张卡牌
local CARD_MAX = 12

local PANEL_POS = {[1] = {cc.p(814,780),cc.p(442,780),cc.p(70,780)},[2] = {cc.p(1390,780),cc.p(1762,780),cc.p(2134,780)}}
local PANEL_IMG = {[2] =
	{
		"city/pvp/cross_mine/txt_blue_1st.png",
		"city/pvp/cross_mine/txt_blue_2nd.png",
		"city/pvp/cross_mine/txt_blue_3rd.png"
	},
	[1] =
	{
		"city/pvp/cross_mine/txt_red_1st.png",
		"city/pvp/cross_mine/txt_red_2nd.png",
		"city/pvp/cross_mine/txt_red_3rd.png"
	}
}

CrossMineLineUpView.RESOURCE_FILENAME = "cross_mine_lineup_adjust.json"
CrossMineLineUpView.RESOURCE_BINDING = {
	["btnChallenge"] = {
		varname = "btnChallenge",
		binds = {
			event = "touch",
			clicksafe = true,
			methods = {ended = bindHelper.self("onBtnChallenge")}
		},
	},

	["upPosition"] = "upPosition",
	["left"] = "left",
	["left.txt"] = {
		binds =
		{
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.ORANGE}},
		}
	},
	["right"] = "right",
	["right.txt"] = {
		binds =
		{
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.BLUE}},
		}
	},
	["movecard"] = "movecard",
	["battlePanel"] = "battlePanel",
	["movePanel"] = "movePanelCell",
	["img01"] = "imgLeft",
	["img02"] = "imgRight",
	["panelBuff"] = "panelCell",
	["imgGlod"] = "imgGlod",
	["txtGetNum"] = "txtGetNum",
	["battlePanel.movePanelLast"] = "movePanelLast",
	["txtGlod"] = "txtGlod",
	["txtRankRes"] = "txtRankRes",
	["panelDot"] = "panelDot",
	["panelDot.imgSign"] = "imgSign",
	["panelDot.txtDot"] = "txtDot",
}
CrossMineLineUpView.RESOURCE_STYLES = {
	full = true,
}

function CrossMineLineUpView:onCreate(enemyInfo, params)
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.formation, subTitle = "FORMATION"})

	self.enemyInfo = enemyInfo
	self.fightCb = params.fightCb
	self.isRevenge = params.isRevenge
	self.heroSprite = {}
	self.panelSelf = {}
	self.panelOther = {}
	self.selfBuffDatas = {}
	self.otherBuffDatas = {}


	self:initUI()
	self:initEnemyInfo()
	self:initModel()

	self.buffPanel =
	{
		{
			data = self.killBoss,
			parent = self.left,
			pos = {cc.p(350,50),cc.p(490,50),cc.p(630,50)}
		},
		{
			data = self.enemyInfo.killBoss,
			parent = self.right,
			pos = {cc.p(-40,50),cc.p(-180,50),cc.p(-320,50)}
		}
	}

	self:initBuff()


	idlereasy.when(self.clientBattleCards, function (_, battle)
		for index, data in ipairs(battle) do
			self:initHeroSprite(index)
		end
	end)

	local x,y = self.btnChallenge:xy()

	self.txtGetNum:text("+"..self.enemyInfo.canRobNum)
	adapt.oneLineCenterPos(cc.p(x, y + 170), {self.txtGlod, self.imgGlod, self.txtGetNum}, cc.p(10, 0))

	local csvRank = csv.cross.mine.rank
	local myspeed =  csvRank[self.role:read().rank].minuteCoin13 *60
	local enemySpeed = csvRank[self.enemyInfo.rank].minuteCoin13 *60

	local dot = enemySpeed - myspeed
	if dot < 0 or self.isRevenge then
		local richText = rich.createByStr(string.format(gLanguageCsv.gameMineRobTip2), 50)
			:addTo(self:getResourceNode(), 100, "tip")
			:anchorPoint(0.5, 0.5)
			:xy(cc.p(x, y + 98))
			:formatText()
	else
		self.txtRankRes:show()
		self.panelDot:show()

		self.txtRankRes:text(string.format(gLanguageCsv.gameMineRobTip, myspeed))
		self.txtDot:text(string.format(gLanguageCsv.crossMinePVPSpeed02,dot))
		adapt.oneLineCenterPos(cc.p(x, y + 98), {self.txtRankRes, self.panelDot}, cc.p(20, 0))
	end
end

function CrossMineLineUpView:initModel()
	self.cards = gGameModel.role:getIdler("cards")
	self.clientBattleCards = idlertable.new({{}, {},{}})
	self.battleCardsData = idlertable.new({})
	self.selectIndex = idlertable.new({})
	self.role = gGameModel.cross_mine:getIdler("role")

	local tempData = gGameModel.cross_mine:read("record").cards
	self.killBoss = gGameModel.cross_mine:read("killBoss")

	local battleCards = {{}, {}, {}}
	for k1, v1 in pairs(tempData) do
		for k2, data in pairs(v1) do
			battleCards[k1] = battleCards[k1] or {}
			battleCards[k1][k2] = data
		end
	end
	self.battleCardsData:set(table.deepcopy(battleCards, true))
	self.clientBattleCards:set(battleCards)
end

function CrossMineLineUpView:initBuff()
	for index = 1, 2 do
		local panel = self.buffPanel[index]
		local datas = {}
		for id, info in pairs(panel.data) do
			local cfg = csv.cross.mine.boss[info.csv_id]
			local countTime = cfg.buffTime*60 + info.time - time.getTime()
			if countTime > 0 then
				table.insert(datas, {bossID = bossID, info = info, cfg = cfg, time = countTime})
			end
		end

		for k, v in pairs(datas) do
			local item = self.panelCell:clone():addTo(panel.parent)
			item:show()
			item:xy(panel.pos[k])
			item:get("img"):texture(v.cfg.buffIcon)
			item:setEnabled(true)
			bind.touch(self, item, {methods = {ended = functools.partial(self.onBtnBuffPanel,self,item, v, k)}})
		end
	end

end

-- 初始化界面
function CrossMineLineUpView:initUI()
	self.upPosition:visible(false)
	local panelS = {
		self.panelSelf,
		self.panelOther,

	}

	local dL = adapt.dockWithScreen(self.left, "left", nil, true)
	local dR = adapt.dockWithScreen(self.right, "right", nil, true)
	dL = dL*0.5
	dR = dR*0.5
	self.left:x(self.left:x() - dL)
	self.right:x(self.right:x() - dR)

	local imgPath = "city/pvp/cross_mine/ing_df_bg.png"
	local color = ui.COLORS.OUTLINE.ORANGE
	local imgX = 289
	local txtX = 67
	local dot = dL

	for index = 1, 2 do
		if index == 2 then
			 imgPath = "city/pvp/cross_mine/ing_wf_bg.png"
			 color = ui.COLORS.OUTLINE.BLUE
			 dot = dR
			 imgX = 81
			 txtX = 303
		end

		for k=1, 3 do
			local panel = self.upPosition:clone():addTo(self.battlePanel, 999, "name"..k)
				:xy(PANEL_POS[index][k])
				:visible(true)

			local childs = panel:multiget("imgBg","imgRank","textInfo01","textFight","textCount")

			childs.imgRank:x(imgX)
			childs.textCount:x(txtX)

			childs.imgBg:texture(imgPath)
			text.addEffect(childs.textInfo01, {outline = {color=color}})
			text.addEffect(childs.textFight, {outline = {color=color}})
			childs.imgRank:texture(PANEL_IMG[index][k])

			panelS[index][k] = panel
			adapt.dockWithScreen(panel, index == 1 and "left" or "right", nil, true)
			panel:x(panel:x() - dot)
		end
	end
	local x1 = self.panelSelf[2]:x()
	local x2 = self.panelOther[2]:x()
	adapt.oneLineCenterPos(cc.p(x1+180, 740), {self.panelSelf[3],self.panelSelf[2],self.panelSelf[1]}, cc.p(12+math.abs(dL)*0.2, 0))
	adapt.oneLineCenterPos(cc.p(x2+180, 740), {self.panelOther[1],self.panelOther[2],self.panelOther[3]}, cc.p(12+math.abs(dR)*0.2, 0))
end

-- 设置敌方信息
function CrossMineLineUpView:initEnemyInfo()
	local unitCsv,unitId,cardCfg
	local fighting = 0
	local cardNum = 0

	for i = 1, 3 do
		local panel = self.panelOther[i]
		fighting = 0
		cardNum = 0
		for j = 1, 6 do
			local item = panel:get("icon0"..j)
			local bgIcon = panel:get("bgIcon0"..j)
			local id = self.enemyInfo.defence_cards[i][j]
			if id then
				local cardData = self.enemyInfo.defence_card_attrs[id]

				cardNum  = cardNum + 1
				fighting = fighting +cardData.fighting_point

				cardCfg = csv.cards[cardData.card_id]
				unitCsv = csv.unit[cardCfg.unitID]
				unitId   = dataEasy.getUnitId(cardData.card_id, cardData.skin_id)

				bind.extend(self, item, {
					class = "card_icon",
					props = {
						unitId = unitId,
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
			end
		end
		panel:get("textCount"):text(cardNum..'/'..4)
		panel:get("textFight"):text(fighting)
		adapt.oneLineCenterPos(cc.p(180, 60), {panel:get("textInfo01"), panel:get("textFight")}, cc.p(6, 0))
	end
end


-- 初始化界面
function CrossMineLineUpView:initHeroSprite(index)
	self.heroSprite[index] = {}
	local unitCsv,unitId,cfg,cardDatas
	local fighting = 0
	local cardNum = 0
	local tab = self.clientBattleCards:read()[index]
	local panel = self.panelSelf[index]

	for k1 = 1, 6 do
		local item = panel:get("icon0"..k1)
		local bgIcon = panel:get("bgIcon0"..k1)
		local cardData = self:getCardAttrs(tab[k1])
		if cardData then
			cardNum  = cardNum + 1
			fighting = fighting +cardData.fighting_point

			cfg      = csv.cards[cardData.card_id]
			unitCsv  = csv.unit[cfg.unitID]
			unitId   = dataEasy.getUnitId(cardData.card_id, cardData.skin_id)
			bind.extend(self, item, {
				class = "card_icon",
				props = {
					unitId = unitId,
					rarity = unitCsv.rarity,
					advance = cardData.advance,
					star = cardData.star,
					levelProps = {
						data = cardData.level,
					},
				}
			})
			bgIcon:hide()
			item:show()
		else
			item:hide()
			bgIcon:show()
		end
		item:onTouch(functools.partial(self.onBattleCardTouch, self, index, k1))
		self.heroSprite[index][k1] = {}
		self.heroSprite[index][k1] = {sprite = item, dbid = cardData and cardData.dbid or nil, markId = cfg and cfg.cardMarkID or nil}

	end
	panel:onTouch(functools.partial(self.onBattlePanelTouch, self, index))
	panel:get("textCount"):text(cardNum..'/'..4)
	panel:get("textFight"):text(fighting)
	adapt.oneLineCenterPos(cc.p(180, 60), {panel:get("textInfo01"), panel:get("textFight")}, cc.p(6, 0))
end



-- move时创建item
function CrossMineLineUpView:createMovePanel(data)
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
function CrossMineLineUpView:deleteMovingItem()
	self.selectIndex:set({0, 0})
	if self.moveItem then
		self.moveItem:removeSelf()
		self.moveItem = nil
	end
end

function CrossMineLineUpView:moveMovePanel(event)
	if self.moveItem then
		self.moveItem:xy(event)
		local dbid, site1, site2 = self:whichEmbattleTargetPos(event)
		self.selectIndex:set({site1, site2})
	end
end

function CrossMineLineUpView:isMovePanelExist()
	return self.moveItem ~= nil
end

function CrossMineLineUpView:onBattleCardTouch(k, k1, event)

	local dbid = self.clientBattleCards:read()[k][k1]
	local dbidInfo = self:getCardAttrs(dbid)
	if not dbidInfo then
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

			--交换位置
		local dbid2, site1, site2 = self:whichEmbattleTargetPos(event)
		self:changeHero(dbidInfo.dbid, dbid2, site1, site2)

		self:deleteMovingItem()
	end
end

function CrossMineLineUpView:moveEndMovePanel(data)
	if not self.moveItem then
		return
	end
	local index = self.selectIndex:read()
	if index[1] and index[2] then
		self:resetBattle(index[1], index[2],  data)
	end
	self:deleteMovingItem()
end


--是否跟换
function CrossMineLineUpView:whichEmbattleTargetPos(p)
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
function CrossMineLineUpView:itemSkin(item, dbid, star)
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



--是否跟换panel
function CrossMineLineUpView:getDistance(index, p)
	local x,y = self.panelSelf[index]:xy()
	local pos = self.panelSelf[index]:getParent():convertToWorldSpace(cc.p(x, y))
	return cc.p(p.x - pos.x , p.y - pos.y)
end

-- move时创建item
function CrossMineLineUpView:createMovePanelBlock(index, p)
	if self.movePanel then
		self.movePanel:removeSelf()
	end
	self.distance = self:getDistance(index, p)
	self.selectPanelIndex = index
	local movePanel = self.movePanelCell:clone():addTo(self:getResourceNode(), 1000)
	self.movePanel = movePanel
	local size = self.movePanelCell:size()
	local clonePanel = self.panelSelf[index]:clone():addTo(movePanel):alignCenter(size)
	clonePanel:get("imgRank"):texture(PANEL_IMG[1][index])

	self.panelSelf[index]:hide()
	self.movePanelLast:xy(self.panelSelf[index]:xy())
	self.movePanelLast:show()


	self:moveMovePanelBlock(p)
	return movePanel

end

-- move时创建item
function CrossMineLineUpView:deleteMovingPanelBlock()
	if self.movePanel then
		self.movePanel:removeSelf()
		self.movePanel = nil
	end

	if self.selectPanelIndex then
		self.panelSelf[ self.selectPanelIndex]:show()
		self.movePanelLast:hide()
		self.selectPanelIndex = nil
	end
end

function CrossMineLineUpView:moveMovePanelBlock(event)

	if self.movePanel then
		self.movePanel:xy(cc.p(event.x - self.distance.x, event.y - self.distance.y))
	end
end

function CrossMineLineUpView:isMovePanelBlockExist()
	return self.movePanel ~= nil
end


function CrossMineLineUpView:onBattlePanelTouch(k, event)
	if event.name == "began" then
		self.moved = false
		self:createMovePanelBlock(k,event)
	elseif event.name == "moved" then
		self.moved = true
		self:moveMovePanelBlock(event)
	elseif (event.name == "ended" or event.name == "cancelled") then
		if not k then
			self:deleteMovingPanelBlock()
			return
		end

		local k2 = self:whichPanelTargetPos(event)
		if k2 then
			self.clientBattleCards:modify(function(oldval)
				oldval[k], oldval[k2] = oldval[k2], oldval[k]
				return true, oldval
			end, true)
		end

		self:deleteMovingPanelBlock()
	end
end



--是否跟换panel
function CrossMineLineUpView:whichPanelTargetPos(p)
	for i,panel in pairs(self.panelSelf) do
		local rect = panel:box()
		local pos = panel:getParent():convertToWorldSpace(cc.p(rect.x, rect.y))
		rect.x, rect.y = pos.x, pos.y
		if cc.rectContainsPoint(rect, p) then
			return i
		end
	end

	return nil
end
--统计上阵数量
function CrossMineLineUpView:spriteNumber(dbid)
	--itemNum上阵数量，itemNumAll总共的位置
	local itemNum, downBattle, itemNumAll = 0, 0, 0
	local downBattleK

	itemNumAll = 12

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
function CrossMineLineUpView:getIdxByDbId(dbid)
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

--拖动上阵判断人数是否达到
function CrossMineLineUpView:cardNumberFunc(idx)
	local numAll =  4
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


-- --判断上下交换的精灵是否是相同cardMarkID
function CrossMineLineUpView:equalCardMarkView(id1, id2)
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
function CrossMineLineUpView:changeHero(dbid1, dbid2, site1, site2)
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
		local num = 4
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
		return true, showDatas
	end)
end

function CrossMineLineUpView:getCardAttrs(dbid)
	local card = gGameModel.cards:find(dbid)
	if card then
		local cardDatas = card:read("card_id", "skin_id", "fighting_point", "level", "star", "advance")
		cardDatas.dbid = dbid
		return cardDatas
	end
	return nil
end


-- 挑战
function CrossMineLineUpView:onBtnChallenge()
	local cards = self.clientBattleCards:read()
	if not next(cards) then
		gGameUI:showTip(gLanguageCsv.noSpriteAvailable)
		return
	end

	self:sendRequeat(function()
		self.fightCb(self, self.clientBattleCards)
	end)
end

function CrossMineLineUpView:onClose()
	self:sendRequeat(functools.partial(ViewBase.onClose, self), true)
end

function CrossMineLineUpView:onCloseSelf()
	ViewBase.onClose(self)
end

-- 关闭或切页阵容变动检测和保存
function CrossMineLineUpView:sendRequeat(cb, isClose)
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

		gGameApp:requestServer("/game/cross/mine/battle/deploy", function(data)
			cb()
		end, battleCards , nil)
	else
		cb()
	end
end

function CrossMineLineUpView:onBtnBuffPanel(node,v, k)
	local rect = node:box()
	local pos = node:parent():convertToWorldSpace(cc.p(rect.x, rect.y))
	local params = {data = v.cfg, pos = {pos.x + k*140, pos.y - 400}}
	gGameUI:createView("city.pvp.cross_mine.buff_info", self):init(params)
end
return CrossMineLineUpView