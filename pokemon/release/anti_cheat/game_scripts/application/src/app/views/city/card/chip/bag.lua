-- @date 2021-5-8
-- @desc 学习芯片背包库

local ViewBase = cc.load("mvc").ViewBase
local ChipBagView = class("ChipBagView", ViewBase)
local ChipTools = require('app.views.city.card.chip.tools')
local ATTR_FILTER_TYPE = {
	"hp", "speed", "mp1Recover", "damage", "defence", "defenceIgnore",
	"strike", "strikeDamage", "strikeResistance", "cure", "rebound", "suckBlood",
	"block", "breakBlock", "blockPower", "controlPer", "immuneControl", "damageAdd",
	"damageSub", "ultimateAdd", "ultimateSub",
}
ChipBagView.ATTR_FILTER_TYPE = ATTR_FILTER_TYPE

ChipBagView.RESOURCE_FILENAME = "chip_bag.json"
ChipBagView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["left"] = "left",
	["right"] = "right",
	["left.btnSuitEffect"] = {
		varname = "btnSuitEffect",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSuitEffectClick")}
		}
	},
	["left.btnSuitEffect.txt"] = {
		binds = {
			event = "effect",
			data = {color=ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["left.btnSuitFilter"] = {
		varname = "btnSuitFilter",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSuitFilterClick")}
		}
	},
	["left.btnAttrFilter"] = {
		varname = "btnAttrFilter",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAttrFilterClick")}
		}
	},
	["left.empty"] = "empty",
	["left.posItem"] = "posItem",
	["left.posList"] = {
		varname = 'posList',
		binds = {
			event = 'extend',
			class = 'listview',
			props = {
				data = bindHelper.self('posData'),
				item = bindHelper.self('posItem'),
				onItem = function(list, node, k, v)
					node:get('bg'):texture(v.select and 'city/card/gem/btn_yq_h.png' or 'city/card/gem/btn_yq_b.png')
					if not v.pos then
						text.addEffect(node:get("txt"), {color = v.select and ui.COLORS.NORMAL.WHITE or ui.COLORS.NORMAL.RED})
						node:get("txt"):show()
						node:get("icon"):hide()
					else
						node:get("txt"):hide()
						node:get('icon'):show():texture(v.select and 'city/card/chip/icon_fx_2.png' or 'city/card/chip/icon_fx_1.png')
							:rotate(60 * (v.pos-1))
					end
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end
			},
			handlers = {
				clickCell = bindHelper.self('onPosClick')
			}
		}
	},
	["left.item"] = "bagItem",
	["left.subList"] = "bagSubList",
	['left.list'] = {
		varname = 'bagList',
		binds = {
			event = 'extend',
			class = 'tableview',
			props = {
				asyncPreload = bindHelper.self('asyncPreload'),
				columnSize = bindHelper.self('midColumnSize'),
				data = bindHelper.self('bagData'),
				item = bindHelper.self('bagSubList'),
				cell = bindHelper.self('bagItem'),
				-- 品质、套装id升序、对应栏位号升序、强化等级降序
				dataOrderCmp = function(a, b)
					if a.cfg.quality ~= b.cfg.quality then
						return a.cfg.quality > b.cfg.quality
					end
					if a.cfg.suitID ~= b.cfg.suitID then
						return a.cfg.suitID < b.cfg.suitID
					end
					if a.cfg.pos ~= b.cfg.pos then
						return a.cfg.pos < b.cfg.pos
					end
					if a.level ~= b.level then
						return a.level > b.level
					end
					return a.idx < b.idx
				end,
				onCell = function(list, node, k, v)
					bind.extend(list, node, {
						class = 'icon_key',
						props = {
							noListener = true,
							data = {
								key = v.chipId,
								dbId = v.dbId,
							},
							specialKey = {
								leftTopLv = v.level,
								locked = v.locked,
								unitId = v.equipShow and v.unitId or nil,
							},
							grayState = v.grayState or 0,
							onNode = function(panel)
								local t = list:getIdx(k)
								local selectItem = list.selectItem()
								local selectEffect = list.selectEffect()
								idlereasy.when(selectItem, function(_, selectItem)
									if selectItem.dbId == nil and selectEffect:parent() then
										selectEffect:removeSelf()
									end
									if selectItem.dbId == v.dbId then
										selectEffect:removeSelf()
										selectEffect:alignCenter(panel:size())
										panel:add(selectEffect, -1)
									end
								end):anonyOnly(list, v.dbId)
								panel:scale(1.15)
								panel:onTouch(functools.partial(list.itemTouch, panel, t, v))
							end
						},
					})
				end
			},
			handlers = {
				itemTouch = bindHelper.self('onItemTouch'),
				selectEffect = bindHelper.self('selectEffect'),
				selectItem = bindHelper.self('selectItem'),
			}
		}
	},
	["right.chipPanel"] = {
		varname = "chipPanel",
		binds = {
			event = "extend",
			class = "chips_panel",
			props = {
				data = bindHelper.self("selectCardDBID"),
				slotFlags = bindHelper.self("slotFlags"),
				selected = bindHelper.self("selectRightPos"),
				showSuitEffect = true,
			},
		}
	},
	["right.chipPanel.card"] = {
		varname = "cardPanel",
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('onShowSelectSpriteView')}
		}
	},
	["right.btnDraw"] = {
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
	["right.btnDraw.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},
	["right.btnOnekeyDown"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onOnekeyDownClick")}
		}
	},
	["right.btnRule.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},

	["right.btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowRule")}
		}
	},
	["right.btnOnekeyDown.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},
	["right.btnPlan"] = {
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
	["right.btnPlan.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},
	["right.btnPlanCompare"] = {
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
	["right.btnPlanCompare.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},
	["right.baseAttrPanel.btnDetail"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBaseAttrDetailClick")}
		}
	},
	["right.suitAttrPanel.btnDetail"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSuitAttrDetailClick")}
		}
	},
	["right.baseAttrPanel.tip"] = "baseAttrTip",
	["right.baseAttrPanel.item"] = "baseAttrItem",
	["right.baseAttrPanel.subList"] = "baseAttrSubList",
	["right.baseAttrPanel.list"] = {
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
	["right.suitAttrPanel.tip"] = "suitAttrTip",
	["right.suitAttrPanel.item"] = "suitAttrItem",
	["right.suitAttrPanel.list"] = {
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
	["suitFilterPanel"] = "suitFilterPanel",
	["suitFilterPanel.panel.item"] = "suitFilterItem",
	["suitFilterPanel.panel.subList"] = "suitFilterSubList",
	['suitFilterPanel.panel.list'] = {
		binds = {
			event = 'extend',
			class = 'tableview',
			props = {
				data = bindHelper.self('suitFilterData'),
				item = bindHelper.self('suitFilterSubList'),
				cell = bindHelper.self('suitFilterItem'),
				columnSize = 4,
				onCell = function(list, node, k, v)
					node:get("selected"):visible(v.selected == true)
					node:get("icon"):texture(v.cfg.suitIcon)
					node:get("name"):text(v.cfg.suitName)
					node:get("count"):text(v.count)
						:setFontSize(36)
					text.addEffect(node:get("count"), {color=ui.COLORS.NORMAL.WHITE, outline={color=ui.COLORS.OUTLINE.DEFAULT, size = 3}})
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, node, k, v)}})
				end
			},
			handlers = {
				itemClick = bindHelper.self('onSuitFilterItemClick'),
			}
		}
	},
	["suitFilterPanel.panel.btnAll"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSuitFilterAllClick")}
		}
	},
	["attrFilterPanel"] = "attrFilterPanel",
	["attrFilterPanel.panel.item"] = "attrFilterItem",
	["attrFilterPanel.panel.subList"] = "attrFilterSubList",
	['attrFilterPanel.panel.list'] = {
		binds = {
			event = 'extend',
			class = 'tableview',
			props = {
				data = bindHelper.self('attrFilterData'),
				item = bindHelper.self('attrFilterSubList'),
				cell = bindHelper.self('attrFilterItem'),
				columnSize = 3,
				onCell = function(list, node, k, v)
					adapt.setTextScaleWithWidth(node:get("name"), v.name, 240)
					if v.selected then
						node:get("icon"):texture("city/card/chip/btn_r.png")
						text.addEffect(node:get("name"), {color = ui.COLORS.NORMAL.WHITE})
					else
						node:get("icon"):texture("city/card/chip/btn_w.png")
						text.addEffect(node:get("name"), {color = ui.COLORS.NORMAL.RED})
					end
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, node, list:getIdx(k), v)}})
				end
			},
			handlers = {
				itemClick = bindHelper.self('onAttrFilterItemClick'),
			}
		}
	},
}

-- @params {curCardDBID, cb}
function ChipBagView:onCreate(params)
	params = params or {}
	self.cb = params.cb

	self.topuiView = gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.chipBag, subTitle = "CHIP BAG"})

	self:initModel()
	self.chipPlanListen = dataEasy.getListenUnlock(gUnlockCsv.chipPlan)
	self.chipPlanCompareListen = dataEasy.getListenUnlock(gUnlockCsv.chipPlanCompare)

	-- 适配
	adapt.dockWithScreen(self.left, "left")
	adapt.dockWithScreen(self.suitFilterPanel:get("panel"), "left")
	adapt.dockWithScreen(self.attrFilterPanel:get("panel"), "left")
	adapt.dockWithScreen(self.right, "right")
	local _, count = adapt.centerWithScreen("left", "right", {
		itemWidth = self.bagItem:width(),
		itemWidthExtra = params.itemWidthExtra or 80,
	},{
		{{self.bagSubList, self.bagList}, "width"},
		-- {{self.bagSubList, self.bagList, self.posList, self.btnSuitEffect}, "pos", 'left'},
		{{self.btnSuitFilter, self.suitFilterPanel:get("panel"), self.btnAttrFilter, self.attrFilterPanel:get("panel")}, "pos", function(left, right)
			return right - left
		end},
	})
	self.midColumnSize = 4 + (count or 0)
	self.asyncPreload = self.midColumnSize * 5
	local leftPos = cc.p(self.left:xy())
	self.left:x(leftPos.x - self.left:width() - 100)
	self.left:runAction(cc.MoveTo:create(0.4, leftPos))
	local rightPos = cc.p(self.right:xy())
	self.originRightPos = rightPos
	self.right:x(rightPos.x + self.right:width() + 100)
	self.right:runAction(cc.MoveTo:create(0.4, rightPos))
	self.posList:setItemsMargin(35)

	self.selectEffect = ccui.ImageView:create("common/box/box_selected.png")
		:alignCenter(self.bagItem:size())
		:retain()
	self.selectCardDBID = idler.new(params.curCardDBID)
	self.selectLeftPos = idler.new() -- nil.全部，1-6
	self.selectRightPos = idler.new()
	self.selectItem = idlereasy.new({})
	self.bagData = idlers.newWithMap({})
	self.posData = idlers.newWithMap({
		{select = true}, {pos = 1}, {pos = 2}, {pos = 3}, {pos = 4}, {pos = 5}, {pos = 6},
	})
	self.suitFilterData = idlers.newWithMap({})
	self.attrFilterData = idlers.newWithMap({})
	self.baseAttrData = idlereasy.new({})
	self.suitAttrData = idlereasy.new({})

	-- 精灵变更
	idlereasy.when(self.cards, function (_, cards)
		local cardDBID = self.selectCardDBID:read()
		local card = gGameModel.cards:find(cardDBID)
		if not card then
			-- 显示为上阵精灵中芯片多的
			local battleCards = gGameModel.role:read("battle_cards")
			local data = {}
			for _, dbId in pairs(battleCards) do
				local card = gGameModel.cards:find(dbId)
				local cardChips = card:read('chip')
				local num = 0
				for i = 1, 6 do
					if cardChips[i] then
						num = num + 1
					end
				end
				table.insert(data, {
					dbId = dbId,
					fight = card:read('fighting_point'),
					chipNum = num,
				})
				table.sort(data, function(a, b)
					if a.chipNum ~= b.chipNum then
						return a.chipNum > b.chipNum
					end
					return a.fight > b.fight
				end)
				cardDBID = data[1].dbId
			end
		end
		self:setCardDBID(cardDBID)
	end)
	idlereasy.when(self.selectCardDBID, function (_, selectCardDBID)
		local card = gGameModel.cards:find(selectCardDBID)
		self.cardChips = idlereasy.assign(card:getIdler("chip"), self.cardChips)
		self:showPanel()
	end)
	-- 右侧芯片刷新
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
	self.selectLeftPos:addListener(function(val, oldval)
		self.bagList:jumpToTop()
		self.selectItem:set({})
		local oldpos = oldval and oldval + 1 or 1
		self.posData:atproxy(oldpos).select = false
		local pos = val and val + 1 or 1
		self.posData:atproxy(pos).select = true
	end)

	-- 单个套装详情
	self.suitAttrDetailPanel:hide()
	bind.click(self, self.suitAttrDetailPanel, {method = function()
		self.suitAttrDetailPanel:hide()
	end})

	-- 套装类型筛选
	self.suitFilterPanel:hide()
	bind.click(self, self.suitFilterPanel, {method = function()
		self.suitFilterPanel:hide()
		self.btnSuitFilter:get("arrow"):setFlippedY(false)
	end})
	self.selectSuitId = idler.new()
	idlereasy.when(self.selectSuitId, function(_, selectSuitId)
		self.bagList:jumpToTop()
		self.suitFilterPanel:hide()
		self.btnSuitFilter:get("arrow"):setFlippedY(false)
		self.btnSuitFilter:get("txt"):text(selectSuitId and gChipSuitCsv[selectSuitId][2][2].suitName or gLanguageCsv.chipBagSuitFilter)
	end)

	-- 属性筛选， 多选
	self.attrFilterPanel:hide()
	self.selectAttrIds = idlereasy.new({}) -- {}:默认，{1=true,7=true}筛选包含选择属性的芯片
	bind.click(self, self.attrFilterPanel, {method = function()
		self.attrFilterPanel:hide()
		self.btnAttrFilter:get("arrow"):setFlippedY(false)
		local ids = {}
		for i, data in self.attrFilterData:ipairs() do
			if i ~= 1 and data:proxy().selected then
				ids[data:proxy().id] = true
			end
		end
		self.selectAttrIds:set(ids)
	end})
	idlereasy.when(self.selectAttrIds, function(_, selectAttrIds)
		self.bagList:jumpToTop()
		self.attrFilterPanel:hide()
		self.btnAttrFilter:get("arrow"):setFlippedY(false)
		local str = gLanguageCsv.chipBagAttrFilter
		if itertools.size(selectAttrIds) == 1 then
			local k = next(selectAttrIds)
			str = ChipTools.getAttrName(k)

		elseif itertools.size(selectAttrIds) > 1 then
			str = gLanguageCsv.chipBagAttrFilterMulti
		end
		adapt.setTextScaleWithWidth(self.btnAttrFilter:get("txt"), str, 200)
	end)

	-- 背包刷新
	local refreshTimes = 0
	self.isRefreshBagPanel = idler.new(true)
	idlereasy.any({self.roleChips, self.cardChips, self.selectLeftPos, self.selectSuitId, self.selectAttrIds, self.isRefreshBagPanel}, function()
		refreshTimes = refreshTimes + 1
		performWithDelay(self, function()
			if refreshTimes > 0 then
				refreshTimes = 0
				self:refreshLeftPanel()
			end
		end, 0)
	end)

	-- 抽卡按钮特效
	widget.addAnimationByKey(self.btnDraw, 'chip/icon.skel', "icon", "effect_loop", 2)
		:alignCenter(self.btnDraw:size()):scale(0.9)
