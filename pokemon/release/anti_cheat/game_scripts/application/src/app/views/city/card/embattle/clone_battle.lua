local CardEmbattleView = require "app.views.city.card.embattle.base"
local CardEmbattleCloneView = class("CardEmbattleCloneView", CardEmbattleView)

CardEmbattleCloneView.RESOURCE_FILENAME = "card_embattle.json"
CardEmbattleCloneView.RESOURCE_BINDING = {
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

-- 只有超过10级才行
function CardEmbattleCloneView:onCreate(params)
	CardEmbattleView.onCreate(self,params)
	self.fightNote:hide()
	self.cardListView:hide()
	self.rightDown:hide()
	self.bottomMask:show()
end

function CardEmbattleCloneView:initRoundUIPanel()
	self.btnChallenge:visible(true)
	self.rightDown:visible(false)
	self.btnJump:visible(false)
end

function CardEmbattleCloneView:initParams(params)
	params = params or {}
	self.sceneType = game.SCENE_TYPE.clone
	self.fightCb = params.fightCb
	self.from = game.EMBATTLE_FROM_TABLE.input
	self.inputCardAttrs = params.inputCardAttrs		-- 外部配置的阵容的详细内容
	self.inputCards = params.inputCards				-- 外部配置阵容 如有 则不需要自己获取
	self.checkBattleArr = params.checkBattleArr or function()
		return true
	end
end

--显示单个精灵战力
function CardEmbattleCloneView:showItemFightPoint(fightPointText, unitCsv, dbid)
	fightPointText:show()
	local fPString = self:getCardAttr(dbid, "fighting_point")
	fightPointText:get("text"):text(fPString)
	local textSize = fightPointText:get("text"):size()
	local bgSize = fightPointText:get("bg"):size()
	fightPointText:get("bg"):size(textSize.width + 80, bgSize.height)		-- 背景图宽度适应变化
	local headY = unitCsv.everyPos.headPos.y
	fightPointText:y(headY + 100)
end

function CardEmbattleCloneView:getCardAttr(cardId, attrString)
	return self.inputCardAttrs:read()[cardId][attrString]
end

function CardEmbattleCloneView:getCardAttrIdler(cardId, attrString)
	return self.inputCardAttrs:read()[cardId][attrString] -- only value
end

-- 重写base函数
function CardEmbattleCloneView:onCardClick(data, isShowTip)
	return
end

function CardEmbattleCloneView:resetBattleCardsCallBack()
	return
end

function CardEmbattleCloneView:getCardAttrs(dbid)
	local data = self.inputCardAttrs:read()[dbid]
	if data then
		local unitId = dataEasy.getUnitId(data.card_id, data.skin_id)
		return {card_id = data.card_id, battle = 1, dbid = data.id, unit_id = unitId}
	end
end


return CardEmbattleCloneView