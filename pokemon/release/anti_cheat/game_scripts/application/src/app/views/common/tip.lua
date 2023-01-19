-- @date: 2018-10-18
-- @desc: 通用飘字

local TipView = class("TipView", cc.load("mvc").ViewBase)
TipView.RESOURCE_FILENAME = "common_tip.json"
TipView.RESOURCE_BINDING = {
	["panel"] = "panel",
	["panel.bg"] = "bg",
	["panel.text"] = "text",
}
function TipView:onCreate(str)
	self.content = str
	self.text:text("")
	local richText = rich.createByStr("#C0x5b545b#"..str, 40)
		:anchorPoint(0.5, 0.5)
		:xy(self.text:x(), self.text:y())
		:addTo(self.panel, 2000)
	richText:formatText()
	local size = richText:size()
	self.bg:size(math.max(size.width + 100, 1024), self.bg:size().height)
	self.panel:anchorPoint(0.5, 0)
		:scale(3, 0)

	transition.executeSequence(self.panel)
		:scaleTo(0.2, 1, 1)
		:delay(2.5)
		:scaleTo(0.2, 0, 1)
		:func(functools.partial(self.onClose, self))
		:done()
end

function TipView:onClose()
	self.panel:stopAllActions()
	-- 只是显示内容，不需要用 onClose，直接移出
	self:removeSelf()
end

function TipView:onMoveUp()
	local x, y = self.panel:xy()
	transition.executeSequence(self.panel)
		:moveTo(0.1, x, y + self.panel:size().height)
		:done()
end

return TipView
