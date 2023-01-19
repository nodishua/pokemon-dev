-- @date:   2021-04-08
-- @desc:   z觉醒一键重置界面

local zawakeTools = require "app.views.city.zawake.tools"
local ViewBase = cc.load("mvc").ViewBase
local ZawakeResetView = class("ZawakeResetView", Dialog)

ZawakeResetView.RESOURCE_FILENAME = "zawake_reset.json"
ZawakeResetView.RESOURCE_BINDING = {
	["btnReset"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onResetClick")}
		}
	},
	["titile"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(251, 110, 70, 255), size = 8}}
		}
	},
	["tip"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE, size = 3}}
		}
	},
	["item"] = "item",
	["innerList"] = "innerList",
	["list"] = {
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("innerList"),
				cell = bindHelper.self("item"),
				columnSize = 8,
				onCell = function(list, node, k, v)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.val,
							},
						},
					})
				end,
			},
		},
	},
	["costPanel"] = "costPanel",
	["costPanel.txt1"] = "txt1",
	["costPanel.cost"] = "cost",
	["costPanel.icon"] = "icon",
}

function ZawakeResetView:onCreate(zawakeID)
	Dialog.onCreate(self)
	self.zawakeID = zawakeID
	local zawakeData = gGameModel.role:read("zawake")[zawakeID]
	local costDatas = zawakeTools.getResetCostItems(zawakeID, zawakeData)
	self.costDatas = costDatas
	local datas = {}
	for k, val in pairs(costDatas) do
		table.insert(datas, {key = k, val = val})
	end
	self.attrDatas = idlers.newWithMap(datas)
	self.cost:text(gCommonConfigCsv.zawakeResetOneKeyCost)
	local size = self.costPanel:size()
	adapt.oneLineCenterPos(cc.p(size.width/2, size.height/2), {self.txt1, self.cost, self.icon}, {cc.p(0, 0), cc.p(10, 0)})
end

function ZawakeResetView:onResetClick()
	if gGameModel.role:read("rmb") < gCommonConfigCsv.zawakeResetOneKeyCost then
		uiEasy.showDialog("rmb")
		return
	end
	gGameUI:showDialog({
		content = string.format(gLanguageCsv.zawakeResetDialagTips, gCommonConfigCsv.zawakeResetOneKeyCost),
		cb = function()
			self:sendReset()
		end,
		isRich = true,
		btnType = 2,
		dialogParams = {clickClose = false},
	})
end

function ZawakeResetView:sendReset()
	gGameApp:requestServer("/game/card/zawake/reset", function(tb)
		gGameUI:showGainDisplay(self.costDatas, {cb = function () self:onClose() end})
	end, self.zawakeID)
end

return ZawakeResetView