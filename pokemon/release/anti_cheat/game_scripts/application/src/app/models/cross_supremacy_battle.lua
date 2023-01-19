--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- CrossSupremacyBattle 跨服竞技场战斗, 战报回放
--

local GameBattleModel = require("app.models.battle")
local CrossSupremacyBattle = class("CrossSupremacyBattle", GameBattleModel)

CrossSupremacyBattle.DefaultGateID = game.GATE_TYPE.crossSupremacy
CrossSupremacyBattle.MultipGroup = true

function CrossSupremacyBattle:getData()
	local datas = GameBattleModel.getData(self)
	if self.stats and next(self.stats) then
		local waveReusult = {}
		for id, result in pairs(self.stats) do
			if result == "win" then
				table.insert(waveReusult, 1)
			else
				table.insert(waveReusult, 2)
			end
		end
		datas.waveReusult = waveReusult
	end
	datas.role_key = self.role_key
	datas.defence_role_key = self.defence_role_key
	return datas
end

function CrossSupremacyBattle:getPreDataForEnd(roleOut)
	return {}
end

return CrossSupremacyBattle
