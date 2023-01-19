--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 界面美化相关辅助函数
--

local byte = string.byte
local ceil = math.ceil

local beauty = {}
globals.beauty = beauty

-- ascii(0-127] 1号字体对应的字符基础宽度
local asciiFontWidth = {1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0.27, 0.33, 0.44, 0.6, 0.54, 0.72, 0.7, 0.24, 0.24, 0.24, 0.39, 0.6, 0.27, 0.6, 0.27, 0.41, 0.55, 0.55, 0.55, 0.55, 0.55, 0.55, 0.55, 0.55, 0.55, 0.55, 0.27, 0.27, 0.6, 0.6, 0.6, 0.48, 0.8, 0.63, 0.57, 0.61, 0.66, 0.46, 0.44, 0.7, 0.7, 0.24, 0.41, 0.61, 0.43, 0.87, 0.68, 0.72, 0.55, 0.72, 0.55, 0.54, 0.48, 0.68, 0.59, 0.91, 0.61, 0.54, 0.59, 0.28, 0.41, 0.28, 0.22, 0.5, 0.22, 0.57, 0.57, 0.46, 0.57, 0.54, 0.29, 0.57, 0.55, 0.22, 0.22, 0.5, 0.22, 0.85, 0.55, 0.55, 0.57, 0.57, 0.33, 0.43, 0.29, 0.55, 0.46, 0.78, 0.5, 0.48, 0.48, 0.33, 0.22, 0.33, 0.6, 1}

local function getWidth(b)
	local num = string.utf8charlen(b)
	if num == 1 then
		-- 长度是1的字符按 asciiFontWidth 宽度算长度
		return asciiFontWidth[b] or 1
	end
	-- TODO 其他按语言固定长度，如中文对应的字符基础宽度是1
	return 1
end

-- 内容限定在 width 长度内
-- width 若为nil，则为求 str 的宽度
local function limitWordWidth(str, fontSize, width)
	local len = #str
	local idx = 1
	local curWidth = 0
	while idx <= len do
		local b = byte(str, idx)
		local nextWidth = curWidth + ceil(getWidth(b) * fontSize)
		if width and nextWidth > width then
			break
		end
		curWidth = nextWidth
		idx = idx + string.utf8charlen(b)
	end
	return str:sub(1, idx-1), curWidth
end

-- tableview布局模式 gird, center
-- @param layout: grid 按照最大完整格子显示 center 尽量居中
function beauty.tableMargin(size, cellSize, count, layout)
	layout = layout or "grid"
	-- grid
	local maxColumnSize = math.floor(size.width / cellSize.width)
	local maxRowSize = math.floor(size.height / cellSize.height)
	local lines = math.ceil(count / maxColumnSize)
	local xMargin = 0
	if maxColumnSize > 1 then
		xMargin = math.floor((size.width - maxColumnSize * cellSize.width) / (maxColumnSize - 1))
	end
	local yMargin = 0
	if lines > 1 then
		yMargin = math.floor((size.height - lines * cellSize.height) / (lines - 1))
	end
	-- center
	local rate = 0.618
	local leftPadding, topPadding
	if layout == "center" then
		local y = yMargin == 0 and cellSize.height or yMargin
		if y > cellSize.height * rate then
			yMargin = math.floor(cellSize.height * rate)
			y = size.height - yMargin * (lines - 1) - cellSize.height * lines
			topPadding = math.floor(y / 2)
		end
		if count < maxColumnSize then
			local x = count > 1 and math.floor((size.width - count * cellSize.width) / (count - 1)) or cellSize.width
			if x > cellSize.width * rate then
				xMargin = math.floor(cellSize.width * rate)
				x = size.width - xMargin * (count - 1) - cellSize.width * count
				leftPadding = math.floor(x / 2)
			end
		end
	end
	return lines, maxColumnSize, xMargin, yMargin, leftPadding, topPadding
end

local function createList(size)
	local list = ccui.ListView:create()
	list:setContentSize(size)
	list:setAnchorPoint(cc.p(0, 0))
	list:setPosition(cc.p(0, 0))
	list:setBackGroundColorType(1)
	list:setScrollBarEnabled(false)
	list:setBackGroundColor(cc.c3b(0, 0, 0))
	list:setOpacity(0)
	return list
end

-- @param params {maxLineWidth, align}
local function generateLabel(str, labelParams, params)
	labelParams = labelParams or {}
	params = params or {}
	local label = label.create(str, {
		fontPath = labelParams.fontPath,
		fontSize = labelParams.fontSize,
		anchorPoint = cc.p(0,0),
		color = ui.COLORS.NORMAL.DEFAULT,
		effect = labelParams.effect,
	})
	if labelParams.verticalSpace then
		label:setLineSpacing(labelParams.verticalSpace)
	end
	if params.maxLineWidth then
		label:setMaxLineWidth(params.maxLineWidth)
	end
	local bound = label:getBoundingBox()
	if params.align == "center" then
		label:setHorizontalAlignment(1)

	elseif params.align == "right" then
		label:setHorizontalAlignment(2)
	else
		label:setHorizontalAlignment(0)
	end
	local item = ccui.Layout:create()
	item:setContentSize(cc.size(bound.width, bound.height))
	item:setScale(1)
	item:addChild(label,1,"label")
	return item, label
