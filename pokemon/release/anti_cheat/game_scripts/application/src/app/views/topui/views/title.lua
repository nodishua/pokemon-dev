-- @desc: 只含有标题的 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiTitleView = class("TopuiTitleView", TopuiBase)

TopuiTitleView.RESOURCE_FILENAME = "topui_default.json"
TopuiTitleView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.rightTopPanel,
})

function TopuiTitleView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)

	self.rightTopPanel:hide()
end

return TopuiTitleView