end

function ChipBagView:initModel()
	self.cards = gGameModel.role:getIdler("cards")
	self.roleChips = gGameModel.role:getIdler('chips')
	self.slotFlags = idlereasy.new({})
end

function ChipBagView:onCleanup()
	self.selectEffect:release()
	ViewBase.onCleanup(self)
end

function ChipBagView:onClose()
	if self.cb then
		self:addCallbackOnExit(functools.partial(self.cb, self.selectCardDBID:read()))
	end
	ViewBase.onClose(self)
end

function ChipBagView:setCardDBID(dbId)
	if not dbId then
		return
	end
	local card = gGameModel.cards:find(dbId)
	local cardDatas = card:read("card_id", "skin_id", "level", "star", "advance")
	local cardCfg = csv.cards[cardDatas.card_id]
	local unitCfg = csv.unit[cardCfg.unitID]
	local unitId = dataEasy.getUnitId(cardDatas.card_id, cardDatas.skin_id)
	bind.extend(self, self.cardPanel, {
		class = "card_icon",
		props = {
			unitId = unitId,
			advance = cardDatas.advance,
			rarity = unitCfg.rarity,
			star = cardDatas.star,
			levelProps = {
				data = cardDatas.level,
			},
			onNode = function(panel)
				panel:alignCenter(self.cardPanel:size()):scale(1.3)
			end,
		}
	})

	self.selectCardDBID:set(dbId)
	-- bind.extend 延迟一帧创建
	performWithDelay(self, function()
		idlereasy.when(self.cardChips, function(_, cardChips)
			for i = 1, 6 do
				local item = self.chipPanel:getItem(i)
				item:setTouchEnabled(true)
				local dbId = cardChips[i]
				if dbId then
					local chip = gGameModel.chips:find(dbId)
					local chipData = chip:read("chip_id", "card_db_id", "level")
					local data = {
						dbId = dbId,
						chipId = chipData.chip_id,
						level = chipData.level,
						cfg = csv.chip.chips[chipData.chip_id],
					}
					item:onTouch(functools.partial(self.onCardChipClick, self, item, i, data))
				else
					item:onTouch(function(event)
						if event.name == 'ended' then
							self.selectLeftPos:set(i)
							self.selectRightPos:set(i)
						end
					end)
				end
			end
		end):anonyOnly(self)
	end, 0)
end

-- 套装效果
function ChipBagView:onSuitEffectClick()
	gGameUI:stackUI('city.card.chip.suit_preview')
end

-- 类型筛选
function ChipBagView:onSuitFilterClick(all)
	self.btnSuitFilter:get("arrow"):setFlippedY(true)
	local data = {}
	local counts = {}
	local roleChips = self.roleChips:read()
	for idx, dbId in ipairs(roleChips) do
		local chip = gGameModel.chips:find(dbId)
		local chipData = chip:read("chip_id", "card_db_id")
		-- 普通背包不显示已被装备的芯片，方案背包都显示
		if all == true or not chipData.card_db_id then
			local cfg = csv.chip.chips[chipData.chip_id]
			counts[cfg.suitID] = counts[cfg.suitID] or 0
			counts[cfg.suitID] = counts[cfg.suitID] + 1
		end
	end
	for suitId, _ in pairs(gChipSuitCsv) do
		table.insert(data, {
			suitId = suitId,
			count = counts[suitId] or 0,
			selected = self.selectSuitId:read() == suitId,
			cfg = gChipSuitCsv[suitId][2][2],
		})
	end
	table.sort(data, function(a, b)
		return a.suitId < b.suitId
	end)
	self.suitFilterData:update(data)
	self.suitFilterPanel:show()
end

-- 属性筛选 多选
function ChipBagView:onAttrFilterClick()
	self.btnAttrFilter:get("arrow"):setFlippedY(true)
	local selectAttrIds = self.selectAttrIds:read()
	local data = {{name = gLanguageCsv.default, selected = itertools.size(selectAttrIds) == 0}}
	for _, key in ipairs(ATTR_FILTER_TYPE) do
		local id = game.ATTRDEF_ENUM_TABLE[key]
		table.insert(data, {id = id, name = ChipTools.getAttrName(id), selected = selectAttrIds[id] or false})
	end
	self.attrFilterData:update(data)
	self.attrFilterPanel:show()
end

function ChipBagView:onShowSelectSpriteView()
	gGameUI:stackUI('city.card.chip.select_sprite', nil, nil, self.selectCardDBID:read(), self:createHandler('setCardDBID'))
end

function ChipBagView:showDetails(panel, item, slotIdx, dbId, cardDBID, plan)
	local pos = item:convertToWorldSpaceAR(cc.p(0, 0))
	local align = "right"
	if slotIdx and slotIdx >= 1 and slotIdx <= 3 then
		align = "left"
	end
	gGameUI:stackUI('city.card.chip.details', nil, {dispatchNodes = {self.bagList, self.chipPanel}, clickClose = true}, {
		dbId = dbId,
		cardDBID = cardDBID,
		plan = plan,
		pos = pos,
		align = align,
		dataRefresh = function()
			self.isRefreshBagPanel:notify()
		end,
		cb = self:createHandler("resetSelected"),
	})
end

function ChipBagView:resetSelected()
	self.selectItem:set({})
	if not self.selectLeftPos:read() then
		self.selectRightPos:set()
	end
end

function ChipBagView:onPosClick(list, k, v)
	self.selectLeftPos:set(v.pos)
	self.selectRightPos:set(v.pos)
end

function ChipBagView:refreshLeftPanel()
	local roleChips = self.roleChips:read()
	local selectLeftPos = self.selectLeftPos:read()
	local selectSuitId = self.selectSuitId:read()
	local selectAttrIds = self.selectAttrIds:read()
	local data = {}
	local flags = {} -- 筛选后的芯片可以镶嵌的位置

	local function filter(cfg, dbId)
		if selectLeftPos and selectLeftPos ~= cfg.pos then
			return false
		end
		if selectSuitId and selectSuitId ~= cfg.suitID then
			return false
		end
		if itertools.size(selectAttrIds) > 0 then
			local _, secondAttrs = ChipTools.getAttrs({dbId})
			for id, _ in pairs(selectAttrIds) do
				-- 副属性中 固定值或百分比没有该属性过滤掉
				if not secondAttrs[1][id] and not secondAttrs[2][id] then
					return false
				end
			end
		end
		return true
	end
	for idx, dbId in ipairs(roleChips) do
		local chip = gGameModel.chips:find(dbId)
		local chipData = chip:read("chip_id", "card_db_id", "level", "locked")
		-- 不显示已被装备的芯片
		if not chipData.card_db_id then
			local cfg = csv.chip.chips[chipData.chip_id]
			if filter(cfg, dbId) then
				data[dbId] = {
					idx = idx, -- 用于排序有序显示
					dbId = dbId,
					chipId = chipData.chip_id,
					level = chipData.level,
					locked = chipData.locked,
					cfg = cfg,
				}
				if selectSuitId then
					flags[cfg.pos] = true
				end
			end
		end
	end
	dataEasy.tryCallFunc(self.bagList, "updatePreloadCenterIndexAdaptFirst")
	self.bagData:update(data)
	self.slotFlags:set(flags)
	self.empty:visible(itertools.size(data) == 0)
end

function ChipBagView:createMovePanel(data)
	if self.movePanel then
		self.movePanel:removeSelf()
	end
	local movePanel = self.bagItem:clone():addTo(self:getResourceNode(), 1000):show()
	self.movePanel = movePanel
	bind.extend(self, movePanel, {
		class = 'icon_key',
		props = {
			noListener = true,
			data = {
				key = data.chipId,
				dbId = data.dbId,
			},
			specialKey = {
				leftTopLv = data.level
			},
			onNode = function(panel)
				panel:scale(1.15)
			end,
		},
	})
	return movePanel
end

function ChipBagView:deleteMovingItem()
	if self.movePanel then
		self.movePanel:removeSelf()
		self.movePanel = nil
	end
end

function ChipBagView:moveMovePanel(event)
	if self.movePanel then
		self.movePanel:xy(event)
	end
end

function ChipBagView:isMovePanelExist()
	return self.movePanel ~= nil
end

function ChipBagView:moveEndMovePanel(data)
	if not self.movePanel then
		return
	end
	 self.selectIndex:read()
	self:onCardMove(data, index, true)
	self:deleteMovingItem()
end

function ChipBagView:onItemTouch(list, node, t, v, event)
	if event.name == 'began' then
		self.moved = false
		self.touchBeganPos = event
		self:deleteMovingItem()
		performWithDelay(self, function()
			t.dbId = v.dbId
			self.selectItem:set(t)
			self.selectRightPos:set(v.cfg.pos)
		end, 0)

	elseif event.name == 'moved' then
		if not self.moved and not self:isMovePanelExist() then
			local deltaX = math.abs(event.x - self.touchBeganPos.x)
			local deltaY = math.abs(event.y - self.touchBeganPos.y)
			if (deltaX >= ui.TOUCH_MOVED_THRESHOLD or deltaY >= ui.TOUCH_MOVED_THRESHOLD) then
				if deltaX > deltaY * 0.7 then
					self:createMovePanel(v)
				end
				self.moved = true
			end
		end
		self.bagList:setTouchEnabled(not self:isMovePanelExist())
		self:moveMovePanel(event)

	elseif event.name == 'ended' or event.name == 'cancelled' then
		if not self.moved then
			self:showDetails(list, node, nil, v.dbId, self.selectCardDBID:read())
			return
		end
		self:resetSelected()
		if self.movePanel then
			self:deleteMovingItem()
			for i = 1, 6 do
				local item = self.chipPanel:getItem(i)
				local rect = item:box()
				local pos = item:getParent():convertToWorldSpace(cc.p(rect.x, rect.y))
				rect.x, rect.y = pos.x, pos.y
				rect.width, rect.height = rect.width * self.chipPanel:scale(), rect.height * self.chipPanel:scale()
				if cc.rectContainsPoint(rect, event) then
					if i == v.cfg.pos then
						local hasEquip = self.cardChips:read()[i] ~= nil
						gGameApp:requestServer("/game/card/chip/change", function(tb)
							if hasEquip then
								gGameUI:showTip(gLanguageCsv.exchange2Success)
							else
								gGameUI:showTip(gLanguageCsv.inlaySuccess)
							end
						end, self.selectCardDBID:read(), {[i] = v.dbId})
					else
						gGameUI:showTip(gLanguageCsv.chipSlotError)
					end
					return
				end
			end
		end
	end
end

function ChipBagView:onCardChipClick(node, idx, v, event)
	if event.name == 'began' then
		self.moved = false
		self.touchBeganPos = event
		self:deleteMovingItem()

	elseif event.name == 'moved' then
		if not self.moved and not self:isMovePanelExist() then
			local deltaX = math.abs(event.x - self.touchBeganPos.x)
			local deltaY = math.abs(event.y - self.touchBeganPos.y)
			if (deltaX >= ui.TOUCH_MOVED_THRESHOLD or deltaY >= ui.TOUCH_MOVED_THRESHOLD) then
				self:createMovePanel(v)
				self.moved = true
			end
		end
		self:moveMovePanel(event)

	elseif event.name == 'ended' or event.name == 'cancelled' then
		if not self.moved then
			self.selectLeftPos:set(idx)
			self.selectRightPos:set(idx)
			self:showDetails(list, node, idx, v.dbId, self.selectCardDBID:read())
			return
		end
		self:resetSelected()
		if self.movePanel then
			self:deleteMovingItem()
			local rect = self.bagList:box()
			local pos =  self.bagList:getParent():convertToWorldSpace(cc.p(rect.x, rect.y))
			rect.x, rect.y = pos.x, pos.y
			if cc.rectContainsPoint(rect, event) then
				gGameApp:requestServer("/game/card/chip/change", function(tb)
					gGameUI:showTip(gLanguageCsv.dischargeSuccess)
				end, self.selectCardDBID:read(), {[v.cfg.pos] = -1})
			end
		end
	end
end

function ChipBagView:showPanel()
	local selectCardDBID = self.selectCardDBID:read()
	-- 基础属性
	local firstAttrs, secondAttrs = ChipTools.getAttrs(selectCardDBID)
	local attrs = {}
	ChipTools.setAttrCollect(firstAttrs, secondAttrs)

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

function ChipBagView:onDrawClick()
	gGameUI:stackUI('city.card.chip.draw')
end

-- 一键卸下
function ChipBagView:onOnekeyDownClick()
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
function ChipBagView:onPlanClick()
	dataEasy.tryCallFunc(self.chipPanel, "pauseSuitEffect")
	gGameUI:stackUI('city.card.chip.plan', nil, nil, {curCardDBID = self.selectCardDBID:read(), cb = self:createHandler("planCb")})
end

function ChipBagView:planCb(curCardDBID)
	self:setCardDBID(curCardDBID)
	dataEasy.tryCallFunc(self.chipPanel, "resumeSuitEffect")
end

-- TODO 方案对比
function ChipBagView:onPlanCompareClick()
end

-- 基础属性详情
function ChipBagView:onBaseAttrDetailClick()
	gGameUI:stackUI('city.card.chip.total_detail', nil, nil, {typ = 1, cardPlan = self.selectCardDBID:read()})
end

-- 套装属性详情
function ChipBagView:onSuitAttrDetailClick()
	gGameUI:stackUI('city.card.chip.suit_detail', nil, nil, self.selectCardDBID:read())
end

function ChipBagView:onSuitAttrItemClick(list, node, k, v)
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

function ChipBagView:onSuitFilterItemClick(list, node, k, v)
	self.selectSuitId:set(v.suitId, true)
end

function ChipBagView:onSuitFilterAllClick()
	self.selectSuitId:set(nil, true)
end

function ChipBagView:onAttrFilterItemClick(list, node, t, v)
	local count = 0
	for i, data in self.attrFilterData:ipairs() do
		if i ~= 1 then
			if data:proxy().selected then
				count = count + 1
			end
		end
	end
	if t.k ~= 1 and count >= 4 and v.selected == false then
		gGameUI:showTip(gLanguageCsv.chipAttrFilterCountMax)
		return
	end
	local hasAttrSelected = false
	for i, data in self.attrFilterData:ipairs() do
		if i ~= 1 then
			if t.k == 1 then
				data:proxy().selected = false
			elseif t.k == i then
				data:proxy().selected = not data:proxy().selected
			end

			if data:proxy().selected then
				hasAttrSelected = true
			end
		end
	end
	self.attrFilterData:atproxy(1).selected = not hasAttrSelected
end


function ChipBagView:onShowRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 2200, height = 1113})
end

function ChipBagView:getRuleContext(view)

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

return ChipBagView