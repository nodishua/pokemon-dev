--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ccui.LoadingBar的react形式的扩展
-- 3宫拉伸，右侧进度显示弧度, 原生的进度值小于3宫的最小设置会变形
--

local helper = require "easy.bind.helper"

local loadingbar = class("loadingbar", cc.load("mvc").ViewBase)

loadingbar.defaultProps = {
	-- number or idler
	data = nil,
	maskImg = nil,
	barImg = nil,
	alphaThreshold = 0.15,
}

function loadingbar:initExtend()
	self.getPercentOrigin = self.getPercent
	self.setPercentOrigin = self.setPercent
	self.getPercent = self.getPercent_
	self.setPercent = self.setPercent_
	local size = self:size()
	local rect = self:getCapInsets()
	local isScale9Enabled = self:isScale9Enabled()
	local texture = self:getVirtualRenderer():getTexture()
	self._width = size.width

	-- 隐藏当前控件
	self:opacity(0)

	-- 创建图片要放到 clipping 里
	local img = ccui.Scale9Sprite:create()
	if self.barImg then
		img:initWithFile(rect, self.barImg)
	else
		img:initWithTexture(texture)
	end
	img:setScale9Enabled(isScale9Enabled)
	img:size(size)
		:anchorPoint(0, 0)
		:setCapInsets(rect)
	self.img = img

	-- 设置遮罩
	local mask = ccui.Scale9Sprite:create()
	if self.maskImg then
		mask:initWithFile(rect, self.maskImg)

	elseif self.bar then
		mask:initWithFile(rect, self.barImg)
	else
		mask:initWithTexture(texture)
	end
	mask:setScale9Enabled(isScale9Enabled)
	mask:size(size)
		:anchorPoint(0, 0)
		:setCapInsets(rect)
	self.mask = mask

	cc.ClippingNode:create(mask)
		-- :setInverted(true)
		:setAlphaThreshold(self.alphaThreshold)
		:anchorPoint(0, 0)
		:size(size)
		:add(img)
		:addTo(self)

	-- 若无设置进度值，设置初始值。如果进度条当前进度则读取，或者默认为 100
	if not self.data then
		if self.getPercentOrigin then
			self.data = self:getPercentOrigin()
		else
			self.data = 100
		end
	end
	helper.callOrWhen(self.data, function (data)
		self:setPercentShow_(data)
	end)
	return self
end

function loadingbar:getPercent_()
	return isIdler(self.data) and self.data:get_() or self.data
end

function loadingbar:setPercent_(p)
	if isIdler(self.data) then
		self.data:set(p)
	else
		self.data = p
		self:setPercentShow_(p)
	end
end

function loadingbar:setPercentShow_(p)
	local x = self._width * (p/100 - 1)
	self.img:x(x)
end

function loadingbar:setContentSize(widthOrSize, height)
	if height then
		cc.Node.setContentSize(self, widthOrSize, height)
		self.img:setContentSize(widthOrSize, height)
		self.mask:setContentSize(widthOrSize, height)
		self._width = widthOrSize
	else
		cc.Node.setContentSize(self, widthOrSize)
		self.img:setContentSize(widthOrSize)
		self.mask:setContentSize(widthOrSize)
		self._width = widthOrSize.width
	end
	self:setPercentShow_(self:getPercent_())
	return self
end

return loadingbar