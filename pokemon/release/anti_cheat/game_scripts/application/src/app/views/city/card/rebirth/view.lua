--
-- @data: 2019-7-24 11:07:58
-- @desc: 卡牌羁绊
--
local RebirthTools = require "app.views.city.card.rebirth.tools"
local HeldItemTools = require "app.views.city.card.helditem.tools"

local RULECONTENT = {
	{58001, 58005},
	{59001, 59006},
	{60001, 60004},
	{83001, 83005},
	{124501, 124505}
}

local RULETITLE = {
	gLanguageCsv.cardRebirthNote,
	gLanguageCsv.cardDecomposeNote,
	gLanguageCsv.heldItemRebirthNote,
	gLanguageCsv.gemRebirthRule,
	gLanguageCsv.chipRebirthRule,
}

local ViewBase = cc.load("mvc").ViewBase
local CardRebirthView = class("CardRebirthView", ViewBase)

CardRebirthView.RESOURCE_FILENAME = "rebirth_main.json"
CardRebirthView.RESOURCE_BINDING = {
	["btnItem"] = "btnItem",
	["starItem"] = "starItem",
	["attrItem"] = "attrItem",
	["item"] = "item",
	["innerList"] = "innerList",

	["page.list"] = {
		varname = "pagelist",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("btnsData"),
				item = bindHelper.self("btnItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local fountSize, selFountSize = 40, 50
					if k == 3 then
						fountSize = 36
						selFountSize = 40
					end
					local clickBtn = node:get("btnClick")
					clickBtn:get("textNote"):text(v.txt)
					local normalBtn = node:get("btnNormal")
					normalBtn:get("textNote"):text(v.txt)
					clickBtn:visible(v.isSel)
					normalBtn:visible(not v.isSel)
					text.addEffect(normalBtn:get("textNote"), {size = fountSize})
					text.addEffect(clickBtn:get("textNote"), {size = selFountSize})
					adapt.setTextScaleWithWidth(clickBtn:get("textNote"), nil, 240)
					adapt.setTextScaleWithWidth(normalBtn:get("textNote"), nil, 230)
					bind.touch(list, normalBtn, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onChangePage"),
			},
		},
	},
	["left"] = "leftPanel",
	["left.panelHeld"] = "heldItemPanel",
	["left.panelHeld.imgBg"] = {
		binds = {
			event = "texture",
			idler = bindHelper.self("heldItemId"),
			method = function(id)
				local path = "city/card/helditem/strengthen/img_dt%d.png"
				local quality = 1
				if id then
					local heldItem = gGameModel.held_items:find(id)
					local csvId = heldItem:read("held_item_id")
					quality = csv.held_item.items[csvId].quality
				end
				return string.format(path, quality)
			end,
		},
	},

	["left.panel404"] = 'panel404',
	["left.panel404.tile.txt"] = "txt404Tip",
	["left.panelGem"] = "panelGem",
	["left.panelGem.subList"] = "gemSubList",
	["left.panelGem.item"] = "gemItem",
	["left.panelGem.list"] = {
		varname = 'gemList',
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("gems"),
				columnSize = 5,
				item = bindHelper.self("gemSubList"),
				cell = bindHelper.self("gemItem"),
				onCell = function(list, node, k, v)

					bind.extend(list, node, {
						class = "icon_key",
						props = {
							noListener = true,
							data = {
								key = v.id,
								dbId = v.dbId
							},
							grayState = v.selected and 1 or 0,
							specialKey = {
								leftTopLv = v.level,
								unitId = v.unitId
							},
							onNode = function(iconnode)
								iconnode:onClick(functools.partial(list.itemClick, list, node, k, v))
								iconnode:scale(1.15)
							end
						},
					})
					node:get('mask'):visible(false)
					node:get('tick'):visible(v.selected and true or false)
				end
			},
			handlers = {
				itemClick = bindHelper.self('onGemClick')
			}
		}
	},

	["left.panelChip"] = "panelChip",
	["left.panelChip.subList"] = "chipSubList",
	["left.panelChip.item"] = "chipItem",
	["left.panelChip.list"] = {
		varname = 'chipList',
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("chips"),
				columnSize = 5,
				item = bindHelper.self("chipSubList"),
				cell = bindHelper.self("chipItem"),
				onCell = function(list, node, k, v)

					bind.extend(list, node, {
						class = 'icon_key',
						props = {
							noListener = true,
							data = {
								key = v.id,
								dbId = v.dbid,
							},
							grayState = v.selected and 1 or 0,
							specialKey = {
								leftTopLv = v.level,
								locked = v.locked,
								unitId = v.unitId
							},
							onNode = function(panel)
								panel:scale(1.15)
								panel:setTouchEnabled(false)
							end
						},
					})

					bind.touch(list, node, {method = function(_, _, event,...)
						list.itemClick(node, list:getIdx(k), v, event)
					end})

					node:get('mask'):visible(false)
					node:get('tick'):visible(v.selected and true or false)
				end
			},
			handlers = {
				itemClick = bindHelper.self('onChipClick')
			}
		}
	},

	["left.panelCard"] = "panelCard",
	["left.panelCard.roleInfo"] = "roleInfoPanel",
	["left.panelCard.btnRoleAdd"] = {
		varname = "roleAddBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddRole")}
		},
	},
	["left.panelCard.btnChange"] = {
		varname = "changeBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChange")}
		},
	},
	["left.panelCard.role"] = "roleNode",
	["left.panelCard.down"] = "downPanel",
	["left.panelCard.roleInfo.starList"] = {
		varname = "starlist",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("starData"),
				item = bindHelper.self("starItem"),
				onItem = function(list, node, k, v)
					node:get("imgStar"):texture(v.icon)
				end,
			}
		},
	},
	["left.panelCard.roleInfo.attrList"] = {
		varname = "attrlist",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("attrData"),
				item = bindHelper.self("attrItem"),
				onItem = function(list, node, k, v)
					node:get("imgIcon"):texture(ui.ATTR_ICON[v])
				end,
			}
		},
	},
	["left.panelCard.down.list"] = {
		varname = "equiplist",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("equipData"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						event = "extend",
						class = "equip_icon",
						props = {
							data = v,
							onNode = function(panel)
								panel:scale(1)
								panel:setTouchEnabled(false)
								local arrow = panel:get("imgArrow")
								arrow:visible(v.state == true)
								-- panel:xy(10, 10)
							end,
						}
					})
				end,
			}
		},
	},

	["left.panelDecompose"] = "decomposePanel",
	["left.panelDecompose.jumpShop.textNote1"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE, size = 4}},
		},
	},
	["left.panelDecompose.jumpShop.textNote2"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE, size = 4}},
		},
	},
	["left.panelDecompose.jumpShop"] = {
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onJumpToShop")}
			},
			{
				event = "visible",
				idler = bindHelper.self("isDecomposeView"),
			},
		},
	},
	["left.panelDecompose.item1"] = {
		varname = "item1",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddCard")},
		},
	},
	["left.panelDecompose.item2"] = {
		varname = "item2",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddCard")},
		},
	},
	["left.panelDecompose.item3"] = {
		varname = "item3",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddCard")},
		},
	},
	["left.panelDecompose.item4"] = {
		varname = "item4",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddCard")},
		},
	},
	["left.panelDecompose.item5"] = {
		varname = "item5",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddCard")},
		},
	},
	["left.panelDecompose.item1.btnCancel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function (view)
				view:onCancel(1)
 			end)}
		},
	},
	["left.panelDecompose.item2.btnCancel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function (view)
				view:onCancel(2)
 			end)}
		},
	},
	["left.panelDecompose.item3.btnCancel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function (view)
				view:onCancel(3)
 			end)}
		},
	},
	["left.panelDecompose.item4.btnCancel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function (view)
				view:onCancel(4)
 			end)}
		},
	},
	["left.panelDecompose.item5.btnCancel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function (view)
				view:onCancel(5)
 			end)}
		},
	},
	["left.panelDecompose.btnAuto"] = {
		varname = "btnAuto",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAutoSelected")},
		},
	},
	["left.panelDecompose.selectTipPanel"] = "decSelectTipPanel",
	["left.panelDecompose.selectTipPanel.btn"] = {
		varname = "decSelectTipBtn",
		binds = {
			event = "click",
			method = bindHelper.self("onDecSelectTipBtn"),
		},
	},

	["right"] = "rightPanel",
	["right.tipPanel"] = "tipPanel",
	["right.tipPanel.textNote"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("tipText"),
		},
	},
	["right.textNote"] = {
		varname = "rightTextNote",
		binds = {
			event = "text",
			idler = bindHelper.self("textRightNote"),
		},
	},
	["right.selectTipPanel"] = "selectTipPanel",
	["right.selectTipPanel.btn"] = {
		varname = "selectTipBtn",
		binds = {
			event = "click",
			method = bindHelper.self("onSelectTipBtn"),
		},
	},
	["right.btnSure"] = {
		varname = "btnSure",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSure")},
		},
	},
	["right.btnSure.textNote"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("btnText"),
		},
	},
	["right.cost"] = "panelCost",
	["right.cost.textCost"] = "costNum",
	["right.cost.textCostNote"] = "textCostNote",
	["right.cost.imgIcon"] = "costIcon",
	["right.list"] = {
		varname = "itemlist",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				columnSize = bindHelper.self('midColumnSize'),
				data = bindHelper.self("itemDatas"),
				item = bindHelper.self("innerList"),
				cell = bindHelper.self("item"),
				-- columnSize = 4,
				onCell = function(list, node, k, v)
					local binds = {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.val,
								noColor = true
							},
						},
					}
					bind.extend(list, node, binds)
				end,
			}
		},
	},

	["left.panelHeld.imgIcon"] = {
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("showHeldItemIcon"),
			},
			{
				event = "texture",
				idler = bindHelper.self("heldItemIcon"),
			},
		},
	},
	["left.panelHeld.textName"] = {
		varname = "heldItemNameText",
		binds = {
			event = "text",
			idler = bindHelper.self("heldItemName"),
		},
	},
	["left.panelHeld.btnAdd"] = {
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onShowHeldItem")},
			},
			{
				event = "visible",
				idler = bindHelper.self("showHeldItemAddBtn"),
			},
		},
	},
	["left.panelHeld.btnChange"] = {
		varname = "heldChangeBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChange")}
		},
	},

	["left.panelHeld.textLv"] = {
		varname = "heldItemTextLv",
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("showHeldItemIcon"),
			},
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.NORMAL.DEFAULT}}
			},
		},
	},
	["left.panelHeld.imgExc"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("isHeldItemExc"),
		},
	},
	["left.panelHeld.textLvNum"] = {
		varname = "textLvNum",
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("showHeldItemIcon"),
			},
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.NORMAL.DEFAULT}}
			},
		},
	},
	["right.btnHelp"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleShow")}
		},
	},
	["right.textChipTip"] = "textChipTip",
}

CardRebirthView.RESOURCE_STYLES = {
	full = true,
}


function CardRebirthView:initData()
	self.rebirthData = {
	 	{
			key = "cardReborn",
			name = gLanguageCsv.cardRebirth,
			isFirst = true,
			resetData = function()
				self.dbId:set(nil)
				self.roleNode:removeAllChildren()
			end,

			getTipInfo = function()
				local isRebirth = RebirthTools.isCardRebirthed(self.dbId:read())
				local tips = (isRebirth and self.dbId:read() ~= nil) and gLanguageCsv.cantRebirth or gLanguageCsv.notSelRole
				return gLanguageCsv.cardRebirth, tips
			end,

			getUrlParams = function()
				local txt = uiEasy.getCardName(self.dbId:read())
				local result = {
					pos = cc.p(910, 520),
					scale = 1,
					parent = self.leftPanel,
					isEffect = true,
					url = "/game/card/rebirth",
					params = self.dbId:read(),
					str = string.format(gLanguageCsv.rebirthCardTip, txt),
					afterRequest = function()
						self.isRebirthEnded:set(true, true)
						self.itemDatas:update({})
						self:refreshUI()
					end
				}
				return result
			end,
		},
		{
			key = "cardReborn",
			name = gLanguageCsv.cardDecompose,

			resetData = function()
				self.decomposePosState = {}
				self.decomposeIds:set({})
			end,

			getTipInfo = function()
				return gLanguageCsv.cardDecompose, gLanguageCsv.notSelRole
			end,

			getUrlParams = function()
				local data = {}
				local haveHighRarity = false
				for k,v in self.decomposeIds:pairs() do
					if v.rarity > 2 then
						haveHighRarity = true
					end
					table.insert(data, v.dbid)
				end
				local result =
				{
					pos = cc.p(1228, 765),
					scale = 2,
					parent = self.decomposePanel,
					url = "/game/card/decompose",
					isEffect = true,
					params = data,
					haveHighRarity = haveHighRarity,
					str = gLanguageCsv.decomposeCardTip,
					afterRequest = function()
						if self.handlers and type(self.handlers) == 'function' then
							self.handlers()
						end
						self.decomposeIds:set({})
						self.itemDatas:update({})
						self:refreshUI()
					end
				}
				return result
			end,
		},
		{
			key = "heldItem",
			name = gLanguageCsv.heldItemRebirth,

			resetData = function()
				self.heldItemId:set(nil)
			end,

			getTipInfo = function()
				local heldId = self.heldItemId:read()
				local isRebirth = RebirthTools.isHeldItemRebirthed(heldId)
				local tips = (isRebirth and heldId ~= nil) and gLanguageCsv.heldItemCanotRebirth or gLanguageCsv.notSelHeldItem

				return gLanguageCsv.reborn, tips
			end,

			getUrlParams = function()

				local heldItem = gGameModel.held_items:find(self.heldItemId:read())
				local csvId = heldItem:read("held_item_id")
				local advance = heldItem:read("advance")
				local info = csv.held_item.items[csvId]
				local quality= info.quality
				local color = quality == 1 and "#C0x5B545B#" or ui.QUALITYCOLOR[quality]
				local txt = string.format("%s%s+%s", color, info.name, advance)

				local result = {
					pos = cc.p(915, 750),
					parent = self.leftPanel,
					scale = 1,
					isEffect = true,
					url = "/game/helditem/rebirth",
					params = self.heldItemId,
					str = string.format(gLanguageCsv.rebirthHeldItemTip, txt),
					afterRequest = function()
						self.isRebirthEnded:set(true, true)
						self.itemDatas:update({})
						self:refreshUI()
					end,
				}
				return result
			end,
		},
		{
			key = "gem",
			name = gLanguageCsv.gemRebirth,

			resetData = function()
				self.selectGems = {}
				self:updateGems()
			end,

			getTipInfo = function()
				return gLanguageCsv.gemRebirth, gLanguageCsv.selectGem, gLanguageCsv.haveNoSelectGem
			end,

			getUrlParams = function()
				local result = {
					pos = cc.p(915, 750),
					parent = self.leftPanel,
					scale = 1,
					url = "/game/gem/rebirth",
					params = self.selectGems,
					str = gLanguageCsv.rebirthGemTip,
					afterRequest = function()
						self.selectGems = {}
						self:updateGemCost()
						self:updateGems()
						self.itemDatas:update({})
						self:refreshUI()
					end
				}
				return result
			end,
		},
		{
			key = "chip",
			name = gLanguageCsv.chipRebirth,
			resetData = function()
				self.selectChips = {}
				self:updateChips()
			end,

			getTipInfo = function()
				return gLanguageCsv.chipRebirth, gLanguageCsv.selectChip, gLanguageCsv.haveNoSelectChip
			end,

			getUrlParams = function()
				local list ={}
				for dbid, sign in pairs(self.selectChips) do
					if sign then
						table.insert(list, dbid)
					end
				end


				local result = {
					pos = cc.p(915, 750),
					scale = 1,
					parent = self.leftPanel,
					url = "/game/chip/rebirth",
					params = list,
					str = gLanguageCsv.rebirthChipTip,
					afterRequest = function()
						self.selectChips = {}
						self:updateChipCost()
						self:updateChips()
						self.itemDatas:update({})
						self:refreshUI()
					end
				}
				return result
			end,
		}
	}
