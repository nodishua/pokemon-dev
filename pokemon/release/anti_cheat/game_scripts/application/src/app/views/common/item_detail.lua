-- @date: 2018-11-22
-- @desc: 道具详情

local ItemDetailView = class("ItemDetailView", cc.load("mvc").ViewBase)
ItemDetailView.RESOURCE_FILENAME = "common_item_detail.json"
ItemDetailView.RESOURCE_BINDING = {
	["baseNode.icon"] = {
		binds = {
			event = "extend",
			class = "icon_key",
			props = {
				data = bindHelper.self("data"),
				noListener = true,
				onNode = function(node)
					local size = node:size()
					node:alignCenter(size)
				end,
			},
		},
	},
	["baseNode.name"] = "nodeName",
	["baseNode.content"] = "contentLabel",
	["baseNode.list"] = "list",
	["baseNode.textNum"] = "textNum",
	["baseNode"] = "baseNode",
}

-- @param params: {key, num}
function ItemDetailView:onCreate(params)
	self:getResourceNode():setTouchEnabled(false)
	local key = params.key
	local num = params.num
	self.data = {key = key, num = num}
	local showNum = true
	if game.ITEM_EXP_HASH[key] then
		showNum = false

	elseif csv.items[key] and csv.items[key].type == game.ITEM_TYPE_ENUM_TABLE.aptitude then
		showNum = false
	end
	local name, effect = uiEasy.setIconName(key, num, {node = self.nodeName})
	self.nodeName:setFontName(ui.FONT_PATH)
	self.nodeName:setTextColor(effect.color)
	if matchLanguage({"en"}) then
        adapt.setTextAdaptWithSize(self.nodeName, {size = cc.size(425, 144), vertical = "center"})
	else
		adapt.setTextScaleWithWidth(self.nodeName, nil, 410)
	end

	-- beauty.singleTextLimitWord(self.nodeName:text(), {fontSize = self.nodeName:getFontSize()}, {width = 410})
	-- 	:anchorPoint(0, 0.5)
	-- 	:xy(self.nodeName:xy())
	-- 	:addTo(self.baseNode, self.nodeName:z())
	-- 	:color(effect.color)

	self.textNum:visible(showNum)
	if not showNum then
		self.nodeName:y(self.nodeName:y() - 50)
	else
		self.textNum:text(gLanguageCsv.have .. ": " .. mathEasy.getShortNumber(dataEasy.getNumByKey(key), 2))
	end
	beauty.textScroll({
		list = self.list,
		strs = "#C0x5B545B#" .. uiEasy.getIconDesc(key, num),
		isRich = true,
	})
end

function ItemDetailView:hitTestPanel(pos)
	if self.list:isTouchEnabled() then
		local node = self.baseNode
		local rect = node:box()
		local nodePos = node:parent():convertToWorldSpace(cc.p(rect.x, rect.y))
		rect.x = nodePos.x
		rect.y = nodePos.y
		return cc.rectContainsPoint(rect, pos)
	end
	return false
end

return ItemDetailView