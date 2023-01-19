--
--@data: 2019-7-24 15:37:20
--@desc: 重生选择精灵界面
--
local RebirthTools = require "app.views.city.card.rebirth.tools"

local DECOMPOSE_MAX = 5
local SELECTED_ROLE = 1

local ChooseRoleView = class("ChooseRoleView", Dialog)

ChooseRoleView.RESOURCE_FILENAME = "rebirth_select_role.json"
ChooseRoleView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["item"] = "item",
	["innerList"] = "innerList",
	["list"] = {
		varname = "list",
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
					node:get("imgMask"):visible((list.from() == 2 and (v.battle == 1)) or v.isSel)
					node:get("battle"):visible(list.from() == 2 and (v.battle == 1 ))

					local t = list:getIdx(k)
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, t, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onCellClick"),
				from = bindHelper.self("from"),
			},
		},
	},
	["down"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("isShowDown")
		},
	},
	["down.textNum"] = "textNum",
	["down.textNote"] = "textNote",
	["down.btnOk"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSure")}
		},
	},
	["tipPanel"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("showTip"),
		},
	},
}

-- from 1:重生 2:分解
function ChooseRoleView:onCreate(params)
	self.from = params.from
	self.curSel = params.curSel
	self.handlers = params.handlers
	self.isShowDown = idler.new(false)
	self.showTip = idler.new(false)
	self.cardDatas = idlers.newWithMap({})
	local cards = RebirthTools.getSelectCard(self.from, self.curSel)
	table.sort(cards, function(a, b)
		if self.from == 1 then
			return a.fight > b.fight
		elseif self.from == 2 then
			if a.battle ~= b.battle then
				return a.battle == 2 and true or false
			end
			if a.rarity ~= b.rarity then
				return a.rarity < b.rarity
			end
			return a.fight < b.fight
		end
	end)
	self.cardDatas:update(cards)

	self.selected = {}
	if self.from == 2 then
		self.isShowDown:set(true)
		self.list:size(1665, 850)
		self.list:y(self.list:y() + 100)
		for k, v in ipairs(cards) do
			if itertools.include(self.curSel, v.dbid) then
				self.selected[k] = v
			end
		end
	end

	self.showTip:set(self.cardDatas:size() == 0)

	self.textNum:text(string.format("%s/%s",  itertools.size(self.selected), DECOMPOSE_MAX))
	Dialog.onCreate(self)
end
function ChooseRoleView:onChangeData(idx, v)
	local card = gGameModel.cards:find(v.dbid)
	self.cardDatas:atproxy(idx).lock = card:read("locked")
end

function ChooseRoleView:onCellClick(list, t, v)
	local len = itertools.size(self.selected)
	local max = self.from == 2 and DECOMPOSE_MAX or SELECTED_ROLE
	if not v.isSel and len >= max then
		gGameUI:showTip(string.format(gLanguageCsv.selectedmax, max))
		return
	end

	local function closeAndCallBack()
		self.selected[t.k] = v
		if self.handlers then
			self.handlers(self.selected)
		end
		self:onClose()
	end
	local function isLock()
		if v.lock then
			local str = self.from == 1 and gLanguageCsv.reborn or gLanguageCsv.decomposeText
			local params = {
				cb = function()
					gGameUI:stackUI("city.card.strengthen", nil, {full = true}, 1, v.dbid, self:createHandler("onChangeData", t.k, v))
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
			if self.from == 1 then
				local params = {
					cb = closeAndCallBack,
					btnType = 2,
					content = gLanguageCsv.sureRebirth,
				}
				gGameUI:showDialog(params)
			else
				local txts = {
					battle = 'inCityTeamCantDecompose',
					unionTraining = 'isInUnionCantDecompose',
					arena = 'inArenaCantDecompose',
					craft = 'inCraftCantDecompose',
					unionFight = 'inUnionFightCantDecompose',
					cloneBattle = 'inCloneBattleCantDecompose',
					crossCraft = 'inCrossCraftCantDecompose',
					crossArena = 'inCrossArenaCantDecompose',
					gymBadgeGuard = 'inGymBadgeGuardCantDecompose',
					gymLeader = "inGymCantDecompose",
					crossGymLeader = "inCrossGymCantDecompose",
					crossMine = "inCrossMineCantDecompose",
					crossunionfight = "inCrossUnionBattleNotDecompose"
				}
				local txt = gLanguageCsv[txts[v.battleType]]
				gGameUI:showTip(txt)
			end
			return true
		end
	end

	if self.from == 1 then
		if isLock() then
			return
		end
		if isInBattle() then
			return
		end
		closeAndCallBack()
	else
		if isInBattle() then
			return
		end
		if isLock() then
			return
		end
		local cardCsv = csv.cards[v.id]
		if v.isSel then
			self.cardDatas:atproxy(t.k).isSel = false
			self.selected[t.k] = nil
			local len = itertools.size(self.selected)
			self.textNum:text(string.format("%s/%s", len, DECOMPOSE_MAX))
			adapt.oneLinePos(self.textNote, self.textNum, nil, "left")
		else
			local content = ""
			local isSpe = false
			-- cardType == 2 是百变怪
			if v.cardType == 2 then
				isSpe = true
				content = gLanguageCsv.materialWizardBeenSelected
			-- elseif v.rarity >= 3 and RebirthTools.isSingleInEvoLine(v.dbid) then
			-- 	isSpe = true
			-- 	content = gLanguageCsv.rebirthTipDouble
			elseif v.rarity >= 3 then
				isSpe = true
				content = gLanguageCsv.sureDecomposeCard
			-- elseif RebirthTools.isSingleInEvoLine(v.dbid) then
			-- 	isSpe = true
			-- 	content = gLanguageCsv.rebirthTip
			elseif v.star > cardCsv.star then
				isSpe = true
				content = gLanguageCsv.higherStarContinueDecomposition
			end

			local function from2DataInsert()
				self.cardDatas:atproxy(t.k).isSel = true
				self.selected[t.k] = v
				local len = itertools.size(self.selected)
				self.textNum:text(string.format("%s/%s", len, DECOMPOSE_MAX))
				adapt.oneLinePos(self.textNote, self.textNum, nil, "left")
			end
			if isSpe then
				local params = {
					cb = from2DataInsert,
					btnType = 2,
					content = content,
				}
				gGameUI:showDialog(params)
			else
				from2DataInsert()
			end
		end
	end
end

function ChooseRoleView:onSure()
	if self.handlers then
		self.handlers(self.selected)
	end
	self:onClose()
end

return ChooseRoleView