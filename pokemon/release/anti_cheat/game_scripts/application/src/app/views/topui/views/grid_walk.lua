-- @desc: 走格子 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiGridWalkView = class("TopuiGridWalkView", TopuiBase)

TopuiGridWalkView.RESOURCE_FILENAME = "topui_grid_walk.json"
TopuiGridWalkView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.gridWalk,
})

function TopuiGridWalkView:onCreate(params)
	self.iconNum = params.iconNum
	TopuiBase.onCreate(self, {"title"}, params)
	self.items = gGameModel.role:getIdler("items")
	idlereasy.any({self.iconNum}, function (_, iconNum)
		local num = math.max(iconNum, 0)
		self.num1:text(mathEasy.getShortNumber(num, 2))
	end)
end

return TopuiGridWalkView