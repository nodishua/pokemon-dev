-- @desc: 跨服石英 topui

local config = require("app.views.topui.config")
local TopuiBase = require("app.views.topui.base")
local TopuiCrossArenaView = class("TopuiCrossArenaView", TopuiBase)

TopuiCrossArenaView.RESOURCE_FILENAME = "topui_cross_arena.json"
TopuiCrossArenaView.RESOURCE_BINDING = maptools.extend({
	config.title,
	config.gold,
	config.diamond,
	config.crossArena,
})

function TopuiCrossArenaView:onCreate(params)
	TopuiBase.onCreate(self, {"title"}, params)
end

return TopuiCrossArenaView