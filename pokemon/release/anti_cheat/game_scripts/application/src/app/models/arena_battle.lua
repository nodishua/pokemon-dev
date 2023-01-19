--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- ArenaBattle 竞技场战斗，战报回放
--

local GameBattleModel = require("app.models.battle")
local ArenaBattle = class("ArenaBattle", GameBattleModel)


ArenaBattle.DefaultGateID = game.GATE_TYPE.arena

function ArenaBattle:getPreDataForEnd(roleOut)
	return {}
end

return ArenaBattle