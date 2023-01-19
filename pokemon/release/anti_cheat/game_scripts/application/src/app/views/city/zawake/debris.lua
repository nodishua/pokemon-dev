-- @date:   2021-04-08
-- @desc:   z觉醒碎片兑换界面

local DEBRIS_TYPE = {
	currency = 1, 	--通用
	exclusive = 2	--专属
}

local zawakeTools = require "app.views.city.zawake.tools"
local ViewBase = cc.load("mvc").ViewBase
local ZawakeDebrisView = class("ZawakeDebrisView", Dialog)

ZawakeDebrisView.RESOURCE_FILENAME = "zawake_debris.json"
ZawakeDebrisView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["titleTxt"] = "title",
	["item"] = "item",
	["btnList"] = {
		varname = "btnList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local btn = node:get("btn")
					local txt = node:get("title")
					txt:text(v.name)
					btn:setBright(not v.isSelected)
					node:onClick(functools.partial(list.itemClick, k))
					if v.isSelected then
						text.addEffect(txt, {glow = {color = ui.COLORS.GLOW.WHITE}, color = ui.COLORS.NORMAL.WHITE})
					else
						text.addEffect(txt, {color = ui.COLORS.NORMAL.RED})
					end
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onChangePage"),
			},
		},
	},
	["cardPanel1"] = "cardPanel1",
	["cardPanel2"] = "cardPanel2",
	["cardPanel1.card1"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:onChooseClick()
			end)}
		}
	},
	["cardPanel2.card1"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:onChooseClick()
			end)}
		}
	},
	["barPanel"] = "barPanel",
	["barPanel.myFrags"] = "myFrags",
	["barPanel.needFrags"] = "needFrags",
	["barPanel.bar"] = "slider",
	["barPanel.subBtn"] = {
		varname = "subBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, -1)
			end),
		}
	},
	["barPanel.addBtn"] = {
		varname = "addBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, 1)
			end),
		}
	},
	["needNum"] = "needNumText",
	["combTipPos"] = "combTipPos",
	["changeBtn"] = {
		varname = "changeBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeClick")}
		}
	},
	["changeBtn.title"] = {
		varname = "btnTxt",
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["priceItem"] = "priceItem",
	["priceList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("priceDatas"),
				item = bindHelper.self("priceItem"),
				onItem = function(list, node, k, v)
					local size = node:size()
					local childs = node:multiget("price", "icon", "txt1")
					childs.price:text(mathEasy.getShortNumber(v.num))
					text.addEffect(childs.price, {color = dataEasy.getNumByKey(v.key) >= v.num and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.ALERT_ORANGE})
					childs.icon:texture(ui.COMMON_ICON[v.key])
					adapt.oneLineCenterPos(cc.p(size.width/2, size.height/2), {childs.txt1, childs.price, childs.icon}, cc.p(10, 0))
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
				end,
			},
		},
	},
}

function ZawakeDebrisView:onCreate(params)
	self:enableSchedule()
	local fragID = params.fragID
	local needNum = params.needNum
	self.cb = params.cb
	self.fragID = fragID
	self.needNum = needNum

	self.selectCardDbId = idler.new() -- 选择的精灵
	self.costNum = idler.new(0)	--精灵兑换 消耗精灵个数
	self.selectedFragId = idler.new(0) 	--选择的碎片
	self.selectEpNum = idler.new(0) --选择兑换Z觉醒碎片的数量
	self:initModel()
	--页签数据
	local tabDatas = {
		{name = gLanguageCsv.fragChange, isSelected = false},
		{name = gLanguageCsv.cardChange, isSelected = false},
	}

	self.tabIdx = idler.new(1)
	local exchangeCsv = csv.zawake.exchange[fragID]
	self.fragExchangeRate = exchangeCsv.type == DEBRIS_TYPE.currency and exchangeCsv.needFrags[1][3] or exchangeCsv.needSpecialFrags[1][2]
	self.cardExchangeRate = exchangeCsv.cardConvertNum
	self.exchangeCsv = exchangeCsv
	self.priceDatas = idlers.newWithMap({})
	-- tab界面显示
	self.tabDatas = idlers.newWithMap(tabDatas)
	self.tabIdx:addListener(function(val, oldval, idler)
		if self.tabDatas:atproxy(oldval) then
			self.tabDatas:atproxy(oldval).isSelected = false
		end
		if self.tabDatas:atproxy(val) then
			self.tabDatas:atproxy(val).isSelected = true
		end
	end)

	idlereasy.any({self.tabIdx, self.gold, self.selectEpNum}, function (_, tabIdx, gold, selectEpNum)
		self:updatePrice(tabIdx == 2 and 1 or selectEpNum)
	end)

	--精灵兑换
	idlereasy.any({self.selectCardDbId, self.tabIdx}, function(_, selectCardDbId, tabIdx)
		local cardPanel = self.cardPanel1:hide()
		if tabIdx == 2 then
			cardPanel:show()
			if selectCardDbId then
				local card = gGameModel.cards:find(selectCardDbId)
				local cardId = card:read("card_id")
				local cardCsv = csv.cards[cardId]
				local unitCsv = csv.unit[cardCsv.unitID]
				local quality = dataEasy.getCfgByKey(cardCsv.fragID).quality
				local skinId = card:read("skin_id")
				local unitId = dataEasy.getUnitId(cardId,skinId)
				uiEasy.setIconName("card", cardId, {node = cardPanel:get("textName1"), name = cardCsv.name, advance = cardCsv.advance, space = true})
				bind.extend(self, cardPanel:get("card1.icon"), {
					class = "card_icon",
					props = {
						unitId = unitId,
						rarity = unitCsv.rarity,
						advance = card:read("advance"),
						star = card:read("star"),
						levelProps = {
							data = card:read("level"),
						},
						onNode = function (panel)
							panel:setTouchEnabled(false)
						end,
					}
				})
			else
				cardPanel:get("textName1"):text(gLanguageCsv.chooseSpriteTips)
			end
			cardPanel:get("card1.icon"):visible(selectCardDbId ~= nil)
			cardPanel:get("card1.imgAdd"):visible(selectCardDbId == nil)

			local key = fragID
			local num = self.cardExchangeRate
			bind.extend(self, cardPanel:get("card2"), {
				class = "icon_key",
				props = {
					data = {
						key = key,
						num = num,
					},
				},
			})
			uiEasy.setIconName(key, num, {node = cardPanel:get("textName2")})
			local quality = csv.zawake.zawake_fragments[fragID].quality
			local textColor = ui.COLORS.QUALITY[quality]
			text.addEffect(cardPanel:get("textName2"), {color = textColor})
			self.barPanel:hide()
		end
		self.needNumText:text(string.format("%s/%s", dataEasy.getNumByKey(self.fragID), self.needNum))
	end)

	--碎片兑换
	idlereasy.any({self.selectedFragId, self.selectEpNum, self.tabIdx, self.frags}, function(_, selectedFragId, selectEpNum, tabIdx, frags)
		local cardPanel = self.cardPanel2:hide()
		if tabIdx == 1 then
			cardPanel:show()
			--碎片兑换
			local changeNum = 0
			if selectedFragId > 0 and dataEasy.getNumByKey(selectedFragId) > 0 then
				changeNum = dataEasy.getNumByKey(selectedFragId)
				local quality = dataEasy.getCfgByKey(selectedFragId).quality
				local textColor = ui.COLORS.QUALITY[quality]
				local bind1s = {
					class = "icon_key",
					props = {
						data = {
							key = selectedFragId,
							num = changeNum,
							targetNum = self.fragExchangeRate * (selectEpNum == 0 and 1 or selectEpNum),
						},
						onNode = function(node)
							node:setTouchEnabled(false)
						end,
					},
				}
				cardPanel:get("card1.imgAdd"):hide()
				cardPanel:get("textName1"):text(uiEasy.setIconName(selectedFragId))
				bind.extend(self, cardPanel:get("card1.icon"), bind1s)
				text.addEffect(cardPanel:get("textName1"), {color = textColor})
			else
				cardPanel:get("card1.imgAdd"):show()
				cardPanel:get("textName1"):text(gLanguageCsv.selectFragment)
				text.addEffect(cardPanel:get("textName1"), {color = ui.COLORS.NORMAL.DEFAULT})
			end
			cardPanel:get("card1.icon"):visible(selectedFragId > 0)

			local key = fragID
			local num = math.max(selectEpNum, 1)
			bind.extend(self, cardPanel:get("card2"), {
				class = "icon_key",
				props = {
					data = {
						key = key,
						num = num,
					},
				},
			})
			uiEasy.setIconName(key, num, {node = cardPanel:get("textName2")})

			local quality = csv.zawake.zawake_fragments[fragID].quality
			local textColor = ui.COLORS.QUALITY[quality]
			text.addEffect(cardPanel:get("textName2"), {color = textColor})

			--可转换的最大数量
			self.maxNum = math.floor(changeNum/self.fragExchangeRate)
			--设置滑动条
			if not self.slider:isHighlighted() then
				local num =  math.ceil(selectEpNum / math.floor(changeNum/self.fragExchangeRate)*100)
				self.slider:setPercent(num)
				if changeNum == 0 then
					self.slider:setTouchEnabled(false)
				else
					self.slider:setTouchEnabled(true)
				end
			end
			--设置滑动条上边的显示数量
			self.barPanel:show()
			self.needFrags:text("/"..self.maxNum)
			self.myFrags:text(selectEpNum)
			adapt.oneLineCenterPos(cc.p(self.barPanel:size().width/2, self.myFrags:y()), {self.myFrags, self.needFrags})
			--加减按钮
			uiEasy.setBtnShader(self.addBtn, nil, (selectEpNum+1)*self.fragExchangeRate <= changeNum  and 1 or 2)
			uiEasy.setBtnShader(self.subBtn, nil, selectEpNum > 0 and 1 or 2)
		end
		self.needNumText:text(string.format("%s/%s", dataEasy.getNumByKey(self.fragID), self.needNum))
	end)
	self.slider:setPercent(0)
	self.slider:addEventListener(function(sender,eventType)
		if eventType == ccui.SliderEventType.percentChanged then
			self:unScheduleAll()
			local percent = sender:getPercent()
			local num = math.floor(self.maxNum * percent * 0.01)
			self.selectEpNum:set(num)
		end
	end)

	Dialog.onCreate(self)
end

function ZawakeDebrisView:initModel()
	self.cards = gGameModel.role:getIdler("cards")
	self.cardCapacity = gGameModel.role:getIdler("card_capacity")--背包容量
	self.frags = gGameModel.role:getIdler("frags")
	self.gold = gGameModel.role:getIdler("gold")
end

function ZawakeDebrisView:updatePrice(num)
	num = math.max(num, 1)
	local costData = self.tabIdx:read() == 2 and self.exchangeCsv.costItemCard or self.exchangeCsv.costItemFrag
	local data = {}
	self.costArr = {}
	for key, val in csvMapPairs(costData) do
		self.costArr[key] = num * val
		table.insert(data, {key = key, num = num * val})
	end
	self.priceDatas:update(data)
end

function ZawakeDebrisView:onIncreaseNum(step)
	self.selectEpNum:modify(function(num)
		return true, cc.clampf(num + step, 0, math.max(self.maxNum, 0))
	end)
end

function ZawakeDebrisView:onChangeNum(node, event, step)
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

--切换页签
function ZawakeDebrisView:onChangePage(list, k)
	self.tabIdx:set(k)
end

function ZawakeDebrisView:onChangeClick()
	local cb = function() end
	local itemName = dataEasy.getCfgByKey(self.fragID).name
	local str, params = "", {}
	if self.tabIdx:read() == 2 then
		if self.selectCardDbId:read() == nil then
			gGameUI:showTip(string.format(gLanguageCsv.chooseSpriteTips))
			return
		end
		cb = function ()
			self.costNum:set(0)
			self.selectCardDbId:set(nil)
		end
		--精灵兑换
		params = {cardID = self.selectCardDbId:read()}
		local cardid = gGameModel.cards:find(self.selectCardDbId:read()):read("card_id")
		local cardName = csv.cards[cardid].name
		str = string.format(gLanguageCsv.consumeConversionSprite, cardName, self.cardExchangeRate, itemName)
	else
		local num = self.selectEpNum:read()
		if self.selectedFragId:read() == 0 then
			gGameUI:showTip(string.format(gLanguageCsv.selectFragment))
			return
		end
		if num == 0 then
			gGameUI:showTip(string.format(gLanguageCsv.pleaseSelectNumber, gLanguageCsv.starSkillExchange))
			return
		end
		cb = function()
			self.selectEpNum:set(0)
			self.slider:setPercent(0)
			self.selectedFragId:set(0)
		end
		-- 碎片兑换
		params = {fragID = self.selectedFragId:read(), num = num}
		local cardName = dataEasy.getCfgByKey(self.selectedFragId:read()).name
		local costNum = self.fragExchangeRate * num
		str = string.format(gLanguageCsv.consumeConversionFigment, costNum, cardName, num, itemName)
	end
	for key, num in pairs(self.costArr) do
		if dataEasy.getNumByKey(key) < num then
			if key == "gold" then
				uiEasy.showDialog("gold")
			else
				gGameUI:showTip(gLanguageCsv.exchangeItemNotEnough)
			end
			return
		end
	end

	local function normalTip(cb)
		gGameUI:showDialog({title = gLanguageCsv.spaceTips, content = str, isRich = true, btnType = 2, cb = function ()
			self:sendExchange(params, cb)
		end})
	end
	normalTip(cb)
end

function ZawakeDebrisView:sendExchange(params, cb)
	local cardID = params.cardID
	local fragID = params.fragID
	local num = params.num
	gGameApp:requestServer("/game/card/zawake/exchange",function (tb)
		gGameUI:showGainDisplay(tb)
		cb()
	end, self.fragID, cardID, fragID, num)
end

function ZawakeDebrisView:onChooseClick()
	local tabIdx = self.tabIdx:read()
	local params = {selectedFragId = self.selectedFragId, fragID = self.fragID}
	local viewName = "city.zawake.choose_fragment"
	if tabIdx == 2 then
		params = {selectCardDbId = self.selectCardDbId, fragID = self.fragID}
		viewName = "city.zawake.choose_card"
	end
	gGameUI:stackUI(viewName, nil, nil, params)
end

function ZawakeDebrisView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

return ZawakeDebrisView