end

-- 多文本滚动
-- @param params {strs, [list/size], [isRich], [leftPadding], [rightPadding], [fontSize]}
-- list:外部传入
-- isRich :是否使用富文本，默认不使用
-- size:如果外部没有传入list，自定义list的时候需要size
-- strs:如果使用richtext的话，格式与rich.createWithWidth()的第一个参数一致
--      示例:strs = "XXXXXXXXXXX",
--      否则，高度可定制化，包括每个label的(fontSize,effect)
--      示例:strs = {{str = "xxx",fontSize= XXX,effect = XXX,verticalSpace},}; 可简化 strs = {"xxx", "xxx"}
--          如果只有一条的话 strs = {str = "xxx",fontSize= XXX,effect = XXX,verticalSpace}; 可简化 strs = "xxx"
--      如果希望每个label都走统一的定制化格式的话将strs里面的参数提到params即可
-- align: "left", 默认左对齐, "center", "right"
-- margin: 两文本间间距
function beauty.textScroll(params)
	local fontSize = params.fontSize or ui.FONT_SIZE
	local leftPadding = params.leftPadding or 0
	local rightPadding = params.rightPadding or 0
	local itemHeight = 0

	local function generateLabelExtend(str, size, list, labelParams)
		local maxLineWidth = size.width - leftPadding - rightPadding
		local item, label = generateLabel(str, labelParams, {
			maxLineWidth = maxLineWidth,
			align = params.align,
		})
		if leftPadding ~= 0 then
			local containerPosX = label:getPositionX()
			label:setPositionX(containerPosX + leftPadding)
		end
		list:addChild(item)
		return item:getContentSize().height
	end

	local function generateText(list, size)
		local strs = params.strs
		if strs == nil then
			printWarn("beauty.textScroll strs is nil")
			strs = {str = ""}

		elseif type(strs) == "string" then
			strs = {str = strs}

		elseif type(strs) == "table" and type(strs[1]) == "string" then
			local t = {}
			for i, v in ipairs(strs) do
				t[i] = {str = v}
			end
			strs = t
		end
		local function createLabel(strParams, index)
			local str = strParams.str or ""
			index = index or 1
			if params.isRich then
				local textWidth = size.width-rightPadding-leftPadding
				local richText = rich.createByStr(str, strParams.fontSize or fontSize, nil)
				richText:formatText()
				local richWidth = richText:getContentSize().width
				local itemWidth = size.width
				if str ~= "" and richWidth < textWidth then
					itemWidth = richWidth + rightPadding + leftPadding
				end
				richText = rich.createWithWidth(str, strParams.fontSize or fontSize, nil, textWidth, strParams.verticalSpace or params.verticalSpace)
				richText:formatText()
				local richSize = richText:getContentSize()
				local item = ccui.Layout:create()
				item:setContentSize(cc.size(itemWidth, richSize.height))
				item:addChild(richText, 1, "label")
				list:addChild(item, 1, index)

				richText:setPosition(cc.p(richSize.width/2 + leftPadding, richSize.height/2))
				itemHeight = itemHeight + richSize.height
			else
				local labelParams = clone(strParams)
				labelParams.fontSize = labelParams.fontSize or fontSize
				labelParams.effect = labelParams.effect or params.effect
				labelParams.verticalSpace = labelParams.verticalSpace or params.verticalSpace
				itemHeight = itemHeight + generateLabelExtend(str, size, list, labelParams)
			end
		end
		if strs.str then
			return createLabel(strs)
		else
			for i, strParams in ipairs(strs) do
				createLabel(strParams, i)
			end
			itemHeight = itemHeight + (#strs - 1) * (params.margin or list:getItemsMargin())
		end
	end

	local list = params.list
	local size = nil
	if list then
		size = list:getContentSize()
		list:removeAllChildren()
	else
		size = params.size
		list = createList(size)
	end
	generateText(list, size)
	list:setScrollBarEnabled(false)

	if params.align == "center" then
		list:setGravity(ccui.ListViewGravity.centerHorizontal)

	elseif params.align == "right" then
		list:setGravity(ccui.ListViewGravity.right)
	else
		list:setGravity(ccui.ListViewGravity.left)
	end
	if params.margin then
		list:setItemsMargin(params.margin)
	end
	list:refreshView()
	if list:getInnerContainerSize().height > size.height then
		list:setTouchEnabled(true)
	else
		list:setTouchEnabled(false)
	end
	return list, itemHeight
end

-- 单文本滚动
-- @param params {strs, [list/size], [isRich], [waitTime], [speed], [align], [fontSize]}
-- list 外部传入的list
-- isRich :是否使用富文本，默认不使用
-- size:遮挡框的尺寸
-- strs:如果使用richtext的话，格式与rich.createByStr()的第一个参数一致
--      示例:strs = "XXXXXXXXXXX",
--      否则，高度可定制化
--      strs = {str = "xxx",fontSize= XXX,effect = XXX}
-- speed:位移速率，默认 fontSize/s
-- waitTime: 1 (默认，表示前后各停顿1s) or {1, 2}
-- align: "center", 默认居中对齐, "left", "right"
-- style:  1:pingpong 2:Loop
-- vertical:richtext垂直方向上的显示
function beauty.singleTextAutoScroll(params)
	local fontSize = params.fontSize or ui.FONT_SIZE
	local function generateText(list)
		if params.isRich then
			local richText = rich.createByStr(params.strs, fontSize, nil, nil, params.anchor)
			if params.vertical then
				richText:setVerticalAlignment(params.vertical)
			end
			richText:setAnchorPoint(cc.p(0, 0))
			richText:setPosition(cc.p(0, 0))
			richText:formatText()
			local item = ccui.Layout:create()
			item:setContentSize(list:size())
			item:setScale(1)
			item:addChild(richText,1,"label")
			list:addChild(item)
			return richText
		else
			local strs = params.strs
			if strs == nil then
				printWarn("beauty.singleTextAutoScroll strs is nil")
				strs = {str = ""}

			elseif type(strs) == "string" then
				strs = {str = strs}
			end
			local effect = strs.effect or params.effect or {}
			effect.color = effect.color or cc.c4b(255, 255, 255, 255)
			local labelParams = clone(strs)
			labelParams.effect = labelParams.effect or effect
			labelParams.fontSize = labelParams.fontSize or fontSize
			local item, label = generateLabel(strs.str or "", labelParams)
			item:setContentSize(list:size())
			list:addChild(item)
			return label
		end
	end

	local function setLabelSetting(label, params)
		if not label then
			return
		end
		label:setPositionY(math.abs((params.size.height-label:getContentSize().height)/2))
		local width = label:getContentSize().width - params.size.width
		if width <= 0 then
			if params.align == "left" then
				label:setPositionX(0)

			elseif params.align == "right" then
				label:setPositionX(-width)
			else
				label:setPositionX(-width/2)
			end
			return
		end
		local speed = params.speed or fontSize
		local waitTimeSt, waitTimeEnd
		if type(params.waitTime) == "table" then
			waitTimeSt = params.waitTime[1] or 2
			waitTimeEnd = params.waitTime[1] or 2
		else
			waitTimeSt = params.waitTime or 2
			waitTimeEnd = params.waitTime or 2
		end
		local returnTime = params.style == 1 and width/speed or 0.1
		label:stopAllActions()
		label:setPositionX(10)
		local y = label:y()
		label:runAction(cc.RepeatForever:create(
			cc.Sequence:create(
				cc.CallFunc:create(function()
					label:setPositionX(10)
				end),
				cc.DelayTime:create(waitTimeSt),
				cc.MoveTo:create(width/speed, cc.p(-width-10, y)),
				cc.DelayTime:create(waitTimeEnd),
				cc.MoveTo:create(returnTime, cc.p(10, y))
			)
		))
		return true
	end

	local list =  params.list  or createList(params.size)
	list:setScrollBarEnabled(false)
	list:setTouchEnabled(false)
	params.size = params.size or list:getContentSize()
	list:removeAllChildren()
	local label = generateText(list)
	setLabelSetting(label, params)
	return list
end

-- @desc 单文本限定在指定范围内（包含超过时替换成 replaceStr 的内容）
-- @param params {width, replaceStr, align, onlyText}
-- align: "center", 默认居中对齐, "left", "right"
function beauty.singleTextLimitWord(str, labelParams, params)
	local fontSize = labelParams.fontSize
	local width = params.width
	local replaceStr = params.replaceStr or "..."

	local _, w = limitWordWidth(str, fontSize)
	if w > width then
		local _, w = limitWordWidth(replaceStr, fontSize)
		str = limitWordWidth(str, fontSize, width - w) .. replaceStr
	end
	if params.onlyText then
		return str
	end
	local label = label.create(str, labelParams)
	if params.align == "left" then
		label:setAnchorPoint(cc.p(0, 0.5))

	elseif params.align == "right" then
		label:setAnchorPoint(cc.p(1, 0.5))
	else
		label:setAnchorPoint(cc.p(0.5, 0.5))
	end
	return label
end

