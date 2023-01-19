-- @desc: 钻石抽卡专用 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiLimitCardView = class("TopuiLimitCardView", TopuiBase)

TopuiLimitCardView.RESOURCE_FILENAME = "topui_drawcard_limit.json"
TopuiLimitCardView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.limitCard,
})

function TopuiLimitCardView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiLimitCardView