-- @date: 2019-2-13
-- @desc: 卡牌详情

local CardDetailView = class("CardDetailView", cc.load("mvc").ViewBase)
CardDetailView.RESOURCE_FILENAME = "common_card_detail.json"
CardDetailView.RESOURCE_BINDING = {
	["baseCardNode"] = "baseCardNode",
	["baseCardNode.cardIcon"] = {
		binds = {
			event = "extend",
			class = "card_icon",
			props = {
				cardId = bindHelper.self("cardId"),
				star = bindHelper.self("star"),
				rarity = bindHelper.self("rarity"),
				onNode = function(node)
					local size = node:size()
					node:alignCenter(size)
				end,
			},
		}
	},
	["baseCardNode.cardName"] = "cardName",
	["baseCardNode.attr1"] = "attr1",
	["baseCardNode.attr2"] = "attr2",
	["baseCardNode.skillIcon"] = "skillIcon",
	["baseCardNode.skillName"] = "skillName",
	["baseCardNode.skillAttr"] = "skillAttr",
	["baseCardNode.skillDescribeList"] = "skillDescribeList",
	["baseCardNode.raceNote"] = "raceNote",
	["baseCardNode.raceNum"] = "raceNum",
	["baseCardNode.attrItem"] = "attrItem",
	["baseCardNode.list"] = {
		varname = "attrList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("attrItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon", "note", "num", "bar")
					childs.note:text(v.note)
					childs.num:text(v.num)
					childs.icon:texture(v.icon)
					local percent = v.num*100/game.RACE_ATTR_LIMIT
					childs.bar:setPercent(percent)
				end,
				asyncPreload = 6,
			},
		},
	},
}

-- @param params {num}
function CardDetailView:onCreate(params)
	local cardId = params.num
	self:getResourceNode():setTouchEnabled(false)
	self.attrDatas = idlertable.new({})
	local cardId, star = dataEasy.getCardIdAndStar(cardId)
	local cardCsv = csv.cards[cardId]
	local unitCsv = csv.unit[cardCsv.unitID]
	local skillCsv = csv.skill[cardCsv.innateSkillID]

	self.cardId = idler.new(cardId)
	self.star = idler.new(star)
	self.rarity = idler.new(unitCsv.rarity)

	beauty.textScroll({
		list = self.skillDescribeList,
		strs = "#C0x5B545B#" .. skillCsv.simDesc,
		isRich = true,
		fontSize = 40,
	})

	self.cardName:text(cardCsv.name)
	self.attr1:texture(ui.ATTR_ICON[unitCsv.natureType])
	if unitCsv.natureType2 then
		self.attr2:texture(ui.ATTR_ICON[unitCsv.natureType2]):show()
	else
		self.attr2:hide()
	end
	self.skillName:text(skillCsv.skillName)
	local skillNameWidth = self.skillName:size().width
	if not skillCsv.skillNatureType then
		self.skillAttr:hide()
		self.skillIcon:hide()
	else
		self.skillAttr:texture(ui.SKILL_TEXT_ICON[skillCsv.skillNatureType]):show()
		self.skillIcon:texture(ui.SKILL_ICON[skillCsv.skillNatureType]):show()
	end

	self.raceNum:text(cardCsv.specValue[csvSize(cardCsv.specValue)])

	local attrDatas = {}
	local attrName = {{"hp","sm"}, {"speed","sd"}, {"damage","wg"}, {"defence","wf"}, {"specialDamage","tg"}, {"specialDefence","tf"}}
	for i,v in ipairs(attrName) do
		local data = {
			note = getLanguageAttr(v[1]),
			num = cardCsv.specValue[i],
			icon = ui.ATTR_LOGO[v[1]],
			barImg = "card_info/bar_"..v[2]..".png"
		}
		attrDatas[i] =  data
	end
	self.attrDatas:set(attrDatas)
end

function CardDetailView:hitTestPanel(pos)
	if self.skillDescribeList:isTouchEnabled() then
		local node = self.baseCardNode
		local rect = node:box()
		local nodePos = node:parent():convertToWorldSpace(cc.p(rect.x, rect.y))
		rect.x = nodePos.x
		rect.y = nodePos.y
		return cc.rectContainsPoint(rect, pos)
	end
	return false
end

return CardDetailView