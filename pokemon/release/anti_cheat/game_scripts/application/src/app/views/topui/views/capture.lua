-- @desc: 捕捉界面专用 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiCaptureView = class("TopuiCaptureView", TopuiBase)

TopuiCaptureView.RESOURCE_FILENAME = "topui_capture.json"
TopuiCaptureView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.capture,
})

function TopuiCaptureView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
	self.items = gGameModel.role:getIdler("items")
	idlereasy.when(self.items, function (_, items)
		self.num1:text(mathEasy.getShortNumber(items[game.SPRITE_BALL_ID.normal] or 0, 2))
		self.num2:text(mathEasy.getShortNumber(items[game.SPRITE_BALL_ID.hero] or 0, 2))
		self.num3:text(mathEasy.getShortNumber(items[game.SPRITE_BALL_ID.nightmare] or 0, 2))
	end)
end

return TopuiCaptureView