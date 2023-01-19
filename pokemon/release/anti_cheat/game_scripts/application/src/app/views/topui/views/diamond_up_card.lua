-- @desc: 饰品抽卡专用 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiDiamondUpCardView = class("TopuiDiamondUpCardView", TopuiBase)

TopuiDiamondUpCardView.RESOURCE_FILENAME = "topui_drawcard_diamond_up.json"
TopuiDiamondUpCardView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.diamondUpCard,
})

function TopuiDiamondUpCardView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiDiamondUpCardView