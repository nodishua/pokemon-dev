--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- UnionFightBattle 公会副本
--

local GameBattleModel = require("app.models.battle")
local UnionFightBattle = class("UnionFightBattle", GameBattleModel)

UnionFightBattle.DefaultGateID = game.GATE_TYPE.unionFight
UnionFightBattle.OmitEmpty = false

function UnionFightBattle:getPreDataForEnd(roleOut)
	return {}
end

return UnionFightBattle