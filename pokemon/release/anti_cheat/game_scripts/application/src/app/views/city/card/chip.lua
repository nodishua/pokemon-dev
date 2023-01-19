-- @date 2021-5-7
-- @desc 学习芯片

local ChipTools = require('app.views.city.card.chip.tools')

local CardChipView = class("CardChipView", cc.load("mvc").ViewBase)

CardChipView.RESOURCE_FILENAME = "card_chip.json"
CardChipView.RESOURCE_BINDING = {
	["panel.btnDraw"] = {
		varname = "btnDraw",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onDrawClick")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "cityChipFreeExtract",
					onNode = function(node)
						node:xy(200, 200)
					end,
				},
			},
		}
	},
	["panel.btnDraw.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},
	["panel.btnOnekeyDown"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onOnekeyDownClick")}
		}
	},
	["panel.btnOnekeyDown.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},
	["panel.btnPlan"] = {
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onPlanClick")}
			}, {
				event = "visible",
				idler = bindHelper.self("chipPlanListen")
			},
		}
	},
	["panel.btnPlan.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},

	["panel.btnRule"] = {
		binds = {

			event = "touch",
			methods = {ended = bindHelper.self("onShowRule")}
		}
	},

	["panel.btnRule.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},

	["panel.btnPlanCompare"] = {
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onPlanCompareClick")}
			}, {
				event = "visible",
				idler = bindHelper.self("chipPlanCompareListen")
			},
		}
	},
	["panel.btnPlanCompare.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},
	["panel.chipPanel"] = {
		varname = "chipPanel",
		binds = {
			event = "extend",
			class = "chips_panel",
			props = {
				data = bindHelper.self("selectCardDBID"),
				showDetails = bindHelper.self("showDetails", true),
				selected = bindHelper.self("selectPos"),
				onItem = function(panel, item, k, dbId)
					bind.click(panel, item, {method = function()
						if dbId then
							panel.showDetails(item, k, dbId)
						else
							panel.chipsBagClick(k)
						end
					end})
				end,
				onNode = function(panel, node)
					node:scale(0.9)
				end,
			},
			handlers = {
				chipsBagClick = bindHelper.self('onChipsBagClick')
			}
		}
	},
	["panel.chipPanel.btnChips"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChipsBagClick")}
		}
	},
	["panel.baseAttrPanel.btnDetail"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBaseAttrDetailClick")}
		}
	},
	["panel.suitAttrPanel.btnDetail"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSuitAttrDetailClick")}
		}
	},
	["panel.baseAttrPanel.tip"] = "baseAttrTip",
	["panel.baseAttrPanel.item"] = "baseAttrItem",
	["panel.baseAttrPanel.subList"] = "baseAttrSubList",
	["panel.baseAttrPanel.list"] = {
		binds = {
			event = 'extend',
			class = 'tableview',
			props = {
				columnSize = 2,
				data = bindHelper.self('baseAttrData'),
				item = bindHelper.self('baseAttrSubList'),
				cell = bindHelper.self('baseAttrItem'),
				onCell = function(list, node, k, v)
					node:get("icon"):texture(ui.ATTR_LOGO[v.attr])
					node:get("text"):text(getLanguageAttr(v.key) .. " +" .. v.val)
				end
			},
		}
	},
	["panel.suitAttrPanel.tip"] = "suitAttrTip",
	["panel.suitAttrPanel.item"] = "suitAttrItem",
	["panel.suitAttrPanel.list"] = {
		binds = {
			event = 'extend',
			class = 'listview',
			props = {
				data = bindHelper.self('suitAttrData'),
				item = bindHelper.self('suitAttrItem'),
				onItem = function(list, node, k, v)
					node:get("icon"):texture(ChipTools.getSuitRes(v.suitId, v.data))
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, node, k, v)}})
				end
			},
			handlers = {
				clickCell = bindHelper.self('onSuitAttrItemClick')
			}
		}
	},
	["suitAttrDetailPanel"] = "suitAttrDetailPanel",
}

function CardChipView:onCreate(dbHandler)
	self.selectCardDBID = dbHandler()
	self.chipPlanListen = dataEasy.getListenUnlock(gUnlockCsv.chipPlan)
	self.chipPlanCompareListen = dataEasy.getListenUnlock(gUnlockCsv.chipPlanCompare)
	self.suitAttrDetailPanel:hide()
	bind.click(self, self.suitAttrDetailPanel, {method = function()
		self.suitAttrDetailPanel:hide()
	end})

	self.baseAttrData = idlereasy.new({})
	self.suitAttrData = idlereasy.new({})
	self.selectPos = idler.new()
	idlereasy.when(self.selectCardDBID, function (_, selectCardDBID)
		local card = gGameModel.cards:find(selectCardDBID)
		self.cardChips = idlereasy.assign(card:getIdler("chip"), self.cardChips)
		self:showPanel()
	end)

	self.cardChipsIdler_ = {}
	idlereasy.when(self.cardChips, function(_, cardChips)
		for _, v in pairs(self.cardChipsIdler_) do
			v:destroy()
		end
		self.cardChipsIdler_ = {}
		for i = 1, 6 do
			local dbId = cardChips[i]
			if dbId then
				local chip = gGameModel.chips:find(dbId)
				-- 等级和副属性变动影响属性
				local chipDatas = chip:multigetIdler("level", "now")
				self.cardChipsIdler_[dbId] = idlereasy.any(chipDatas, function()
					self:showPanel()
				end, true):anonyOnly(self, stringz.bintohex(dbId))
			end
		end
		self:showPanel()
	end)

	widget.addAnimationByKey(self.btnDraw, 'chip/icon.skel', "icon", "effect_loop", 2)
		:alignCenter(self.btnDraw:size()):scale(0.9)
end

