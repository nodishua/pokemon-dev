-- @date 2021-07-01
-- @desc 夏日挑战关卡详情界面

local ViewBase = cc.load("mvc").ViewBase
local SummerChallengeGateDetail = class("SummerChallengeGateDetail", ViewBase)
SummerChallengeGateDetail.RESOURCE_FILENAME = "summer_challenge_gate_detail.json"
SummerChallengeGateDetail.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["item"] = "item",
	["enemyList"] = {
		varname = "enemyList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 6,
				padding = 10,
				data = bindHelper.self("combatDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							cardId = v.cardId,
							-- unitId = v.unitId,
							advance = v.advance,
							levelProps = {
								data = v.level,
							},
							star = v.star,
							rarity = v.rarity,
							onNode = function(panel)
								panel:y(node:height()/2)
								panel:anchorPoint(0, 0.5)
								panel:scale(0.9)
							end,
						}
					})
				end,
			}
		},
	},
	["rewardList"] = "rewardList",
	["battleBtn"] = {
		varname = "battleBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBattleClick")},
		},
	},
	["battleBtn.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
	["title1"] = "title1",
	["title2"] = "title2",
	["title3"] = "title3",
	["reviewPanel"] = "reviewPanel",
	["reviewPanel.list"] = "reviewList",
	["gateTextList"] = "gateTextList",
}
SummerChallengeGateDetail.RESOURCE_STYLES = {
	blackLayer = true,
	clickClose = true,
}

function SummerChallengeGateDetail:onCreate(params)
	self.handler = params.handler
	local data = params.data
	local floor = data.floor
	local gateCfg = data.gateCfg
	self.gateCfg = gateCfg
	self.gateID = data.gateID

	local yyhuodongs = gGameModel.role:read("yyhuodongs")

	self.title2:text(floor)
	self.title3:text(gateCfg.name)
	adapt.oneLinePos(self.title1, self.title2, cc.p(3, 0))
	adapt.oneLinePos(self.title2, self.title3, cc.p(15, 0))

	beauty.textScroll({
		list = self.gateTextList,
		strs = "#C0x5B545B#" .. gateCfg.desc,
		fontSize = 36,
		isRich = true,
	})
	uiEasy.createItemsToList(self, self.rewardList, gateCfg.award, {scale = 0.8})

	local monsterID = gateCfg.monsterIDs[itertools.size(gateCfg.monsterIDs)]
	local cards = csv.summer_challenge.monsters[monsterID].cards
	self.combatDatas = idlers.newWithMap(self:getMonsters(cards))

	local yyData = yyhuodongs[params.yyID] or {}
	local stamps = yyData.stamps or {}
	local isShowReviewPanel = stamps[self.gateID] == 1

	self.battleBtn:visible(not isShowReviewPanel)
	self.reviewPanel:visible(isShowReviewPanel)
	if isShowReviewPanel then
		beauty.textScroll({
			list = self.reviewList,
			strs = "#C0x5B545B#" .. gateCfg.reviewPlot,
			fontSize = 40,
			isRich = true,
		})
	end
	-- Dialog.onCreate(self)
end

function SummerChallengeGateDetail:getMonsters(cards)
	local datas = {}
	local cardsCsv = csv.summer_challenge.cards
	for k, id in ipairs(cards) do
		if id > 0 then
			local cfg = cardsCsv[id]
			table.insert(datas, {
				cardId = cfg.cardID,
				unitId = cfg.unitID,
				advance = cfg.advance,
				level = cfg.level,
				rarity = cfg.rarity,
				star = cfg.star,
			})
		end
	end
	return datas
end

function SummerChallengeGateDetail:onBattleClick()
	gGameUI:stackUI("city.activity.summer_challenge.embattle", nil, {full = true},
		{fightCb = self:createHandler("startFighting"), gateCfg = self.gateCfg, gateID = self.gateID})
end

function SummerChallengeGateDetail:startFighting(view, battleCards)
	self.handler(view, self, battleCards)
end

return SummerChallengeGateDetail