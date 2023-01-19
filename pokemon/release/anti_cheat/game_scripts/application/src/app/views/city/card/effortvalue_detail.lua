
local CardEffortValueDetailView = class("CardEffortValueDetailView", Dialog)
CardEffortValueDetailView.RESOURCE_FILENAME = "card_effortvalue_detail.json"
CardEffortValueDetailView.RESOURCE_BINDING = {
	["item"] = "item",
	["panel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("advanceDatas"),
				item = bindHelper.self("item"),
				padding = 5,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("pos")
					local isActive = v.effortAdvance >= v.advance
					local color = isActive and "#C0x5b545b#" or "#C0xb8af9d#"
					local str = color .. gLanguageCsv.effortAdvanceAttrTip
					if v.effortAdvance == v.advance then
						str = str .. gLanguageCsv.effortCurrentAdvance
					end
					local addStr = v.addStr
					if not string.find(addStr,"%%") then
						addStr = addStr .. "%"
					end
					if matchLanguage({"cn", "tw"}) then
						rich.createByStr(string.format(str, dataEasy.getRomanNumeral(v.advance), addStr), 40)
							:anchorPoint(0, 0.5)
							:addTo(childs.pos, 6)
					else
						rich.createByStr(string.format(str, dataEasy.getRomanNumeral(v.advance), addStr), 36)
							:anchorPoint(0, 0.5)
							:addTo(childs.pos, 6)
					end
				end,
			},
		},
	},
}



function CardEffortValueDetailView:onCreate(effortAdvance, cardId)
	self.item:hide()
	self.list:size(918, 770)
	local cfg = csv.cards[cardId]
	local t = {}
	for i,v in orderCsvPairs(gCardEffortAdvance[cfg.effortSeqID]) do
		if i <= v.advanceLimit then
			table.insert(t, {
				advance = i,
				addStr = v.attrEffect,
				effortAdvance = effortAdvance
			})
		end
	end
	self.advanceDatas = t
	Dialog.onCreate(self, {noBlackLayer = true,clickClose = true})
end

return CardEffortValueDetailView
