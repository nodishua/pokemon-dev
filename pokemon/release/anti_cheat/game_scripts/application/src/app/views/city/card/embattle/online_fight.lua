local CardEmbattleView = require "app.views.city.card.embattle.base"
local CardEmbattleOnlineFightView = class("CardEmbattleOnlineFightView", CardEmbattleView)

CardEmbattleOnlineFightView.RESOURCE_FILENAME = "card_embattle.json"
CardEmbattleOnlineFightView.RESOURCE_BINDING = {
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

function CardEmbattleOnlineFightView:onCreate(params)
	CardEmbattleView.onCreate(self,params)
	if params.tip then
		gGameUI:showTip(gLanguageCsv.onlineFightTeamChange)
	end
end

-- ??????UI?????????
function CardEmbattleOnlineFightView:initRoundUIPanel()
	adapt.centerWithScreen("left", "right", nil, {
		{self.fightNote, "pos", "right"},
		{self.btnChallenge, "pos", "right"},
		{self.btnJump, "pos", "right"},
		{self.rightDown, "pos", "right"},
	})
	local showFightBtn = false
	self.rightDown:visible(not showFightBtn)
	self.btnChallenge:visible(showFightBtn)
	self.btnJump:visible(false)
	self.useDefaultBattle:visible(not showFightBtn)
	self:initDeployment()
end

-- ???????????????????????????
function CardEmbattleOnlineFightView:onUseDefaultBattle()
	local flag = not self.deploymentFlag:read()
	local key = "cross_online_fight"
	gGameApp:requestServer("/game/deployment/sync", function()
		-- ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
		if flag then
			self.battleCardsData:notify()
		end
		self:setDeploymentFlag()
	end, key, flag)
end

function CardEmbattleOnlineFightView:setDeploymentFlag()
	local key = "cross_online_fight"
	local flag = gGameModel.role:read("deployments_sync")
	self.deploymentFlag:set(flag[key] or false)
end

function CardEmbattleOnlineFightView:initDeployment( )
	-- ????????????????????????????????????, ???????????????????????????????????????????????????
	self.deploymentFlag = idler.new(false)
	idlereasy.when(self.deploymentFlag, function(_, flag)
		self.useDefaultBattle:get("checkBox"):setSelectedState(flag)
	end)
	idlereasy.when(self.clientBattleCards, function (_, battle)
		local changed = false
		for k, v in pairs(battle) do
			local card = gGameModel.cards:find(v)
			if self:confirmBanCard(card:read("card_id")) then
				battle[k] = nil
				changed = true
			end
		end
		if changed then
			gGameUI:showTip(gLanguageCsv.onlineFightUseMainTeam)
		end
		self.deploymentFlag:set(false)
	end, true)
	self:setDeploymentFlag()
end

function CardEmbattleOnlineFightView:limtFunc(dbid, card_id, skin_id,fighting_point, level, star, advance, created_time, nature_choose, inBattle)
	if self:confirmBanCard(card_id) then
		return nil
	end
	local tb = CardEmbattleView.limtFunc(self, dbid, card_id,skin_id, fighting_point, level, star, advance, created_time, nature_choose, inBattle)
	return tb
end

--???????????????ban?????????
function CardEmbattleOnlineFightView:confirmBanCard(cardID)
	if gGameModel.cross_online_fight:read("round") == "closed" then
		return false
	end
	local startDate = gGameModel.cross_online_fight:read("start_date") -- ????????????
	local day = math.floor((time.getTime() - time.getNumTimestamp(startDate, 5, 0, 0)) / 60 / 60 / 24) + 1
	local isLimit = false
	local cfg = {}
	for _, data in csvPairs(csv.cross.online_fight.theme_open) do
		if data.day == day then
			cfg = data
			break
		end
	end
	if itertools.size(cfg.invalidMarkIDs or {}) == 0 and itertools.size(cfg.invalidMegaCardIDs or {}) == 0 then
		return false
	end
	-- ???mega
	for _, v in ipairs(cfg.invalidMarkIDs) do
		if csv.cards[cardID].cardMarkID == v then
			return true
		end
	end
	-- mega
	for _, id in ipairs(cfg.invalidMegaCardIDs) do
		if cardID == id then
			return true
		end
	end
	return false
end
-- ????????????
function CardEmbattleOnlineFightView:oneKeyEmbattleBtn()
	CardEmbattleView.oneKeyEmbattleBtn(self)
	self.deploymentFlag:set(false)
end

return CardEmbattleOnlineFightView