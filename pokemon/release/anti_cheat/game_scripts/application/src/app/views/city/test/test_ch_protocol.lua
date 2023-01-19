__TestDefine.chProtocol = {
	["battlePlay.Gate/newWaveGoon"] = {
		makeEnv = function(self, result, raw, ...)
			return {
				play = raw,						-- 玩法
				curWave = raw.curWave,			-- 当前波数
				scene = raw.scene				-- 场景
			}
		end,
	},
	["BuffModel/init"] = {
		makeEnv = function(self, result, raw, ...)
			return {
				buffID = raw.cfgId,									-- buff csvId
				buffType = raw.csvCfg.easyEffectFunc,				-- buff类型
				lifeRound = raw.lifeRound,							-- buff生命周期
				casterSeat = raw.caster and raw.caster.seat or -1, 	-- caster座位号
				holderSeat = raw.holder.seat,						-- holder座位号
				-- record使用
				buff = raw,
			}
		end,
		record = {
			["buff.doEffectValue"] = "buff生效的value值"
		},
		protocol = {
			-- {
			-- 	type = "counter", -- 计数
			-- 	condition = "buffID == 11111",
			-- 	output = {"Buff初始化次数",0}
			-- }
		}
	},
	["ObjectModel/beAttack"] = {
		makeEnv = function(self, result, raw, ...)
			local args = {...}
			return {
				deader = raw.seat,									-- 死亡的单位位置
				killDamageFrom = raw.killDamageFrom or 0			-- 造成死亡伤害类型 battle.DamageFrom
			}
		end,
	},
	["battlePlay.Gate/getObjectBaseSpeedRankSortKey"] = {
		changeArgs = function(self, result, raw, ...)
			result[1] = math.random(999)
		end,
	}
}