-- @date: 2018-11-6
-- @desc: 捕捉精灵提示界面

local CaptureTips = class("CaptureTips", cc.load("mvc").ViewBase)

CaptureTips.RESOURCE_FILENAME = "common_capture_tips.json"
CaptureTips.RESOURCE_BINDING = {
	["imgBG"] = {
		varname = "bg",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onEnterCaptureClick")}
		},
	}
}

--进入可捕捉精灵界面
function CaptureTips:onEnterCaptureClick( )
	self:removeSelf()
	gGameUI:stackUI("city.capture.capture_limit",nil, {full = true})
end

function CaptureTips:onEnter( )
	local endPos = cc.p(self.bg:xy())
	local action1 = cc.Place:create(cc.p(endPos.x - 500, endPos.y))
	local action2 = cc.MoveTo:create(0.5,endPos)
	local action3 = cc.EaseBackOut:create(action2)
	self.bg:runAction(cc.Sequence:create(action1,action3))
end

return CaptureTips
