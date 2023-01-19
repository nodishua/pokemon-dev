-- @date:   2019-06-21
-- @desc:   携带道具背包界面

local HeldItemTools = require "app.views.city.card.helditem.tools"
local BagHandbookView = class("BagHandbookView", Dialog)

--{1,5,4,3,2}切页时的品质对应顺序
local iconText = "city/card/helditem/bag/"
local iconText1 = {"btn_red_1.png", "btn_orange_1.png", "btn_purple_1.png", "btn_blue_1.png", "btn_green_1.png"}
local iconText2 = {"btn_red.png", "btn_orange.png", "btn_purple.png", "btn_blue.png", "btn_green.png"}
local iconText3 = {"label_red.png", "label_orange.png", "label_purple.png", "label_blue.png", "label_green.png"}

local qualityNumber = {1,5,4,3,2}
for i,v in ipairs(qualityNumber) do
	qualityNumber[v] = i
end

BagHandbookView.RESOURCE_FILENAME = "held_item_bag_handbook.json"
BagHandbookView.RESOURCE_BINDING = {
	["left"] = "left",
	["right"] = {
		varname = "rightPanel",
		binds = {
			event = "visible",
			idler = bindHelper.self("isVisibleRight")
		},
	},
	["item"] = "item",
	["innweList"] = "innweList",
	["left.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("heldItems"),
				item = bindHelper.self("innweList"),
				cell = bindHelper.self("item"),
				asyncPreload = 20,
				columnSize = 4,
				topPadding = 10,
				leftPadding = 10,
				itemAction = {isAction = true, alwaysShow = true},
				onCell = function(list, node, k, v)
					node:get("imgSel"):visible(v.isSel)
					local csvItemTab = csv.held_item.items
					local csvEffTab = csv.held_item.effect
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {key = v.csvId},
							noListener = true,
							onNode = function(panel)
								local t = list:getIdx(k)
								bind.click(list, panel, {method = functools.partial(list.clickCell, t, v)})
							end,
						}
					})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["right.item"] = "rightItem",
	["right.textName"] = {
		varname = "heldItemName",
		binds = {
			event = "text",
			idler = bindHelper.self("itemName"),
		},
	},
	["attrInnerList"] = "attrInnerList",
	["item1"] = "item1",
	["right.list"] = {
		varname = "rightlist",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("attrs"),
				item = bindHelper.self("attrInnerList"),
				cell = bindHelper.self("item1"),
				columnSize = 2,
				onCell = function(list, node, k, v)
					local attr = game.ATTRDEF_TABLE[v.attr]
					local attrName = gLanguageCsv["attr" .. string.caption(attr)]
					local path = ui.ATTR_LOGO[attr]
					node:get("imgIcon"):texture(path)
					node:get("textAttrName"):text(attrName)
					node:get("textAttrNum"):text("+" .. v.val)
					adapt.oneLinePos(node:get("textAttrName"), node:get("textAttrNum"), cc.p(10, 0), "left")
				end,
			},
		},
	},
	["right.center"] = "rightCenter",
	["right.center.list"] = "rightCenterList",
	["right.center.btnInfo"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onInfoClick")},
		},
	},
	["right.rightInfo"] = "rightInfo",
	["right.rightInfo.rightIcon1"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:selectQuality(1)
			end)}
		},
	},
	["right.rightInfo.rightIcon2"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:selectQuality(5)
			end)}
		},
	},
	["right.rightInfo.rightIcon3"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:selectQuality(4)
			end)}
		},
	},
	["right.rightInfo.rightIcon4"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:selectQuality(3)
			end)}
		},
	},
	["right.rightInfo.rightIcon5"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:selectQuality(2)
			end)}
		},
	},
	["icon"] = "icon",
}

