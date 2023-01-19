-- @date 2021-5-17
-- @desc 学习芯片洗练重置

local ChipAdvanceResetView = class("ChipAdvanceResetView", Dialog)
local ChipTools = require('app.views.city.card.chip.tools')

ChipAdvanceResetView.RESOURCE_FILENAME = "chip_advance_reset.json"
ChipAdvanceResetView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["descList"] = "descList",
	["btnOK"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClickOK")}
		},
	},
	["btnCancel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onCancel")}
		},
	},
	["item"] = "item",
	["subList"] = "subList",
	['list'] = {
		binds = {
			event = 'extend',
			class = 'tableview',
			props = {
				columnSize = 2,
				data = bindHelper.self('resetData'),
				item = bindHelper.self('subList'),
				cell = bindHelper.self('item'),
				onCell = function(list, node, k, v)
					local name = getLanguageAttr(v.key)
					local name = ChipTools.getAttrName(v.key)
					node:get("name"):text(name)
					node:get("value"):text(v.val)
					node:get("arrow"):visible(k%2 == 1)
				end,
			}
		}
	}
}

-- @param params {cb, dbId}
function ChipAdvanceResetView:onCreate(params)
	self.cb = params.cb
	beauty.textScroll({
		list = self.descList,
		strs = string.format(gLanguageCsv.chipAdvanceReset, gCommonConfigCsv.chipResetCost),
		isRich = true,
	})

	self.resetData = {}

	local _, data1 = ChipTools.getAttr(params.dbId, nil, true)
	local chip = gGameModel.chips:find(params.dbId)
	local first = chip:read("first") or {}
	local now = chip:read("now") or {}
	-- data的属性分别是 属性库ID，洗练次数，强化次数

	local data2 = {}
	for k, csvId in ipairs(first) do
		ChipTools.setAttrAddition(data2, csv.chip.libs[csvId], now[k][3], true)
	end

	for i, t1 in ipairs(data1) do
		local key = t1.key
		if not ChipTools.ignoreAttr(key) then
			table.insert(self.resetData, t1)
			table.insert(self.resetData, data2[i])
		end
	end
	Dialog.onCreate(self)
end

function ChipAdvanceResetView:onClickOK()
	self:addCallbackOnExit(self.cb)
	Dialog.onCloseFast(self)
	return self
end

function ChipAdvanceResetView:onCancel()
	self:onClose()
end

return ChipAdvanceResetView