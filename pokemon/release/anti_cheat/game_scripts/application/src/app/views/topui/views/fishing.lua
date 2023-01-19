-- @desc: 钓鱼 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiFishingView = class("TopuiFishingView", TopuiBase)

TopuiFishingView.RESOURCE_FILENAME = "topui_fishing.json"
TopuiFishingView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.diamond,
	config.fishingGold,
})

function TopuiFishingView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

function TopuiFishingView:onBtnClick()
	gGameUI:stackUI("city.adventure.fishing.sence_select", nil, nil)
end

return TopuiFishingView