-- @date:   2020-02-13
-- @desc:   推荐阵容详情界面
local function createRichTxt(str, x, y, parent, lineWidth)
	if parent:get("richText") then
		parent:removeChildByName("richText")
	end
	return rich.createWithWidth(str, 40, nil, lineWidth)
		:anchorPoint(0, 1)
		:xy(x, y)
		:addTo(parent, 6, "richText")
end
local ViewBase = cc.load("mvc").ViewBase
local CardBattleDetailView = class("CardBattleDetailView", Dialog)
CardBattleDetailView.RESOURCE_FILENAME = "card_battle_detail.json"
CardBattleDetailView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["cardItem"] = "cardItem",
	["cardList"] = {
		varname = "cardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("cardItem"),
				backupCached = false,
				onItem = function(list, node, k, v)
					local childs = node:multiget("textName", "maskPanel")
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							levelProps = {
								data = v.level,
							},
							rarity = v.rarity,
							cardId = v.cardId,
							advance = v.advance,
							star = v.star,
							grayState = v.fight and 0 or 2,
							onNode = function(node)
								node:y(52):scale(0.8)
							end
						}
					})
					childs.textName:text("")
					childs.maskPanel:visible(not v.fight)
					childs.maskPanel:get("iconMask"):hide()
					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.itemClick, node, t, v)
						}
					})
				end,
				asyncPreload = 7,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["leftPanel"] = "leftPanel",
	["rightPanel"] = "rightPanel",
	["leftBtn"] = {
		varname = "subBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onLeftClick")}
		}
	},
	["rightBtn"] = {
		varname = "addBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRightClick")}
		}
	},
}

-- 精灵是1，碎片是2
function CardBattleDetailView:onCreate(battleDatas, selectId, cardDatas)
	self.count = itertools.size(battleDatas)
	self:initModel()
	self.selectId = idler.new(selectId)
	self.datas = idlertable.new({})
	idlereasy.when(self.selectId, function(_, selectId)
		local battleData = battleDatas[selectId]
		local battleCsv = csv.card_battle_recommend[battleData.csvId]
		local datas = {}
		for i, id in ipairs(battleCsv.cards) do
			local cfg = csv.cards[id]
			local cardMarkID = cfg.cardMarkID
			local fightData = cardDatas[cardMarkID] and (cardDatas[cardMarkID][cfg.branch] or cardDatas[cardMarkID][0])
			local cardId = fightData and fightData.cardId or id
			local cardCsv = csv.cards[cardId]
			local unitCsv = csv.unit[cardCsv.unitID]
			local t = fightData or {
				cardId = cardId,
				name = cardCsv.name,
				rarity = unitCsv.rarity
			}
			t.isCoreMark = battleCsv.coreMark[i] == 1
			table.insert(datas, t)
		end
		self.datas:set(datas)
		self:setLeftPanel(battleData)
		self:setRightPanel(battleData)
	end)
	Dialog.onCreate(self)
end

function CardBattleDetailView:initModel()
	self.cards = gGameModel.role:getIdler("cards")--卡牌
	self.battleCards = gGameModel.role:getIdler("battle_cards")--队伍中的卡牌
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.roleLv = gGameModel.role:getIdler("level")
end

function CardBattleDetailView:onRightClick()
	local selectId = self.selectId:read() + 1
	self.selectId:set(selectId > self.count and 1 or selectId)
end

function CardBattleDetailView:onLeftClick()
	local selectId = self.selectId:read() - 1
	self.selectId:set(selectId < 1 and self.count or selectId)
end
function CardBattleDetailView:setLeftPanel(battleData)
	local cardData = battleData.cardData
	local childs = self.leftPanel:multiget("cardIcon", "rarityIcon", "imgSpecialMark", "textName", "bg")
	-- 精灵遮罩
	local size = childs.bg:size()
	local mask = ccui.Scale9Sprite:create()
	mask:initWithFile(cc.rect(0, 0, 0, 0), "city/card/battle_recommend/mask_jlzs.png")
	mask:size(size.width - 5, size.height)
		:alignCenter(size)
		:xy(childs.bg:x() - 160, childs.bg:y() - 414)
		:scale(2)
	local sp = cc.Sprite:create(cardData.icon)
	local spSize = sp:size()
	local rect = cc.rect((spSize.width-size.width)/2, (spSize.height-size.height)/2, size.width, size.height)
	sp:alignCenter(size)
		:scale(2)
		:setTextureRect(rect)
	self.leftPanel:removeChildByName("clipping")
	cc.ClippingNode:create(mask)
		:setAlphaThreshold(0.1)
		:size(size)
		:alignCenter(self.leftPanel:size())
		:xy(childs.cardIcon:x(), childs.cardIcon:y())
		:add(sp)
		:addTo(self.leftPanel, 1, "clipping")
	childs.cardIcon:texture(cardData.icon):hide()
	childs.rarityIcon:texture(ui.RARITY_ICON[cardData.rarity])
	childs.imgSpecialMark:hide()
	childs.textName:text(cardData.name)
end

function CardBattleDetailView:setRightPanel(battleData)
	local childs = self.rightPanel:multiget("attrIcon", "attrText", "titleBg1", "titleBg2", "titleBg3", "list")
	local battleCsv = csv.card_battle_recommend[battleData.csvId]
	childs.attrText:text(battleCsv.name)
	childs.attrIcon:texture(battleData.attrIcon)
	childs.titleBg2:get("textTitle"):text(battleCsv.coreEffectName)
	local richTxt1 = createRichTxt("#C0x5B545B#" .. battleCsv.features, 40, -15, childs.titleBg1, 1160)
	local richTxt2 = createRichTxt("#C0x5B545B#" .. battleCsv.coreEffect, 40, -15, childs.titleBg2, 1160)
	childs.titleBg2:y(childs.titleBg1:y() - 104 - richTxt1:size().height)
	childs.titleBg3:y(childs.titleBg2:y() - 104 - richTxt2:size().height)
	childs.list:size(1160, 578 - richTxt1:size().height - richTxt2:size().height)
	local strs = {}
	for i=1,10 do
		if battleCsv["matchEffect"..i] and battleCsv["matchEffect"..i] ~= "" then
			table.insert(strs, {
				str = "#C0x5B545B#" .. battleCsv["matchEffect"..i],
				verticalSpace = 10
			})
		end
	end
	beauty.textScroll({
		list = childs.list,
		strs = strs,
		isRich = true
	})

	childs.titleBg1:width(math.max(childs.titleBg1:get("textTitle"):width(), childs.titleBg1:width()))
	childs.titleBg2:width(math.max(childs.titleBg2:get("textTitle"):width(), childs.titleBg2:width()))
	childs.titleBg3:width(math.max(childs.titleBg3:get("textTitle"):width(), childs.titleBg3:width()))
	childs.titleBg1:get("textTitle"):x(childs.titleBg1:width()/2)
	childs.titleBg2:get("textTitle"):x(childs.titleBg2:width()/2)
	childs.titleBg3:get("textTitle"):x(childs.titleBg3:width()/2)
end
--排序item点击 and
function CardBattleDetailView:onItemClick(list,item, t, v)
	gGameUI:stackUI("city.handbook.view", nil, {full = true}, {cardId = v.cardId})
end

return CardBattleDetailView