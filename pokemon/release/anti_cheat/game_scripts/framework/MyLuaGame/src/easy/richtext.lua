--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 处理RichText和自定义格式字符串
--

local rich = {}
globals.rich = rich

--@param blackEnd: 时候文本结束后恢复为黑色
function rich.color(color, text, blackEnd)
	if blackEnd == nil then
		blackEnd = true
	end
	return {text = text, color = color, blackEnd = blackEnd}
end

function rich.font(size, text)
	return {text = text, fontSize = size}
end

-- str: 0x00FF00FF
local function getColor(str)
	local num = tonumber(str)
	if #str > 8 then
		return cc.c4b(math.floor(num/65536%256), math.floor(num/256%256), num%256, math.floor(num/(65536*256)))
	end
	return cc.c3b(math.floor(num/65536), math.floor(num/256%256), num%256)
end

-- "Icommon/icon/icon_diamond.png-20-30" -> "Icommon/icon/icon_diamond.png", 30
local function getLastVal(path)
	local val
	local p, q = string.find(path, "-[%d.]*$")
	if p and q then
		val = path:sub(p+1, q)
		path = path:sub(1, p-1)
	end
	return path, val
end

-- enum {
--     ITALICS_FLAG = 1 << 0,          /*!< italic text */
--     BOLD_FLAG = 1 << 1,             /*!< bold text */
--     UNDERLINE_FLAG = 1 << 2,        /*!< underline */
--     STRIKETHROUGH_FLAG = 1 << 3,    /*!< strikethrough */
--     URL_FLAG = 1 << 4,              /*!< url of anchor */
--     OUTLINE_FLAG = 1 << 5,          /*!< outline effect */
--     SHADOW_FLAG = 1 << 6,           /*!< shadow effect */
--     GLOW_FLAG = 1 << 7              /*!< glow effect */
-- };
local function getFlags(v)
	local flags = tonumber(string.sub(v,2), 2)
	if flags then
		-- val 配置为2进制为 "#L11111111#"
		-- 2^7:glow 2^6:shader 2^5:outline 2^4:url 2^3:删除线 2^2:下划线 2^1:粗体(使用 youmi1.ttf) 2^0:斜体
		return {type="flags", val=flags}
	end
	local chExtra = string.sub(v,2,3)
	local str = string.sub(v,4)
	if chExtra == "SO" then
		local t = string.split(str, ",")
		if #t >= 2 then
			return {type="flags", flags="shaderOffset", val=cc.size(t[1], t[2])}
		else
			printWarn("richtext(%s): format may be like #LSO2,-2#", v)
			return
		end
	end
	if chExtra == "UL" then
		return {type="flags", flags="url", val=str}
	end
	local num = tonumber(str)
	if not num then
		printWarn("richtext(%s): format can't transform to number", v)
		return
	end
	if chExtra == "OC" then
		return {type="flags", flags="outlineColor", val=getColor(str)}
	end
	if chExtra == "OS" then
		return {type="flags", flags="outlineSize", val=num}
	end
	if chExtra == "SC" then
		return {type="flags", flags="shadowColor", val=getColor(str)}
	end
	if chExtra == "SR" then
		return {type="flags", flags="shadowBlurRadius", val=num}
	end
	if chExtra == "GC" then
		return {type="flags", flags="glowColor", val=getColor(str)}
	end
	printWarn("richtext(%s): chExtra Invalid", v)
	return
end

