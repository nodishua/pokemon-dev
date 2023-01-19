-- @Date:   2019-05-16
-- @Desc:
-- @Last Modified time: 2019-06-10
local helper = require "easy.bind.helper"

local rotationSpine = class("rotationSpine", cc.load("mvc").ViewBase)

rotationSpine.defaultProps = {
	data = nil, -- 御三家的id
	unitRes = nil,
	a = 500, --椭圆半长轴
	b = 300, --椭圆半短轴
	maxScale = 3, --c位大小
	minScale = 2,
	isClockWise = false, -- 默认逆时针
	onNode = nil,
	textNode = nil,
	icon = nil,
	clickCb = nil,
}
-- 顺时针 1,2,3-> 2,3,1 逆时针1,2,3->3,1,2
function rotationSpine:rotation(isClockWise, pos, scales)
	audio.playEffectWithWeekBGM("slip.mp3")
	local judgePos = isClockWise and 1 or 3
	local last = self.spriteArr[judgePos]
	pos = pos and #pos == 3 and pos or self.pos
	scales = scales and #scales == 3 and scales or self.scales
	local begin = isClockWise and 3 or 1
	local endPos = isClockWise and 1 or 3
	local step = isClockWise and -1 or 1
	for j = begin, endPos, step do
		self.spriteArr[j]:z(isClockWise and 10 + j or 10 - j)
		local diffX = j == judgePos and math.abs((2 * self.a - math.abs(pos[j].x - self.pos[j].x)))/2
		  or math.abs((self.a - math.abs(pos[j].x - self.pos[j].x)))
		local times = math.ceil(diffX/self.a * 30)
		if diffX ~= 0 then
			self.spriteArr[j]:stopAllActions()
			local try = transition.executeSequence(self.spriteArr[j])
			for i = 1, times do
				local x
				if isClockWise then
					x = j == 1 and pos[j].x + i * (2*diffX)/times or pos[j].x - i * diffX/times
				else
					x = j == 3 and pos[j].x - i * (2*diffX)/times or pos[j].x + i * diffX/times
				end
				local y, scale = self:getY(x, j, isClockWise)
				try:spawnBegin()
					:scaleTo(0.02, scale)
					:moveTo(0.02, x, y)
					:spawnEnd()
			end
			if j == 2 then
				try:func(function()
					local effect = self.spriteArr[j]:get("effect")
					effect:play("standby2")
					effect:addPlay("standby_loop")
				end)
			end
			try:done()
		else
			self.spriteArr[j]:xy(pos[j])
				:scale(scales[j])
		end
	end
	begin = isClockWise and 1 or 3
	endPos = isClockWise and 3 or 1
	step = isClockWise and 1 or -1
	judgePos = isClockWise and 3 or 1
	for i = begin, endPos, step do
		self.spriteArr[i] = i == judgePos and last or self.spriteArr[isClockWise and (i+1) or (i-1)]
	end
	if self.textNode then
		local id = self.spriteArr[2]:getTag()
		local card = csv.cards[id]
		local unit = csv.unit[card.unitID]
		self.textNode:text(card.name)
		if self.icon then
			self.icon:texture(ui.ATTR_ICON[unit.natureType])
		end
	end
end
-- 椭圆公式
function rotationSpine:getY(x, index, isClockWise)
	local a2 = self.a*self.a
	local b2 = self.b*self.b
	local x2 = (x - self.a) * (x - self.a)
	local y
	local scale
	if isClockWise then
		if index == 1 then
			y = math.sqrt(((1- (x2/a2)) * b2)) + self.b
			scale = self.minScale
		else
			y = -math.sqrt(((1- (x2/a2)) * b2)) + self.b
			scale = math.abs(self.b - y)/self.b * math.abs(self.maxScale - self.minScale) + self.minScale
		end
	else
		if index == 3 then
			y = math.sqrt(((1- (x2/a2)) * b2)) + self.b
			scale = self.minScale
		else
			y = -math.sqrt(((1- (x2/a2)) * b2)) + self.b
			scale = math.abs(self.b - y)/self.b * math.abs(self.maxScale - self.minScale) + self.minScale
		end
	end
	return y, scale
end

function rotationSpine:touchEventListener(panel, cb, index)
	local time = 0
	local dt = 5
	local function timeAdd(dt)
		time = time + dt
	end
	local newPos = {}
	local newScale = {}
	local beginPosX, offsetX =0, 0
	panel:addTouchEventListener(function(sender, eventType)
		if eventType == ccui.TouchEventType.began then
			local beganPos = sender:getTouchBeganPosition()
			time = 0
			self:schedule(timeAdd, 0.1, 0, 2)
			beginPosX = beganPos.x
		elseif eventType == ccui.TouchEventType.moved then
			self:unSchedule(1)
			local movedPos = sender:getTouchMovePosition()
			offsetX = movedPos.x - beginPosX
			local isClockWise = offsetX < 0
			if isClockWise then
				offsetX = offsetX <= -self.a and -self.a or offsetX
			else
				offsetX = offsetX >= self.a and self.a or offsetX
			end
			local judgePos = isClockWise and 1 or 3

			for i,v in ipairs(self.pos) do
				local y, scale
				if i == judgePos then
					y, scale = self:getY(v.x - 2 * offsetX, i, isClockWise)
					newPos[i] = cc.p(v.x - 2 * offsetX, y)
				else
					y, scale = self:getY(v.x + offsetX, i, isClockWise)
					newPos[i] = cc.p(v.x + offsetX, y)
				end
				newScale[i] = scale
			end

			for i=1,3 do
				self.spriteArr[i]:xy(newPos[i])
					:scale(newScale[i])
					:z(isClockWise and 10+i or 10-i)
			end
		elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
			local endPos = sender:getTouchEndPosition()
			self:unSchedule(2)

			self:unSchedule(1)
			if math.abs(endPos.x - beginPosX) < 5 then
				for i=1,3 do
					self.spriteArr[i]:xy(self.pos[i])
						:scale(self.scales[i])
				end
				if index then
					self:clickCb(index)
				end
			else --if math.abs(offsetX) >= self.a/5 or math.abs(offsetX) / time > self.a then
				self:rotation(offsetX < 0, newPos, newScale)
			end
			newPos = {}
			newScale = {}
			self:schedule(cb, dt, 5, 1)
		end
	end)
end

function rotationSpine:initExtend()
	local size = cc.size(2*self.a, 5*self.b)
	local panel = ccui.Layout:create()
		:size(size)
		:addTo(self, 10)
		:alignCenter(self:size())
		:setTouchEnabled(true)

	self.spriteArr = {}
	self.pos = {cc.p(0, self.b), cc.p(self.a, 0), cc.p(2*self.a, self.b)}
	self.scales = {self.minScale, self.maxScale, self.minScale}

	local _playAction = function(dt)
		self:rotation(self.isClockWise)
	end

	local dt = 5
	self:enableSchedule()
		:schedule(_playAction, dt, 5, 1)

	-- 原点：self.a, self.b
	for i,v in ipairs(self.data) do
		local unit = csv.unit[csv.cards[v].unitID]
		local unitRes = self.unitRes and self.unitRes[i] or unit.unitRes
		local spinePanel = ccui.Layout:create()
			:setTag(v)
			:addTo(panel, 10)
			:anchorPoint(cc.p(0.5, 0.1))
			:xy(self.pos[i])
			:setTouchEnabled(true)
			:scale(self.scales[i])

		local spine = widget.addAnimationByKey(spinePanel, unitRes, "effect", "standby_loop")
		local box = spine:getBoundingBox()
		spinePanel:size(box)
		spine:xy(box.width/2, 60)
		if i == 2 then
			spine:play("standby2")
			spine:addPlay("standby_loop")
		end
		self:touchEventListener(spinePanel, _playAction, i)
		table.insert(self.spriteArr, spinePanel)
	end
	self:touchEventListener(panel, _playAction)
	if self.onNode then
		self:onNode(panel)
	end
	return self
end

return rotationSpine