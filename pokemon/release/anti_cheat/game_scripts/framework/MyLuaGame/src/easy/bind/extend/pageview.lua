--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ccui.PageView的react形式的扩展
--

local listview = require "easy.bind.extend.listview"
local helper = require "easy.bind.helper"

local pageview = class("pageview", listview)

pageview.defaultProps = {
	-- onXXXX 响应函数
	-- 数据 array table, function
	data = nil,
	-- 数量 nil 自动
	itemSize = nil,
	-- item模板
	item = nil,
	-- 异步加载, nil 不使用异步加载, >=0 预加载数量
	asyncPreload = nil,
	preloadCenter = nil, -- key in data
	preloadBottom = nil,
}

function pageview:initExtend()
	self.backupCached = false
	return listview.initExtend(self)
end

function pageview:insertCustomItem(item, idx)
	return self:insertPage(item, idx)
end

function pageview:pushBackCustomItem(item)
	return self:addPage(item)
end

function pageview:removeItem(idx)
	return self:removePageAtIndex(idx)
end

function pageview:onAfterBuild_()
	self:setRenderHint(0)
	self:onAfterBuild()
end

return pageview