--@param fontSize: 默认24
local function _generateRichTexts(array, fontSize, deltaSize, adjustWidth)
	deltaSize = deltaSize or 0
	fontSize = fontSize or ui.FONT_SIZE

	local elems = {}
	local tag = 1 --先写死
	local ttf = ui.FONT_PATH
	local opacity = 255 --这个先写死 看需求是否需要
	local color = ui.COLORS.WHITE
	local flags = {}
	for k, t in ipairs(array) do
		if t.type == "color" then -- 颜色
			color = t.color

		elseif t.type == "font" then -- 字体
			if t.path then
				ttf = t.path
			else
				fontSize = t.size + deltaSize
			end

		elseif t.type == "image" then -- 图片
			local path = t.path or "" -- "img/kongbai.png"
			local url = flags.url or ""
			-- int tag, const Color3B& color, GLubyte opacity, const std::string& filePath, const std::string& url = "", Widget::TextureResType texType = Widget::TextureResType::LOCAL, const Vec2& anchor = Vec2::ZERO
			local element = ccui.RichElementImage:create(0, ui.COLORS.WHITE, 255, path, url)
			if t.width then
				element:setWidth(t.width)
				element:setHeight(t.heightOrScale)

			elseif t.heightOrScale then
				local img = cc.Sprite:create(path)
				local size = img:size()
				element:setWidth(size.width * t.heightOrScale)
				element:setHeight(size.height * t.heightOrScale)
			end
			table.insert(elems, {element})
			flags = {}

		elseif t.type == "spine" then -- 特效
			local width = t.width * t.scale
			local height = t.height * t.scale
			local node = cc.Node:create()
			node:setContentSize(width, height)
			local url = flags.url or ""
			-- int tag, const Color3B& color, GLubyte opacity, Node* customNode, const std::string& url = "", const Vec2& anchor = Vec2::ZER
			local element = ccui.RichElementCustomNode:create(0, ui.COLORS.WHITE, 255, node, url)
			local spine = CSprite.new(t.path)
			spine:play(t.action)
			spine:setPosition(cc.p(width/2, height/2))
			spine:scale(t.scale)
			node:addChild(spine)
			table.insert(elems, {element})
			flags = {}

		elseif t.type == "text" then
			local text = t.text
			if adjustWidth then
				-- 富文本内对齐需要添加\n 最后一个文本内容添加
				if k < #array then
					text = text .. "\n"
				end
			end
			local outlineColor = flags.outlineColor or ui.COLORS.NORMAL.DEFAULT
			local outlineSize = flags.outlineSize or ui.DEFAULT_OUTLINE_SIZE
			local shadowColor = flags.shadowColor or ui.COLORS.NORMAL.DEFAULT
			local shaderOffset = flags.shaderOffset or cc.size(6,-6)
			local shadowBlurRadius = flags.shadowBlurRadius or 0
			local glowColor = flags.glowColor or ui.COLORS.NORMAL.DEFAULT
			local url = flags.url or ""
			-- int tag, const Color3B& color, GLubyte opacity, const std::string& text,
			--   const std::string& fontName, float fontSize, uint32_t flags, const std::string& url,
			--   const Color3B& outlineColor = Color3B::WHITE, int outlineSize = -1,
			--   const Color3B& shadowColor = Color3B::BLACK, const cocos2d::Size& shadowOffset = Size(2.0, -2.0), int shadowBlurRadius = 0,
			--   const Color3B& glowColor = Color3B::WHITE, const Vec2& anchor = Vec2::ZERO
			local element = ccui.RichElementText:create(tag, color, opacity, text, ttf, fontSize,
				flags.val or 0, url, outlineColor, outlineSize, shadowColor, shaderOffset, shadowBlurRadius, glowColor)
			table.insert(elems, {element, {color, opacity, text, ttf, fontSize, flags.val or 0, url, outlineColor, outlineSize, shadowColor, shaderOffset, shadowBlurRadius, glowColor}})
			flags = {}
			ttf = ui.FONT_PATH

		elseif t.type == "flags" then
			flags = flags or {}
			if t.flags then
				flags[t.flags] = t.val
			else
				if bit.band(t.val, tonumber("10", 2)) > 0 then
					flags.val = t.val - tonumber("10", 2)
					ttf = "font/youmi1.ttf"
				else
					flags.val = t.val
				end
			end
		end
	end
	return elems
end

local function _getRichTextsByStr(str, fontSize, deltaSize, adjustWidth)
	local nstr = string.gsub(str, "\\n", function(c)
		return "\n"
	end)
	local T = {}
	local start = 1
	while true do
		local l, r, ss = nstr:find('#([CFPTIL][^#]+)#', start)
		if l == nil then break end
		if l > start then
			table.insert(T, {s=nstr:sub(start, l - 1)})
		end
		table.insert(T, {s=ss, format=true})
		start = r + 1
	end
	if start <= #nstr then
		table.insert(T, {s=nstr:sub(start)})
	end

	local T2 = {}
	for k, t in ipairs(T) do
		local v = t.s
		local t2 = {}
		if t.format then
			local ch = string.sub(v,1,1)
			if ch == 'C' then -- 颜色
				local num = tonumber(string.sub(v,2))
				if num == nil then
					t2 = {type="text", text=tostring(v)}
				else
					t2 = {type="color", color=getColor(string.sub(v,2))}
				end

			elseif ch == 'F' then -- 字号
				local size = tonumber(string.sub(v,2))
				if size == nil or size > 200 or size < 0 then
					t2 = {type="text", text=tostring(v)}
				else
					t2 = {type="font", size=size}
				end

			elseif ch == "P" then -- 字体
				local fontPath = string.sub(v,2)
				t2 = {type="font", path=fontPath}

			elseif ch == 'T' then -- 头衔
				local str = string.sub(v,2)
				local num, hOrScale = getLastVal(str)
				local num, w = getLastVal(num)
				num = tonumber(num)
				if num and csv.title[num] then
					local cfg = csv.title[num]
					local showType = cfg.showType
					if showType == "pic" then
						t2 = {type="image", path=cfg.res, width=w, heightOrScale=hOrScale}

					elseif showType == "txt" then
						-- 添加描边
						table.insert(T2, getFlags("L100000"))
						table.insert(T2, {type="flags", flags="outlineColor", val=cc.c4b(cfg.color[1],cfg.color[2],cfg.color[3],255)})
						t2 = {type="text", text=cfg.title}

					elseif showType == "spine" then
						t2 = {type="spine", path=cfg.res, action="effect_loop", scale = hOrScale or 1, width=cfg.spineSize[1], height=cfg.spineSize[2]}
					end
				end

			elseif ch == 'I' then -- 图片
				local resPath = string.sub(v,2)
				local resPath, hOrScale = getLastVal(resPath)
				local resPath, w = getLastVal(resPath)
				t2 = {type="image", path=resPath, width=w, heightOrScale=hOrScale}

			elseif ch == 'L' then -- flags
				t2 = getFlags(v)
			end
		else
			v = tostring(v)
			if LOCAL_LANGUAGE == "en" then
				if v:byte(#v) == 10 then
					v = v .. "\n"
				end
			end
			t2 = {type="text", text=v}
		end

		if t2 and next(t2) then
			table.insert(T2, t2)
		end
	end

	return _generateRichTexts(T2, fontSize, deltaSize, adjustWidth)
end

local function _getRichTextsByArray(array, fontSize, deltaSize)
	local T2 = {}
	for _, t in ipairs(array) do
		if type(t) == "table" then
			if t.color then
				table.insert(T2, {type="color", color=t.color})
				table.insert(T2, {type="text", text=t.text})
				if t.blackEnd then
					table.insert(T2, {type="color", color=ui.COLORS.WHITE})
				end

			elseif t.fontSize then
				table.insert(T2, {type="font", size=t.fontSize})
				table.insert(T2, {type="text", text=t.text})
			end
		else
			table.insert(T2, {type="text", text=t})
		end
	end

	return _generateRichTexts(T2, fontSize, deltaSize)
end

local function round(f)
	local n = math.floor(f)
	local e = f - n
	if e < 0.5 then
		return n
	else
		return n + 1
	end
end

local function ltrim(s)
	return s:gsub("^%s*(.-)", "%1")
end

local function _binarySearchSplit(richTextTest, params, lineWidth)
	local tag = 1 --先写死
	local color, opacity, s, ttf, fontSize, val, url, outlineColor, outlineSize, shadowColor, shaderOffset, shadowBlurRadius, glowColor = unpack(params)
	local l, r = 1, #s + 1
	while l < r do
		local mid = math.floor((l + r) / 2)
		local left = s:sub(1, mid)
		local elem = ccui.RichElementText:create(tag, color, opacity, left, ttf, fontSize, val, url, outlineColor, outlineSize, shadowColor, shaderOffset, shadowBlurRadius, glowColor)
		richTextTest:pushBackElement(elem)
		richTextTest:formatText()
		local size = richTextTest:getContentSize()
		if size.width > lineWidth then
			r = mid
		else
			l = mid + 1
		end
		richTextTest:removeElement(elem)
	end
	local split = r - 1
	while 0 < split and split < #s do
		if s:byte(split) == 32 then
			break
		else
			split = split - 1
		end
	end
	return split
end

--@param onlyElems: true 返回richtext中间格式，false 返回组装好的ccui.RichText
local function _getRichTextsWordLineFeed(strOrArray, size, deltaSize, lineWidth, onlyElems)
	onlyElems = onlyElems or false

	local tag = 1 --先写死
	local richText = onlyElems or ccui.RichText:create()
	local richTextTest = ccui.RichText:create()
	richTextTest:ignoreContentAdaptWithSize(true)
	local testCount = 0

	local retElems = {}
	local elems
	if type(strOrArray) == "table" then
		elems = _getRichTextsByArray(strOrArray, size, deltaSize)
	else
		elems = _getRichTextsByStr(strOrArray, size, deltaSize)
	end

	local lineElems = {}
	for _, t in ipairs(elems) do
		local elem, params = t[1], t[2]
		richTextTest:pushBackElement(elem)
		testCount = testCount + 1
		richTextTest:formatText()
		local size = richTextTest:getContentSize()
		while size.width > lineWidth do
			-- printInfo("width=%s | %s | %s | %s | %s", size.width, lineWidth, tostring(size.width > lineWidth), tostring(params and params[3]), tolua.type(elem))

			richTextTest:removeElement(elem)
			testCount = testCount - 1

			-- split
			if tolua.type(elem) == "ccui.RichElementText" then
				local color, opacity, s, ttf, fontSize, val, url, outlineColor, outlineSize, shadowColor, shaderOffset, shadowBlurRadius, glowColor = unpack(params)
				-- 默认是英文
				local split = _binarySearchSplit(richTextTest, params, lineWidth)
				-- printInfo("%s,%s,%s%s",size.width, split, 'left=', s:sub(1, split))
				if split == 0 and #lineElems == 0 then
					-- error("could not split word")
					-- 一段无法分割的字会有纰漏，多余自动换行的没有计算长度
					break
				end
				local left = s:sub(1, split) .. "\n"
				table.insert(lineElems, {ccui.RichElementText:create(tag, color, opacity, left, ttf, fontSize, val, url, outlineColor, outlineSize, shadowColor, shaderOffset, shadowBlurRadius, glowColor),
					{color, opacity, left, ttf, fontSize, val, url, outlineColor, outlineSize, shadowColor, shaderOffset, shadowBlurRadius, glowColor}})
				local right = ltrim(s:sub(split + 1))
				-- printInfo('right=%s', right)
				elem = ccui.RichElementText:create(tag, color, opacity, right, ttf, fontSize, val, url, outlineColor, outlineSize, shadowColor, shaderOffset, shadowBlurRadius, glowColor)
				params[3] = right
			end
			-- fill line
			for _, t2 in ipairs(lineElems) do
				if onlyElems then
					table.insert(retElems, t2)
				else
					richText:pushBackElement(t2[1])
				end
			end

			for i = testCount, 1, -1  do
				richTextTest:removeElement(i - 1)
			end
			lineElems = {}

			-- force _formatTextDirty=true
			richTextTest:ignoreContentAdaptWithSize(false)
			richTextTest:ignoreContentAdaptWithSize(true)
			-- right
			richTextTest:pushBackElement(elem)
			testCount = 1
			richTextTest:formatText()
			size = richTextTest:getContentSize()
		end
		table.insert(lineElems, {elem, params})
	end

	for _, t2 in ipairs(lineElems) do
		if onlyElems then
			table.insert(retElems, t2)
		else
			richText:pushBackElement(t2[1])
		end
	end
	return onlyElems and retElems or richText
end

-------------------
-- 导出函数

--@param array: 使用rich.相关函数创建的数组
function rich.createByArray(array, size, deltaSize, anchor)
	local richText = ccui.RichText:create()
	local elems = _getRichTextsByArray(array, size, deltaSize)
	for _, t in ipairs(elems) do
		local elem = t[1]
		if anchor then
			elem:setAnchorPoint(anchor)
		end
		richText:pushBackElement(elem)
	end
	return richText
end

--@desc #C代表color  #F代表字体大小 其他就是要显示的字符串
--@param deltaSize: 偏移量，用在city中聊天缩略窗口，需要调整大小，小于聊天界面的字体
--@example str = "#C0xffffff##F24#dfsagfeif23df#C0xf45fff##F32#grgfgsf#F24#哈哈哈dfs  #C0xffffff#Inksu#C0xff22ff##F1##F12##C0xFFFFFF#恭喜#C0xFFEE2C#Inky#C0xFFFFFF#历尽艰辛后，达到数码试炼50层，希望ta百尽竿头，更进一步！#T1#T2#T3#T##T1rank"
function rich.createByStr(str, size, deltaSize, adjustWidth, anchor)
	local richText = ccui.RichText:create()
	local elems = _getRichTextsByStr(str, size, deltaSize, adjustWidth)
	for _, t in ipairs(elems) do
		local elem = t[1]
		if anchor then
			elem:setAnchorPoint(anchor)
		end
		richText:pushBackElement(elem)
	end
	return richText
end

-- 固定宽度
function rich.adjustWidth(richText, fixedWidth, verticalSpace)
	if verticalSpace then
		richText:setVerticalSpace(verticalSpace)
	end
	richText:ignoreContentAdaptWithSize(false)
	richText:setContentSize(cc.size(fixedWidth , 0))
	richText:formatText()
	return richText:getContentSize()
end

-- 获取固定宽度的richtext控件
--@desc 相比调用getRichTextsByStr和adjustRichTextWidth，getRichTextWithWidth能进行英文按单词换行
--@desc 如果是array，不允许里面的srting有类似#C这类格式字符串存在
function rich.createWithWidth(strOrArray, size, deltaSize, lineWidth, verticalSpace, anchor)
	local richText
	if LOCAL_LANGUAGE == "en" then
		richText = _getRichTextsWordLineFeed(strOrArray, size, deltaSize, lineWidth)
	else
		if type(strOrArray) == "table" then
			richText = rich.createByArray(strOrArray, size, deltaSize, anchor)
		else
			richText = rich.createByStr(strOrArray, size, deltaSize, true, anchor)
		end
	end
	rich.adjustWidth(richText, lineWidth, verticalSpace)

	-- "#C0x5B545B##C0x5C9971#hello#C0x5B545B#福星高照，抢到#C0xE69900#112#Iconfig/item/icon_ghb.png-64-64##C0x5B545B#！#L10100##LULhttp://www.163.com#[http-link]#L0#over#T15#aaaaa"
	-- richText:setOpenUrlHandler(function(...)
	-- 	print('!!! setOpenUrlHandler', ...)
	-- 	-- cc.Application:getInstance():openURL(...)
	-- end)
	return richText
end

-- 获取richtext格式信息
-- 现在只提供给SRichText使用
function rich.createElemsWithWidth(strOrArray, size, deltaSize, lineWidth)
	if LOCAL_LANGUAGE == "en" then
		return _getRichTextsWordLineFeed(strOrArray, size, deltaSize, lineWidth, true)
	else
		if type(strOrArray) == "table" then
			return _getRichTextsByArray(strOrArray, size, deltaSize)
		else
			return _getRichTextsByStr(strOrArray, size, deltaSize)
		end
	end
end