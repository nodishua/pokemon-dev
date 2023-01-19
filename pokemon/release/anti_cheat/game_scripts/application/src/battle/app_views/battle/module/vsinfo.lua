--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

-- 对战双方信息（有BOSS时，上方要显示BOSS的血条见下图（3））

local VSInfo = class('VSInfo', battleModule.CBase)

function VSInfo:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.widgetLeft = self.parent.UIWidgetLeft:get("Image_8")
	self.widgetRight = self.parent.UIWidgetRight:get("Image_11")
end

function VSInfo:onNewBattleRound(args)
end

function VSInfo:onClose()
end

return VSInfo