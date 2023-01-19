-- @desc: 通用提示框

local ViewBase = cc.load("mvc").ViewBase
local unionAnswerTipsView = class("unionAnswerTipsView", Dialog)

unionAnswerTipsView.RESOURCE_FILENAME = "union_answer_tips.json"
unionAnswerTipsView.RESOURCE_BINDING = {
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

}

function unionAnswerTipsView:onCreate(params)
	self:enableSchedule()
	params = params or {}
	self._okcb = params.cb
	self._closecb = params.closeCb
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
		end
		counTtime = counTtime - 1
	end, 1, 0, "countdownLess")

	Dialog.onCreate(self, dialogParams)
end

function unionAnswerTipsView:onClickOK()
	self:addCallbackOnExit(self._okcb)
	Dialog.onClose(self)
	return self
end

-- function unionAnswerTipsView:onCancel()
-- 	self:addCallbackOnExit(self._cancelcb)
-- 	self:onClose()
-- end

function unionAnswerTipsView:onClose()
	self:addCallbackOnExit(self._closecb)
	Dialog.onClose(self)
end

return unionAnswerTipsView