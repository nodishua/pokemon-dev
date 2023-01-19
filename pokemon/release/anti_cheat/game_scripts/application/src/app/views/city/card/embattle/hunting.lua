local CardEmbattleView = require "app.views.city.card.embattle.base"
local CardEmbattleHuntingView = class("CardEmbattleHuntingView", CardEmbattleView)

CardEmbattleHuntingView.RESOURCE_FILENAME = "card_embattle.json"
CardEmbattleHuntingView.RESOURCE_BINDING = {
	["btnGHimg"] = {
		varname = "btnGHimg",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onTeamBuffClick")}
		}
	},
	["battlePanel"] = "battlePanel",
	["spritePanel"] = "spriteItem",
	["dailyGateTipsPos"] = "dailyGateTipsPos",
	["btnJump"] = {
		varname = "btnJump",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("cardBagBtn")}
		},
	},

	["textNotRole"] = "emptyTxt",
	["btnChallenge"] = {
		varname = "btnChallenge",
		binds = {
			event = "touch",
			clicksafe = true,
			methods = {ended = bindHelper.self("fightBtn")}
		},
	},
	["fightNote"] = "fightNote",
	["fightNote.textFightPoint"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("fightSumNum"),
		},
	},
	["ahead.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["back.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["btnJump.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["btnChallenge.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["rightDown"] = "rightDown",
	["rightDown.btnOneKeySet"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("oneKeyEmbattleBtn")}
		},
	},
	["rightDown.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("battleNum"),
		},
	},
	["rightDown.btnOneKeySet.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["textLimit"] = "textLimit",
	["bottomMask"] = "bottomMask",
	["bottomPanel"] = "bottomPanel",
	["btnReady"] = {
		varname = "btnReady",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("oneReadyBtn")}
		},
	},
	["btnReady.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["rightDown.btnSaveReady"] = {
		varname = "btnSaveReady",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("oneSaveReadyBtn")}
		},
	},
	["rightDown.btnSaveReady.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
}

function CardEmbattleHuntingView:getCardStates()
	return gGameModel.hunting:read("hunting_route")[self.route].card_states or {}
end

function CardEmbattleHuntingView:initBottomList( )
	self.cardListView = gGameUI:createView("city.card.embattle.hunting_card_list", self.bottomPanel):init({
		base = self,
		clientBattleCards = self.clientBattleCards,
		battleCardsData = self.battleCardsData,
		selectIndex = self.selectIndex,
		deleteMovingItem = self.deleteMovingItem,
		createMovePanel = self.createMovePanel,
		moveMovePanel = self.moveMovePanel,
		isMovePanelExist = self.isMovePanelExist,
		onCardClick = self.onCardClick,
		allCardDatas = self.allCardDatas,
		moveEndMovePanel = self.moveEndMovePanel,
		limtFunc = self.limtFunc,
	}, true)
end

-- limitInfo: 限制上阵的条件1-限制可上阵的精灵自然属性 2-限制不可上阵的精灵自然属性 6-强制上阵特定稀有度的精灵
function CardEmbattleHuntingView:initParams(params)
	CardEmbattleView.initParams(self, params)
end

-- 只有超过10级才行
function CardEmbattleHuntingView:limtFunc(dbid, card_id, skin_id,fighting_point, level, star, advance, created_time, nature_choose, inBattle)
	if level < 10 then return nil end
	local tb = CardEmbattleView.limtFunc(self, dbid, card_id,skin_id, fighting_point, level, star, advance, created_time, nature_choose, inBattle)
	local cardStates = self:getCardStates()
	tb.states = cardStates[dbid] or {1,0}
	return tb
end

-- 一键布阵的筛选按钮
function CardEmbattleHuntingView:embattleBtnFunc(hash, v)
	if not CardEmbattleView.embattleBtnFunc(self, hash, v) then return false end

	local states = self:getCardStates()
	local state = states[v.dbid] or {1, 1}
	return state[1] > 0 		-- 小于等于0 不允许上阵
end

return CardEmbattleHuntingView