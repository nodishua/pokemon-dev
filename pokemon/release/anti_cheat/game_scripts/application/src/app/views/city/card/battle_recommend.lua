-- @date:   2020-02-13
-- @desc:   推荐阵容界面
local function getAttrIcon(cards)
	local attrs = {} -- [attrId] = num
	local count = itertools.size(cards)
	for _, cardId in orderCsvPairs(cards) do
		local cardCsv = csv.cards[cardId]
		local unitCsv = csv.unit[cardCsv.unitID]
		local curAttr = unitCsv.natureType

		attrs[curAttr] = attrs[curAttr] or 0
		attrs[curAttr] = attrs[curAttr] + 1
	end
	local attrsIdx = {} -- [idx] = num
	for attrId, value in pairs(attrs) do
		table.insert(attrsIdx, value)
	end
	table.sort(attrsIdx, function(a, b)
		return a > b
	end)

	local natureCount = #attrsIdx -- 一共有得元素种类
	local csvHalo = csv.battle_card_halo
	local teamBuff = {} 		-- 比例buff [group] = {csvId, priority}
	local attrNumBuff = {} 		-- 单元素数量buff [csvId] = attrId

	for id, cfg in csvPairs(csvHalo) do
		local args = cfg.args
		if cfg.type == 1 then
			local size = itertools.size(args)
			if size <= natureCount then -- 起码种类数量要符合
				for i = 1, size do
					if attrsIdx[i] < args[i] then -- 不符合
						break
					end
					if i == size then -- 最终符合
						local group = cfg.group
						local priority = cfg.priority
						-- 只要优先级不如现在这个则覆盖
						if not (teamBuff[group] and teamBuff[group].priority > priority) then
							teamBuff[group] = {
								csvId = id,
								priority = priority
							}
						end
					end
				end
			end
		elseif cfg.type == 2 then
			for _, arg in pairs(args) do
				local n = attrs[arg[1]] or 0
				if n >= arg[2] then
					attrNumBuff[id] = arg[1]
				end
			end
		end
	end

	-- 比例buff会影响按钮的图标
	local imgPath = "config/embattle/icon_gh.png"
	local curGroup = -1
	for group, tb in pairs(teamBuff) do
		if curGroup < group then -- 不应该相等
			curGroup = group
			imgPath = csvHalo[tb.csvId].icon
		end
	end
	return imgPath
end
local function setCardIcon(cell, v, childs, mask, scale, offX, offY, childName)
	local isBg = childName == "clippingBg"
	local size = childs.bg:size()
	local sp = cc.Sprite:create(v.cardData.icon)
	local spSize = sp:size()
	local scale = scale *v.cardData.scale
	local soff = cc.p(v.cardData.posOffset.x/scale-offX, -v.cardData.posOffset.y/scale+offY)
	local ssize = cc.size(size.width/scale, size.height/scale)
	local rect = cc.rect((spSize.width-ssize.width)/2-soff.x, (spSize.height-ssize.height)/2-soff.y, ssize.width, ssize.height)
	sp:alignCenter(size)
		:scale(scale)
		:setTextureRect(rect)
	if isBg then
		cache.setShader(sp, false, "hsl_gray_white")
		sp:opacity(36)
	end
	cell:removeChildByName(childName)
	cc.ClippingNode:create(mask)
		:setAlphaThreshold(0.1)
		:size(size)
		:alignCenter(cell:size())
		:add(sp)
		:addTo(cell, isBg and 1 or 2, childName)
end
local ViewBase = cc.load("mvc").ViewBase
local CardBattleRecommendView = class("CardBattleRecommendView", Dialog)

CardBattleRecommendView.RESOURCE_FILENAME = "card_battle_recommend.json"
CardBattleRecommendView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["item"] = "item",
	["subList"] = "subList",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("battleDatas"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				columnSize = 3,
				itemAction = {isAction = true},
				onCell = function(list, cell, k, v)
					local childs = cell:multiget("iconCard", "iconCardBg", "imgSpecialMark", "textSpecial", "bg", "iconAttr", "textAttr", "textDesc", "recommendPanel")
					childs.textAttr:text(v.name)
					text.addEffect(childs.textAttr, {outline = {color = ui.COLORS.NORMAL.WHITE}})

					childs.textDesc:text(v.desc)
					childs.iconAttr:texture(v.attrIcon)
					childs.imgSpecialMark:texture(v.specialMarkBg):visible(v.specialMarkBg ~= "")
					adapt.setTextScaleWithWidth(childs.textSpecial, v.specialMarkTitle, 110)
					childs.recommendPanel:visible(v.isRecommend)
					local size = childs.bg:size()
					local mask = ccui.Scale9Sprite:create()
					local cardId = dataEasy.getCardIdAndStar(v.cardData.cardId)
					mask:initWithFile(cc.rect(60, 60, 1, 1), "common/box/mask_panel_exercise.png")
					mask:size(size.width - 20, size.height - 20)
						:alignCenter(size)

					setCardIcon(cell, v, childs, mask, 1, 92, 10, "clipping")
					setCardIcon(cell, v, childs, mask, 1.2, 20, 5, "clippingBg")

					bind.touch(list, cell, {
						methods = {
							ended = functools.partial(list.itemClick, cell, list:getIdx(k), v)
						}
					})
				end,
				asyncPreload = 9,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
}
-- 精灵是1，碎片是2
function CardBattleRecommendView:onCreate(bagType)
	self.item:hide()
	self:initModel()

	self.battleDatas = idlertable.new({})
	local cards = self.cards:read()
	--背包里有的卡牌战力数据
	local cardDatas = {}
	for i,v in ipairs(cards) do
		local card = gGameModel.cards:find(v)
		local cardData = card:read("card_id", "name", "fighting_point", "level", "star", "advance")
		local cardCsv = csv.cards[cardData.card_id]
		local unitCsv = csv.unit[cardCsv.unitID]
		cardDatas[cardCsv.cardMarkID] = cardDatas[cardCsv.cardMarkID] or {}
		local data = cardDatas[cardCsv.cardMarkID][cardCsv.branch]
		if not data or data.fight < cardData.fighting_point then
			cardDatas[cardCsv.cardMarkID][cardCsv.branch] = {
				cardId = cardData.card_id,
				name = cardData.name ~= "" and cardData.name or cardCsv.name,
				rarity = unitCsv.rarity,
				fight = cardData.fighting_point,
				level = cardData.level,
				star = cardData.star,
				advance = cardData.advance
			}
		end
	end
	self.cardDatas = cardDatas
	local battleDatas = {}
	--核心卡牌数据
	local cardData = {}
	for csvId,v in orderCsvPairs(csv.card_battle_recommend) do
		for i,id in orderCsvPairs(v.cards) do
			local cfg = csv.cards[id]
			local cardMarkID = cfg.cardMarkID
			if v.coreMark[i] == 1 then
				local fightData = cardDatas[cardMarkID] and (cardDatas[cardMarkID][cfg.branch] or cardDatas[cardMarkID][0]) or {}
				local cardId = fightData.cardId or id
				local cardCsv = csv.cards[cardId]
				local unitCsv = csv.unit[cardCsv.unitID]
				cardData = {
					cardId = cardId,
					name = not fightData.name and cardCsv.name or fightData.name,
					advance = fightData.advance,
					rarity = unitCsv.rarity,
					fight = fightData.fighting_point or 0,
					icon = unitCsv.cardShow,
					scale = unitCsv.cardShowScale,
					posOffset = unitCsv.cardShowPosC
				}
			end
		end
		local csvHalo = csv.battle_card_halo[v.haloId]
		table.insert(battleDatas, {
			csvId = csvId,
			cardData = cardData,
			name = v.name,
			desc = v.desc,
			specialMarkBg = v.specialMarkBg,
			specialMarkTitle = v.specialMarkTitle,
			sort = v.sort,
			attrIcon = not csvHalo and getAttrIcon(v.cards) or csvHalo.icon,
			isRecommend = v.isRecommend
		})
	end
	table.sort(battleDatas, function(a,b)
		return a.sort > b.sort
	end)
	self.battleDatas:set(battleDatas)

	Dialog.onCreate(self)
end

function CardBattleRecommendView:initModel()
	self.cards = gGameModel.role:getIdler("cards")--卡牌
	self.battleCards = gGameModel.role:getIdler("battle_cards")--队伍中的卡牌
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.roleLv = gGameModel.role:getIdler("level")
end

--排序item点击 and
function CardBattleRecommendView:onItemClick(list,item, t, v)
	gGameUI:stackUI("city.card.battle_detail", nil, {dialog = true}, self.battleDatas:read(), t.k, self.cardDatas)
end

return CardBattleRecommendView