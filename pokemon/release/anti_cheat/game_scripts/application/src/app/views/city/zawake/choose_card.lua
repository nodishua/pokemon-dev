-- @date:   2021-04-25
-- @desc:   z觉醒卡牌选择主界面

local ViewBase = cc.load("mvc").ViewBase
local ZawakeChoosCardView = class("ZawakeChoosCardView", Dialog)

local function isInUnion(dbId)
	local cardDeployment = gGameModel.role:read("card_deployment")
	for k,v in pairs(cardDeployment.union_training.cards or {}) do
		if v == dbId then
			return true
		end
	end
	return false
end

ZawakeChoosCardView.RESOURCE_FILENAME = "zawake_choose_card.json"
ZawakeChoosCardView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["title.textNote2"] = "textNote2",
	["tipPanel"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("showTip"),
		},
	},
	["chooseItem"] = "item",
	["innerList"] = "innerList",
	["list"] = {
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("cardDatas"),
				item = bindHelper.self("innerList"),
				cell = bindHelper.self("item"),
				asyncPreload = 12,
				columnSize = 3,
				itemAction = {isAction = true},
				dataOrderCmp = function(a, b)
					if a.battle ~= b.battle then
						return a.battle == 2
					end
					if a.rarity ~= b.rarity then
						return a.rarity < b.rarity
					end
					if a.id ~= b.id then
						return a.id < b.id
					end
					return a.fight < b.fight
				end,
				onCell = function(list, node, k, v)
					bind.extend(list, node:get("head"), {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							star = v.star,
							rarity = v.rarity,
							levelProps = {
								data = v.level,
							},
						}
					})
					local txt = gLanguageCsv.inTheTeam
					if v.battle == 1 then
						if ui.CARD_USING_TXTS[v.battleType] then
							txt = gLanguageCsv[ui.CARD_USING_TXTS[v.battleType]]
						end
					end
					local textNote = node:get("battle.textNote")
					textNote:text(txt)
					uiEasy.addTextEffect1(textNote)
					node:get("textName"):text(csv.cards[v.id].name)
					node:get("textFightPoint"):text(v.fight)
					node:get("imgLock"):visible(v.lock)
					node:get("imgTick"):visible(v.isSel)
					node:get("imgMask"):visible(v.battle == 1 or v.isSel)
					node:get("battle"):visible(v.battle == 1 )

					-- local t = list:getIdx(k)
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onSelectClick"),
			},
		},
	},
}

-- 卡牌选择
function ZawakeChoosCardView:onCreate(params, cb)
	self.selectCardDbId = params.selectCardDbId

	local fragID = params.fragID

	self.cardDatas = idlers.new({})
	self.cb = cb
	self.showTip = idler.new(false)

	self.exchangeCfg = csv.zawake.exchange[fragID]
	local text = gLanguageCsv.card
	local cards = self:getSelectCard(self.selectCardDbId:read())
	self.cardDatas:update(cards)

	self.showTip:set(itertools.size(cards) == 0)
	self.textNote2:text(text)

	Dialog.onCreate(self)
end



function ZawakeChoosCardView:getSelectCard(selectCardDbId)
	local result = {}
	local csvTab = csv.cards
	local unitTab = csv.unit
	local hash = dataEasy.inUsingCardsHash()
	local cards = gGameModel.role:read("cards")--卡牌
	for i,v in ipairs(cards) do
		local card = gGameModel.cards:find(v)
		local cardId = card:read("card_id")
		local skinId = card:read("skin_id")
		local cardCsv = csvTab[cardId]
		local unitCsv = unitTab[cardCsv.unitID]
		local unitId = dataEasy.getUnitId(cardId,skinId)
		if card:read("star") == cardCsv.star then
			for _, needCard in csvMapPairs(self.exchangeCfg.needCards) do
				if needCard[1] == unitCsv.rarity and (needCard[2] == -1 or needCard[2] == unitCsv.natureType or needCard[2] == unitCsv.natureType2) then
					local t = {
						id = cardId,
						unitId = unitId,
						rarity = unitCsv.rarity,
						fight = card:read("fighting_point"),
						level = card:read("level"),
						star = card:read("star"),
						advance = card:read("advance"),
						dbid = v,
						lock = card:read("locked"),
						battle = hash[v] and 1 or 2,
						battleType = hash[v],
						isUnion = isInUnion(v),
						isSel = selectCardDbId == v,
						cardType = cardCsv.cardType
					}
					result[v] = t
				end
			end
			for _, markID in csvMapPairs(self.exchangeCfg.needSpecialCards) do
				if markID == cardCsv.cardMarkID then
					local t = {
						id = cardId,
						unitId = unitId,
						rarity = unitCsv.rarity,
						fight = card:read("fighting_point"),
						level = card:read("level"),
						star = card:read("star"),
						advance = card:read("advance"),
						dbid = v,
						lock = card:read("locked"),
						battle = hash[v] and 1 or 2,
						battleType = hash[v],
						isUnion = isInUnion(v),
						isSel = curSle == v,
						cardType = cardCsv.cardType
					}
					result[v] = t
				end
			end
		end

	end
	return result
end

function ZawakeChoosCardView:onSelectClick(list, k, v)
	if v.isSel then return end
	local function isLock()
		if v.lock then
			local str =  gLanguageCsv.starSkillExchange
			local params = {
				cb = function()
					gGameUI:stackUI("city.card.strengthen", nil, {full = true}, 1, v.dbid, self:createHandler("onChangeData", k, v))
				end,
				btnType = 2,
				content = string.format(gLanguageCsv.gotoUnLock, str),
				clearFast = true,
			}
			gGameUI:showDialog(params)
			return true
		end
	end
	local function isInBattle()
		if v.battle == 1 then
			local txts = {
				battle = 'inCityTeamCantExchange',
				unionTraining = 'isInUnionCantExchange',
				arena = 'inArenaCantExchange',
				craft = 'inCraftCantExchange',
				unionFight = 'inUnionFightCantExchange',
				cloneBattle = 'inCloneBattleCantExchange',
				crossCraft = 'inCrossCraftCantExchange',
				crossArena = 'inCrossArenaCantExchange',
				gymBadgeGuard = 'inGymBadgeGuardCantExchange',
				gymLeader = "inGymCantExchange",
				crossGymLeader = "inCrossGymCantExchange",
				crossMine = "inCrossMineCantExchange",
			}
			local txt = gLanguageCsv[txts[v.battleType]]
			gGameUI:showTip(txt)
			return true
		end
	end
	if isInBattle() then
		return
	end
	if isLock() then
		return
	end

	local cardCfg = csv.cards[v.id]
	local str = nil
	if v.level > 1 or v.advance > 1 or v.star > cardCfg.star then
		str = gLanguageCsv.selectCardMaterialsMega
	end
	local function cb()
		self.selectCardDbId:set(v.dbid)
		ViewBase.onClose(self)
	end
	if str then
		gGameUI:showDialog({title = gLanguageCsv.spaceTips, content = str, isRich = true, fontSize = 50, btnType = 2, cb = cb})
		return
	end
	cb()
end

function ZawakeChoosCardView:onChangeData(idx, v)
	local card = gGameModel.cards:find(v.dbid)
	self.cardDatas:atproxy(v.dbid).lock = card:read("locked")
end

return ZawakeChoosCardView