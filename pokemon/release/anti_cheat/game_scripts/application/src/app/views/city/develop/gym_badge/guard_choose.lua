-- @Date:   2020-08-3
-- @Desc: 守护精灵选择界面界面

local ViewBase = cc.load("mvc").ViewBase
local gymBadgeGuardChooseView = class("gymBadgeGuardChooseView", ViewBase)

-- local SHOW_BADGE = {
-- 	[1] = {
-- 		{icon = "city/develop/gym_badge/icon_bing1.png"},
-- 		{icon = "city/develop/gym_badge/icon_bing1.png"},
-- 		{icon = "city/develop/gym_badge/icon_bing1.png"},
-- 		{icon = "city/develop/gym_badge/icon_bing1.png"},
-- 		{icon = "city/develop/gym_badge/icon_bing1.png"},
-- 		{icon = "city/develop/gym_badge/icon_bing1.png"},
-- 		{icon = "city/develop/gym_badge/icon_bing1.png"},
-- 		{icon = "city/develop/gym_badge/icon_bing1.png"},
-- 	},
-- 	[2] = {
-- 		{icon = "city/develop/gym_badge/icon_bing2.png"},
-- 		{icon = "city/develop/gym_badge/icon_bing2.png"},
-- 		{icon = "city/develop/gym_badge/icon_bing2.png"},
-- 		{icon = "city/develop/gym_badge/icon_bing2.png"},
-- 		{icon = "city/develop/gym_badge/icon_bing2.png"},
-- 		{icon = "city/develop/gym_badge/icon_bing2.png"},
-- 		{icon = "city/develop/gym_badge/icon_bing2.png"},
-- 		{icon = "city/develop/gym_badge/icon_bing2.png"},
-- 	}
-- }


local SHOW_TYPE = {
	CARD = 1,
}
local SORT_DATAS = {
	{
		{name = gLanguageCsv.fighting, val = 1},
		{name = gLanguageCsv.rarity, val = 2},
		{name = gLanguageCsv.star, val = 3},
		{name = gLanguageCsv.breakthroughLevel, val = 4},
		{name = gLanguageCsv.getTime, val = 5}
	}, {
		{name = gLanguageCsv.fighting, val = 1},
		{name = gLanguageCsv.level, val = 2},
		{name = gLanguageCsv.star, val = 4},
		{name = gLanguageCsv.getTime, val = 5}
	}, {
		{name = gLanguageCsv.rarity, val = 3},
		{name = gLanguageCsv.numberPieces, val = 6},
		{name = gLanguageCsv.collectDegrees, val = 7}
	}, {
		{name = gLanguageCsv.numberPieces, val = 6},
		--搜集度（当前碎片数量/可合成所需碎片数量）
		{name = gLanguageCsv.collectDegrees, val = 7}
	}
}
--排序方法
local function sortData(data, index, order)
	if next(data) == nil then
		return {}
	end
	for k,v in pairs(data) do
		if v.num then
			v.numPercent = v.num / v.maxNum
		end
	end
	local condition = {"fight","rarity","star","advance","getTime","num","numPercent"}
	if index == nil then
		table.sort(data, function(a, b)
			for i = 1, 4 do
				if a[condition[i]] ~= b[condition[i]] then
					return a[condition[i]] > b[condition[i]]
				end
			end
			return a[condition[5]] > b[condition[5]]
		end)
	else
		table.sort(data, function(a, b)
			if a.isBg ~= b.isBg then
				return a.isBg
			end
			if a[condition[index]] ~= b[condition[index]] then
				if order then
					return a[condition[index]] > b[condition[index]]
				else
					return a[condition[index]] < b[condition[index]]
				end
			end
			if a.markId ~= b.markId then
				return a.markId < b.markId
			end
			if a.fight and b.fight then
				return a.fight > b.fight
			end
			return false
		end)
	end
	return data
end

--筛选
local function filterData(data, condition)
	if next(data) == nil then
		return {}
	end
	if condition == nil or condition[2] == nil then
		return data
	end
	local function isOK(data, key, val)
		if key == "allCards" then
			if val == true then
				return true
			else
				if not data.badge[1] then
					return true
				else
					return false
				end
			end
		end
		if key == "chooseBadge" then
			if val == 0 then
				return true
			else
				if data.badge[1] == val then
					return true
				else
					return false
				end
			end
		end
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
		-- if key == "allCards" then
		-- 	if val == true then
		-- 		return true
		-- 	else
		-- 		if not v.badge[1] then
		-- 			return true
		-- 		end
		-- 	end
		-- end
		-- if key == "chooseBadge" then
		-- 	if val == 0 then
		-- 		return true
		-- 	else
		-- 		if v.badge[1] == val then
		-- 			return true
		-- 		end
		-- 	end
		-- end
		return false
	end
	local tmp = {}
	for k,v in pairs(data) do
		if isOK(v, condition[1], condition[2]) then
			table.insert(tmp, v)
		end
	end
	return tmp
end

local function filterDo(data, conditions)
	local result = data
	for i = 1, #conditions do
		result = filterData(result, conditions[i])
	end
	return result
end

gymBadgeGuardChooseView.RESOURCE_FILENAME = "gym_badge_choose_card.json"
gymBadgeGuardChooseView.RESOURCE_BINDING = {
	["item"] = "badgeItem",
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["list1"] = {
		varname = "list1",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("badgeData"),
				item = bindHelper.self("badgeItem"),
				onItem = function(list, node, k, v)
					node:get("icon"):texture(v.icon)
					if v.isIcon == 1 then
						node:get("bg"):texture("city/card/gem/btn_yq_b.png")
					else
						node:get("bg"):texture("city/card/gem/btn_yq_h.png")
					end
					bind.click(list, node, {method = functools.partial(list.itemClick, node, k, v)})
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["sortPanel"] = {
		varname = "sortPanel",
		binds = {
			event = "extend",
			class = "sort_menus",
			props = {
				data = bindHelper.self("sortTabData"),
				showSelected = bindHelper.self("sortKey"),
				width = 245,
				height = 80,
				btnWidth = 270,
				btnHeight = 80,
				btnType = 2,
				maxCount = 4,
				expandUp = false,
				btnClick = bindHelper.self("onSortMenusBtnClick", true),
				showSortList = bindHelper.self("isDownListShow"),
				onNode = bindHelper.self("onSortMenusNode", true),
			},
		}
	},
	["allBtn"] = {
		varname = "allBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAllBtn")}
		},
	},
	["useBtn"] = {
		varname = "useBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onUseBtn")}
		},
	},
	["empty"] = "showEmpty",
	["cardItem"] = "cardItem",
	["subList"] = "subList",
	["list"] = {
		varname = "cardList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("cardDatas"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("cardItem"),
				columnSize = 3,
				onCell = function(list, node, k, v)
					local childs = node:multiget("iconPanel", "textFight", "textName", "icon", "icon1", "badge", "mask", "textPanel")
					-- if csv.unit[v.unitID].cardIcon then
					bind.extend(list, childs.iconPanel, {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							star = v.star,
							rarity = v.rarity,
							levelProps = {
								data = v.level,
							},
							onNode = function(panel)
								-- panel:xy(21, 20)
							end,
						}
					})
					-- end
					bind.click(list, node, {method = functools.partial(list.guardUp, node, k, v)})
					childs.textName:text(v.name)
					childs.textFight:text(v.fight)
					childs.icon:texture(ui.ATTR_ICON[v.attr1])
					if v.attr2 then
						childs.icon1:texture(ui.ATTR_ICON[v.attr2])
					else
						childs.icon1:hide()
					end
					if v.badge[1] then
						childs.badge:show()
						childs.badge:texture(csv.gym_badge.badge[v.badge[1]].icon)
					else
						childs.badge:hide()
					end
				end,
				asyncPreload = 18,
				leftPadding = 5,
			},
			handlers = {
				guardUp = bindHelper.self("onGuardUp"),
			},
		},
	},
}

