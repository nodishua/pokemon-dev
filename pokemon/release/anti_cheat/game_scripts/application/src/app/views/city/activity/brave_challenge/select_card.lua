-- @date:   2021-03-09
-- @desc:   勇者挑战---选择精灵
local BCAdapt = require("app.views.city.activity.brave_challenge.adapt")

local MAX_NUM = 3
--精灵解锁
local UNLOCK_TYPE = {
	uncondition = 0, --无条件
	gainCard = 1,   --招募到%s解锁
	failure = 2, --失败%d轮解锁
	gainBuff = 3, --获得%d解锁
	clearance = 4 -- 通关指定关卡
}
local ACTION_TIME = 0.5

local CARD_POS =
{
	cc.p(95,100),cc.p(295,100),cc.p(495,100),cc.p(695,100),
	cc.p(895,100),cc.p(1095,100),cc.p(1455,100),cc.p(1655,100)
}

local PANEL_POS =
{
	cc.p(-522, 165), cc.p(11, 165), cc.p(546, 165)
}

local ViewBase = cc.load("mvc").ViewBase
local BraveChallengeSelectCardView = class("BraveChallengeSelectCardView",ViewBase)

BraveChallengeSelectCardView.RESOURCE_FILENAME = "activity_brave_challenge_view_select_card.json"

BraveChallengeSelectCardView.RESOURCE_BINDING = {
	["item01"] = "item01",
	["item02"] = "item02",
	["bottomPanel.btnFilter"] = "btnFilter",
	["bottomPanel.btnStart"] = {
		varname = "btnStart",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnGame")},
		},
	},
	["bottomPanel.btnStart.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.ORANGE}}
		}
	},
	["bottomPanel.btnFilter.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(246,82,102, 255)}}
		}
	},
	["bottomPanel.rateTipPanel"] = "rateTipPanel",
	["bottomPanel.commonTipPanel"] = "commonTipPanel",
	["bottomPanel.txtTip"] = "txtTip",
	------------------------bottomPanel---------------------------
	["bottomPanel"] = "bottomPanel",
	["bottomPanel.cardList"] = {
		varname = "cardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("allCardDatas"),
				item = bindHelper.self("item01"),
				cloneItem = bindHelper.self("item02"),
				asyncPreload = 3,
				onItem = function(list, node, k ,v)
					local rate = 7
					local common = 1
					node:removeAllChildren()
					for index, data in pairs(v) do
						local location = rate
						if data.unlockType == 0 then
							location = common
							common = common + 1
						else
							rate = rate + 1
						end

						local cell = list.cloneItem:clone()
						cell:addTo(node)
						cell:xy(CARD_POS[location])

						local childs = cell:multiget("imgSelect", "imgLock","imgNew")
						childs.imgSelect:visible(data.battle == 1)
						childs.imgLock:visible(not data.isUse)
						-- childs.imgNew:visible(data.isNew)
						local sign = data.battle == 1
						if not sign then
							sign = not data.isUse
						end
						bind.extend(list, cell, {
							class = "card_icon",
							props = {
								unitId = data.unitId,
								advance = data.advance,
								rarity = data.rarity,
								star = data.star,
								grayState = sign and 1 or 0,
								isNew = data.isNew,
								levelProps = {
									data = data.level,
								},
								onNode = function(panel)
									panel:xy(-4, -4)
								end,
							}
						})
						if data.isUse then
							bind.touch(list, cell, {methods = {ended = functools.partial(list.clickCell, data, k ,index)}})
						else
							bind.touch(list, cell, {methods = {ended = functools.partial(list.clickCellTwo, data)}})
						end
					end
				end
			},
			handlers = {
				clickCell = bindHelper.self("onSelectCard", true),
				clickCellTwo = bindHelper.self("onDelockTip", true),
			},
		},
	},

	["selectPanel"] = "selectPanel",
	["selectItem"] = "selectItem",
	["starItem"] = "starItem",
	["selectItem.panelAddInfo.txtUp"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.ORANGE, size = 3}}
		}
	}
}
function BraveChallengeSelectCardView:onCreate(params)
	self.parent = params.parent
	self.data = params.data.datas
	self:initModel()
	self.selectIndex = idler.new()
	self.allCardDatas = idlers.newWithMap({})
	self.selectCardData = idlertable.new({})
	self.filterCondition = idlertable.new()
	self.commonCardDatas = {}
	self.rateCardDatas = {}
	self.activityId = self.id:read()
	self:initBaseCardData()
	self.showPanel = {}
	self.baseInfo = self.parent:getBaseInfo()

	self:initShowPanel()
	idlereasy.when(self.selectCardData, function(_,  cardDatas)
		for index = 1, MAX_NUM do
			self:showSelectCard(index, cardDatas[index])
		end
	end)

	idlereasy.when(self.filterCondition, function()
		self:reflushDatas()
	end)

	self:initFilterBtn()
	self:initSelectPanel()
	self:initDownPanel()
	self:runStartAction()