end
function CardRebirthView:onCreate(pageIdx, handlers, cardsChanged, params)
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.cardRebirth, subTitle = "ELVES REBIRTH"})

	params = params or {}

	local _, count = adapt.centerWithScreen("left", nil,{
		itemWidth = self.item:width(),
		itemWidthExtra = 80,
	},{
		{{self.innerList, self.itemlist}, "width"}
	})
	self.midColumnSize = 4 + (count or 0)
	self.asyncPreload = self.midColumnSize * 5
	local dot = (self.midColumnSize - 4)*self.item:width()

	self.itemlist:x(self.itemlist:x() - dot)
	self.rightTextNote:x(self.itemlist:x())
	self.tipPanel:x(self.tipPanel:x() - dot/2)
	-- self.btnSure:x(self.btnSure:x() - dot/2)
	self.selectTipPanel:x(self.selectTipPanel:x() - dot/2)
	self.panelCost:x(self.panelCost:x() - dot)
	self.textChipTip:x(self.textChipTip:x() - dot/2)

	self.handlers = handlers

	if cardsChanged then
		self.cardsChanged = cardsChanged()
	end

	self:initModel()
	self:initData()

	self.pageIdx        = idler.new(pageIdx or 1)
	self.isDecomposeView = idler.new(self.pageIdx:read() == 2)
	self.heldItemId:set(params.heldItemId)

	self.panel404:visible(false)

	local btnsData = {}
	for index, data in ipairs(self.rebirthData) do
		if dataEasy.isUnlock(data.key) then
			btnsData[index] = {txt = data.name, isSel = false}
		end
	end
	self.btnsData:update(btnsData)


	idlereasy.any({self.dbId, self.isRebirthEnded},function (_, dbId, isRebirthEnded)
		if not dbId or not gGameModel.cards:find(dbId) then
			self.dbId:set(nil)
			return
		end

		self:initRebirthCardUI(dbId)
		local items, cost = RebirthTools.getReturnItems(dbId)
		self:initRightData(items, cost)
		self:refreshUI()
	end)


	self.pageIdx:addListener(function(val, oldval)
		self.btnsData:atproxy(oldval).isSel = false
		self.btnsData:atproxy(val).isSel = true
		-- --选择卡牌分解提示
		self:initRightData({}, 0)
		self.rebirthData[val]:resetData()

		self:refreshUI(val)

	end)

	-- 初始选择设置
	idlereasy.when(self.decomposeIds, function(_, decomposeIds)
		self:initCardDecomposeUI(decomposeIds)
		local items, cost = RebirthTools.computeDecomposeItems(decomposeIds)
		self:initRightData(items, cost)

		self:refreshUI()
	end)

	idlereasy.any({self.heldItemId, self.isRebirthEnded}, function(_, heldItemId, isRebirthEnded)

		self:initHeldItemUI(heldItemId)
		if heldItemId then
			local items, cost = RebirthTools.computeHeldItemReturn(heldItemId)
			self:initRightData(items, cost)
			self:refreshUI()
		end
	end)


	idlereasy.when(self.rmb, function(_, rmb)
		self:refreshTextColor()
	end)

	self:initSelectTipPanel()
end

function CardRebirthView:initModel()
	self.rmb = gGameModel.role:getIdler("rmb")
	self.cards = gGameModel.role:getIdler("cards")
	self.items = gGameModel.role:getIdler("items")

	self.dbId = idler.new()
	self.heldItemId = idler.new()
	self.selectGems = {}
	self.gems = idlers.new({})
	self.chips = idlers.new({})
	self.cost = idler.new(0)
	self.decomposePosState = {}
	self.btnText = idler.new("")
	self.showHeldItemIcon = idler.new(false)
	self.isHeldItemExc = idler.new(false)
	self.showHeldItemAddBtn = idler.new(false)
	self.showGemItemAddBtn = idler.new(false)
	self.heldItemName = idler.new("")
	self.heldItemIcon = idler.new("")
	self.decomposeIds = idlertable.new({})
	self.isRebirthEnded = idler.new(false)
	self.textRightNote = idler.new("")
	self.tipText = idler.new("")
	self.attrData = idlers.newWithMap({})
	self.equipData = idlers.newWithMap({})
	self.starData = idlers.newWithMap({})
	self.btnsData = idlers.newWithMap({})
	self.itemDatas = idlers.newWithMap({})
	self.canRebirthGetItems = {}
	self.canDecomposeIdsGetItems = {}
end

function CardRebirthView:initSelectTipPanel()
	self.decSelectTipPanel:visible(dataEasy.isUnlock(gUnlockCsv.decompositionMaxStar))
	local state = userDefault.getForeverLocalKey("cardRebirthTip", false)
	self.selectTipBtn:get("checkBox"):setSelectedState(state)
	state = userDefault.getForeverLocalKey("cardRebirthSelcetTip", false)
	self.decSelectTipBtn:get("checkBox"):setSelectedState(state)
	local decSelectTipPanelSize = self.decSelectTipPanel:size()
	adapt.oneLineCenterPos(cc.p(decSelectTipPanelSize.width/2, decSelectTipPanelSize.height/2), {self.decSelectTipBtn, self.decSelectTipPanel:get("textTip")}, cc.p(0, 0))

	local textTip = self.selectTipPanel:get("textTip")
	adapt.setTextAdaptWithSize(textTip, {str = gLanguageCsv.selectSpriteDecompositionTip, size = cc.size(800, 200), vertical = "center", horizontal = "left", margin = -8})
	textTip:anchorPoint(0.5, 0.5)
	local size = self.selectTipPanel:size()
	adapt.oneLineCenterPos(cc.p(size.width/2, size.height/2), {self.selectTipBtn, textTip})
	if not matchLanguage({"cn", "tw"}) then
		textTip:y(textTip:y() - 10)
	end
end

function CardRebirthView:initRebirthCardUI(dbid)
	local card = gGameModel.cards:find(dbid)
	local cardData = card:read("card_id","skin_id", "level", "star", "advance", "equips", "skills")
	local cardInfo = csv.cards[cardData.card_id]
	local unitInfo = dataEasy.getUnitCsv(cardData.card_id, cardData.skin_id)

	local childs = self.roleInfoPanel:multiget("imgIcon","textLvNum","textLv","textName")
	childs.imgIcon:texture(ui.RARITY_ICON[unitInfo.rarity])
	childs.textLvNum:text(cardData.level)
	adapt.oneLineCenterPos(cc.p(childs.imgIcon:x(), childs.textLvNum:y()), {childs.textLv, childs.textLvNum})
	uiEasy.setIconName("card", cardData.card_id, {node = childs.textName, name = cardInfo.name, advance = cardData.advance, space = true})

	self.roleNode:removeAllChildren()

	local size = self.roleNode:size()
	local cardSprite = widget.addAnimation(self.roleNode, unitInfo.unitRes, "standby_loop", 1)
		:xy(size.width / 2, 0)
		:scale(unitInfo.scaleU * 3)
	cardSprite:setSkin(unitInfo.skin)

	local attrDatas = {}
	table.insert(attrDatas, unitInfo.natureType)
	if unitInfo.natureType2 then
		table.insert(attrDatas, unitInfo.natureType2)
	end
	self.attrData:update(attrDatas)

	local starDatas = {}
	local starIdx = cardData.star - 6
	for i=1,6 do
		local icon = "common/icon/icon_star_d.png"
		if i <= cardData.star then
			icon = i <= starIdx and "common/icon/icon_star_z.png" or "common/icon/icon_star.png"
		end
		table.insert(starDatas,{icon = icon})
	end
	self.starData:update(starDatas)

	self.equipData:update(table.deepcopy(cardData.equips, true))
end

function CardRebirthView:initCardDecomposeUI(decomposeIds)
	if itertools.isempty(self.decomposePosState) then
		local keys = itertools.keys(decomposeIds)
		table.sort(keys)
		self.decomposePosState = keys
	end
	for i = 1, 5 do
		local k = self.decomposePosState[i]
		local data = decomposeIds[k]
		if not data then
			self["item" .. i]:get("btnCancel"):visible(false)
			self["item" .. i]:get("head"):visible(false)
			self["item" .. i]:get("btnAdd"):visible(true)
		else
			local rarity = csv.unit[data.unitId].rarity
			bind.extend(self, self["item" .. i]:get("head"), {
				class = "card_icon",
				props = {
					unitId = data.unitId,
					advance = data.advance,
					star = data.star,
					rarity = rarity,
					levelProps = {
						data = data.level,
					},
				}
			})
			self["item" .. i]:get("btnCancel"):visible(true)
			self["item" .. i]:get("head"):visible(true)
			self["item" .. i]:get("btnAdd"):visible(false)
		end
	end
end

function CardRebirthView:initHeldItemUI(heldItemId)
	if not heldItemId then
		self.showHeldItemIcon:set(false)
		self.showHeldItemAddBtn:set(true)
		self.heldItemName:set("")
		self.isHeldItemExc:set(false)
		self.heldItemTextLv:visible(false)
		self.textLvNum:visible(false)
		return
	end
	self.showHeldItemIcon:set(true)
	self.showHeldItemAddBtn:set(false)
	local heldItem = gGameModel.held_items:find(heldItemId)
	local csvId = heldItem:read("held_item_id")
	local advance = heldItem:read("advance")
	local level = heldItem:read("level")
	local _, isExc = HeldItemTools.isExclusive({csvId = csvId, dbId = heldItemId})
	local csvTab= csv.held_item.items
	local cfg = csvTab[csvId]
	self.isHeldItemExc:set(isExc)
	self.textLvNum:text(level)
	adapt.oneLinePos(self.heldItemTextLv, self.textLvNum, cc.p(5, 0), "left")
	local nameStr = cfg.name
	if advance ~= 0 then
		nameStr = cfg.name .. " +" .. advance
	end
	self.heldItemName:set(nameStr)
	self.heldItemIcon:set(cfg.icon)
	local color = cfg.quality == 1 and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.QUALITY[cfg.quality]
	text.addEffect(self.heldItemNameText, {color= color})
end

function CardRebirthView:initRightData(items, cost)
	self.canRebirthGetItems = items
	self.itemDatas:update(items)
	self.costNum:text(cost)
	self.cost:set(cost)
	self:refreshTextColor()
	adapt.oneLinePos(self.textCostNote, {self.costNum, self.costIcon}, cc.p(6, 0))
end

function CardRebirthView:updateGems()
	local gems = gGameModel.role:read("gems")
	local data = {}
	for i, dbid in pairs(gems) do
		local gem = gGameModel.gems:find(dbid)
		local gem_id = gem:read('gem_id')
		local cardDbID = gem:read("card_db_id")
		local unitId = nil
		if cardDbID then
			local cardData = gGameModel.cards:find(cardDbID)
			unitId = dataEasy.getUnitId(cardData:read("card_id"), cardData:read("skin_id"))
		end

		local level = gem:read('level')
		local cfg = dataEasy.getCfgByKey(gem_id)
		local gemdata = {
			id = gem_id,
			num = 1,
			unitId = unitId,
			suitNo = cfg.suitNo,
			suitID = cfg.suitID,
			level = level,
			quality = cfg.quality,
			isEquipped = gem:read("card_db_id") and true or false,
			dbid = dbid,
			cardDbID = gem:read("card_db_id"),
		}

		if gemdata.level > 1 then
			table.insert(data, gemdata)
		end
	end
	table.sort(data, function(a, b)
		if a.isEquipped ~= b.isEquipped then
			return not a.isEquipped
		end
		if a.quality ~= b.quality then
			return a.quality < b.quality
		end
		if a.level ~= b.level then
			return a.level > b.level
		end
		return a.id < b.id
	end)
	self.gems:update(data)
	self.panel404:visible(#data == 0)
end

function CardRebirthView:updateChips()
	local chips = gGameModel.role:read("chips")
	local data = {}
	for i, dbid in pairs(chips) do
		local chip = gGameModel.chips:find(dbid)
		local chipData = chip:read('chip_id', 'locked', 'card_db_id', 'level', "sum_exp")

		local unitId = nil
		if chipData.card_db_id then
			local cardData = gGameModel.cards:find(chipData.card_db_id)
			unitId = dataEasy.getUnitId(cardData:read("card_id"), cardData:read("skin_id"))
		end
		if self.selectChips[dbid] and chipData.locked then
			self.selectChips[dbid] = false
		end

		local cfg = dataEasy.getCfgByKey(chipData.chip_id)
		local tempData = {
			id = chipData.chip_id,
			unitId = unitId,
			level = chipData.level,
			locked = chipData.locked,
			quality = cfg.quality,
			isEquipped = chipData.card_db_id and true or false,
			dbid = dbid,
			cardDbID = chipData.card_db_id,
			selected = self.selectChips[dbid]
		}

		if chipData.sum_exp > 0 then
			table.insert(data, tempData)
		end

	end

	table.sort(data, function(a, b)
		if a.isEquipped ~= b.isEquipped then
			return not a.isEquipped
		end
		if a.quality ~= b.quality then
			return a.quality < b.quality
		end
		if a.level ~= b.level then
			return a.level > b.level
		end
		return a.id < b.id
	end)
	self.chips:update(data)
	self.panel404:visible(#data == 0)
	-- self.gem404:visible(#data == 0)
end


function CardRebirthView:refreshTextColor()
	local color = ui.COLORS.NORMAL.DEFAULT
	if self.cost:read() > self.rmb:read() then
		color = ui.COLORS.NORMAL.RED
	end
	text.addEffect(self.costNum, {color = color})
end


function CardRebirthView:refreshUI(curPage)
	curPage = curPage or self.pageIdx:read()

	self.decomposePanel:visible(curPage == 2)
	self.panelChip:visible(false)
	self.heldItemPanel:visible(curPage == 3)
	self.panelGem:visible(curPage == 4)
	self.panelChip:visible(curPage == 5)
	self.textChipTip:visible(curPage == 5)
	self.panelCard:visible(curPage == 1)
	if curPage <= 3 then
		self.panel404:visible(false)
	end

	self.roleInfoPanel:visible(curPage == 1 and self.dbId:read() ~= nil)
	self.roleNode:visible(curPage == 1)
	self.downPanel:visible(curPage == 1 and  self.dbId:read() ~= nil)
	self.roleAddBtn:visible(curPage == 1 and not self.dbId:read())
	self.changeBtn:visible(self.dbId:read() ~= nil )
	self.heldChangeBtn:visible(self.heldItemId:read() ~= nil)

	local hasItems = self.itemDatas:size() > 0

	if curPage >= 4 and self.panel404:isVisible() then
		self.tipPanel:visible(false)
	else
		self.tipPanel:visible(not hasItems)
	end
	self.itemlist:visible(hasItems)
	-- self.rightPanel:get("cost"):visible(hasItems and self.cost:read() > 0)


	cache.setShader(self.btnSure, false, self.itemDatas:size() > 0 and "normal" or "hsl_gray")
	self.btnSure:setTouchEnabled(self.itemDatas:size() > 0)
	local color = self.itemDatas:size() > 0 and ui.COLORS.NORMAL.WHITE or ui.COLORS.DISABLED.WHITE
	text.addEffect(self.btnSure:get("textNote"), {color = color})

	local str,tips,notip = self.rebirthData[curPage].getTipInfo()
	local txt = string.format(gLanguageCsv.rebirthNotes, str)
	self.textRightNote:set(txt)
	self.tipText:set(tips)

	self.selectTipPanel:visible(curPage == 2)
	local txt = curPage == 2 and gLanguageCsv.decompose or gLanguageCsv.rebirthSpace
	self.btnText:set(txt)
	self.isDecomposeView:set(curPage == 2)

	self.txt404Tip:text(notip or "")
end


function CardRebirthView:onChangePage(list, idx, v)
	self.pageIdx:set(idx)
end

function CardRebirthView:onAddRole()
	gGameUI:stackUI("city.card.rebirth.choose_role", nil, nil, {from = 1, handlers = self:createHandler("onSetDbId")})
end

--更换
function CardRebirthView:onChange()
	if self.pageIdx:read() == 3 then
		gGameUI:stackUI("city.card.rebirth.choose_helditem", nil, nil, {curSel = self.heldItemId:read(), handlers = self:createHandler("onSetHeldItemDbId")})
	else
		gGameUI:stackUI("city.card.rebirth.choose_role", nil, nil, {from = 1, curSel = {self.dbId:read()}, handlers = self:createHandler("onSetDbId")})
	end
end

function CardRebirthView:onSetDbId(tab)
	local _, data = next(tab)
	if data then
		local card = gGameModel.cards:find(data.dbid)
		if card then
			self.dbId:set(data.dbid)
		else
			self.dbId:set(nil)
		end
	end
end

function CardRebirthView:onSetDecomposeDbId(tab)
	for i, v in pairs(tab) do
		local card = gGameModel.cards:find(v.dbid)
		if not card then
			tab[i] = nil
		end
	end
	self.decomposePosState = {}
	self.decomposeIds:set(tab)
end

function CardRebirthView:onAddCard()
	local curSel = {}
	for i,v in self.decomposeIds:pairs() do
		curSel[i] = v.dbid
	end
	gGameUI:stackUI("city.card.rebirth.choose_role", nil, nil, {from = 2, curSel = curSel, handlers = self:createHandler("onSetDecomposeDbId")})
end

-- a.battle: 1上阵 2:未上阵
function CardRebirthView:onAutoSelected()
	local cards = RebirthTools.getSelectCard(2)
	local function isSpe(v)
		if v.rarity >= 3 then
			return true
		end
		if v.star > csv.cards[v.id].star then
			return true
		end
		return false
	end
	table.sort(cards, function(a, b)
		if a.battle ~= b.battle then
			return a.battle == 2 and true or false
		end
		local speA = isSpe(a)
		local speB = isSpe(b)
		if speA ~= speB then
			return speB
		end
		if a.rarity ~= b.rarity then
			return a.rarity < b.rarity
		end
		return a.fight < b.fight
	end)

	-- 同一markID最大星级
	local maxStar = {}
	for k,v in ipairs(gGameModel.role:read("cards")) do
		local card = gGameModel.cards:find(v)
		local cardId = card:read("card_id")
		local star = card:read("star")
		local cardCsv = csv.cards[cardId]
		local cardMarkID = cardCsv.cardMarkID
		maxStar[cardMarkID] = maxStar[cardMarkID] and math.max(maxStar[cardMarkID], star) or star
	end

	local selTab = {}
	local idx = 0
	local topRarity = {}
	local selDbIds = {}
	local count = 0
	local isTopStar = false
	local isTopRarity = false
	local content = gLanguageCsv.hasRarityCard

	local state = userDefault.getForeverLocalKey("cardRebirthSelcetTip", false)
	for i,v in ipairs(cards) do
		if v.battle ~= 1 and not v.isUnion and not v.lock and v.cardType == 1 then
			if not state or (maxStar[v.markId] == 12 and v.star ~= 12) then
				count = count + 1
				selTab[i] = v
				table.insert(selDbIds, v.dbid)
				local cardCsv = csv.cards[v.id]
				if v.rarity >= 3 or v.star > cardCsv.star then
					table.insert(topRarity, i)
				end
				if v.star > cardCsv.star then
					isTopStar = true
					content = gLanguageCsv.higherStarContinueDecomposition
				end
				if v.rarity >= 3 then
					isTopRarity = true
				end
			end
		end
		if count == 5 then
			break
		end
	end
	if (isTopStar and isTopRarity) then
		content = gLanguageCsv.hasRarityAndStarCard
	end
	if itertools.size(selTab) == 0 then
		gGameUI:showTip(gLanguageCsv.noSpriteToDecompose)
		return
	end
	self.decomposePosState = {}
	self.decomposeIds:set(selTab, true)
	if #topRarity > 0 then
		local params = {
			closeCb = function()
				self.decomposeIds:modify(function(oldval)
					for _,v in ipairs(topRarity) do
						oldval[v] = nil
					end
					return true, oldval
				end, true)
			end,
			btnType = 2,
			content = content,
		}
		gGameUI:showDialog(params)
	end
end

function CardRebirthView:onCancel(idx)
	local k = self.decomposePosState[idx]
	if self.decomposePosState[idx] then
		self.decomposePosState[idx] = 0
	end
	self.decomposeIds:modify(function(oldval)
		if oldval[k] then
			oldval[k] = nil
		end
		return true, oldval
	end, true)
end

function CardRebirthView:onSetHeldItemDbId(data)
	self.heldItemId:set(data.dbId)
end


--选择携带道具
function CardRebirthView:onShowHeldItem()
	if self.pageIdx:read() == 3 then
		gGameUI:stackUI("city.card.rebirth.choose_helditem", nil, nil, {handlers = self:createHandler("onSetHeldItemDbId")})
	end

end

--重生
function CardRebirthView:onSure()
	local pageIdx = self.pageIdx:read()
	local itemNum = self.itemDatas:size()
	local function sure()
		--是否有高稀有度精灵 用于分解
		-- local haveHighRarity = false
		if itemNum == 0 then
			local str = gLanguageCsv.cantRebirth
			if (pageIdx == 1 and not self.dbId:read()) or pageIdx == 2  then
				str = gLanguageCsv.notSelRole
			elseif pageIdx == 3 then
				str = gLanguageCsv.notSelHeldItem
				if self.heldItemId:read() ~= nil then
					str = gLanguageCsv.heldItemCanotRebirth
				end
			elseif pageIdx == 4 then
				str = gLanguageCsv.selectGem
			end
			gGameUI:showTip(str)
			return
		end
		if self.cost:read() > 0 and self.cost:read() > self.rmb:read() then
			uiEasy.showDialog("rmb")
			return
		end
		local val = self.rebirthData[pageIdx].getUrlParams()

		local function cb()
			local showOver = {false}
			gGameApp:requestServerCustom(val.url)
				:params(val.params)
				:onResponse(function (tb)
					local effect = val.parent:getChildByName("effect")
					if val.isEffect then
						if effect then
							effect:xy(val.pos)
							effect:show()
							effect:play("effect")
						else
							effect = widget.addAnimationByKey(val.parent, "effect/chongsheng.skel", "effect", "effect", 100)
								:xy(val.pos)
								:scale(val.scale)
						end

						performWithDelay(self, function ()
							effect:hide()
							if val.afterRequest then
								val.afterRequest()
							end
							showOver[1] = true
						end, 25/30)
					else
						if val.afterRequest then
							val.afterRequest()
						end
						showOver[1] = true
					end
				end)
				:wait(showOver)
				:doit(function (tb)
					gGameUI:showGainDisplay(tb)
				end)
		end
		--复选框状态
		local state = userDefault.getForeverLocalKey("cardRebirthTip", false)
		if pageIdx == 2 and state and not val.haveHighRarity then
			cb()
		else
			local params = {
				cb = cb,
				isRich = true,
				btnType = 2,
				content = val.str,
			}
			if self.cost:read() > 0 and self.cost:read() < self.rmb:read() then
				local paramsCb = params.cb
				local function cb()
					dataEasy.sureUsingDiamonds(paramsCb, self.cost:read())
				end
				params.cb = cb
			end
			gGameUI:showDialog(params)
		end
	end

	--当道具超出上限时是否继续分解
	local itemExceed = {}
	local items = self.items:read()
	local itemCsv = csv.items
	local canGetItems = pageIdx ~= 2 and self.canRebirthGetItems or pageIdx == 2 and self.canDecomposeIdsGetItems
	for k, v in ipairs(canGetItems) do
		if type(v.key) == "number" and itemCsv[v.key] then
			local count = items[v.key] or 0
			if v.val + count > itemCsv[v.key].stackMax then
				table.insert(itemExceed, {val = count + v.val - itemCsv[v.key].stackMax, key = v.key})
			end
		end
	end
	if #itemExceed > 0 then
		table.sort(itemExceed, function(a, b)
			return a.val > b.val
		end)
		local strItemsName = ""
		--超过3个之后加上等
		for k, v in ipairs(itemExceed) do
			if k == 4 then
				strItemsName = strItemsName.."..."
				break
			elseif k == 1 then
				strItemsName = strItemsName.."#C0xE77422#"..itemCsv[v.key].name.."#C0x5b545b#"
			else
				strItemsName = strItemsName.."#C0xE77422#,"..itemCsv[v.key].name.."#C0x5b545b#"
			end
		end
		local content = ""
		if pageIdx ~= 2 then
			content = string.format("#C0x5b545b#"..gLanguageCsv.itemRebirthExceed, strItemsName)
		else
			content = string.format("#C0x5b545b#"..gLanguageCsv.itemDecomposeIdsExceed, strItemsName)
		end
		gGameUI:showDialog({content = content, delayTime = 5, cb = function()
			sure()
		end, btnType = 2, isRich = true, dialogParams = {clickClose = false}})
	else
		sure()
	end

end
--选择卡牌分解提示
function CardRebirthView:onSelectTipBtn()
	local state = userDefault.getForeverLocalKey("cardRebirthTip", false)
	self.selectTipBtn:get("checkBox"):setSelectedState(not state)
	userDefault.setForeverLocalKey("cardRebirthTip", not state)
end

--选择卡牌分解模式
function CardRebirthView:onDecSelectTipBtn()
	local state = userDefault.getForeverLocalKey("cardRebirthSelcetTip", false)
	self.decSelectTipBtn:get("checkBox"):setSelectedState(not state)
	userDefault.setForeverLocalKey("cardRebirthSelcetTip", not state)
end

function CardRebirthView:onRuleShow()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function CardRebirthView:getRuleContext(view)
	local pageIdx = self.pageIdx:read()
	local content = RULECONTENT[pageIdx]
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(RULETITLE[pageIdx])
		end),
		c.noteText(unpack(content)),
	}
	return context
end

function CardRebirthView:onJumpToShop()
	if not dataEasy.isUnlock(gUnlockCsv.fragmentShop) then
		gGameUI:showTip(gLanguageCsv.shopNotOpen)
		return
	end
	if not gGameUI:goBackInStackUI("city.shop") then
		gGameApp:requestServer("/game/frag/shop/get", function(tb)
			gGameUI:stackUI("city.shop", nil, {full = true}, game.SHOP_INIT.FRAG_SHOP)
		end)
	end
end

function CardRebirthView:onGemClick(list, node, panel, k, v, event)
	local selected = not v.selected
	local cb = function()
		if not selected then
			for i = #self.selectGems, 1, -1 do
				if self.selectGems[i] == v.dbid then
					table.remove(self.selectGems, i)
					self:updateGemCost()
					break
				end
			end
		else
			table.insert(self.selectGems, v.dbid)
			self:updateGemCost()
		end
		local t = list:getIdx(k)
		self.gems:atproxy(t.k).selected = selected
		audio.playEffectWithWeekBGM("circle.mp3")
	end

	local key = "rebirthGemTip"
	local state = userDefault.getCurrDayKey(key, "first")
	if state == "first" then
		state = "true"
		userDefault.setCurrDayKey(key, state)
	end
	if (state == "first" or state == "true") and (selected and v.isEquipped) then
		local txt = uiEasy.getCardName(v.cardDbID)
		local str = string.format(gLanguageCsv.inlayCard, txt)
		gGameUI:showDialog({
			cb = cb,
			isRich = true,
			btnType = 2,
			content = str,
			selectKey = key,
			selectType = 2,
			selectTip = gLanguageCsv.todayNoTip,
		})
	else
		cb()
	end
end

function CardRebirthView:updateGemCost()
	local items, cost = RebirthTools.getReturnItemsGem(self.selectGems)
	self:initRightData(items,cost)
	self:refreshUI()
end

function CardRebirthView:updateChipCost()
	local list = {}
	for dbid, sign in pairs(self.selectChips) do
		if sign then
			table.insert(list, dbid)
		end
	end
	local items, cost = RebirthTools.getReturnItemsChip(list)
	self:initRightData(items,cost)
	self:refreshUI()
end


function CardRebirthView:onItemTouchShow(list, node, t, v)
	local pos = node:convertToWorldSpaceAR(cc.p(100, 0))
	gGameUI:stackUI('city.card.chip.details', nil, {dispatchNodes = self.strengthenPanel, clickClose = true}, {
		dbId = v.dbid,
		pos = pos,
		align ="right",
		justShow = true,
		dataRefresh = function()
			self:updateChips()
			self:updateChipCost()
		end,
	})
end


-- 点击芯片操作
function CardRebirthView:onChipClick(list, node, t, v, event)
	if event.name == "began" then
		self.touchBeganPos = event
		self.isClicked = true
		self.itemTouchShow = false
		if self.sequence then
			self:stopAction(self.sequence)
		end
		self.chipSubList:setTouchEnabled(true)
		self.sequence = cc.Sequence:create(cc.DelayTime:create(0.3), cc.CallFunc:create(function()
			if v.type ~= "item" then
				self.itemTouchShow = true
				self:onItemTouchShow(list, node, t, v)
				self.chipSubList:setTouchEnabled(false)
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
				local selected = not v.selected
				local cb = function()

					self.selectChips[v.dbid] = selected
					self:updateChipCost()

					self.chips:atproxy(t.k).selected = selected

					audio.playEffectWithWeekBGM("circle.mp3")
				end

				local key = "rebirthChipTip"
				local state = userDefault.getCurrDayKey(key, "first")
				if state == "first" then
					state = "true"
					userDefault.setCurrDayKey(key, state)
				end
				if (state == "first" or state == "true") and (selected and v.isEquipped) then
					local txt = uiEasy.getCardName(v.cardDbID)
					local str = string.format(gLanguageCsv.inlayCard, txt)
					gGameUI:showDialog({cb = cb,
						isRich = true,
						btnType = 2,
						content = str,
						selectKey = key,
						selectType = 2,
						selectTip = gLanguageCsv.todayNoTip,
					})
				else
					cb()
				end
			end
		end
	end
end

function CardRebirthView:onClose()
	if self.cardsChanged then
		self.cardsChanged:notify()
	end
	ViewBase.onClose(self)
end

return CardRebirthView