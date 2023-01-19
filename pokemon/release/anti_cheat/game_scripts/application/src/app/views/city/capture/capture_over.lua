
local CaptureOver = class("CaptureOver", cc.load("mvc").ViewBase)

CaptureOver.RESOURCE_FILENAME = "capture_failed.json"
CaptureOver.RESOURCE_BINDING = {
	["btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["iconBg2.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		},
	},
	["iconBg.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		},
	},
}

function CaptureOver:onCreate(cb)
	self.cb = cb
	
	local pnode = self:getResourceNode()
	local textEffect = CSprite.new("level/jiesuanshengli.skel")		-- 文字部分特效
	textEffect:addTo(pnode, 100)
	textEffect:setAnchorPoint(cc.p(0.5,1.0))
	textEffect:setPosition(pnode:get("titlePos"):getPosition())
	textEffect:visible(true)
	textEffect:play("jiesuan_buzhuoshibai")
	textEffect:addPlay("jiesuan_buzhuoshibai_loop")
	textEffect:retain()
end

function CaptureOver:onClose()
	if self.cb then
		self.cb(true)
	end
end

return CaptureOver