-- @Date:   2020-08-3
-- @Desc: 徽章天赋界面
local ViewBase = cc.load("mvc").ViewBase
local gymBadgeGuardDetailView = class("gymBadgeGuardDetailView", ViewBase)

gymBadgeGuardDetailView.RESOURCE_FILENAME = "gym_badge_guard_detail.json"
gymBadgeGuardDetailView.RESOURCE_BINDING = {
	["baseNode"] = "baseNode",
	["baseNode.cardIcon"] = "cardIcon",
	["baseNode.cardName"] = "cardName",
	["baseNode.bg"] = "bg",
	["baseNode.attr1"] = "attr1",
	["baseNode.attr2"] = "attr2",
	["baseNode.txt1"] = "txt1",
	["baseNode.txt2"] = "txt2",
	["baseNode.txt3"] = "txt3",
	["baseNode.txt4"] = "txt4",
	["baseNode.txt5"] = "txt5",
	["baseNode.text5"] = "text5",
	["baseNode.text4"] = "text4",
}

function gymBadgeGuardDetailView:onCreate(parms)
	self.selectDbId = parms.selectDbId
	local badgeNumb = parms.badgeNumb
	self:initModel()
	local cardCsv = csv.cards[self.cardId]
	local unitCsv = csv.unit[cardCsv.unitID]
	-- self.cardIdData = idler.new(self.cardId)
	-- self.starData = idler.new(self.star)
	-- self.rarityData = idler.new(unitCsv.rarity)
	-- self.advanceData = idler.new(self.advance)
	-- self.levelData = idler.new(self.level)
	self.cardName:text(unitCsv.name)
	self.attr1:texture(ui.ATTR_ICON[unitCsv.natureType])
	if unitCsv.natureType2 then
		self.attr2:texture(ui.ATTR_ICON[unitCsv.natureType2])
	else
		self.attr2:hide()
	end
	local rarityNum = "0%"
	local starNum = "0%"
	local advanceNum = "0%"
	local sameNum = "0%"
	local nvalueSum = 0
	local nvalueAttrsCfg = {}
	for k, v in pairs(self.nvalue) do
		nvalueSum = nvalueSum + v
	end
	local isSame = false
	if itertools.include(csv.gym_badge.badge[badgeNumb].nature, unitCsv.natureType) then
		isSame = true
	end
	if itertools.include(csv.gym_badge.badge[badgeNumb].nature, unitCsv.natureType2) then
		isSame = true
	end
	for k, v in ipairs(csv.gym_badge.guard_effect) do
		if k == unitCsv.rarity then
			rarityNum = v.rarityAttr
			starNum = v.starAttrs[self.star]
			advanceNum = v.advanceAttrs[self.advance]
			if isSame then
				sameNum = v.natureAttr
			end
			nvalueAttrsCfg = v.nvalueAttrs
		end
	end
	local quality, numStr = dataEasy.getQuality(self.advance)
	local str = ""
	if not itertools.isempty(numStr) then
		str = gLanguageCsv[ui.QUALITY_COLOR_TEXT[quality]].."+"..numStr
	else
		str = gLanguageCsv[ui.QUALITY_COLOR_TEXT[quality]]..numStr
	end
	rich.createWithWidth(string.format(gLanguageCsv.rarityAdditionText, ui.QUALITYCOLOR[unitCsv.rarity + 2]..gLanguageCsv["rarityCard"..(unitCsv.rarity-1)], rarityNum), 40, nil, 1250)
			:addTo(self.txt1, 10)
			:anchorPoint(cc.p(0, 0.5))
			:xy(0, 0)
			:formatText()
	rich.createWithWidth(string.format(gLanguageCsv.advanceAdditionText, ui.QUALITYCOLOR[quality]..str, advanceNum), 40, nil, 1250)
			:addTo(self.txt2, 10)
			:anchorPoint(cc.p(0, 0.5))
			:xy(0, 0)
			:formatText()
	rich.createWithWidth(string.format(gLanguageCsv.starAdditionText, self.star, starNum), 40, nil, 1250)
			:addTo(self.txt3, 10)
			:anchorPoint(cc.p(0, 0.5))
			:xy(0, 0)
			:formatText()

	local max, value = 0, nil
	for k, v in orderCsvPairs(nvalueAttrsCfg) do
		if nvalueSum >= k and k >= max then
			max = k
			value = v
		end
	end
	if value then
		rich.createWithWidth(string.format(gLanguageCsv.nNatureAdditionText, max, value), 40, nil, 1250)
			:addTo(self.txt4, 10)
			:anchorPoint(cc.p(0, 0.5))
			:xy(0, 0)
			:formatText()
		-- self.bg:width(self.bg:width() + 0)
	else
		self.txt4:hide()
		self.baseNode:get("text4"):hide()
		self.bg:height(self.bg:height() - 150)
		self.bg:y(self.bg:y() + 75)
	end

	if isSame == true then
		rich.createWithWidth(string.format(gLanguageCsv.sameNatureAdditionText, sameNum), 40, nil, 1250)
			:addTo(self.txt5, 10)
			:anchorPoint(cc.p(0, 0.5))
			:xy(0, 0)
			:formatText()
		if self.txt4:isVisible() == false then
			self.txt5:y(self.txt4:y())
			self.text5:y(self.text4:y())
		end
	else
		self.txt5:hide()
		self.baseNode:get("text5"):hide()
		self.bg:height(self.bg:height() - 150)
		self.bg:y(self.bg:y() + 75)
	end

	local unitId = dataEasy.getUnitId(self.cardId, self.skinId)
	bind.extend(self, self.cardIcon, {
		class = "card_icon",
		props = {
			unitId = unitId,
			star = self.star,
			rarity = unitCsv.rarity,
			advance = self.advance,
			levelProps = {
				data = self.level,
			},
			onNode = function(node)
				local size = node:size()
				node:alignCenter(size)
			end,
		}
	})
end

function gymBadgeGuardDetailView:initModel()
	local card = gGameModel.cards:find(self.selectDbId)
	self.advance = card:read("advance")
	self.cardId = card:read("card_id")
	self.skinId = card:read("skin_id")
	self.star = card:read("star")
	self.nvalue = card:read("nvalue")
	self.level = card:read("level")
end

return gymBadgeGuardDetailView