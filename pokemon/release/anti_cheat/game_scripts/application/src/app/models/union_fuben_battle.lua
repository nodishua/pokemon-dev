--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- UnionFubenBattle 公会副本
--

local GameBattleModel = require("app.models.battle")
local UnionFubenBattle = class("UnionFubenBattle", GameBattleModel)

function UnionFubenBattle:getPreDataForEnd(roleOut)
	return {}
end

function UnionFubenBattle:getData()
	local ret = GameBattleModel.getData(self)
	ret.hpMax = self.hpMax
	ret.damage = self.damage
	return ret
end

return UnionFubenBattle