end

function BraveChallengeSelectCardView:initShowPanel()
	for index = 1, MAX_NUM do
		local panel = self.selectItem:clone():show()
			:addTo(self.selectPanel)
			:xy(PANEL_POS[index])
		self.showPanel[index] = panel
	end
end

-- 检测新卡片打开
function BraveChallengeSelectCardView:openAddCardView()
	self.addCards = idler.new(0)
	idlereasy.when(self.addCards, function(_, addCards)
		local add = self.data.add or {}
		if addCards < itertools.size(add) then
			self:checkCards(add[addCards + 1])
		end
	end)
end


function BraveChallengeSelectCardView:initDownPanel()
	self.txtTip:text(string.format(gLanguageCsv.bcSelectCardTip03,self.baseInfo.sameTimes))
end

-- 进场 动作发起人进场界面
function BraveChallengeSelectCardView:runStartAction()
	local posX, posY = self.bottomPanel:xy()
	self.bottomPanel:xy(posX, posY - 600)
	self.selectPanel:visible(false)
	performWithDelay(self, function ()
		self.bottomPanel:runAction(cc.Sequence:create(
			cc.EaseOut:create(cc.MoveTo:create(ACTION_TIME, cc.p(posX,posY)), ACTION_TIME),
			cc.CallFunc:create(function()
				self.selectPanel:visible(true)
				self:openAddCardView()
			 end),
		nil))
		self.parent:setType(2)
	end, 1/60)
end


-- 退场，动作发起人view界面
function BraveChallengeSelectCardView:runEndAction()
	self.selectPanel:visible(false)
	local posX, posY = self.bottomPanel:xy()
	self.bottomPanel:runAction(cc.Sequence:create(
		cc.EaseOut:create(cc.MoveTo:create(ACTION_TIME, cc.p(posX,posY - 600)), ACTION_TIME),
		cc.CallFunc:create(function()
			-- gGameUI:disableTouchDispatch(nil, true)
		end),
		nil))

end

-- modle数据初始化
function BraveChallengeSelectCardView:initModel()
	self.id = gGameModel.brave_challenge:getIdler("yyID")
	self.unlockCards = gGameModel.brave_challenge:getIdler("unlock_cards")
	self.status = gGameModel.brave_challenge:getIdler("status")
end

function BraveChallengeSelectCardView:initSelectPanel()
	for i = 1, 3 do
		local item = self.showPanel[i]
		local imgBg = item:get("imgBg")
		local imgSel = imgBg:get("imgSel")
		local size = imgBg:size()
		if not imgSel then
			imgSel = widget.addAnimationByKey(item, "effect/buzhen2.skel", "imgSel", "effect_loop", 5)
				:xy(imgBg:x(), imgBg:y()+20)
				:scale(0.6)
		end
	end
end

--判断是否有解锁精灵
function BraveChallengeSelectCardView:checkCards(data)
	gGameUI:stackUI("city.activity.brave_challenge.gain_card", nil, {blackLayer = true, clickClose = true}, data, self:createHandler("addCount"))
end

