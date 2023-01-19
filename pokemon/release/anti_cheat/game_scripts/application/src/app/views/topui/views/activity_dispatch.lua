-- @desc: 派遣活动 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local DispatchTaskView = class("DispatchTaskView", TopuiBase)

DispatchTaskView.RESOURCE_FILENAME = "topui_activity_dispatch.json"
DispatchTaskView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.actionPoint,
})

function DispatchTaskView:onCreate(params)
	local actionPointKey = params.actionPointKey
	TopuiBase.onCreate(self, {"title"}, params)
	self.items = gGameModel.role:getIdler("items")

	idlereasy.when(self.items, function (_, items)
		self.num1:text(mathEasy.getShortNumber(items[actionPointKey] or 0, 2))
	end)
end


return DispatchTaskView