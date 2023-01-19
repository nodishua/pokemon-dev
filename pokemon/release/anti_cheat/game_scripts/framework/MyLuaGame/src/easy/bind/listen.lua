--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ViewBase bind listen监听相关
--

local helper = require "easy.bind.helper"

-- listen
-- @param method: view关联函数
-- @param idler: 惰性求值器; 如果是string，则绑定view上的变量；如果是function，则绑定函数返回值
function bind.listen(view, node, b)
	local f = helper.method(view, node, b)

	if b.idler then
		-- 延迟绑定idler变量名
		-- if type(b.idler) == "string" then
		-- 	view:deferUntilCreated(function()
		-- 		logf.bind("%s - %s listen %s", tostring(view), tostring(node), b.idler)
		-- 		view:nodeListenIdler(node, b.idler, f)
		-- 	end)

		-- 延迟绑定function返回值
		if helper.isHelper(b.idler) then
			view:deferUntilCreated(function()
				logf.bind("%s - %s listen %s", tostring(view), tostring(node), tostring(b.idler))
				view:nodeListenIdler(node, b.idler(view), f)
				idlersystem.onBindNode(node, tostring(b.idler))
			end)

		-- 直接绑定idler变量
		else
			view:nodeListenIdler(node, b.idler, f)
			idlersystem.onBindNode(node, tostring(b.idler))
		end
	end
end

