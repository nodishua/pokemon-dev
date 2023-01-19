local BASE_TIME = 0.08

local ViewBase = cc.load("mvc").ViewBase
local CardCommonSuccessView = class("CardCommonSuccessView", cc.load("mvc").ViewBase)

CardCommonSuccessView.RESOURCE_FILENAME = "card_common_success.json"
CardCommonSuccessView.RESOURCE_BINDING = {
	["bg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onClose")
		},
	},
	["centerPanel.card1"] = {
		varname = "card1",
		binds = {
			event = "extend",
			class = "card_icon",
			props = {
				unitId = bindHelper.self("unitIdOld"),
				advance = bindHelper.self("advanceOld"),
				rarity = bindHelper.self("oldRarity"),
				star = bindHelper.self("starOld"),
			},
		}
	},
	["centerPanel.card2"] = {
		varname = "card2",
		binds = {
			event = "extend",
			class = "card_icon",
			props = {
				unitId = bindHelper.self("unitId"),
				advance = bindHelper.self("advance"),
				rarity = bindHelper.self("rarity"),
				star = bindHelper.self("starNew"),
			},
		}
	},
	["item"] = "item",
	["centerPanel.subList"] = "subList",
	["centerPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("attrDatas"),
				columnSize = 2,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				onCell = function(list, node, k, v)
					local childs = node:multiget("note", "txt1", "txt2", "icon", "iconArrow")
					childs.note:setString(v.note)
					childs.txt1:setString(math.floor(v.txt1))
					childs.txt2:setString(math.floor(v.txt2))
					childs.icon:loadTexture(v.icon)

					local idx = list:getIdx(k).k
					local baseDelay = BASE_TIME * (3 + idx)
					uiEasy.setExecuteSequence({childs.icon, childs.note}, {delayTime = baseDelay})
					uiEasy.setExecuteSequence(childs.txt1, {delayTime = baseDelay + BASE_TIME})
					uiEasy.setExecuteSequence(childs.iconArrow, {delayTime = baseDelay + BASE_TIME * 2})
					uiEasy.setExecuteSequence(childs.txt2, {delayTime = baseDelay + BASE_TIME * 3})
				end,
				onAfterBuild = function(list)
					list:adaptTouchEnabled()
				end,
				asyncPreload = 6,
			},
		},
	},
	["centerPanel.name1"] = "name1",
	["centerPanel.name2"] = "name2",
	["centerPanel.fight1"] = "fight1",
	["centerPanel.fight2"] = "fight2",
	["centerPanel.cardImg"] = "cardImg",
	["centerPanel.fightBg"] = "fightBg",
	["skillName"] = "skillName",
	["skillIcon"] = "skillIcon",
	["skillNote"] = "skillNote",
	["centerPanel"] = "centerPanel",
	["centerPos"] = "centerPos",
}
-- @params 参数:starOld,advanceOld,cardOld
function CardCommonSuccessView:onCreate(selectDbId, fightOld, params)
	audio.playEffectWithWeekBGM("advance_suc.mp3")
	self.selectDbId = selectDbId
	self:initModel()
	self.cb = params.cb

	self.attrDatas = idlers.new({})
	if params.attrs then
		local attrDatas = {}
		for i,v in ipairs(game.ATTRDEF_SIMPLE_TABLE) do
			local data = {
				note = getLanguageAttr(v),
				txt1 = math.floor(params.attrs[v]),
				txt2 = math.floor(self.attrs[v]),
				icon = ui.ATTR_LOGO[v],
			}
			table.insert(attrDatas, data)
		end
		self.attrDatas:update(attrDatas)
	end

	local cardId = self.cardId
	local advance = self.advance
	local star = self.star
	self.unitIdOld = self.unitId
	self.advanceOld = advance
	self.starOld = 0
	self.starNew = 0
	--速度
	local csvUnit = csv.unit[self.unitId]
	self.rarity = csvUnit.rarity
	self.oldRarity = self.rarity
	--title特效
	local effectName = "xjiesuan_jinhuazi"
	itertools.invoke({self.skillNote, self.skillName,self.skillIcon}, "hide")
	if params.advanceOld then
		effectName = "xjiesuan_tupozi"
		local advanceOld = params.advanceOld or advance - 1
		--名字
		uiEasy.setIconName("card", cardId, {node = self.name1, name = csv.cards[cardId].name, advance = advanceOld, space = true})
		uiEasy.setIconName("card", cardId, {node = self.name2, name = csv.cards[cardId].name, advance = advance, space = true})
		--头像
		self.advanceOld = advanceOld
	elseif params.starOld then
		effectName = "xjiesuan_tishengzi"
		uiEasy.setIconName("card", cardId, {node = self.name1, name = csv.cards[cardId].name, advance = advance, space = true})
		uiEasy.setIconName("card", cardId, {node = self.name2, name = csv.cards[cardId].name, advance = advance, space = true})
		self.starOld = star-1
		self.starNew = star
		for k,v in pairs(self.skills) do
		 	if not params.skills[k] then
				itertools.invoke({self.skillNote, self.skillName,self.skillIcon}, "show")
		 		local cfg = csv.skill[k]
		 		self.skillName:text(cfg.skillName)
		 		if cfg.skillNatureType then
		 			self.skillIcon:texture(ui.SKILL_TEXT_ICON[cfg.skillNatureType])
		 		else
		 			self.skillIcon:texture("city/card/system/skill/icon_skill_text.png")
		 		end
		 		self.centerPanel:y(self.centerPos:y() + 20)
				adapt.oneLinePos(self.skillNote, {self.skillName, self.skillIcon}, cc.p(10, 0), "left")
				uiEasy.setExecuteSequence(self.skillNote, {delayTime = BASE_TIME * 5})
				uiEasy.setExecuteSequence(self.skillName, {delayTime = BASE_TIME * 6})
				uiEasy.setExecuteSequence(self.skillIcon, {delayTime = BASE_TIME * 7})
		 		break
		 	end
		end
	elseif params.effortAdvance then
		self.name1:text(gLanguageCsv.effortAdvance .. dataEasy.getRomanNumeral(params.effortAdvance - 1))
		self.name2:text(gLanguageCsv.effortAdvance .. dataEasy.getRomanNumeral(params.effortAdvance))
		text.addEffect(self.name1,{color = ui.COLORS.NORMAL.DEFAULT})
		text.addEffect(self.name2,{color = ui.COLORS.NORMAL.DEFAULT})
		effectName = "xjiesuan_jinshengzi"
		local cfg = csv.cards[cardId]
		local attrEffect = gCardEffortAdvance[cfg.effortSeqID][params.effortAdvance].attrEffect
		if not string.find(attrEffect,"%%") then
			attrEffect = attrEffect .. "%"
		end
		local str = string.format(gLanguageCsv.effortAdvanceActiveTip, attrEffect)
		local richText = rich.createByStr(str, 40, nil, nil, cc.p(0, 0.5))
			:anchorPoint(0, 0.5)
			:xy(300, 150)
			:addTo(self.centerPanel, 6)
		uiEasy.setExecuteSequence(richText, {delayTime = BASE_TIME * 5})
	else
		uiEasy.setIconName("card", params.cardOld, {node = self.name1, name = csv.cards[params.cardOld].name, space = true})
		uiEasy.setIconName("card", cardId, {node = self.name2, name = csv.cards[cardId].name, space = true})
		local csvCards = csv.cards[params.cardOld]
		local csvUnit = csv.unit[csvCards.unitID]
		self.unitIdOld = csvCards.unitID
		self.oldRarity = csvUnit.rarity
	end
	--title特效

	uiEasy.setTitleEffect(self.centerPos, effectName, params)

	--动画
	uiEasy.setExecuteSequence(self.name1)
	uiEasy.setExecuteSequence(self.card1)
	uiEasy.setExecuteSequence(self.cardImg, {delayTime = BASE_TIME})
	uiEasy.setExecuteSequence(self.name2, {delayTime = BASE_TIME * 2})
	uiEasy.setExecuteSequence(self.card2, {delayTime = BASE_TIME * 2})
	uiEasy.setExecuteSequence(self.fightBg, {delayTime = BASE_TIME * 3})
	uiEasy.setExecuteSequence(self.fight1, {delayTime = BASE_TIME * 4})
	uiEasy.setExecuteSequence(self.fight2, {delayTime = BASE_TIME * 5})
	--战力
	self.fight1:text(fightOld)
	self.fight2:text(self.fight)

	-- gGameUI:disableTouchDispatch(1 + BASE_TIME * 12)
end

function CardCommonSuccessView:initModel()
	local card = gGameModel.cards:find(self.selectDbId)
	self.attrs = card:read("attrs")
	self.advance = card:read("advance")
	self.star = card:read("star")
	self.cardId = card:read("card_id")
	self.skinId = card:read("skin_id")
	self.fight = card:read("fighting_point")
	self.skills = card:read("skills")
	self.unitId = dataEasy.getUnitId(self.cardId, self.skinId)
end

function CardCommonSuccessView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

return CardCommonSuccessView
