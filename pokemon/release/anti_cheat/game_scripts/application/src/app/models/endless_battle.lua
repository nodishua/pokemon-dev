--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- 无尽之塔战斗
--

local GameBattleModel = require("app.models.battle")
local EndlessBattle = class('EndlessBattle', GameBattleModel)

function EndlessBattle:getData()
	local ret = GameBattleModel.getData(self)
	ret.actions = self.actions
	return ret
end

function EndlessBattle:sceneConf(sceneID)
	return csv.endless_tower_scene[sceneID]
end

function EndlessBattle:getPreDataForEnd(roleOut)
	local db_gate_id = gGameModel.role:read("endless_tower_max_gate")
	return {
		isFirst = db_gate_id and self.gate_id > db_gate_id or false,
	}
end

return EndlessBattle
