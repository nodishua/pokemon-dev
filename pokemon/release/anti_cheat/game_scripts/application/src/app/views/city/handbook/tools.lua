-- @date 2020-01-20
-- @desc 图鉴 （通用方法）

local handbookTools = {}

function handbookTools.setAttrPanel(panel, img, name, num)
	local childs = panel:multiget("imgAttr", "textName", "textNum")
	childs.imgAttr:texture(img)
	childs.textName:text(name)
	childs.textNum:text("+"..num)
	adapt.oneLinePos(childs.imgAttr, childs.textName, cc.p(25, 0))
	adapt.oneLinePos(childs.textName, childs.textNum, cc.p(15, 0))
end
function handbookTools.getStarAttrData(cardMarkID)
	local attrType = gPokedexDevelop[cardMarkID][1].attrType1
	local attr = game.ATTRDEF_TABLE[attrType]
	local attrName = gLanguageCsv["attr" .. string.caption(attr)]
	local attrIcon = ui.ATTR_LOGO[game.ATTRDEF_TABLE[attrType]]
	local attrNum = "0%"
	local myMaxStar, existCards, dbid = dataEasy.getCardMaxStar(cardMarkID)
	if myMaxStar > 0 then
		attrNum = gPokedexDevelop[cardMarkID][myMaxStar].attrValue1
	end
	return attrIcon, attrName, attrNum
end
return handbookTools