-- @date:   2019-10-12
-- @desc:   随机塔-使用buff
--前置条件（1-有精灵残血；2-有精灵怒气没达到1000；3-有精灵死亡）
local SUPPLY_TITLE = {
	[1] = gLanguageCsv.recover,
	[2] = gLanguageCsv.recover,
	[3] = gLanguageCsv.revive
}
local randomTowerTools = require "app.views.city.adventure.random_tower.tools"
local ViewBase = cc.load("mvc").ViewBase
local RandomTowerUseBuffView = class("RandomTowerUseBuffView", Dialog)

RandomTowerUseBuffView.RESOURCE_FILENAME = "random_tower_use_buff.json"
RandomTowerUseBuffView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["textNum"] = "textNum",
	["item"] = "item",
	["subList"] = "subList",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("cardDatas"),
				columnSize = 7,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					local childs = node:multiget(
						"cardPanel",
						"mask",
						"hpBar",
						"mpBar",
						"imgDie",
						"extraCondition2",
						"gainChance",
						"btnReward",
						"btnComplete"
					)
					childs.imgDie:visible(v.hp <= 0)
					childs.hpBar:setPercent(v.hp * 100)
					local mpPercent = v.mp * 100
					if v.hp <= 0 then
						mpPercent = 0
					end
					childs.mpBar:setPercent(mpPercent)
					local size = node:size()
					bind.extend(list, childs.cardPanel, {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							rarity = v.rarity,
							star = v.star,
							levelProps = {
								data = v.level,
							},
							onNode = function (panel)
								-- panel:scale(1.1)
							end,
						}
					})
					childs.mask:visible(v.selectState)
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick,list:getIdx(k), v)}})
				end,
				asyncPreload = 38,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onitemClick"),
				afterBuild = bindHelper.self("onAfterBuild"),
			},
		},
	},
	["btnSure"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnSure")},
		},
	},
	["textNote"] = "textNote"
}
function RandomTowerUseBuffView:onCreate(boardID, cb)
	self:initModel()
	self.cb = cb
	local roomInfo = self.roomInfo:read()
	local buffId = roomInfo.buff[boardID]
	local buffCfg = csv.random_tower.buffs[buffId]
	self.boardID = boardID
	self.buffId = buffId

	self.textNote:text(string.format(gLanguageCsv.selectCardSupply, SUPPLY_TITLE[buffCfg.supplyType]))

	self.cardDatas = idlers.new()
	local cardInfos = {}
	local cardState = self.cardStates:read()
	local cards = randomTowerTools.getCards(buffCfg.supplyTarget)
	for i,cardDbId in pairs(cards) do
		if randomTowerTools.reachCondition(buffCfg.condition, cardState[cardDbId], cardDbId) then
			table.insert(cardInfos, self:getCardData(cardDbId))
		end
	end
	table.sort(cardInfos, function(a,b)
		return a.fight > b.fight
	end)
	self.cardDatas:update(cardInfos)
	self.selectIdx = idler.new(0)
	self.textNum:text("0/1")
	adapt.oneLinePos(self.textNote, self.textNum, cc.p(5, 0))
	--单选的情况
	self.selectIdx:addListener(function(val, oldval)
		local cardDatas = self.cardDatas:atproxy(val)
		local oldCardDatas = self.cardDatas:atproxy(oldval)
		if oldCardDatas then
			oldCardDatas.selectState = false
		end
		if cardDatas then
			self.textNum:text("1/1")
			adapt.oneLinePos(self.textNote, self.textNum, cc.p(5, 0))
			cardDatas.selectState = true
		end
	end)

	Dialog.onCreate(self)
end
--获取卡牌数据
function RandomTowerUseBuffView:getCardData(cardDbId)
	local cardState = self.cardStates:read()[cardDbId]
	local hp = 1
	local mp = 0
	if cardState then
		hp = cardState[1]
		mp = cardState[2]
	end

	local card = gGameModel.cards:find(cardDbId)
	local cardData = card:read("card_id", "skin_id", "name", "level", "star", "advance", "fighting_point")
	local cardCsv = csv.cards[cardData.card_id]
	local unitCsv = dataEasy.getUnitCsv(cardData.card_id, cardData.skin_id)
	return {
		id = cardData.card_id,
		unitId = unitCsv.id,
		rarity = unitCsv.rarity,
		level = cardData.level,
		star = cardData.star,
		advance = cardData.advance,
		dbid = cardDbId,
		fight = cardData.fighting_point,
		selectState = false,
		hp = hp,
		mp = mp
	}
end

function RandomTowerUseBuffView:initModel()
	--卡牌血量怒气 {cardID: (hp, mp)}
	self.cardStates = gGameModel.random_tower:getIdler("card_states")
	self.roomInfo = gGameModel.random_tower:getIdler("room_info")
	self.cards = gGameModel.role:getIdler("cards")
end

function RandomTowerUseBuffView:onitemClick(list, t, v)
	self.selectIdx:set(t.k)
end

function RandomTowerUseBuffView:onBtnSure()
	local cardData = self.cardDatas:atproxy(self.selectIdx:read())
	if not cardData then
		return
	end
	local showOver = {false}
	gGameApp:requestServerCustom("/game/random_tower/buff/used")
		:params(cardData.dbid)
		:onResponse(function (tb)
			showOver[1] = true
		end)
		:wait(showOver)
		:doit(function(tb)
			self:addCallbackOnExit(self.cb)
			ViewBase.onClose(self)
		end)
end

return RandomTowerUseBuffView
