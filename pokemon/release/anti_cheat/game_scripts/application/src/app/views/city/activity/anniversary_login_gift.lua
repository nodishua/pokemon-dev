-- @date 2021-3-23
-- @desc 周年庆登录奖励

local ActivityAnniversaryLoginGiftView = class("ActivityAnniversaryLoginGiftView", cc.load("mvc").ViewBase)

ActivityAnniversaryLoginGiftView.RESOURCE_FILENAME = "activity_anniversary_login_gift.json"
ActivityAnniversaryLoginGiftView.RESOURCE_BINDING = {
	["list"] = "list",
	["btn.lable"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnClick")}
		},
	},
}

function ActivityAnniversaryLoginGiftView:onCreate(params)
	print_r(params)
	uiEasy.createItemsToList(self, self.list, params.data, {margin = 20, onAfterBuild = function()
		self.list:setItemAlignCenter()
	end})
	self.cb = params.cb
end

function ActivityAnniversaryLoginGiftView:onBtnClick()
	self:addCallbackOnExit(self.cb)
	self:onClose()
end

return ActivityAnniversaryLoginGiftView