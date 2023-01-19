--
-- @desc 布阵下边操作
--

-- 筛选
local CONDITIONS = {
	{name = gLanguageCsv.fighting, attr = "fighting_point"},
	{name = gLanguageCsv.level, attr = "level"},
	{name = gLanguageCsv.rarity, attr = "rarity"},
	{name = gLanguageCsv.star, attr = "star"},
	{name = gLanguageCsv.getTime, attr = "getTime"}
}

local PRELOAD_COUNT = 13

local EmbattleCardList = class("EmbattleCardList", cc.load("mvc").ViewBase)

EmbattleCardList.RESOURCE_FILENAME = "common_battle_card_list.json"
EmbattleCardList.RESOURCE_BINDING = {
	["textNotRole"] = "emptyTxt",
	["item"] = "item",
	["list"] = "list",
	["list"] = {
		varname = "cardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("allCardDatas"),
				item = bindHelper.self("item"),
				emptyTxt = bindHelper.self("emptyTxt"),
				dataFilterGen = bindHelper.self("onFilterCards", true),
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				padding = 4,
				backupCached = false,
				onItem = function(list, node, k, v)
					node:setName("item" .. list:getIdx(k)) --新手引导要用
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							unitId = v.unit_id,
							advance = v.advance,
							rarity = v.rarity,
							star = v.star,
							grayState = (v.battle > 0) and 1 or 0,
							levelProps = {
								data = v.level,
							},
							onNode = function(panel)
								panel:xy(-4, -4)
							end,
						}
					})
					local textNote = node:get("textNote")
					textNote:visible(v.battle == 1)
					uiEasy.addTextEffect1(textNote)
					node:onTouch(functools.partial(list.clickCell, v))
				end,
				onBeforeBuild = function(list)
					list.emptyTxt:hide()
				end,
				onAfterBuild = function(list)
					local cardDatas = itertools.values(list.data)
					if #cardDatas == 0 then
						list.emptyTxt:show()
					else
						list.emptyTxt:hide()
					end
				end,
				asyncPreload = PRELOAD_COUNT,
			},
			handlers = {
				clickCell = bindHelper.self("onCardItemTouch", true),
				initItem = bindHelper.self("initItem", true),
			},
		},
	},
	["btnPanel"] = {
		varname = "btnPanel",
		binds = {
			event = "extend",
			class = "sort_menus",
			props = {
				data = bindHelper.self("sortDatas"),
				expandUp = true,
				btnClick = bindHelper.self("onSortMenusBtnClick", true),
				onNode = function(node)
					node:xy(-930, -480):z(18)
				end,
			},
		}
	},
}

function EmbattleCardList:onCreate(params, bAdaptUi)
	self.base = params.base
	self.battleCardsData = params.battleCardsData
	self.allCardDatas = params.allCardDatas
	self.clientBattleCards = params.clientBattleCards

	self.limtFunc = handler(self.base, params.limtFunc)
	-----------------卡牌操作函数-----------------
	--存在
	self.isMovePanelExist = handler(self.base, params.isMovePanelExist)
	--创建
	self.createMovePanel = handler(self.base, params.createMovePanel)
	--删除
	self.deleteMovingItem = handler(self.base, params.deleteMovingItem)
	--移动
	self.moveMovePanel = handler(self.base, params.moveMovePanel)
	--点击
	self.onCardClick = handler(self.base, params.onCardClick)
	--移动结束
	self.moveEndMovePanel = handler(self.base, params.moveEndMovePanel)
	---------------------------------------------

	self:initModel()
	self:initAllCards()
	self:adaptNode(bAdaptUi)
	self:initFilterBtn()
	idlereasy.when(self.clientBattleCards, function (_, battle)
		dataEasy.tryCallFunc(self.cardList, "filterSortItems", true)
	end)
	return self
end

