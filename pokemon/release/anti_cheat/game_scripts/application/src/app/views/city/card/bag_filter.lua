local CardBagFilterView = class("CardBagFilterView", cc.load("mvc").ViewBase)

-- return : res, isAll
local function getAttrData(index)
	local qbRes = ""
	if not index then
		local t = clone(ui.ATTR_ICON)
		table.insert(t, qbRes)
		return t
	end
	return (ui.ATTR_ICON[index] or qbRes), not ui.ATTR_ICON[index]
end

-- return : res, isAll
local function getRarityData(index)
	local qbRes = ""
	if not index then
		local t = clone(ui.RARITY_ICON)
		t[table.maxn(t) + 1] = qbRes
		return t
	end
	return (ui.RARITY_ICON[index] or qbRes), not ui.RARITY_ICON[index]
end

CardBagFilterView.RESOURCE_FILENAME = "card_bag_filter.json"
CardBagFilterView.RESOURCE_BINDING = {
	["filterBtn"] = "filterBtn",
	["filterBtn.btn"] = "selBtn",
	["filterBtn.btn.title"] = {
		varname = "btnTitle",
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
	["filterBtn.filterPanel"] = {
		varname = "filterPanel",
		binds = {
			event = "visible",
			idler = bindHelper.self("showfilterPanel"),
		},
	},
	["filterBtn.filterPanel.cancle"] = {
		varname = "cancleBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onCancleClick")}
		},
	},
	["filterBtn.filterPanel.cancle.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
	["filterBtn.filterPanel.sure"] = {
		varname = "sureBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSureClick")}
		},
	},
	["filterBtn.filterPanel.sure.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
	["filterBtn.filterPanel.attr1Btn"] = {
		varname = "attr1Btn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAttr1Click")}
		},
	},
	["filterBtn.filterPanel.attr2Btn"] = {
		varname = "attr2Btn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAttr2Click")}
		},
	},
	["filterBtn.filterPanel.rarityBtn"] = {
		varname = "rarityBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRarityClick")}
		},
	},
	["filterBtn.filterPanel.atk1Btn"] = {
		varname = "atk1Btn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onAtkClick(game.ATTRDEF_ENUM_TABLE.damage)
			end)}
		},
	},
	["filterBtn.filterPanel.atk2Btn"] = {
		varname = "atk2Btn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onAtkClick(game.ATTRDEF_ENUM_TABLE.specialDamage)
			end)}
		},
	},
	["closePanel"] = {
		varname = "closePanel",
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("showfilterPanel"),
			}, {
				event = "touch",
				methods = {ended = bindHelper.self("onClosePanel")}
			},
		},
	},
	["filterBtn.attrListPanel.item"] = "attrItem",
	["filterBtn.attrListPanel.subList"] = "attrSubList",
	["filterBtn.attrListPanel"] = {
		varname = "attrListPanel",
		binds = {
			event = "visible",
			idler = bindHelper.self("showAttrList"),
		},
	},
	["filterBtn.attrListPanel.list"] = {
		varname = "attrList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("attrDatas"),
				columnSize = 6,
				item = bindHelper.self("attrSubList"),
				cell = bindHelper.self("attrItem"),
				onCell = function(list, node, k, v)
					node:get("icon"):texture(v.icon)
					local t = list:getIdx(k)
					node:onClick(functools.partial(list.itemClick, t, v))
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onAttrItemClick"),
			},
		},
	},

	["filterBtn.attrListPanel.allBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onAttrItemClick(nil, {k = ui.ATTR_MAX})
			end)}
		},
	},
	["filterBtn.rarityListPanel.item"] = "rarityItem",
	["filterBtn.rarityListPanel.subList"] = "raritySubList",
	["filterBtn.rarityListPanel"] = {
		varname = "rarityListPanel",
		binds = {
			event = "visible",
			idler = bindHelper.self("showRarityList"),
		},
	},
	["filterBtn.rarityListPanel.allBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSelectedAll")},
		},
	},
	["filterBtn.rarityListPanel.list"] = {
		varname = "rarityList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("rarityDatas"),
				columnSize = 4,
				item = bindHelper.self("raritySubList"),
				cell = bindHelper.self("rarityItem"),
				onCell = function(list, node, k, v)
					local path = getRarityData(v.rarity)
					node:get("icon"):texture(path)
					node:onClick(functools.partial(list.itemClick, list:getIdx(k), v))
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onRarityItemClick"),
			},
		},
	},
}

-- ?????????1????????????2
function CardBagFilterView:onCreate(params)
	self.cb = params.cb
	if params.showIdler then
		self.showIdler = params.showIdler()
	end

	local others = params.others or {}
	local width = others.width
	local height = others.height
	local x = others.x
	local y = others.y
	local scale = others.scale
	local btn = others.btn
	local panelOrder = others.panelOrder or false
	local panelOffsetX = others.panelOffsetX or 760
	local panelOffsetY = others.panelOffsetY or 0
	if width and height then
		self.selBtn:size(width, height)
		self.btnTitle:xy(width/2, height/2)
	end
	if scale then
		self.selBtn:scale(scale)
	end
	if x then
		self.filterBtn:xy(x, y)
	end
	if btn then
		self.selBtn:visible(false)
		self.selBtn = btn
	end
	if panelOrder then
		local panelY = self.filterPanel:y()
		local filterPanelY = 120 - panelOffsetY
		self.filterPanel:xy(panelOffsetX, filterPanelY)
		self.attrListPanel:xy(panelOffsetX, filterPanelY + self.attrListPanel:y() - panelY)
		self.rarityListPanel:xy(panelOffsetX, filterPanelY + self.rarityListPanel:y() - panelY)
	end
	if others.subPanelOrder then
		self.attrListPanel:y(self.attrListPanel:y() - 100 - self.attrListPanel:height())
		self.rarityListPanel:y(self.rarityListPanel:y() - 60 - self.rarityListPanel:height())
	end
	self.attr12Choose = 1--1?????????????????????1

	self.attr1 = idler.new(ui.ATTR_MAX)--???????????????
	self.attr2 = idler.new(ui.ATTR_MAX)--???????????????
	self.rarity = idler.new(ui.RARITY_LAST_VAL) --??????
	-- ??????/????????????
	self.atkType = idlertable.new({
		[game.ATTRDEF_ENUM_TABLE.damage] = true,
		[game.ATTRDEF_ENUM_TABLE.specialDamage] = true,
	})

	self.attrDatas = arraytools.map(ui.ATTR_ICON, function(i, v) return {icon = v} end)
	self.rarityDatas = ui.RARITY_DATAS

	self.showAttrList = idler.new(false)--??????????????????
	self.showRarityList = idler.new(false)--?????????????????????
	self.showfilterPanel = idler.new(false)--????????????

	idlereasy.when(self.attr1, function(_, attr1)
		local path, isAll = getAttrData(attr1)
		if isAll then
			self.attr1Btn:get("img1"):hide()
			self.attr1Btn:get("all"):show()
		else
			self.attr1Btn:get("img1"):show():texture(path)
			self.attr1Btn:get("all"):hide()
		end
	end)
	idlereasy.when(self.attr2, function(_, attr2)
		local path, isAll = getAttrData(attr2)
		if isAll then
			self.attr2Btn:get("img1"):hide()
			self.attr2Btn:get("all"):show()
		else
			self.attr2Btn:get("img1"):show():texture(path)
			self.attr2Btn:get("all"):hide()
		end
	end)

	idlereasy.when(self.rarity, function(_, rarity)
		local path, isAll = getRarityData(rarity)
		if isAll then
			self.rarityBtn:get("img1"):hide()
			self.rarityBtn:get("all"):show()
		else
			self.rarityBtn:get("img1"):show():texture(path)
			self.rarityBtn:get("all"):hide()
		end
	end)

	idlereasy.when(self.atkType, function(_, flag)
		self.atk1Btn:get("checkBox"):setSelectedState(flag[game.ATTRDEF_ENUM_TABLE.damage])
		self.atk2Btn:get("checkBox"):setSelectedState(flag[game.ATTRDEF_ENUM_TABLE.specialDamage])
	end)

	bind.touch(self, self.selBtn, {methods = {ended = function()
		self:onFilterClick()
	end}})

	self:initData()
end

function CardBagFilterView:initData()
	self.attr1:set(ui.ATTR_MAX)--???????????????
	self.attr2:set(ui.ATTR_MAX)--???????????????
	self.rarity:set(ui.RARITY_LAST_VAL) --??????
	-- ??????/????????????
	self.atkType:set({
		[game.ATTRDEF_ENUM_TABLE.damage] = true,
		[game.ATTRDEF_ENUM_TABLE.specialDamage] = true,
	}, true)
	-- ????????????????????????
	self:onSureClick()
end

--????????????panel
function CardBagFilterView:onClosePanel()
	itertools.invoke({self.showAttrList, self.showRarityList, self.showfilterPanel}, "set", false)
end

--??????item??????
function CardBagFilterView:onAttrItemClick(list, t, v)
	if self.attr12Choose == 1 then
		self.attr1:set(t.k)
	else
		self.attr2:set(t.k)
	end
	self.showAttrList:set(false)
end

function CardBagFilterView:onSelectedAll()
	self.rarity:set(table.maxn(getRarityData()))
	self.showRarityList:set(false)
end

--?????????item??????
function CardBagFilterView:onRarityItemClick(list, t, v)
	self.rarity:set(v.rarity)
	self.showRarityList:set(false)
end

--??????1??????????????????
function CardBagFilterView:onAttr1Click()
	self.showRarityList:set(false)
	local flag = self.showAttrList:read()
	if not flag then
		self.attr12Choose = 1
		self.showAttrList:set(true)
		return
	end
	self.showAttrList:set(false)
end

--??????2??????????????????
function CardBagFilterView:onAttr2Click()
	self.showRarityList:set(false)
	local flag = self.showAttrList:read()
	if not flag then
		self.attr12Choose = 2
		self.showAttrList:set(true)
		return
	end
	self.showAttrList:set(false)
end
--???????????????????????????
function CardBagFilterView:onRarityClick()
	self.showAttrList:set(false)
	self.showRarityList:modify(function(val)
		return true, not val
	end)
end

--????????????
function CardBagFilterView:onCancleClick()
	self:onClosePanel()
end

--????????????, ??????????????????????????????
function CardBagFilterView:onSureClick()
	self.cb(self.attr1:read(), self.attr2:read(), self.rarity:read(), self.atkType:read())
	self:onClosePanel()
end

--??????????????????
function CardBagFilterView:onFilterClick()
	if self.showIdler then
		self.showIdler:set(false)
	end
	itertools.invoke({self.showAttrList, self.showRarityList}, "set", false)
	self.showfilterPanel:modify(function(val)
		return true, not val
	end)
end

-- ???????????????7????????? 8??????
function CardBagFilterView:onAtkClick(flag)
	self.atkType:modify(function(val)
		val[flag] = not val[flag]
		return true, val
	end)
end

return CardBagFilterView