local PropertySwapView = class("PropertySwapView", Dialog)


local SWAP_TYPE = {
	NATURE = 1, 	-- 性格
	NVALUE = 2, 	-- 个体值
	EFFORTVALUE = 3, -- 努力值
	FEEL = 4        -- 好感度
}

PropertySwapView.SWAP_TYPE = SWAP_TYPE

local function commonEffortValueShow(list, node, k, v)
	local childs = node:multiget("name", "icon", "num", "bar", "arrow")
	local name, icon = dataEasy.getEffortValueAttrData(game.ATTRDEF_ENUM_TABLE[v.attr])
	childs.name:text(name)
	childs.icon:texture(icon)
	if v.currVal then
		childs.num:text(v.currVal.."/"..v.maxVal)
		local progress = math.min(v.currVal / v.maxVal * 100, 100)
		childs.bar:percent(progress)
		if v.rightVal then
			childs.arrow:texture(v.rightVal > v.currVal and "common/icon/logo_arrow_green.png" or "common/icon/logo_arrow_red.png")
			childs.arrow:visible(v.rightVal ~= v.currVal)
		else
			childs.arrow:hide()
		end
		adapt.oneLinePos(childs.num, childs.arrow, cc.p(10, 0))
		if matchLanguage({"kr"}) then
			adapt.oneLinePos(childs.bar, childs.num, cc.p(5, 0))
			adapt.setTextScaleWithWidth(childs.name, nil, 100)
			adapt.oneLinePos(childs.num, childs.arrow, cc.p(5, 0))
		end
	end
end
PropertySwapView.RESOURCE_FILENAME = "card_property_swap_view.json"
PropertySwapView.RESOURCE_BINDING = {
	["leftItem"] = "leftItem",
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["leftList"] = {
		varname = "leftList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				margin = 5,
				data = bindHelper.self("leftData"),
				item = bindHelper.self("leftItem"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
						panel:get("txt"):getVirtualRenderer():setLineSpacing(-10)
					else
						selected:hide()
						panel = normal:show()
						panel:get("txt"):getVirtualRenderer():setLineSpacing(-10)
					end
					-- panel:get("txt"):text(v.name)
					local maxHeight = panel:getSize().height
					adapt.setAutoText(panel:get("txt"),v.name, maxHeight)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onLeftButtonClick"),
			},
		},
	},
	["txt"] = "txt",
	["leftPos"] = "leftPos",
	["leftPos.name"] = "leftName",
	["rightPanel"] = "rightPanel",
	["rightPanel.txt2"] = "rightPanelTxt",
	["btnAddSingle"] = {
		varname = "btnAddSingle",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSelect")}
		}
	},
	["btnAddDouble"] = "btnAddDouble",
	["btnAddDouble.btnAddSprite"] = {
		varname = "btnAddSprite",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSelect")}
		}
	},
	["btnAddDouble.text"] = "btnAddText",
	["btnAddDouble.btnAddItem"] = {
		varname = "btnAddItem",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSelectItem")}
		}
	},
	["btnExchange"] = {
		varname = "btnExchange",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onExchange")}
		}
	},
	["btnExchange.txt"] = {
		varname = "btnExchangeText",
		binds = {
			{
				event = "effect",
				data = {glow={color=ui.COLORS.GLOW.WHITE}}
			},
		}
	},
	["centerCharacter"] = "centerCharacter",
	["centerNvalue"] = "centerNvalue",
	["centerEffortValue"] = "centerEffortValue",
	['centerCharacter.leftPanel'] = "leftCharacter",
	['centerCharacter.rightPanel'] = "rightCharacter",
	["centerNvalue.leftPanel"] = "leftNValue",
	["centerNvalue.leftPanel.num"] = "leftNValueNum",
	["centerNvalue.leftPanel.pos"] = "leftNValuePos",
	["centerNvalue.rightPanel.pos"] = "rightNValuePos",
	["centerNvalue.rightPanel.num"] = "rightNValueNum",
	["centerEffortValue.itemAttr"] = "itemAttr",
	["centerEffortValue.leftPanel.num"] = "leftEffortValueNum",
	["centerEffortValue.rightPanel.txt"] = "rightEffortValueTxt",
	["centerEffortValue.rightPanel.num"] = "rightEffortValueNum",
	["centerEffortValue.leftPanel.num1"] = "leftEffortValueNum1",
	["centerEffortValue.rightPanel.txt1"] = "rightEffortValueTxt1",
	["centerEffortValue.rightPanel.num1"] = "rightEffortValueNum1",
	["centerEffortValue.leftPanel.arrow"] = "effortAdvanceArrow",
	["centerEffortValue.rightPanel.list"] = {
		varname = "rightEffortValueList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rightEffortValue"),
				item = bindHelper.self("itemAttr"),
				margin = 6,
				onItem = function(list, node, k, v)
					commonEffortValueShow(list, node, k, v)
				end,
			},
		},
	},
	["centerEffortValue.leftPanel.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("leftEffortValue"),
				item = bindHelper.self("itemAttr"),
				margin = 6,
				onItem = function(list, node, k, v)
					commonEffortValueShow(list, node, k, v)
				end,
			},
		},
	},
	["centerFeelValue"] = "centerFeelValue",

	["centerFeelValue.leftPanel.lvTxt"] = "leftFeelLv",
	["centerFeelValue.leftPanel.txt2"] = "leftFeelMaxTxt",
	["centerFeelValue.leftPanel.txt3"] = "leftFeelCurTxt",
	["centerFeelValue.leftPanel.bar"] = "leftFeelBar",

	["centerFeelValue.rightPanel.lvTxt"] = "rightFeelLv",
	["centerFeelValue.rightPanel.txt2"] = "rightFeelMaxTxt",
	["centerFeelValue.rightPanel.txt3"] = "rightFeelCurTxt",
	["centerFeelValue.rightPanel.bar"] = "rightFeelBar",
	["centerFeelValue.handbookPanel"] = {
		varname = "handbookPanel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onItemClick")}
		}
	},
	["centerFeelValue.btnInfo"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnInfo")}
		}
	},
	["costPanel"] = "costPanel",
	["costPanel.txt"] = "costTxt",
	["costPanel.cost"] = "cost",
	["costPanel.icon"] = "costIcon",
}

function PropertySwapView:onCreate(selTabKey, selectDbId)
	if not selectDbId then
		selectDbId = gGameModel.role:read("cards")[1]
	end
	self.cardFeels = gGameModel.role:getIdler("card_feels")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.selectDbId = selectDbId
	self.leftCard = gGameModel.cards:find(selectDbId)
	self.rightEffortAdvance = idler.new(0)
	local cardData = self.leftCard:read("card_id", "skin_id", "level", "star", "advance", "locked", "name")
	self.sprOrItemIds = idlertable.new({{0, 0}, {0, 0}, {0, 0}, {0,0}})	 -- 对应四个选项的精灵Id、道具Id
	local cardCsv = csv.cards[cardData.card_id]
	local unitCsv = csv.unit[cardCsv.unitID]
	self.cardMarkID = cardCsv.cardMarkID
	self.selectCardAdvance = idler.new()
	self.selectCardStar = idler.new()
	self.selectCardRarity = idler.new()
	self.selectCardLevel = idler.new()
	self.selectUnitId = idler.new()
	self:initCfg()
	bind.extend(self, self.leftPos, {
		class = "card_icon",
		props = {
			unitId = self.selectUnitId,
			advance = self.selectCardAdvance,
			star = self.selectCardStar,
			rarity = self.selectCardRarity,
			levelProps = {
				data = self.selectCardLevel,
			},
			params = {
				starScale = 0.85,
				starInterval = 12.5,
			},
		}
	})

	local leftButtonName = {
		{name = gLanguageCsv.natureSwap, desc = gLanguageCsv.nature, view = self.centerCharacter, cost = gCommonConfigCsv.characterSwapCostRmb},
		{name = gLanguageCsv.nvalueSwap, desc = gLanguageCsv.nvalue, view = self.centerNvalue, cost = gCommonConfigCsv.nvalueSwapCostRmb},
		{name = gLanguageCsv.effortvalueSwap, desc = gLanguageCsv.effortvalue, view = self.centerEffortValue, cost = gCommonConfigCsv.effortSwapCostRmb},
		{name = gLanguageCsv.feelValueSwap, desc = gLanguageCsv.feelValue, view = self.centerFeelValue, cost = gCommonConfigCsv.feelSwapCostRmb}
	}
	self.leftData = idlers.newWithMap(leftButtonName)
	selTabKey = string.upper(selTabKey or "NATURE")
	self.showTab = idler.new(SWAP_TYPE[selTabKey])
	self.showTab:addListener(function (val, oldval)
		local oldProxy = self.leftData:atproxy(oldval)
		local newProxy = self.leftData:atproxy(val)
		oldProxy.select = false
		oldProxy.view:hide()
		newProxy.view:show()
		newProxy.select = true

		local isCharacter = val == SWAP_TYPE.NATURE
		self.btnAddSingle:visible(not isCharacter)
		self.btnAddDouble:visible(isCharacter)
		if isCharacter then
			-- 性格页面特殊逻辑
			local hasItem = self:checkCharacterItem()
			local nameItem = self.centerCharacter:get("nameItem")
			local name = self.centerCharacter:get("name")
			local rightPos = self.centerCharacter:get("rightPos")
			self.btnAddItem:visible(hasItem)						 -- 按钮自身
			self.btnAddText:visible(hasItem)						 -- 或 字
			nameItem:visible(hasItem)	 -- 按钮下方的名字栏

			-- 因为要做位置变换 所以先进行计算后直接取用
			if not self.itemPos then
				local x1,x2 = self.btnAddSprite:x(), self.btnAddItem:x()
				local x3,x4 = name:x(), nameItem:x()
				local t = {
					btnPos = {x1, math.floor((x1+x2)/2 + 1.5)},
					textPos = {x3, math.floor((x3+x4)/2 + 0.5)},
				}
				self.itemPos = t
			end

			local btnPos = self.itemPos.btnPos
			local textPos = self.itemPos.textPos
			local idx = hasItem and 1 or 2
			self.btnAddSprite:x(btnPos[idx])
			name:x(textPos[idx])
			rightPos:x(textPos[idx])
			self.rightPanelTxt:text(hasItem and gLanguageCsv.chooseSprOrItem or gLanguageCsv.chooseSpr)
		else
			self.rightPanelTxt:text(gLanguageCsv.chooseSpr)
		end

		self.cost:text(newProxy.cost)
		idlereasy.when(self.rmb, function(_, rmb)
			self.cost:setTextColor(rmb >= newProxy.cost and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.RED)
		end):anonyOnly(self, 'rmb')
		adapt.oneLineCenterPos(cc.p(self.costPanel:width()/2, self.costPanel:height()/2), {self.costTxt, self.cost, self.costIcon}, cc.p(10, 0))
		if val ~= SWAP_TYPE.FEEL then
			self.txt:text(string.format(gLanguageCsv.swapCard, newProxy.desc))
		else
			self.txt:text(gLanguageCsv.swapFeel)
		end

		local isFeel = val == SWAP_TYPE.FEEL
		local advance, name
		if isFeel then
			self.selectCardAdvance:set(nil)
			self.selectCardStar:set(nil)
			self.selectCardRarity:set(unitCsv.rarity)
			self.selectCardLevel:set(nil)
			self.selectUnitId:set(cardCsv.unitID)
			-- 目前使用黑色，没其他地方使用卡牌颜色
			-- advance = game.QUALITY_TO_FITST_ADVANCE[unitCsv.rarity + 2]
		else
			self.selectCardAdvance:set(cardData.advance)
			self.selectCardStar:set(cardData.star)
			self.selectCardRarity:set(unitCsv.rarity)
			self.selectCardLevel:set(cardData.level)
			local unitId = dataEasy.getUnitId(cardData.card_id, cardData.skin_id)
			self.selectUnitId:set(unitId)
			name = cardData.name
			advance = cardData.advance
		end
		uiEasy.setIconName("card", cardData.card_id, {node = self.leftName, name = name, advance = advance, space = true})
	end)

	idlereasy.any({self.leftCard:getIdler("effort_values"), self.leftCard:getIdler("star"), self.leftCard:getIdler("level"), self.rightEffortAdvance}, function (_, val, star, level, rightEffortAdvance)
		local t = {}
		local total = 0
		local leftEffortAdvance = self.leftCard:read("effort_advance") or 1
		for i,v in orderCsvPairs(self.effortCfg) do
			local attrType = game.ATTRDEF_TABLE[v.attrType]
			local maxVal, totalVal = dataEasy.getCardEffortMax(i, cardData.card_id, attrType, leftEffortAdvance)
			local currVal = val[attrType] or 0
			table.insert(t, {
				attr = attrType,
				maxVal = maxVal,
				currVal = currVal - totalVal,
			})
			total = total + currVal
		end
		self.leftEffortValueNum:text(total)
		self.leftEffortValueNum1:text(dataEasy.getRomanNumeral(leftEffortAdvance))
		self.effortAdvanceArrow:texture(leftEffortAdvance < rightEffortAdvance and "common/icon/logo_arrow_green.png" or "common/icon/logo_arrow_red.png")
		self.effortAdvanceArrow:visible(leftEffortAdvance ~= rightEffortAdvance and rightEffortAdvance ~= 0)
		adapt.oneLinePos(self.leftEffortValueNum1, self.effortAdvanceArrow, cc.p(15,0))
		if not self.leftEffortValue then
			self.leftEffortValue = idlers.newWithMap(t)
		else
			self.leftEffortValue:update(t)
		end
	end)
	self.rightEffortValue = idlertable.new({})

	local function setCharacterPanel(character)
		local cfg = csv.character[character]
		local childs = self.rightCharacter:multiget("name", "none", "special")
		childs.name:text(cfg.name)
		local isHaveAttr = csvSize(cfg.attrMap) > 0
		childs.none:visible(not isHaveAttr)
		childs.special:visible(isHaveAttr)
		if isHaveAttr then
			for k,v in csvPairs(cfg.attrMap) do
				local num = tonumber(string.match(v,"%d+"))
				if num > 100 then
					childs.special:get("name1"):text(getLanguageAttr(k))
					local new = num - 100
					childs.special:get("num1"):text("+"..new.."%")
					if matchLanguage({"kr"}) then
						adapt.oneLinePos(childs.special:get("name1"), {childs.special:get("num1"), childs.special:get("green")}, cc.p(15, 0))
					end
				else
					local new = 100 - num
					childs.special:get("num2"):text("-"..new.."%")
					childs.special:get("name2"):text(getLanguageAttr(k))
					if matchLanguage({"kr"}) then
						adapt.oneLinePos(childs.special:get("name2"), {childs.special:get("num2"), childs.special:get("red")}, cc.p(15, 0))
					end
				end
			end
		end
	end

	local function setNvaluePanel(nvalue)
		local total = 0
		for k,v in pairs(nvalue) do
			total = total + v
		end
		self.rightNValueNum:text(total)
		self.rightNValuePos:removeAllChildren()
		bind.extend(self, self.rightNValuePos, {
			class = "draw_attr",
			props = {
				nvalue = nvalue,
				type = "big",
				offsetPos = {
					{x = -225, y = -365},
					{x = -200, y = -350},
					{x = -200, y = -370},
					{x = -225, y = -365},
					{x = matchLanguage({"kr", "en"}) and -265 or -210, y = -370},
					{x = matchLanguage({"kr", "en"}) and -265 or -210, y = -350},
				},
				perfectShow = false,
				offset = {x = 110, y = 100},
				numFontSize = 40,
				textFontSize = 36,
				onNode = function (node)
					node:get("img"):scale(0.58)
				end
			},
		})
	end

	local function setEffortPanel(effortAdvance, effortvalue)
		local t = {}
		local total = 0
		local i = 0
		for _,v in orderCsvPairs(self.effortCfg) do
			i = i + 1
			local attrType = game.ATTRDEF_TABLE[v.attrType]
			local currVal = effortvalue[attrType] or 0
			local maxVal, totalVal = dataEasy.getCardEffortMax(i, cardData.card_id, attrType, effortAdvance)
			table.insert(t, {
				attr = attrType,
				maxVal = maxVal,
				currVal = currVal - totalVal,
			})
			local leftProxy = self.leftEffortValue:atproxy(i)
			leftProxy.rightVal = currVal - totalVal
			total = total + currVal
		end
		self.rightEffortValue:set(t)
		self.rightEffortValueNum:text(total)
		self.rightEffortValueNum1:text(dataEasy.getRomanNumeral(effortAdvance))
		adapt.oneLinePos(self.rightEffortValueNum, self.rightEffortValueTxt, cc.p(15,0), "right")
		adapt.oneLinePos(self.rightEffortValueNum1, self.rightEffortValueTxt1, cc.p(15,0), "right")
	end

	local function setFeelPanel(level,cardId)
		local cardCsv = csv.cards[cardId]
		local cardFeels = self.cardFeels:read()
		local cardFeel = cardFeels[cardCsv.cardMarkID] or {}
		self.rightFeelLv:text(level)
		local maxLimitLv = table.length(gGoodFeelCsv[cardCsv.feelType])
		local feelCsv = gGoodFeelCsv[cardCsv.feelType]
		local clientNextLvExp = feelCsv[math.min(level + 1, maxLimitLv)].needExp
		local levelExp = cardFeel.level_exp or 0
		local progress = levelExp/clientNextLvExp*100
		self.rightFeelBar:percent(progress)
		self.rightFeelCurTxt:text(levelExp)
		self.rightFeelMaxTxt:text("/"..clientNextLvExp)
		if level == maxLimitLv then
			self.rightFeelBar:percent(100)
			local maxExp = feelCsv[level].needExp
			self.rightFeelCurTxt:text(maxExp)
			self.rightFeelMaxTxt:text("/"..maxExp)
		end
		adapt.oneLinePos(self.rightFeelMaxTxt, self.rightFeelCurTxt, nil, "right")
	end

	idlereasy.any({self.showTab, self.sprOrItemIds}, function (_, tab, ids)
		local sprId = ids[tab][1]
		local hasSpr = sprId ~= 0 -- 有id表示选中了精灵

		local posPanel = self.leftData:atproxy(tab).view:get("rightPos")
		local nameTxt = self.leftData:atproxy(tab).view:get("name")

		posPanel:visible(hasSpr)
		self.handbookPanel:visible(hasSpr)
		if hasSpr then
			local rightCard
			local cardData = {}
			local unitId = 0
			if self.showTab:read() ~= SWAP_TYPE.FEEL then
				rightCard = gGameModel.cards:find(sprId)
				cardData = rightCard:read("card_id", "skin_id", "level", "star", "advance", "locked", "name", "nvalue", "character", "effort_values", "effort_advance")
				unitId = dataEasy.getUnitId(cardData.card_id, cardData.skin_id)
			else
				cardData.card_id = sprId
				cardData.advance = nil
				cardData.star = nil
				cardData.level = nil
			end
			uiEasy.setIconName("card", cardData.card_id, {node = nameTxt, name = cardData.name, advance = cardData.advance, space = true})
			local cardCsv = csv.cards[cardData.card_id]
			local unitCsv = csv.unit[cardCsv.unitID]
			if unitId == 0 then
				unitId = cardCsv.unitID
			end
			bind.extend(self, posPanel, {
				class = "card_icon",
				props = {
					unitId = unitId,
					advance = cardData.advance,
					star = cardData.star,
					rarity = unitCsv.rarity,
					levelProps = {
						data = cardData.level,
					},
					params = {
						starScale = 0.85,
						starInterval = 12.5,
					},
				}
			})
			local cardCsv = csv.cards[cardData.card_id]
			local cardFeels = self.cardFeels:read()
			local cardFeel = cardFeels[cardCsv.cardMarkID] or {}
			local level = cardFeel.level or 0

			if tab == SWAP_TYPE.NATURE then
				setCharacterPanel(cardData.character)
			elseif tab == SWAP_TYPE.NVALUE then
				setNvaluePanel(cardData.nvalue)
			elseif tab == SWAP_TYPE.EFFORTVALUE then
				self.rightEffortAdvance:set(cardData.effort_advance)
				setEffortPanel(cardData.effort_advance, cardData.effort_values)
			else
				setFeelPanel(level, cardData.card_id)
			end
		else
			nameTxt:text(gLanguageCsv.chooseSpr)
			for i = 1, self.leftEffortValue:size() do
				local proxy = self.leftEffortValue:atproxy(i)
				proxy.rightVal = false
			end
		end

		---------------上方是精灵相关---------------
		---------------下方是道具相关---------------

		local itemId = ids[tab][2]
		local hasItem = itemId ~= 0
		posPanel = self.leftData:atproxy(tab).view:get("rightPosItem")
		nameTxt = self.leftData:atproxy(tab).view:get("nameItem")
		if posPanel then
			posPanel:visible(hasItem)
			if hasItem then
				local cfg = dataEasy.getCfgByKey(itemId)
				local num = dataEasy.getNumByKey(itemId)
				nameTxt:text(cfg.name)
				bind.extend(self, posPanel, {
					class = "icon_key",
					props = {
						data = {
							key = itemId,
							num = 1,
						},
						noListener = true,
						onNode = function(panel)
							panel:setTouchEnabled(false)
						end,
					}
				})
				-- todo  现在用到这一功能的只有性格道具 所以这里其他类型无视
				if tab == SWAP_TYPE.NATURE then
					setCharacterPanel(cfg.specialArgsMap.character)
				end
			else
				nameTxt:text(gLanguageCsv.chooseItem)
			end
		end

		if posPanel and hasItem then
			self.btnExchangeText:text(gLanguageCsv.use)
		else
			self.btnExchangeText:text(gLanguageCsv.exchange)
		end

		self.rightPanel:visible(not (hasSpr or hasItem))
		self.leftData:atproxy(tab).view:get("rightPanel"):visible(hasSpr or hasItem)
	end)

	idlereasy.when(self.leftCard:getIdler("character"), function (_, val)
		local cfg = csv.character[val]
		local childs = self.leftCharacter:multiget("name", "none", "special")
		childs.name:text(cfg.name)
		local isHaveAttr = csvSize(cfg.attrMap) > 0
		childs.none:visible(not isHaveAttr)
		childs.special:visible(isHaveAttr)
		if isHaveAttr then
			for k,v in csvPairs(cfg.attrMap) do
				local num = tonumber(string.match(v,"%d+"))
				local attrTypeStr = game.ATTRDEF_TABLE[k]
				local str = "attr" .. string.caption(attrTypeStr)
				if num > 100 then
					childs.special:get("name1"):text(gLanguageCsv[str])
					local new = num - 100
					childs.special:get("num1"):text("+"..new.."%")
					if matchLanguage({"kr"}) then
						adapt.oneLinePos(childs.special:get("name1"), {childs.special:get("num1"), childs.special:get("green")}, cc.p(15, 0))
					end
				else
					local new = 100 - num
					childs.special:get("num2"):text("-"..new.."%")
					childs.special:get("name2"):text(gLanguageCsv[str])
					if matchLanguage({"kr"}) then
						adapt.oneLinePos(childs.special:get("name2"), {childs.special:get("num2"), childs.special:get("red")}, cc.p(15, 0))
					end
				end
			end
		end
	end)

	idlereasy.when(self.leftCard:getIdler("nvalue"), function (_, val)
		local total = 0
		for k,v in pairs(val) do
			total = total + v
		end
		self.leftNValueNum:text(total)
		self.leftNValuePos:removeAllChildren()
		bind.extend(self, self.leftNValuePos, {
			class = "draw_attr",
			props = {
				nvalue = val,
				type = "big",
				offsetPos = {
					{x = -225, y = -365},
					{x = -200, y = -350},
					{x = -200, y = -370},
					{x = -225, y = -365},
					{x = matchLanguage({"kr", "en"}) and -265 or -210, y = -370},
					{x = matchLanguage({"kr", "en"}) and -265 or -210, y = -350},
				},
				perfectShow = false,
				offset = {x = 110, y = 100},
				numFontSize = 40,
				textFontSize = 36,
				onNode = function (node)
					node:get("img"):scale(0.58)
				end
			},
		})
	end)

	self.maxLimitLv = table.length(gGoodFeelCsv[cardCsv.feelType])
	idlereasy.when(self.cardFeels, function(_, cardFeels)
		local cardFeel = cardFeels[cardCsv.cardMarkID] or {}
		local level = cardFeel.level or 0
		local levelExp = cardFeel.level_exp or 0
		local feelCsv = gGoodFeelCsv[cardCsv.feelType]
		self.clientNextLvExp = feelCsv[math.min(level + 1, self.maxLimitLv)].needExp
		self.leftFeelLv:text(level)
		local progress = levelExp/self.clientNextLvExp*100
		self.leftFeelBar:percent(progress)
		self.leftFeelCurTxt:text(levelExp)
		self.leftFeelMaxTxt:text("/"..self.clientNextLvExp)
		if level == self.maxLimitLv then
			self.leftFeelBar:percent(100)
			local maxExp = feelCsv[level].needExp
			self.leftFeelCurTxt:text(maxExp)
			self.leftFeelMaxTxt:text("/"..maxExp)
		end
		adapt.oneLinePos(self.leftFeelMaxTxt, self.leftFeelCurTxt, nil, "right")
	end)
	Dialog.onCreate(self)
