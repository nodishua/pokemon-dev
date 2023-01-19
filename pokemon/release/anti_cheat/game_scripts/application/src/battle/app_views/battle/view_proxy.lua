--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
-- 实现ViewProxy接口
--



function BattleView:onViewProxyNotify(msg, ...)
	return self.subModuleNotify:notify(msg, ...)
end

function BattleView:onViewProxyCall(msg, ...)
	return self.subModuleNotify:call(msg, ...)
end

function BattleView:onViewBeProxy(view, proxy)
	return self.subModuleNotify:notify("ViewBeProxy", view, proxy)
end

function BattleView:addSpecModule(mods)
	self.subModuleNotify:addSpec(mods)
end

