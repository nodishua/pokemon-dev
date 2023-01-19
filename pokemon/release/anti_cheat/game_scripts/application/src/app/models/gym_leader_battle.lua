--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- GymLeaderBattle 道馆馆主战斗
--

local GameBattleModel = require("app.models.battle")
local GymLeaderBattle = class("GymLeaderBattle", GameBattleModel)

GymLeaderBattle.DefaultGateID = game.GATE_TYPE.gymLeader

function GymLeaderBattle:getPreDataForEnd(roleOut)
	return {}
end

return GymLeaderBattle
