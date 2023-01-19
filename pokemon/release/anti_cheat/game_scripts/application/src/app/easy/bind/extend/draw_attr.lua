-- @date: 2019-01-10 17:15:34
-- @desc:六边形

local helper = require "easy.bind.helper"
local drawAttr = class("drawAttr", cc.load("mvc").ViewBase)

-- 属性的最大值
local ATTR_MAX_VAL = 31

drawAttr.defaultProps = {
	--展示类型
	type = "small",
	--六个文字的相对边的偏移
	offsetPos = {
		{x = 0, y = 0},
		{x = 0, y = 0},
		{x = 0, y = 0},
		{x = 0, y = 0},
		{x = 0, y = 0},
		{x = 0, y = 0},
	},
	--展示数据
	nvalue = {0,0,0,0,0,0},
	--锁回调
	lockCb = nil,
	--是否有锁
	lock = false,
	--这个panel的位置偏移
	offset = nil,
	--选中精灵id
	selectDbId = nil,
	--锁的状态
	nvalueLocked = nil,
	onNode = nil,
	perfectShow = true,
	bgScale = nil,
	textFontSize = nil,
	numFontSize = nil
}

local hexagonItem = {}
hexagonItem.RESOURCE_FILENAME = "common_hexagon_item.json"
hexagonItem.RESOURCE_BINDING = {
	["panel"] = "panel",
	["perfect"] = "panel.perfect",
	["txt"] = "panel.txt",
	["lock"] = "panel.lock",
	["num"] = "panel.num",
	["imgType"] = "panel.imgType",
}

function drawAttr:refresh(nvalue)
	local img = self.panel:get("img")
	local bgSize = img:size()
	local drawNode = img:get("MyDrawNode")
	if not drawNode then
		drawNode = cc.DrawNode:create()
		drawNode:alignCenter(img:size())
			:addTo(img, 3, "MyDrawNode")
	end
	drawNode:clear()
	local x, y = 0, 0
	local d = 220
	local g3 = math.sqrt(3) -- 根号3的结果
	-- 从六边形的上定点顺时针顺序 y坐标做种画的时候需要乘上系数
	-- 系数计算方式：属性值/属性max
	local dLength = {}
	for i, v in ipairs(game.ATTRDEF_SIMPLE_TABLE) do
		table.insert(dLength, d * (nvalue[v] or 0) / ATTR_MAX_VAL)
	end
	local pointTab = {
		cc.p(x, y + dLength[1]),
		cc.p(x + (dLength[2] / 2) * g3, y + dLength[2] / 2),
		cc.p(x + (dLength[3] / 2) * g3, y - dLength[3] / 2),
		cc.p(x, y - dLength[4]),
		cc.p(x - (dLength[5] / 2) * g3, y - dLength[5] / 2),
		cc.p(x - (dLength[6] / 2) * g3, y + dLength[6] / 2)
	}
	local size = self.item:size()
	local offset = cc.p(bgSize.width/2 + 90, bgSize.height - 50)
	local offsetPos = self.offsetPos
	local itemPos = {
		cc.p(offset.x + offsetPos[1].x, offset.y + d + offsetPos[1].y),
		cc.p(offset.x + (d / 2) * g3 + offsetPos[2].x, offset.y + d / 2 + offsetPos[2].y),
		cc.p(offset.x + (d / 2) * g3 + offsetPos[3].x, offset.y - d / 2 + offsetPos[3].y),
		cc.p(offset.x + offsetPos[4].x, offset.y - d + offsetPos[4].y),
		cc.p(offset.x - (d / 2) * g3 + offsetPos[5].x, offset.y - d / 2 + offsetPos[5].y),
		cc.p(offset.x - (d / 2) * g3 + offsetPos[6].x, offset.y + d / 2 + offsetPos[6].y)
	}
	local hash3 = arraytools.hash({3, 4, 5})
	for i,v in ipairs(self.itemNodes) do
		local anchorPointX = self.lock and 1 or 0.5
		local offsetX = self.lock and v:get("lock"):x()-30 or (v:get("txt"):x() + v:get("txt"):width()/2)
		if self.numFontSize then
			v:get("num"):setFontSize(self.numFontSize)
			if hash3[i] then
				v:get("num"):y(v:get("txt"):y() - v:get("txt"):height()/2 - v:get("num"):height()/2)
			else
				v:get("num"):y(v:get("txt"):y() + v:get("txt"):height()/2 + v:get("num"):height()/2)
			end
		end
		v:get("num"):text(nvalue[game.ATTRDEF_SIMPLE_TABLE[i]])
			:anchorPoint(anchorPointX, 0.5)
			:x(offsetX)
		v:get("perfect"):visible(nvalue[game.ATTRDEF_SIMPLE_TABLE[i]] == ATTR_MAX_VAL and self.perfectShow)
		v:xy(itemPos[i])
	end

	local idx = 1
	for i = 1, #pointTab do
		local ps = {
			pointTab[idx],
			(pointTab[idx + 1] or pointTab[1]),
			cc.p(x, y)
		}
		drawNode:drawPolygon(ps, 3, cc.c4f(241 / 255, 92 / 255, 98 / 255, 0.6), 0.5, cc.c4f(241 / 255, 92 / 255, 98 / 255, 0.6))
		idx = idx + 1
	end
	img:xy(self.offset.x, self.offset.y)
end

function drawAttr:baseShow()
	self.itemNodes = {}
	local panel = ccui.Layout:create()
		:size(198, 198)
		:alignCenter(self:size())
		:addTo(self, 1, "_draw_")
	local img = self:get("img")
	if not img then
		local scale = self.bgScale or (self.type == "small" and 1.8 or 1)
		img = ccui.ImageView:create("city/card/system/nvalue/bg_individual.png")
			:scale(scale)
			:addTo(panel, 2, "img")
			:alignCenter(panel:size())
	end
	self.panel = panel
	local hexagonItemView = gGameUI:createSimpleView(hexagonItem, self):init()
	hexagonItemView:hide()
	self.item = hexagonItemView.panel
	self.item:hide()
	local childs = self.item:multiget("perfect", "txt", "lock", "imgType", "num")
	if self.type == "small" then
		itertools.invoke({childs.txt, childs.num}, "setFontSize", 45)
		childs.txt:y(childs.txt:y() - 10)
		childs.lock:hide()
	elseif self.lock == false then
		childs.lock:hide()
	end
	local hash1 = arraytools.hash({1})

	local hash2 = arraytools.hash({2, 6})
	local hash3 = arraytools.hash({3, 4, 5})
	for i = 1, 6 do
		local itemClone = self.item:clone():tag(i):scale((self.type == "small" and 0.68 or 1))
		table.insert(self.itemNodes, itemClone)
		local childs = itemClone:multiget("perfect", "txt", "lock", "imgType", "num")
		childs.txt:text(getLanguageAttr(game.ATTRDEF_SIMPLE_TABLE[i]))
		if self.textFontSize then
			childs.txt:setFontSize(self.textFontSize)
		end
		childs.imgType:texture(ui.ATTR_LOGO[game.ATTRDEF_SIMPLE_TABLE[i]])
		itemClone:show()
		itemClone:addTo(self.panel, 5)
		if hash3[i] then
			local y1 = childs.num:y()
			childs.perfect:y(y1 - 55)
			itertools.invoke({childs.imgType, childs.txt}, "y", y1 + 50)
		end
		if hash2[i] then
			local y1 = childs.txt:y()
			childs.perfect:y(y1 - 60)
		end
	end
end

function drawAttr:initExtend()
	self:baseShow()
	helper.callOrWhen(self.nvalue, functools.partial(self.refresh, self))
	if self.nvalueLocked then
		idlereasy.when(self.nvalueLocked, function (_, nvalueLocked)
			local tmpLockNum = 0
			for i,v in ipairs(game.ATTRDEF_SIMPLE_TABLE) do
				if nvalueLocked[v] then
					tmpLockNum = tmpLockNum + 1
				end
			end
			for i,v in ipairs(game.ATTRDEF_SIMPLE_TABLE) do
				local state = nvalueLocked[v] or false
				local lockImg = "common/btn/btn_unlock_big.png"
				if state then
					lockImg = "common/btn/btn_lock_big.png"
				end
				local node = self.itemNodes[i]
				local lock = self.itemNodes[i]:get("lock")
				local num = self.itemNodes[i]:get("num")
				lock:show()
				lock:texture(lockImg)
				adapt.oneLinePos(self.itemNodes[i]:get("txt"), lock, cc.p(-55,0), "left")
				adapt.oneLinePos(lock, num, cc.p(5,0), "right")
				if lock and self.lockCb then
					bind.touch(self, node, {methods = {ended = function()
						self.lockCb(self, i, self.selectDbId, tmpLockNum, state)
					end}})
					lock:setTouchEnabled(true)
					bind.touch(self, lock, {methods = {ended = function()
						self.lockCb(self, i, self.selectDbId, tmpLockNum, state)
					end}})
				end
			end
		end)
	end
	if self.onNode then
		self.onNode(self.panel)
	end
	return self
end

return drawAttr
