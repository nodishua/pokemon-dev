--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2020 TianJi Information Technology Inc.
--
-- 红点相关缓存
--

local KVCache = require "cache.kv"

local RedHintCache = class("RedHintCache", KVCache)

function RedHintCache:init()
	local messageComponent = cc.load("message")
	-- TODO: no accurately, but quick and simple
	messageComponent.registerMessageListener("idlersystem.endIntercept/begin", function()
		self:clean()
	end)
	-- messageComponent.registerMessageListener("idlersystem.endIntercept/end", function()
	-- end)
	-- messageComponent.registerMessageListener("GameModelBase:syncFrom", function(obj, objID)
	-- 	if objID == nil then return end
	-- 	specialCardIcon[objID] = nil
	-- end)
end


return RedHintCache

