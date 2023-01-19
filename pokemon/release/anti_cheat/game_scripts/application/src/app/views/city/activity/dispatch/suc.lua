
local ViewBase = cc.load("mvc").ViewBase
local ActivityDispatchSuc = class("ActivityDispatchSuc", ViewBase)
ActivityDispatchSuc.RESOURCE_FILENAME = "activity_dispatch_suc.json"
ActivityDispatchSuc.RESOURCE_BINDING = {
	["textNote"] = "textNote",
}

function ActivityDispatchSuc:onCreate()
	local effect = widget.addAnimation(self:getResourceNode(), "qimiaomaoxian/weipaichenggong.skel", "effect", 0)
		:scale(2.5)
		:alignCenter(display.sizeInView)
	effect:addPlay("effect_loop")
end

return ActivityDispatchSuc
