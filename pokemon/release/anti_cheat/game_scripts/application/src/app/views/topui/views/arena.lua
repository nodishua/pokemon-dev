-- @desc: 商店pvp topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiArenaView = class("TopuiArenaView", TopuiBase)

TopuiArenaView.RESOURCE_FILENAME = "topui_arena.json"
TopuiArenaView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.arena,
})

function TopuiArenaView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiArenaView