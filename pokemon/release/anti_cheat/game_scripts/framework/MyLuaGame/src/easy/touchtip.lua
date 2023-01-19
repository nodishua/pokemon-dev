--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 长按框
-- 这个文件里面require 对应的长按框文件 例如
-- local test = require "longTouch.testLongTouchPane"
-- table.insert(M, test)
-- 之后会根据参数里面的 panelType 类型来M里面取出来 这里必须要加注释
--

globals.tip = {}

-- view: 长按框
local function adaptView(view, parent, params)
	local relativeNode = params.relativeNode
	local dir = params.dir
	if not (relativeNode and view) then
		return
	end
	local canvasDir = params.canvasDir
	if not canvasDir or canvasDir == "" then
		canvasDir = "vertical"
	end
	local offx, offy = params.offx or 0, params.offy or 0
	local distance = 14
	local s1 = relativeNode:getBoundingBox()
	local node = params.node
	local pos = gGameUI:getConvertPos(relativeNode, node)
	local x,y = pos.x,pos.y
	local resNode = view:getResourceNode()
	local s2 = resNode:getBoundingBox()
	--TODO:增加一个table用来判定需要显示物体的子节点的size。
	local childsName = params.childsName
	local canvas = resNode:getBoundingBox()
	local s2 = canvas
	if childsName and itertools.size(childsName) > 0 then
		s2 = resNode:get(unpack(childsName)):size()
	end

	local ra = resNode:getAnchorPoint()
	local pa = relativeNode:getAnchorPoint()
	local tx,ty = 0, 0
	local function panelInnerCanvas(showX, showY)
		if showY > canvas.height - (1 - ra.y) * s2.height then
			showY = canvas.height - (1 - ra.y) * s2.height
		elseif showY < ra.y * s2.height then
			showY =  ra.y * s2.height
		end
		if showX < ra.x * s2.width + canvas.x then
			showX = ra.x * s2.width + canvas.x
		elseif showX > canvas.width  - (1 - ra.x) * s2.width + canvas.x then
			showX = canvas.width  - (1 - ra.x) * s2.width + canvas.x
		end
		return showX, showY
	end
	local funcs = {
		top = function()
			ty = y + (1 - pa.y) * s1.height + s2.height*ra.y + distance
			local lx = x - s1.width * pa.x
			tx = lx + s1.width/2
			return cc.p(panelInnerCanvas(tx + offx, ty + offy))
		end,
		right = function()
			tx = x + s1.width * (1 - pa.x) + s2.width * ra.x + distance
			local dy = y - s1.height * pa.y
			ty = dy + s1.height/2
			return cc.p(panelInnerCanvas(tx + offx, ty + offy))
		end,
		down = function()
			ty = y - pa.y * s1.height - s2.height * (1 - ra.y) - distance
			local lx = x - s1.width*pa.x
			tx = lx + s1.width/2
			return cc.p(panelInnerCanvas(tx + offx, ty + offy))
		end,
		left = function()
			tx = x - s1.width * pa.x - s2.width * (1 - ra.x) - distance
			local dy = y - s1.height * pa.y
			ty = dy + s1.height/2
			return cc.p(panelInnerCanvas(tx + offx, ty + offy))
		end,
	}
	if not dir or dir == "" then
		local canvas = resNode:getBoundingBox()
		local midX = canvas.width / 2
		local midY = canvas.height / 2
		if canvasDir == "vertical" then
			--true为父物体节点在canvas上方，false为父物体节点在canvas下方
			dir = pos.y >= midY and "down" or "top"
		elseif canvasDir == "horizontal" then
			--true为父物体节点在canvas右方，false为父物体节点在canvas左方
			dir = pos.x >= midX and "left" or "right"
		end
		pos = funcs[dir]()
	else
		pos = funcs[dir]()
	end
	resNode:setPosition(pos)
	view:z(params.z or 9999)
end

tip.adaptView = adaptView

-- tip.create('tips.card', self, {relativeNode=self.inputWidget.btnLogin}):init({data})
-- params{panelType,parent:一般是self, relativeNode:被长按的控件 dir:加在哪个位置 node:转换坐标用 z:层级}
function tip.create(name, parent, params, ...)
	local view = gGameUI:createView(name, parent):init(...)
	if view then
		adaptView(view, parent, params)
	end
	return view
end

