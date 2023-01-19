--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ViewBase bind touch触摸点击相关
--

local helper = require "easy.bind.helper"

local function changeColor(node, color, flag)
	if not flag then
		-- getter
		flag = 0
		if node.getTextColor then
			color = node:getTextColor()
			if color.r == 255 and color.g == 255 and color.b == 255 then
				flag = 2
			end
		end
		if flag == 0 and node.getColor then
			color = node:getColor()
			if color.r == 255 and color.g == 255 and color.b == 255 then
				flag = 1
			end
		end
		return color, flag
	else
		-- setter
		-- 存在按住松开中控件发生了变动的情况
		if flag == 2 and node.setTextColor then
			node:setTextColor(cc.c4b(color.r, color.g, color.b, 255))

		elseif flag == 1 and node.setColor then
			node:setColor(color)
		end
	end
end

-- touch
-- @param method: view关联函数
-- @param methods: view关联函数,接受消息映射 {ended=XXX, began=XXX}
-- @param sound: 点击音效ID
-- @param soundClose: 关闭点击音效
-- @param clicksafe: 一般有服务器响应的 不需要调用保护 因为本身服务器响应会把全部界面响应禁了
-- @param scaletype: 缩放效果 1: 先放大后正常 2：先缩小再正常 0:不放大也不缩小
-- @param ignoremask: 默认nil点击不加蒙灰遮罩效果，true：为不加该效果
-- @param zoomscale: 默认设置一点缩放效果, 主要是 ccui.Button 的点击缩放
-- @param bounce: 位移效果，更强烈的点击感
-- @param longtouch: 长按效果, bool or number
-- @param args: 现在只有Layer:onTouch用
function bind.touch(view, node, b)
	local scale = 0.95 -- 默认先缩小再正常
	local nodeScaleX, nodeScaleY = node:scaleX(), node:scaleY()
	if b.scaletype == 0 then
		scale = 1

	elseif b.scaletype == 1 then
		scale = 1.05

	elseif b.scaletype == 2 then
		scale = 0.95
	end
	local zoomscale = 0 -- 默认按钮不缩放，整体缩放
	if b.zoomscale then
		zoomscale = type(b.zoomscale) == "number" and b.zoomscale or 0.1
	end
	if node.setZoomScale then
		node:setZoomScale(zoomscale)
	end

	local bouncex, bouncey
	local posx, posy
	if b.bounce then
		local size = node:getContentSize()
		posx, posy = node:getPosition()
		bouncex, bouncey = size.width*0.05, size.height*0.05
	end
	local colors = {}
	local function callback(recv)
		-- 缩放效果
		if scale and scale ~= 1 and recv.name ~= "moved" then
			local baseScale = recv.name == "began" and scale or 1
			if recv.name == "began" then
				transition.executeSequence(node)
					:easeBegin("INOUT")
						:scaleTo(0.05, baseScale*nodeScaleX, baseScale*nodeScaleY)
					:easeEnd()
					:done()
			else
				local extraScale = scale < 1 and 1.02 or 1/1.02
				transition.executeSequence(node)
					:easeBegin("INOUT")
						:scaleTo(0.02, extraScale*nodeScaleX, extraScale*nodeScaleY)
						:scaleTo(0.05, baseScale*nodeScaleX, baseScale*nodeScaleY)
					:easeEnd()
					:done()
			end
		end
		if b.ignoremask == false then
			if recv.name == "began" then
				colors = {}
				node:enumerateChildren(true, function (child)
					local color, flag = changeColor(child)
					colors[child] = {color = color, flag = flag}
				end)
			end

			local c = 255 * 0.94
			for child, v in pairs(colors) do
				local color = (recv.name == "began" or recv.name == "moved") and cc.c3b(c, c, c) or v.color
				changeColor(child, color, v.flag)
			end
		end

		-- 位移效果
		if bouncex then
			if recv.name == "began" then
				node:setPosition(bouncex+posx, bouncey+posy)
			else
				node:setPosition(posx, posy)
			end
		end

		-- 消息过滤
		local f = helper.method(view, node, b, recv.name)
		if not f then return end

		-- 点击音效
		if not b.soundClose and recv.name == "ended" then
			audio.playEffectWithWeekBGM(ui.TOUCH_SOUND_LIST[b.sound or 1])
		end

		-- 审核服事件点击上报
		if FOR_SHENHE and recv.name == "ended" and gGameUI.rootViewName ~= "login.view" then
			local _, viewName = gGameUI:getTopStackUI()
			local nodeName = node:name()
			local nodeParentName = node:parent():name()
			gGameApp:slientRequestServer("/game/click", nil, string.format("%s/%s/%s", viewName, nodeParentName, nodeName))
		end

		-- 点击保护
		if b.clicksafe and recv.name == "ended" then
			local delay = 0.2
			node:setEnabled(false)
			performWithDelay(node, function()
				node:setEnabled(true)
			end, delay)
			transition.executeParallel(node)
				:func(function()
					f(recv)	--这里可能会清除node的操作，所以要放在最后处理
				end)
			return
		end

		return f(recv)
	end

	if b.longtouch then
		local delay = 0.1
		if type(b.longtouch) == "number" then
			delay = b.longtouch
		end
		node:onLongTouch(delay, callback, unpack(b.args or {}))
	else
		node:onTouch(callback, unpack(b.args or {}))
	end
end

-----------
-- simple for touch
local function clickCallback(view, node, b, recv)
	local f = helper.method(view, node, b)

	-- 点击音效
	if not b.soundClose then
		audio.playEffectWithWeekBGM(ui.TOUCH_SOUND_LIST[b.sound or 1])
	end

	-- 审核服事件点击上报
	if FOR_SHENHE and gGameUI.rootViewName ~= "login.view" then
		local _, viewName = gGameUI:getTopStackUI()
		local nodeName = node:name()
		local nodeParentName = node:parent():name()
		gGameApp:slientRequestServer("/game/click", nil, string.format("%s/%s/%s", viewName, nodeParentName, nodeName))
	end

	-- 点击保护
	if b.clicksafe then
		local delay = 0.2
		node:setEnabled(false)
		performWithDelay(node, function()
			node:setEnabled(true)
		end, delay)
		transition.executeParallel(node)
			:func(function()
				f(recv)	--这里可能会有清除所有的uiNode的操作，所以要放在最后处理
			end)
		return
	end

	return f(recv)
end

-- click
-- @param method: view关联函数
-- @param sound: 点击音效ID
-- @param clicksafe: 一般有服务器响应的 不需要调用保护 因为本身服务器响应会把全部界面响应禁了
function bind.click(view, node, b)
	node:onClick(functools.partial(clickCallback, view, node, b))
end

-- event 监听checkBox textFiled
-- @param method: view关联函数
-- @param sound: 点击音效ID
-- @param clicksafe: 一般有服务器响应的 不需要调用保护 因为本身服务器响应会把全部界面响应禁了
function bind.event(view, node, b)
	node:onEvent(functools.partial(clickCallback, view, node, b))
end