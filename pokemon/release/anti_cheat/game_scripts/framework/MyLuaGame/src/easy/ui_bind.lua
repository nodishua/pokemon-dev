--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ViewBase bind辅助函数
--

local bind = {}
globals.bind = bind

local bindNode

-- @param ui: ViewBase
function globals.bindUI(ui, node, binding)
	for nodeName, nodeBinding in pairs(binding) do
		-- local node = self.resourceNode_:getChildByName(nodeName)
		local node = nodetools.get(node, nodeName)
		if type(nodeBinding) == "table" then
			if nodeBinding.varname then
				logf.alias("%s - %s (%s) -> %s", tostring(ui), tostring(node), nodeName, nodeBinding.varname)
				ui[nodeBinding.varname] = node
			end
			bindNode(ui, node, nodeBinding.binds)
		else
			logf.alias("%s - %s (%s) -> %s", tostring(ui), nodeName, tostring(node), nodeBinding)
			ui[nodeBinding] = node
		end
	end
end

-- 1.bindNode 配置形式（多个bind）
-- 	bindNode(ui, node, {{event = "touch", bounce = true, ...}, ...})
-- 		-> 1:N bind.XXXX
-- 2.bind 调用形式（单个bind）
-- 	bind.touch(ui, node, {bounce = true})
function globals.bindNode(ui, node, binds)
	if node == nil or binds == nil then return end

	-- simple optimize, binds may be 1d map or 2d map-array
	if binds.event then
		local b = binds
		logf.bind("%s - %s %s", tostring(ui), tostring(node), b.event)
		local f = bind[b.event]
		if f then
			f(ui, node, b)
		end
	else
		for _, b in ipairs(binds) do
			logf.bind("%s - %s %s", tostring(ui), tostring(node), b.event)
			local f = bind[b.event]
			if f then
				f(ui, node, b)
			end
		end
	end
end
bindNode = globals.bindNode


require "easy.bind.helper"
require "easy.bind.touch"
require "easy.bind.text"
require "easy.bind.texture"
require "easy.bind.progress"
require "easy.bind.listen"
require "easy.bind.extend"


