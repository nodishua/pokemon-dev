-- @desc: 充值专用 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiRechargeView = class("TopuiRechargeView", TopuiBase)

TopuiRechargeView.RESOURCE_FILENAME = "topui_default.json"
TopuiRechargeView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.stamina,
})

function TopuiRechargeView:onCreate(params)
	TopuiBase.onCreate(self, {"title", "stamina"}, params)
end

function TopuiRechargeView:onDiamondClick()
end

return TopuiRechargeView