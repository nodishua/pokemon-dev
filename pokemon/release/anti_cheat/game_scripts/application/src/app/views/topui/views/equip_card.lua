-- @desc: 饰品抽卡专用 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiEquipCardView = class("TopuiEquipCardView", TopuiBase)

TopuiEquipCardView.RESOURCE_FILENAME = "topui_drawcard_equip.json"
TopuiEquipCardView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.equipCard,
})

function TopuiEquipCardView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiEquipCardView