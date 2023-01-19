-- @date 2020-8-13
-- @desc 实时匹配公平赛预设阵容

local function initItem(view, node, v)
	local id = v.cardId
	local cfg = gOnlineFightCards[id]
	local cardCfg = csv.cards[id]
	local unitCfg = csv.unit[cardCfg.unitID]
	bind.extend(view, node, {
		class = "card_icon",
		props = {
			cardId = id,
			star = cfg.star,
			rarity = unitCfg.rarity,
			advance = cfg.advance,
			onNode = function(panel)
				local bound = panel:box()
				panel:alignCenter(bound)
				panel:size(bound)
			end
		}
	})
end

local function dataOrderCmp(a, b)
	if a.rarity ~= b.rarity then
		return a.rarity > b.rarity
	end
	return a.cardId < b.cardId
end

local ViewBase = cc.load("mvc").ViewBase
local OnlineFightLimitedEmbattleView = class("OnlineFightLimitedEmbattleView", ViewBase)

OnlineFightLimitedEmbattleView.RESOURCE_FILENAME = "online_fight_limited_embattle.json"
OnlineFightLimitedEmbattleView.RESOURCE_BINDING = {
	["title"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(50, 18, 6, 255)}},
		},
	},
	["desc"] = "desc",
	["leftPanel.filterBtn.name"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["rightPanel.numTip"] = "numTip",
	["item"] = "item",
	["subList"] = "subList",
	["leftPanel"] = "leftPanel",
	["leftPanel.filterBtn"] = "filterBtn",
	["leftPanel.emptyPanel"] = "leftEmptyPanel",
	["leftPanel.list"] = {
		varname = "leftList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("leftCards"),
				columnSize = 5,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				leftEmptyPanel = bindHelper.self("leftEmptyPanel"),
				dataFilterGen = bindHelper.self("onFilterCards", true),
				dataOrderCmp = dataOrderCmp,
				topPadding = 16,
				asyncPreload = 34,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					initItem(list, node, v)
					node:onTouch(functools.partial(list.itemClick, node, k, v, 1))
				end,
				onBeforeBuild = function(list)
					list.leftEmptyPanel:hide()
				end,
				onAfterBuild = function(list)
					list.leftEmptyPanel:visible(list:getChildrenCount() <= 2)
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["rightPanel"] = "rightPanel",
	["rightPanel.list"] = {
		varname = "rightList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("rightCards"),
				columnSize = 5,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				dataOrderCmp = dataOrderCmp,
				topPadding = 16,
				asyncPreload = 34,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					initItem(list, node, v)
					node:onTouch(functools.partial(list.itemClick, node, k, v, 2))
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
}

OnlineFightLimitedEmbattleView.RESOURCE_STYLES = {
	full = true,
}

function OnlineFightLimitedEmbattleView:onCreate()
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.onlineFightEmbattleTitle, subTitle = "PREPARE A FORMATION"})
	local baseCfg = csv.cross.online_fight.base[1]
	self.leastCardNum = baseCfg.leastCardNum
	self.mostCardNum = baseCfg.mostCardNum
	self.desc:getVirtualRenderer():setLineSpacing(10)
	self.numTip:text(string.format(gLanguageCsv.onlineFightEmbattleNumTip, self.leastCardNum))

	-- 自身拥有的卡牌markId
	local cardMarkIdHash = {}
	for _, v in ipairs(gGameModel.role:read("cards")) do
		local card = gGameModel.cards:find(v)
		local markID = csv.cards[card:read("card_id")].cardMarkID
		cardMarkIdHash[markID] = true
	end
	-- 记录所有可用的卡牌
	local allCardsHash = {}
	for _, v in orderCsvPairs(csv.cross.online_fight.cards) do
		local markID = csv.cards[v.cardId].cardMarkID
		if cardMarkIdHash[markID] then
			allCardsHash[v.cardId] = true
		end
	end
	-- 初始化数据
	local limitedCards = gGameModel.role:read("cross_online_fight_limited_cards")
	local limitedCardsHash = arraytools.hash(limitedCards)
	local leftCards = {}
	local rightCards = {}
	for cardId, _ in pairs(allCardsHash) do
		local cardCfg = csv.cards[cardId]
		local unitCfg = csv.unit[cardCfg.unitID]
		local data = {
			cardId = cardId,
			rarity = unitCfg.rarity,
			attr1 = unitCfg.natureType,
			attr2 = unitCfg.natureType2,
			atkType = cardCfg.atkType,
		}
		if limitedCardsHash[cardId] then
			rightCards[cardId] = data
		else
			leftCards[cardId] = data
		end
	end
	self.leftCards = idlertable.new(leftCards)
	self.rightCards = idlertable.new(rightCards)

	self.leftPanel:removeChildByName("num")
	rich.createByStr("#C0x5B5559##L10#" .. gLanguageCsv.onlineFightEmbattleNumDesc1 .. " " .. itertools.size(allCardsHash), 50)
		:anchorPoint(1, 0.5)
		:xy(1020, 1120)
		:addTo(self.leftPanel, 5, "num")
	idlereasy.when(self.rightCards, function(_, rightCards)
		self.rightPanel:removeChildByName("num")
		local num = itertools.size(rightCards)
		local color = num >= self.leastCardNum and "#C0x88C855#" or "#C0xF13B54#"
		rich.createByStr("#C0x5B5559##L10#" .. gLanguageCsv.onlineFightEmbattleNumDesc2 .. string.format(" %s%d#C0x5B5559#/%d", color, num, self.mostCardNum), 50)
			:anchorPoint(1, 0.5)
			:xy(1020, 1120)
			:addTo(self.rightPanel, 5, "num")
		self.rightPanel:get("emptyPanel"):visible(num == 0)
	end)

	self:initFilterBtn()
