-- @desc: 饰品商店专用 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiDrawCardShopView = class("TopuiDrawCardShopView", TopuiBase)

TopuiDrawCardShopView.RESOURCE_FILENAME = "topui_drawcard.json"
TopuiDrawCardShopView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.drawcard,
})

function TopuiDrawCardShopView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiDrawCardShopView