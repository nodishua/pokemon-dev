local ViewBase = cc.load("mvc").ViewBase
local CloneBattleChooseView = class("CloneBattleChooseView", Dialog)

CloneBattleChooseView.RESOURCE_FILENAME = "clone_battle_sprite.json"
CloneBattleChooseView.RESOURCE_BINDING = {
	["item"] = "item",
	["subList"] = "subList",
	["list"] = {
		varname = "cardList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("cardDatas"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				dataOrderCmpGen = bindHelper.self("onSortCardList", true),	--排序
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					local children = node:multiget("cardItem", "name", "txtValueTitle", "txtValue", "mask")
					uiEasy.setIconName("card", v.id, {node = children.name, name = v.name, advance = v.advance, space = true})
					children.txtValue:text(v.fightPoint)
					adapt.oneLinePos(children.txtValueTitle, children.txtValue, cc.p(15,0), "left")
					bind.extend(list, children.cardItem, {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							star = v.star,
							rarity = v.rarity,
							levelProps = {data = v.level,},
							params = {
								starScale = 0.85,
								starInterval = 12.5,
							},
						}
					})
					if not v.isCur then
						children.mask:hide()
						bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, node, k, v)}})
					else
						children.mask:show()
						local note = children.mask:get('textNote')
						uiEasy.addTextEffect1(children.mask:get('textNote'))
					end
				end,
				asyncPreload = 12,
				columnSize = 3,
			},
			handlers = {
				itemClick = bindHelper.self("onItemChoose"),
			},
		},
	},
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
}

function CloneBattleChooseView:onCreate(curId)
	self.curSprId = curId
	self:initModel()
	self.cardDatas = idlers.new()--卡牌数据

	idlereasy.any({self.cards},function (obj, cards)
		local tmpCardDatas = {}
		local tmpSize = 0
		for k, dbid in ipairs(cards) do
			local cardData = gGameModel.cards:find(dbid):read("card_id", "skin_id","level", "star", "advance", "name", "fighting_point")
			local cardCsv = csv.cards[cardData.card_id]
			local unitCsv = csv.unit[cardCsv.unitID]
			local unitId = dataEasy.getUnitId(cardData.card_id, cardData.skin_id)
			tmpCardDatas[dbid] = {
				id = cardData.card_id,
				unitId = unitId,
				name = cardCsv.name,
				rarity = unitCsv.rarity,
				level = cardData.level,
				star = cardData.star,
				dbid = dbid,
				advance = cardData.advance,
				fightPoint = cardData.fighting_point,
				isCur = self.curSprId == dbid,
			}
			tmpSize = tmpSize + 1
		end
		self.cardDatas:update(tmpCardDatas)
	end)
	Dialog.onCreate(self, {clickClose = true})
end

function CloneBattleChooseView:initModel()
	self.cards = gGameModel.role:getIdler("cards")
end

function CloneBattleChooseView:onItemChoose(list, node, k, v)
	gGameApp:requestServer("/game/clone/battle/deploy", function (tb)
		self:onClose()
	end, v.dbid)
end

function CloneBattleChooseView:onSortCardList(list)
	return function(a, b)
		if a.isCur then return true end
		if b.isCur then return false end

		return a.fightPoint > b.fightPoint
	end
end

return CloneBattleChooseView
