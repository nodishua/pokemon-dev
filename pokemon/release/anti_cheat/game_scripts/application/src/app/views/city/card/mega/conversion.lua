-- @date 2020-7-21
-- @desc: 超进化转换

local rarityData = ui.RARITY_TEXT
local MegaConversionView = class("MegaConversionView", Dialog)

-- 超级石判断使用它的精灵是否有过超进化
local function checkHadMega(id)
	for cardMegaId, data in orderCsvPairs(csv.card_mega) do
		for k, v in csvMapPairs(data.costItems) do
			if k == id then
				for _, dbid in ipairs(gGameModel.role:read("cards")) do
					local card = gGameModel.cards:find(dbid)
					if card:read("card_id") == gCardsMega[cardMegaId].key then
						return cardMegaId
					end
				end
				return
			end
		end
	end
end

MegaConversionView.RESOURCE_FILENAME = "card_mega_debris.json"
MegaConversionView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["spriteBtn"] = {
		varname = "spriteBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("spriteBtnFunc")}
		},
	},
	["debrisBtn"] = {
		varname = "debrisBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("debrisBtnFunc")}
		},
	},
	["rule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("ruleFunc")}
		},
	},
	["clickBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("conversionFunc")}
		},
	},
	["timesPanel"] = "timesPanel",
	["timesPanel.add"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("addNumFunc")}
		},
	},
	["sliderPanel"] = 'sliderPanel',
	["sliderPanel.slider"] = "slider",
	["sliderPanel.subBtn"] = {
		varname = "sliderSubBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, -1)
			end),
		},
	},
	["sliderPanel.addBtn"] = {
		varname = "sliderAddBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, 1)
			end),
		},
	},
	["debrisItem"] = "debrisItem",
	["costPanel"] = "costPanel",
	["imgIcon"] = "imgIcon",
	["title1"] = "title1",
	["title2"] = "title2",
	["item"] = "item",
	["list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("costDatas"),
				item = bindHelper.self("item"),
				imgIcon = bindHelper.self("imgIcon"),
				debrisItem = bindHelper.self("debrisItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("name", "name2", "icon", "item", "add")
					if itertools.size(v) == 0 then
						childs.add:show()
						itertools.invoke({childs.name, childs.icon, childs.item}, "hide")
						childs.name2:hide()
						node:width(80)
						childs.add:x(40)
					else
						childs.add:hide()
						itertools.invoke({childs.name, childs.icon, childs.item}, "show")
						childs.item:get("add"):hide()
						node:width(200)
						if v.type == "card" then
							if not v.selectId then
								childs.item:hide()
								local cfg = v.cfg
								local str = gLanguageCsv.selectCardFragments .. string.format(gLanguageCsv.selectRarityCardFragments, rarityData[cfg.needCards1[1]])
								for i = 1, math.huge do
									local needCards = cfg["needCards" .. i]
									if itertools.isempty(needCards) then
										break
									end
									if needCards[2] ~= -1 then
										local txt = game.NATURE_TABLE[needCards[2]]
										str = str .. ui.ATTRCOLOR[txt] .. string.format(gLanguageCsv.selectTypeCardFragments, gLanguageCsv[txt]) .. "#C0x5B545B#"
									end
								end
								childs.name:hide()
								childs.name2:hide()
								str = "#C0x5B545B#" .. str .. gLanguageCsv.card
								node:removeChildByName("descList")
								local list = beauty.textScroll({
									size = {width = 250, height = 180},
									strs = str,
									isRich = true,
								})
								list:xy(childs.name2:x() - childs.name2:width()/2, childs.name2:y() - childs.name2:height()/2)
									:addTo(node, 5, "descList")
							else
								childs.icon:hide()
								local card = gGameModel.cards:find(v.selectId)
								local cardData = card:read("card_id", "name", "level", "star", "advance")
								local cardCfg = csv.cards[cardData.card_id]
								local unitCfg = csv.unit[cardCfg.unitID]
								bind.extend(list, childs.item, {
									class = "card_icon",
									props = {
										cardId = cardData.card_id,
										advance = cardData.advance,
										star = cardData.star,
										rarity = unitCfg.rarity,
										levelProps = {
											data = cardData.level,
										},
										onNode = function(panel)
											panel:setTouchEnabled(false)
										end,
									},
								})
								uiEasy.setIconName("card", cardData.card_id, {node = childs.name})
								childs.name2:hide()
							end
						elseif v.type == "frag" then
							local num, targetNum
							if not v.selectId then
								childs.item:hide()
								local cfg = v.cfg
								local str = gLanguageCsv.selectCardFragments .. string.format(gLanguageCsv.selectRarityCardFragments, rarityData[cfg.needFrags1[1]-2])
								for i = 1, math.huge do
									local needFrags = cfg["needFrags" .. i]
									if itertools.isempty(needFrags) then
										break
									end
									if needFrags[2] ~= -1 then
										local txt = game.NATURE_TABLE[needFrags[2]]
										str = str .. ui.ATTRCOLOR[txt] .. string.format(gLanguageCsv.selectTypeCardFragments, gLanguageCsv[txt]) .. "#C0x5B545B#"
									end
								end
								childs.name:hide()
								childs.name2:hide()
								str = "#C0x5B545B#" .. str .. gLanguageCsv.fragment
								node:removeChildByName("descList")
								local list = beauty.textScroll({
									size = {width = 250, height = 180},
									strs = str,
									isRich = true,
								})
								list:xy(childs.name2:x() - childs.name2:width()/2, childs.name2:y() - childs.name2:height()/2)
									:addTo(node, 5, "descList")
								childs.item:get("add"):show()
								num = v.num
							else
								childs.icon:hide()
								childs.name2:hide()
								uiEasy.setIconName(v.selectId, v.num, {node = childs.name, width = node:width()})
								num = dataEasy.getNumByKey(v.selectId)
								targetNum = v.num * v.targetNum
								childs.item:get("add"):visible(num < targetNum)
								bind.extend(list, childs.item, {
									class = "icon_key",
									props = {
										grayState = num < targetNum and 1 or 0,
										data = {
											key = v.selectId,
											num = num,
											targetNum = targetNum,
										},
										onNode = function(panel)
											panel:setTouchEnabled(false)
										end,
									},
								})
							end
						else
							childs.icon:hide()
							local num = dataEasy.getNumByKey(v.key)
							if num < v.num then
								childs.item:get("add"):show()
							end
							bind.extend(list, childs.item, {
								class = "icon_key",
								props = {
									grayState = num < v.num and 1 or 0,
									data = {
										key = v.key,
										num = num,
										targetNum = v.num * (v.targetNum or 1),
									},
									onNode = function(panel)
										panel:setTouchEnabled(false)
									end,
								},
							})
							childs.name2:hide()
							uiEasy.setIconName(v.key, v.num, {node = childs.name})
						end
						bind.touch(list, childs.icon, {methods = {ended = function()
							list.chooseCard(k, v)
						end}})
						bind.touch(list, childs.item, {methods = {ended = function()
							list.chooseCard(k, v)
						end}})
					end
				end,
				onAfterBuild = function(list)
					local listWidth = list:getInnerItemSize().width
					local imgIconWidth = 80
					local debrisItemWidth = 200
					local margin = 100
					local length = listWidth + imgIconWidth + debrisItemWidth + margin * 2
					list:x(display.sizeInView.width/2 - length/2)
					list.imgIcon:x(list:x() + listWidth + margin + imgIconWidth/2)
					list.debrisItem:x(list:x() + listWidth + imgIconWidth + margin * 2 + debrisItemWidth/2)
				end,
			},
			handlers = {
				chooseCard = bindHelper.self("chooseCard"),
			},
		},
	},
}

-- 2、超级石转化	1、钥石转化(common)
function MegaConversionView:onCreate(data)
	self.debrisItem:y(self.debrisItem:y() + 18)
	self.cardConvertFlag = true
	self.data = data
	self:initModel()
	self:enableSchedule()
	self.cardConvertCfg = csv.card_mega_convert[data.id]
	local hintText = gLanguageCsv.yaoStone
	local vipNum = gVipCsv[self.vipLevel]
	if self.cardConvertCfg.type == 2 then
		self.ruleContent = {97001, 97010}
		hintText = gLanguageCsv.superStone
		self.ruleTitle = gLanguageCsv.superStoneRule
		self.hadMega = checkHadMega(data.id)
	else
		self.ruleContent = {96001, 96010}
		self.ruleTitle = gLanguageCsv.yaoStoneRule

	end
	self.title1:text(hintText)
	self.title2:x(self.title1:x() + self.title1:width())

	--转换的总次数
	local times = self.cardConvertCfg.type ~= 1 and gCommonConfigCsv.megaConvertTimes or gCommonConfigCsv.megaCommonConvertTimes
	self.timesPanel:get("tip"):text(string.format(gLanguageCsv.megaConvertTimesTip, times))
	idlereasy.any({self.megaConvertTimes, self.megaConvertBuyTimes}, function(_, megaConvertTimes, megaConvertBuyTimes)
		self.conversionNum = megaConvertTimes and megaConvertTimes[data.id] or 0
		self.timesPanel:get("num1"):text(self.conversionNum)
		self.conversionNumMax = self.cardConvertCfg.type ~= 1 and gVipCsv[self.vipLevel].megaItemMaxTimes or gVipCsv[self.vipLevel].megaCommonItemMaxTimes
		self.timesPanel:get("num2"):text("/" .. self.conversionNumMax)
		adapt.oneLinePos(self.timesPanel:get("num2"), {self.timesPanel:get("num1"), self.timesPanel:get("txt1")}, cc.p(0, 0), "right")
	end)

	self.selectedData = {key = "card", csvId = data.id}	--保存当前卡牌的信息 {key, csvId, selectId}
	self.costDatas = idlers.newWithMap({})

	self.maxNum = 0
	self.debrisBtn:get("txt2"):hide()
	self.spriteBtn:get("txt2"):hide()
	local fragmentX, spriteX = self.debrisBtn:x(), self.spriteBtn:x()
	self.debrisBtn:x(spriteX)
	self.spriteBtn:x(fragmentX)

	--进度条
	self.sliderNum = idler.new(0)
	idlereasy.when(self.sliderNum, function(_, num)
		self.sliderPanel:get("txt1"):text(num)
		self:stateUpdate()

		-- 非拖动时才设置进度
		if not self.slider:isHighlighted() then
			local percent = self.maxNum == 0 and 0 or num / self.maxNum
			self.slider:setPercent(percent * 100)
		end
	end)

	self.slider:addEventListener(function(sender,eventType)
		self:unScheduleAll()
		local percent = sender:getPercent()
		local num = cc.clampf(math.ceil(self.maxNum * percent * 0.01), 0, self.maxNum)
		self.sliderNum:set(num)
	end)

	idlereasy.when(self.gold, functools.partial(self.costGoldUpdate, self))
	idlereasy.any({self.cards, self.frags, self.items}, functools.partial(self.stateChange, self))

	self:debrisBtnFunc()

	Dialog.onCreate(self, {blackType = 2})
end

function MegaConversionView:initModel()
	self.vipLevel = gGameModel.role:read("vip_level")
	-- 可转化的总次数
	self.megaConvertTimes = gGameModel.role:getIdler("mega_convert_times")
	-- 购买的机会
	self.megaConvertBuyTimes = gGameModel.daily_record:getIdler("mega_convert_buy_times")
	self.cards = gGameModel.role:getIdler("cards")
	self.items = gGameModel.role:getIdler("items")
	self.frags = gGameModel.role:getIdler("frags")
	self.gold = gGameModel.role:getIdler("gold")
end

function MegaConversionView:getCostGold()
	local baseGold
	if self.cardConvertFlag then
		baseGold = self.cardConvertCfg.costItemCard.gold or 0
	else
		baseGold = (self.cardConvertCfg.costItemFrag.gold or 0) * math.max(self.sliderNum:read(), 1)
	end
	return baseGold
end

function MegaConversionView:costGoldUpdate()
	local gold = self:getCostGold()
	if gold == 0 then
		self.costPanel:hide()
	else
		self.costPanel:show()
		self.costPanel:get("num"):text(gold)
		local roleGold = gGameModel.role:read("gold")
		text.addEffect(self.costPanel:get("num"), {color = roleGold >= gold and ui.COLORS.QUALITY_OUTLINE[1] or ui.COLORS.NORMAL.ALERT_ORANGE})
		adapt.oneLineCenterPos(cc.p(260, 40), {self.costPanel:get("txt1"), self.costPanel:get("num"), self.costPanel:get("icon")}, cc.p(8, 0))
	end
end

function MegaConversionView:stateChange()
	self:stateUpdate()
	self.sliderNum:modify(function(num)
		return true, math.min(num, self.maxNum)
	end, true)
end

function MegaConversionView:stateUpdate()
	self.debrisBtn:texture(self.cardConvertFlag and "common/btn/btn_nomal_3.png" or "common/btn/btn_nomal_2.png")
	self.spriteBtn:texture(self.cardConvertFlag and "common/btn/btn_nomal_2.png" or "common/btn/btn_nomal_3.png")
	self.debrisBtn:get("txt1"):visible(self.cardConvertFlag)
	self.debrisBtn:get("txt2"):visible(not self.cardConvertFlag)
	self.spriteBtn:get("txt1"):visible(self.cardConvertFlag)
	self.spriteBtn:get("txt2"):visible(not self.cardConvertFlag)

	self:costGoldUpdate()

	local sliderNum = self.sliderNum:read()
	local targetNum = 1
	local maxNum = self.conversionNum
	local data = {}
	if self.cardConvertFlag then
		self.sliderPanel:hide()
		targetNum = self.cardConvertCfg.cardConvertNum
		maxNum = math.min(math.floor(maxNum/targetNum), 1)
		for key, num in csvMapPairs(self.cardConvertCfg.costItemCard) do
			if key ~= "gold" then
				local ownNum = dataEasy.getNumByKey(key)
				maxNum = math.min(maxNum, math.floor(ownNum/num))
				table.insert(data, {key = key, num = num})
			end
		end
		if self.cardConvertCfg.needCards1[1] then
			if not self.selectedData.selectId then
				maxNum = 0
			else
				maxNum = math.min(maxNum, 1)
			end
			table.insert(data, 1, {type = "card", cfg = self.cardConvertCfg, selectId = self.selectedData.selectId})
		end
	else
		self.sliderPanel:show()
		targetNum = math.max(sliderNum, 1)
		for key, num in csvMapPairs(self.cardConvertCfg.costItemFrag) do
			if key ~= "gold" then
				local ownNum = dataEasy.getNumByKey(key)
				maxNum = math.min(maxNum, math.floor(ownNum/num))
				table.insert(data, {key = key, num = num, targetNum = targetNum})
			end
		end
		if self.cardConvertCfg.needFrags1[1] then
			local num = self.cardConvertCfg.needFrags1[3]
			if not self.selectedData.selectId then
				maxNum = 0
			else
				local ownNum = dataEasy.getNumByKey(self.selectedData.selectId)
				maxNum = math.min(maxNum, math.floor(ownNum/num))
			end
			self.fragExchangeRate = num
			table.insert(data, 1, {type = "frag", cfg = self.cardConvertCfg, num = num, selectId = self.selectedData.selectId, targetNum = targetNum})
		end
	end
	self.maxNum = maxNum
	self.sliderPanel:get("txt2"):text("/" .. maxNum)
	uiEasy.setBtnShader(self.sliderSubBtn, false, sliderNum >= 1 and 1 or 2)
	uiEasy.setBtnShader(self.sliderAddBtn, false, sliderNum < self.maxNum and 1 or 2)
	if sliderNum < 1 or sliderNum >= self.maxNum then
		self:unScheduleAll()
	end

	-- 中间补充空的+控件
	for i = #data, 2, -1 do
		table.insert(data, i, {})
	end
	self.costDatas:update(data)

	local ownNum = dataEasy.getNumByKey(self.data.id)
	uiEasy.setIconName(self.data.id, nil, {node = self.debrisItem:get("name")})
	self.debrisItem:get("title.num"):text(ownNum)
	self.debrisItem:get("title.txt2"):text("/" .. self.data.num)
	text.addEffect(self.debrisItem:get("title.num"), {color = ownNum >= self.data.num and ui.COLORS.QUALITY_OUTLINE[1] or ui.COLORS.NORMAL.ALERT_ORANGE})
	adapt.oneLineCenterPos(cc.p(200, 30), {self.debrisItem:get("title.txt1"), self.debrisItem:get("title.num"), self.debrisItem:get("title.txt2")}, cc.p(5, 0))
	bind.extend(self, self.debrisItem:get("item"), {
		class = "icon_key",
		props = {
			data = {
				key = self.data.id,
				num = targetNum,
			},
		},
	})
end

function MegaConversionView:chooseCard(list, k, v)
	if v.type == "card" then
		gGameUI:stackUI("city.card.mega.choose_card", nil, {dialog = true}, self.selectedData, self:createHandler('stateChange'))

	elseif v.type == "frag" then
		gGameUI:stackUI("city.card.mega.fragment_select", nil, {dialog = true}, self.selectedData, self:createHandler('stateChange'))
	else
		gGameUI:stackUI("common.gain_way", nil, {dialog = true}, v.key, nil, v.num)
	end
end

function MegaConversionView:onIncreaseNum(step)
	local data = step > 0 and 1 or 0
	local num = cc.clampf(self.sliderNum:read() + step, data, math.max(self.maxNum, 1))
	self.sliderNum:set(num, true)
end

function MegaConversionView:onChangeNum(node, event, step)
	if self.cardConvertFlag then
		return
	end
	if event.name == "click" then
		self:unScheduleAll()
		self:onIncreaseNum(step)

	elseif event.name == "began" then
		self:schedule(function()
			self:onIncreaseNum(step)
		end, 0.05, 0, 1)

	elseif event.name == "ended" or event.name == "cancelled" then
		self:unScheduleAll()
	end
