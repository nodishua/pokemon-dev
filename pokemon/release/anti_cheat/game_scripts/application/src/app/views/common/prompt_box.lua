-- @desc: 通用提示框

local ViewBase = cc.load("mvc").ViewBase
local PromptBoxView = class("PromptBoxView", Dialog)

PromptBoxView.RESOURCE_FILENAME = "common_prompt_box.json"
PromptBoxView.RESOURCE_BINDING = {
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
			methods = {ended = bindHelper.self("onCancel")}
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
	["selectPanel"] = "selectPanel",
	["selectPanel.btn"] = {
		varname = "selectTipBtn",
		binds = {
			event = "click",
			method = bindHelper.self("onSelectTipBtn"),
		},
	},
}

-- @param params {content, title, cb(ok callback), closeCb, cancelCb, strs, isRich, btnType, btnStr, align, fontSize, dialogParams, verticalSpace, clearFast}
-- btnType 按钮类型：1.确定按钮(默认), 2.确定取消按钮；
-- btnStr 确定按钮的文本变动 string for btnOk
-- clearFast 点击确定后会有额外界面的需要快速关闭
-- selectKey 不在弹出提示; selectType 1:(默认，永久)，2:(每日); selectTip: 提示文本
function PromptBoxView:onCreate(params)
	params = params or {}
	self.params = params
	local btnType = params.btnType or 1
	self._okcb = params.cb
	self._closecb = params.closeCb
	self._cancelcb = params.cancelCb
	self.selectKey = params.selectKey
	local originX, originY = self.btnOK:getPosition()
	if params.title then
		self.titleLabel:text(params.title)
	end
	if params.delayTime then
		self.btnOK:setTouchEnabled(false)
		cache.setShader(self.btnOK, false, "hsl_gray")
		local limitTime = params.delayTime
		local text = ccui.Text:create(limitTime, "font/youmi1.ttf", 65)
			:alignCenter(self.btnOK:size())
			:addTo(self.btnOK, 10, "delayTime")
		self:enableSchedule():schedule(function (dt)
			text:text(limitTime)
			limitTime = limitTime - 1
			if limitTime < 0 then
				text:setVisible(false)
				cache.setShader(self.btnOK, false, "normal")
				self.btnOK:setTouchEnabled(true)
			end
		end, 1, 0, "delayTime")
	end
	--自动关闭时间
	if params.closeTime then
		self:enableSchedule():schedule(function (dt)
			if time.getTime() >= params.closeTime  then
				self:enableSchedule():unScheduleAll()
				performWithDelay(self, function()
					self:onClose()
				end, 1/60)
				return false
			end
		end, 1, 0, "closeTime")
	end
	local size = params.size or self.contentLabel:size()
	if btnType == 1 then
		self.btnOK:hide()
		self.btnCancel:hide()
		self.btnOkCenter:show()
		size.height = size.height - 80
		self.contentLabel:size(size)
		if params.btnStr then
			self.btnOkCenter:get("title"):text(params.btnStr)
		end
	else
		self.btnOK:show()
		self.btnCancel:show()
		self.btnOkCenter:hide()
	end

	if self.selectKey then
		self.selectPanel:show()
		-- "first" "false" 为勾选状态, "true" 非勾选状态表示还要再次提示
		local state = self:getSelectKey()
		if state == "first" or state == "false" then
			self.selectTipBtn:get("checkBox"):setSelectedState(true)
			self:setSelectKey("false")
		else
			self.selectTipBtn:get("checkBox"):setSelectedState(false)
		end
		if params.selectTip then
			self.selectPanel:get("textTip"):text(params.selectTip)
		end
		local checkBoxWidth = self.selectPanel:get("btn.checkBox"):width()
		local textTipWidth = self.selectPanel:get("textTip"):width()
		local width = checkBoxWidth + textTipWidth + 20
		local x = (self.selectPanel:width() - width)/2
		self.selectPanel:get("btn"):x(x + self.selectPanel:get("btn"):width()/2 - checkBoxWidth/2)
		self.selectPanel:get("textTip"):x(x + checkBoxWidth + 20 + textTipWidth/2)
	else
		self.selectPanel:hide()
	end

	-- 统一用 beauty.textScroll 处理
	-- self.contentLabel:text(params.content)
	local defaultAlign = "center"
	local list, height = beauty.textScroll({
		size = size,
		fontSize = params.fontSize or 50,
		effect = {color=ui.COLORS.NORMAL.DEFAULT},
		strs = params.content or params.strs,
		verticalSpace = params.verticalSpace or 10,
		isRich = params.isRich,
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
	Dialog.onCreate(self, dialogParams)
end

function PromptBoxView:onClickOK()
	self:addCallbackOnExit(self._okcb)
	Dialog.onClose(self)
	return self
end

function PromptBoxView:onCancel()
	self:addCallbackOnExit(self._cancelcb)
	self:onClose()
end

function PromptBoxView:onClose()
	self:addCallbackOnExit(self._closecb, true)
	Dialog.onClose(self)
	return self
end

function PromptBoxView:getSelectKey()
	if self.params.selectType == 2 then
		return userDefault.getCurrDayKey(self.selectKey, "first")
	else
		return userDefault.getForeverLocalKey(self.selectKey, "first")
	end
end

function PromptBoxView:setSelectKey(val)
	if self.params.selectType == 2 then
		userDefault.setCurrDayKey(self.selectKey, val)
	else
		userDefault.setForeverLocalKey(self.selectKey, val)
	end
end

function PromptBoxView:onSelectTipBtn()
	local state = self:getSelectKey()
	if state == "first" or state == "true" then
		self.selectTipBtn:get("checkBox"):setSelectedState(true)
		self:setSelectKey("false")
	else
		self.selectTipBtn:get("checkBox"):setSelectedState(false)
		self:setSelectKey("true")
	end
end

return PromptBoxView