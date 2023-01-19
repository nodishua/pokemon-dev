local ViewBase = cc.load("mvc").ViewBase
local CardEmbattleView = require "app.views.city.card.embattle.base"
local CrossAreanEmbattleView = class("CrossAreanEmbattleView", CardEmbattleView)
local TEAM = {
	PANEL = {6, 6, 3},  -- 每队的底盘数量
	TEAM_NUM = {6, 4, 3}, -- 每队的数量
	TEAM_SUM = {12, 18, 9}, -- 每个战场队伍的底盘总数
	TEAMS = {2, 3, 3} -- 每个战场队伍数
}

CrossAreanEmbattleView.RESOURCE_FILENAME = "cross_union_fight_battle.json"
CrossAreanEmbattleView.RESOURCE_BINDING = {
	["battlePanel1.fightNote.btnGHimg"] = {
		varname = "btnGHimg",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onTeamBuffClick1")}
		}
	},
	["battlePanel1"] = "battlePanel1",

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
			methods = {ended = bindHelper.self("teamSaveBtn")}
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
	["battlePanel1.imgDuiwu.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["rightDown"] = "rightDown",
	["battlePanel1.fightNote.textFightPoint"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("fightSumNum1"),
		},
	},
	["bottomPanel"] = "bottomPanel",
	["topTableItem"] = "topTableItem",
	["teamList"] = {
		varname = "teamList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("topTabDatas"),
				item = bindHelper.self("topTableItem"),
				showTab = bindHelper.self("topTab"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
					else
						selected:hide()
						panel = normal:show()
					end
					if v.sign == 1 then
						node:get("sign"):show()
					else
						node:get("sign"):hide()
					end
					panel:get("txt"):text(v.name)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k, 1)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["leftTableItem"] = "leftTableItem",
	["procList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("leftTabDatas"),
				item = bindHelper.self("leftTableItem"),
				showTab = bindHelper.self("leftTab"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
					else
						selected:hide()
						panel = normal:show()
					end
					panel:get("txt"):text(v.name)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k, 2)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["panelTip"] = "panelTip",
	["panelTip.tip2"] = {
		varname = "tip2",
		binds = {
			event = "effect",
			data = {color=cc.c4b(251, 209, 60,255), outline={color=cc.c4b(184,52,11,255), size=4}}
		}
	},
	["panelTip.tip1"] = {
		varname = "tip1",
		binds = {
			event = "effect",
			data = {color=cc.c4b(226, 89, 52,255)}
		}
	},
	["tips"] = "tips",
	["txtTip"] = {
		varname = "txtTip",
		binds = {
			event = "effect",
			data = {color=ui.COLORS.NORMAL.DEFAULT, size = 50}
		}
	},
}

function CrossAreanEmbattleView:onCreate(params)
	adapt.centerWithScreen("left", "right", nil, {
		{self.rightDown, "pos", "right"},
	})
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose", true)})
		:init({title = gLanguageCsv.ministryHouseBattle, subTitle = "FORMATION"})

	self.topTabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.crossUnionFightEmbattle1, id = self.activityId, type = 1, sign = 0},
		[2] = {name = gLanguageCsv.crossUnionFightEmbattle2, id = self.activityId, type = 2, sign = 0},
		[3] = {name = gLanguageCsv.crossUnionFightEmbattle3, id = self.activityId, type = 3, sign = 0},
	})
	local teams1 = {
		[1] = {name = gLanguageCsv.team .. 1,id = self.activityId, type = 1, select = false},
		[2] = {name = gLanguageCsv.team .. 2,id = self.activityId, type = 2, select = false},
	}
	local teams2 = {
		[1] = {name = gLanguageCsv.team .. 1,id = self.activityId, type = 1, select = false},
		[2] = {name = gLanguageCsv.team .. 2,id = self.activityId, type = 2, select = false},
		[3] = {name = gLanguageCsv.team .. 3,id = self.activityId, type = 3, select = false},
	}
	self.leftTabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.team .. 1,id = self.activityId, type = 1},
		[2] = {name = gLanguageCsv.team .. 2,id = self.activityId, type = 2},
		[3] = {name = gLanguageCsv.team .. 3,id = self.activityId, type = 3},
	})
	self.oldTopVal = 0
	self.indexProject = params.sign or 0

	self:initModel(params)
	self:initBattlePanel()
	self:initBottomList()
	idlereasy.any({self.clientBattleCards, self.leftTab}, function (_, battle, leftTab)
		local topTab = self.topTab:read()
		local embattleNum, panel = TEAM.TEAM_NUM, TEAM.PANEL
		self.embattleMax = embattleNum[topTab] --单个Tab最大可上阵数
		self.panelNum = panel[topTab]    --布阵底座数量
		self.fightSumNum1:set(self:getFightSumNum(1))
		self:refreshTeamBuff(1)
		self.rightDown:get("textNum"):text(self:calcCardsNum(battle, topTab, leftTab) .. "/" .. self.embattleMax)
		adapt.oneLineCenterPos(cc.p(163, 300), {self.rightDown:get("textNote"), self.rightDown:get("textNum")}, cc.p(5, 0))

		if topTab == 3 then
			self:resetPanel(3)
		else
			self:resetPanel(6)
		end
		for i = 1, self.panelNum do
			self:refreshBattleSprite(i)
		end
	end)

	idlereasy.any({self.userInfo}, function (_, userInfo)
		local  my = gGameModel.role:read("id")
		local myData = {}
		for i, v in pairs(userInfo or {}) do
			if i == my then
				myData =v
				break
			end
		end
		if not itertools.isempty(myData) then
			self.indexProject = myData.projects[params.type]
			for i = 1, 3 do
				if self.indexProject == i then
					self.topTabDatas:atproxy(i).sign = 1
				else
					self.topTabDatas:atproxy(i).sign = 0
				end
			end
		end
	end)
	self.topTab:addListener(function(val, oldval)
		self.topTabDatas:atproxy(oldval).select = false
		self.topTabDatas:atproxy(val).select = true
		self.oldTopVal = oldval
		if val < 2 then
			for _, v in ipairs(teams1) do
				v.select = false
			end
			self.leftTabDatas:update(teams1)
		else
			for _, v in ipairs(teams2) do
				v.select = false
			end
			self.leftTabDatas:update(teams2)
		end
		self.leftTab:set(1,true)
		self:changeAllCard(val)
		--self.clientBattleCards:set(self.allBattleCardsData[val])
	end)
	self.leftTab:addListener(function(val, oldval)
		if self.topTab:read() == 1 and oldval > 2 then
			oldval = 1
		end
		self.leftTabDatas:atproxy(oldval).select = false
		self.leftTabDatas:atproxy(val).select = true
		for i = 1, self.panelNum do
			self:refreshBattleSprite(i)
		end
	end)
	self.tip2:text(gLanguageCsv.crossUnionFightEmbattleTip1)
	self.tip1:text(gLanguageCsv.crossUnionFightEmbattleTip2)
	self.tips:hide()

	idlereasy.when(self.status, function(_, status)
		local topTab = self.indexProject ~= 0 and self.indexProject or 1
		if status ~= "topPrepare" and status ~= "prePrepare" then
			self.bottomPanel:hide()
			self.rightDown:hide()
			self.teamList:hide()
			self.tips:show()
			self.tips:text(self.topTabDatas:atproxy(topTab).name)
			self.txtTip:show()
			self.txtTip:text(gLanguageCsv.crossUnionFightNotEmbattle)
			self.tip2:hide()
			self.tip1:hide()
		else
			self.bottomPanel:show()
			self.rightDown:show()
			self.teamList:show()
			self.tips:hide()
			self.txtTip:hide()
			self.tips:text("")
			self.tip2:show()
			self.tip1:show()
		end
	end)
end

function CrossAreanEmbattleView:calcCardsNum(battle, topTab, leftTab)
	local num = TEAM.PANEL
	local sum = 0
	for i = 1 + (leftTab - 1) * num[topTab], leftTab * num[topTab] do
		if battle[i] then
			sum = sum + 1
		end
	end
	return sum
end

function CrossAreanEmbattleView:initModel(params)
	self.status = gGameModel.cross_union_fight:getIdler("status")
	self.topTab = idler.new(params.sign~=0 and params.sign or 1)
	self.leftTab = idler.new(1)
	self.fightSumNum1 = idler.new(0)
	self.cards = gGameModel.role:getIdler("cards")
	self.userInfo = gGameModel.cross_union_fight:getIdler("roles")
	self.type = params.type or 1
	self.fightCb = params.fightCb
	self.allCardDatas = idlers.newWithMap({})
	self.selectIndex = idler.new(0)
	--local battleCardsData1 = {}
	self.cards = gGameModel.cross_union_fight:getIdler("cards")

	local getBestCard =  function(topTab)
		local cards = gGameModel.role:read("cards")
		local all = {}
		local oneKeyAllCards = {}
		for _, dbid in ipairs(cards) do
			local card = gGameModel.cards:find(dbid)
			local cardDatas = card:read("card_id", "skin_id", "fighting_point", "level", "star", "advance", "created_time", "nature_choose")
			all[dbid] =  self.limtFunc(self, dbid, cardDatas.card_id,cardDatas.skin_id, cardDatas.fighting_point, cardDatas.level, cardDatas.star, cardDatas.advance, cardDatas.created_time, cardDatas.nature_choose, false)
			if all[dbid] then
				table.insert(oneKeyAllCards, all[dbid])
			end
		end
		table.sort(oneKeyAllCards, function(a, b)
			if a.fighting_point ~= b.fighting_point then
				return a.fighting_point > b.fighting_point
			end
			return a.rarity > b.rarity
		end)
		local oneKeyCards = {}
		local oneKeyHash = {}
		local count = 0
		for _, v in ipairs(oneKeyAllCards) do
			if not oneKeyHash[v.markId] then
				oneKeyHash[v.markId] = true
				table.insert(oneKeyCards, v.dbid)
				count = count + 1
				if count == 12 then
					break
				end
			end
		end


		local card, index = {}, 1
		for i = 1, TEAM.TEAMS[topTab] do
			for j = 1, TEAM.PANEL[topTab] do
				if j > TEAM.TEAM_NUM[topTab] then
					card[(i-1)*TEAM.PANEL[topTab] + j] = nil
				else
					card[(i-1)*TEAM.PANEL[topTab] + j] = oneKeyCards[index]
					index = index + 1
				end
			end
		end
		return card
	end
	local maxBattleCard = {[1] = getBestCard(1), [2] = getBestCard(2), [3] = getBestCard(3)}

	idlereasy.any({self.cards}, function (_, cards)
		local battleCardsData = cards[params.type]
		self.allBattleCardsData = {{}, {}, {}}
		local num = {2, 3, 3}
		local indexs = 1
		for i = 1, 3 do
			if not itertools.isempty(battleCardsData[i]) then
				for j = 1, TEAM.TEAM_SUM[i] do
					self.allBattleCardsData[i][j] = battleCardsData[i][j]
					indexs = indexs + 1
				end
			else
				self.allBattleCardsData[i] = maxBattleCard[i]
			end
		end
		self.beforeBattleCards = table.deepcopy(self.allBattleCardsData, true)   -- 保留原始卡牌组
	end)

	self.battleCardsData = idlertable.new(self.allBattleCardsData[self.topTab:read()])
	self.clientBattleCards =  idlertable.new(self.allBattleCardsData[self.topTab:read()])
	self:initDefine()
	self:initAllCards()
end

-- 更新卡牌列表的数据
function CrossAreanEmbattleView:changeAllCard(topTab)
	-- 判断现在是那个阵营
	local cards = self.allBattleCardsData[topTab]
	for idx = 1, 18 do
		if self.clientBattleCards:read()[idx] then
			self:getCardAttrs(self.clientBattleCards:read()[idx]).battle = 0
		end
	end
	for idx = 1, 18 do
		local dbid = cards[idx]
		if dbid then
			self:getCardAttrs(dbid).battle = self:getBattle(idx)
		end
	end
	self.allBattleCardsData[topTab] = cards
	self.clientBattleCards:set(cards, true)
end

function CrossAreanEmbattleView:initDefine()
	local num, panel = TEAM.TEAM_NUM, TEAM.PANEL
	self.embattleMax = num[self.topTab:read()] --单个Tab最大可上阵数
	self.panelNum = panel[self.topTab:read()]    --布阵底座数量
end

-- 改变panel形状
function CrossAreanEmbattleView:resetPanel(number)
	if number == 3 then
		local child = self.battlePanel1:multiget("item4", "item5", "item6", "ahead", "back")
		for _, v in pairs(child) do
			v:hide()
		end
		child = self.battlePanel1:multiget("item1","item2","item3")
		local x = {278, 825, 1366}
		for i, v in pairs(child) do
			v:get("imgBg"):scale(1,1)
			v:size(cc.size(500, 300))
		end
		child.item1:xy(338,750)
		child.item2:xy(905,730)
		child.item3:xy(1366,730)
		self.battlePanel1:get("place"):show()
	else
		local child = self.battlePanel1:multiget("item4", "item5", "item6", "ahead", "back")
		for _, v in pairs(child) do
			v:show()
		end
		child = self.battlePanel1:multiget("item1","item2","item3")
		local x = {1302, 1165, 997}
		local y = {987, 746, 524}
		local scale = {0.6, 0.8, 1}
		local size = {cc.size(367, 255), cc.size(387, 225), cc.size(500, 225)}
		for i = 1, 3 do
			child["item"..i]:xy(x[i], y[i]):size(size[i])
			child["item"..i]:xy(x[i], y[i])
			child["item"..i]:get("imgBg"):scale(scale[i])
		end
		self.battlePanel1:get("place"):hide()
	end

	self.battleCardsRect = {}
	self.battleCards = {}
	for j = 1, self.panelNum do
		local item = self["battlePanel1"]:get("item"..j)
		local rect = item:box()
		local pos = item:getParent():convertToWorldSpace(cc.p(rect.x, rect.y))
		rect.x, rect.y = pos.x, pos.y
		local idx = j

		self.battleCardsRect[idx] = rect
		self.battleCards[idx] = item
		item:onTouch(functools.partial(self.onBattleCardTouch, self, idx))
	end
	for i = 1, self.panelNum do
		local imgBg = self.battleCards[i]:get("imgBg")
		local imgSel = imgBg:get("imgSel")
		local size = imgBg:size()
		if not imgSel then
			imgSel = widget.addAnimationByKey(imgBg, "effect/buzhen2.skel", "imgSel", "effect_loop", 2)
						   :xy(size.width/2, size.height/2 + 15)
			imgSel:visible(false)
		end
	end


end

-- 初始化所有cards
function CrossAreanEmbattleView:initAllCards()
	local cards = gGameModel.role:read("cards")
	local hash = itertools.map(self.clientBattleCards:read(), function(k, v) return v, k end)

	local all = {}
	self.oneKeyAllCards = {}
	for _, dbid in ipairs(cards) do
		local card = gGameModel.cards:find(dbid)
		local inBattle = self:getBattle(hash[dbid])
		local cardDatas = card:read("card_id", "skin_id", "fighting_point", "level", "star", "advance", "created_time", "nature_choose")
		all[dbid] =  self.limtFunc(self, dbid, cardDatas.card_id,cardDatas.skin_id, cardDatas.fighting_point, cardDatas.level, cardDatas.star, cardDatas.advance, cardDatas.created_time, cardDatas.nature_choose, inBattle)
		if all[dbid] then
			table.insert(self.oneKeyAllCards, all[dbid])
		end
	end
	self.allCardDatas:update(all)

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
			if count == 12 then
				break
			end
		end
	end
end
-- 初始化精灵布阵
function CrossAreanEmbattleView:initBattlePanel()
	self.battleCardsRect = {}
	self.battleCards = {}
	for j = 1, self.panelNum do
		local item = self["battlePanel1"]:get("item"..j)
		local rect = item:box()
		local pos = item:getParent():convertToWorldSpace(cc.p(rect.x, rect.y))
		rect.x, rect.y = pos.x, pos.y
		local idx = j

		self.battleCardsRect[idx] = rect
		self.battleCards[idx] = item
		item:onTouch(functools.partial(self.onBattleCardTouch, self, idx))
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

-- 刷新座位角色
function CrossAreanEmbattleView:refreshBattlePanel()

end

-- 底部所有卡牌
function CrossAreanEmbattleView:initBottomList(  )
	self.cardListView = gGameUI:createView("city.card.embattle.cross_union_fight_card_list", self.bottomPanel):init({
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
	local topTab, leftTab = self.topTab:read(), self.leftTab:read()
	local startIndex, endIndex = 1 + (leftTab -1) * TEAM.PANEL[topTab], leftTab * TEAM.PANEL[topTab]
	for i = startIndex, endIndex do
		if self.clientBattleCards:read()[i] then
			fightSumNum = fightSumNum + self:getCardAttrs(self.clientBattleCards:read()[i]).fighting_point
		end
	end
	return fightSumNum
end

function CrossAreanEmbattleView:getCardNum(battle)
	local cardNum = 0
	local topTab, leftTab = self.topTab:read(), self.leftTab:read()
	local startIndex, endIndex = 1 + (leftTab -1) * TEAM.PANEL[topTab], leftTab * TEAM.PANEL[topTab]
	for i = startIndex, endIndex do
		if self.clientBattleCards:read()[i] then
			cardNum = cardNum + 1
		end
	end
	return cardNum
end

-- 刷新buf
function CrossAreanEmbattleView:refreshTeamBuff()
	-- 只有6v6有
	local topTab = self.topTab:read()
	local leftTab = self.leftTab:read()
	self.btnGHimg:show()
	if topTab ~= 1 then
		self.btnGHimg:hide()
		return
	end
	local attrs = {}
	local startIndex = 1 + (leftTab - 1) * 6
	for i = startIndex, startIndex + 5 do
		local data = self:getCardAttrs(self.clientBattleCards:read()[i])
		if data then
			local cardCfg = csv.cards[data.card_id]
			local unitCfg = csv.unit[cardCfg.unitID]
			attrs[i - startIndex + 1] = {unitCfg.natureType, unitCfg.natureType2}
		end
	end
	local result = dataEasy.getTeamBuffBest(attrs)
	self.btnGHimg:texture(result.buf.imgPath)
	self.teamBuffs1 = result
end


-----------------------------RightDownPanel-----------------------------

-- 一键布阵
function CrossAreanEmbattleView:oneKeyEmbattleBtn()
	-- 判断现在是那个阵营
	local topTab = self.topTab:read()
	local cards, index = {}, 1
	for i = 1, TEAM.TEAMS[topTab] do
		for j = 1, TEAM.PANEL[topTab] do
			if j > TEAM.TEAM_NUM[topTab] then
				cards[(i-1)*TEAM.PANEL[topTab] + j] = nil
			else
				cards[(i-1)*TEAM.PANEL[topTab] + j] = self.oneKeyCards[index]
				index = index + 1
			end
		end
	end
	if not self.clientBattleCards:read() then
		return
	end
	if itertools.equal(cards, self.clientBattleCards:read()) then
		gGameUI:showTip(gLanguageCsv.embattleNotChange)
		return
	end
	for idx = 1, 18 do
		if self.clientBattleCards:read()[idx] then
			self:getCardAttrs(self.clientBattleCards:read()[idx]).battle = 0
		end
	end
	for idx = 1, TEAM.TEAM_SUM[topTab] do
		local dbid = cards[idx]
		if dbid then
			self:getCardAttrs(dbid).battle = self:getBattle(idx)
		end
	end
	self.allBattleCardsData[topTab] = cards
	self.clientBattleCards:set(cards, true)
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
		self.allBattleCardsData[self.topTab:read()] = oldval
	end, true)
end


function CrossAreanEmbattleView:teamSaveBtn()
	local topTab = self.topTab:read()
	gGameUI:showDialog({title = gLanguageCsv.tips, content = string.format(gLanguageCsv.crossUnionFightEmbattle, gLanguageCsv["crossUnionFightEmbattle" .. topTab]),
		isRich = true, fontSize = 50, btnType = 2, cb = function() self:saveBtn()
		end,})
end

-- 保存
function CrossAreanEmbattleView:saveBtn(deployType, cb)
	if self.status:read() ~= "topPrepare" and self.status:read() ~= "prePrepare" then
		gGameUI:showTip(gLanguageCsv.crossUnionFightCantEmbattle) -- todo
		return
	end
	local topTab = self.topTab:read()
	--local equality = itertools.equal(self.battleCardsData:read(), self.clientBattleCards:read())
	local equality, index = self:lastModify()
	if equality and topTab == self.indexProject then
		gGameUI:showTip(gLanguageCsv.embattleNotChange)
		return 1
	end
	if type(deployType) ~= "number" then
		deployType = topTab
	end
	-- 判断对应需要保存的阵容是否合理
	local battle = self.allBattleCardsData[deployType] --self.clientBattleCards:read()
	local cardSum = 0
	for i = 1, TEAM.TEAMS[deployType] do
		if TEAM.TEAM_NUM[deployType] ~= self:calcCardsNum(battle, deployType, i) then
			cardSum = i
		end
	end
	if cardSum == 0  then
		gGameApp:requestServer("/game/cross/union/fight/battle/deploy", function(tb)
			if type(cb) == "function" then cb() else gGameUI:showTip(gLanguageCsv.positionSave) end
		end, self.type, deployType, battle)
	else
		gGameUI:showTip(string.format(gLanguageCsv.crossUnionFightCardNotEnough, gLanguageCsv["symbolNumber" .. cardSum]))
		return 1
	end
end

-- 光环
function CrossAreanEmbattleView:onTeamBuffClick1()
	local teamBuffs = self.teamBuffs1 and self.teamBuffs1.buf.teamBuffs or {}
	gGameUI:stackUI("city.card.embattle.attr_dialog",nil, {}, teamBuffs)
end
-- 光环
-----------------------------DragItem-----------------------------

function CrossAreanEmbattleView:refreshBattleSprite(index)
	local panel = self.battleCards[index]
	local cardNums = TEAM.PANEL
	local data = self:getCardAttrs(self.clientBattleCards:read()[index + (self.leftTab:read()-1)*cardNums[self.topTab:read()]])
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
	if self.status:read() ~= "topPrepare" and self.status:read() ~= "prePrepare" then
		return
	end
	local cardNums = TEAM.PANEL
	if not self.clientBattleCards:read()[idx + (self.leftTab:read() - 1) * cardNums[self.topTab:read()]] then
		return
	end
	local data = self:getCardAttrs(self.clientBattleCards:read()[idx + (self.leftTab:read() - 1) * cardNums[self.topTab:read()]])
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
	local cardNums = TEAM.PANEL
	targetIdx = targetIdx and targetIdx + (self.leftTab:read() - 1) * cardNums[self.topTab:read()]
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
					self.allBattleCardsData[self.topTab:read()] = oldval
					return true, oldval
				end, true)
			end
		else
			local commonIdx = self:hasSameMarkIDCard(data)
			if commonIdx and commonIdx ~= targetIdx then
				tip = gLanguageCsv.alreadyHaveSameSprite
			else
				if not targetDbid and not self:canBattleUp() then
					tip = gLanguageCsv.battleCardCountEnough
				else
					if targetDbid then-- 到阵容已有对象上，阵容上的下阵，拖动对象上阵
						self:getCardAttrs(targetDbid).battle = 0
					end
					self:getCardAttrs(dbid).battle = self:getBattle(targetIdx)
					self.clientBattleCards:modify(function(oldval)
						oldval[targetIdx] = dbid
						self.allBattleCardsData[self.topTab:read()] = oldval
						return true, oldval
					end, true)
					tip = gLanguageCsv.addToEmbattle
				end
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
		self.allBattleCardsData[self.topTab:read()] = oldval
		return true, oldval
	end, true)
end

-- 上阵
function CrossAreanEmbattleView:upBattle(dbid, idx)
	self:getCardAttrs(dbid).battle = self:getBattle(idx)
	self.clientBattleCards:modify(function(oldval)
		oldval[idx] = dbid
		self.allBattleCardsData[self.topTab:read()] = oldval
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
	local num = {12, 18 ,9}
	for i = 1, num[self.topTab:read()] do
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
	if self.status:read() ~= "topPrepare" and self.status:read() ~= "prePrepare" then
		cb()
		return
	end
	-- 完善条件处理[√]
	-- 1. 该战场不是报名的战场且阵容发生变化 提示
	-- 2. 该战场是报名的战场且阵容发生变化 提示
	--local equality = itertools.equal(self.battleCardsData:read(), self.clientBattleCards:read())
	local equality, changeTab = self:lastModify()
	local sign = self.indexProject -- 报名场地
	local topTab = self.topTab:read()
	if not equality then
		local closeCb = function()
			gGameUI:showTip(gLanguageCsv.positionSave)
			cb()
		end
		if sign ~= changeTab then
			-- 1. 该战场不是报名的战场且阵容发生变化 提示 是=> 切换新战场 判断是否合理 飘字， 否 保留  ， 都退出布阵界面
			gGameUI:showDialog({title = gLanguageCsv.crossUnionFightEmbattleTitle, content = string.format(gLanguageCsv.crossUnionFightEmbattleSave, gLanguageCsv["crossUnionFightEmbattle" .. changeTab]),
				isRich = true, fontSize = 50, btnType = 2, cb = function() self:saveBtn(changeTab, closeCb)
				end, cancelCb = cb, clearFast = true})
		else
			--该战场是报名的战场且阵容发生变化 提示 是=>保存战场 判断是否合理 飘字，否=> 直接退出  都退出布阵界面
			gGameUI:showDialog({title = gLanguageCsv.crossUnionFightEmbattleTitle, content = string.format(gLanguageCsv.crossUnionFightEmbattleSave, gLanguageCsv["crossUnionFightEmbattle" .. changeTab]),
				isRich = true, fontSize = 50, btnType = 2, cb = function() self:saveBtn(changeTab, closeCb)
				end, cancelCb = cb, clearFast = true})
		end
	else
		cb()
	end
end

function CrossAreanEmbattleView:lastModify()
	local changePlace, topTab, flag = 0, self.topTab:read(), {0,0,0}
	for i = 1, 3 do
		local equal = itertools.equal(self.allBattleCardsData[i], self.beforeBattleCards[i])
		if not equal then
			flag[i] = 1
			changePlace = 1
		end
	end

	if changePlace == 0 then
		return true
	end

	if flag[topTab] == 1 then
		return false, topTab
	end

	if flag[self.oldTopVal] == 1 then
		return false, self.oldTopVal
	end

	for i, v in ipairs(flag) do
		if v == 1 then
			return false, i
		end
	end
end

-- 重载
function CrossAreanEmbattleView:getBattle(i)
	local num = TEAM.PANEL
	if i and i~= 0 then
		return math.ceil(i/num[self.topTab:read()])
	else
		return 0
	end
end

-- 重载
function CrossAreanEmbattleView:onTabClick(list, index, tab)
	local tabs = {"topTab", "leftTab"}
	self[tabs[tab]]:set(index)
end

-- 重载
function CrossAreanEmbattleView:getIdxByDbId(dbid)
	if not dbid then
		local num = TEAM.PANEL
		local battle, topTab, leftTab = self.clientBattleCards:read(), self.topTab:read(), self.leftTab:read()
		for i = 1 + (leftTab - 1) * num[topTab], leftTab * num[topTab] do
			if battle[i] == dbid then
				return i
			end
		end
	else
		local num = TEAM.TEAM_SUM
		for i = 1, num[self.topTab:read()] do
			if self.clientBattleCards:read()[i] == dbid then
				return i
			end
		end
	end
end
-- 重载
function CrossAreanEmbattleView:canBattleUp()
	local num = TEAM.TEAM_NUM
	local battle, topTab, leftTab = self.clientBattleCards:read(), self.topTab:read(), self.leftTab:read()
	return self:calcCardsNum(battle, topTab, leftTab) <  num[topTab]
end


return CrossAreanEmbattleView