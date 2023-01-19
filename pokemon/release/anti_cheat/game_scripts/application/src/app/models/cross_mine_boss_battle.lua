--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- CrossMineBossBattle 跨服竞技场战斗, 战报回放
--

local GameBattleModel = require("app.models.battle")
local CrossMineBossBattle = class("CrossMineBossBattle", GameBattleModel)

CrossMineBossBattle.DefaultGateID = game.GATE_TYPE.crossMineBoss

function CrossMineBossBattle:getData()
	local datas = GameBattleModel.getData(self)
	datas.bossHp = self.hp
	datas.bossHpMax = self.hpMax
	datas.actions = self.actions
	return datas
end

function CrossMineBossBattle:getPreDataForEnd(roleOut)
	return {}
end

return CrossMineBossBattle
