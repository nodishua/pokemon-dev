-- @desc: 商店pvp topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiChipView = class("TopuiChipView", TopuiBase)

TopuiChipView.RESOURCE_FILENAME = "topui_chip.json"
TopuiChipView.RESOURCE_BINDING = maptools.extend({
	config.rightTopPanel,
	config.title,
	config.gold,
	config.diamond,
	config.chip,
})

function TopuiChipView:onCreate(params)
	self.rightTopPanel:get("coin8Panel.btnAdd"):hide()
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiChipView