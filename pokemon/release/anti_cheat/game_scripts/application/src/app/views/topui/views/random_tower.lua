-- @desc: 公会专用 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiRandomTowerView = class("TopuiRandomTowerView", TopuiBase)

TopuiRandomTowerView.RESOURCE_FILENAME = "topui_random_tower.json"
TopuiRandomTowerView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.randomTower,
})

function TopuiRandomTowerView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiRandomTowerView