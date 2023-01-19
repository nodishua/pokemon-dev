
local getMaskSprite = function(node,size)
	local tempSprite = ccui.Scale9Sprite:create()
	tempSprite:initWithFile(cc.rect(60, 60, 1, 1), "common/box/mask_panel_exercise.png")
	tempSprite:size(size.width - 20, size.height - 20)
		:alignCenter(node:size())
	return tempSprite
end

local ChipSelectSpriteView = class("ChipSelectSpriteView", Dialog)

ChipSelectSpriteView.RESOURCE_FILENAME = "chip_select_sprite.json"
ChipSelectSpriteView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["item"] = "item",
	["subList"] = "subList",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("data"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				dataOrderCmp = function(a, b)
					if a.chipNum ~= b.chipNum then
						return a.chipNum > b.chipNum
					end
					return a.fight > b.fight
				end,
				asyncPreload = 9,
				columnSize = 3,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					bind.extend(list, node:get('item'), {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							rarity = v.rarity,
							star = v.star,
							levelProps = {
								data = v.level,
							},
							onNode = function(panel)
								panel:scale(1.2):alignCenter(panel:size())
							end,
						}
					})
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, node, k, v)}})
					node:get('isCur'):visible(v.isCur)
					if v.isCur then
						local size = node:get('bg'):getContentSize()
						node:add(getMaskSprite(node, size), 90)
					end

					bind.extend(list, node:get("chipPanel"), {
						class = "chips_panel",
						props = {
							data = v.dbId,
							panelIdx = 1,
							noIdlerListener = true,
							onItem = function(panel, item, k, dbId)
								if dbId then
									item:get("defaultLv"):y(0)
								end
								item:get("effect_line"):hide()
							end,
						}
					})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},

	["panel404"] = "panel404",
	["title"] = "title",
	["num"] = "num",
}

function ChipSelectSpriteView:onCreate(cardDBID, cb)
	self.cb = cb
	self.item:visible(false)
	local all = {}
	local cards = gGameModel.role:read("cards")
	for _, dbId in ipairs(cards) do
		local card = gGameModel.cards:find(dbId)
		local cardDatas = card:read("card_id","skin_id", "fighting_point", "level", "star", "advance")
		local cardCfg = csv.cards[cardDatas.card_id]
		local unitCfg = csv.unit[cardCfg.unitID]
		local cardChips = card:read('chip')
		local num = 0
		for i = 1, 6 do
			if cardChips[i] then
				num = num + 1
			end
		end
		all[dbId] = {
			dbId = dbId,
			cardId = cardDatas.card_id,
			unitId = dataEasy.getUnitId(cardDatas.card_id, cardDatas.skin_id),
			rarity = unitCfg.rarity,
			attr1 = unitCfg.natureType,
			attr2 = unitCfg.natureType2,
			fight = cardDatas.fighting_point,
			level = cardDatas.level,
			star = cardDatas.star,
			advance = cardDatas.advance,
			isCur = cardDBID == dbId,
			chipNum = num,
		}
	end
	self.cardDBID = cardDBID
	self.data = all
	self.panel404:visible(itertools.size(all) == 0)

	Dialog.onCreate(self)
end

function ChipSelectSpriteView:onItemClick(list, node, k, v)
	if self.cardDBID == v.dbId then
		return
	end
	if self.cb then
		self.cb(v.dbId)
	end
	self:onClose()
end

return ChipSelectSpriteView
