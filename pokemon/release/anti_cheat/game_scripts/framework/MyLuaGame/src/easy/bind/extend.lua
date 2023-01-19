--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ViewBase bind extend类相关
--

local helper = require "easy.bind.helper"
local inject = require "easy.bind.extend.inject"

local classCache = {}

-- extend
-- @param class: 关联类；string
function bind.extend(view, node, b)
	if b.class then
		-- 延迟绑定，类名
		view:deferUntilCreated(function()
			logf.bind("%s - %s extend %s", tostring(view), tostring(node), b.class)
			if b.handlers then
				logf.bind.handlers("%s %s", tostring(node), dumps(b.handlers))
			end
			if b.props then
				logf.bind.props("%s %s", tostring(node), dumps(b.props))
			end
			local clsPath
			local cls = classCache["easy.bind.extend." .. b.class] or classCache["app.easy.bind.extend." .. b.class]
			if not cls then
				xpcall(function()
					clsPath = "easy.bind.extend." .. b.class
					cls = require(clsPath)
				end,
				function()
					clsPath = "app.easy.bind.extend." .. b.class
					cls = require(clsPath)
				end)
				if cls == nil then
					error(string.format("%s extend not existed", b.class))
				end
				classCache[clsPath] = cls
				printInfo("%s be loaded in %s", b.class, clsPath)
			end
			inject(cls, view, node, b.handlers, helper.props(view, node, b.props))
				:initExtend()
			if helper.isHelper(b.props and b.props.data) then
				idlersystem.onBindNode(node, tostring(b.props.data))
			end
		end)
	end
end

