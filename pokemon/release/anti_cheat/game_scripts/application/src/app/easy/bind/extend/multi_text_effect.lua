-- 多层描边投影字
local helper = require "easy.bind.helper"

local multiTextEffect = class("multiTextEffect", cc.load("mvc").ViewBase)

multiTextEffect.defaultProps = {
	-- string or idler
	data = nil,
	effects = nil,
	labelParams = nil,
	onNode = nil,
}

function multiTextEffect:initExtend()
	if self.panel then
		self.panel:removeFromParent()
	end
	local panel = ccui.Layout:create()
		:size(cc.size(0, 0))
		:addTo(self, 1)
	panel:setTouchEnabled(false)
	self.panel = panel

	local count = self.effects and #self.effects or 1
	for i = 1, count do
		local obj = label.create(" ", self.labelParams)
			:addTo(panel, 100 - i, i)
		helper.callOrWhen(self.data, functools.partial(obj.text, obj))
		if self.effects then
			bind.effect(self, obj, {data = self.effects[i]})
		else
			text.deleteEffect(obj, "all")
		end
	end

	if self.onNode then
		self.onNode(panel)
	end
	return self
end

return multiTextEffect