function CardChipView:showPanel()
	local selectCardDBID = self.selectCardDBID:read()
	-- 基础属性
	local firstAttrs, secondAttrs = ChipTools.getAttrs(selectCardDBID)

	-- 属性值汇总
	ChipTools.setAttrCollect(firstAttrs, secondAttrs)

	local attrs = {}
	for _, attr in ipairs(game.ATTRDEF_SIMPLE_TABLE) do
		local key = game.ATTRDEF_ENUM_TABLE[attr]
		if firstAttrs[1][key] then
			table.insert(attrs, {attr = attr, key = key, val = firstAttrs[1][key]})
		end
	end
	self.baseAttrData:set(attrs)
	self.baseAttrTip:visible(#attrs == 0)
	-- 套装属性
	local suitAttrData = {}
	local suitAttrs = ChipTools.getComplateSuitAttrByCard(selectCardDBID)
	for _, val in pairs(suitAttrs) do
		-- 最大激活的套件数
		local maxActiveNum = 0
		for _, v in ipairs(val.data) do
			if v[3] then
				maxActiveNum = math.max(maxActiveNum, v[1])
			end
		end
		if maxActiveNum > 0 then
			table.insert(suitAttrData, {suitId = val.suitId, maxActiveNum = maxActiveNum, data = val.data})
		end
	end
	self.suitAttrData:set(suitAttrData)
	self.suitAttrTip:visible(#suitAttrData == 0)
end

function CardChipView:onDrawClick()
	gGameUI:stackUI('city.card.chip.draw')
end

-- 一键卸下
function CardChipView:onOnekeyDownClick()
	local selectCardDBID = self.selectCardDBID:read()
	local card = gGameModel.cards:find(selectCardDBID)
	local cardChips = card:read("chip")
	if itertools.size(cardChips) == 0 then
		return
	end

	local function cb()
		local chips = {-1, -1, -1, -1, -1, -1}
		gGameApp:requestServer("/game/card/chip/change", function(tb)
			gGameUI:showTip(gLanguageCsv.dischargeSuccess)
		end, selectCardDBID, chips)
	end
	local key = "chipOnekeyDownTip"
	local state = userDefault.getCurrDayKey(key, "first")
	if state == "first" then
		state = "true"
		userDefault.setCurrDayKey(key, state)
	end
	if state == "first" or state == "true" then
		gGameUI:showDialog({content = "#C0x5B545B#" .. gLanguageCsv.chipOnekeyDownTip, cb = cb, isRich = true, btnType = 2, selectKey = key, selectType = 2, selectTip = gLanguageCsv.todayNoTip})
	else
		cb()
	end
end

-- 芯片方案
function CardChipView:onPlanClick()
	gGameUI:stackUI('city.card.chip.plan', nil, nil, {curCardDBID = self.selectCardDBID:read()})
end

-- TODO 方案对比
function CardChipView:onPlanCompareClick()
end

-- 芯片库
function CardChipView:onChipsBagClick(panel, idx)
	local function cb()
		gGameUI:stackUI('city.card.chip.bag', nil, {full = true}, {curCardDBID = self.selectCardDBID:read()})
	end
	if idx then
		self.selectPos:set(idx)
		performWithDelay(self, function()
			cb()
			self.selectPos:set(nil)
		end, 0.01)
	else
		cb()
	end
end

function CardChipView:showDetails(panel, item, slotIdx, dbId)
	local pos = item:convertToWorldSpaceAR(cc.p(0, 0))
	local align = "right"
	if slotIdx >= 1 and slotIdx <= 3 then
		align = "left"
	end
	self.selectPos:set(slotIdx)
	gGameUI:stackUI('city.card.chip.details', nil, {dispatchNodes = self.chipPanel, clickClose = true}, {
		dbId = dbId,
		cardDBID = self.selectCardDBID:read(),
		pos = pos,
		align = align,
		cb = self:createHandler("resetSelected"),
	})
end

-- 重置选择
function CardChipView:resetSelected()
	self.selectPos:set()
end

-- 基础属性详情
function CardChipView:onBaseAttrDetailClick()
	gGameUI:stackUI('city.card.chip.total_detail', nil, nil, {typ = 1, cardPlan = self.selectCardDBID:read()})
end

-- 套装属性详情
function CardChipView:onSuitAttrDetailClick()
	gGameUI:stackUI('city.card.chip.suit_detail', nil, nil, self.selectCardDBID:read())
end

function CardChipView:onSuitAttrItemClick(list, node, k, v)
	local panel = self.suitAttrDetailPanel:get("panel")
	local childs = panel:multiget("icon", "name", "count", "list")
	local suitCfg = gChipSuitCsv[v.suitId][2][2]
	childs.icon:texture(ChipTools.getSuitRes(v.suitId, v.data))
	childs.name:text(suitCfg.suitName)
	local count = 0
	local roleChips = gGameModel.role:read('chips')
	for _, dbId in ipairs(roleChips) do
		local chip = gGameModel.chips:find(dbId)
		local chipId = chip:read("chip_id")
		local chipCfg = csv.chip.chips[chipId]
		if v.suitId == chipCfg.suitID then
			count = count + 1
		end
	end
	childs.count:text(gLanguageCsv.currentOwn .. count):hide()
	local strs = {}
	for _, data in ipairs(v.data) do
		local str = ChipTools.getSuitAttrStr(v.suitId, data)
		table.insert(strs, {str = str})
	end
	beauty.textScroll({
		list = childs.list,
		strs = strs,
		margin = 10,
		isRich = true,
	})

	local pos = node:convertToWorldSpaceAR(cc.p(0, 0))
	local pos = self.suitAttrDetailPanel:convertToNodeSpace(pos)
	panel:x(pos.x - panel:width()/2)
	self.suitAttrDetailPanel:show()
end

function CardChipView:onShowRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 2200, height = 1113})
end

function CardChipView:getRuleContext(view)

	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.chipRule)
		end),
		c.noteText(124601, 124605),
	}
	local infoList = {}
	table.insert(infoList, {key = csv.note[124606].fmt, main = csv.note[124607].fmt,sec = csv.note[124608].fmt, sign =  true})

	local count = 124609
	for index = 1, 6 do
		table.insert(infoList, {key = index, main = csv.note[count + 2*index-2].fmt, sec = csv.note[count + 2*index-1].fmt, sign =  false})
	end
	for index = 1, 7  do
		table.insert(context, c.clone(view.panelChip, function(item)
			local childs = item:multiget("txtLocation", "imgLocation", "txtMain", "txtSec","img01", "img02")
			local data = infoList[index]
			if data.sign then
				childs.txtLocation:x(40)
				childs.txtSec:x(1000)
				childs.imgLocation:hide()
			else
				childs.imgLocation:show()
				childs.imgLocation:rotate(60 * (data.key-1))
			end
			childs.txtLocation:text(data.key)
			childs.txtMain:text(data.main)
			childs.txtSec:text(data.sec)

			childs.img01:visible(data.sign)
			childs.img02:visible(data.sign)
		end))
	end
	return context
end

return CardChipView
