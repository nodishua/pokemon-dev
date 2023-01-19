-- 重写
require "battle.models.scene"
require "app.views.city.test.test_ch_protocol"

local historyBattleInfo = __TestDefine.historyBattleInfo
local easySwitch = true -- 简单开关
local listenerMap = {
	["battlePlay.Gate"] = {
		newWaveGoon = easySwitch,
		onBattleEndSupply = easySwitch,
		onWaveEndSupply = easySwitch,
		addCardRole = easySwitch,
		onNewRound = easySwitch,
		getObjectBaseSpeedRankSortKey = easySwitch,
	},
	-- SceneModel = {
	-- 	newWave = easySwitch,
	-- },
	ObjectModel = {
		beAttack = easySwitch,
		processRealDeath = easySwitch,
		toAttack = easySwitch,
		setDead = easySwitch,
	-- 	-- setHP = easySwitch,
	},
	BuffModel = {
		init = easySwitch,
		over = easySwitch,
		doEffect = easySwitch,
	},
	["battleSkill.SkillModel"] = {
		spellTo = easySwitch,
	},
	_Globals = {
		addBuffToHero = easySwitch,
	},
	ymrand = {
		random = easySwitch,
		randomseed = easySwitch,
	}
}

globals.__TestProtocol = {}

__TestProtocol["battlePlay.Gate/newWaveGoon"] = function(self,state,raw,...)
	local args = {...}
	if state == __TestDefine.CallState.enter then
		if raw.curWave == 1 then
			__TestDefine.historyBattleInfo = {}
			historyBattleInfo = __TestDefine.historyBattleInfo
		end
		historyBattleInfo[raw.curWave] = {}
		for i=1,12 do
			local obj = raw.scene:getObjectBySeatExcludeDead(i)
			if obj then
				historyBattleInfo[raw.curWave][i] = __TestEasy.toObject(obj)
				historyBattleInfo[raw.curWave][i].totalDamage = obj.totalDamage
				historyBattleInfo[raw.curWave][i].totalResumeHp = obj.totalResumeHp
				historyBattleInfo[raw.curWave][i].totalTakeDamage = obj.totalTakeDamage
			end
		end
	elseif state == __TestDefine.CallState.exit then
	end
end

__TestProtocol["battlePlay.Gate/onNewRound"] = function(self,state,raw,...)
	local args = {...}
	if state == __TestDefine.CallState.enter then
		__TestEasy.log('[GATE ROUND] round=%s totalRound=%s', raw.curRound,raw.totalRound)
	elseif state == __TestDefine.CallState.exit then
	end
end

__TestProtocol["battlePlay.Gate/onBattleEndSupply"] = function(self,state,raw,...)
	local args = {...}
	if state == __TestDefine.CallState.enter then
		local data,record,curValueTable = {}
		for i=1,12 do
			if historyBattleInfo[raw.curWave][i] then
				data = clone(historyBattleInfo[raw.curWave][i])
				record = battleEasy.valueTypeTable()
				for k,v in pairs(battle.DamageFrom) do
					record:add(historyBattleInfo[raw.curWave][i].totalDamage[v])
				end
				data._totalDamage = clone(record)

				record = battleEasy.valueTypeTable()
				for k,v in pairs(battle.ResumeHpFrom) do
					record:add(historyBattleInfo[raw.curWave][i].totalResumeHp[v])
				end
				record:add(data.resumeSpecialHp or 0)
				data._totalResumeHp = clone(record)
				data.totalRound = raw.curRound
				historyBattleInfo[raw.curWave][i] = data
			end
		end
	elseif state == __TestDefine.CallState.exit then
	end
end

__TestProtocol["battlePlay.Gate/onWaveEndSupply"] = function(self,state,raw,...)
	local args = {...}
	if state == __TestDefine.CallState.enter then
	elseif state == __TestDefine.CallState.exit then
	end
end

__TestProtocol["battlePlay.Gate/getObjectBaseSpeedRankSortKey"] = function(self,state,raw,...)
	local args = {...}
	if state == __TestDefine.CallState.enter then
	elseif state == __TestDefine.CallState.exit then
	end
end

__TestProtocol["battlePlay.Gate/addCardRole"] = function(self,state,raw,...)
	local args = {...}
	if state == __TestDefine.CallState.enter then
	elseif state == __TestDefine.CallState.exit then
		local addObj = args[1]
		if addObj and addObj.type == battle.ObjectType.Normal then
			local i = addObj.seat
			historyBattleInfo[raw.curWave][i] = __TestEasy.toObject(addObj)
			historyBattleInfo[raw.curWave][i].totalDamage = addObj.totalDamage
			historyBattleInfo[raw.curWave][i].totalResumeHp = addObj.totalResumeHp
			historyBattleInfo[raw.curWave][i].totalTakeDamage = addObj.totalTakeDamage
		end
	end
end

__TestProtocol["ObjectModel/processRealDeath"] = function(self,state,raw,...)
	local args = {...}
	if state == __TestDefine.CallState.enter then
		local waveFinal = historyBattleInfo[raw.scene.play.curWave]
		local deadObj = waveFinal[raw.id]
		__TestEasy.log('[OBJECT DEAD] self.id=%s attacker.id=%s', raw.seat, raw.attackMeDeadObj and raw.attackMeDeadObj.seat)
		if raw.attackMeDeadObj then
			local killer = waveFinal[raw.attackMeDeadObj.seat]
			killer.kill = killer.kill or 0
			killer.kill = killer.kill + 1
		end
	elseif state == __TestDefine.CallState.exit then
	end
end

__TestProtocol["ObjectModel/beAttack"] = function(self,state,raw,...)
	local args = {...}
	if state == __TestDefine.CallState.enter then
		local attacker = args[1]
		local damageArgs = args[4]
		self.objState = raw:isDeath()

		if attacker and damageArgs.from == battle.DamageFrom.skill then
			local waveFinal = historyBattleInfo[raw.scene.play.curWave]
			local beAttackObj = waveFinal[raw.seat]
			beAttackObj.beAttack = beAttackObj.beAttack or 0
			beAttackObj.beAttackStrike = beAttackObj.beAttackStrike or 0
			beAttackObj.beAttackBlock = beAttackObj.beAttackBlock or 0
			beAttackObj.beAttack = beAttackObj.beAttack + 1
			if damageArgs.strike then
				beAttackObj.beAttackStrike = beAttackObj.beAttackStrike + 1
			elseif damageArgs.block then
				beAttackObj.beAttackBlock = beAttackObj.beAttackBlock + 1
			end
		end
	elseif state == __TestDefine.CallState.exit then
		local attacker = raw.curAttackMeObj
		if attacker then
			local waveFinal = historyBattleInfo[raw.scene.play.curWave]
			local attackerData = waveFinal[attacker.seat]
			local damage = args[1]:get(battle.ValueType.normal)
			if attacker.type ~= battle.ObjectType.Normal then
				-- 召唤物伤害记到座位号对应上面
				waveFinal[attacker.seat].extraHerosDamage = waveFinal[attacker.seat].extraHerosDamage or 0
				waveFinal[attacker.seat].extraHerosDamage = waveFinal[attacker.seat].extraHerosDamage + damage
				return
			end
			if attackerData then
				attackerData.onceMaxDamage = attackerData.onceMaxDamage or 0
				attackerData.onceMaxDamage = math.max(damage, attackerData.onceMaxDamage)
				attackerData.totalDamage[battle.DamageFromExtra.allocate] = attackerData.totalDamage[battle.DamageFromExtra.allocate] or battleEasy.valueTypeTable()
				attackerData.totalDamage[battle.DamageFromExtra.link] = attackerData.totalDamage[battle.DamageFromExtra.link] or battleEasy.valueTypeTable()
				attackerData.totalDamage[battle.DamageFromExtra.allocate]:add((args[2].fromExtra and args[2].fromExtra[battle.DamageFromExtra.allocate]) and args[1]:get(battle.ValueType.normal) or 0)
				attackerData.totalDamage[battle.DamageFromExtra.link]:add((args[2].fromExtra and args[2].fromExtra[battle.DamageFromExtra.link]) and args[1]:get(battle.ValueType.normal) or 0)
			end
		end
		-- 死亡伤害来源
		if raw:isDeath() ~= self.objState and not raw.killDamageFrom then
			raw.killDamageFrom = args[2].from
		end
	end
end

__TestProtocol["ObjectModel/toAttack"] = function(self,state,raw,...)
	local args = {...}
	if state == __TestDefine.CallState.enter then
	elseif state == __TestDefine.CallState.exit then
	end
end

__TestProtocol["BuffModel/over"] = function(self,state,raw,...)
	local args = {...}
	if state == __TestDefine.CallState.enter then
		local info1 = debug.getinfo(3)
		local from1 = string.format("%s [Line:%s]",info1.source,info1.currentline)

		local info2 = debug.getinfo(4)
		local from2 = string.format("%s [Line:%s]",info2.source,info2.currentline)
		__TestEasy.log('[BUFF OVER] id=%s cfgId=%s holder=%s \n\toverFrom1=%s\n\toverFrom2=%s', raw.id, raw.cfgId, raw.holder.seat,from1,from2)
	elseif state == __TestDefine.CallState.exit then
	end
end

__TestProtocol["BuffModel/init"] = function(self,state,raw,...)
	local args = {...}
	if state == __TestDefine.CallState.enter then
		__TestEasy.log('[BUFF INIT] id=%s cfgId=%s buffType=%s lifeRound=%s caster=%s holder=%s', raw.id, raw.cfgId, raw.csvCfg.easyEffectFunc, raw.lifeRound, raw.caster and raw.caster.seat, raw.holder.seat)
	elseif state == __TestDefine.CallState.exit then
	end
