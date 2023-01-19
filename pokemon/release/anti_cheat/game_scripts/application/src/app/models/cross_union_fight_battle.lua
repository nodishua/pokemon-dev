--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- CrossUnionFightBattle 跨服公会战战斗, 战报回放
--

local GameBattleModel = require("app.models.battle")
local CrossUnionFightBattle = class("CrossUnionFightBattle", GameBattleModel)

CrossUnionFightBattle.DefaultGateID = game.GATE_TYPE.crossUnionFight
CrossUnionFightBattle.OmitEmpty = false

function CrossUnionFightBattle:getPreDataForEnd(roleOut)
	return {}
end

function CrossUnionFightBattle:getData()
	local ret = GameBattleModel.getData(self)
	ret.battleType = self.battle_type
	ret.battleTimes = self.battle_times
	ret.defenceBattleTimes = self.defence_battle_times
	return ret
end

return CrossUnionFightBattle
