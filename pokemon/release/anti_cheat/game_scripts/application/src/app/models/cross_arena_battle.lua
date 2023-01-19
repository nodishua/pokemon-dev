--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- CrossArenaBattle 跨服竞技场战斗, 战报回放
--

local GameBattleModel = require("app.models.battle")
local CrossArenaBattle = class("CrossArenaBattle", GameBattleModel)

CrossArenaBattle.DefaultGateID = game.GATE_TYPE.crossArena
CrossArenaBattle.MultipGroup = true

function CrossArenaBattle:getPreDataForEnd(roleOut)
	return {}
end

return CrossArenaBattle
