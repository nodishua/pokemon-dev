-- @desc: 公会专用 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiFragmentView = class("TopuiFragmentView", TopuiBase)

TopuiFragmentView.RESOURCE_FILENAME = "topui_fragment.json"
TopuiFragmentView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.fragment,
})

function TopuiFragmentView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiFragmentView