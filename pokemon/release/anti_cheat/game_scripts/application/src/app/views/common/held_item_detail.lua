-- @date: 2019-60-27
-- @desc: 携带道具详情

local HeldItemTools = require "app.views.city.card.helditem.tools"

local HeldItemDetailView = class("HeldItemDetailView", cc.load("mvc").ViewBase)
HeldItemDetailView.RESOURCE_FILENAME = "common_helditem_detail.json"
HeldItemDetailView.RESOURCE_BINDING = {
	["baseNode"] = "baseNode",
	["baseNode.imgBg"] = "bgImg",
	["baseNode.item"] = {
		binds = {
			event = "extend",
			class = "icon_key",
			props = {
				data = bindHelper.self("data"),
				noListener = true,
				-- onNode = function(node)
					-- local size = node:size()
					-- node:alignCenter(size)
				-- end,
			},
		},
	},
	["baseNode.textName"] = {
		varname = "textName",
		binds = {
			event = "text",
			idler = bindHelper.self("nameStr"),
		},
	},
	["baseNode.textLv"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("level"),
		},
	},
	["baseNode.down"] = {
		binds ={
			event = "visible",
			idler = bindHelper.self("hasShowCards"),
		},
	},
	["baseNode.center"] = "center",
	["baseNode.center.list"] = "centerList",
	["item"] = "item",
	["innerList"] = "innerList",
	["baseNode.top.list"] = {
		varname = "attrList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("attrs"),
				item = bindHelper.self("innerList"),
				cell = bindHelper.self("item"),
				columnSize = 2,
				onCell = function(list, node, k, v)
					local attr = game.ATTRDEF_TABLE[v.attr]
					local attrName = gLanguageCsv["attr" .. string.caption(attr)]..": "
					local path = ui.ATTR_LOGO[attr]
					node:get("imgIcon"):texture(path)
					node:get("textName"):text(attrName)
					node:get("textVal"):text("+" .. v.val)
					adapt.oneLinePos(node:get("textName"), node:get("textVal"), cc.p(10, 0), "left")
				end,
			},
		},
	},
	["item1"] = "item1",
	["baseNode.down.list"] = {
		varname = "downlist",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabCards"),
				item = bindHelper.self("item1"),
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							rarity = v.rarity,
							cardId = v.card.id,
							onNode = function(panel)
								panel:scale(0.9)
								panel:alignCenter(node:size())
							end,
						}
					})
				end,
			},
		},
	},
}

-- @param params: {key, num, dbId}
function HeldItemDetailView:onCreate(params)
	self:getResourceNode():setTouchEnabled(false)
	local key = params.key
	local num = params.num
	local dbId = params.dbId
	self.data = {key = key, dbId = dbId}
	local level = params.level or 1
	local advance = params.advance or 0

	if dbId then
		local heldItemInfo = gGameModel.held_items:find(dbId)
		level = heldItemInfo:read("level")
		advance = heldItemInfo:read("advance")
	end
	local cfg = csv.held_item.items[key]
	local nameStr = cfg.name
	if advance > 0 then
		nameStr = nameStr .. " +" .. advance
	end
	self.nameStr = idler.new(nameStr)
	text.addEffect(self.textName, {color = ui.COLORS.QUALITY[cfg.quality]})
	self.level = idler.new("Lv" .. level)
	self.attrs = idlers.newWithMap({})
	self.tabCards = idlers.newWithMap({})
	-- 属性显示
	local attrTypes = cfg.attrTypes
	local attrNumRates = cfg.attrNumRates
	local advanceAttrTab = csv.held_item.advance_attrs[advance]
	local advAttrNum = advanceAttrTab["attrNum" .. cfg.advanceAttrSeq]
	local advAttrRate = advanceAttrTab["attrRate" .. cfg.advanceAttrSeq]
	local lvAttrNum = csv.held_item.level_attrs[level]["attrNum" .. cfg.strengthAttrSeq]
	local t = {}
	for i,v in ipairs(attrTypes) do
		local data = {}
		data.attr = v
		data.val = math.floor(attrNumRates[i] * advAttrRate[i] * (lvAttrNum[i] + advAttrNum[i]))
		table.insert(t, data)
	end
	self.attrs:update(t)

	-- 默认用第一个效果id索引
	local effectInfo = csv.held_item.effect[cfg.effect1]
	local cards = {}
	for k,v in csvMapPairs(effectInfo.exclusiveCards) do
		for _, data in pairs(gCardsCsv[v]) do
			for _, card in pairs(data) do
				local unitCfg = csv.unit[card.unitID]
				table.insert(cards, {card = card, rarity = unitCfg.rarity})
			end
		end
	end
	self.tabCards:update(cards)
	local hasDownList = #cards > 0
	self.hasShowCards = idler.new(hasDownList)

	local strTab = {}
	for i=1,100 do
		local effectVal = cfg[string.format("effect%dLevelAdvSeq", i)]
		if not cfg["effect" .. i] or cfg["effect" .. i] == 0 or not effectVal or advance < effectVal[1] then
			break
		end
		local data = {}
		data.cfg = cfg
		data.advance = advance
		data.csvId = key
		local resultStr = HeldItemTools.getStrinigByData(i, data)
		table.insert(strTab, resultStr)
	end
	local targetStr = "#C0x5B545B#"..table.concat(strTab, '\n')
	local list = beauty.textScroll({
		list = self.centerList,
		strs = targetStr,
		isRich = true,
		fontSize = 40,
	})
	self.descList = list

	local nodeSize = self.baseNode:size()
	local bgSize = self.bgImg:size()
	local children = self.baseNode:getChildren()
	if not hasDownList then
		local childHeight = 0
		for i,child in ipairs(self.centerList:getChildren()) do
			childHeight = childHeight + child:size().height
		end
		local offy = 275
		local listHeight = self.centerList:size().height
		if childHeight < listHeight then
			offy = 275 + listHeight - childHeight
		end
		self.bgImg:size(bgSize.width, bgSize.height - offy)
		self.baseNode:size(nodeSize.width, nodeSize.height - offy)
		for i,child in ipairs(children) do
			child:y(child:y() - offy)
		end
		self.bgImg:y(self.bgImg:y() + offy / 2)
	end
end


function HeldItemDetailView:hitTestPanel(pos)
	if self.descList:isTouchEnabled() then
		local node = self.baseNode
		local rect = node:box()
		local nodePos = node:parent():convertToWorldSpace(cc.p(rect.x, rect.y))
		rect.x = nodePos.x
		rect.y = nodePos.y
		return cc.rectContainsPoint(rect, pos)
	end
	return false
end

return HeldItemDetailView