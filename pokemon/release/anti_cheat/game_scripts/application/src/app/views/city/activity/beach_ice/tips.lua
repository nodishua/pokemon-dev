-- @desc: 通用提示框

local STATE_TYPE = {
	closed = 1,
	start = 2,	-- 开始游戏 开始制作之前
	play = 3,	-- 开始制作之后
}
local ViewBase = cc.load("mvc").ViewBase
local BeachIceTipsView = class("BeachIceTipsView", Dialog)

BeachIceTipsView.RESOURCE_FILENAME = "beach_ice_tip.json"
BeachIceTipsView.RESOURCE_BINDING = {
	["title"] = "titleLabel",
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["content"] = "contentLabel",
	["btnOK"] = {
		varname = "btnOK",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClickOK")}
		},
	},
	["btnCancel"] = {
		varname = "btnCancel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["btnOkCenter"] = {
		varname = "btnOkCenter",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClickOK")}
		},
	},
	["btnOkCenter.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["textNum"] = "timeText",
	["text"] = "text",

}

function BeachIceTipsView:onCreate(params)
	self:enableSchedule()
	params = params or {}
	self.params = params
	self._okcb = params.cb
	local counTtime = params.time
	local originX, originY = self.btnOK:getPosition()
	if params.title then
		self.titleLabel:text(params.title)
	end
	local size = self.contentLabel:size()
	self.btnOK:show()
	self.btnCancel:show()

	-- 统一用 beauty.textScroll 处理
	-- self.contentLabel:text(params.content)
	local defaultAlign = "center"
	local list, height = beauty.textScroll({
		size = size,
		fontSize = params.fontSize or 50,
		effect = {color=ui.COLORS.NORMAL.DEFAULT},
		strs = params.content or params.strs,
		verticalSpace = params.verticalSpace or 10,
		isRich = true,
		margin = 20,
		align = params.align or defaultAlign,
	})
	local y = 0
	if height < size.height then
		y = -(size.height - height) / 2
	end
	list:addTo(self.contentLabel,10):y(y)

	local dialogParams = params.dialogParams or {}
	dialogParams.clearFast = dialogParams.clearFast or params.clearFast

	self:enableSchedule():schedule(function()
		self.timeText:text(counTtime)
		if counTtime <= 0 then
			self:unSchedule("countdownLess")
			self:onClickOK()
		end
		counTtime = counTtime - 1
	end, 1, 0, "countdownLess")

	if params.state == STATE_TYPE.start then
		self:unSchedule("countdownLess")
		self.timeText:hide()
		self.text:hide()
	end
	Dialog.onCreate(self, dialogParams)
end

function BeachIceTipsView:onClickOK()
	self:addCallbackOnExit(self._okcb)
	Dialog.onClose(self)
	return self
end

function BeachIceTipsView:onClose()
	Dialog.onClose(self)
end

return BeachIceTipsView