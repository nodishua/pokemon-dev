-- @desc: 公会专用 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiUnionView = class("TopuiUnionView", TopuiBase)

TopuiUnionView.RESOURCE_FILENAME = "topui_union.json"
TopuiUnionView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.union,
})

function TopuiUnionView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiUnionView