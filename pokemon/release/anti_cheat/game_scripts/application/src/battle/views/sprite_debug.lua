--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- BattleSprite调试用
--

local LineSize = 6
local DotSize = 10
local FontSize = 30
local EffectFontSize = 30
local TopZ = 999999
local LabelAnchor = cc.p(0.5, 1)

local function createLabel(color, y, parent, fontSize)
	fontSize = fontSize or FontSize
	local lbl = cc.Label:createWithTTF("", ui.FONT_PATH, fontSize, cc.size(0, 0), cc.TEXT_ALIGNMENT_CENTER)
	lbl:align(LabelAnchor, 0, y):addTo(parent, TopZ)
		:setTextColor(cc.convertColor(color, "4b"))
	lbl:enableShadow(cc.c4b(0,0,0,255*color.a), cc.size(1, -1))
	-- lbl:enableOutline(cc.c4b(255,255,255,255), 1)
	return lbl
end

local function createDotDraw(color, line, parent)
	local node = cc.DrawNode:create(LineSize)
	node:drawDot(cc.p(0, 0), DotSize, color)
	if line then
		node:drawLine(cc.p(0, 0), cc.p(20, 0), color)
	end
	node:addTo(parent, TopZ)
	return node
end

local function attachNode(src, dst)
	src:retain()
	src:removeSelf():addTo(dst, TopZ)
	src:autorelease()
end

local function createDotDrawAndLabel(color, pos, tag, parent)
	local node = cc.Node:create()
	node:addTo(parent, TopZ)
	node:xy(pos)
	createDotDraw(color, false, node)
	createLabel(color, -FontSize, node)
		:setString(string.format("%s (%d, %d)", tag, pos.x, pos.y))
	return node
end

local function addDebugNode(self)
	-- 红色是worldPos, self世界坐标
	-- 绿色是cspritePos, spine, self.sprite世界坐标
	-- 蓝色是curPos, self:getCurPos()
	-- 黄色是yinying骨骼

	local curPosColor = cc.c4f(0, 0, 1, 0.8)
	local curPosLabel = createLabel(curPosColor, -FontSize, self)
	local curPosDraw
	if self:getParent() then
		curPosDraw = createDotDraw(curPosColor, false, self:getParent())
		curPosDraw:move(self:getCurPos())
		attachNode(curPosLabel, curPosDraw)
	end

	local worldColor = cc.c4f(1, 0, 0, 0.8)
	local worldPosLabel = createLabel(worldColor, -FontSize*2, self)
	local worldPosDraw = createDotDraw(worldColor, true, self)

	local cspriteColor = cc.c4f(0, 1, 0, 0.8)
	local cspritePosLabel = createLabel(cspriteColor, -FontSize*3, self)
	local cspritePosDraw
	if self.sprite then
		cspritePosDraw = createDotDraw(cspriteColor, true, self.sprite.__ani)
	end

	local yinyingColor = cc.c4f(1, 1, 0, 0.8)
	local yinyingPosLabel = createLabel(yinyingColor, -FontSize*4, self)
	local yinyingPosDraw
	if self.sprite then
		yinyingPosDraw = createDotDraw(yinyingColor, false, self.sprite)
	end

	local everyPosColor = yinyingColor
	local headPosNode, lifePosNode, hitPosNode
	if self.unitCfg then
		headPosNode = createDotDrawAndLabel(everyPosColor, self.unitCfg.everyPos.headPos, string.format("[%d] head", self.seat), self)
		lifePosNode = createDotDrawAndLabel(everyPosColor, self.unitCfg.everyPos.lifePos, string.format("[%d] life", self.seat), self)
		hitPosNode = createDotDrawAndLabel(everyPosColor, self.unitCfg.everyPos.hitPos, string.format("[%d] hit", self.seat), self)
	end

	-- update
	local action = cc.RepeatForever:create(cc.Sequence:create(
		cc.CallFunc:create(function()
			if curPosDraw then
				curPosDraw:move(self:getCurPos())
			end
			local yinyingxy = cc.p(0, 0)
			if yinyingPosDraw then
				yinyingxy = self.sprite:getBonePosition("yinying")
				yinyingPosDraw:move(yinyingxy)
			end

			local wxy = self:convertToWorldSpace(cc.p(0, 0))
			local sxy = self.sprite:convertToWorldSpace(cc.p(0, 0))
			curPosLabel:setString(string.format("[%d] cur (%d, %d)", self.seat, self:getCurPos()))
			worldPosLabel:setString(string.format("[%d] world (%d, %d)", self.seat, wxy.x, wxy.y))
			cspritePosLabel:setString(string.format("[%d] csprite (%d, %d)", self.seat, sxy.x, sxy.y))
			yinyingPosLabel:setString(string.format("[%d] yinying (%d, %d)", self.seat, yinyingxy.x, yinyingxy.y))
		end)
	))
	gRootViewProxy:proxy():runAction(action)

	self.debug.nodes = {
		curPos = curPosDraw,
		worldPos = worldPosDraw,
		cspritePos = cspritePosDraw,
		yinyingPos = yinyingPosDraw,

		curPosLabel = curPosLabel,
		worldPosLabel = worldPosLabel,
		cspritePosLabel = cspritePosLabel,
		yinyingPosLabel = yinyingPosLabel,

		headPosNode = headPosNode,
		lifePosNode = lifePosNode,
		hitPosNode = hitPosNode,
	}
	for _, node in pairs(self.debug.nodes) do
		node:retain()
	end
	self.debug.action = action
end

local function addEffectDebugNode(self)
	local effectColor = cc.c4f(1, 0, 0, 1)
	local effectNode = cc.Node:create():addTo(self:getParent(), TopZ)
	local effectLabel = createLabel(effectColor, -EffectFontSize, effectNode, EffectFontSize)
	local infoLabel = createLabel(effectColor, -EffectFontSize*2, effectNode, EffectFontSize)
	infoLabel:setAlignment(cc.TEXT_ALIGNMENT_LEFT, cc.VERTICAL_TEXT_ALIGNMENT_TOP)
	-- may be scene
	if not self.getCurPos then
		effectNode:move(display.top_center)
	end

	-- update
	local action = cc.RepeatForever:create(cc.Sequence:create(
		cc.CallFunc:create(function()
			if self.getCurPos then
				local offset = cc.p(0, 0)
				if self.debug.enabled then
					offset.y = -FontSize*4
				end
				effectNode:move(cc.pAdd(cc.p(self:getCurPos()), offset))
			end

			local queSize = self.effectManager:queueSize()
			local queInfo = self.effectManager:queueInfo()
			local updEffects = self.effectManager.updEffects
			local effSize = 0
			local effInfo = {}
			if updEffects then
				effSize = itertools.size(updEffects)
				effInfo = itertools.map(updEffects, function(k, v)
					return v:debugString()
				end)
			end
			local seat = self.seat and self.seat or "scene"
			effectLabel:setString(string.format("[%s] effect que %d upd %d", seat, queSize, effSize))
			local queStr = ""
			if table.length(queInfo) > 0 then
				queStr = string.format("[%s] que:\n%s\n", seat, table.concat(queInfo, "\n"))
			end
			local effStr = ""
			if table.length(effInfo) > 0 then
				effStr = string.format("[%s] upd:\n%s", seat, table.concat(effInfo, "\n"))
			end
			infoLabel:setString(string.format("%s%s", queStr, effStr))
		end)
	))
	gRootViewProxy:proxy():runAction(action)

	self.effectDebug.nodes = {
		effectNode = effectNode,
	}

	for _, node in pairs(self.effectDebug.nodes) do
		node:retain()
	end
	self.effectDebug.action = action
end

function BattleSprite:setDebugEnabled(flag)
	if flag == self.debug.enabled then return end
	self.debug.enabled = flag
	-- self.sprite.__ani:setDebugBonesEnabled(flag)

	if flag then
		addDebugNode(self)
	else
		for _, node in pairs(self.debug.nodes) do
			node:removeSelf():autorelease()
		end
		gRootViewProxy:proxy():stopAction(self.debug.action)
		self.debug = {
			enabled = false,
		}
	end
end

function BattleSprite:setEffectDebugEnabled(flag)
	if flag == self.effectDebug.enabled then return end
	self.effectDebug.enabled = flag

	if flag then
		if self.effectManager == nil then
			printWarn("%s no effectManager", self)
			return
		end
		addEffectDebugNode(self)
	else
		for _, node in pairs(self.effectDebug.nodes) do
			node:removeSelf():autorelease()
		end
		gRootViewProxy:proxy():stopAction(self.effectDebug.action)
		self.effectDebug = {
			enabled = false,
		}
	end
end

function BattleSprite:debugParents()
	local t = self.sprite.__ani or self.sprite
	local i = 0
	while t do
		local x, y = t:getPosition()
		print('[DBG]', self, i, t, t:getName(), x, y, t:getScaleX(), t:getScaleY())
		t = t:getParent()
		i = i + 1
	end
end

function BattleSprite:debugString()
	return string.format("BattleSprite: %d", self.seat)
end