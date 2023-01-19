-- @desc: 通用默认 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiDefaultView = class("TopuiDefaultView", TopuiBase)

TopuiDefaultView.RESOURCE_FILENAME = "topui_default.json"
TopuiDefaultView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.stamina,
})

function TopuiDefaultView:onCreate(params)
	TopuiBase.onCreate(self, {"title", "stamina"}, params)
end

return TopuiDefaultView