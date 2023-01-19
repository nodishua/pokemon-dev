-- @Date:   2019-04-02
-- @Desc:
-- @Last Modified time: 2019-04-24

local function getAttrData(index)
	if not index then
		local t = clone(ui.ATTR_ICON)
		return t
	end
	return ui.ATTR_ICON[index]
end

local AttrFilterView = class("AttrFilterView", cc.load("mvc").ViewBase)
AttrFilterView.RESOURCE_FILENAME = "common_attr_filter.json"
AttrFilterView.RESOURCE_BINDING = {
	["item"] = "item",
	["subList"] = "subList",
	["btnReset"] = {
		varname = "btnReset",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowAttrPanel")}
		},
	},
	["btnOK"] = {
		varname = "btnOK",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSpecialClose")}
		},
	},
	["list"] = {
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("attrDatas"),
				columnSize = 6,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				onCell = function(list, node, k, v)
					node:show()
					local t = list:getIdx(k)
					node:get("bg"):texture(getAttrData(t.k))
					node:get("name"):text(gLanguageCsv[game.NATURE_TABLE[t.k]])
					node:get("select"):visible(v.state == true)
					node:onClick(functools.partial(list.itemClick, t, v))
				end,
				asyncPreload = 24,
			},
			handlers = {
				itemClick = bindHelper.self("onAttrItemClick"),
			},
		},
	},
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSpecialClose")}
		},
	},
	["closeBtn"] = {
		varname = "closeBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSpecialClose")}
		},
	},
}

-- @desc:
-- @params: {isMultiSelect, selectData, isShow, btnColse} isMultiSelect:是否多选,isShow:该界面是否展示, selectData:选中数据, btnColse返回
-- @return:
function AttrFilterView:onCreate(params)
	self.item:hide()
	local info = params.btnColse and true or false
	self.isMultiSelect = params.isMultiSelect
	self.btnOK:visible(not info)
	self.btnReset:visible(not info)
	self.closeBtn:visible(info)

	self.isShow = params.panelState()
	if self.isMultiSelect then
		self.selectData = params.selectDatas()
		self.attrDatas = self.selectData
	else
		self.selectData = params.selectDatas()
		self.attrDatas = arraytools.map(getAttrData(), function(i, v) return {icon = v} end)
	end
end

function AttrFilterView:onSpecialClose()
	self.isShow:set(false)
end

function AttrFilterView:onAttrItemClick(list, t, v)
	if self.isMultiSelect then
		self.attrDatas:atproxy(t.k).state = not self.attrDatas:atproxy(t.k).state
	else
		self.selectData:set(t.k, true)
		self:onSpecialClose()
	end
end

function AttrFilterView:onShowAttrPanel()
	if self.isMultiSelect then
		local t = {}
		for i = 1, #ui.ATTR_ICON do
			table.insert(t, {state = false})
		end
		self.attrDatas:update(t)
	else
		self.selectData:set(#ui.ATTR_ICON + 1, true)
		self:onSpecialClose()
	end
end

return AttrFilterView