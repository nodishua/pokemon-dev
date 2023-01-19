-- @date:   2020-11-05
-- @desc:   预设队伍

local ViewBase = cc.load("mvc").ViewBase
local CardEmbattleReady = class("CardEmbattleReady", Dialog)

CardEmbattleReady.RESOURCE_FILENAME = "card_embattle_ready.json"
CardEmbattleReady.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("battleDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				asyncPreload = 4,
				onItem = function(list, node, k, v)
					local childs = node:multiget("list", "node", "name", "btnGHimg", "power", "powerText", "btnChangeName", "btnSure", "btnFormation", "btnClear")
					childs.name:text(v.name)
					if v.teamBuffs then
						childs.btnGHimg:texture(v.teamBuffs.buf.imgPath)
					end
					childs.powerText:text(v.getFightSumNum)
					adapt.oneLinePos(childs.power, childs.powerText, cc.p(0, 0))
					childs.btnClear:setTouchEnabled(v.state)
					childs.btnSure:setTouchEnabled(v.state)
					text.deleteAllEffect(childs.btnSure:get("textNote"))
					if v.state then
						cache.setShader(childs.btnClear, false, "normal")
						cache.setShader(childs.btnSure, false, "normal")
						text.addEffect(childs.btnSure:get("textNote"), {color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})
					else
						cache.setShader(childs.btnClear, false, "hsl_gray")
						cache.setShader(childs.btnSure, false, "hsl_gray")
						text.addEffect(childs.btnSure:get("textNote"), {color = ui.COLORS.DISABLED.WHITE})
					end
					childs.list:removeAllItems()
					childs.list:setScrollBarEnabled(false)
					for i = 1, 6 do
						local icon = childs.node:clone()
						icon:visible(true)
						icon:setTouchEnabled(true)
						bind.touch(list, icon, {methods = {ended = functools.partial(list.formationClickCell, k, v)}})
						if v.cardsData[i] then
							local unitId = dataEasy.getUnitId(v.cardsData[i]:read("card_id"),v.cardsData[i]:read("skin_id"))
							bind.extend(list, icon, {
								class = "card_icon",
								props = {
									unitId = unitId,
									advance = v.cardsData[i]:read("advance"),
									rarity = v.cardsData[i]:read("rarity"),
									star = v.cardsData[i]:read("star"),
									levelProps = {
										data = v.cardsData[i]:read("level"),
									},
								}
							})
							icon:get("bg"):visible(false)
						end
						childs.list:pushBackCustomItem(icon)
					end

					bind.touch(list, childs.btnClear, {methods = {ended = functools.partial(list.clearClickCell, k, v)}})
					bind.touch(list, childs.btnFormation, {methods = {ended = functools.partial(list.formationClickCell, k, v)}})
					bind.touch(list, childs.btnSure, {methods = {ended = functools.partial(list.sureClickCell, k, v)}})
					bind.touch(list, childs.btnGHimg, {methods = {ended = functools.partial(list.teamBuffClickCell, k, v)}})
					bind.touch(list, childs.btnChangeName, {methods = {ended = functools.partial(list.changeNameClickCell, k, v)}})
				end,
			},
			handlers = {
				sureClickCell = bindHelper.self("onSureClick"),
				clearClickCell = bindHelper.self("onClearClick"),
				formationClickCell = bindHelper.self("onFormationClick"),
				teamBuffClickCell = bindHelper.self("onTeamBuffClick"),
				changeNameClickCell = bindHelper.self("onChangeNameClick"),
			},
		},
	}
}

function CardEmbattleReady:onCreate(params)
	self.params = params

	self:initModel()
	self.battleDatas = idlers.newWithMap({})

	idlereasy.when(self.ready_cards, function(_, ready_cards)
		local datas = {}
		for i = 1, gCommonConfigCsv.embattleReadyMax do
			local cardsData = {}
			local empty = true
			local name = gLanguageCsv["team"..i]
			local teamBuffs = nil
			local getFightSumNum = 0
			local cards = ready_cards[i] and ready_cards[i].cards or {}
			if ready_cards[i] then
				for idx, id in pairs(cards) do
					empty = false
					cardsData[idx] = self:getCardAttr(id)
				end
				teamBuffs = self:refreshTeamBuff(cards)
				getFightSumNum = self:getFightSumNum(cards)
				if ready_cards[i].name and ready_cards[i].name ~= "" then
					name = ready_cards[i].name
				end
			end
			table.insert(datas, {cards = cards, cardsData = cardsData, name = name, state = not empty, getFightSumNum = getFightSumNum, teamBuffs = teamBuffs})
		end
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.battleDatas:update(datas)
	end)

	Dialog.onCreate(self)
end

function CardEmbattleReady:initModel()
	self.ready_cards = gGameModel.role:getIdler("ready_cards")--预设队伍卡牌
end

function CardEmbattleReady:getCardAttr(cardId, attrString)
	if attrString then
		return gGameModel.cards:find(cardId):read(attrString)
	else
		return gGameModel.cards:find(cardId)
	end
end

function CardEmbattleReady:getFightSumNum(battle)
	local fightSumNum = 0
	for k,v in pairs(battle) do
		local fightPoint = self:getCardAttr(v, "fighting_point")
		fightSumNum = fightSumNum + fightPoint
	end
	return fightSumNum
end

-- 根据布阵信息刷新队伍光环效果
function CardEmbattleReady:refreshTeamBuff(battleCards)
	local attrs = {}
	for i = 1, 6 do
		local dbid = battleCards[i]
		if dbid then
			local card_id = self:getCardAttr(dbid, "card_id")
			local cardCfg = csv.cards[card_id]
			local unitCfg = csv.unit[cardCfg.unitID]
			attrs[i] = {unitCfg.natureType, unitCfg.natureType2}
		end
	end
	return dataEasy.getTeamBuffBest(attrs)
end

-- 应用此队伍
function CardEmbattleReady:onSureClick(list, k ,v)
	local function closeView()
		gGameUI:showTip(gLanguageCsv.teamSaveSuccess)
		ViewBase.onClose(self)
	end
	self.params.cb(table.deepcopy(v.cards, true), closeView)
end

-- 清除
function CardEmbattleReady:onClearClick(list, k ,v)
	gGameUI:showDialog({
		content = gLanguageCsv.teamClear,
		btnType = 2,
		cb = function()
		gGameApp:requestServer("/game/ready/card/deploy", function(tb)
			gGameUI:showTip(gLanguageCsv.positionSave)
			end, k, {})
	end})
end

-- 编队
function CardEmbattleReady:onFormationClick(list, k ,v)
	gGameUI:stackUI("city.card.embattle.base", nil, {full = true}, {
		sceneType = self.params.sceneType,
		from = game.EMBATTLE_FROM_TABLE.ready,
		inputCards = idlertable.new(v.cards),
		readyIdx = k,
	})
end

-- 显示buff
function CardEmbattleReady:onTeamBuffClick(list, k ,v)
	local teamBuffs = v.teamBuffs and v.teamBuffs.buf.teamBuffs or {}
	gGameUI:stackUI("city.card.embattle.attr_dialog",nil, {}, teamBuffs)
end

-- 改队名
function CardEmbattleReady:onChangeNameClick(list, k ,v)
	gGameUI:stackUI("city.card.changename", nil, nil, {
		typ = "ready",
		name = v.name,
		cost = 0,
		maxFontCount = 7,
		titleTxt = gLanguageCsv.changeReadyName,
		requestParams = {k},
		cb = function (name)
			self.battleDatas:atproxy(k).name = name
		end
	})
end

return CardEmbattleReady