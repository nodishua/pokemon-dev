local CardAdvanceView = class("CardAdvanceView", cc.load("mvc").ViewBase)

CardAdvanceView.RESOURCE_FILENAME = "card_advance.json"
CardAdvanceView.RESOURCE_BINDING = {
	["panel"] = "panel",
	["panel.btnInfo"] = "btnInfo",
	["panel.head"] = {
		binds = {
			event = "extend",
			class = "card_icon",
			props = {
				unitId = bindHelper.self("unitId"),
				advance = bindHelper.self("advance"),
				-- star = bindHelper.self("star"),
				-- rarity = bindHelper.self("rarity"),
				onNode = function(panel)
				end,
			}
		},
	},
	["panel.textBefore"] = "oldAdvanceNote",
	["panel.textEnd"] = "newAdvanceNote",
	["panel.textLv"] = {
		varname = "needLevelTxt",
		binds = {
			event = "text",
			idler = bindHelper.self("needLevel")
		}
	},
	["panel.btnUp"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAdvanceClick")}
		}
	},
	["panel.btnOneKeyUp"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onOneKeyAdvanceClick")}
		}
	},
	["panel.costInfo"] = "costInfo",
	["panel.costInfo.textCostNum"] = "needGoldTxt",
	["panel.costInfo.imgIcon"] = "costIcon",
	["item"] = "item",
	["panel"] = "panel",
}

-- function CardAdvanceView:changeCard(cardID)
-- 	self.selectDbId:set(cardID)
-- end
local pos = {
	{cc.p(476.5, 450)},
	{cc.p(315, 430), cc.p(625, 430)},
	{cc.p(160, 660), cc.p(476.5, 450), cc.p(785, 660)},
	{cc.p(160, 660), cc.p(315, 430), cc.p(625, 430), cc.p(785, 660)},
}
function CardAdvanceView:onCreate(dbHandler, playAction)
	self.selectDbId = dbHandler()
	self.playAction = playAction
	self:initModel()
	self.needLevel = idler.new("")
	self.needGold = idler.new("")
	self.lackMaterial = idler.new(false)
	self.itemId = {}
	self.btnInfo:hide()
	self.unitId = idler.new(0)

	widget.addAnimation(self.panel, "effect/tupohuan.skel", "effect_loop", 1)
		:xy(477, 770)

	idlereasy.any({self.cardId, self.skinId, self.advance, self.cardLv, self.items}, function(_, cardId,skinId, advance, cardLv, items)
		local csvCards = csv.cards[cardId]
		local csvAdvance = gCardAdvanceCsv[csvCards.advanceTypeID][advance]

		uiEasy.setIconName("card", cardId, {node = self.oldAdvanceNote, name = ui.QUALITY_COLOR_TEXT, advance = advance, space = true})
		uiEasy.setIconName("card", cardId, {node = self.newAdvanceNote, name = ui.QUALITY_COLOR_TEXT, advance = advance+1, space = true})

		self.needGold:set(csvAdvance.gold)
		self.needGoldTxt:text(csvAdvance.gold)
		self.costInfo:visible(csvAdvance.gold and csvAdvance.gold > 0)
		adapt.oneLinePos(self.needGoldTxt, self.costIcon, nil, "left")
		local goldColor = (dataEasy.getNumByKey("gold") >= csvAdvance.gold) and cc.c4b(91, 84, 91, 255) or cc.c4b(249,87,114,255)
		text.addEffect(self.needGoldTxt, {color = goldColor})

		local needLevel = csvCards.advanceLevelReq[advance]
		self.needLevel:set(needLevel)
		local color = (cardLv >= needLevel) and ui.COLORS.QUALITY[2] or ui.COLORS.QUALITY[7]
		text.addEffect(self.needLevelTxt, {color = color})

		self.unitId:set(dataEasy.getUnitId(cardId, skinId))
		self:setUI(cardId,advance,items)
	end)
	idlereasy.when(self.gold, function(_, gold)
		local csvCards = csv.cards[self.cardId:read()]
		local csvAdvance = gCardAdvanceCsv[csvCards.advanceTypeID][self.advance:read()]
		local goldColor = (gold >= csvAdvance.gold) and cc.c4b(91, 84, 91, 255) or cc.c4b(249,87,114,255)
		text.addEffect(self.needGoldTxt, {color = goldColor})
	end)

end

function CardAdvanceView:setUI(cardId,advance,items)
	self.lackMaterial:set(false)
	local csvCards = csv.cards[cardId]
	local csvAdvance = gCardAdvanceCsv[csvCards.advanceTypeID][advance]
	local tmpMap = {}
	for k,v in csvPairs(csvAdvance.itemMap) do
		table.insert(tmpMap,{id = k,num = v})
	end
	table.sort(tmpMap,function (a,b)
		return a.id < b.id
	end)

	local i = 1
	local len = itertools.size(tmpMap)
	for k=1,999 do
		local child = self.panel:getChildByName("item"..k)
		if not child then
			break
		end
		child:removeFromParent()
	end
	for k,v in pairs(tmpMap) do
		local item = self.item:clone()
		local myItemNum = items[v.id] or 0
		local showAddBtn = (myItemNum < v.num)
		item:get("btnAdd"):visible(showAddBtn)
		local binds = {
			class = "icon_key",
			props = {
				data = {
					key = v.id,
					num = myItemNum,
					targetNum = v.num,
				},
				grayState = showAddBtn and 1 or 0,
				onNode = function(node)
					node:setTouchEnabled(false)
				end,
			},
		}
		bind.extend(self, item, binds)
		local position = pos[len][i]
		item:xy(position.x, position.y)
		item:show()
		self.panel:add(item, 10, "item"..k)
		bind.touch(self, item, {methods = {ended = function(view, node, event)
			gGameUI:stackUI("common.gain_way", nil, nil, v.id, nil, v.num)
		end}})
		if myItemNum < v.num then
			self.lackMaterial:set(true)
		end
		self.itemId[i] = v.id
		i = i + 1
	end
end


function CardAdvanceView:initModel()
	self.gold = gGameModel.role:getIdler("gold")
	self.items = gGameModel.role:getIdler("items")
	idlereasy.when(self.selectDbId,function (_, selectDbId)
		if assertInWindows(selectDbId, "val:%s", tostring(selectDbId)) then
			return
		end
		local card = gGameModel.cards:find(selectDbId)
		self.advance = idlereasy.assign(card:getIdler("advance"), self.advance)
		self.cardId = idlereasy.assign(card:getIdler("card_id"), self.cardId)
		self.skinId =  idlereasy.assign(card:getIdler("skin_id"), self.skinId)
		self.star = idlereasy.assign(card:getIdler("star"), self.star)
		local cardCfg = csv.cards[self.cardId:read()]
		self.rarity = csv.unit[cardCfg.unitID].rarity
		self.cardLv = idlereasy.assign(card:getIdler("level"), self.cardLv)
		self.fight = idlereasy.assign(card:getIdler("fighting_point"), self.fight)
		self.attrs = idlereasy.assign(card:getIdler("attrs"), self.attrs)
	end)
end

function CardAdvanceView:onAdvanceClick()
	if not self:advancedTips() then return end
	local fight = self.fight:read()
	local advance = self.advance:read()
	local attrs = clone(self.attrs:read())
	local n = 0
	for i=1,math.huge do
		local item = self.panel:getChildByName("item"..i)
		if not item then
			n = i - 1
			break
		end
	end
	local showCount = 2*n
	local showOver = {false}
	gGameApp:requestServerCustom("/game/card/advance")
		:params(self.selectDbId)
		:onResponse(function (tb)
			self.playAction()
			for i=1, n do
				local item = self.panel:getChildByName("item"..i)
				local icon = item:get("_icon_", "icon")
				icon:hide()
				local x, y = item:xy()
				local icon =icon:clone()
					:xy(x, y)
					:show()
					:addTo(self.panel, 100)
				transition.executeSequence(icon)
					:moveTo(0.3, -500, 450)
					:func(function()
						icon:show()
						showCount = showCount - 1
						showOver[1] = showCount <= 0
					end)
					:done()
				transition.executeSequence(icon)
					:scaleTo(0.3, 0)
					:func(function()
						icon:removeFromParent()
						showCount = showCount - 1
						showOver[1] = showCount <= 0
					end)
					:done()
			end
		end)
		-- :delay(0.3)
		:wait(showOver)
		:doit(function (tb)
			gGameUI:stackUI("city.card.common_success", nil, {blackLayer = true},
				self.selectDbId:read(),
				fight,
				{attrs = attrs, advanceOld = advance}
			)
		end)
end

function CardAdvanceView:advancedTips()
	local advanceMax = csv.cards[self.cardId:read()].advanceMax
	if self.advance:read() >= advanceMax then
		gGameUI:showTip(gLanguageCsv.advanceMaxErr)
		return
	end
	if self.cardLv:read() < self.needLevel:read() then
		gGameUI:showTip(gLanguageCsv.advanceLevelNotEnough)
		return
	end
	if dataEasy.getNumByKey("gold") < self.needGold:read() then
		gGameUI:showTip(gLanguageCsv.advanceGoldNotEnough)
		return
	end
	if self.lackMaterial:read() then
		gGameUI:showTip(gLanguageCsv.advanceItemsNotEnough)
		return
	end
	return true
end

function CardAdvanceView:onOneKeyAdvanceClick()
	if not self:advancedTips() then return end
	self.oldFight = self.fight:read()
	self.oldAttrs = clone(self.attrs:read())
	self.oldAdvance = self.advance:read()
	gGameUI:stackUI("city.card.advance_onekey", nil, nil, self.selectDbId:read(), self:createHandler("onSuccess"))
end

function CardAdvanceView:onSuccess()
	gGameUI:stackUI("city.card.common_success", nil, {blackLayer = true},
		self.selectDbId:read(),
		self.oldFight,
		{advanceOld = self.oldAdvance, attrs = self.oldAttrs}
	)
end

return CardAdvanceView
