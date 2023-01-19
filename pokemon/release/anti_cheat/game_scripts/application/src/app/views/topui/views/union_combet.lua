-- @desc: 商店公会战 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiUnionCombetView = class("TopuiUnionCombetView", TopuiBase)

TopuiUnionCombetView.RESOURCE_FILENAME = "topui_union_combet.json"
TopuiUnionCombetView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.union_combet,
})

function TopuiUnionCombetView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiUnionCombetView