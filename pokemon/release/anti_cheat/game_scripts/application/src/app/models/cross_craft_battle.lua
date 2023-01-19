--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- CrossCraftBattle 跨服王者战斗, 战报回放
--

local GameBattleModel = require("app.models.battle")
local CrossCraftBattle = class("CrossCraftBattle", GameBattleModel)

CrossCraftBattle.DefaultGateID = game.GATE_TYPE.crossCraft
CrossCraftBattle.OmitEmpty = true

function CrossCraftBattle:getPreDataForEnd(roleOut)
	return {}
end

function CrossCraftBattle:getData()
	local datas = GameBattleModel.getData(self)
	datas.recordResult = self.result

	for id in ipairs(self.buffs) do
		local cfg = csv.cross.craft.buffs[id]
		local types = arraytools.hash(cfg.natureTypes)
		local percent = 1
		local const = 0
		if string.find(cfg.attrNum, "%%") then
			percent = percent + tonumber(string.sub(cfg.attrNum, 1, -2)) / 100
		else
			const = tonumber(cfg.attrNum)
		end
		local attr = game.ATTRDEF_TABLE[cfg.attrType]
		-- 每条buff对一张卡只生效一次，优先主自然属性
		for _, roleout in pairs(datas.roleOut) do
			local unit = csv.unit[roleout.roleId]
			if types[0] or types[unit.natureType] or types[unit.natureType2] then -- 0表示全部卡牌
				local value = roleout[attr]
				if value then -- 部分属性不是必定有的
					roleout[attr] = value * percent + const
				end
			end
		end
	end
	return datas
end

return CrossCraftBattle
