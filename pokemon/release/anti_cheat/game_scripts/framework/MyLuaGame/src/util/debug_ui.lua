--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2020 TianJi Information Technology Inc.
--

local FontName = "宋体"

local tjuidebug = {}
globals.tjuidebug = tjuidebug

function tjuidebug.getDebugBox(child, text, color, lineWidth, textColor)
	display.director:setFontAutoScaleDownEnabled(false)
	lineWidth = lineWidth or 3
	local draw = cc.DrawNode:create()
	local p = child:getParent():convertToWorldSpace(cc.p(child:getPosition()))
	local ax, ay = p.x, p.y
	local rect = child:getContentSize()
	local box = child:getBoundingBox()
	local anchor = child:getAnchorPoint()
	local x, y = ax - box.width * anchor.x, ay - box.height * anchor.y
	-- print(tostring(child), tolua.type(child), child:getTag(), child:getName(), x, y, 'world', p.x, p.y, 'box', box.width, box.height, 'rect', rect.width, rect.height, 'anchor', anchor.x, anchor.y)

	draw:drawSegment(cc.p(0, 0), cc.p(box.width, 0), lineWidth, color)
	draw:drawSegment(cc.p(box.width, 0), cc.p(box.width, box.height), lineWidth, color)
	draw:drawSegment(cc.p(box.width, box.height), cc.p(0, box.height), lineWidth, color)
	draw:drawSegment(cc.p(0, box.height), cc.p(0, 0), lineWidth, color)
	draw:drawSegment(cc.p(0, 0), cc.p(box.width, box.height), lineWidth, color)
	draw:drawDot(cc.p(box.width * anchor.x, box.height * anchor.y), 6, color)
	draw:setPosition(x, y)

	local label = cc.Label:createWithSystemFont(text, FontName, 60)
	label:enableOutline(cc.c4b(0, 0, 0, 255), 3)
	label:setPosition(box.width * anchor.x, box.height * anchor.y):name("label")
	if textColor then
		label:setTextColor(textColor) -- cc.c4b
	end
	draw:addChild(label)
	display.director:setFontAutoScaleDownEnabled(true)
	return draw
end


local function dfsChilds(node, debugNode, filter)
	for _, child in pairs(node:getChildren()) do
		dfsChilds(child, debugNode, filter)
		if filter(child) then
			local c4f = cc.c4f(math.random(), math.random(), math.random(), 1)
			local draw = tjuidebug.getDebugBox(child, tj.type(child), c4f, 1, cc.convertColor(c4f, "4b"))
			debugNode:add(draw)
		end
	end
end

function tjuidebug.showDebugBox(parent, filter)
	local debugNode = cc.Node:create()
	dfsChilds(parent, debugNode, filter)
	gGameUI.uiRoot:removeChildByName("_debug_node_")
	gGameUI.uiRoot:addChild(debugNode, 0, "_debug_node_")
end