--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2020 TianJi Information Technology Inc.
--
-- RenderTarget封装
--

-- for debug
globals.CRenderSpritesMap = setmetatable({}, {__mode = "k"})

globals.CRenderSprite = class("CRenderSprite", cc.Node)

local function collectNodes(nodes)
	local t, rect = {}
	for i, node in ipairs(nodes) do
		if type(node) == "table" then
			node = node.node
		end

		local x, y = node:xy()
		local box = cc.utils:getCascadeBoundingBox(node)
		local wpos = node:convertToWorldSpace(cc.p(0, 0))
		local anchor = node:getAnchorPoint()
		-- print('collect node', i, node, x, y, 'size', dumps(node:size()), 'box', dumps(box), 'wpos', dumps(wpos), 'anchor', dumps(anchor))

		local rect2 = cc.rect(wpos.x, wpos.y, box.width, box.height)
		if rect == nil then
			rect = rect2
		else
			rect = cc.rectUnion(rect, rect2)
		end
		table.insert(t, {
			node = node,
			pos = cc.p(x, y),
			world = wpos,
			anchor = anchor,
			capturePos = nil, -- delay calc when capture
		})
	end
	return t, rect
end

function CRenderSprite.newWithNodes(format, ...)
	local nodes, rect = collectNodes({...})
	-- need rect size
	local ret = CRenderSprite.new(rect, format)
	ret.nodes = nodes
	ret.rect = rect
	local name = string.format("_rt_%s_%d_", nodes[1].node:name(), #nodes)
	ret:name(name)
	-- print('CRenderSprite.newWithNodes', #nodes, dumps(rect))
	return ret
end

-- size was fixed and pre-defined NOW
-- anchorPoint was (0, 0) in default, align at left-bottom
function CRenderSprite:ctor(size, format)
	self.rtSize = size
	self.rt = cc.RenderTexture:create(size.width, size.height, format)
	self.nodes = {} -- array
	self.rect = cc.rect(0, 0, size.width, size.height)
	self.offest = nil -- cc.p(0, 0)
	self.touch = false

	cc.Node.setVisible(self, false)
	self:setContentSize(size.width, size.height)
	self:enableNodeEvents()
		:add(self.rt)

	CRenderSpritesMap[self] = true
end

function CRenderSprite:addDebugLayer()
	local size = self.rtSize
	self:add(cc.LayerColor:create(cc.c4b(100, 0, 0, 100), size.width, size.height))
end

function CRenderSprite:setTouchEnabled()
	self.touch = true
	local listener = cc.EventListenerTouchOneByOne:create()
	local eventDispatcher = display.director:getEventDispatcher()
	local function transferTouch(touch, event)
		self:hide()
		for _, t in ipairs(self.nodes) do
			-- refresh the state when capture
			t.visible = nil
		end

		listener:setEnabled(false)
		eventDispatcher:dispatchEvent(event)
		listener:setEnabled(true)
		-- delay it could be avoid crash when node be released
		performWithDelay(self, function()
			self:show()
		end, 0)
		return true
	end
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(transferTouch, cc.Handler.EVENT_TOUCH_BEGAN)
	listener:registerScriptHandler(transferTouch, cc.Handler.EVENT_TOUCH_MOVED)
	listener:registerScriptHandler(transferTouch, cc.Handler.EVENT_TOUCH_ENDED)
	listener:registerScriptHandler(transferTouch, cc.Handler.EVENT_TOUCH_CANCELLED)
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function CRenderSprite:refreshNodes()
	local nodes, rect = collectNodes(self.nodes)
	-- print('CRenderSprite rect old', self, dumps(self.rect), 'new', dumps(rect))
	self.nodes = nodes
	self.rect = rect
end

function CRenderSprite:setCaptureOffest(off)
	self.offest = off
end

local function calcCapturePos(t, size, rect, offest)
	local relOffest = cc.pSub(t.world, rect)
	-- align with node left-bottom
	-- TODO: scale need be considered
	local selfAnchorOffest = cc.p(size.width*t.anchor.x, size.height*t.anchor.y)
	if offest == nil then
		return cc.pAdd(selfAnchorOffest, relOffest)
	end
	return cc.pAdd(offest, cc.pAdd(selfAnchorOffest, relOffest))
end

function CRenderSprite:coverTo(node)
	-- getCascadeBoundingBox more accurate than convertToWorldSpace
	-- because the node coordinate may be not same with image
	-- but it had problem, box is dynamic when the node scaled
	local wpos = cc.utils:getCascadeBoundingBox(node)
	local ppos = self:parent():convertToWorldSpace(cc.p(0, 0))
	local name = string.format("_rt_%s_", node:name())
	return self:xy(wpos.x - ppos.x, wpos.y - ppos.y):name(name)
end

-- you may be captured the wrong image
-- because the nodes would be change pos or visible in the same frame
-- force could be help you capture immediately
function CRenderSprite:_capture()
	self.rt:beginWithClear(0, 0, 0, 0)
	for _, t in ipairs(self.nodes) do
		-- update size realtime
		-- local size = cc.utils:getCascadeBoundingBox(t.node)
		local size = t.node:size()
		t.capturePos = t.capturePos or calcCapturePos(t, size, self.rect, self.offest)
		-- get the init visible state
		-- TODO: t.visible need watch the real state change
		if t.visible == nil then
			t.visible = t.node:visible()
		else
			t.node:setVisible(t.visible)
		end
		t.node:xy(t.capturePos):visit()
	end
	self.rt:endToLua()

	-- touch be call in drawScene.pollEvents
	-- capture will fill some render commands in render queue
	-- then scheduler update may remove the node self
	-- it will crash when cc.RenderTexture destroyed after touch
	-- so force drawOnce more safe
	-- http://172.81.227.66:1104/crashinfo?_id=76048&type=-1
	self.rt:drawOnce(true)
end

function CRenderSprite:refresh()
	local flag = cc.Node.isVisible(self)
	if not flag then return end

	self:_capture()
	-- revert pos back
	for _, t in ipairs(self.nodes) do
		t.node:setVisible(false)
		t.node:xy(t.pos)
	end
end

-- override cc.Node
function CRenderSprite:setVisible(flag)
	if flag == cc.Node.isVisible(self) then
		return
	end

	cc.Node.setVisible(self, flag)
	if flag then
		self:_capture()
	end

	for _, t in ipairs(self.nodes) do
		if flag then
			t.node:setVisible(false)
		elseif t.visible ~= nil then
			t.node:setVisible(t.visible)
		end
		t.node:xy(t.pos)
	end
end

function CRenderSprite:onExit()
	self:hide()
end