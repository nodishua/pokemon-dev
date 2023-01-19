local ChipTools = require('app.views.city.card.chip.tools')


local ChipSuitAttrView = class("ChipSuitAttrView", cc.load("mvc").ViewBase)


ChipSuitAttrView.RESOURCE_FILENAME = "chip_suit_attr.json"
ChipSuitAttrView.RESOURCE_BINDING = {
	["item01"] = "item",
	["txtTip"] = "txtTip",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showDatas"),
                item = bindHelper.self("item"),
				itemAction = {isAction = true},
                onItem = function(list, node, k, v)
                	local childs = node:multiget("imgChip","txtName")
                	childs.txtName:text(v.name)

                	local twoText = rich.createWithWidth(v.twoStr, 40, nil, 1240, nil, cc.p(0, 0))
						:anchorPoint(cc.p(0, 1))
						:xy(280,210)
						:addTo(node)

					local fourText = rich.createWithWidth(v.fourStr, 40, nil, 1240, nil, cc.p(0, 0))
						:anchorPoint(cc.p(0,1))
						:xy(280, 150)
						:addTo(node)


					if not v.fourSign then
						fourText:setOpacity(130)
					end

					childs.imgChip:texture(v.icon)
				end,
				onAfterBuild = function(list)

					local containerSize = list:getInnerContainerSize()
					local size = list:getContentSize()

					if containerSize.height <= size.height then
						list:setTouchEnabled(false)
					end
				end,
			}
		}
	}
}

ChipSuitAttrView.RESOURCE_STYLES = {
    blackLayer = true,
    clickClose = true,
    backGlass = true,
}


function ChipSuitAttrView:onCreate(cardDBID)
	self.cardDBID = cardDBID
	self.showDatas = idlertable.new({})

	local tempShowDatas = {}
	local suitList = ChipTools.getComplateSuitAttrByCard(self.cardDBID)
	for _, list in pairs(suitList) do
		local showData = {}
		local suitID = list.suitId
		showData.icon = ChipTools.getSuitRes(suitID, list.data)
		for index, data in ipairs(list.data) do

			local suitCsv = gChipSuitCsv[suitID][data[2]][data[1]]

			showData.name = suitCsv.suitName

			local color = string.format("%s(%s)", ui.QUALITY_DARK_COLOR[data[2]], gLanguageCsv[ui.QUALITY_COLOR_TEXT[data[2]]])
			local str = string.format(gLanguageCsv.chipSuitCount, data[1], color)
			if suitCsv.skillID == 0 then
				for index = 1, 3 do

					local attrT = suitCsv["attrType"..index]
					if attrT and attrT ~= 0 then
						local attrN = dataEasy.getAttrValueString(attrT, suitCsv["attrNum"..index])
						str = str .. string.format(gLanguageCsv.chipSuit01, getLanguageAttr(attrT), attrN)
					end

					local nextAttrT = suitCsv["attrType"..(index + 1)]
					if nextAttrT and nextAttrT ~= 0 then
						str =str.."#C0xFFFCED#, "
					end
				end
				showData.twoStr = str
				showData.twoSign = data[3]
			else

				str =  str .. "#C0xFFFCED#"..string.gsub(csv.skill[suitCsv.skillID].describe, "#C0x5B545B#", "#C0xFFFCED#")
				showData.fourStr = string.gsub(str, "#C0x5c9970#", "#C0x91e1b1#")
				showData.fourSign = data[3]
			end
		end
		table.insert(tempShowDatas, showData)
	end

	if #tempShowDatas == 0 then
		self.txtTip:show()
		self.list:hide()
	else
		self.showDatas:set(tempShowDatas)
	end
end


return ChipSuitAttrView