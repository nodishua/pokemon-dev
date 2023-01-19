-- @desc: 跨服石英 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiCrossMineView = class("TopuiCrossMineView", TopuiBase)

TopuiCrossMineView.RESOURCE_FILENAME = "topui_cross_mine.json"
TopuiCrossMineView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.crossMine,
})

function TopuiCrossMineView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
	self.sign = params.sign
end

return TopuiCrossMineView