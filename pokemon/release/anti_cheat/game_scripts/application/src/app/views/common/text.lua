-- @date: 2020-8-28

local TextView = class("TextView", cc.load("mvc").ViewBase)
TextView.RESOURCE_FILENAME = "common_text.json"
TextView.RESOURCE_BINDING = {
	["baseNode"] = "baseNode",
	["baseNode.bg"] = "bg",
}

function TextView:onCreate(params)
	if not matchLanguage({"cn", "tw"}) then
		params.width = (params.width or 0) + 160
	else
		params.width = (params.width or 0) + 135
	end

	local offx, offy = 30, 30
	local richText = rich.createWithWidth(params.content, params.fontSize or 40, nil, params.width or 580, 15)
		:addTo(self.baseNode, 99)
		:setAnchorPoint(cc.p(0, 1))

	local textHeight = math.max(richText:getContentSize().height, 240)
	local newHeight = textHeight + offy * 2
	richText:xy(offx, newHeight - 40)
	self.bg:size(richText:getContentSize().width + offx * 2, newHeight)
end

return TextView