end

__TestProtocol["BuffModel/doEffect"] = function(self,state,raw,...)
	local args = {...}
	if state == __TestDefine.CallState.enter then
		__TestEasy.log('[BUFF DOEFFECT] id=%s cfgId=%s buffType=%s isOver=%s', raw.id, raw.cfgId, args[1] or "nil", args[3] or "nil")
		-- dump(args[2] or {},string.format('[BUFF %s %s ARGS]',raw.cfgId,args[1] or "nil"),3)
		if itertools.include(__TestDefine.buffId, tostring(raw.cfgId)) then
			local holder = historyBattleInfo[raw.scene.play.curWave][raw.holder.seat]
			holder.buffTakeEffect = holder.buffTakeEffect or {}
			holder.buffTakeEffect[raw.cfgId] = holder.buffTakeEffect[raw.cfgId] or 0
			holder.buffTakeEffect[raw.cfgId] = holder.buffTakeEffect[raw.cfgId] + 1
		end
		if args[1] == 'setHpPer' then
			-- 特殊治疗
			local caster = historyBattleInfo[raw.scene.play.curWave][raw.caster.seat]
			local val = raw.holder:hpMax() * args[2] - raw.holder:hp()
			caster.resumeSpecialHp = caster.resumeSpecialHp or 0
			caster.resumeSpecialHp = math.ceil(caster.resumeSpecialHp + val)
			-- raw.holder.totalResumeHp[104] = raw.holder.totalResumeHp[104] or battleEasy.valueTypeTable()
			-- raw.holder.totalResumeHp[104].add(val)
		end
	elseif state == __TestDefine.CallState.exit then
	end
end

__TestProtocol["battleSkill.SkillModel/spellTo"] = function(self,state,raw,...)
	local args = {...}
	if state == __TestDefine.CallState.enter then
		local owner = raw.owner
		local gate = owner.scene.play
		local data = historyBattleInfo[gate.curWave][owner.seat]

		if raw.cfg.skillType2 == battle.MainSkillType.BigSkill then
			if not data.firstBigSkillRound then
				data.firstBigSkillRound = gate.totalRound
			end
		end

		local _skillType2 = raw.cfg.skillType2
		if not data.skillTime[_skillType2] then
			data.skillTime[_skillType2] = 0
		end
		data.skillTime[_skillType2] = data.skillTime[_skillType2] + 1
	elseif state == __TestDefine.CallState.exit then
	end
end

__TestProtocol["ObjectModel/setDead"] = function(self,state,raw,...)
	local args = {...}
	if state == __TestDefine.CallState.enter then
		local gate = raw.scene.play
		local killer = args[1].seat
		local data = historyBattleInfo[gate.curWave][killer]

		if not data.firstKill then
			data.firstKill = gate.totalRound
		end
	elseif state == __TestDefine.CallState.exit then
		if raw.state == battle.ObjectState.realDead then
			local gate = raw.scene.play
			local data = historyBattleInfo[gate.curWave][raw.seat]

			data.deadBigRound = gate.totalRound
		end
	end
end

__TestProtocol["ymrand/random"] = function(self,state,raw,...)
	local args = {...}
	if state == __TestDefine.CallState.enter then
	elseif state == __TestDefine.CallState.exit then
		-- __TestEasy.log("[!!!] random",raw,args[1])
	end
end

__TestProtocol["ymrand/randomseed"] = function(self,state,raw,...)
	if state == __TestDefine.CallState.exit then
		local randomseed = raw
		self.__func(randomseed) --自定义随机数
		__TestEasy.log("\n\n\t\t__battle_protocol start - seed=%s\n\n",randomseed)
	end
end

__TestProtocol["_Globals/addBuffToHero"] = function(self,state,raw,...)
	local args = {...}
	if state == __TestDefine.CallState.enter then
		__TestEasy.log('[BUFF ADDCHECK] cfgId=%s holderId=%s casterId=%s', raw or "nil", args[1] and args[1].seat or "nil", args[2] and args[2].seat or "nil" )
		-- dump(args[3] or {},string.format('[BUFF ADDCHECK %s ARGS]',raw or "nil"),1)
	elseif state == __TestDefine.CallState.exit then
	end
end


local function GetGlobalObj(key)
	if key == "_Globals" then return _G end
	local strTb = string.split(key,".")
	local parent = _G
	for i=1,#strTb do
		if i == #strTb then
			return parent[strTb[i]]
		end
		parent = parent[strTb[i]]
	end
end

local function main()
	for k,v in pairs(listenerMap) do
		local raw = GetGlobalObj(k)
		if raw then
			for func_name,switch in pairs(v) do
				if switch then
					__TestEasy.addFuncListener(func_name,raw,k .. "/" .. func_name)
				end
			end
		end
	end
end

main()

return __TestProtocol