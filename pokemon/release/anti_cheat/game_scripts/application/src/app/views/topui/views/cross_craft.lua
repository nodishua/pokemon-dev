-- @desc: 跨服石英 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiCrossCraftView = class("TopuiCrossCraftView", TopuiBase)

TopuiCrossCraftView.RESOURCE_FILENAME = "topui_cross_craft.json"
TopuiCrossCraftView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.crossCraft,
})

function TopuiCrossCraftView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiCrossCraftView