--
--@date 2020-10-14
--@desc 活动boss出现界面
--

local ViewBase = cc.load("mvc").ViewBase
local ActivityBossShowView = class("ActivityBossShowView",ViewBase)

ActivityBossShowView.RESOURCE_FILENAME = "activity_boss_show.json"
ActivityBossShowView.RESOURCE_BINDING = {
	["closePanel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
}

function ActivityBossShowView:onCreate(params)
	gGameUI:disableTouchDispatch(0.5)
end

function ActivityBossShowView:onClose()
	ViewBase.onClose(self)
end

return ActivityBossShowView