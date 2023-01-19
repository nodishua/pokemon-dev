--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- cc.Node原生类的扩展
--

local Node = cc.Node

local nodetools_get = nodetools.get
local nodetools_multiget = nodetools.multiget

function Node:get(...)
	return nodetools_get(self, ...)
end

function Node:multiget(...)
	return nodetools_multiget(self, ...)
end

function Node:size(widthOrSize, height)
	-- getter
	if widthOrSize == nil then
		-- return cc.size
		return self:getContentSize()
	end
	-- setter
	if height then
		self:setContentSize(widthOrSize, height)
	else
		self:setContentSize(widthOrSize)
	end
	return self
end

function Node:width(width)
	local size = self:getContentSize()
	-- getter
	if width == nil then
		return size.width
	end
	-- setter
	self:setContentSize(width, size.height)
	return self
end

function Node:height(height)
	local size = self:getContentSize()
	-- getter
	if height == nil then
		return size.height
	end
	-- setter
	self:setContentSize(size.width, height)
	return self
end

function Node:parent(parent)
	-- getter
	if parent == nil then
		return self:getParent()
	-- setter
	else
		self:setParent(parent)
		return self
	end
end

function Node:tag(tag)
	-- getter
	if tag == nil then
		return self:getTag()
	-- setter
	else
		self:setTag(tag)
		return self
	end
end

function Node:name(name)
	-- getter
	if name == nil then
		return self:getName()
	-- setter
	else
		self:setName(name)
		return self
	end
end

function Node:xy(x, y)
	-- getter
	if x == nil then
		-- x, y
		return self:getPosition()
	end
	-- setter
	if y then
		self:setPosition(x, y)
	else
		self:setPosition(x)
	end
	return self
end

function Node:x(x)
	-- getter
	if x == nil then
		return self:getPositionX()
	-- setter
	else
		self:setPositionX(x)
		return self
	end
end

function Node:y(y)
	-- getter
	if y == nil then
		return self:getPositionY()
	-- setter
	else
		self:setPositionY(y)
		return self
	end
end

function Node:z(z)
	-- getter
	if z == nil then
		return self:getLocalZOrder()
	-- setter
	else
		self:setLocalZOrder(z)
		return self
	end
end

function Node:scale(x, y)
	-- getter
	if x == nil then
		-- scale
		return self:getScale()
	end
	-- setter
	if y then
		self:setScale(x, y)
	else
		self:setScale(x)
	end
	return self
end

function Node:scaleX(x)
	-- getter
	if x == nil then
		-- x
		return self:getScaleX()
	-- setter
	else
		self:setScaleX(x)
		return self
	end
end

function Node:scaleY(y)
	-- getter
	if y == nil then
		-- y
		return self:getScaleY()
	-- setter
	else
		self:setScaleY(y)
		return self
	end
end

function Node:globalZ(z)
	-- getter
	if z == nil then
		return self:getGlobalZOrder()
	-- setter
	else
		self:setGlobalZOrder(z)
		return self
	end
end

function Node:anchorPoint(x, y)
	-- getter
	if x == nil then
		return self:getAnchorPoint()
	end
	-- setter
	if y then
		self:setAnchorPoint(x, y)
	else
		self:setAnchorPoint(x)
	end
	return self
end

function Node:opacity(opacity)
	-- getter
	if opacity == nil then
		return self:getOpacity()
	-- setter
	else
		self:setOpacity(opacity)
		return self
	end
end

function Node:color(color)
	-- getter
	if color == nil then
		-- cc.c3b
		return self:getColor()
	-- setter
	else
		self:setColor(color)
		return self
	end
end

function Node:visible(v)
	-- getter
	if v == nil then
		return self:isVisible()
	-- setter
	else
		self:setVisible(v)
		return self
	end
end

-- setString不是Node实现的接口
-- 只是子类用的地方比较多，子类之间也没唯一的继承关系，所以text放这先
function Node:text(s)
	-- getter
	if s == nil then
		return self:getString()
	-- setter
	else
		self:setString(s)
		return self
	end
end

function Node:box(rect)
	-- getter
	if v == nil then
		return self:getBoundingBox()
	-- setter
	else
		self:setBoundingBox(rect)
		return self
	end
end

function Node:alignCenter(size)
	self:setAnchorPoint(cc.p(0.5, 0.5))
	return self:move(size.width/2, size.height/2)
end

function Node:listenIdler(pathOrIdler, f)
	local idler = pathOrIdler
	if type(pathOrIdler) == "string" then
		idler = self[pathOrIdler]
	end
	if idler == nil then return end

	local key = idler:addListener(function(val, oldval, idler)
		return f(val, oldval, idler, self)
	end)

	local cb
	cb = self:onNodeEvent("exit", function(...)
		-- print('Node exit', tostring(self), tolua.getpeer(self), key)
		cb:remove()
		key:detach()
	end)
end