end

-- 检查自身是否有性格道具
function PropertySwapView:checkCharacterItem()
	for key, num in pairs(gGameModel.role:read("items")) do
		local cfg = csv.items[key]
		if cfg.type == game.ITEM_TYPE_ENUM_TABLE.characterType then
			return true
		end
	end
	return false
end

function PropertySwapView:onLeftButtonClick(list, index)
	self.showTab:set(index)
end

function PropertySwapView:setParams(sprId, itemId)
	self.sprOrItemIds:modify(function (val)
		val[self.showTab:read()] = {sprId or 0, itemId or 0}
	end, true)
end

-- 选择精灵的页面
function PropertySwapView:onSelect()
	gGameUI:stackUI("city.card.property_swap.choose", nil, nil, self.showTab:read(), self.selectDbId, self:createHandler("setParams"))
end

-- 筛选努力值配表
function PropertySwapView:initCfg()
	local cfg = {}
	for i,v in orderCsvPairs(csv.card_effort) do
		if v.attrType ~= game.ATTRDEF_ENUM_TABLE.specialDamage and v.advance == 1 then
			cfg[i] = v
		end
	end
	self.effortCfg = cfg
end

-- 选择道具的页面
function PropertySwapView:onSelectItem()
	gGameUI:stackUI("city.card.property_swap.choose_item", nil, nil, self.showTab:read(), self.selectDbId, self:createHandler("setParams"))