function BagHandbookView:onCreate(cardDbId)
	self:initModel()
	self.cardDbId = cardDbId or self.cards:read()[1]
	self.isVisibleRight = idler.new(false)
	self.heldItems = idlers.newWithMap({})
	self.showLeftSelected = idler.new(1)
	self.showRightSelected = idler.new(1)
	self.attrInnerList:setScrollBarEnabled(false)

	self.itemName = idler.new("")
	-- 1:装备 2:卸下
	self.curBtnState = idler.new(1)
	self.attrs = idlers.newWithMap({})

	idlereasy.when(self.isVisibleRight, function(_, isVisibleRight, xxx)
		local centerPos = display.sizeInView.width / 2
		local width = self.left:size().width
		local x = isVisibleRight and centerPos - width / 2 - 17 or centerPos
		self.left:x(x)
	end)

	local csvTab = csv.held_item.items
	local function baseSort(a, b)
		local infoA = csvTab[a.csvId]
		local infoB = csvTab[b.csvId]
		if infoA.quality ~= infoB.quality then
			return infoA.quality > infoB.quality
		end

		if a.isExc ~= b.isExc then
			return a.isExc
		end

		if a.csvId ~= b.csvId then
			return a.csvId < b.csvId
		end
		-- 有堆叠，数量少的显示前面
		return a.num < b.num
	end

	idlereasy.any({self.showLeftSelected, self.showRightSelected, self.refreshFlag, self.quality}, function(_, left, right, refreshFlag, quality)
		local t = {}
		local count = 0
		for i,v in ipairs(self.tableDatas) do
			count = count + 1
			if quality ~= 1 then
				if csvTab[v.csvId].quality == quality then
					table.insert(t, clone(v))
				end
			else
				table.insert(t, clone(v))
			end
		end

		table.sort(t, function(a, b)
			if right == 1 then
				return baseSort(a, b)
			end
		end)
		t[1].isSel = true
		self.heldItems:update(t)
		self.selIdx:modify(function(oldval)
			return true, 1
		end, true)
		self.isVisibleRight:set(count > 0)
	end)

	self.selIdx:addListener(function(idx, oldval)
		if oldval ~= idx then
			if oldval ~= -1 then
				if self.heldItems:atproxy(oldval) and self.heldItems:atproxy(oldval).isSel ~= false then
					self.heldItems:atproxy(oldval).isSel = false
				end
			end
			if self.heldItems:atproxy(idx).isSel ~= true then
				self.heldItems:atproxy(idx).isSel = true
			end
		end
		local csvTab = csv.held_item.items
		local effectTab = csv.held_item.effect
		local info = self.heldItems:atproxy(idx)
		local state = 1
		local str = gLanguageCsv.spaceEquip
		local nameStr = info.cfg.name
		if info.advance > 0 then
			nameStr = string.format("%s +%d", info.cfg.name, info.advance)
		end
		self.itemName:set(nameStr)
		text.addEffect(self.heldItemName, {color= info.cfg.quality == 1 and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.QUALITY[info.cfg.quality]})
		-- 左上角item
		bind.extend(self, self.rightItem, {
			class = "icon_key",
			props = {
				data = {
					key = info.csvId,
				},
				noListener = true,
			}
		})
		-- 属性显示
		local attrTypes = info.cfg.attrTypes
		local attrNumRates = info.cfg.attrNumRates
		local advanceAttrTab = csv.held_item.advance_attrs[info.advance]
		local advAttrNum = advanceAttrTab["attrNum" .. info.cfg.advanceAttrSeq]
		local advAttrRate = advanceAttrTab["attrRate" .. info.cfg.advanceAttrSeq]
		local lvAttrNum = csv.held_item.level_attrs[info.lv]["attrNum" .. info.cfg.strengthAttrSeq]
		local t = {}
		for i,v in ipairs(attrTypes) do
			local data = {}
			data.attr = v
			data.val = math.floor(attrNumRates[i] * advAttrRate[i] * (lvAttrNum[i] + advAttrNum[i]))
			table.insert(t, data)
		end
		self.attrs:update(t)
		-- 属性加成显示
		local strTab = {}
		for i=1,100 do
			local effectVal = info.cfg[string.format("effect%dLevelAdvSeq", i)]
			-- local curAdv = gGameModel.held_items:find(info.dbId[1]):read("advance")
			local curAdv = 0
			-- 没有配置  或者没有达到开放的advance等级 就不显示
			if not info.cfg["effect" .. i] or info.cfg["effect" .. i] == 0 or not effectVal or curAdv < effectVal[1] then
				break
			end
			local resultStr = HeldItemTools.getStrinigByData(i, info)
			table.insert(strTab, resultStr)
		end
		local targetStr = "#C0x5B545B#"..table.concat(strTab, '\n')
		local list = beauty.textScroll({
			list = self.rightCenterList,
			strs = targetStr,
			isRich = true,
			fontSize = 40,
		})

	end)
	self.quality:addListener(function(idx, oldval)
		if idx ~= oldval then
			idx = qualityNumber[idx]
			oldval = qualityNumber[oldval]
			self.icon:texture(iconText..iconText3[idx])
			self.rightInfo:get("rightIcon"..idx):texture(iconText..iconText1[idx])
			self.rightInfo:get("rightIcon"..idx):get("txt"):visible(true)
			self.rightInfo:get("rightIcon"..idx):get("txt1"):visible(false)
			self.rightInfo:get("rightIcon"..oldval):texture(iconText..iconText2[oldval])
			self.rightInfo:get("rightIcon"..oldval):get("txt"):visible(false)
			self.rightInfo:get("rightIcon"..oldval):get("txt1"):visible(true)
		else
			for i=2, 5 do
				self.rightInfo:get("rightIcon"..i):get("txt"):visible(false)
			end
			self.rightInfo:get("rightIcon1"):get("txt1"):visible(false)
		end
	end)
	Dialog.onCreate(self)