-- 初始化所有cards
function EmbattleCardList:initAllCards()
	idlereasy.any({self.battleCardsData, self.cards},function (_, orignBattleCards, cards)
		-- 过滤上阵阵容不满足条件的卡
		local battleCards = {}
		for k, dbid in pairs(orignBattleCards) do
			local card = gGameModel.cards:find(dbid)
			if card then
				local cardDatas = card:read("card_id", "skin_id","fighting_point", "level", "star", "advance", "created_time", "nature_choose")
				if self.limtFunc(dbid, cardDatas.card_id,cardDatas.skin_id, cardDatas.fighting_point, cardDatas.level, cardDatas.star, cardDatas.advance, cardDatas.created_time, cardDatas.nature_choose, self:getBattle(k)) then
					battleCards[k] = dbid
				end
			else
				battleCards[k] = dbid
			end
		end

		local hash = itertools.map(battleCards, function(k, v) return v, k end)
		local all = {}
		-- 注意闭包，要使用同一个变量值ok，不能放for里面
		local ok
		for k, dbid in ipairs(cards) do
			ok = (k == #cards)
			local card = gGameModel.cards:find(dbid)
			local cardDatas = card:multigetIdler("card_id", "skin_id","fighting_point", "level", "star", "advance", "created_time", "nature_choose")
			idlereasy.any(cardDatas, function(_, card_id,skin_id, fighting_point, level, star, advance, created_time, nature_choose)
				all[dbid] = self.limtFunc(dbid, card_id,skin_id, fighting_point, level, star, advance, created_time, nature_choose, self:getBattle(hash[dbid]))
				if ok then
					dataEasy.tryCallFunc(self.cardList, "updatePreloadCenterIndex")
					-- 初始化和卡牌变动时只需要最后触发一次
					self.allCardDatas:update(all)
					self.clientBattleCards:set(battleCards, true)
				end
			end):anonyOnly(self, k)
		end
	end)
end

function EmbattleCardList:getBattle(i)
	if i and i~= 0 then
		return 1
	else
		return 0
	end
end

function EmbattleCardList:adaptNode(bAdaptUi)
	if not bAdaptUi then
		return
	end
	adapt.centerWithScreen("left", "right", nil, {
		{self.cardList, "width"},
		{self.cardList, "pos", "left"},
		{self.btnPanel, "pos", "left"},
	})
end

function EmbattleCardList:initFilterBtn()
	-- 筛选UI按钮
	self.filterCondition = idlertable.new()
	--true是降序，false升序
	self.tabOrder = idler.new(true)
	self.seletSortKey = idler.new(1)
	idlereasy.any({self.filterCondition, self.seletSortKey, self.tabOrder}, function()
		dataEasy.tryCallFunc(self.cardList, "filterSortItems", false)
	end)

	local pos = self.btnPanel:parent():convertToWorldSpace(self.btnPanel:box())
	pos = self:convertToNodeSpace(pos)
	local btnPos = gGameUI:getConvertPos(self.btnPanel, self:getResourceNode())
	self.bagFilter = gGameUI:createView("city.card.bag_filter", self.btnPanel):init({
		cb = self:createHandler("onBattleFilter"),
		others = {
			width = 190,
			height = 122,
			x = btnPos.x + 190/2,
			y = btnPos.y + 122/2,
			panelOrder = true,
		}
	}):z(19):xy(-pos.x, -pos.y)
	self.btnPanel:z(5)
end

function EmbattleCardList:initModel()
	self.cards = gGameModel.role:getIdler("cards")
	self.sortDatas = idlertable.new(arraytools.map(CONDITIONS, function(i, v) return v.name end))
end

function EmbattleCardList:onFilterCards(list)
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

function EmbattleCardList:onSortCards(list)
	local seletSortKey = self.seletSortKey:read()
	local attrName = CONDITIONS[seletSortKey].attr
	local tabOrder = self.tabOrder:read()
	return function(a, b)
		if a.battle ~= b.battle then
			return a.battle > b.battle
		end
		local attrA = a[attrName]
		local attrB = b[attrName]
		if attrA ~= attrB then
			if tabOrder then
				return attrA > attrB
			else
				return attrA < attrB
			end
		end
		return a.card_id < b.card_id
	end
end

-- 按下
function EmbattleCardList:onCardItemTouch(list, v, event)
	if event.name == "began" then
		self.moved = false
		self.touchBeganPos = event
		self.deleteMovingItem()
	elseif event.name == "moved" then
		local deltaX = math.abs(event.x - self.touchBeganPos.x)
		local deltaY = math.abs(event.y - self.touchBeganPos.y)
		if not self.moved and not self.isMovePanelExist() and (deltaX >= ui.TOUCH_MOVED_THRESHOLD or deltaY >= ui.TOUCH_MOVED_THRESHOLD) then
			-- 斜率不够或对象数量不足列表长度，判定为选中对象
			if deltaY > deltaX * 0.7 then
				local data = self.allCardDatas:atproxy(v.dbid)
				self.createMovePanel(data)
			end
			self.moved = true
		end
		self.cardList:setTouchEnabled(not self.isMovePanelExist())
		self.moveMovePanel(event)
	elseif event.name == "ended" or event.name == "cancelled" then
		if self.isMovePanelExist() == false and self.moved == false then --没有创建movePanel 说明是点击操作
			self.onCardClick(v, true)
			return
		end
		self.moveEndMovePanel(v)
	end
end

-- 排序按钮
function EmbattleCardList:onSortMenusBtnClick(panel, node, k, v, oldval)
	if oldval == k then
		self.tabOrder:modify(function(val)
			return true, not val
		end)
	else
		self.tabOrder:set(true)
	end
	self.seletSortKey:set(k)
end

-- 筛选
function EmbattleCardList:onBattleFilter(attr1, attr2, rarity, atkType)
	self.filterCondition:set({attr1 = attr1, attr2 = attr2, rarity = rarity, atkType = atkType}, true)
end

return EmbattleCardList