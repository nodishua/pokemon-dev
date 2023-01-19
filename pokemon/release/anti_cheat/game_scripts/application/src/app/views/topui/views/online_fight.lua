-- @desc: 实时匹配 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiOnlineFightView = class("TopuiOnlineFightView", TopuiBase)

TopuiOnlineFightView.RESOURCE_FILENAME = "topui_online_fight.json"
TopuiOnlineFightView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.onlineFight,
})

function TopuiOnlineFightView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiOnlineFightView