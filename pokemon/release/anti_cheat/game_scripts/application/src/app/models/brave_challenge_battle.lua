--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
-- BraveChallengeBattle 勇者挑战战斗
--
local BCAdapt = require("app.views.city.activity.brave_challenge.adapt")
local GameBattleModel = require("app.models.battle")
local BraveChallengeBattle = class("BraveChallengeBattle", GameBattleModel)

BraveChallengeBattle.DefaultGateID = game.GATE_TYPE.braveChallenge

function BraveChallengeBattle:getData()
	local ret = GameBattleModel.getData(self)
	ret.floorID = self.floorID
	ret.actions = self.actions
	ret.gamemodel_data = ret.gamemodel_data or BraveChallengeBattle.getGameModelData(self)
	ret.battleEndUrl = BCAdapt.url("battleEnd")
	return ret
end

function BraveChallengeBattle:getGameModelData()
	local brave_challenge_gamemodel = {}

	brave_challenge_gamemodel["cards"] = {}
	for _, cardId in ipairs(self.cards) do
		if self.cards_status[cardId] then
			brave_challenge_gamemodel["cards"][cardId] = self.cards_status[cardId]
		end
	end

	brave_challenge_gamemodel["monsters"] = {}
	for _, cardId in pairs(self.defence_cards) do
		if self.monsters_status[cardId] then
			brave_challenge_gamemodel["monsters"][cardId] = self.monsters_status[cardId]
		end
	end

	return brave_challenge_gamemodel
end

function BraveChallengeBattle:getPreDataForEnd(roleOut)
	return {}
end

return BraveChallengeBattle