function BraveChallengeSelectCardView:addCount()
	self.addCards:set(self.addCards:read() + 1)
end

-- 本次牌库的类型转换hash
function BraveChallengeSelectCardView:getCardType()
	local data =self.parent:getBaseInfo()
	local hash = {}
	for index, id in csvPairs(data.cards) do
		hash[id] = index
	end
	return hash
end

-- 原始数据初始化
function BraveChallengeSelectCardView:initBaseCardData()
	local cardHash = self:getCardType()

	-- 解锁卡牌转成hash
	local unlockHash = {}
	local unlockCards = gGameModel.brave_challenge:read("unlock_cards")
	for index, csvID in ipairs(unlockCards) do
		unlockHash[csvID] = true
	end

	local newCardhash = {}
	local addList =  self.data.add or {}
	for index, csvID in ipairs(addList) do
		newCardhash[csvID] = true
	end

	local commonCardDatas = {}
	local rateCardDatas = {}
	self.starAddAttrsData = {}

	for id, val in csvPairs(csv.brave_challenge.cards) do
		if cardHash[val.groupID] then
			self.starAddAttrsData[val.cardID] = val
			local csvCards = csv.cards[val.cardID]
			local csvUnit  =  csv.unit[csvCards.unitID]

			local data = {
				csvID = id,
				cardId = val.cardID,
				unitId = csvCards.unitID,
				level = val.level,
				star = val.star,
				advance = val.advance,
				rarity = csvUnit.rarity,
				attr1 = csvUnit.natureType,
				attr2 = csvUnit.natureType2,
				atkType = csvCards.atkType,
				battle = 0,
				unlockTarget = val.unlockTarget,
				unlockType = val.unlockType,
				lockTip = val.unlockdesc1,
				isNew = newCardhash[id] or false
			}

			if val.unlockType == 0 then
				data.isUse = true
				table.insert(self.commonCardDatas, data)
			else
				data.isUse = unlockHash[id] or false
				table.insert(self.rateCardDatas, data)
			end
		end
	end
end

-- 数据结构整理函数
function BraveChallengeSelectCardView:setStructData(list, index)
	local newDatas = {}
	local item = {}
	local k = 0

	for id, v in pairs(list) do
		k = k + 1
		if k%index == 1 then
			if k > index then
				table.insert(newDatas, item)
			end
			item = {}
		end
		table.insert(item, v)
	end

	if #item > 0 then
		table.insert(newDatas, item)
		item = {}
	end
	return newDatas
end

-- list数据 整理 刷新
function BraveChallengeSelectCardView:setShowData(commonCardDatas, rateCardDatas)
	local tempCommonDatas = self:setStructData(commonCardDatas, 6)
	local tempRateDatas = self:setStructData(rateCardDatas, 2)
	local num = #tempCommonDatas
	if #tempCommonDatas < #tempRateDatas then
		num = #tempRateDatas
	end

	local tempDatas = {}
	for index = 1, num do
		tempDatas[index] = tempCommonDatas[index] or {}
		local list = tempRateDatas[index] or {}
		for _, info in ipairs(list) do
			table.insert(tempDatas[index], info)
		end
	end

	self.allCardDatas:update(tempDatas)
end

