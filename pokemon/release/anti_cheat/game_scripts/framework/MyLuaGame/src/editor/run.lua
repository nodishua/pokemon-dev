--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- 内置编辑器 - 战斗录像
--

local ButtonNormal = "img/editor/btn_1.png"
local ButtonClick = "img/editor/btn.png"

local editor = {}
local _msgpack = require '3rd.msgpack'
local msgpack = _msgpack.pack
local msgunpack = _msgpack.unpack

local lblRunResult
function editor:onRunLua()
	local fp = io.open("editor_run.lua", "rb")
	local lbl = cc.Label:createWithTTF(fp and "reading editor_run.lua" or "no editor_run.lua be readed!!!", ui.FONT_PATH, 40)
	lbl:move(display.center):addTo(self.node)
		:setTextColor(cc.c4b(255, 0, 0, 255))
	performWithDelay(self.node, function()
		if lbl then
			lbl:removeSelf()
			lbl = nil
		end
	end, 2)
	if fp == nil then
		return
	end

	local s = fp:read("*a")
	fp:close()
	print('--------- begin of editor_run.lua ---------')
	print(#s)
	print('--------- end of editor_run.lua ---------')
	print('run it:')
	local ret = assert(loadstring(s))()
	print('return:')
	print(tostring(ret))

	if lbl then
		lbl:removeSelf()
		lbl = nil
	end
	if ret ~= nil then
		if lblRunResult then
			lblRunResult:removeSelf()
			lblRunResult = nil
		end
		lblRunResult = cc.Label:createWithTTF(tostring(ret), ui.FONT_PATH, 40)
		lblRunResult:move(display.center):addTo(self.node)
			:setTextColor(cc.c4b(255, 0, 0, 255))
		performWithDelay(self.node, function()
			if lblRunResult then
				lblRunResult:removeSelf()
				lblRunResult = nil
			end
		end, 15)
	end
end

function editor:onRunLuaInEditBox()
	local codeLayer = cc.LayerColor:create(cc.c4b(60, 60, 60, 200), display.sizeInView.width, display.sizeInView.height)
	codeLayer:setAnchorPoint(cc.p(0, 0))
	codeLayer:setPosition(0, 0)
	codeLayer:setTouchMode(cc.TOUCHES_ONE_BY_ONE)
	codeLayer:setSwallowsTouches(true)
	codeLayer:setTouchEnabled(true)
	codeLayer:setName("codeLayer")
	codeLayer:registerScriptTouchHandler(function(...)
		return true
	end)
	self.node:addChild(codeLayer)

	local txtScroll = ccui.ScrollView:create()
	txtScroll:setScrollBarEnabled(true)
	txtScroll:setScrollBarAutoHideEnabled(false)
	txtScroll:setScrollBarWidth(100)
	txtScroll:setScrollBarColor(cc.c3b(255, 0, 0))
	txtScroll:setDirection(1)
	txtScroll:setLayoutType(1)
	txtScroll:setInertiaScrollEnabled(true)
	txtScroll:setContentSize(cc.size(2000, 1000))
	txtScroll:setAnchorPoint(cc.p(0.5, 0.5))
	txtScroll:setInnerContainerSize(cc.size(2000, 10000))
	txtScroll:setPosition(display.cx + display.uiOrigin.x, display.cy)
	codeLayer:addChild(txtScroll)

	local editBox = ccui.EditBox:create(cc.size(2000, 10000), ButtonClick)
	-- editBox:setPosition(display.cx, display.cy)
	editBox:setFontSize(72)
	editBox:setMaxLength(1024*1024)
	txtScroll:addChild(editBox)

	local btnRun = ccui.Button:create(ButtonNormal, ButtonClick)
	btnRun:setTitleText("运行")
	btnRun:setTitleFontSize(20)
	btnRun:setPressedActionEnabled(true)
	btnRun:setPosition(display.cx + display.uiOrigin.x - 500, 200)
	btnRun:setScale(3)
	local lastClickTime = 0
	btnRun:addClickEventListener(function()
		local s = editBox:getText()
		print('--------- begin of script ---------')
		print(s)
		print('--------- end of script ---------')
		print('run it:')
		assert(loadstring(s))()
	end)
	codeLayer:addChild(btnRun)

	local btnExit = ccui.Button:create(ButtonNormal, ButtonClick)
	btnExit:setTitleText("退出")
	btnExit:setTitleFontSize(20)
	btnExit:setPressedActionEnabled(true)
	btnExit:setPosition(display.cx + display.uiOrigin.x + 500, 200)
	btnExit:setScale(3)
	local lastClickTime = 0
	btnExit:addClickEventListener(function()
		codeLayer:removeFromParent()
	end)
	codeLayer:addChild(btnExit)
end

return editor