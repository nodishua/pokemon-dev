local CardEmbattleView = require "app.views.city.card.embattle.base"
local CardEmbattleArenaView = class("CardEmbattleArenaView", CardEmbattleView)

CardEmbattleArenaView.RESOURCE_FILENAME = "card_embattle.json"
CardEmbattleArenaView.RESOURCE_BINDING = {
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
	["useDefaultBattle"] = {
		varname = "useDefaultBattle",
		binds = {
			event = "click",
			method = bindHelper.self("onUseDefaultBattle"),
		},
	},
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

-- ??????UI?????????
function CardEmbattleArenaView:initRoundUIPanel()
	adapt.centerWithScreen("left", "right", nil, {
		{self.fightNote, "pos", "right"},
		{self.btnChallenge, "pos", "right"},
		{self.btnJump, "pos", "right"},
		{self.rightDown, "pos", "right"},
	})

	local showFightBtn = self.fightCb and true or false
	self.rightDown:visible(not showFightBtn)
	self.btnChallenge:visible(showFightBtn)
	self.btnJump:visible(false)
	self.useDefaultBattle:visible(not showFightBtn)
	self:initDeployment()
end

-- ???????????????????????????
function CardEmbattleArenaView:onUseDefaultBattle()
	local flag = not self.deploymentFlag:read()
	local key = self.fightCb and "arena_cards" or "arena_defence_cards"
	gGameApp:requestServer("/game/deployment/sync", function()
		-- ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
		if flag then
			self.battleCardsData:notify()
		end
		self:setDeploymentFlag()
	end, key, flag)
end

function CardEmbattleArenaView:setDeploymentFlag()
	local key = self.fightCb and "arena_cards" or "arena_defence_cards"
	local flag = gGameModel.role:read("deployments_sync")
	self.deploymentFlag:set(flag[key] or false)
end

function CardEmbattleArenaView:initDeployment( )
	-- ????????????????????????????????????, ???????????????????????????????????????????????????
	self.deploymentFlag = idler.new(false)
	idlereasy.when(self.deploymentFlag, function(_, flag)
		self.useDefaultBattle:get("checkBox"):setSelectedState(flag)
	end)
	idlereasy.when(self.clientBattleCards, function (_, battle)
		self.deploymentFlag:set(false)
	end, true)
	self:setDeploymentFlag()
end

-- ????????????
function CardEmbattleArenaView:oneKeyEmbattleBtn()
	CardEmbattleView.oneKeyEmbattleBtn(self)
	self.deploymentFlag:set(false)
end

return CardEmbattleArenaView