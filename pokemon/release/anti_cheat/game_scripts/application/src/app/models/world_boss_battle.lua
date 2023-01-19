--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- WorldBossBattle 世界 BOSS 战斗
--

local GameBattleModel = require("app.models.battle")
local WorldBossBattle = class("WorldBossBattle", GameBattleModel)


WorldBossBattle.DefaultGateID = game.GATE_TYPE.worldBoss

function WorldBossBattle:getPreDataForEnd(roleOut)
	return {}
end

function WorldBossBattle:getData()
	local ret = GameBattleModel.getData(self)
	ret.boss_damage_max = gGameModel.daily_record:read("boss_damage_max")
	return ret
end

function WorldBossBattle:getLimitDamage()
	local ret = 0
	for k,v in pairs(self.card_attrs) do
		ret = ret + v.fighting_point
	end

	return ret * gCommonConfigCsv.worldBossMaxDamageMultiple
end

return WorldBossBattle