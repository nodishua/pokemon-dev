-- @date:   2019-06-21
-- @desc:   携带道具背包界面
local LIST_WIDTH = 350

local HeldItemTools = require "app.views.city.card.helditem.tools"
local function setCostTxt(panel, myCoin, needCoin)
	local cost = panel:get("cost")
	cost:text(needCoin)
	local coinColor = (myCoin >= needCoin) and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.RED
	text.addEffect(cost, {color = coinColor})
	adapt.oneLinePos(cost, panel:get("note"), cc.p(8,0), "right")
	adapt.oneLinePos(cost, panel:get("icon"), cc.p(18,0))
end

local function setEffect(parent, effectName, cb)
	local effect = parent:get(effectName)
	if not effect then
		effect = widget.addAnimationByKey(parent, "koudai_gonghuixunlian/gonghuixunlian.skel", effectName, "fangguang2", 10)
			:xy(40, 20)
			:scale(0.25)
		effect:setSpriteEventHandler(function(event, eventArgs)
			effect:hide()
			if cb then
				cb()
			end
		end, sp.EventType.ANIMATION_COMPLETE)
	else
		effect:show():play("fangguang2")
	end
end
local function createAttrRichText(parent, csvId, advance, isNext)
	parent:removeAllChildren()
	local strTab = {}
	local cfg = csv.held_item.items[csvId]
	local data = {}
	data.cfg = cfg
	data.csvId = csvId
	data.advance = advance
	for i=1,100 do
		local effectVal = cfg[string.format("effect%dLevelAdvSeq", i)]
		if not cfg["effect" .. i] or cfg["effect" .. i] == 0 or not effectVal or advance < effectVal[1] then
			break
		end
		local resultStr = HeldItemTools.getStrinigByData(i, data)
		table.insert(strTab, resultStr)
	end
	local targetStr = table.concat(strTab, '\n')
	if cfg.effect2LevelAdvSeq[1] == advance and isNext then
		targetStr = targetStr .. "#Icommon/icon/txt_new.png-132-54#"
	end
	beauty.textScroll({
		list = parent,
		strs = "#C0x5B545B#" .. targetStr,
		isRich = true,
		fontSize = 40,
	})
end
local function getAttrNum(cfg, level, advance, i)
	-- 属性显示
	local attrNumRates = cfg.attrNumRates
	local advanceAttrTab = csv.held_item.advance_attrs[advance]
	local advAttrNum = advanceAttrTab["attrNum" .. cfg.advanceAttrSeq]
	local advAttrRate = advanceAttrTab["attrRate" .. cfg.advanceAttrSeq]
	local lvAttrNum = csv.held_item.level_attrs[level]["attrNum" .. cfg.strengthAttrSeq]
	return attrNumRates[i] * advAttrRate[i] * (lvAttrNum[i] + advAttrNum[i])
end

local function setCardIcon(view, panel, cardDbId)
	if cardDbId then
		local card = gGameModel.cards:find(cardDbId):read("card_id", "skin_id", "advance", "level", "star")
		local cardCfg = csv.cards[card.card_id]
		local unitCfg = csv.unit[cardCfg.unitID]
		local unitId = dataEasy.getUnitId(card.card_id, card.skin_id)
		bind.extend(view, panel, {
			class = "card_icon",
			props = {
				levelProps = {
					data = card.level,
				},
				rarity = unitCfg.rarity,
				unitId = unitId,
				advance = card.advance,
				star = card.star,
				onNode = function(node)
					node:x(-7)
				end
			}
		})
	end
end
local function setItemIcon(list, node, v, noColor, showAddBtn)
	bind.extend(list, node, {
		class = "icon_key",
		props = {
			data = {
				key = v.csvId,
				csvId = v.csvId,
				num = v.selectNum,
				targetNum = v.targetNum,
				noColor = noColor,
			},
			specialKey = {
				lv = v.lv,
			},
			grayState = showAddBtn and 1 or 0,
			onNode = function(panel)
				panel:setTouchEnabled(false)
			end
		}
	})
end
local function getItemCfg(csvId)
	if csv.held_item.items[csvId] then
		return csv.held_item.items[csvId]
	else
		return csv.items[csvId]
	end
end

local function isSpecialItem(id)
	for k,v in ipairs(gHeldItemExpCsv) do
		if v.id == id then
			return true
		end
	end

	return false
end

local ViewBase = cc.load("mvc").ViewBase
local HeldItemAdvanceView = class("HeldItemAdvanceView", ViewBase)
HeldItemAdvanceView.RESOURCE_FILENAME = "held_item_advance.json"
HeldItemAdvanceView.RESOURCE_BINDING = {
	["tabItem"] = "tabItem",
	["tabList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("tabItem"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("select")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
					else
						selected:hide()
						panel = normal:show()
					end
					-- panel:get("txt"):text(v.name)
					local maxHeight = panel:getSize().height - 40
					adapt.setAutoText(panel:get("txt"),v.name, maxHeight)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
					if v.redHint then
						list.state = v.select ~= true
						bind.extend(list, node, v.redHint)
					end
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabItemClick"),
			},
		},
	},
	["leftPanel"] = "leftPanel",
	["attrItem"] = "attrItem",
	["leftPanel.attrSubList"] = "attrSubList",
	["leftPanel.attrList"] = {
		varname = "attrList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("attrSubList"),
				cell = bindHelper.self("attrItem"),
				asyncPreload = 6,
				columnSize = 2,
				onCell = function(list, node, k, v)
					local childs = node:multiget(
						"txtName",
						"txtNum",
						"txtNote1",
						"txtAdd",
						"icon",
						"txtNote2",
						"maxIcon",
						"imgIcon"
					)
					childs.imgIcon:texture(ui.ATTR_LOGO[v.attrIconName])
					childs.txtName:text(v.attrName)
					childs.txtNum:text(math.floor(v.val))
					childs.txtAdd:text("+"..math.floor(v.valExtra))
					adapt.oneLinePos(childs.txtName, childs.txtNum, cc.p(20, 0))
					adapt.oneLinePos(childs.txtNum, childs.txtNote1, cc.p(20, 0))
					adapt.oneLinePos(childs.txtNote1, {childs.txtAdd, childs.icon, childs.txtNote2}, cc.p(5, 0))
					adapt.oneLinePos(childs.txtNum, childs.maxIcon, cc.p(20, 0))
					childs.maxIcon:visible(v.isMax)
					itertools.invoke({childs.txtNote1, childs.txtAdd, childs.icon, childs.txtNote2}, (v.isMax or v.valExtra <= 0) and "hide" or "show")
				end,
			},
		},
	},
	["strengthenPanel"] = "strengthenPanel",
	["item"] = "item",
	["strengthenPanel.itemSubList"] = "itemSubList",
	["strengthenPanel.itemList"] = {
		varname = "itemList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("itemDatas"),
				item = bindHelper.self("itemSubList"),
				cell = bindHelper.self("item"),
				asyncPreload = 20,
				columnSize = 5,
				leftPadding = 10,
				topPadding = 10,
				onCell = function(list, node, k, v)
					local t = list:getIdx(k)
					setItemIcon(list, node, v, true)
					node:get("mask"):hide()
					node:get("subIcon"):visible(v.selectNum > 0)
					node:get("select"):visible(v.select == true)
					node:onTouch(functools.partial(list.itemClick, t, node, v))
					bind.touch(list, node:get("subIcon"), {methods = {ended = functools.partial(list.subClick, t, v)}})
				end,
				asyncPreload = 24,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				afterBuild = bindHelper.self("onAfterBuild"),
				itemClick = bindHelper.self("onSelectItemClick"),
				subClick = bindHelper.self("onItemReduceClick"),
			},
		},
	},
	["strengthenPanel.btnStrengthen"] = {
		varname = "btnStrengthen",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onStrengthenClick")},
		},
	},
	["strengthenPanel.btnSub"] = {
		varname = "btnSub",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onReduceClick")}
		}
	},
	["strengthenPanel.btnAdd"] = {
		varname = "btnAdd",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddClick")}
		}
	},
	["strengthenPanel.slider"] = "slider",
	["advancePanel"] = "advancePanel",
	["advancePanel.itemList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("costItemDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					setItemIcon(list, node, v, false, v.selectNum < v.targetNum)
					node:get("mask"):visible(v.selectNum < v.targetNum)
					node:get("subIcon"):hide()
					node:get("select"):hide()
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
				asyncPreload = 4,
			},
			handlers = {
				clickCell = bindHelper.self("onLeftItemClick"),
			},
		},
	},
	["advancePanel.btnAdvance"] = {
		varname = "btnAdvance",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAdvanceClick")},
		},
	},
	["advancePanel.btnInfo"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onInfoClick")},
		},
	},
	["advancePanel.clickTipPanel"] = "clickTipPanel",
	["advancePanel.clickTipPanel.txt1"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		},
	},
	["advancePanel.clickTipPanel.txt2"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		},
	},
}

function HeldItemAdvanceView:onCreate(dbId)
	self.strengthenPanel:get("empty"):hide()
	local txtEmpty = self.strengthenPanel:get("empty"):get("textNote")
	adapt.setTextAdaptWithSize(txtEmpty, {size = cc.size(520, 200), vertical = "center", horizontal = "center"})
	self.dbId = dbId[1] or dbId
	self:initModel()
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.carryItem, subTitle = "CARRY PROP"})
	self.tabDatas = {
		{
			name = gLanguageCsv.equipStrengthen,
			redHint = {
				class = "red_hint",
				props = {
					state = bindHelper.self("state"),
					listenData = {
						curDbId = self.dbId,
						checkDress = true,
					},
					specialTag = "heldItemLevelUp",
					-- onNode = function (node)
					-- 	node:xy(266, 120)
					-- 		:z(10)
					-- end
				}
			}
		},
		{
			name = gLanguageCsv.advance,
			redHint = {
				class = "red_hint",
				props = {
					state = bindHelper.self("state"),
					listenData = {
						curDbId = self.dbId,
						checkDress = true,
					},
					specialTag = "heldItemAdvanceUp",
					-- onNode = function (node)
					-- 	node:xy(266, 120)
					-- 		:z(10)
					-- end
				}
			}
		}
	}
	self.tabDatas = idlers.newWithMap(self.tabDatas)
	self.showTab = idler.new(1)
	--模拟的总经验
	self.totalExp = idler.new(0)
	--属性加成数据
	self.attrDatas = idlers.new()
	self.showTab:addListener(function(val, oldval, idler)
		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true
		self.advancePanel:visible(val == 2)
		self.strengthenPanel:visible(val == 1)
		self.leftPanel:get("strengthenPanel"):visible(val == 1)
		self.leftPanel:get("advancePanel"):visible(val == 2)
	end)
	--物品数据
	self.itemDatas = idlers.new()
	--所有可消耗的物品
	self.canCostItems = idlertable.new({})
	--选择的物品数量
	self.selectItemNum = idler.new(1)
	--选择的物品ID
	self.selectItemIdx = idler.new(1)
	--突破需要消耗的物品
	self.costItemDatas = idlers.new()
	local oldSelectItemIdx
	--监听物品总数
	idlereasy.any({self.heldItems, self.items}, function(_, heldItems, items)
		local itemDatas = {}
		local t = {}
		for _,v in pairs(heldItems) do
			local heldItem = gGameModel.held_items:find(v)
			if heldItem then
				local itemData = heldItem:read("held_item_id", "advance", "sum_exp", "card_db_id", "exist_flag")
				if not t[itemData.held_item_id] then
					t[itemData.held_item_id] = {num = 0, itemType = 2}
				end
				if itemData.advance == 0
					and itemData.sum_exp == 0
					and not itemData.card_db_id
					and itemData.exist_flag
					and v ~= self.dbId then
						t[itemData.held_item_id].num = t[itemData.held_item_id].num + 1
				end
			end
		end
		for _, cfg in ipairs(gHeldItemExpCsv) do
			local i = cfg.id
			if items[i] then
				if not t[i] then
					t[i] = {num = 0}
				end
				t[i].num = items[i]
				t[i].itemType = 1
			end
		end
		self.canCostItems:set(t)
		local datas = {}
		for k,v in pairs(t) do
			local csvItems = getItemCfg(k)
			local isExc = false
			if v.itemType == 2 then
				isExc = csvSize(csvItems.exclusiveCards) > 0
			end
			local stackMax = dataEasy.itemStackMax(k)
			if v.num > 0 then
				local data = {}
				data.cfg = csvItems
				data.heldItemExp = v.itemType == 2 and csvItems.heldItemExp or csvItems.specialArgsMap.heldItemExp
				data.csvId = k
				data.selectNum = 0
				data.targetNum = math.min(stackMax, v.num)
				data.isExc = isExc
				data.itemType = v.itemType
				table.insert(datas, data)
			end
		end
		table.sort(datas, function(a, b)
			if a.itemType ~= b.itemType then
				return a.itemType < b.itemType
			end
			if a.cfg.quality ~= b.cfg.quality then
				return a.cfg.quality < b.cfg.quality
			end
			if a.targetNum ~= b.targetNum then
				return a.targetNum > b.targetNum
			end
			return a.csvId < b.csvId
		end)
		self.selectItemIdx:set(0, true)
		self.itemDatas:update(datas)
		self.selectItemNum:set(0, true)
	end)

	self.needStrengthenGold = idler.new(0)
	self.clientLevel = 0
	--监听选择的物品 和物品数量
	idlereasy.any({self.selectItemIdx, self.selectItemNum, self.level}, function(_, selectItemIdx, selectItemNum, level)
		local itemData = self.itemDatas:atproxy(selectItemIdx)
		if itemData then
			if oldSelectItemIdx ~= selectItemIdx then
				oldSelectItemIdx = selectItemIdx
				self.selectItemNum:set(itemData.selectNum, true)
			else
				local selectNum = selectItemNum
				itemData.selectNum = level < self.maxLevel and selectNum or 0
				self.slider:setPercent(math.min(math.ceil(selectNum/itemData.targetNum*100), 100))
				self:setStrengthenPanel(itemData)
				local notAdd = (selectNum >= itemData.targetNum) or level >= self.maxLevel or self.clientLevel >= self.maxLevel
				local notSub = (selectNum <= 0) or level >= self.maxLevel
				cache.setShader(self.btnAdd, false, notAdd and "hsl_gray" or  "normal")
				cache.setShader(self.btnSub, false, notSub and "hsl_gray" or  "normal")
				self.btnAdd:setTouchEnabled(not notAdd)
				self.btnSub:setTouchEnabled(not notSub)
				self.slider:setTouchEnabled(level < self.maxLevel)
			end
		else
			self.slider:setPercent(0)
			self:setStrengthenPanel()
			self.slider:setTouchEnabled(false)
			uiEasy.setBtnShader(self.btnAdd, nil, 2)
			uiEasy.setBtnShader(self.btnSub, nil, 2)
		end
	end)
	--选中框
	self.selectItemIdx:addListener(function(val, oldval)
		local itemDatas = self.itemDatas:atproxy(val)
		local oldItemDatas = self.itemDatas:atproxy(oldval)
		if oldItemDatas then
			oldItemDatas.select = false
		end
		if itemDatas then
			itemDatas.select = true
		end
	end)
	--设置强化消耗的金币
	idlereasy.any({self.gold, self.needStrengthenGold},function(_, gold, needStrengthenGold)
		setCostTxt(self.strengthenPanel:get("costPanel"), gold, needStrengthenGold)
	end)
	--监听 突破 强化 模拟强化的数据
	idlereasy.any({self.level, self.advance, self.sumExp, self.totalExp, self.showTab}, function(_, level, advance, sumExp, totalExp)
		self:setLeftPanel(level, advance, sumExp, totalExp)
		local notStrengthen = level >= self.maxLevel and totalExp <= 0
		uiEasy.setBtnShader(self.btnStrengthen, self.btnStrengthen:get("title"), notStrengthen and 2 or 1)
	end)
	--选择物品数量进度条
	self.slider:addEventListener(function(sender,eventType)
		if eventType == ccui.SliderEventType.percentChanged then
			local percent = sender:getPercent()
			local itemData = self.itemDatas:atproxy(self.selectItemIdx:read())
			if itemData then
				local totalExp = self:getClientTotalExp(self.selectItemIdx:read())
				local totalExpMax = self:getMaxTotalExp()
				local maxSelectNum = math.ceil((totalExpMax - totalExp)/itemData.heldItemExp)
				local selectNum = math.floor((itemData.targetNum * percent)/100)
				self.selectItemNum:set(math.min(selectNum, itemData.targetNum, maxSelectNum), true)
			end
		end
	end)
	--监听 突破数据
	idlereasy.any({self.advance, self.showTab}, function(_, advance, showTab)
		if showTab == 2 then
			self:setAdvancePanel(advance)
		end
	end)

	self.leftPanel:get("cardNote"):visible(self.cardDbId ~= nil)
	setCardIcon(self, self.leftPanel:get("cardIcon"), self.cardDbId)
end

function HeldItemAdvanceView:initModel()
	self.heldItems = gGameModel.role:getIdler("held_items")
	self.items = gGameModel.role:getIdler("items")
	self.gold = gGameModel.role:getIdler("gold")
	local item = gGameModel.held_items:find(self.dbId)
	local itemData = item:multigetIdler("held_item_id", "sum_exp", "id", "card_db_id", "advance", "level", "exist_flag")
	self.sumExp = idler.new(0)
	self.advance = idler.new(0)
	self.level = idler.new(1)
	self.existFlag = idler.new(0)
	idlereasy.any(itemData, function(_, held_item_id, sum_exp, id, card_db_id, advance, level, exist_flag)
		self.maxLevel = csv.held_item.items[held_item_id].strengthMax
		self.heldItemId = held_item_id
		self.sumExp:set(sum_exp)
		self.id = id
		self.cardDbId = card_db_id
		self.advance:set(advance)
		self.level:set(level)
		self.existFlag:set(exist_flag)
	end)
end
--设置突破面板
function HeldItemAdvanceView:setAdvancePanel(advance)
	local csvItems = csv.held_item.items[self.heldItemId]
	local costItemCfg = csv.held_item.advance[advance]
	local needItems = costItemCfg and costItemCfg["costItemMap"..csvItems.advanceSeqID] or {}
	local costItemDatas = {}

	self.costHeldItemIDs = {}
	self.costItemIDs = {}
	self.advanceCostNum = 0
	for k,v in csvPairs(needItems) do
		local cfg = getItemCfg(k)
		table.insert(costItemDatas, {
			csvId = k,
			selectNum = 0,
			targetNum = v,
			isExc = cfg.exclusiveCards and csvSize(cfg.exclusiveCards) > 0,
			itemType = cfg.exclusiveCards and 2 or 1
		})
	end
	self.costItemDatas:update(costItemDatas)
	local childs = self.advancePanel:multiget(
		"attrNote",
		"nextNote",
		"attrList",
		"nextList",
		"costNote",
		"textTip",
		"itemList",
		"btnAdvance",
		"maxIcon"
	)
	self.advanceMax = advance >= csvItems.advanceMax
	self.levelNotEnough = false
	childs.textTip:hide()
	if not self.advanceMax then
		local advanceLvLimit = csvItems.advanceLvLimit[advance+1]
		self.levelNotEnough = self.level:read() < advanceLvLimit
		childs.textTip:visible(self.levelNotEnough):text(string.format(gLanguageCsv.breakthroughInStrengtheningLv, advanceLvLimit))
		createAttrRichText(childs.nextList, self.heldItemId, advance+1, true)
	end
	createAttrRichText(childs.attrList, self.heldItemId, advance)
	itertools.invoke({childs.nextNote, childs.nextList, childs.costNote, childs.itemList, childs.btnAdvance}, self.advanceMax and "hide" or "show")
	childs.maxIcon:visible(self.advanceMax)
	self.clickTipPanel:visible(not self.advanceMax)
	self:setLeftAdvancePanel(advance)
	self:adaptAdvancePanelList(childs)

end

function HeldItemAdvanceView:adaptAdvancePanelList(childs)
	local func = function(list, dot)
		local innerSize = list:getInnerContainerSize()
		local size = list:size()
		if innerSize.height >= size.height then
			innerSize.height = innerSize.height > LIST_WIDTH and LIST_WIDTH or innerSize.height
			list:size(innerSize)
			dot = dot + innerSize.height - size.height
			list:y(list:y() - dot)
		end
		return dot
	end

	local dot = 0
	dot = dot + func(childs.attrList, dot)
	childs.nextNote:y(childs.nextNote:y() - dot)
	func(childs.nextList, dot)
end
--设置左侧突破面板
function HeldItemAdvanceView:setLeftAdvancePanel(advance)
	local childs = self.leftPanel:get("advancePanel"):multiget(
		"iconMax",
		"level1",
		"level2",
		"iconArrow"
	)
	childs.iconMax:visible(self.advanceMax)
	childs.level1:text("+"..advance)
	adapt.oneLinePos(childs.level1, childs.iconMax, cc.p(20, 0))
	childs.level2:text("+"..advance + 1):visible(not self.advanceMax)
end
--设置左侧面板
function HeldItemAdvanceView:setLeftPanel(level, advance, sumExp, totalExp)
	local childs = self.leftPanel:multiget(
		"itemName",
		"itemIcon",
		"itemIconBg",
		"strengthenPanel",
		"advancePanel"
	)
	local csvItems = csv.held_item.items[self.heldItemId]
	local advanceStr = advance > 0 and "+".. advance or ""
	childs.itemName:text(csvItems.name..advanceStr)
	local quality = csvItems.quality
	text.addEffect(childs.itemName, {color= quality == 1 and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.QUALITY[quality]})
	childs.itemIcon:texture(csvItems.icon)
	childs.itemIconBg:texture(string.format("city/card/helditem/strengthen/img_dt%d.png", csvItems.quality))
	local clientLevel = level
	local sum_exp = sumExp + totalExp
	local needExp
	local maxLevel = self.maxLevel
	for i=1,maxLevel do
		needExp = csv.held_item.level[i]["levelExp"..csvItems.strengthSeqID]
		if i >= maxLevel or sum_exp < needExp then
			clientLevel = i
			sum_exp = sum_exp
			break
		end
		sum_exp = sum_exp - needExp
	end
	local strengthenPanel = childs.strengthenPanel:multiget(
		"iconMax",
		"level1",
		"level2",
		"iconArrow",
		"bar",
		"percent"
	)
	strengthenPanel.iconMax:visible(level >= maxLevel or clientLevel >= maxLevel)
	strengthenPanel.level1:text("Lv"..level)
	strengthenPanel.level2:text(clientLevel):visible(clientLevel > level)
	if level >= maxLevel then
		adapt.oneLinePos(strengthenPanel.level1, strengthenPanel.iconMax, cc.p(20, 0))
	else
		adapt.oneLinePos(strengthenPanel.level2, strengthenPanel.iconMax, cc.p(20, 0), "left")
	end
	strengthenPanel.iconArrow:visible(clientLevel > level)
	strengthenPanel.bar:setPercent(sum_exp/needExp*100)
	strengthenPanel.percent:text(sum_exp.."/"..needExp)
	if self.tmpShowTab ~= self.showTab:read()
		or self.clientLevel ~= clientLevel
		or self.tmpAdvance ~= advance
		or totalExp == 0 then
			self.tmpAdvance = advance
			self.clientLevel = clientLevel
			self.tmpShowTab = self.showTab:read()
			self:setAttrDatas(level, advance, clientLevel)
	end
end
--获取到满级所需的经验
function HeldItemAdvanceView:getMaxTotalExp()
	local csvItems = csv.held_item.items[self.heldItemId]
	local sum_exp = 0
	local maxLevel = self.maxLevel
	for i=1,maxLevel do
		local needExp = csv.held_item.level[i]["levelExp"..csvItems.strengthSeqID]
		if i >= maxLevel then
			break
		end
		sum_exp = sum_exp + needExp
	end
	return sum_exp - self.sumExp:read()
end
--设置属性数据
function HeldItemAdvanceView:setAttrDatas(level, advance, clientLevel)
	local cfg = csv.held_item.items[self.heldItemId]
	local attrDatas = {}
	local clientLevel = self.showTab:read() == 1 and clientLevel or level
	local clientAdvance = math.min((self.showTab:read() == 2 and advance + 1 or advance), cfg.advanceMax)
	local isMax = (self.showTab:read() == 2 and self.advanceMax) or (self.showTab:read() == 1 and level >= self.maxLevel)
	for i,v in ipairs(cfg.attrTypes) do
		local data = {}
		local attr = game.ATTRDEF_TABLE[v]
		local attrName = gLanguageCsv["attr" .. string.caption(attr)]
		data.attrName = attrName
		data.val = getAttrNum(cfg, level, advance, i)
		data.valExtra = getAttrNum(cfg, clientLevel, clientAdvance, i) - data.val
		data.isMax = isMax
		data.attrIconName = attr
		table.insert(attrDatas, data)
	end
	self.attrDatas:update(attrDatas)
end
--设置强化面板
function HeldItemAdvanceView:setStrengthenPanel(itemData)
	local childs = self.strengthenPanel:multiget(
		"itemName",
		"exp",
		"numNote1",
		"num",
		"numNote2",
		"btnSub",
		"btnAdd",
		"costPanel"
	)
	if itemData then
		childs.itemName:text(itemData.cfg.name)
		text.addEffect(childs.itemName, {color= itemData.cfg.quality == 1 and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.QUALITY[itemData.cfg.quality]})
	end
	childs.itemName:visible(itemData ~= nil)
	local totalExp, totalItemNum = self:getClientTotalExp()
	self.totalExp:set(totalExp)
	self.needStrengthenGold:set(totalExp * gCommonConfigCsv.heldItemExpNeedGold)
	--显示单个数量和经验
	local exp = 0
	local num = "0/0"
	local itemData = self.itemDatas:atproxy(self.selectItemIdx:read())
	if itemData then
		exp = itemData.selectNum * itemData.heldItemExp
		num = itemData.selectNum .. "/" .. itemData.targetNum
	end
	childs.exp:text(exp)
	childs.num:text(num)
	adapt.oneLinePos(childs.numNote2, childs.num, cc.p(10, 0), "right")

	if matchLanguage({"cn", "tw"}) then
		adapt.oneLinePos(childs.num, childs.numNote1, cc.p(-10, 0), "right")
	else
		adapt.oneLinePos(childs.num, childs.numNote1, cc.p(5, 0), "right")
	end
end
--获取选择物品的总数量总经验
function HeldItemAdvanceView:getClientTotalExp(idx)
	local totalExp = 0
	local totalItemNum = 0
	for k ,v in self.itemDatas:pairs() do
		local info = v:proxy()
		if info.selectNum > 0 and (not idx or idx ~= k) then
			totalExp = totalExp + info.heldItemExp * info.selectNum
			totalItemNum = totalItemNum + info.selectNum
		end
	end
	return totalExp, totalItemNum, heldItemExp
end
--增加物品数量
function HeldItemAdvanceView:onAddClick()
	self.selectItemNum:set(self.selectItemNum:read()+1)
end
--减少物品数量
function HeldItemAdvanceView:onReduceClick()
	self.selectItemNum:set(math.max(self.selectItemNum:read()-1, 0))
end
--item里的减号 减少物品数量
function HeldItemAdvanceView:onItemReduceClick(list, t, v)
	self.selectItemIdx:set(t.k, true)
	self.selectItemNum:set(math.max(v.selectNum-1, 0))
end

function HeldItemAdvanceView:playAction(parent, target)
	local cloneItem = target:get("_icon_.icon"):clone()
	parent:add(cloneItem, 999)
	local x, y = target:xy()
	local pos = target:getParent():convertToWorldSpace(cc.p(x, y))
	pos = parent:convertToNodeSpace(pos)
	cloneItem:xy(pos.x, pos.y)
	x, y = self.leftPanel:get("strengthenPanel.bar"):xy()
	pos = self.leftPanel:get("strengthenPanel"):convertToWorldSpace(cc.p(x, y))
	pos = parent:convertToNodeSpace(pos)
	transition.executeSequence(cloneItem, true)
		:moveTo(0.4, pos.x, pos.y)
		:func(function()
			cloneItem:removeFromParent()
		end)
		:done()
end

--选中材料
function HeldItemAdvanceView:onSelectItemClick(list, t, node, v, event)
	if self.clientLevel >= self.maxLevel or self.level:read() >= self.maxLevel then
		return
	end
	local beganTouchPos
	local hasEft, tipState = false, false
	local time, cur = 0, self.selectItemNum:read()
	if event.name == "began" then
		self.isLongTouch = false
		tipState = false
		cur = v.selectNum
		beganTouchPos = node:getTouchBeganPosition()
		self:enableSchedule():schedule(function(dt)
			time = time + dt
			if time > 0.5 then
				local max = self.itemDatas:atproxy(t.k).targetNum
				if self.clientLevel >= self.maxLevel or self.level:read() >= self.maxLevel or max <= cur then
					cur = 0
					return false
				end
				self.isLongTouch = true
				local perSel = self.selectItemIdx:read()
				if perSel ~= t.k and v.cfg.quality >= 4 and v.selectNum == 0 and not tipState then
					if not isSpecialItem(v.csvId) then
						tipState = true
						gGameUI:showDialog({content = gLanguageCsv.advancedQualityCarryingProps, btnStr = gLanguageCsv.tips, cb = function()
							self.selectItemIdx:set(t.k, true)
						end, btnType = 2})
					else
						self.selectItemIdx:set(t.k, true)
					end

				elseif perSel ~= t.k and (v.cfg.quality < 4 or v.selectNum > 0) then
					self.selectItemIdx:set(t.k, true)

				elseif perSel == t.k then
					cur = cur + 1
					self.selectItemNum:set(cur)
					self:playAction(self.strengthenPanel, node)
				end
			end
		end, 0.1, 0, "efcschedule")

	elseif event.name == "moved" then
		if not beganTouchPos then
			beganTouchPos = node:getTouchBeganPosition()
		end
		local dx = math.abs(event.x - beganTouchPos.x)
		local dy = math.abs(event.y - beganTouchPos.y)
		if dx >= ui.TOUCH_MOVE_CANCAE_THRESHOLD or dy >= ui.TOUCH_MOVE_CANCAE_THRESHOLD then
			self.isLongTouch = true
			self:unSchedule("efcschedule")
		end

	elseif event.name == "ended" or event.name == "cancelled" then
		self:unSchedule("efcschedule")
		-- 点击
		if not self.isLongTouch then
			local perSelIdx = self.selectItemIdx:read()
			local max = self.itemDatas:atproxy(t.k).targetNum
			local cur = self.selectItemNum:read()
			if perSelIdx ~= t.k then
				if v.cfg.quality >= 4 and v.selectNum == 0 and not isSpecialItem(v.csvId) then
					gGameUI:showDialog({content = gLanguageCsv.advancedQualityCarryingProps, btnStr = gLanguageCsv.tips, cb = function()
						self.selectItemIdx:set(t.k, true)
					end, btnType = 2})
				else
					self.selectItemIdx:set(t.k, true)
				end

			elseif perSelIdx == t.k and cur < max then
				self.selectItemNum:set(cur + 1)
				self:playAction(self.strengthenPanel, node)
			end
		end
	end
end
--强化按钮
function HeldItemAdvanceView:onStrengthenClick()
	if dataEasy.getNumByKey("gold") < self.needStrengthenGold:read() then
		gGameUI:showTip(gLanguageCsv.goldNotEnough)
		return
	end
	local csvIds = {}
	for k ,v in self.itemDatas:pairs() do
		local info = v:proxy()
		if info.selectNum > 0 then
			if not csvIds[info.csvId] then
				csvIds[info.csvId] = 0
			end
			csvIds[info.csvId] = csvIds[info.csvId] + info.selectNum
		end
	end
	if next(csvIds) == nil then
		gGameUI:showTip(gLanguageCsv.pleaseSelectMaterials)
		return
	end
	self.oldLevel = self.level:read()
	self.oldFight = nil
	if self.cardDbId ~= nil then
		self.oldFight = gGameModel.cards:find(self.cardDbId):read("fighting_point")
	end

	self.showOver = {false}
	gGameApp:requestServerCustom("/game/helditem/strength")
		:params(csvIds, self.dbId)
		:onResponse(function (tb)
			setEffect(self.leftPanel:get("itemIcon"), "strength", function()
				self.showOver[1] = true
			end)
		end)
		:wait(self.showOver)
		:doit(function (tb)
			if self.oldLevel < self.level:read() then
				gGameUI:stackUI("city.card.helditem.common_success", nil, {blackLayer = true}, {
					dbId = self.dbId,
					level = self.oldLevel,
					advance = self.advance:read(),
					typ = "level",
					fight = self.oldFight,
					cardDbId = self.cardDbId
				})
			end
		end)
end
--突破按钮
function HeldItemAdvanceView:onAdvanceClick()
	if self.levelNotEnough then
		gGameUI:showTip(gLanguageCsv.currentLevelNotAvailable)
		return
	end
	local itemNum = 0
	for k,v in pairs(self.costItemIDs) do
		itemNum = itemNum + v
	end
	local selectNum = itertools.size(self.costHeldItemIDs) + itemNum
	if self.advanceCostNum == 0 or selectNum < self.advanceCostNum then
		gGameUI:showTip(gLanguageCsv.inadequateProps)
		return
	end
	self.oldAdvance = self.advance:read()
	self.oldFight = nil
	if self.cardDbId ~= nil then
		self.oldFight = gGameModel.cards:find(self.cardDbId):read("fighting_point")
	end
	local costHeldItemIDs = nil
	local costItemIDs = nil
	if itertools.size(self.costHeldItemIDs) > 0 then
		costHeldItemIDs = self.costHeldItemIDs
	end
	if itertools.size(self.costItemIDs) > 0 then
		costItemIDs = self.costItemIDs
	end
	self.showOver = {false}
	gGameApp:requestServerCustom("/game/helditem/advance")
		:params(self.dbId, costHeldItemIDs, costItemIDs)
		:onResponse(function (tb)
			setEffect(self.leftPanel:get("itemIcon"), "advance", function()
				self.showOver[1] = true
			end)
		end)
		:wait(self.showOver)
		:doit(function (tb)
			gGameUI:stackUI("city.card.helditem.common_success", nil, {blackLayer = true}, {
				dbId = self.dbId,
				level = self.level:read(),
				advance = self.oldAdvance,
				typ = "advance",
				fight = self.oldFight,
				cardDbId = self.cardDbId
			})
		end)
end

--tab点击
function HeldItemAdvanceView:onTabItemClick(list, index)
	self.showTab:set(index)
end

--关闭的时候刷新上一个界面
function HeldItemAdvanceView:onClose()
	self.refreshData(self.dbId)
	ViewBase.onClose(self)
end

--弹出信息面板
function HeldItemAdvanceView:onInfoClick(node, event)
	local data = {}
	data.cfg = csv.held_item.items[self.heldItemId]
	data.csvId = self.heldItemId
	data.advance = self.advance:read()
	local x, y = node:getPosition()
	local pos = node:getParent():convertToWorldSpace(cc.p(x, y))
	local params = {data = data, target = node, x = pos.x, y = pos.y, offx = 256, offy = 10}
	gGameUI:stackUI("city.card.helditem.advance_detail", nil, nil, params)
end

--强化材料为空
function HeldItemAdvanceView:onAfterBuild()
	self.strengthenPanel:get("empty"):visible(self.itemDatas:size() == 0)
end
--选择突破携带道具
function HeldItemAdvanceView:onLeftItemClick(list, k, v)
	if v.csvId <= game.HELD_ITEM_CSVID_LIMIT and v.csvId > game.FRAGMENT_CSVID_LIMIT then
		self.advanceCostNum = v.targetNum
		gGameUI:stackUI("city.card.helditem.advance_select", nil, nil, self.dbId, v.csvId, v.targetNum, self:createHandler("setCostItem"))
	end
end
--设置突破材料
function HeldItemAdvanceView:setCostItem(costHeldItemIDs, costItemIDs)
	self.costHeldItemIDs = costHeldItemIDs
	self.costItemIDs = costItemIDs
	local itemNum = 0
	for k,v in pairs(costItemIDs) do
		itemNum = itemNum + v
	end
	local selectNum = itertools.size(costHeldItemIDs) + itemNum
	self.costItemDatas:atproxy(1).selectNum = selectNum
end
return HeldItemAdvanceView