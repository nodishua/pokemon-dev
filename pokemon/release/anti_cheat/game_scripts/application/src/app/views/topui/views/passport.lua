-- @desc: 饰品商店专用 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiPassportShopView = class("TopuiPassportShopView", TopuiBase)

TopuiPassportShopView.RESOURCE_FILENAME = "topui_passport.json"
TopuiPassportShopView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.passportCoin,
	config.passportVipCoin,
})

function TopuiPassportShopView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiPassportShopView