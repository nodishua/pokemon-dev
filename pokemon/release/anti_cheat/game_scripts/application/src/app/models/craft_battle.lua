--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- CraftBattle 王者战斗, 战报回放
--

local GameBattleModel = require("app.models.battle")
local CraftBattle = class("CraftBattle", GameBattleModel)

CraftBattle.DefaultGateID = game.GATE_TYPE.craft
CraftBattle.OmitEmpty = true

function CraftBattle:getPreDataForEnd(roleOut)
	return {}
end

function CraftBattle.isFinal(s)
	if string.find(s,"pre") then
		return false
	elseif string.find(s,"final") then
		return true
	else
		error(string.format("Server gives wrong craft battle round data:%s",s))
	end
end

function CraftBattle:getData()
	local datas = GameBattleModel.getData(self)
	datas.isFinal = CraftBattle.isFinal(self.round)
	datas.recordResult = self.result

	for id in ipairs(self.buffs) do
		local cfg = csv.craft.buffs[id]
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

return CraftBattle
