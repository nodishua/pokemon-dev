--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
-- RandomTowerBattle 试炼塔战斗
--

local GameBattleModel = require("app.models.battle")
local RandomTowerBattle = class("RandomTowerBattle", GameBattleModel)

RandomTowerBattle.DefaultGateID = game.GATE_TYPE.randomTower

function RandomTowerBattle:getData()
	local ret = GameBattleModel.getData(self)
	ret.actions = self.actions
	ret.gamemodel_data = ret.gamemodel_data or RandomTowerBattle.getGameModelData(self)
	return ret
end

function RandomTowerBattle:getGameModelData()
	local random_tower_gamemodel = {}

	random_tower_gamemodel["buffs"] = table.getraw(gGameModel.random_tower:read("buffs"))
	random_tower_gamemodel["skill_used"] = table.getraw(gGameModel.random_tower:read("skill_used"))
	random_tower_gamemodel["enemy_states"] = table.getraw(gGameModel.random_tower:read("enemy_states"))
	random_tower_gamemodel["card_states"] = table.getraw(gGameModel.random_tower:read("card_states"))
	random_tower_gamemodel["room_info"] = table.getraw(gGameModel.random_tower:read("room_info"))

	return random_tower_gamemodel
end

function RandomTowerBattle:getPreDataForEnd(roleOut)
	return {}
end

return RandomTowerBattle