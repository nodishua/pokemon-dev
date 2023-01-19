-- @desc: 公会专用 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiGemDrawView = class("TopuiGemDrawView", TopuiBase)

TopuiGemDrawView.RESOURCE_FILENAME = "topui_gem_draw.json"
TopuiGemDrawView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.goldGem,
	config.rmbGem
})

function TopuiGemDrawView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

function TopuiGemDrawView:onGoldGemClick()
	self:buyTickets('goldGem', 'gold')
end

function TopuiGemDrawView:onRmbGemClick()
	self:buyTickets('rmbGem', 'rmb')
end

return TopuiGemDrawView