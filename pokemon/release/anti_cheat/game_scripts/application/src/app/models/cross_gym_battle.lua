--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- CrossGymBattle 跨服道馆战斗
--

local GameBattleModel = require("app.models.battle")
local CrossGymBattle = class("CrossGymBattle", GameBattleModel)

CrossGymBattle.DefaultGateID = game.GATE_TYPE.crossGym

function CrossGymBattle:getPreDataForEnd(roleOut)
	return {}
end

return CrossGymBattle