-- list数据 筛选 排序
function BraveChallengeSelectCardView:reflushDatas()
	local funcFilter = self:onFilterCards()
	local funcSort = self:onSortCards()

	local func = function(list)
		local tempDatas = {}
		for index, data in ipairs(list) do
			if funcFilter(data) then
				table.insert(tempDatas,data)
			end
		end
		table.sort(tempDatas, funcSort)
		return tempDatas
	end

	local tempCommonDatas = func(self.commonCardDatas)
	local tempRateDatas = func(self.rateCardDatas)
	self:setShowData(tempCommonDatas, tempRateDatas)
	--数据为空的时候增加提示
	self.rateTipPanel:visible(#tempRateDatas == 0)
	self.commonTipPanel:visible(#tempCommonDatas == 0)

end

-- 选中精灵展示
function BraveChallengeSelectCardView:showSelectCard(index, cardInfo)
	local csvCards = csv.brave_challenge.cards
	local csvID = self.selectCardData:read()[index]
	local panel = self.showPanel[index]
	local paneldownShow = panel:get("panelAddInfo")

	if not csvID then
		if panel:getChildByName("sprite") then
			panel:getChildByName("sprite"):hide()
		end
		paneldownShow:hide()
		return
	end

	local csvCard = csvCards[csvID]
	local unitID  = csv.cards[csvCard.cardID].unitID
	local csvUnit = csv.unit[unitID]

	local imgBg = panel:get("imgBg")
	if panel.csvID == csvID and panel:getChildByName("sprite") then
		panel:getChildByName("sprite"):show()
	else
		panel:removeChildByName("sprite")
		local cardSprite = widget.addAnimationByKey(panel, csvUnit.unitRes, "sprite", "standby_loop", 1)
			:scale(csvUnit.scale * 0.8)
			:xy(imgBg:x(), imgBg:y() + 15)
		cardSprite:setSkin(csvUnit.skin)
		panel.csvID = csvID
	end

	if self.baseInfo.isStarAttrAdd then
		paneldownShow:show()
		self:initDownStar(paneldownShow, csvCard.cardID)
	end
end

-- 筛选界面添加
function BraveChallengeSelectCardView:initFilterBtn()

	local pos = self.btnFilter:parent():convertToWorldSpace(self.btnFilter:box())
	pos = self:convertToNodeSpace(pos)
	local btnPos = gGameUI:getConvertPos(self.btnFilter, self:getResourceNode())

	gGameUI:createView("city.card.bag_filter", self.btnFilter):init({
		cb = self:createHandler("onBattleFilter"),
		others = {
			width = 190,
			height = 122,
			x = btnPos.x,
			y = btnPos.y,
			panelOrder = false,
			isShow = false,
			btn = self.btnFilter,
		}
	}):z(100):xy(-pos.x, -pos.y)
end

--游戏开始
function BraveChallengeSelectCardView:onBtnGame()
	local num = table.nums(self.selectCardData:read())
	if num ~= 3 then
		gGameUI:showTip(gLanguageCsv.bcSelectCardTip)
		return
	end

	if self.status:read() == "start" then
		return
	end

	gGameApp:requestServer(BCAdapt.url("preEnd"), function(tb)
		gGameUI:disableTouchDispatch(ACTION_TIME, false)
		self.parent:openOtherView("city.activity.brave_challenge.challenge_gate", 3, true)
	end, self.selectCardData:read(), self.activityId)
end

-- 点击选择函数
function BraveChallengeSelectCardView:onSelectCard(list, data, k, index)
	local cardDatas = {}
	if table.nums(self.selectCardData:read()) >= 3 and data.battle == 0 then
		gGameUI:showTip(gLanguageCsv.bcSelectCardTip02)
		return
	end
	for index, id in self.selectCardData:ipairs() do
		cardDatas[index] = id
	end

	if data.battle == 0 then
		table.insert(cardDatas, data.csvID)
	else
		for index, id in ipairs(cardDatas) do
			if id == data.csvID then
				table.remove(cardDatas, index)
				break
			end
		end
	end
	local data1 = self.allCardDatas:atproxy(k)
	data1[index].battle = data.battle == 0 and 1 or 0
	data1[index].isNew = false

	self.selectCardData:set(cardDatas)
end

-- 解锁提示函数
function BraveChallengeSelectCardView:onDelockTip(list, data)
	gGameUI:showTip(data.lockTip)
end

-- 刷选回调
function BraveChallengeSelectCardView:onBattleFilter(attr1, attr2, rarity, atkType)
	self.filterCondition:set({attr1 = attr1, attr2 = attr2, rarity = rarity, atkType = atkType}, true)
end

-- 帅选函数
function BraveChallengeSelectCardView:onFilterCards()
	local filterCondition = self.filterCondition:read()
	local condition = {}
	if not itertools.isempty(filterCondition) then
		condition = {
			{"rarity", (filterCondition.rarity < ui.RARITY_LAST_VAL) and filterCondition.rarity or nil},
			{"attr2", (filterCondition.attr2 < ui.ATTR_MAX) and filterCondition.attr2 or nil},
			{"attr1", (filterCondition.attr1 < ui.ATTR_MAX) and filterCondition.attr1 or nil},
			{"atkType", filterCondition.atkType},
		}
	end

	local function isOK(data, key, val)
		if data[key] == nil then
			if key ~= "attr2" or data.attr1 == val then
				return true
			end
		end
		if key == "atkType" then
			for k, v in ipairs(data.atkType) do
				if val[v] then
					return true
				end
			end
			return false
		end
		if data[key] == val then
			return true
		end
		return false
	end

	return function(card)
		for i = 1, #condition do
			local cond = condition[i]
			if cond[2] then
				if not isOK(card, cond[1], cond[2]) then
					return false
				end
			end
		end
		return true
	end
end

-- 返回排序函数
function BraveChallengeSelectCardView:onSortCards()
	return function(a, b)
		if a.battle ~= b.battle then
			return a.battle > b.battle
		end
		if a.isUse ~= b.isUse then
			return a.isUse
		end

		local attrA = a.rarity
		local attrB = b.rarity
		if attrA ~= attrB then
			return attrA > attrB
		end
		return a.cardId < b.cardId
	end
end

function BraveChallengeSelectCardView:getCardMaxStar(cardMarkID, isMega)
	local cards = gGameModel.role:read("cards")
	-- 背包里相同MarkID的最大星级
	local myMaxStar = 0
	-- 背包里存在的卡牌
	local existCards = {}
	-- 最大星级卡牌的dbid
	local dbid
	for k,v in ipairs(cards) do
		local card = gGameModel.cards:find(v)
		local cardId = card:read("card_id")
		local star = card:read("star")
		existCards[cardId] = true
		local csvInfo = csv.cards[cardId]
		if cardMarkID == csvInfo.cardMarkID and star > myMaxStar then

			if not isMega or (isMega and csvInfo.megaIndex ~= 0) then
				myMaxStar = star
				dbid = v
			end
		end
	end
	return myMaxStar, existCards, dbid
end


function BraveChallengeSelectCardView:getAddNum(cardId, star)
	local info = self.starAddAttrsData[cardId]
	if info then
		local index = 0
		for i, val in ipairs(info.starUnlock) do
			if star >= val then
				index = i
			end
		end

		if index ~= 0 then
			return 	dataEasy.attrSubtraction(info.addAttributes[index], "100%")
		end
	end
	return "0%"
end

function BraveChallengeSelectCardView:initDownStar(panel, cardID)
	local cardCsv = csv.cards[cardID]
	local cardMarkID = cardCsv.cardMarkID
	local isMega = cardCsv.megaIndex ~= 0
	local starNum = self:getCardMaxStar(cardMarkID, isMega)
	local upNum = self:getAddNum(cardID, starNum)

	local childs = panel:multiget("txtUp","starList", "btnDetail")
	childs.txtUp:text(upNum)

	bind.extend(self, childs.starList, {
		class = "listview",
		props = {
			data = dataEasy.getStarData(starNum),
			item = bindHelper.self("starItem"),
			onItem = function(list, node, k, v)
				node:get("icon"):texture(v.icon)
			end,
		},
	})

	bind.touch(self, childs.btnDetail, {methods = {ended = functools.partial(self.onBtnDetail, self, childs.btnDetail)}})
end


function BraveChallengeSelectCardView:onBtnDetail(btn)
	local params = {}
	local pos = btn:getParent():convertToWorldSpace(cc.p(btn:xy()))
	params.pos = cc.p(pos.x, pos.y+50)
	params.strs = {
		csv.note[125101].fmt,
		csv.note[125102].fmt,
	}

	local view = gGameUI:stackUI("city.activity.brave_challenge.tip", nil, nil, params)
	gGameUI.itemDetailView = view
end


return BraveChallengeSelectCardView