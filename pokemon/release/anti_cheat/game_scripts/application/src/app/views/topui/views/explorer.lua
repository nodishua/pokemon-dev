-- @desc: 寻宝专用 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiExplorerView = class("TopuiExplorerView", TopuiBase)

TopuiExplorerView.RESOURCE_FILENAME = "topui_explorer.json"
TopuiExplorerView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.explorer,
})

function TopuiExplorerView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiExplorerView