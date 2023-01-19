--
-- 个人形象
--
local helper = require "easy.bind.helper"

local roleFigure = class("roleFigure", cc.load("mvc").ViewBase)

roleFigure.defaultProps = {
	-- figureId: number or idler
	data = nil,
	onNode = nil,
	spine = nil,	-- 是否需要展示spine(不同界面需求不一样), 默认不展示
	onSpine = nil,
}

function roleFigure:initExtend()
	local figure = ccui.ImageView:create()
			:alignCenter(self:size())
			:addTo(self, 10, "figure")
			:visible(false)

	helper.callOrWhen(self.data, function(id)
		local cfg = gRoleFigureCsv[id]
		self:removeChildByName("spine")
		if self.spine and cfg and cfg.resSpine ~= "" then
			figure:visible(false)
			local spine = widget.addAnimationByKey(self, cfg.resSpine, "spine", "standby_loop1")
				:xy(self:size().width/2, 0)
			if self.onSpine then
				self.onSpine(spine)
			end
		else
			figure:texture(dataEasy.getRoleFigureIcon(id))
			figure:visible(true)
		end
	end)

	if self.onNode then
		self.onNode(figure)
	end
	return self
end

return roleFigure