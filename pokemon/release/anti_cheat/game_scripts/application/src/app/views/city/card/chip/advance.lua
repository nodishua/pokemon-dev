-- @date 2021-5-11
-- @desc 学习芯片强化洗练

local ChipAdvanceView = class("ChipAdvanceView", cc.load("mvc").ViewBase)
local ChipTools = require('app.views.city.card.chip.tools')

local function bagOrderCmp(a, b)
	if a.type == "item" or b.type == "item" then
		if a.type ~= b.type then
			return a.type == "item"
		end
		return a.idx < b.idx
	end
	if a.cfg.quality ~= b.cfg.quality then
		return a.cfg.quality < b.cfg.quality
	end
	if a.level ~= b.level then
		return a.level < b.level
	end
	if a.cfg.suitID ~= b.cfg.suitID then
		return a.cfg.suitID < b.cfg.suitID
	end
	if a.cfg.pos ~= b.cfg.pos then
		return a.cfg.pos < b.cfg.pos
	end
	return a.idx < b.idx
end

ChipAdvanceView.RESOURCE_FILENAME = "chip_advance.json"
ChipAdvanceView.RESOURCE_BINDING = {
	["leftPanel"] = "leftPanel",
	["leftPanel.btnRebirth"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRebirth")}
		}
	},
	["leftPanel.btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowRule")}
		}
	},
	["leftPanel.btnRule.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		},
	},

	["leftPanel.btnRebirth.txtInfo01"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE, size = 4}},
		},
	},
	["leftPanel.btnRebirth.txtInfo02"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE, size = 4}},
		},
	},

	["strengthenPanel"] = "strengthenPanel",
	["advancePanel"] = "advancePanel",
	["subAttrDetailPanel"] = "subAttrDetailPanel",
	["line"] = "line",
	["tabItem"] = "tabItem",
	["tabList"] = {
		varname = "tabList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabData"),
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
					local maxHeight = panel:getSize().height - 40
					adapt.setAutoText(panel:get("txt"), v.name, maxHeight)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, node, k, v)}})
					if v.redHint then
						v.redHint.state = v.select ~= true
						bind.extend(list, node, v.redHint)
					end
					uiEasy.updateUnlockRes(v.unlockKey, normal, {justRemove = not v.unlockKey, pos = cc.p(100, 220)})
						:anonyOnly(list, list:getIdx(k))
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabItemClick"),
			},
		},
	},
	["strengthenPanel.item"] = "strengthenItem",
	["strengthenPanel.subList"] = "strengthenSubList",
	["strengthenPanel.empty"] = "empty",
	['strengthenPanel.list'] = {
		varname = "strengthenList",
		binds = {
			event = 'extend',
			class = 'tableview',
			props = {
				asyncPreload = bindHelper.self('asyncPreload'),
				columnSize = bindHelper.self('midColumnSize'),
				data = bindHelper.self('strengthenData'),
				item = bindHelper.self('strengthenSubList'),
				cell = bindHelper.self('strengthenItem'),
				topPadding = 10,
				dataOrderCmp = bagOrderCmp,
				onCell = function(list, node, k, v)
					node:get("select"):hide():scale(1.1)
					local grayState = 0
					local selected = false
					if v.type == "item" then
						if (v.selectedNum or 0) > 0 then
							grayState = 1
							selected = true
						end
					else
						if v.selected then
							grayState = 1
							selected = true
						end
					end
					node:get("tick"):visible(selected)
					bind.extend(list, node, {
						class = 'icon_key',
						props = {
							noListener = true,
							data = {
								key = v.key,
								num = v.num and (v.selectedNum or 0) or nil,
								targetNum = v.num,
								noColor = true,
							},
							specialKey = {
								leftTopLv = v.level,
								locked = v.locked,
							},
							grayState = grayState,
							onNode = function(panel)
								panel:scale(1.1)
								panel:setTouchEnabled(false)
							end
						},
					})

					local selectItem = list.selectItem()
					idlereasy.when(selectItem, function(_, selectItem)
						if v.type == "item" then
							node:get("select"):visible(selectItem.key == v.key)
						else
							node:get("select"):visible(selectItem.dbId == v.dbId)
						end
					end):anonyOnly(list, v.dbId or v.key)

					bind.touch(list, node, {method = function(_, _, event,...)
						list.itemTouch(node, list:getIdx(k), v, event)
					end})
				end
			},
			handlers = {
				itemTouch = bindHelper.self('onItemTouch'),
				selectItem = bindHelper.self('selectItem'),
			}
		}
	},
	["strengthenPanel.costPanel"] = "strengthenCostPanel",
	["strengthenPanel.btnStrengthen"] = {
		varname = "btnStrengthen",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onStrengthenClick")}
		}
	},
	["strengthenPanel.btnStrengthen.title"] = {
		binds = {
			event = "effect",
			data = {color=ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["strengthenPanel.quickSelectPanel"] = "quickSelectPanel",
	["strengthenPanel.quickSelectPanel.item"] = "quickSelectItem",
	["strengthenPanel.quickSelectPanel.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("quickSelectData"),
				item = bindHelper.self("quickSelectItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("bg", "name", "selected")
					childs.bg:texture(v.icon)
					childs.name:text(v.name)
					childs.selected:visible(v.selected == true)
					text.addEffect(childs.name, {color = ui.COLORS.QUALITY[v.quality]})
					bind.touch(list, node, {methods = {
						ended = functools.partial(list.clickCell, k, v)
					}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onQuickSelectClick"),
			},
		},
	},
	["advancePanel.resetCostPanel"] = "resetCostPanel",
	["advancePanel.btnReset"] = {
		varname = "btnReset",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onResetClick")}
		}
	},
	["advancePanel.advanceTip"] = "advanceTip",
	["advancePanel.costPanel"] = "costPanel",
	["advancePanel.btnAdvance"] = {
		varname = "btnAdvance",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAdvanceClick")}
		}
	},
	["advancePanel.btnAdvance.title"] = {
		binds = {
			event = "effect",
			data = {color=ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["panelRule"] = "panelRule",
}

-- @param chip dbId
function ChipAdvanceView:onCreate(dbId)
	self.dbId = dbId
	self.isFirst = true

	gGameUI.topuiManager:createView("chip", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.chipAdvanceTitle, subTitle = "CHIP ADVANCE"})
	self:initModel()

	adapt.dockWithScreen(self.leftPanel, "left")
	adapt.dockWithScreen(self.advancePanel:get("ruleList"), "left")
	local _, count = adapt.centerWithScreen("left", "right", {
		itemWidth = self.strengthenItem:width(),
		itemWidthExtra = 80,
	},{
		{{self.strengthenList, self.strengthenSubList}, "width"},
		{{self.strengthenList, self.quickSelectPanel}, "pos", 'left'},
		{{self.btnStrengthen, self.strengthenCostPanel, self.line, self.tabList, self.subAttrDetailPanel:get("panel")}, "pos", 'right'},
	})
	self.midColumnSize = 4 + (count or 0)
	self.asyncPreload = self.midColumnSize * 5

	self:initSubAttrDetailPanel()

	self.tabData = idlers.newWithMap({})
	self:initTabData()
	self.showTab = idler.new(1)
	self.showTab:addListener(function(val, oldval, idler)
		self.tabData:atproxy(oldval).select = false
		self.tabData:atproxy(val).select = true
		self.advancePanel:visible(val == 2)
		self.strengthenPanel:visible(val == 1)
		self.leftPanel:get("attrPanel"):visible(val == 1)
	end)

	self.sign = false
	self.advanceLv = self.chipCfg.acquiredLevels[csvSize(self.chipCfg.acquiredLevels)]

	self.isRefreshBagPanel = idler.new(true)
	self.strengthenData = idlers.newWithMap({})
	self.advanceData = idlers.newWithMap({})
	self.selectItem = idlereasy.new({})
	self.costChips = {}
	self.costCsvIDs = {}

	self:initLeftPanel()
	idlereasy.when(self.isRefreshBagPanel, function()
		self:setStrengthData()
	end)
	self:setAdvanceData()
	self:setAttrSelectIdx()
	self:initAdvanceRuleList()

	self.isFirst = false
end


function ChipAdvanceView:initModel()
	self.gold = gGameModel.role:getIdler("gold")
	self.rmb = gGameModel.role:getIdler("rmb")
	local chip = gGameModel.chips:find(self.dbId)
	self.chipLevel = chip:getIdler("level")
	self.chipLevelExp = chip:getIdler("level_exp")
	self.chipNow = chip:getIdler("now")

	self.chipId = chip:read("chip_id")
	self.cardDBID = chip:read("card_db_id")
	self.chipCfg = csv.chip.chips[self.chipId]
end

function ChipAdvanceView:setAttrSelectIdx()
	local firstAttrs, secondAttrs = ChipTools.getAttr(self.dbId, nil, true)

	local t = {}
	local idx = 0
	for i, data in ipairs(secondAttrs) do
		local key = data.key
		if not ChipTools.ignoreAttr(key) then
			idx = idx + 1
			if data.now[2] > 0 then
				t[idx] = true
			end
		end
	end
	self.curSecondAttrSelect:set(t)
end

function ChipAdvanceView:initAdvanceRuleList()
	local attrDatas = {}
	for i=124401,124405 do
		if not csv.note[i] then break end
		local content = csv.note[i].fmt or ""
		table.insert(attrDatas,  "#C0x5B545B#"..content)
		table.insert(attrDatas,  "")
	end

	beauty.textScroll({
		list = self.advancePanel:get("ruleList"),
		strs = attrDatas,
		isRich = true,
	})
end

function ChipAdvanceView:initTabData()
	local tabData = {
		{
			name = gLanguageCsv.chipStrengthenSpace,
		},
		{
			name = gLanguageCsv.chipAdvanceSpace,
			unlockKey = "chipAdvance",
		}
	}
	local t = {}
	for i, v in pairs(tabData) do
		if not v.unlockKey or dataEasy.isShow(v.unlockKey) then
			t[i] = clone(v)
		end
	end
	self.tabData:update(t)
end

function ChipAdvanceView:onTabItemClick(list, node, k, v)
	if v.unlockKey and not dataEasy.isUnlock(v.unlockKey) then
		gGameUI:showTip(dataEasy.getUnlockTip(v.unlockKey))
	else
		self.showTab:set(k)
	end
end

function ChipAdvanceView:initLeftPanel()
	local childs = self.leftPanel:multiget("itemName", "itemIconBg", "itemIcon", "cardIcon", "cardNote")
	local quality = self.chipCfg.quality
	childs.itemName:text(self.chipCfg.name)
	text.addEffect(childs.itemName, {color=ui.COLORS.QUALITY[quality]})
	childs.itemIconBg:texture(string.format("city/card/helditem/strengthen/img_dt%d.png", quality))
	bind.extend(self, childs.itemIcon, {
		class = 'icon_key',
		props = {
			noListener = true,
			data = {
				key = self.chipId,
			},
			simpleShow = true,
			onNode = function(panel)
				panel:scale(2)
				panel:get("fragBg"):show()
			end,
		},
	})

	childs.cardNote:hide()
	if self.cardDBID then
		childs.cardNote:show()
		local card = gGameModel.cards:find(self.cardDBID):read("card_id", "skin_id", "advance", "level", "star")
		local cardCfg = csv.cards[card.card_id]
		local unitCfg = csv.unit[cardCfg.unitID]
		local unitId = dataEasy.getUnitId(card.card_id, card.skin_id)
		bind.extend(self, childs.cardIcon, {
			class = "card_icon",
			props = {
				levelProps = {
					data = card.level,
				},
				rarity = unitCfg.rarity,
				unitId = unitId,
				advance = card.advance,
				star = card.star,
				onNode = function(panel)
					panel:scale(1.1)
					panel:alignCenter(childs.cardIcon:size())
				end
			}
		})
	end

	local levelPanel = self.leftPanel:get("levelPanel")
	self.clientChipLevel = idler.new()
	self.clientChipLevelExp = idler.new()
	self.clientChipAddExp = idler.new()
	self.clientChipLeftAddExp = 0 -- 剩余可添加的经验
	idlereasy.when(self.chipLevel, function(_, level)
		levelPanel:get("level1"):text("Lv" .. level)
		self.clientChipLevel:set(level, true)

		self.sign = level >= self.advanceLv
		self.costPanel:visible(self.sign)
		self.advanceTip:visible(not self.sign)
		self.btnAdvance:setTouchEnabled(self.sign)
		uiEasy.setBtnShader(self.btnAdvance, self.btnAdvance:get("title"), not self.sign and 2 or 1)
	end)
	idlereasy.any({self.chipLevelExp,self.chipLevel}, function(_, levelExp)
		self.clientChipAddExp:set(0, true)
		self.costChips = {}
		self.costCsvIDs = {}
		self:setStrengthData()
	end)
	idlereasy.when(self.clientChipLevel, function(_, level)
		local childs = levelPanel:multiget("level1", "iconArrow", "level2", "iconMax")
		local isSame = level == self.chipLevel:read()
		childs.iconArrow:visible(not isSame)
		childs.level2:visible(not isSame)
		if not isSame then
			childs.level2:text("Lv" .. level)
		end
		childs.iconMax:visible(level >= self.chipCfg.maxLevel)
		adapt.oneLinePos(childs.level1, {childs.iconArrow, childs.level2, childs.iconMax},cc.p(0, 0))
	end)
	idlereasy.any({self.clientChipAddExp, self.gold}, function(_, addLevelExp, gold)
		local level = self.chipLevel:read()
		local levelExp = self.chipLevelExp:read() + addLevelExp
		local leftExp = 0
		local strengthSeq = self.chipCfg.strengthSeq
		for i = level, self.chipCfg.maxLevel - 1 do
			local levelExpMax = csv.chip.strength_cost[i]["levelExp" .. strengthSeq]
			if levelExp >= levelExpMax then
				level = level + 1
				levelExp = levelExp - levelExpMax
			else
				leftExp = leftExp + levelExpMax
			end
		end
		leftExp = leftExp - levelExp

		self.clientChipLeftAddExp = leftExp
		self.clientChipLevelExp:set(levelExp)
		self.clientChipLevel:set(level)
		local levelExpMax = csv.chip.strength_cost[level]["levelExp" .. strengthSeq]

		if level == self.chipCfg.maxLevel then
			levelExpMax = csv.chip.strength_cost[level - 1]["levelExp" .. strengthSeq]
			levelExp = levelExpMax
		end

		levelPanel:get("bar"):percent(100 * levelExp / levelExpMax)
		levelPanel:get("percent"):text(levelExp .. "/" .. levelExpMax)
		uiEasy.setBtnShader(self.btnStrengthen, self.btnStrengthen:get("title"), addLevelExp == 0 and 2 or 1)

		self.strengthenCostGold = addLevelExp * gCommonConfigCsv.chipExpNeedGold
		self.strengthenCostPanel:show()
		local childs = self.strengthenCostPanel:multiget("cost", "icon", "note")
		childs.cost:text(self.strengthenCostGold)
		local isEnough = gold >= self.strengthenCostGold
		text.addEffect(childs.cost, {color = isEnough and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.RED})

		adapt.oneLinePos(childs.icon, {childs.cost, childs.note}, cc.p(10, 0), "right")
	end)


	local leftAttrPanel = self.leftPanel:get("attrPanel")
	local list = leftAttrPanel:get("attrList")
	list:setScrollBarEnabled(false)
	leftAttrPanel:get("attrTip"):text(gLanguageCsv.strengthenSecondTip)

	self.leftFirstAttrsData = {}
	self.leftSecondAttrsData = {}
	idlereasy.any({self.clientChipLevel, self.chipLevel, self.chipNow}, function(_, clientChipLevel, chipLevel, chipNow)
		local idx = 0
		local firstAttrs, secondAttrs = ChipTools.getAttr(self.dbId, nil, true, true)
		local clientFirstAttrs, _ = ChipTools.getAttr(self.dbId, clientChipLevel, true)
		local isMax = clientChipLevel >= self.chipCfg.maxLevel
		for i, data in ipairs(firstAttrs) do
			local key = data.key
			if not ChipTools.ignoreAttr(key) then
				idx = idx + 1
				local val = data.val
				local upVal = nil
				if clientChipLevel ~= chipLevel then
					upVal = dataEasy.attrSubtraction(clientFirstAttrs[i].val, val)
				end
				self:setLeftAttrItem(1, idx, {key = key, val = val, upVal = upVal, isMax = isMax})
			end
		end
		if self.isFirst then
			local lineItem = leftAttrPanel:get("lineItem"):clone():show()
			list:pushBackCustomItem(lineItem)
		end
		idx = 0
		for i, data in ipairs(secondAttrs) do
			local key = data.key
			if not ChipTools.ignoreAttr(key) then
				idx = idx + 1
				local val = data.val
				self:setLeftAttrItem(2, idx, {key = key, val = val, name = data.name})
			end
		end
		local strengthenSecondAttrTip = false
		for _, v in csvPairs(self.chipCfg.acquiredLevels) do
			if v > chipLevel and v <= clientChipLevel then
				strengthenSecondAttrTip = true
				break
			end
		end
		if not strengthenSecondAttrTip then
			-- 当前副属性未强化到上限
			for id, data in ipairs(chipNow) do
				if data[3] < csvSize(csv.chip.libs[data[1]].attrNum1) - 1 then
					for _, v in csvPairs(self.chipCfg.strengthLevels) do
						if v > chipLevel and v <= clientChipLevel then
							strengthenSecondAttrTip = true
							break
						end
					end
					break
				end
			end
		end
		-- 新增副属性或已有副属性强化
		leftAttrPanel:get("attrTip"):visible(strengthenSecondAttrTip)
	end)

	self.quickSelectData = idlers.newWithMap({
		{name = gLanguageCsv.greenText, icon = "city/develop/explore/tag_2.png", quality = 2},
		{name = gLanguageCsv.blueText, icon = "city/develop/explore/tag_3.png", quality = 3},
		{name = gLanguageCsv.purpleText, icon = "city/develop/explore/tag_4.png", quality = 4},
		{name = gLanguageCsv.orangeText, icon = "city/develop/explore/tag_5.png", quality = 5},
	})
end

-- @param attrType 1: firstAttr 2:secondAttr
-- @param params {key, val, upVal, isMax}
function ChipAdvanceView:setLeftAttrItem(attrType, idx, params)
	local leftAttrPanel = self.leftPanel:get("attrPanel")
	local list = leftAttrPanel:get("attrList")
	local data = attrType == 1 and self.leftFirstAttrsData or self.leftSecondAttrsData
	local name = params.key and ChipTools.getAttrName(params.key) or params.name
	local val = params.key and ("+" .. params.val) or params.val
	local item
	if data[idx] then
		item = data[idx].item
		params.isNew = false
		if self.isStrengthenClick then
			params.isNew = data[idx].isNew
		end
		if item:get("name"):text() ~= name or item:get("val"):text() ~= val then
			performWithDelay(self, function()
				if not tolua.isnull(item) then
					local effect = item:get("effect")
					if not effect then
						effect = widget.addAnimationByKey(item, "effect/shuzisaoguang.skel", "effect", "effect", 100)
							:xy(100, 40)
							:scale(2, 0.5)
					end
					effect:play("effect")
				end
			end, 0.1)
		end
		-- 属性提升则显示对应特效
	else
		item = leftAttrPanel:get("attrItem"):clone():show()
		list:pushBackCustomItem(item)
		params.isNew = not self.isFirst
	end
	params.item = item
	data[idx] = params
	item:get("name"):text(name)
	item:get("val"):text(val)
	local color = params.key and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.GRAY
	text.addEffect(item:get("name"), {color = color})
	text.addEffect(item:get("val"), {color = color})
	local upValChilds = item:multiget("up1", "upVal", "upIcon", "up2")
	itertools.invoke(upValChilds, "visible", params.upVal ~= nil)
	if params.upVal then
		item:get("upVal"):text("+" .. params.upVal)
		adapt.oneLinePos(upValChilds.up1, {upValChilds.upVal, upValChilds.upIcon, upValChilds.up2})
	end
	item:get("iconMax"):visible(not params.upVal and params.isMax or false)
	item:get("iconNew"):visible(not params.upVal and params.isNew or false)
end

function ChipAdvanceView:getStrengthData()
	local roleChips = gGameModel.role:read("chips")
	local items = gGameModel.role:read("items")
	local data = {}
	local idx = 0
	local addExp = 0
	for _, v in ipairs(gChipExpCsv) do
		local num = dataEasy.getNumByKey(v.id)
		if num > 0 then
			idx = idx + 1
			local exp = csv.items[v.id].specialArgsMap.chipExp
			table.insert(data, {type = "item", key = v.id, num = num, idx = idx, exp = exp, selectedNum = self.costCsvIDs[v.id]})
		end
	end
	for _, v in ipairs(roleChips) do
		local chip = gGameModel.chips:find(v)
		local chipDatas = chip:read("chip_id", "card_db_id", "level", "level_exp", "sum_exp", "locked")
		if v ~= self.dbId and not chipDatas.card_db_id then
			idx = idx + 1
			local chipId = chipDatas.chip_id
			local cfg = csv.chip.chips[chipId]
			local exp = cfg.exp + chipDatas.sum_exp
			if chipDatas.locked and self.costChips[v] then
				self.costChips[v] = nil
				addExp = addExp - exp
			end
			table.insert(data, {dbId = v, key = chipId, level = chipDatas.level, locked = chipDatas.locked, cfg = cfg, idx = idx, exp = exp, selected = self.costChips[v]})
		end
	end
	self.clientChipAddExp:modify(function(val)
		return true, val + addExp
	end, true)
	return data
end

function ChipAdvanceView:setStrengthData()
	local data = self:getStrengthData()
	dataEasy.tryCallFunc(self.strengthenList, "updatePreloadCenterIndexAdaptFirst")
	self.strengthenData:update(data)
	self.empty:visible(itertools.size(data) == 0)
end

function ChipAdvanceView:onItemChange(list, node, v, num)
	self.costCsvIDs[v.key] = num
	bind.extend(list, node, {
		class = 'icon_key',
		props = {
			noListener = true,
			data = {
				key = v.key,
				num = num,
				targetNum = v.num,
				noColor = true,
			},
			grayState = num > 0 and 1 or 0,
		},
	})
	node:get("tick"):visible(num > 0)
	self.clientChipAddExp:modify(function(exp)
		return true, self.originClientChipAddExp + v.exp * num
	end)
end

function ChipAdvanceView:onItemTouchShow(list, node, t, v)
	local pos = node:convertToWorldSpaceAR(cc.p(0, 0))
	local align = "right"
	if t.col > 2 then
		align = "left"
	end
	if v.type == "item" then
		local originNum = self.costCsvIDs[v.key] or 0
		self.originClientChipAddExp = self.clientChipAddExp:read() - v.exp * originNum
		local exp = csv.items[v.key].specialArgsMap.chipExp
		local maxNum = math.min(originNum + math.ceil(self.clientChipLeftAddExp/exp), v.num)
		gGameUI:stackUI('city.card.chip.item_details', nil, {dispatchNodes = self.strengthenPanel, clickClose = true}, {
			id = v.key,
			num = originNum,
			maxNum = maxNum,
			pos = pos,
			align = align,
			chipId = self.chipId,
			clientChipLevel = self.clientChipLevel,
			clientChipLevelExp = self.clientChipLevelExp,
			changeCb = self:createHandler("onItemChange", list, node, v),
			cb = self:createHandler("resetSelected"),
		})
		t.key = v.key
		self.selectItem:set(t)
	else
		local grayState = 0
		if self.itemTouchShow then
			gGameUI:stackUI('city.card.chip.details', nil, {dispatchNodes = self.strengthenPanel, clickClose = true}, {
				dbId = v.dbId,
				pos = pos,
				align = align,
				showExp = v.exp,
				dataRefresh = function()
					self.isRefreshBagPanel:notify()
				end,
				cb = self:createHandler("resetSelected"),
			})
			t.dbId = v.dbId
			self.selectItem:set(t)
		elseif self.costChips[v.dbId] then
			self.costChips[v.dbId] = nil
			self.clientChipAddExp:modify(function(exp)
				return true, exp - v.exp
			end)
			-- 取消若是最后一个品质的，取消勾选状态
			local quickSelected = self.quickSelectData:atproxy(v.cfg.quality - 1)
			if quickSelected and quickSelected.selected then
				local flag = false
				for _, strengthenData in self.strengthenData:ipairs() do
					local data = strengthenData:proxy()
					if data.type ~= "item" then
						if self.costChips[data.dbId] and data.cfg.quality == v.cfg.quality then
							flag = true
							break
						end
					end
				end
				if not flag then
					quickSelected.selected = false
				end
			end
		else
			if self.clientChipLeftAddExp <= 0 then
				gGameUI:showTip(gLanguageCsv.chipExpMax)
			else
				self:showPlanTip(v.dbId)

				self.costChips[v.dbId] = true
				self.clientChipAddExp:modify(function(exp)
					return true, exp + v.exp
				end)
			end
		end
		node:get("tick"):visible(self.costChips[v.dbId] ~= nil)
		bind.extend(list, node, {
			class = 'icon_key',
			props = {
				noListener = true,
				data = {
					key = v.key,
					num = v.num,
					targetNum = v.num and 0 or nil,
				},
				grayState = self.costChips[v.dbId] ~= nil and 1 or 0,
				specialKey = {
					leftTopLv = v.level,
					locked = v.locked,
				},
			},
		})
	end
end

function ChipAdvanceView:onItemTouch(list, node, t, v, event)
	if event.name == "began" then
		self.touchBeganPos = event
		self.isClicked = true
		self.itemTouchShow = false
		if self.sequence then
			self:stopAction(self.sequence)
		end
		self.strengthenList:setTouchEnabled(true)
		self.sequence = cc.Sequence:create(cc.DelayTime:create(0.3), cc.CallFunc:create(function()
			if v.type ~= "item" then
				self.itemTouchShow = true
				self:onItemTouchShow(list, node, t, v)
				self.strengthenList:setTouchEnabled(false)
			end
			self.sequence = nil
		end))
		self:runAction(self.sequence)

	elseif event.name == "moved" then
		if self.isClicked then
			local deltaX = math.abs(event.x - self.touchBeganPos.x)
			local deltaY = math.abs(event.y - self.touchBeganPos.y)
			if deltaX >= ui.TOUCH_MOVED_THRESHOLD or deltaY >= ui.TOUCH_MOVED_THRESHOLD then
				self.isClicked = false
				if self.sequence then
					self:stopAction(self.sequence)
					self.sequence = nil
				end
			end
		end

	elseif event.name == 'ended' or event.name == 'cancelled' then
		if self.sequence then
			self:stopAction(self.sequence)
			self.sequence = nil
		end
		if self.isClicked and not self.itemTouchShow then
			if v.locked then
				gGameUI:showTip(gLanguageCsv.chipStrengthenLocked)
			else
				self:onItemTouchShow(list, node, t, v)
			end
		end
	end
end

function ChipAdvanceView:resetSelected()
	self.selectItem:set({})
end

function ChipAdvanceView:onStrengthenClick()
	if self.strengthenCostGold > self.gold:read() then
		gGameUI:showTip(gLanguageCsv.goldNotEnough)
		return
	end
	local costCsvIDs = {}
	for k, v in pairs(self.costCsvIDs) do
		if v > 0 then
			costCsvIDs[k] = v
		end
	end
	local haveHigh = false
	local costChips = {}

	local exp = 0
	for dbId, _ in pairs(self.costChips) do
		table.insert(costChips, dbId)
		local chip = gGameModel.chips:find(dbId)
		local chipDatas = chip:read("chip_id",  "sum_exp")
		exp = exp +  chipDatas.sum_exp

		if not haveHigh  then
			local cfg = csv.chip.chips[chipDatas.chip_id]
			if cfg.quality >= 4 or chipDatas.sum_exp > 0 then
				haveHigh = true
			end
		end
	end
	local str = gLanguageCsv.strengthenSuccess
	if exp > 0 then
		str = str .. string.format(gLanguageCsv.chipStrengthComeBack, exp*gCommonConfigCsv.chipExpNeedGold)
	end
	local function cb()
		self.isStrengthenClick = true
		gGameApp:requestServer("/game/card/chip/strength", function()
			self:setEffect()
			gGameUI:showTip(str)
			self.isStrengthenClick = false
			for _, v in self.quickSelectData:ipairs() do
				v:proxy().selected = false
			end
		end, self.dbId, costChips, costCsvIDs)
	end

	if haveHigh then
		gGameUI:showDialog({title = gLanguageCsv.spaceTips, content = gLanguageCsv.chipStrengthenTip, isRich = true, btnType = 2, cb = cb})
	else
		cb()
	end

end

function ChipAdvanceView:setAdvanceData()
	local list = self.advancePanel:get("attrList")
	list:setScrollBarEnabled(false)

	local originBtnAdvanceX = self.btnAdvance:x()
	self.advanceFirstAttrsData = {}
	self.advanceSecondAttrsData = {}
	self.curSecondAttrSelect = idlertable.new({})
	-- self.refreshSecondAttrSelect = true
	local refreshTimes = 0
	self.isFirstAdvance = true
	idlereasy.any({self.chipLevel, self.chipNow, self.gold}, function()
		refreshTimes = refreshTimes + 1
		-- 减少一帧内多次调用
		performWithDelay(self, function()
			if refreshTimes > 0 then
				refreshTimes = 0
				-- 洗练次数为每条副属性洗练中最大值
				self.advanceCount = 0
				local advanceMax = 0
				-- 延迟执行一次的不能用监听旧值，用最新数据
				local chipNow = self.chipNow:read()
				for _, v in pairs(chipNow) do
					if v[2] > 0 then
						self.advanceCount = self.advanceCount + 1
					end
					advanceMax = math.max(advanceMax, v[2])
				end
				local firstAttrs, secondAttrs = ChipTools.getAttr(self.dbId, nil, true)
				-- 保存当前副属性选择的条目，最多只能选2条
				-- if self.refreshSecondAttrSelect then
				-- 	self.refreshSecondAttrSelect = false

				local idx = 0
				for i, data in ipairs(firstAttrs) do
					local key = data.key
					if not ChipTools.ignoreAttr(key) then
						idx = idx + 1
						self:setAdvanceAttrItem(1, idx, data)
					end
				end
				if self.isFirstAdvance then
					self.isFirstAdvance = false
					local lineItem = self.advancePanel:get("lineItem"):clone():show()
					list:pushBackCustomItem(lineItem)
					bind.touch(self, lineItem:get("detail"), {methods = {ended = function()
						self.subAttrDetailPanel:show()
					end}})
				end
				for idx = 1, 4 do
					local data = secondAttrs[idx]
					if not data then
						self:setAdvanceAttrItem(2, idx, nil)

					else
						local key = data.key
						if not ChipTools.ignoreAttr(key) then
							self:setAdvanceAttrItem(2, idx, data)
						end
					end
				end
				-- 洗练消耗
				local childs = self.costPanel:multiget("note", "cost1", "icon1", "cost2", "icon2")
				local cfg = csv.chip.recast_cost[math.min(advanceMax + 1, csvSize(csv.chip.recast_cost))]
				local cost = cfg["costItemMap" .. self.chipCfg.recastCostSeq]
				self.advanceCost = cost
				local idx = 0
				local space = {}
				local sign = true
				for k, v in csvMapPairs(cost) do
					idx = idx + 1
					if idx <= 2 then
						childs["cost" .. idx]:text(v):show()
						childs["icon" .. idx]:texture(dataEasy.getIconResByKey(k)):show()
						local isEnough = dataEasy.getNumByKey(k) >= v
						sign = sign and isEnough
						text.addEffect(childs["cost" .. idx], {color = isEnough and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.RED})
						table.insert(space, cc.p(15, 0))
						table.insert(space, cc.p(0, 0))
					end
				end

				for i = idx+1, 2 do
					childs["cost" .. i]:hide()
					childs["icon" .. i]:hide()
				end

				adapt.oneLineCenterPos(cc.p(self.costPanel:width()/2, self.costPanel:height()/2), {childs.note, childs.cost1, childs.icon1, childs.cost2, childs.icon2}, space)
				if advanceMax == 0 or not dataEasy.isUnlock("chipAdvanceReset") or not self.sign then
					local x = (self.btnReset:x() + originBtnAdvanceX) / 2
					self.costPanel:x(x)
					self.btnAdvance:x(x)
					self.advanceTip:x(x)
					self.resetCostPanel:hide()
					self.btnReset:hide()
				else
					self.costPanel:x(originBtnAdvanceX)
					self.btnAdvance:x(originBtnAdvanceX)
					self.resetCostPanel:show()
					self.btnReset:show()
					local childs = self.resetCostPanel:multiget("note", "cost1", "icon1")
					childs.cost1:text(gCommonConfigCsv.chipResetCost)
					childs.icon1:texture(dataEasy.getIconResByKey("rmb"))
					adapt.oneLineCenterPos(cc.p(self.resetCostPanel:width()/2, self.resetCostPanel:height()/2), {childs.note, childs.cost1, childs.icon1}, {cc.p(15, 0), cc.p(0, 0)})
				end
				self.isAdvanceClick = false
			end
		end, 0)
	end)
end


-- @param attrType 1: firstAttr 2:secondAttr
-- @param params {key, val, now}
function ChipAdvanceView:setAdvanceAttrItem(attrType, idx, params)
	local list = self.advancePanel:get("attrList")
	local data = attrType == 1 and self.advanceFirstAttrsData or self.advanceSecondAttrsData
	local item

	if params == nil then
		if data[idx] then
			data[idx].item:hide()
		end
		return
	end

	if data[idx] then
		item = data[idx].item
		item:show()
		params.isNew = false
		local selectIdx = self.curSecondAttrSelect:read()
		if attrType == 2 and self.isAdvanceClick and selectIdx[idx] then
			params.isNew = true
			local effect = item:get("effect")
			if not effect then
				effect = widget.addAnimationByKey(item, "effect/shuzisaoguang.skel", "effect", "effect", 100)
					:xy(100, 40)
					:scale(2, 0.5)
			end
			effect:play("effect")
		end
	else
		item = self.advancePanel:get("attrItem"):clone():show()
		list:pushBackCustomItem(item)
	end
	local val = "+" .. params.val
	params.item = item
	data[idx] = params
	local key = params.key
	local name = ChipTools.getAttrName(key)
	item:get("name"):text(name)
	item:get("val"):text(val)
	item:get("iconNew"):visible(params.isNew or false)
	adapt.oneLinePos(item:get("val"), item:get("iconNew"), cc.p(10, 0))
	item:get("checkBox"):hide()
	item:get("selected"):hide()
	if params.now then
		item:get("selected"):visible((params.now[2] > 0))

		bind.click(self, item:get("checkBox"), {method = function()
			local selected = self.curSecondAttrSelect:read()
			local count = 0
			for _, flag in pairs(selected) do
				if flag then
					count = count + 1
				end
			end
			if not selected[idx] and count >= 2 then
				gGameUI:showTip(gLanguageCsv.chipAdvanceSelectedMax)
			else
				self.curSecondAttrSelect:modify(function(selected)
					selected[idx] = not selected[idx]
					return true, selected
				end)
			end
		end})

		idlereasy.when(self.curSecondAttrSelect, function(_, selected)
			if self.advanceCount >= 2 then
				if params.now[2] > 0 then
					item:get("checkBox"):show()
					item:get("checkBox.icon"):setSelectedState(selected[idx] or false)
				end
			else
				item:get("checkBox"):show()
				item:get("checkBox.icon"):setSelectedState(selected[idx] or false)
			end
			if not self.sign then
				item:get("checkBox"):hide()
			end
		end):anonyOnly(self, idx)
	end
end

function ChipAdvanceView:onResetClick()
	if gCommonConfigCsv.chipResetCost > self.rmb:read() then
		gGameUI:showTip(gLanguageCsv.rmbNotEnough)
		return
	end
	gGameUI:stackUI("city.card.chip.advance_reset", nil, nil, {
		dbId = self.dbId,
		cb = function()
			gGameApp:requestServer("/game/card/chip/recast/reset", function()
				self.curSecondAttrSelect:set({})
				gGameUI:showTip(gLanguageCsv.resetSuccess)
			end, self.dbId)
		end,
	})
end

function ChipAdvanceView:initSubAttrDetailPanel()
	self.subAttrDetailPanel:hide()
	bind.click(self, self.subAttrDetailPanel, {method = function()
		self.subAttrDetailPanel:hide()
	end})
	local panel = self.subAttrDetailPanel:get("panel")
	local childs = panel:multiget("list", "bg")
	childs.list:setScrollBarEnabled(false)

	local count = 1
	local strs = {{str = "#C0x5b545b##L10#" .. gLanguageCsv.chipSubAttrRandom}}
	table.insert(strs, {str = "#C0xF13B54##L10#" .. gLanguageCsv.chipAdvanceTip})
	for _, v in orderCsvPairs(csv.chip.libs) do
		if v.randomLibID == self.chipCfg.acquiredLib then
			count = count + 1
			local key = v.attrType1
			local minCount  = dataEasy.getAttrValueString(v.attrType1, v.attrNum1[1])
			local maxCount = dataEasy.getAttrValueString(v.attrType1, v.attrNum1[table.nums(v.attrNum1)])
			table.insert(strs, {str = "#C0x5b545b#" .. v.attrsDesc .. "(".."#C0x5C9970#"..minCount.."~"..maxCount.."#C0x5b545b#)"})
		end
	end

	local length = count*65
	local size = childs.list:size()
	childs.list:size(cc.size(size.width, length+100))
	childs.list:y(childs.list:y() + size.height - (length + 90))

	beauty.textScroll({
		list = childs.list,
		strs = strs,
		margin = 20,
		isRich = true,
	})

	childs.bg:size(cc.size(childs.bg:size().width, length+140))
end

function ChipAdvanceView:onAdvanceClick()
	local pos1, pos2
	for idx, v in pairs(self.curSecondAttrSelect:read()) do
		if v == true then
			if not pos1 then
				pos1 = idx
			elseif not pos2 then
				pos2 = idx
			end
		end
	end
	if not pos1 then
		gGameUI:showTip(gLanguageCsv.chipAdvanceSelectFirst)
		return
	end

	for k, v in csvMapPairs(self.advanceCost) do
		local num = dataEasy.getNumByKey(k)
		if v > num then
			local cfg = dataEasy.getCfgByKey(k)
			gGameUI:showTip(string.format(gLanguageCsv.chipCoinNotEnough, cfg.name))
			return
		end
	end

	self.isAdvanceClick = true
	gGameApp:requestServer("/game/card/chip/recast", function()
		self:setEffect()
		-- gGameUI:showTip(gLanguageCsv.nvalueCuccess)
	end, self.dbId, pos1, pos2)
end

function ChipAdvanceView:setEffect()
	local itemIcon = self.leftPanel:get("itemIcon")
	local effect = itemIcon:get("effect")
	if not effect then
		effect = widget.addAnimation(itemIcon, "koudai_gonghuixunlian/gonghuixunlian.skel", "fangguang2", 10)
			:name("effect")
			:alignCenter(itemIcon:size())
			:y(100)
		effect:setSpriteEventHandler(function(event, eventArgs)
			effect:hide()
		end, sp.EventType.ANIMATION_COMPLETE)
	else
		effect:show():play("fangguang2")
	end
end

function ChipAdvanceView:showPlanTip(dbids)
	local isPlan = ChipTools.isChipPlan(dbids)
	if isPlan then
		gGameUI:showTip(gLanguageCsv.planHasExist)
	end
end
function ChipAdvanceView:onQuickSelectClick(list, k, v)
	local quality = v.quality
	local selected = not self.quickSelectData:atproxy(k).selected
	self.quickSelectData:atproxy(k).selected = selected

	local addExp = 0
	local isMax = false
	local isHas = false
	local data = self:getStrengthData()
	local selectChips = {}
	table.sort(data, bagOrderCmp)
	for _, v in ipairs(data) do
		if v.type ~= "item" then
			local dbId = v.dbId
			local cfg = v.cfg
			local exp = v.exp
			if cfg.quality == quality then
				if selected then
					if not v.locked then
						isHas = true
					end
					if not isMax and not self.costChips[dbId] and not v.locked then
						if addExp >= self.clientChipLeftAddExp then
							isMax = true
						else
							self.costChips[dbId] = true
							table.insert(selectChips, dbId)
							addExp = addExp + exp
						end
					end
				else
					if self.costChips[dbId] then
						self.costChips[dbId] = nil
						addExp = addExp - exp
					end
				end
			end
			v.selected = self.costChips[dbId]
		end
	end

	self.clientChipAddExp:modify(function(val)
		return true, val + addExp
	end, true)
	if selected and not isHas then
		self.quickSelectData:atproxy(k).selected = false
		gGameUI:showTip(gLanguageCsv.chipQuickSelectTip)

	elseif isMax then
		gGameUI:showTip(gLanguageCsv.chipExpMax)
	end

	self:showPlanTip(selectChips)

	dataEasy.tryCallFunc(self.strengthenList, "updatePreloadCenterIndexAdaptFirst")
	self.strengthenData:update(data)
end

function ChipAdvanceView:onBtnRebirth()
	gGameUI:stackUI("city.card.rebirth.view", nil,  {full = true}, 5)
end


function ChipAdvanceView:onShowRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1181, height = 1038})
end

local function getStrByTable(list)
	local str = ""
	for i, num in ipairs(list) do
		str = str..num
		if list[i+1] then
			str = str..","
		end
	end
	-- str = str ..")"
	return str
end

function ChipAdvanceView:getRuleContext(view)

	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.chipAdvanceRule)
		end),
		c.noteText(124701, 124705),
	}
	local infoList = {}
	table.insert(infoList, {key = csv.note[124706].fmt, main = csv.note[124707].fmt,sec = csv.note[124708].fmt, sign =  true})

	local chipsData = {}
	for _, v in csvPairs(csv.chip.chips) do
		chipsData[v.quality] = v
	end

	for quality, v in pairs(chipsData) do
		local key = ui.QUALITYCOLOR[quality]..gLanguageCsv[ui.QUALITY_COLOR_SINGLE_TEXT[quality]]
		local main = getStrByTable(v.acquiredLevels)
		local sec = getStrByTable(v.strengthLevels)
		table.insert(infoList, {key = key, main = main, sec = sec, sign =  false})
	end
	for index = 1, 6  do
		table.insert(context, c.clone(self.panelRule, function(item)
			local childs = item:multiget("txtKey", "txtMain", "txtSec", "img")
			local data = infoList[index]
			childs.txtKey:hide()

			local richText = rich.createWithWidth(data.key, 40, nil, 1000, nil, cc.p(0.5, 0))
				:anchorPoint(0, 0.5)
				:xy(childs.txtKey:xy())
				:addTo(item)

			childs.txtMain:text(data.main)
			childs.txtSec:text(data.sec)

			childs.img:visible(data.sign)
		end))
	end
	return context
end

return ChipAdvanceView