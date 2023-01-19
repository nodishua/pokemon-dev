-- @date 2019-01-11
-- @desc 限时活动海报

local ActivityView = require "app.views.city.activity.view"
local ActivityClientShowView = class("ActivityClientShowView", cc.load("mvc").ViewBase)

ActivityClientShowView.RESOURCE_FILENAME = "activity_client_show.json"
ActivityClientShowView.RESOURCE_BINDING = {
	["img"] = "img",
	["timeLabel"] = "timeLabel",
	["time"] = {
		varname = "time",
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.WHITE}},
		},
	},
	["timeLimit"] = {
		varname = "timeLimit",
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.WHITE}},
		},
	},
	["list"] = "list"
}

function ActivityClientShowView:onCreate(activityID)
	local yyCfg = csv.yunying.yyhuodong[activityID]
	if yyCfg.clientParam.panelImg then
		self.img:texture(yyCfg.clientParam.panelImg)
		local pos = yyCfg.clientParam.panelImgPos
		if pos then
			local x, y = self.img:xy()
			self.img:xy(x+pos.x, y+pos.y)
		end
	end
	if yyCfg.clientParam.isHideDate then
		self.timeLimit:hide()
	else
		self.timeLimit:show():text(time.getActivityOpenDate(activityID))
	end
	beauty.textScroll({
		list = self.list,
		strs = {str = "#C0x5B545B#" .. yyCfg.rDesc, verticalSpace = 21},
		isRich = true,
		fontSize = 42
	})
	ActivityView.setCountdown(self, activityID, self.timeLabel, self.time, {labelChangeCb = function()
		adapt.oneLinePos(self.timeLabel, {self.time, self.timeLimit}, cc.p(15, 0))
	end})
end

return ActivityClientShowView