function gymBadgeGuardChooseView:onCreate(parms)
	self.badgeNumb = parms.badgeNumb
	self.seat = parms.key
	self.setType = parms.setType
	self:initModel()
	self.sortPanel:xy(self.sortPanel:x() - 308, 1020)
	self.chooseBadge = idler.new(0) --守护某个徽章的精灵
	self.badgeData = idlers.new()
	self.cardDatas = idlertable.new({})--显示卡牌
	self.sortOrder = idler.new(true) -- order
	self.sortKey = idler.new(1) -- condition
	self.sortTabData = idlertable.new()--排序列表数据
	self.sortTabDataIndex = idler.new()
	self.attr1 = idler.new()--第一个属性
	self.attr2 = idler.new()--第二个属性
	self.rarity = idler.new() --品级
	self.atkType = idlertable.new({})
	self.type = idler.new(1)
	self.allCards = idler.new(true) --全部精灵
	--补充控制未上阵按钮
	self.notAllCardsBtn = idler.new(false)
	self.allCardsBtn = idler.new(true)

	self.isDownListShow = idler.new(false)
	self.filterPanel = gGameUI:createView("city.develop.gym_badge.guard_filter", self)
		:init({
			cb = self:createHandler("onBagFilter"),
			showIdler = self:createHandler("isDownListShow"),
			others = {
				panelOffsetX = 330,
				panelOrder = true
			}
		})
		:xy(-80, -18)

	idlereasy.any({self.type, self.rarity}, function (obj, typ, rarity)
		local newIndex = nil
		if typ == SHOW_TYPE.CARD then
			newIndex = ui.RARITY_ICON[rarity] and 2 or 1
		else
			newIndex = ui.RARITY_ICON[rarity] and 4 or 3
		end
		self.sortTabDataIndex:set(newIndex)
		local tmpSortTabData = {}
		for k,v in pairs(SORT_DATAS[newIndex]) do
			table.insert(tmpSortTabData, v.name)
		end
		self.sortTabData:set(tmpSortTabData)
		self.sortKey:set(1)
		self.sortOrder:set(true)
	end)
	self.cardInfos = idlertable.new({})
	local csvBadge = csv.gym_badge.badge
	idlereasy.when(self.cards, function(_, cards)
		local datas = {}
		local hash = dataEasy.inUsingCardsHash()
		local badgesData = self.badges:read() and self.badges:read()[self.badgeNumb] or {}
		local guards = badgesData.guards or {}
		for i,v in ipairs(cards) do
			if guards[self.seat] and guards[self.seat] == v then
			else
				local card = gGameModel.cards:find(v)
				if card then
					local cardData = card:read("card_id", "skin_id", "name", "fighting_point", "level", "star", "advance", "created_time", "locked", "equips", "effort_values", "badge_guard")
					-- local badgeGuard = cardData.badge_guard[1]
					local cardCsv = csv.cards[cardData.card_id]
					local unitCsv = csv.unit[cardCsv.unitID]
					local unitId = dataEasy.getUnitId(cardData.card_id, cardData.skin_id)
					datas[i] = {
						-- id = cardData.card_id,
						unitId = unitId,
						markId = cardCsv.cardMarkID,
						name = unitCsv.name,
						rarity = unitCsv.rarity,
						isSprite = true,
						attr1 = unitCsv.natureType,
						attr2 = unitCsv.natureType2,
						fight = cardData.fighting_point,
						level = cardData.level,
						star = cardData.star,
						advance = cardData.advance,
						dbid = v,
						battleType = hash[v],
						atkType = cardCsv.atkType,
						badge = cardData.badge_guard,
					}
					self.cardInfos:set(datas, true)
				end
			end
		end
	end)

	idlereasy.when(self.chooseBadge, function(_, chooseBadge)
		local badgeData = {}
		for k, v in ipairs(csvBadge) do
			if chooseBadge == k then
				local icon = v.showIcon2
				table.insert(badgeData, {icon = icon, isIcon = 2})
			else
				local icon = v.showIcon1
				table.insert(badgeData, {icon = icon, isIcon = 1})
			end
		end
		self.badgeData:update(badgeData)
	end)

	idlereasy.any({self.notAllCardsBtn, self.allCardsBtn}, function(_, notAllCardsBtn, allCardsBtn)
		self.allBtn:setBright(not allCardsBtn)
		self.useBtn:setBright(not notAllCardsBtn)
		text.addEffect(self.allBtn:get("txt"), {color = allCardsBtn and ui.COLORS.NORMAL.WHITE or ui.COLORS.NORMAL.RED})
		text.addEffect(self.useBtn:get("txt"), {color = not notAllCardsBtn and ui.COLORS.NORMAL.RED or ui.COLORS.NORMAL.WHITE})
	end)

	local resort = idler.new(true)
	local sortTriggers = idlereasyArgs.new(self, "sortTabDataIndex", "cardInfos", "type", "sortKey", "sortOrder", "rarity", "attr1", "attr2", "atkType", "allCards", "chooseBadge")
	local resortTimes = 0
	idlereasy.any(sortTriggers, function(...)
		resortTimes = resortTimes + 1
		performWithDelay(self, function()
			if resortTimes > 0 then
				resort:notify()
				resortTimes = 0
			end
		end, 0)
	end)

	idlerflow.if_(resort):do_(function(vars)
		local data = vars.cardInfos
		if SORT_DATAS[vars.sortTabDataIndex][vars.sortKey] then
			local tmpSortKey = SORT_DATAS[vars.sortTabDataIndex][vars.sortKey].val
			self:sortFilterData(vars.type, data, tmpSortKey, vars.sortOrder, {
				{"rarity", ui.RARITY_ICON[vars.rarity] and vars.rarity},
				{"attr2", ui.ATTR_ICON[vars.attr2] and vars.attr2},
				{"attr1", ui.ATTR_ICON[vars.attr1] and vars.attr1},
				{"atkType", vars.atkType},
				{"allCards", vars.allCards},
				{"chooseBadge", vars.chooseBadge},
			})
		end
	end, sortTriggers)



	Dialog.onCreate(self)
end

function gymBadgeGuardChooseView:initModel()
	self.cards = gGameModel.role:getIdler("cards")--卡牌
	self.badges = gGameModel.role:getIdler("badges")
end

function gymBadgeGuardChooseView:sortFilterData(typ, data, key, order, condition)
	local filter = filterDo(data, condition)
	local sortResult = sortData(filter, key, order)
	if next(sortResult) == nil then
		self.showEmpty:show()
		self.showEmpty:get("txt"):text(gLanguageCsv.noGuardCards)
	else
		self.showEmpty:hide()
	end
	if typ == SHOW_TYPE.CARD then
		-- 特殊写法，不参考
		local preloadCenter = nil
		if self.cardCenterDbid then
			for k, v in ipairs(sortResult) do
				if v.dbid == self.cardCenterDbid then
					preloadCenter = k
					break
				end
			end
		end
		self.cardList.preloadCenterIndex = preloadCenter and math.ceil(preloadCenter/self.columnSize)
		self.cardDatas:set(sortResult, true)
	end
end

function gymBadgeGuardChooseView:onBagFilter(attr1, attr2, rarity, atkType)
	self.attr1:set(attr1)
	self.attr2:set(attr2)
	self.rarity:set(rarity)
	self.atkType:modify(function()
		return true, atkType
	end)
end

function gymBadgeGuardChooseView:onSortMenusBtnClick(panel, node, k, v, oldval)
	if oldval == k then
		self.sortOrder:modify(function(val)
			return true, not val
		end)
	else
		self.sortOrder:set(true)
	end
	self.sortKey:set(k)
end

function gymBadgeGuardChooseView:onSortMenusNode(panel, node)
	node:xy(900, -448):z(20)
end

function gymBadgeGuardChooseView:onAllBtn(panel, node)
	self.allCards:set(true)
	self.chooseBadge:set(0)
	self.notAllCardsBtn:set(false)
	self.allCardsBtn:set(true)
end

function gymBadgeGuardChooseView:onUseBtn(panel, node)
	self.allCards:set(false)
	self.allCardsBtn:set(false)
	self.chooseBadge:set(0)
	self.notAllCardsBtn:set(true)
end

function gymBadgeGuardChooseView:onItemClick(panel, node, k)
	if self.chooseBadge:read() ~= k then
		self.chooseBadge:set(k)
		self.allCards:set(true)
		self.allCardsBtn:set(false)
		self.notAllCardsBtn:set(false)
	else
		self.chooseBadge:set(0)
		self.allCards:set(true)
		self.allCardsBtn:set(true)
		self.notAllCardsBtn:set(false)
	end
end

function gymBadgeGuardChooseView:onGuardUp(panel, node, k, v)
	local badgesData = self.badges:read() and self.badges:read()[self.badgeNumb] or {}
	local guards = badgesData.guards or {}
	if v.dbid == guards[self.seat] then
		gGameUI:showTip(gLanguageCsv.cardAlrealyGuard)
		return
	end
	gGameApp:requestServer("/game/badge/guard/setup", nil, self.badgeNumb, self.seat, v.dbid)
	if self.setType == 1 then
		gGameUI:showTip(gLanguageCsv.guardAlreadyChange)
	else
		gGameUI:showTip(gLanguageCsv.guardALreadySet)
	end
	ViewBase.onClose(self)
end

return gymBadgeGuardChooseView