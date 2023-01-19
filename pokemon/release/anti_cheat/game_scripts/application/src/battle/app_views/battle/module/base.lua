
---------------------------------------
--
-- 模块
-- 模块可以是子View控制，也可以是非View功能
-- 模块=Component+System，BattleView=Super Entity
-- 通过CModuleBase对BattleView进行功能垂直分割
-- 通过CModuleNotify广播，使得多模块顺序工作
-- 通过CModule.notify广播，使得模块间进行协同工作
--

local CBase = class("CBase")
battleModule.CBase = CBase

function CBase:ctor(parent)
	self.parent = parent
	self.subModuleNotify = parent.subModuleNotify
end

function CBase:notify(msg, ...)
	return self.subModuleNotify:notify(msg, ...)
end

function CBase:call(msg, ...)
	return self.subModuleNotify:call(msg, ...)
end

function CBase:onClose()
end

return CBase

