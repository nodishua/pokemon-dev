--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 弹出框
--

local ViewBase = cc.load("mvc").ViewBase
globals.Dialog = class("Dialog", ViewBase)
Dialog.__dialog = true

function globals.isDialog(view)
	return view.__dialog == true
end

local ACTIONE_TIME = 0.1 -- 动画时间

-- @params {clearFast, noBlackLayer, clickClose, blackType}
-- clearFast:直接关闭没有动画
-- noBlackLayer:默认有黑色遮罩
-- clickClose: nil(有遮罩则有点击), false(无点击关闭)，true(点击关闭)
-- blackType: nil:默认 cc.c4b(91, 84, 91, 204), 1:cc.c4b(0, 0, 0, 180)
-- blackOpacity: nil:默认204
function Dialog:onCreate(params)
	params = params or {}
	self._clearFast = params.clearFast

	audio.playEffectWithWeekBGM("popupopen.mp3")

	local baseNode = self:getResourceNode()
	local baseScaleY = baseNode:scaleY()
	baseNode:setScaleY(0)
	if not params.noBlackLayer or params.clickClose == true then
		local color = cc.c3b(91, 84, 91)
		local opacity = 204
		if params.blackType == 1 then
			color = cc.c3b(0, 0, 0)
			opacity = 180
		end
		if params.blackOpacity then
			opacity = params.blackOpacity
		end 
		local blackLayer = ccui.Layout:create()
		blackLayer:setContentSize(display.sizeInView)
		blackLayer:setBackGroundColorType(1)
		blackLayer:setBackGroundColor(color)
		blackLayer:setOpacity(0)
		blackLayer:setTouchEnabled(true)
		blackLayer:setPosition(cc.p(display.board_left, 0))
		self:addChild(blackLayer, -1) -- 默认Zorder是-1
		baseNode:setTouchEnabled(false)
		if params.clickClose ~= false then
			bind.click(self, blackLayer, {method = function()
				self:onClose()
			end})
		end
		if not params.noBlackLayer then
			blackLayer:setOpacity(opacity)
		end
	end

	-- 异常情况存在同帧打开关闭界面导致界面卡死
	gGameUI:disableTouchDispatch(nil, false)
	local cb
	cb = self:onNodeEvent("exit", function()
		if cb then
			cb:remove()
			cb = nil
			gGameUI:disableTouchDispatch(nil, true)
		end
	end)

	-- only one be called when exit or sequence_end
	transition.executeSequence(baseNode)
		:easeBegin("INOUT")
			:scaleYTo(ACTIONE_TIME, baseScaleY)
		:easeEnd()
		:func(function()
			if cb then
				cb:remove()
				cb = nil
				gGameUI:disableTouchDispatch(nil, true)
			end
		end)
		:done()
end

function Dialog:onClose()
	-- schedule中可能有网络请求行为，会导致exit之后cb回来
	-- 但不能简单disableSchedule，因为View没有exit，会有相关逻辑需要schedule（比如longTouch）
	-- disable等同于unbind，所以如有enabled，只是逻辑上清理，而非unbind清除
	if self:isScheduleEnabled() then
		self:unScheduleAll()
	end
	if self:isAsyncloadEnabled() then
		self:pauseFor()
	end
	if self:isMessageEnabled() then
		self:unregisterTarget()
	end

	audio.playEffectWithWeekBGM("popupclose.mp3")
	if self._clearFast then
		ViewBase.onClose(self)
		return
	end

	-- 关闭动画过程中不响应点击和请求
	local baseNode = self:getResourceNode()
	gGameApp:pauseRequest()
	gGameUI:disableTouchDispatch(nil, false)
	local cb
	cb = self:onNodeEvent("exit", function()
		cb:remove()
		gGameApp:resumeRequest()
		gGameUI:disableTouchDispatch(nil, true)
	end)

	transition.executeSequence(baseNode)
		:easeBegin("INOUT")
			:scaleYTo(ACTIONE_TIME * 0.8, 0.3)
			:scaleTo(ACTIONE_TIME * 0.2, 0)
		:easeEnd()
		:delay(0.05)
		:func(function()
			ViewBase.onClose(self)
		end)
		:done()
end

function Dialog:onCloseFast()
	self._clearFast = true
	self:onClose()
end
