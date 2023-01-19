local ViewBase = cc.load("mvc").ViewBase
local CardEmbattleView = require "app.views.city.card.embattle.base"
local CardEmbattleActivityBossView = class("CardEmbattleActivityBossView", CardEmbattleView)

CardEmbattleActivityBossView.RESOURCE_FILENAME = "card_embattle.json"
CardEmbattleActivityBossView.RESOURCE_BINDING = {
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

function CardEmbattleActivityBossView:onClose(sendRequeat)
    if sendRequeat == true  then
        if self.from == game.EMBATTLE_FROM_TABLE.huodongBoss then
			local battleCards = self.clientBattleCards:read()
			local battleCardsHex = {}
			for k, v in pairs(battleCards) do
				battleCardsHex[k] = stringz.bintohex(v)
			end
			userDefault.setForeverLocalKey("huodongboss_emabttle", battleCardsHex, {new = true})
			ViewBase.onClose(self)
		else
			ViewBase.onClose(self)
	end
	else
        if self.from == game.EMBATTLE_FROM_TABLE.huodongBoss then
				local battleCards = self.clientBattleCards:read()
				local battleCardsHex = {}
				for k, v in pairs(battleCards) do
					battleCardsHex[k] = stringz.bintohex(v)
				end
				userDefault.setForeverLocalKey("huodongboss_emabttle", battleCardsHex, {new = true})
				ViewBase.onClose(self)
			else
				ViewBase.onClose(self)
        end
	end
end

return CardEmbattleActivityBossView