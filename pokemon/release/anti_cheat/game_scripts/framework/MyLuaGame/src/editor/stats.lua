--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- 内置编辑器 - 统计
--

local editor = {}

local LayerW = 800
local LayerH = 500
local FontName = 'consolas'
local FontSize = 30
local StatsFontSize = 30
local UpdateDelta = 1.
local ChartFrameNum = 20
local ChartBaseY = 100
local ChartColors = {
	frames = cc.c4f(1.0, 0, 0, 1.0),
	create_sprites = cc.c4f(0, 1.0, 0, 1.0),
	draw_call = cc.c4f(0, 0, 1.0, 1.0),
	lua_mem = cc.c4f(1.0, 1.0, 0, 1.0),
}
local ChartArgs = {
	frames = {minMetric = 1, maxMetric = 60},
	create_sprites = {minMetric = 1, maxMetric = 100},
	draw_call = {minMetric = 1, maxMetric = 500},
	lua_mem = {minMetric = 1, maxMetric = 500, labelFmt = "%.0f"},
}
local ChartEnables = {
	frames = true,
	create_sprites = true,
	draw_call = true,
	lua_mem = true,
}
local ChartFieldOrder = {
	"frames",
	"create_sprites",
	"draw_call",
	"lua_mem",
}

local CreateTotal = {}
local CreateTotalPrev = 0
local AniMap = {}
local TotalFrames = 0
local Stats = {}

-- inject
require "easy.sprite"
local CSprite_ctor = CSprite.ctor
function CSprite:ctor(...)
	CSprite_ctor(self, ...)
	local ani = self:getAni()
	if ani then
		local typ = tj.type(ani)
		AniMap[ani] = typ

		CreateTotal[typ] = 1 + (CreateTotal[typ] or 0)
	end
	return self
end

local function c4f_c4b(color)
	return cc.c4b(color.r * 255.0, color.g * 255.0, color.b * 255.0, color.a * 255.0)
end

local function initUI(layer)
	local label = cc.Label:createWithSystemFont("total", FontName, FontSize)
	label:xy(0, 0)
		:anchorPoint(0, 0)
	label:setTextColor(cc.c4b(255, 255, 255, 255))
	label:enableBold()
	layer:addChild(label, 9, "total")
	layer.stats = label

	local chart = cc.Node:create()
	chart:xy(0, ChartBaseY)
	for k, v in pairs(ChartEnables) do
		chart[k] = cc.DrawNode:create()
		chart:addChild(chart[k], 1, k)
	end
	layer:addChild(chart, 0, "chart")
	layer.chart = chart

	TotalFrames = display.director:getTotalFrames()
end

local function drawChartLines(draw, field, color, fmt)
	local color4B = c4f_c4b(color)
	local startIndex = math.max(1, #Stats - ChartFrameNum)
	local yMax = fmt.maxMetric or Stats[startIndex][field]
	if fmt.maxMetric == nil then
		for i = startIndex + 1, #Stats do
			yMax = math.max(yMax, Stats[i][field])
		end
	end
	if fmt.minMetric then
		yMax = math.max(fmt.minMetric, yMax)
	end
	local yRatio = 1.0 * (LayerH - 2 * ChartBaseY) / yMax

	local xDelta = LayerW / ChartFrameNum
	local xy1 = cc.p(0, Stats[startIndex][field] * yRatio)
	local prev = nil
	for i = startIndex + 1, #Stats do
		local v2 = Stats[i][field]
		local xy2 = cc.p((i - startIndex) * xDelta, v2 * yRatio)
		draw:drawLine(xy1, xy2, color)
		draw:drawDot(xy2, 2, color)
		-- label
		local v2s = tostring(v2)
		if fmt.labelFmt then
			v2s = string.format(fmt.labelFmt, v2)
		end
		if prev ~= v2s then
			prev = v2s
			local label = cc.Label:createWithSystemFont(v2s, FontName, StatsFontSize)
			label:xy(xy2.x, math.min(xy2.y, LayerH - ChartBaseY - StatsFontSize))
				:anchorPoint(0, 0)
			label:setTextColor(color4B)
			draw:addChild(label, 0, field)
		end

		xy1 = xy2
	end
end

local function updateChart(layer)
	if #Stats <= 1 then
		return
	end
	-- -- remove old
	-- for i = 1, #Stats - ChartFrameNum do
	-- 	table.remove(Stats, 1)
	-- end

	for k, v in pairs(ChartEnables) do
		local draw = layer[k]
		draw:clear()
		draw:removeAllChildren()
		if v then
			drawChartLines(draw, k, ChartColors[k], ChartArgs[k])
		end
	end
end

local function updateUI(layer)
	local total = 0
	for typ, cnt in pairs(CreateTotal) do
		total = total + cnt
	end

	local alive = {}
	local vis = {}
	for ani, typ in pairs(AniMap) do
		if tolua.isnull(ani) then
			AniMap[ani] = nil
		else
			alive[typ] = 1 + (alive[typ] or 0)
			if ani:isVisibleInGlobal() then
				vis[typ] = 1 + (vis[typ] or 0)
			end
		end
	end

	local lines = string.split(display.director:getStats(), "\n")
	local draw_call = 0
	for _, s in ipairs(lines) do
		if s:find("GL calls:") then
			draw_call = tonumber(s:sub(10))
			break
		end
	end
	table.insert(Stats, {
		clock = os.clock(),
		frames = display.director:getTotalFrames() - TotalFrames,
		create_sprites = total - CreateTotalPrev,
		draw_call = draw_call,
		lua_mem = collectgarbage("count") / 1024.0,
	})
	print("Stats", #Stats, dumps(Stats[#Stats]))
	CreateTotalPrev = total
	TotalFrames = display.director:getTotalFrames()
	updateChart(layer.chart)

	local txts = {
		string.format("%-20s Visible/ Alive/ Create", ""),
	}
	for typ, cnt in pairs(CreateTotal) do
		table.insert(txts, string.format("%-20s: %6s/%6s/%6s", typ, vis[typ] or 0, alive[typ] or 0, CreateTotal[typ]))
	end
	layer.stats:setString(table.concat(itertools.reverse(txts), "\n"))
end

local function showHelp(node)
	if node:getChildByName("_help_") then
		node:removeChildByName("_help_")
		return
	end

	local list = ccui.ListView:create()
	list:setAnchorPoint(cc.p(0.5, 0.5))
	list:setContentSize(cc.size(1000, 800))
	list:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
	list:setBackGroundColor(cc.c3b(0, 0, 0))
	list:setBackGroundColorOpacity(150)
	list:setPosition(display.cx, display.cy)

	node:addChild(list, 99999, "_help_")

	local text = ccui.Text:create("H - help", FontName, FontSize*2)
	list:pushBackCustomItem(text)
	local text = ccui.Text:create("D - dump stats", FontName, FontSize*2)
	list:pushBackCustomItem(text)
	local text = ccui.Text:create("= - larger", FontName, FontSize*2)
	list:pushBackCustomItem(text)
	local text = ccui.Text:create("- - smaller", FontName, FontSize*2)
	list:pushBackCustomItem(text)
	local text = ccui.Text:create("1 - chart:create_sprites", FontName, FontSize*2)
	text:setTextColor(c4f_c4b(ChartColors.create_sprites))
	if not ChartEnables.create_sprites then
		text:setTextColor(cc.c4b(100, 100, 100, 255))
	end
	list:pushBackCustomItem(text)
	local text = ccui.Text:create("2 - chart:draw_call", FontName, FontSize*2)
	text:setTextColor(c4f_c4b(ChartColors.draw_call))
	if not ChartEnables.draw_call then
		text:setTextColor(cc.c4b(100, 100, 100, 255))
	end
	list:pushBackCustomItem(text)
	local text = ccui.Text:create("3 - chart:lua_mem", FontName, FontSize*2)
	text:setTextColor(c4f_c4b(ChartColors.lua_mem))
	if not ChartEnables.lua_mem then
		text:setTextColor(cc.c4b(100, 100, 100, 255))
	end
	list:pushBackCustomItem(text)
end

local function dumpStats()
	local filename = os.date("%y%m%d-%H%M%S") .. ".stats.csv"
	local fp = io.open(filename, 'wb')
	for _, key in ipairs(ChartFieldOrder) do
		fp:write(key .. ",")
	end
	fp:write("\n")
	for _, v in ipairs(Stats) do
		for _, key in ipairs(ChartFieldOrder) do
			fp:write(tostring(v[key]) .. ",")
		end
		fp:write("\n")
	end
	fp:close()
	return filename
end

local function initKeyboardMonitor(editor, layer)
	-- 键盘按键按下回调函数
	local function keyboardPressed(keyCode, event)
		print('!!! keyCode', keyCode)

		-- h
		if keyCode == 131 then
			showHelp(editor.node)

		-- d
		elseif keyCode == 127 then
			local filename = dumpStats()
			editor:addTipLabel(filename .. " be saved", "_dumpStats_")

		-- 1
		elseif keyCode == 77 then
			ChartEnables.create_sprites = not ChartEnables.create_sprites

		-- 2
		elseif keyCode == 78 then
			ChartEnables.draw_call = not ChartEnables.draw_call

		-- 3
		elseif keyCode == 79 then
			ChartEnables.lua_mem = not ChartEnables.lua_mem

		-- =
		elseif keyCode == 89 then
			LayerW = LayerW*1.5
			LayerH = LayerH*1.5
			ChartFrameNum = ChartFrameNum*1.2
			layer:xy(display.right - LayerW, display.top - LayerH)
				:changeWidthAndHeight(LayerW, LayerH)

		-- -
		elseif keyCode == 73 then
			LayerW = math.max(LayerW/1.5, 400)
			LayerH = math.max(LayerH/1.5, 250)
			ChartFrameNum = math.max(ChartFrameNum/1.2, 20)
			layer:xy(display.right - LayerW, display.top - LayerH)
				:changeWidthAndHeight(LayerW, LayerH)
		end
	end

	-- 注册键盘监听事件
	local listener = cc.EventListenerKeyboard:create()
	layer.statsKeyboard = listener

	-- 绑定回调函数
	listener:registerScriptHandler(keyboardPressed, cc.Handler.EVENT_KEYBOARD_PRESSED)
	-- listener:registerScriptHandler(keyboardReleased, cc.Handler.EVENT_KEYBOARD_RELEASED)
	local eventDispatcher = layer:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, layer)
end

function editor:onCSpriteStats()
	if self.node:getChildByName("_onCSpriteStats_") then
		self.node:removeChildByName("_onCSpriteStats_")
		Stats = {}
		return
	end

	local layer = cc.LayerColor:create(cc.c4b(0, 0, 0, 150), LayerW, LayerH)
	layer:xy(display.right - LayerW, display.top - LayerH)
	self.node:addChild(layer, 9999, "_onCSpriteStats_")

	initKeyboardMonitor(self, layer)
	initUI(layer)
	updateUI(layer)
	schedule(layer, function()
		updateUI(layer)
	end, UpdateDelta)
end

return editor