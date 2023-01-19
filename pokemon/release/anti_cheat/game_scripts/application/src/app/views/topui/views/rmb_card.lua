-- @desc: 钻石抽卡专用 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiRmbCardView = class("TopuiRmbCardView", TopuiBase)

TopuiRmbCardView.RESOURCE_FILENAME = "topui_drawcard_rmb.json"
TopuiRmbCardView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.rmbCard,
})

function TopuiRmbCardView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiRmbCardView