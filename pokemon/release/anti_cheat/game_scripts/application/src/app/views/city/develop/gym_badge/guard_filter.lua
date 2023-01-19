local CardGuardFilterView = class("CardGuardFilterView", cc.load("mvc").ViewBase)

local ATTR_MAX = #ui.ATTR_ICON + 1
--选择全部时的下标
local RARITY_LAST_VAL = table.maxn(ui.RARITY_ICON) + 1
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

CardGuardFilterView.RESOURCE_FILENAME = "gym_badge_filter.json"
CardGuardFilterView.RESOURCE_BINDING = {
	["filterBtn"] = "filterBtn",
	["filterBtn.btn"] = {
		varname = "selBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onFilterClick")}
		},
	},
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
				return view:onAttrItemClick(nil, {k = ATTR_MAX})
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

-- 精灵是1，碎片是2
function CardGuardFilterView:onCreate(params)
	self.cb = params.cb
	if params.showIdler then
		self.showIdler = params.showIdler()
	end

	local others = params.others or {}
	local width = others.width
	local height = others.height
	local x = others.x
	local y = others.y
	local panelOrder = others.panelOrder or false
	self.selBtn:xy(250, -125)
	if panelOrder then
		self.filterPanel:xy(335, -1093)
		self.attrListPanel:xy(348, -736)
		self.rarityListPanel:xy(351, -652)
	end
	self.attr12Choose = 1--1表示选中了属性1

	self.attr1 = idler.new(ATTR_MAX)--第一个属性
	self.attr2 = idler.new(ATTR_MAX)--第二个属性
	self.rarity = idler.new(RARITY_LAST_VAL) --品级
	-- 物攻/特攻选中
	self.atkType = idlertable.new({
		[game.ATTRDEF_ENUM_TABLE.damage] = true,
		[game.ATTRDEF_ENUM_TABLE.specialDamage] = true,
	})

	self.attrDatas = arraytools.map(ui.ATTR_ICON, function(i, v) return {icon = v} end)
	self.rarityDatas = ui.RARITY_DATAS

	self.showAttrList = idler.new(false)--属性筛选界面
	self.showRarityList = idler.new(false)--稀有度筛选界面
	self.showfilterPanel = idler.new(false)--筛选界面

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

	self:initData()
end

function CardGuardFilterView:initData()
	self.attr1:set(ATTR_MAX)--第一个属性
	self.attr2:set(ATTR_MAX)--第二个属性
	self.rarity:set(RARITY_LAST_VAL) --品级
	-- 物攻/特攻选中
	self.atkType:set({
		[game.ATTRDEF_ENUM_TABLE.damage] = true,
		[game.ATTRDEF_ENUM_TABLE.specialDamage] = true,
	}, true)
	-- 设置外部属性一致
	self:onSureClick()
end

--透明全屏panel
function CardGuardFilterView:onClosePanel()
	itertools.invoke({self.showAttrList, self.showRarityList, self.showfilterPanel}, "set", false)
end

--属性item点击
function CardGuardFilterView:onAttrItemClick(list, t, v)
	if self.attr12Choose == 1 then
		self.attr1:set(t.k)
	else
		self.attr2:set(t.k)
	end
	self.showAttrList:set(false)
end

function CardGuardFilterView:onSelectedAll()
	self.rarity:set(table.maxn(getRarityData()))
	self.showRarityList:set(false)
end

--稀有度item点击
function CardGuardFilterView:onRarityItemClick(list, t, v)
	self.rarity:set(v.rarity)
	self.showRarityList:set(false)
end

--属性1显示面板按钮
function CardGuardFilterView:onAttr1Click()
	self.showRarityList:set(false)
	local flag = self.showAttrList:read()
	if not flag then
		self.attr12Choose = 1
		self.showAttrList:set(true)
		return
	end
	self.showAttrList:set(false)
end

--属性2显示面板按钮
function CardGuardFilterView:onAttr2Click()
	self.showRarityList:set(false)
	local flag = self.showAttrList:read()
	if not flag then
		self.attr12Choose = 2
		self.showAttrList:set(true)
		return
	end
	self.showAttrList:set(false)
end
--稀有度显示面板按钮
function CardGuardFilterView:onRarityClick()
	self.showAttrList:set(false)
	self.showRarityList:modify(function(val)
		return true, not val
	end)
end

--取消筛选
function CardGuardFilterView:onCancleClick()
	self:onClosePanel()
end

--确定筛选, 点击后再进行筛选操作
function CardGuardFilterView:onSureClick()
	self.cb(self.attr1:read(), self.attr2:read(), self.rarity:read(), self.atkType:read())
	self:onClosePanel()
end

--显示筛选界面
function CardGuardFilterView:onFilterClick()
	if self.showIdler then
		self.showIdler:set(false)
	end
	itertools.invoke({self.showAttrList, self.showRarityList}, "set", false)
	self.showfilterPanel:modify(function(val)
		return true, not val
	end)
end

return CardGuardFilterView