-- @date:   2021-06-26
-- @desc:   自选抽卡界面

-- diamondUpDrawTips
-- 需配置

local t = {}

local DIA_COST = {
	ONCE = gCommonConfigCsv.drawCardUp1CostPrice,
	TEN = gCommonConfigCsv.drawCardUp10CostPrice,
}
function t.initPageItemFunc(self, curType, goldCount, diamondCount, allCount, half, trainerCount, equipCount, drawEquipCount)
	self.isLimitDraw:set(true)
	self.isCutDown:set(false)
	self.isFree:set(false)
	self.isCost:set(true)
	local onePath = "common/icon/icon_diamond.png"
	local tenPath = "common/icon/icon_diamond.png"

	local costOnce = DIA_COST.ONCE
	local costTen = DIA_COST.TEN
	local diamondUpCard = dataEasy.getNumByKey(game.ITEM_TICKET.diamondUpCard)
	if diamondUpCard > 0 then
		onePath = dataEasy.getIconResByKey(game.ITEM_TICKET.diamondUpCard)
		costOnce = string.format("%s/%s", diamondUpCard, 1)
	end
	if diamondUpCard >= 10 then
		tenPath = dataEasy.getIconResByKey(game.ITEM_TICKET.diamondUpCard)
		costTen = string.format("%s/%s", diamondUpCard, 10)
	end
	self.oneIconPath:set(onePath)
	self.tenIconPath:set(tenPath)
	self.drawOnceCost:set(costOnce)
	self.drawTenCost:set(costTen)
	self:initCards()

end


function t:initCards( )
	self.diamondUpCardPanel:removeAllChildren()

	local data = {}

	for k,v in csvMapPairs(csv.draw_card_up_group) do
		if k == self:makeSelectPositive(self.selfChooseNum:read()) then
			data = v.cards
			break
		end
	end
	local count = table.getn(data)
	local cardsId = {}
	for i, cardId in pairs(data) do
		local cardCsv = csv.cards[cardId]
		local unitCsv = csv.unit[cardCsv.unitID]
		local rarity = unitCsv.rarity
		table.insert(cardsId, {id = cardId,rarity = rarity})
	end

	-- 品质排序
	table.sort( cardsId, function(a, b)
		return a.rarity < b.rarity
	end)
	local maxWidth = self.diamondUpCardPanel:size().width - 200
	local baseY = (count % 2 == 0) and 60 or 80
	local maxRot = 35
	local maxHeight = 400
	local scale = 1
	if count >= 10 then
		scale = 0.7
	elseif count >= 6 then
		scale = 0.7 + (10 - count)  * 0.05
	end
	baseY = baseY / scale
	for i, data in csvPairs(cardsId) do
		local center = (count+1) / 2
		local card = self:createCard(data.id):addTo(self.diamondUpCardPanel)
		card:setAnchorPoint(cc.p(0.5, 0))
		card:x(maxWidth / 2 + (i - center) * maxWidth / (count + 1))
		card:y(baseY + math.abs((i - center)) * maxHeight / (count + 1))
		card:setRotation((i - center) * (maxRot / (count + 1)))
		card:z(100 - math.abs(i - (math.floor(count / 2) + 1)))
		card:scale(scale)
	end
end


function t:makeSelectPositive(num)
	if not num or num == 0 then
		return 1
	end
	return num
end


function t:createCard(cardId)
	local card= self.cardItem:clone():show()
	card:show()
	local cardCsv = csv.cards[cardId]
	local unitCsv = csv.unit[cardCsv.unitID]
	local rarity = unitCsv.rarity
	local icon = unitCsv.cardShow
	local scale = unitCsv.cardShowScale
	local posOffset = unitCsv.cardShowPosC
	local name = unitCsv.name
	local attr1 = unitCsv.natureType
	local attr2 = unitCsv.natureType2

	uiEasy.setIconName("card", cardId, {node = card:get("name"), name = name, advance = 1, space = true})
	text.addEffect(card:get("name"), {color = ui.COLORS.NORMAL.WHITE})
	-- 背景
	local color = {[2] = "z",[3] = "h",[4] = "c"}
	card:get("bg"):texture(string.format("city/drawcard/draw/panel_card_%s.png",color[rarity]))
	-- 品质
	card:get("rarity"):texture((ui.RARITY_ICON[rarity]))
	-- 种类
	if attr2 == nil then
		card:get("attr1"):texture(ui.ATTR_ICON[attr1])
		card:get("attr2"):hide()
	else
		card:get("attr1"):texture(ui.ATTR_ICON[attr1])
		card:get("attr2"):texture(ui.ATTR_ICON[attr2]):show()
	end
	-- 遮罩
	local size = card:get("bg"):size()
	local mask = ccui.Scale9Sprite:create()
	mask:initWithFile(cc.rect(82, 82, 1, 1), "common/icon/mask_card.png")
	mask:size(size.width - 39, size.height - 39)
		:alignCenter(size)
	-- 显示素材图标
	-- setRenderHint(1) 模式下，需要用 setTextureRect 裁剪超框部分
	local sp = cc.Sprite:create(icon)
	local spSize = sp:size()
	local soff = cc.p(posOffset.x/scale, - posOffset.y/scale)
	local ssize = cc.size(size.width/scale, size.height/scale)
	local rect = cc.rect((spSize.width-ssize.width)/2-soff.x, (spSize.height-ssize.height)/2-soff.y, ssize.width, ssize.height)
	sp:alignCenter(size)
		:scale(scale + 0.2)
		:setTextureRect(rect)

	card:removeChildByName("clipping")
	cc.ClippingNode:create(mask)
		:setAlphaThreshold(0.1)
		:size(size)
		:alignCenter(card:size())
		:add(sp)
		:addTo(card, 5, "clipping")
	return card
end

function t.isEnoughToDrawFunc(self, isTen)
	local myNumOne = self.rmb:read()
	local myNumTen = myNumOne

	local once = DIA_COST.ONCE
	local ten = DIA_COST.TEN

	-- 代金券
	local target = dataEasy.getNumByKey(game.ITEM_TICKET.diamondUpCard)
	if target > 0 then-- 至少有一张
		once = 1
		myNumOne = target

		if target >= 10 then-- 满足十连
			ten = 10
			myNumTen = target
		end
	end

	-- return myNumOne >= once, myNumTen >= ten
	if isTen then
		return myNumTen >= ten
	else
		return myNumOne >= once
	end
end


function t.drawOneClickFunc(self)
	local target = dataEasy.getNumByKey(game.ITEM_TICKET.diamondUpCard)
	local function cb()
		gGameApp:requestServer("/game/lottery/card/up/draw", function(tb)
			audio.pauseMusic()
			audio.playEffectWithWeekBGM("drawcard_one.mp3")
			local ret, spe, isFull = dataEasy.getRawTable(tb)
			local items = dataEasy.getItems(ret, spe)
			local cb
			local params = {
				items = items,
				drawType = "self_choose",
				times = 1,
				isFree = false,
				selfChooseType = self:makeSelectPositive(self.selfChooseNum:read()),
				cb = function()
					self:initAward()
				end,
			}
			gGameUI:stackUI("city.drawcard.result", nil, nil, params)
			self:initAward()
		end, "group_up_rmb1",self:makeSelectPositive(self.selfChooseNum:read()))
	end
	if target > 0 then
		cb()
	else
		dataEasy.sureUsingDiamonds(cb, DIA_COST.ONCE)
	end
end

function t.drawTenClickFunc(self)
	local bUseDiamond = false --是否消耗钻石抽卡
	if dataEasy.getNumByKey(game.ITEM_TICKET.diamondUpCard) < 10 then
		bUseDiamond = true
	end
	local function requestServer()
		gGameApp:requestServer("/game/lottery/card/up/draw", function(tb)
			audio.pauseMusic()
			audio.playEffectWithWeekBGM("drawcard_ten.mp3")
			local ret, spe, isFull = dataEasy.getRawTable(tb)
			local items = dataEasy.getItems(ret, spe)
			local cb
			local params = {
				items = items,
				drawType = "self_choose",
				times = 10,
				isFree = false,
				selfChooseType = self:makeSelectPositive(self.selfChooseNum:read()),
				cb = function()
					self:initAward()
				end,
			}
			gGameUI:stackUI("city.drawcard.result", nil, nil, params)
			self:initAward()
			if bUseDiamond then
				userDefault.setCurrDayKey("diamondUpDrawTips", 0)
			end
		end, "group_up_rmb10",self:makeSelectPositive(self.selfChooseNum:read()))
	end
	if bUseDiamond and (matchLanguage({"kr"}) or (userDefault.getCurrDayKey("diamondUpDrawTips", 1) == 1 and dataEasy.isUnlock("diamondUpDrawTips"))) then
		local cost = DIA_COST.TEN
		gGameUI:showDialog{content = string.format(gLanguageCsv.draw10CardTips, cost), cb = function()
			requestServer()
		end, btnType = 2, clearFast = true, isRich = true}
	else
		requestServer()
	end
end
-- 奖励预览
function t:onPerviewClick()
	gGameUI:stackUI("city.drawcard.preview", nil, {blackLayer = true, clickClose = true}, self.curType:read(), nil,self:makeSelectPositive(self.selfChooseNum:read()))
end

return t