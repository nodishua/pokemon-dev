-- @desc: 商店pvp topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiCraftView = class("TopuiCraftView", TopuiBase)

TopuiCraftView.RESOURCE_FILENAME = "topui_craft.json"
TopuiCraftView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.craft,
})

function TopuiCraftView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiCraftView