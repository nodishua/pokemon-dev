-- @desc: 主城专用 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiCityView = class("TopuiCityView", TopuiBase)

TopuiCityView.RESOURCE_FILENAME = "topui_city.json"
TopuiCityView.RESOURCE_BINDING = maptools.extend({
	config.gold,
	config.diamond,
	config.stamina,
})


function TopuiCityView:onCreate()
	TopuiBase.onCreate(self, {"stamina"})
end

return TopuiCityView