end

function BagHandbookView:refreshData()
	self.tableDatas = {}
	-- {[dbid or csvId] = idx}
	local t = {}
	local datas = {}
	local csvTab = csv.held_item.items
	for k,v in orderCsvPairs(csvTab) do
		if v.itemsShow then
			local data = {}
			data.cfg = v
			data.csvId = k
			data.num = 1
			data.isSel = false
			data.lv = 1
			data.cardDbID = k
			data.advance = 0
			local isDress, isExc = HeldItemTools.isExclusive(data)
			data.isExc = isExc
			table.insert(datas, data)
		end
	end
	self.tableDatas = datas
	self.refreshFlag:set(true, true)
end

function BagHandbookView:initModel()
	self.quality = idler.new(1)
	self.qualityTextNum = idler.new(1)
	self.myHeldItem = gGameModel.role:getIdler("held_items")
	self.cards = gGameModel.role:getIdler("cards")
	self.refreshFlag = idler.new(false)
	self.selIdx = idler.new(1)
	self:refreshData()
	self.item:visible(false)
	self.item1:visible(false)
end

function BagHandbookView:onInfoClick(node, event)
	local data = self.heldItems:atproxy(self.selIdx:read())
	local x, y = node:getPosition()
	local pos = node:getParent():convertToWorldSpace(cc.p(x, y))
	local params = {data = data, target = node, x = pos.x, y = pos.y, offx = 256, offy = 120}
	gGameUI:stackUI("city.card.helditem.advance_detail", nil, nil, params)
end

function BagHandbookView:onItemClick(list, t, v)
	self.selIdx:set(t.k)
	self.isVisibleRight:set(true)
end

function BagHandbookView:selectQuality(quality)
	self.quality:set(quality)
end

function BagHandbookView:onClose()
	local heldItemDbId = gGameModel.cards:find(self.cardDbId):read("held_item")
	Dialog.onClose(self)
end

return BagHandbookView