end

function OnlineFightLimitedEmbattleView:changeCard(flag, v)
	if flag == 1 and itertools.size(self.rightCards:read()) >= self.mostCardNum then
		gGameUI:showTip(gLanguageCsv.onlineFightEmbattleNumMax)
		return
	end
	dataEasy.tryCallFunc(self.leftList, "updatePreloadCenterIndex")
	dataEasy.tryCallFunc(self.rightList, "updatePreloadCenterIndex")
	local removeData = flag == 1 and self.leftCards or self.rightCards
	local addData = flag == 1 and self.rightCards or self.leftCards
	removeData:modify(function(data)
		data[v.cardId] = nil
		return true, data
	end)
	addData:modify(function(data)
		data[v.cardId] = v
		return true, data
	end)
end

function OnlineFightLimitedEmbattleView:createMovingItem(v)
	if not self.hasMovingItem then
		self.hasMovingItem = true
		self.movePanel = self.item:clone()
			:addTo(self:getResourceNode(), 1000, "movePanel")
		initItem(self, self.movePanel, v)
	end
end

function OnlineFightLimitedEmbattleView:deleteMovingItem()
	if self.movePanel then
		self.movePanel:removeSelf()
		self.movePanel = nil
		return true
	end
end

function OnlineFightLimitedEmbattleView:onItemClick(list, node, k, v, flag, event)
	if event.name == "began" then
		self.touchBeganPos = event
		self.hasMovingItem = nil
		self.movingTime = 0
		self:deleteMovingItem()
		list:enableSchedule()
		list:schedule(function(delay)
			self.movingTime = self.movingTime + delay
			if self.movingTime >= 0.5 then
				self:createMovingItem(v)
				self.movePanel:xy(event)
				return false
			end
		end, 0.1, nil, "onItemClick")

	elseif event.name == "moved" then
		local deltaX = math.abs(event.x - self.touchBeganPos.x)
		local deltaY = math.abs(event.y - self.touchBeganPos.y)
		if self.hasMovingItem == nil and (deltaX >= ui.TOUCH_MOVED_THRESHOLD or deltaY >= ui.TOUCH_MOVED_THRESHOLD) then
			list:unSchedule("onItemClick")
			-- 斜率不够或对象数量不足列表长度，判定为选中对象
			self.hasMovingItem = false
			if deltaX > deltaY * 0.7 then
				self:createMovingItem(v)
			end
		end
		self.leftList:setTouchEnabled(not self.hasMovingItem)
		if self.movePanel then
			self.movePanel:xy(event)
		end
	elseif event.name == "ended" or event.name == "cancelled" then
		list:unSchedule("onItemClick")
		-- 点击
		if self.hasMovingItem == nil then
			self:changeCard(flag, v)
		end
		self.hasMovingItem = nil
		-- 移动
		if self:deleteMovingItem() then
			if flag == 1 and cc.rectContainsPoint(self.rightPanel:box(), event) then
				self:changeCard(flag, v)

			elseif flag == 2 and cc.rectContainsPoint(self.leftPanel:box(), event) then
				self:changeCard(flag, v)
			end
		end
	end
end

function OnlineFightLimitedEmbattleView:onClose()
	local limitedCards = gGameModel.role:read("cross_online_fight_limited_cards")
	local rightCards = self.rightCards:read()
	local cards = itertools.map(rightCards, function(k, v) return v.cardId end)
	table.sort(cards, function(a, b)
		return a < b
	end)
	if not itertools.equal(limitedCards, cards) then
		local function cb()
			gGameApp:requestServer("/game/cross/online/deploy", function (tb)
				ViewBase.onClose(self)
				gGameUI:showTip(gLanguageCsv.positionSave)
			end, cards, 2)
		end
		if itertools.size(cards) < self.leastCardNum then
			gGameUI:showDialog({content = string.format(gLanguageCsv.onlineFightEmbattleCloseTip, self.leastCardNum), cb = cb, btnType = 2, isRich = true, clearFast = true})
		else
			cb()
		end
	else
		ViewBase.onClose(self)
	end
end
function OnlineFightLimitedEmbattleView:initFilterBtn()
	-- 筛选UI按钮
	self.filterCondition = idlertable.new()
	idlereasy.when(self.filterCondition, function()
		dataEasy.tryCallFunc(self.leftList, "filterSortItems", false)
	end)

	local pos = self.filterBtn:parent():convertToWorldSpace(self.filterBtn:box())
	pos = self:convertToNodeSpace(pos)
	gGameUI:createView("city.card.bag_filter", self.filterBtn):init({
		cb = self:createHandler("onBattleFilter"),
		others = {
			width = 280,
			height = 122,
			scale = 0.8,
			x = gGameUI:getConvertPos(self.filterBtn, self:getResourceNode()),
			panelOrder = true,
			subPanelOrder = true,
			panelOffsetX = 730,
			panelOffsetY = 620,
		}
	}):z(19):xy(-pos.x, -pos.y)
end

-- 筛选
function OnlineFightLimitedEmbattleView:onBattleFilter(attr1, attr2, rarity, atkType)
	self.filterCondition:set({attr1 = attr1, attr2 = attr2, rarity = rarity, atkType = atkType}, true)
end

function OnlineFightLimitedEmbattleView:onFilterCards(list)
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
	return function(dbid, card)
		for i = 1, #condition do
			local cond = condition[i]
			if cond[2] then
				if not isOK(card, cond[1], cond[2]) then
					return false
				end
			end
		end
		return true, dbid
	end
end

return OnlineFightLimitedEmbattleView