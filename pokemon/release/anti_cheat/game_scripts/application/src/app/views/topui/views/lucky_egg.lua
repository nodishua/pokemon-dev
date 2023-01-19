-- @desc: 饰品商店专用 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiLuckyEggView = class("TopuiLuckyEggView", TopuiBase)

TopuiLuckyEggView.RESOURCE_FILENAME = "topui_drawcard_lucky_egg.json"
TopuiLuckyEggView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.luckyEgg,
})

function TopuiLuckyEggView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiLuckyEggView