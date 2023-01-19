-- @date:   2019-1-29
-- @desc:   通用规则界面

local RuleView = class("RuleView", Dialog)

RuleView.RESOURCE_FILENAME = "common_rule.json"
RuleView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["list"] = "list",
	["title"] = "title",
	["awardItem"] = "awardItem",
	["rateTips"] = "rateTips",
	["panelChip"] = "panelChip",
}

-- @param params:{width, height}
function RuleView:onCreate(context, params)
	Dialog.onCreate(self)
	self.list:setScrollBarEnabled(false)

	params = params or {}
	if params.width then
		local dx = self.bg:width() - params.width
		self.bg:width(params.width)
		self.list:width(self.list:width() - dx)
			:x(self.list:x() + dx/2)
		setContentSizeOfAnchor(self.title, cc.size(self.title:width() - dx, self.title:height()))
	end

	adaptContext.setToList(self, self.list, context(self), 16, nil, function()
		self.list:refreshView()
		local height = cc.clampf(params.height or self.list:getInnerItemSize().height, 400, self.list:height())
		local dy = self.list:height() - height
		self.bg:height(self.bg:height() - dy)
		self.list:height(self.list:height() - dy)
			:y(self.list:y() + dy/2)
	end)
	self:quickFor()
end

return RuleView