end

function PropertySwapView:onExchange()
	local tab = self.showTab:read()
	local ids = self.sprOrItemIds:read()[tab]
	local sprId = ids[1]
	local itemId = ids[2]
	if sprId == 0 and itemId == 0 then
		gGameUI:showTip(gLanguageCsv.propertyChoiceFirst)
		return
	end
	if self.rmb:read() < self.leftData:atproxy(self.showTab:read()).cost then
		uiEasy.showDialog("rmb")
		return
	end

	local str2 = gLanguageCsv.swapSuccess
	local strs
	if tab ~= SWAP_TYPE.FEEL then
		strs = string.format(gLanguageCsv.swapCardContinue, self.leftData:atproxy(tab).desc)
		-- 努力值特殊提醒
		if tab == SWAP_TYPE.EFFORTVALUE and self:effortsValue() then
			strs = string.format(gLanguageCsv.spriteUpperLimit, self.leftData:atproxy(tab).desc, self.leftData:atproxy(tab).desc)
		end
	else
		strs = gLanguageCsv.swapFeelContinue
	end
	local params = {strs = strs, cb = function ()
		local showOver = {false}
		local req
		if sprId ~= 0 then
			if tab ~= SWAP_TYPE.FEEL then
				req = gGameApp:requestServerCustom("/game/card/property/swap"):params(self.selectDbId, sprId, tab)
			else
				local leftCardData = self.leftCard:read("card_id", "level", "star", "advance", "locked", "name")
				req = gGameApp:requestServerCustom("/game/card/feel/swap"):params(leftCardData.card_id, sprId)
			end
		elseif itemId ~= 0 then
			req = gGameApp:requestServerCustom("/game/card/character/use_items"):params(self.selectDbId, itemId)
		else
			return
		end
		req:onResponse(function()
			-- 继承特效
			local pnode = self:getResourceNode()
			widget.addAnimationByKey(pnode, "effect/peiyanghuhuan.skel", 'peiyanghuhuan', "effect", 99)
				:anchorPoint(cc.p(0.5,0.5))
				:xy(pnode:width()/2, pnode:height()/2)
				:play("effect")
			performWithDelay(self, function()
				gGameUI:showTip(str2)
				self.sprOrItemIds:modify(function (val)
					val[self.showTab:read()] = {0, 0}
				end, true)
				showOver[1] = true
			end, 55/30)
		end)
		:wait(showOver)
		:doit()
	end, btnType = 2}

	if itemId ~= 0 then
		params.strs = gLanguageCsv.useCharacterItemTip
		params.isRich = true
		str2 = gLanguageCsv.characterChangeSuccess
		-- 检查目标性格和道具性格是否相同
		local cfg = dataEasy.getCfgByKey(itemId)
		if self.leftCard:read("character") == cfg.specialArgsMap.character then
			gGameUI:showTip(gLanguageCsv.characterSame)
			return
		end
	end
	local paramsCb = params.cb
	local function cb()
		dataEasy.sureUsingDiamonds(paramsCb, self.leftData:atproxy(self.showTab:read()).cost)
	end
	params.cb = cb
	gGameUI:showDialog(params)
end

--努力值交换损失时提示
function PropertySwapView:effortsValue()
	local number1, number2 = 0, 0
	local tab = self.showTab:read()
	local ids = self.sprOrItemIds:read()[tab]
	local cardId1 = self.leftCard:read("card_id")
	local cardId2 = gGameModel.cards:find(ids[1]):read("card_id")
	local effortSeqID1 = csv.cards[cardId1].effortSeqID
	local effortSeqID2 = csv.cards[cardId2].effortSeqID
	for i,v in csvPairs(csv.card_effort_advance) do
		if v.effortSeqID == effortSeqID1 and (v.advance <= v.advanceLimit) then
			number1 = number1 + v.hp + v.speed + v.damage + v.defence + v.specialDamage + v.specialDefence
		end
		if v.effortSeqID == effortSeqID2 and (v.advance <= v.advanceLimit) then
			number2 = number2 + v.hp + v.speed + v.damage + v.defence + v.specialDamage + v.specialDefence
		end
	end
	if tonumber(self.leftEffortValueNum:getString()) > number2 or tonumber(self.rightEffortValueNum:getString()) > number1 then
		return true
	end
	return false
end

function PropertySwapView:onBtnInfo()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1415})
end

function PropertySwapView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.feelSwapStatement)
		end),
		c.noteText(89001, 89010),
	}
	return context
end

function PropertySwapView:onItemClick()
	local tab = self.showTab:read()
	local ids = self.sprOrItemIds:read()[tab]
	local sprId = ids[1]
	local rightCardCsv = csv.cards[sprId]
	gGameUI:stackUI("city.handbook.view", nil, {full = true}, {cardId = rightCardCsv.id})
end

return PropertySwapView