end

--精灵转化
function MegaConversionView:spriteBtnFunc()
	if not self.cardConvertFlag then
		self.selectedData.selectId = nil
		self.cardConvertFlag = true
		self.sliderNum:set(0, true)
	end
end

--碎片转化
function MegaConversionView:debrisBtnFunc()
	if self.cardConvertFlag then
		self.selectedData.selectId = nil
		self.cardConvertFlag = false
		self.sliderNum:set(0, true)
	end
end

--购买次数:1是钥石 2是超级石
function MegaConversionView:addNumFunc()
	if self.conversionNum >= self.conversionNumMax then
		gGameUI:showTip(gLanguageCsv.megaConvertTimesLimit)
		return
	end
	gGameUI:stackUI("common.buy_number", nil, nil, {
		id = self.data.id,
		itemType = self.cardConvertCfg.type,
	}, self:createHandler('stateChange'))
end

--转化
function MegaConversionView:conversionFunc()
	local selectId = self.selectedData.selectId
	if not selectId then
		gGameUI:showTip(gLanguageCsv.materialsNotEnoughMega)
		return
	end
	local num = self.sliderNum:read()
	if self.cardConvertFlag then
		num = self.cardConvertCfg.cardConvertNum
	end
	if self.conversionNum - num < 0 then
		gGameUI:showTip(gLanguageCsv.conversionInsufficient)
		return
	end
	if self.cardConvertFlag and self.maxNum <= 0 then
		gGameUI:showTip(gLanguageCsv.materialsNotEnoughMega)
		return
	end
	if not self.cardConvertFlag and num <= 0 then
		gGameUI:showTip(gLanguageCsv.selectConversionNumber)
		return
	end

	local gold = self:getCostGold()
	local roleGold = gGameModel.role:read("gold")
	if roleGold < gold then
		gGameUI:showTip(gLanguageCsv.conversionNotGold)
		return
	end

	local str, url
	local params = {}
	if self.cardConvertFlag then
		local cardid = gGameModel.cards:find(selectId):read("card_id")
		local cardName = csv.cards[cardid].name
		local itemName = csv.items[self.data.id].name
		str = string.format(gLanguageCsv.consumeConversionSprite, cardName, num, itemName)
		params = {self.data.id, selectId}
		url = "/game/develop/mega/convert/card"
	else
		local cardName = ""
		if dataEasy.isFragment(selectId) then
			cardName = csv.fragments[selectId].name
		elseif dataEasy.isZawakeFragment(selectId) then
			cardName = csv.zawake.zawake_fragments[selectId].name
		end
		local itemName = csv.items[self.data.id].name
		local costNum = (self.fragExchangeRate or 0) * num
		str = string.format(gLanguageCsv.consumeConversionFigment, costNum, cardName, num, itemName)
		params = {self.data.id, num, selectId}
		url = "/game/develop/mega/convert/frag"
	end
	local function normalTip()
		gGameUI:showDialog({title = gLanguageCsv.spaceTips, content = str, isRich = true, btnType = 2, cb = function ()
			self.selectedData.selectId = nil
			gGameApp:requestServer(url,function (tb)
				gGameUI:showGainDisplay({[self.data.id] = num})
				self:stateChange()
			end, unpack(params))
		end})
	end

	local hadMegaTip = userDefault.getForeverLocalKey("hadMegaTip", {})
	local ownNum = dataEasy.getNumByKey(self.data.id)
	if self.hadMega and not hadMegaTip[self.hadMega] then
		-- 已超进化过，首次点击转换提示
		userDefault.setForeverLocalKey("hadMegaTip", {[self.hadMega] = true})
		gGameUI:showDialog({title = gLanguageCsv.spaceTips, content = gLanguageCsv.megaConvertHadMega, isRich = true, btnType = 2, cb = normalTip})

	elseif self.cardConvertCfg.type == 2 and ownNum <= self.data.num and (ownNum+num) > self.data.num then
		-- 如果本次转化后，超出*超进化所需的超级石数量*上限
		gGameUI:showDialog({title = gLanguageCsv.spaceTips, content = gLanguageCsv.megaConvertExceedLimit, isRich = true, btnType = 2, cb = normalTip})

	else
		normalTip()
	end
end

--规则
function MegaConversionView:ruleFunc()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1300})
end

function MegaConversionView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(self.ruleTitle)
		end),
		c.noteText(unpack(self.ruleContent)),
	}
	return context
end

return MegaConversionView
