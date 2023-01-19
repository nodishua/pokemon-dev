--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 主要是进行多语言版本的UI工程适配
--

local type = type

local config = nil
local configCn = nil
-- 配置遍历优先级，小的优先
local configOrderKeys = {
	set = 1,
	scaleWithWidth = 2,
	textAdaptWithSize = 3,
	dockWithScreen = 4,
	oneLineCenterPos = 5,
	oneLineCenter = 6,
	oneLinePos = 7
}

local verticalTab = {
	top = cc.VERTICAL_TEXT_ALIGNMENT_TOP,
	bottom = cc.VERTICAL_TEXT_ALIGNMENT_BOTTOM,
	center = cc.VERTICAL_TEXT_ALIGNMENT_CENTER,
}

local horizontalTab = {
	left = cc.TEXT_ALIGNMENT_LEFT,
	right = cc.TEXT_ALIGNMENT_RIGHT,
	center = cc.TEXT_ALIGNMENT_CENTER,
}

local internalFuncMap

function globals.setContentSizeOfAnchor(node, targetSize)
	local anchor = node:getAnchorPoint()
	local size = node:getContentSize()
	local p = {}
	for _, child in pairs(node:getChildren()) do
		local x, y = child:getPosition()
		x = x - size.width * anchor.x
		y = y - size.height * anchor.y
		p[child] = cc.p(x, y)
	end
	node:setContentSize(targetSize)
	for _, child in pairs(node:getChildren()) do
		local x, y = p[child].x, p[child].y
		x = x + targetSize.width * anchor.x
		y = y + targetSize.height * anchor.y
		child:setPosition(x, y)
	end
end

-- @param node: cocos2dx node
-- @param res: resource path for key match
-- @param reverse: nil(初始化设置)，true(适配回置)，false(配置重置)
function globals.adaptUI(node, res, reverse)
	-- 全屏画布，适配全面屏
	local size = node:getContentSize()
	if size.width == CC_DESIGN_RESOLUTION.width and size.height == CC_DESIGN_RESOLUTION.height then
		local anchorPoint = node:anchorPoint()
		-- assertInWindows(anchorPoint.x == 0.5 and anchorPoint.y == 0.5, "!!! uijson(%s) root anchorPoint(%s, %s) must be {0.5, 0.5}", res, anchorPoint.x, anchorPoint.y)
		setContentSizeOfAnchor(node, display.sizeInView)
	end

	if config == nil then
		local path = "app.defines.adapter." .. LOCAL_LANGUAGE
		xpcall(function() config = require(path) end, function()
			printWarn('not exist ' .. path)
			config = {}
		end)
		configCn = require("app.defines.adapter.cn")
	end

	-- 文本内容适配
	local uiConfig = config[res] or configCn[res]
	if uiConfig then
		-- 优先级遍历，set 比 oneLinePos 先
		local keys = itertools.keys(uiConfig)
		table.sort(keys, function(a, b)
			 local ka = configOrderKeys[a] or math.huge
			 local kb = configOrderKeys[b] or math.huge
			 return ka < kb
		end)
		for _, key in ipairs(keys) do
			local op = key
			local t = uiConfig[op]
			local memo = {}
			local f = internalFuncMap[op]
			for _, params in ipairs(t) do
				if reverse == nil then
					f(node, params, memo)
				else
					if op == "dockWithScreen" then
						local curParams = clone(params)
						curParams[5] = reverse
						f(node, curParams, memo)
					end
				end
			end
		end
	end
end

function globals.adaptBtnTitle(node)
	if not matchLanguage({"vn", "en"}) then
		 return
	end
	local function adaptAll(object)
		local children = object:getChildren()
		if tj.type(object) == "ccui.Button" and #children == 1 and tj.type(children[1]) == "ccui.Text" then
			if object:width() < children[1]:width() + 60 then
				children[1]:scale(object:width() / (children[1]:width() + 60))
			end
		else
			for _, child in pairs(children) do
				adaptAll(child)
			end
		end
	end
	adaptAll(node)
end

local function _getMemo(memo, key)
	if memo == nil then
		return
	end
	if memo[key] then
		return memo[key][1]
	end
end

local function _setMemo(memo, key, node)
	if memo == nil then
		return node
	end
	if node ~= nil then
		if memo[key] then
			return node, memo[key][2]
		end
		local nextMemo = {}
		memo[key] = {node, nextMemo}
		return node, nextMemo
	end
end

-- node:get('a.b.c')
-- node:get(112)
local function _getChild(node, key, memo)
	if type(key) == 'number' then
		local nextNode = _getMemo(memo, key)
		if nextNode == nil then
			nextNode = node:getChildByTag(key)
		end
		node, memo = _setMemo(memo, key, nextNode)
	else
		for k in key:gmatch("([^.]+)") do
			local ik = tonumber(k)
			local nextNode = _getMemo(memo, ik or k)
			if nextNode == nil then
				if ik then
					nextNode = node:getChildByTag(ik)
				else
					nextNode = node:getChildByName(k)
				end
			end
			node, memo = _setMemo(memo, ik or k, nextNode)
			if node == nil then return end
		end
	end
	return node, memo
end

--@return 可能是cdx或者{cdx1, cdx2, ...}
local function _getChilds(node, keys, memo)
	local ret
	if type(keys) == "string" then
		return _getChild(node, keys, memo)
	else
		ret = {}
		for _, name in ipairs(keys) do
			local w = _getChild(node, name, memo)
			if w == nil then
				error('can not found child [' .. name .. '], check ui adapter config!')
			end
			table.insert(ret, w)
		end
		return ret
	end
end

--@desc 获取widget 的相关信息
local function _getWidgetInfo(widget)
	local size = widget:getContentSize()
	local x, y = widget:getPosition()
	local scaleX = widget:getScaleX()
	local scaleY = widget:getScaleY()
	local anchorPoint = widget:getAnchorPoint()

	if scaleX < 0 then
		anchorPoint = cc.p(1 - anchorPoint.x, anchorPoint.y)
	end
	if scaleY < 0 then
		anchorPoint = cc.p(anchorPoint.x, 1 - anchorPoint.y)
	end

	return cc.size(size.width * math.abs(scaleX), size.height * math.abs(scaleY)), cc.p(x,y), anchorPoint
end

-- 对齐适配
--@desc 函数不处理旋转控件
--@param widget1: cdx 中心控件为基准
--@param widgets: cdx1 or {cdx1, cdx2, ...}
--@param align: left widget1, cdx1, cdx2, ...
--				right ..., cdx2, cdx1, widget1
local function _oneLinePos(widget1, widgets, space, align)
	space = space or cc.p(0,0)
	align = align or "left"
	if not itertools.isarray(space) then
		space = {space}
	end

	local showCount = 0
	if widget1:isVisible() then
		showCount = 1
	end
	local size1, p1, anchor1 = _getWidgetInfo(widget1)

	if type(widgets) ~= "table" then
		widgets = {widgets}
	end
	for _, widget2 in ipairs(widgets) do
		if widget2:isVisible() then
			showCount = showCount + 1
			local size2, p2, anchor2 = _getWidgetInfo(widget2)
			if showCount == 1 then
				local targetX
				if align == "left" then
					targetX = p1.x - anchor1.x * size1.width + anchor2.x * size2.width
				else
					targetX = p1.x + (1 - anchor1.x) * size1.width - (1 - anchor2.x) * size2.width
				end
				widget2:setPosition(cc.p(p1.x, p2.y))
			else
				local targetX
				local curSpace = space[showCount - 1] or space[#space]
				if align == "left" then
					targetX = p1.x + curSpace.x + (1 - anchor1.x) * size1.width + anchor2.x * size2.width
				else
					targetX = p1.x - curSpace.x - anchor1.x * size1.width - (1 - anchor2.x) * size2.width
				end
				local targetY = p2.y + curSpace.y
				widget2:setPosition(cc.p(targetX, targetY))
			end
			-- next
			size1, p1, anchor1 = _getWidgetInfo(widget2)
		end
	end
end

-- 居中对齐
local function _oneLineCenter(widget1, lefts, rights, space)
	_oneLinePos(widget1, lefts, space, "right")
	_oneLinePos(widget1, rights, space, "left")
end

-- 根据给定位置居中对齐
local function _oneLineCenterPos(centerPos, widgets, space)
	space = space or cc.p(0,0)
	if not itertools.isarray(space) then
		space = {space}
	end
	if type(widgets) ~= "table" then
		widgets = {widgets}
	end
	local newWidgets = {}
	for _, widget in ipairs(widgets) do
		if widget:isVisible() then
			table.insert(newWidgets, widget)
		end
	end
	widgets = newWidgets

	local len = 0
	local showCount = 0
	for _, widget in ipairs(widgets) do
		showCount = showCount + 1
		local size = _getWidgetInfo(widget)
		len = len + size.width
		local curSpace = space[showCount] or space[#space]
		if showCount < #widgets then
			len = len + curSpace.x
		end
	end

	local showCount = 0
	local x, y = centerPos.x - len / 2, centerPos.y
	for _, widget in ipairs(widgets) do
		showCount = showCount + 1
		local size, p, anchor = _getWidgetInfo(widget)
		widget:setPosition(cc.p(x + anchor.x * size.width, y))
		local curSpace = space[showCount] or space[#space]
		x = x + size.width + curSpace.x
		y = y + curSpace.y
	end
end

-- 屏幕边缘适配
-- @param checkNotchScreen nil:全面屏默认按有刘海屏的处理，true:则根据刘海屏进行处理(如战斗中心先手进度), false:不进行额外处理(如topui贴边)
local function _dockWithScreen(widget, xAlign, yAlign, checkNotchScreen, reverse)
	local flag = reverse == true and -1 or 1
	local dx, dy = 0, 0
	local function getDiffX()
		if checkNotchScreen == false or display.sizeInPixels.width < display.sizeInPixels.height * 2 then
			return 0
		end
		if yAlign == "up" or yAlign == "down" then
			if checkNotchScreen then
				return display.notchSceenSafeArea
			else
				return display.fullScreenSafeArea
			end
		else
			if checkNotchScreen then
				return display.notchSceenDiffX
			else
				return display.fullScreenDiffX
			end
		end
	end
	if xAlign == "left" then
		dx = -display.uiOriginMax.x + getDiffX()

	elseif xAlign == "right" then
		dx = display.uiOriginMax.x - getDiffX()
	end
	dx = dx * flag
	if widget then
		widget:setPositionX(widget:getPositionX() + dx)
	end

	if yAlign == "down" or yAlign == "bottom" then
		dy = display.uiOriginMax.y
	end
	dy = dy * flag
	if widget then
		widget:setPositionY(widget:getPositionY() + dy)
	end
	return dx, dy
end

-- 中心适配，参数获得左右适配的方式
-- 扩展方式: 1、扩展多少偏移多少; 2、扩展量够整个item才扩展(是否有 itemWidth 控制)；3、进行计算适量缩放(预留)
-- @param params: {itemWidth, itemWidthExtra}
-- @param sets: {
-- 	{nodes, "width"}, -- nodes 自动扩展 size.width
-- 	{nodes, "pos", "left"}, -- nodes 位置左适配偏移
-- }
local function _centerWithScreen(xLeft, xRight, params, sets)
	params = params or {}
	sets = sets or {}
	local width = 0 -- 宽度变化量
	local left = 0 -- 左侧变化量
	local right = 0 -- 右侧变化量
	if xLeft then
		if type(xLeft) ~= "table" then
			xLeft = {xLeft}
		end
		left = _dockWithScreen(nil, unpack(xLeft, 1, table.maxn(xLeft)))
		width = width - left
	end
	if xRight then
		if type(xRight) ~= "table" then
			xRight = {xRight}
		end
		right = _dockWithScreen(nil, unpack(xRight, 1, table.maxn(xRight)))
		width = width + right
	end
	-- printInfo("centerWithScreen width(%s), left(%s), right(%s)", width, left, right)

	local count = 0 -- 若有 params.itemWidth (可额外左右偏移params.itemWidthExtra)，获得能增加的整数个
	if params.itemWidth then
		count = math.floor((width + 2 * (params.itemWidthExtra or 0)) / params.itemWidth)
		local newWidth = params.itemWidth * count
		local halfDiffWidth = (width - newWidth)/2
		left = left + halfDiffWidth
		right = right - halfDiffWidth
		width =  newWidth
		-- printInfo("centerWithScreen width(%s), left(%s), right(%s), itemWidthExtra(%s), itemWidth(%s), count(%s)"
		-- 	width, left, right, params.itemWidthExtra, params.itemWidth, count))
	end

	for _, set in ipairs(sets) do
		local widgets, method, param = unpack(set)
		if type(widgets) ~= "table" then
			widgets = {widgets}
		end
		for _, widget in pairs(widgets) do
			if method == "width" then
				local dw = width
				if type(param) == "function" then
					-- 自定义调整宽度
					dw = param(width)
				end
				if dw ~= 0 then
					local scale = widget:scale()
					local size = widget:size()
					-- widget:size(size.width + dw / scale, size.height)
					-- 适配调整大小时保持子结点相对屏幕位置不变
					setContentSizeOfAnchor(widget, cc.size(size.width + dw / scale, size.height))
				end

			elseif method == "pos" then
				local dx = 0
				if type(param) == "function" then
					-- 自定义调整位置
					dx = param(left, right)

				elseif param == "left" then
					dx = left

				elseif param == "right" then
					dx = right

				elseif param == "center" then
					dx = (left + right) / 2
				end
				if dx ~= 0 then
					widget:x(widget:x() + dx)
				end
			end
		end
	end
	return width, count
end

-- 自动缩放
local function _setTextScaleWithWidth(node, s, maxWidth)
	maxWidth = maxWidth or node:getParent():width()
	if s then
		node:text(s)
	end
	if tolua.type(node) == "cc.Label" then
		local autoSize = node:getBoundingBox()
		if autoSize.width > maxWidth then
			node:scale(maxWidth / autoSize.width)
		else
			node:scale(1)
		end
		return
	end
	local autoSize = node:getAutoRenderSize()
	if autoSize.width > maxWidth then
		node:scale(maxWidth / autoSize.width)
	else
		node:scale(1)
	end
	node:ignoreContentAdaptWithSize(true)
	node:setContentSize(autoSize)
	node:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
end

-- 文本固定宽度
-- @params {str, size, vertical, horizontal, margin, maxLine}
-- horizontal: "left", "center", "right"
-- vertical "top", "center", "bottom"
-- margin 两文本间间距
-- maxLine 最大行数
local function _setTextAdaptWithSize(node, params)
	if tolua.type(node) ~= "ccui.Text" then return end
	local params = params or {}
	local size = params.size or node:size()
	local vertical = params.vertical
	local horizontal = params.horizontal
	local margin = params.margin
	local maxLine = params.maxLine
	local str = params.str or node:text()

	local baseFontSize = node.defaultFontSize or node:getFontSize()
	local maxFontSize = baseFontSize
	local minFontSize = 10
	local maxWidth = size.width
	local maxHeight = size.height

	node:ignoreContentAdaptWithSize(false)
	node:text(str)
	node:setContentSize(size)

	local renderer = node:getVirtualRenderer()
	local function getAutoFontSize(fontSize, deep)
		deep = deep or 0
		if deep > 20 then
			return
		end
		node:setFontSize(fontSize)
		renderer:setMaxLineWidth(maxWidth)
		if margin then
			renderer:setLineSpacing(margin)
		end
		local boundHeight = renderer:getBoundingBox().height
		local line = renderer:getStringNumLines()
		-- print("xxx", fontSize, maxLine, line, maxHeight, boundHeight)
		-- 如果对行数有要求，则优先满足行数，然后再满足高度
		if (maxLine and line > maxLine) or boundHeight > maxHeight then
			maxFontSize = fontSize
		else
			minFontSize = fontSize
		end
		local midFontSize = math.floor((maxFontSize + minFontSize)/2)
		if midFontSize ~= fontSize then
			getAutoFontSize(midFontSize, deep + 1)
		end
	end
	local autoSize = node:getAutoRenderSize()
	if autoSize.width > maxWidth then
		renderer:setDimensions(0, 0)
		getAutoFontSize(baseFontSize)
	end
	if vertical then
		node:setTextVerticalAlignment(verticalTab[vertical])
	end
	if horizontal then
		node:setTextHorizontalAlignment(horizontalTab[horizontal])
	end
end

-- setVisible等适配
-- 如果params就是table, 需要再加层{}，如：{"xx", "position", {cc.p(0, 0)}},
local function _set(widget, func, params)
	if type(params) ~= "table" then
		params = {params}
	end
	func = "set" .. string.caption(func)
	if widget[func] then
		widget[func](widget, unpack(params))
	else
		printInfo("ui adapter _set(%s) not exist!", func)
	end
end

--@desc aux for adaptUI
--@param params: {widget1, ...}
local function _auxAdaptWidgetParamsFunc(func)
	return function (parent, params, memo)
		local name1 = params[1]
		local widget1 = _getChild(parent, name1, memo)
		if widget1 == nil then
			local str = name1 .. " is nil"
			error('can not found child, check ui adapter config!\n' .. str)
		end
		-- unpack not same between lua and luajit
		-- luajit unpack until the param was nil
		func(widget1, unpack(params, 2, table.maxn(params)))
	end
end

--@desc aux for adaptUI
--@param params: {widget1, widget2, ...}
local function _auxAdapt2WidgetParamsFunc(func)
	return function (parent, params, memo)
		local name1, name2 = params[1], params[2]
		local widget1 = _getChild(parent, name1, memo)
		local widget2 = _getChilds(parent, name2, memo)
		if widget1 == nil or widget2 == nil then
			local str = (widget1 == nil and name1 or name2) .. " is nil"
			error('can not found child, check ui adapter config!\n' .. str)
		end
		func(widget1, widget2, unpack(params, 3))
	end
end

--@desc aux for adaptUI
--@param params: {widget1, widget2, widget3, ...}
local function _auxAdapt3WidgetParamsFunc(func)
	return function (parent, params, memo)
		local name1, name2, name3 = params[1], params[2], params[3]
		local widget1 = _getChild(parent, name1, memo)
		local widget2 = _getChilds(parent, name2, memo)
		local widget3 = _getChilds(parent, name3, memo)
		if widget1 == nil or widget2 == nil or widget3 == nil then
			local str = (widget1 == nil and name1 or (widget2 == nil and name2 or name3)) .. " is nil"
			error('can not found child, check ui adapter config!\n' .. str)
		end
		func(widget1, widget2, widget3, unpack(params, 4))
	end
end

--@desc aux for adaptUI
--@param params: {centerPos, widgets, ...}
local function _auxAdapt4WidgetParamsFunc(func)
	return function (parent, params, memo)
		local pos, name = params[1], params[2]
		local widget = _getChilds(parent, name, memo)
		if widget == nil then
			error('can not found child, check ui adapter config!\n' .. name .. " is nil")
		end
		func(pos, widget, unpack(params, 3))
	end
end

function globals.adaptTextWithSize(node)
	if matchLanguage({"cn"}) then
		 return
	end
	local function adaptAll(object)
		local children = object:getChildren()
		if tj.type(object) == "ccui.Text" and not object:isIgnoreContentAdaptWithSize() then
			object.defaultFontSize = object:getFontSize()
			_setTextAdaptWithSize(object)
		else
			for _, child in pairs(children) do
				adaptAll(child)
			end
		end
	end
	adaptAll(node)
end

internalFuncMap = {
	oneLinePos = _auxAdapt2WidgetParamsFunc(_oneLinePos),
	oneLineCenter = _auxAdapt3WidgetParamsFunc(_oneLineCenter),
	oneLineCenterPos = _auxAdapt4WidgetParamsFunc(_oneLineCenterPos),
	dockWithScreen = _auxAdaptWidgetParamsFunc(_dockWithScreen),
	set = _auxAdaptWidgetParamsFunc(_set),
	scaleWithWidth = _auxAdaptWidgetParamsFunc(_setTextScaleWithWidth),
	textAdaptWithSize = _auxAdaptWidgetParamsFunc(_setTextAdaptWithSize),
}

------------
-- adapt导出

local adapt = {
	oneLinePos = _oneLinePos,
	oneLineCenter = _oneLineCenter,
	oneLineCenterPos = _oneLineCenterPos,
	dockWithScreen = _dockWithScreen,
	centerWithScreen = _centerWithScreen,
	setTextScaleWithWidth = _setTextScaleWithWidth,
	setTextAdaptWithSize = _setTextAdaptWithSize,
}

------------
-- adaptContext导出
local adaptContext = {}


function adaptContext.clone(node, cb)
	return {node=node, cb=cb}
end

function adaptContext.noteText(startID, endID)
	return {startID=startID, endID=(endID or startID), csv=true}
end

function adaptContext.func(func, ...)
	return {func=func, params={...}}
end

function adaptContext.oneLinePos(name, other, space, align)
	return {adapt=internalFuncMap.oneLinePos, params={name, other, space, align}}
end

function adaptContext.oneLineCenter(name, lefts, rights, space)
	return {adapt=internalFuncMap.oneLineCenter, params={name, lefts, rights, space}}
end

function adaptContext.oneLineCenterPos(centerPos, others, space)
	return {adapt=internalFuncMap.oneLineCenterPos, params={centerPos, others, space}}
end

-- 将当前listView换成widget
--@desc 辅助函数，不支持链式调用
local easyEnterFuncMap = {
	oneLinePos = adaptContext.oneLinePos,
	oneLineCenter = adaptContext.oneLineCenter,
	oneLineCenterPos = adaptContext.oneLineCenterPos,
}
function adaptContext.easyEnter(name)
	return setmetatable({}, {
		__index = function (t, fname)
			local f = easyEnterFuncMap[fname]
			return function (t, ...)
				local context = f(...)
				return {enter=name, context=context}
			end
		end
	})
end

--@desc 填充规则面板，使用限制
--@param contextTable: {context,...}
--		context = {noteStartID, noteEndID}
--				= function
--				= {ccui.Layout, tagName or function}
--@param asyncCount: nil为一次性全部加载本函数内加载，>0值协程加载
function adaptContext.setToList(view, listView, contextTable, asyncCount, asyncOver, asyncPreloadOver)
	listView:removeAllChildren()
	local fixedWidth = listView:getContentSize().width

	local function contextHandle(curView, curMemo, context, eachCB)
		if curView == nil then
			error('curView was nil, check ui adapter context!')
		end

		local cType = type(context)
		if cType == "string" then
			local richText = rich.createWithWidth("#C0x5B545B#" .. context, nil, nil, fixedWidth)
			curView:pushBackCustomItem(richText)

		elseif cType == "function" then
			context()

		elseif cType == "table" then
			-- noteText
			if context.csv then
				for i = context.startID, context.endID do
					if csv.note[i] and csv.note[i].fmt then
						local richText = rich.createWithWidth("#C0x5B545B#" .. csv.note[i].fmt, nil, nil, fixedWidth)
						curView:pushBackCustomItem(richText)
						eachCB()
					end
				end

			-- clone
			elseif context.node then
				local item = context.node:clone()
				item:setVisible(true)
				curView:pushBackCustomItem(item)
				if context.cb then
					context.cb(item)
				end

			-- func
			elseif context.func then
				context.func(unpack(context.params))

			-- oneLinePos
			-- oneLineCenter
			-- oneLineCenterPos
			elseif context.adapt then
				context.adapt(curView, context.params, curMemo)

			-- easyEnter
			elseif context.enter then
				local nextView, nextMemo = _getChild(curView, context.enter, curMemo)
				contextHandle(nextView, nextMemo, context.context, eachCB)
			end
		end
	end

	local function asyncFunc()
		local function yield()
			if asyncCount ~= nil then
				coroutine.yield()
			end
		end

		for _, v in ipairs(contextTable) do
			contextHandle(listView, {}, v, yield)
			yield()
		end
	end
	view:enableAsyncload()
	view:asyncFor(asyncFunc, asyncOver, asyncCount, asyncPreloadOver)
end

-- 多语言 自动旋转缩放
function adapt.setAutoText(node, str, maxHeight)
	maxHeight = maxHeight or node:getParent():height()
	if str then
		node:text(str)
	end
	if matchLanguage({"cn", "tw", "kr"}) then
		-- custom 设置为 auto size
		node:getVirtualRenderer():setDimensions(0, 0)
		node:ignoreContentAdaptWithSize(true)
		node:getVirtualRenderer():setMaxLineWidth(node:getFontSize())
	else
		node:ignoreContentAdaptWithSize(false)
		-- 超宽缩放处理
		local autoSize = node:getAutoRenderSize()
		if autoSize.width > maxHeight then
			node:scale(maxHeight / autoSize.width)
		end
		node:setContentSize(cc.size(autoSize.width*1.2, autoSize.height*1.2))
		node:anchorPoint(cc.p(0.5,0.5))
		node:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
		node:rotate(90)
	end
end

globals.adapt = adapt
globals.adaptContext = adaptContext
