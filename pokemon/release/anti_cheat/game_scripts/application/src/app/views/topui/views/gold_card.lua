-- @desc: 金币抽卡专用 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiGoldCardView = class("TopuiGoldCardView", TopuiBase)

TopuiGoldCardView.RESOURCE_FILENAME = "topui_drawcard_gold.json"
TopuiGoldCardView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.goldCard,
})

function TopuiGoldCardView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiGoldCardView