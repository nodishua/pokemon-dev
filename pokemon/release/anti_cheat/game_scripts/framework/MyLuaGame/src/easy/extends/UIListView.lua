--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ccui.ListView原生类的扩展
--

local ListView = ccui.ListView

-- 自适应 如果 list 内容没有超出 innerSize, 则取消list响应
function ListView:adaptTouchEnabled()
	self:refreshView()
	local size = self:size()
	local innerSize = self:getInnerContainerSize()
	self:setTouchEnabled(innerSize.width > size.width or innerSize.height > size.height)
	return self
end

-- 获得内部item的范围
function ListView:getInnerItemSize()
	local count = self:getChildrenCount()
	if count == 0 then
		return cc.size(0, 0)
	end
	self:refreshView()
	local lastItem = self:getItem(count - 1)
	local width = lastItem:x() + (1 - lastItem:anchorPoint().x) * lastItem:size().width
	local lowerY = lastItem:y() - lastItem:anchorPoint().y * lastItem:size().height
	local firstItem = self:getItem(0)
	local height = firstItem:y() + (1 - firstItem:anchorPoint().y) * firstItem:size().height - lowerY
	return cc.size(width, height)
end

-- 设置 innerItem 居中显示效果, 会改变list的位置
function ListView:setItemAlignCenter(originSize)
	-- has refreshView
	local innerSize = self:getInnerItemSize()
	local size = self:size()
	if originSize then
		self.__originSize = originSize

	elseif not self.__originSize then
		self.__originSize = size
	end

	local tSize
	if self:getDirection() == ccui.ListViewDirection.horizontal then
		tSize = cc.size(math.min(self.__originSize.width, innerSize.width), self.__originSize.height)
	else
		tSize = cc.size(self.__originSize.width, math.min(self.__originSize.height, innerSize.height))
	end
	self:size(tSize)

	local dx = (size.width - tSize.width) / 2
	self:x(self:x() + dx * self:scaleX())
	local dy = (size.height - tSize.height) / 2
	self:y(self:y() + dy * self:scaleY())
	return self
end
