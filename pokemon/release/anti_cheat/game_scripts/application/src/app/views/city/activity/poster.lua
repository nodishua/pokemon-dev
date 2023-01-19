-- @Date:   2019-7-9 18:21:21
-- @Desc:	海报界面

local ViewBase = cc.load("mvc").ViewBase
local ActivityPosterView = class("ActivityPosterView", Dialog)
ActivityPosterView.RESOURCE_FILENAME = "activity_poster.json"
ActivityPosterView.RESOURCE_BINDING = {
	["btnClose"] = {
		varname = "btnClose",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["leftPanel"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onCheckBox")
		},
	},
	["leftPanel.checkBox"] = "checkBox",
	["timeNode.activityTime"] = "activityTime",
}

function ActivityPosterView:onCreate(params)
	self.cb = params.cb
	self.state = params.state()

	idlereasy.when(self.state, function (_, state)
		self.checkBox:setSelectedState(state)
	end)

	local pnode = self:getResourceNode()
	ccui.ImageView:create(params.cfg.clientParam.res)
		:alignCenter(pnode:size())
		:scale(2)
		:addTo(pnode)
		:setTouchEnabled(false)

	-- clientParam字段配置
	-- showId 表示需要展示活动截止时间的活动id, countInfo 活动截止时间相关位置信息(包括旋转、x、y坐标)
	local activityId = params.cfg.clientParam.showId
	local countInfo  = params.cfg.clientParam.countInfo
	if params.cfg.clientParam.showId then
		self.activityTime:show()
		local times = string.split(time.getActivityOpenDate(params.cfg.clientParam.showId),"-")
		self.activityTime:text(times[2])
		if countInfo then
			local rotation = countInfo.rotation or 0
			local posX = countInfo.posX or self.activityTime:x()
			local posY = countInfo.posY or self.activityTime:y()
			self.activityTime:setRotation(rotation)
			self.activityTime:x(posX)
			self.activityTime:y(posY)
		end
	else
		self.activityTime:hide()
	end
	-- 关闭按钮样式
	if params.cfg.clientParam.closeButton then
		self.btnClose:loadTextureNormal(params.cfg.clientParam.closeButton)
	end

	Dialog.onCreate(self, {blackType = 1, blackOpacity = 204})
end

function ActivityPosterView:onCheckBox()
	self.state:modify(function(val)
		return true, not val
	end)
end

function ActivityPosterView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

return ActivityPosterView