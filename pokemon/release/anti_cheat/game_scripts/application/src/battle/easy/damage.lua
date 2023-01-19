local ValueType = battle.ValueType
local processState = {
	fillEnv = 1,
	calcProb = 2,
	result = 3,
}

battleEasy.IDCounter = 0


local deepcopy_args = function(args)
	local _args = table.deepcopy(args, true)
	return _args
end

-- 实际计算伤害流程,返回真实伤害,只涉及计算,不能操作model的生命周期
-- 操作符号
--[[
	功能型: out:中断计算 jump:跳过该计算(或者为空 beAttack部分不能为空) run:正常运行
	min:保底math.max  max:封顶math.min
	计算型: multiply:乘 sum1:求和(sum1 + sum1 + sum1) mutex:互斥(mutex(1,mutex,mutex,...) 存在值返回其中一个mutex 不然返回默认值)
--]]
function battleEasy.runDamageProcess(damage,attacker,target,processId,extraArgs)
	battleEasy.IDCounter = battleEasy.IDCounter + 1
	local damageCsv = csv.damage_process[processId]
	local exdamageCsv
	if extraArgs and extraArgs.exProcessId then
		exdamageCsv = csv.damage_process[extraArgs.exProcessId]
	end
	local preBehaviour = damageCsv.preBehaviour or {}
	if not attacker or not target then
		errorInWindows("attacker(%d) or target(%d) is nil",attacker and attacker.seat or -1,target and target.seat or -1)
		return 0,{}
	elseif not damageCsv then
		errorInWindows("%d to %d damage Process %d is nil",attacker.seat,target.seat,processId)
		return 0,{}
	end
	local alterValFormulars, alterSigns, alterExtraArgs = battleEasy.alterDmgRecordVals(attacker, target)
	-- 实际,有效,溢出伤害在beAttack计算
	local record = battleEasy.makeDamageEnv(damage,processId,extraArgs)
	record.args.damageId = battleEasy.IDCounter
	-- init: 更改伤害流程全局的一些数据
	record.preBehaviour = preBehaviour["init"]
	-- 提前计算
	battleEasy.fillDamageEnv(attacker, target, record, {
		damageType = record.args.damageType
	}, true)

	local continue,sign = true
	for _,processName in ipairs(battle.DamageProcess) do
		sign = alterSigns[processName] and alterSigns[processName][1].data or damageCsv[processName]

		if sign and sign ~= "jump" and (not exdamageCsv or exdamageCsv[processName] == sign) then
			if sign == "out" or (not continue) then break end
			-- 预制行为
			record.preBehaviour = nil
			if preBehaviour and preBehaviour[processName] then
				record.preBehaviour = preBehaviour[processName]
			end

			record.buffBehaviourTb = alterValFormulars[processName] or {}
			record.buffExtraArgs = alterExtraArgs[processName] and alterExtraArgs[processName][1] or {}

			if battleEasy[processName .. "Funcs"] then
				local processFunc = battleEasy[processName .. "Funcs"]
				processFunc[processState.fillEnv](record,attacker,target,sign)
				if not record.args.hasCalcDamageProb then
					processFunc[processState.calcProb](record,attacker,target,sign)
				end
				continue = processFunc[processState.result](record,attacker,target,sign)
			else
				local processFunc = battleEasy[processName .. "Process"]
				continue = processFunc(record,attacker,target,sign,true)
			end

			logf.battle.damage.process("attacker:%d, target:%d, skillId:%d, buffCfgId:%d process name:%s,damage:%s",attacker.seat,target.seat,extraArgs.skillId or -1,extraArgs.buffCfgId or -1,processName,record.valueF)
			if type(record.valueF) == "number" and record.valueF < 0 then
				record.valueF = 0
			end
			-- print("ipairs(battle.DamageProcess)",processName,record.valueF)
		end
	end

	battleEasy.calcInternalDamageFinishProcess(record)
	return record.valueF,record.args
end

function battleEasy.makeDamageEnv(damage,processId,extraArgs)
	local p = {}
	p.args = extraArgs or {}
	p.valueF = damage
	p.valueBase = damage

	p.id = processId -- 伤害分段id
	p.showTargetHeadNumber = function(self,target,damage)
		local damageTextInfo = {
			miss = self.args.skillMiss or self.args.miss,
			segId = self.args.segId
		}
		local damageNumberInfo = {
			strike = self.args.strike,
			miss = damageTextInfo.miss,
			-- skillMiss = self.args.skillMiss,
			block = self.args.block,
			natureFlag = self.args.natureFlag,	 	-- 克制关系
			nature = self.args.nature or 1,		 --克制值
			from = self.args.from,             -- 吸血 或者 反伤
			segId = self.args.segId,
			isLastSeg = self.args.isLastDamageSeg
		}
		damage = damage or (self.valueF + (self.args.extraValueF or 0))
		battleEasy.deferNotifyCantJump(target.view, "showHeadText", {args=damageTextInfo})
		if not self.args.hideHeadNumber then
			battleEasy.deferNotify(target.view, "showHeadNumber", {typ=0, num=damage, args=damageNumberInfo})
		end
	end
	-- 主伤害类型只能存在一项
	-- fromExtra 子伤害项是可以不同类型同时存在
	p.damageFromExtraExit = function(self,fromExtra)
        self.args.fromExtra = self.args.fromExtra or {}
		if not fromExtra then return next(self.args.fromExtra) end
		if self.args.fromExtra[fromExtra] == nil then
			self.args.fromExtra[fromExtra] = false
		end
		return self.args.fromExtra[fromExtra]
	end
	p.fillEnv = function(self,env)
		self.__index = env
		return self
	end
	p.resetEnv = function(self)
		self.__index = nil
		return self
	end

	return setmetatable(p, p)
end

function battleEasy.fillDamageEnv(attacker, target, protected, attr, applyAttr)
	protected:resetEnv()

	local env = {}
	if attr then
		env = battleCsv.makeDamageProcessEnv(attacker,target,protected,attr)
	end

	if protected.preBehaviour then
		-- 计算结果
		battleCsv.doFormula(protected.preBehaviour, env)
	end

	if protected.buffBehaviourTb and next(protected.buffBehaviourTb) then
		for _, behaviour in ipairs(protected.buffBehaviourTb) do
			battleCsv.doFormula(behaviour.data,env)
		end
	end

	if applyAttr and attr then
		for key, value in pairs(attr) do
			protected[key] = env[key] or value
		end
	end

	return protected:fillEnv(env)
end


local moreSignFormula = function(key,sign,valueF,rate,subKey)
	if string.match(valueF,key) then
		return string.gsub(valueF,key,string.format("%s,%s",rate,key))
	end
	return string.format(valueF,string.gsub(sign,subKey.."%d+%(%w+",function(s)
		return string.format("%s,%s,%s",string.gsub(s,key,subKey),rate,key)
	end))
end

-- damage * rate
-- damage * (rate and rate or mutex)
-- damage * (rate + sum)
local signPattern = {
	["multiply"] = function(key,sign,valueF,rate)
		rate = (rate ~= "nil") and rate or 1
		return string.format("%s*%s",valueF,rate)
	end,
	["mutex%d+"] = function(key,sign,valueF,rate)
		return moreSignFormula(key,sign,valueF,rate,"mutex")
	end,
	["sum%d+"] = function(key,sign,valueF,rate)
		return moreSignFormula(key,sign,valueF,rate,"sum")
	end
}
function battleEasy.updDamageFormula(sign,record,rate)
	local signs = string.split(sign,'|')
    rate = rate or "nil"
	if table.length(signs) > 1 then
		for k,v in ipairs(signs) do
			local isLast = table.length(signs) == k
			battleEasy.updDamageFormula(v,record,isLast and rate or "%s")
		end
		return
	end

    if tonumber(sign) then
		record.valueF = string.format(record.valueF,sign)
        return
	end

	local key
	for pattern,formulaFunc in pairs(signPattern) do
		key = string.match(sign,pattern)
		if key then
			record.valueF = formulaFunc(key,sign,record.valueF,rate)
			break
		end
	end
	--record.valueF = string.format(_formula,record.valueF,rate)
	-- print(sign,"export",record.valueF)
end

-- function battleEasy.skillMissProcess(record,attacker,target,sign)
-- 	if record.args.miss then
-- 		record:showTargetHeadNumber(target)
-- 		record.valueF = 0
-- 		return false
-- 	end
-- 	return true
-- end

battleEasy.damageHitFuncs = {
	[processState.fillEnv] = function(record,attacker,target,sign)
		battleEasy.fillDamageEnv(attacker,target,record,{
			damageHit = attacker:damageHit(),
			damageDodge = target:damageDodge(),
		})
	end,
	[processState.calcProb] = function(record,attacker,target,sign)
		local delta = (record:damageHit() - record:damageDodge())
		local prob = ymrand.random()
		if delta < prob then
			record.args.miss = true
		end
	end,
	[processState.result] = function(record,attacker,target,sign)
		if record.args.miss then
			record.valueF = 0
			return false
		else
			return true
		end
	end,
}

battleEasy.natureFuncs = {
	[processState.fillEnv] = function(record,attacker,target,sign)
		battleEasy.fillDamageEnv(attacker,target,record,{
			natureRestraint = attacker:natureRestraint(),
			natureResistance = target:natureResistance(),
		})
	end,
	[processState.calcProb] = function(record,attacker,target,sign)
		local nature,natureFlag = 1
		if record.args.skillId then
			local curSkill = attacker.skills[record.args.skillId] or attacker.passiveSkills[record.args.skillId]
			local natureType = curSkill and curSkill:getSkillNatureType()
			natureFlag, nature = skillHelper.natureRestraintType(natureType, target, record:natureRestraint(), record:natureResistance())
		elseif record.args.natureType then
			local val = 1
			for i=1,2 do
				if target:getNatureType(i) then
					local natureName = game.NATURE_TABLE[target:getNatureType(i)]
					val = skillHelper.getNatureMatrix(record.args.natureType, natureName,
						record:natureRestraint(), record:natureResistance()) * val
				end
			end
			local objNatureName = game.NATURE_TABLE[record.args.natureType]
			natureFlag, nature = skillHelper.getNatureFlag(val)
		end
		-- print("battleEasy.natureProcess ",nature,natureFlag)
		record.args.nature = nature
		record.args.natureFlag = natureFlag
	end,
	[processState.result] = function(record,attacker,target,sign)
		battleEasy.updDamageFormula(sign,record,record.args.nature)
		return true
	end,
}

-- 属性克制
-- function battleEasy.natureProcess(record,attacker,target,sign,isFillEnv)
-- 	if isFillEnv then
-- 		battleEasy.fillDamageEnv(attacker,target,record,{
-- 			natureRestraint = attacker:natureRestraint(),
-- 			natureResistance = target:natureResistance(),
-- 		})
-- 		return battleEasy.natureProcess(record,attacker,target,sign)
-- 	end
-- 	local nature,natureFlag = 1
-- 	if record.args.skillId then
-- 		local curSkill = attacker.skills[record.args.skillId] or attacker.passiveSkills[record.args.skillId]
-- 		local natureType = curSkill and curSkill:getSkillNatureType()
-- 		natureFlag, nature = skillHelper.natureRestraintType(natureType, target, record:natureRestraint(), record:natureResistance())
-- 	elseif record.args.natureType then
-- 		local val = 1
-- 		for i=1,2 do
-- 			if target:getNatureType(i) then
-- 				local natureName = game.NATURE_TABLE[target:getNatureType(i)]
-- 				val = skillHelper.getNatureMatrix(record.args.natureType, natureName,
-- 					record:natureRestraint(), record:natureResistance()) * val
-- 			end
-- 		end
-- 		local objNatureName = game.NATURE_TABLE[record.args.natureType]
-- 		natureFlag, nature = skillHelper.getNatureFlag(val)
-- 	end
-- 	battleEasy.updDamageFormula(sign,record,nature)
-- 	-- print("battleEasy.natureProcess ",nature,natureFlag)
-- 	record.args.nature = nature
-- 	record.args.natureFlag = natureFlag
-- 	return true
-- end
-- 伤害加成
function battleEasy.damageAddProcess(record,attacker,target,sign,isFillEnv)
	if isFillEnv then
		battleEasy.fillDamageEnv(attacker,target,record,{
			damageAdd = attacker:damageAdd(),
			damageSub = target:damageSub(),
			ignoreDamageSub = attacker:ignoreDamageSub(),
		})
		return battleEasy.damageAddProcess(record,attacker,target,sign)
	end
	local dmgSub = record:damageAdd() - (math.max((record:damageSub() - record:ignoreDamageSub()),0))
	battleEasy.updDamageFormula(sign,record,dmgSub)
	return true
end

-- 伤害加深/减免
function battleEasy.damageDeepenProcess(record,attacker,target,sign,isFillEnv)
	if isFillEnv then
		battleEasy.fillDamageEnv(attacker,target,record,{
			damageDeepen = target:damageDeepen(),
			damageReduce = attacker:damageReduce(),
		})
		return battleEasy.damageDeepenProcess(record,attacker,target,sign)
	end
	local damageDeepen = record:damageDeepen() - record:damageReduce()
	battleEasy.updDamageFormula(sign,record,damageDeepen)
	return true
end

-- 物/特伤害加成
function battleEasy.dmgDeltaProcess(record,attacker,target,sign,isFillEnv)
	if isFillEnv then
		battleEasy.fillDamageEnv(attacker,target,record,{
			physicalDamageAdd = attacker:physicalDamageAdd(),
			specialDamageAdd = attacker:specialDamageAdd(),
			trueDamageAdd = attacker:trueDamageAdd(),
			physicalDamageSub = target:physicalDamageSub(),
			specialDamageSub = target:specialDamageSub(),
			trueDamageSub = target:trueDamageSub(),
		})
		return battleEasy.dmgDeltaProcess(record,attacker,target,sign)
	end
	if not record.damageType then return true end
	local dmgDelta
	if record.damageType == battle.SkillDamageType.Physical then
		dmgDelta = record:physicalDamageAdd() - record:physicalDamageSub()
	elseif record.damageType == battle.SkillDamageType.True then
		dmgDelta = record:trueDamageAdd() - record:trueDamageSub()
	else
		dmgDelta = record:specialDamageAdd() - record:specialDamageSub()
	end
	battleEasy.updDamageFormula(sign,record,dmgDelta)
	return true
end

-- 自然属性伤害加成
function battleEasy.natureDeltaProcess(record,attacker,target,sign,isFillEnv)
	if not record.args.natureType then return true end
	local objNatureName = game.NATURE_TABLE[record.args.natureType]
	local natureDeltaAdd = objNatureName..'DamageAdd'
	local natureDeltaSub = objNatureName..'DamageSub'
	if isFillEnv then
		battleEasy.fillDamageEnv(attacker,target,record,{
			natureDeltaAdd = attacker[natureDeltaAdd](attacker),
			natureDeltaSub = target[natureDeltaSub](target),
		})
		return battleEasy.natureDeltaProcess(record,attacker,target,sign)
	end
	local natureDelta = record.natureDeltaAdd - record.natureDeltaSub
	battleEasy.updDamageFormula(sign,record,natureDelta)
	return true
end

-- pvp伤害加成/减免
function battleEasy.gateDeltaProcess(record,attacker,target,sign,isFillEnv)
	if isFillEnv then
		battleEasy.fillDamageEnv(attacker,target,record,{
			pvpDamageAdd = attacker:pvpDamageAdd(),
			pvpDamageSub = target:pvpDamageSub(),
		})
		return battleEasy.gateDeltaProcess(record,attacker,target,sign)
	end
	local gateDelta = record:pvpDamageAdd() - record:pvpDamageSub()
	battleEasy.updDamageFormula(sign,record,gateDelta)
	return true
end

-- 减伤
function battleEasy.reduceProcess(record,attacker,target,sign,isFillEnv)
	if record.damageType == battle.SkillDamageType.True then
		return true
	end
	if isFillEnv then
		battleEasy.fillDamageEnv(attacker,target,record,{
			defence = target:defence(),
			specialDefence = target:specialDefence(),
			defenceIgnore = attacker:defenceIgnore(),
			specialDefenceIgnore = attacker:specialDefenceIgnore(),
			damage = attacker:damage(),
			specialDamage = attacker:specialDamage()
		})
		return battleEasy.reduceProcess(record,attacker,target,sign)
	end
	local defence
	if record.damageType == battle.SkillDamageType.Physical then
		defence = record:defence()
	else
		defence = record:specialDefence()
	end

	if target.calDmgKeepDefenceBuff then
		defence = target.calDmgKeepDefenceBuff(record:defence(),record:specialDefence())
	end

	local defenceDelta
	if record.damageType == battle.SkillDamageType.Physical then
		defenceDelta = defence * math.max((1 - record:defenceIgnore()),ConstSaltNumbers.dot05)
	else
		defenceDelta = defence * math.max((1 - record:specialDefenceIgnore()),ConstSaltNumbers.dot05)
	end
	defenceDelta = math.max(defenceDelta, 0) -- >= 0

	local damageAttr
	if record.damageType == battle.SkillDamageType.Physical then
		damageAttr = record:damage()
	else
		damageAttr = record:specialDamage()
	end

	local reduce = (1 - defenceDelta/math.max(damageAttr,0.0001))
	reduce = math.max(reduce, ConstSaltNumbers.dot1) -- 1 >= reduce >= 0.1
	battleEasy.updDamageFormula(sign,record,reduce)
	return true
end
-- 暴击
-- 数据1= attacker:strike()-max((target:strikeResistance() - attacker:ignoreStrikeResistance()),0)
-- 数据2 = target:block() - attacker:breakBlock()
-- 数据3 = 0.04
-- 重新赋值
-- 数据11 =数据1/（数据1+数据2）*系数1-数据3/2（范围0~1）
-- 数据22 =数据2/（数据1+数据2）*系数2-数据3/2（范围0~1）
-- 数据33 =数据3
-- 系数1，2，3由策划配置
-- random一下取数据1，数据2，数据3当中的某个，然后再对其伤害做对应的处理
battleEasy.strikeBlockFuncs = {
	[processState.fillEnv] = function(record,attacker,target,sign)
		battleEasy.fillDamageEnv(attacker,target,record,{
			-- 暴击
			strikeResistance = target:strikeResistance(),
			ignoreStrikeResistance = attacker:ignoreStrikeResistance(),
			strike = attacker:strike(),
			strikeDamage = attacker:strikeDamage(),
			strikeDamageSub = target:strikeDamageSub(),
			strikePowerRate = ConstSaltNumbers.one15, -- 系数1
			-- 抵御
			block = target:block(),
			breakBlock = attacker:breakBlock(),
			blockPower = target:blockPower(),
			blockPowerRate = ConstSaltNumbers.one, -- 系数2
			-- 数据三
			rate = ConstSaltNumbers.dot96,
		})
	end,
	[processState.calcProb] = function(record,attacker,target,sign)
		local strikeRate = math.max(record:strike() - math.max((record:strikeResistance() - record:ignoreStrikeResistance()),0),0)
		local blockRate = math.max(record:block() - record:breakBlock(),0)

		-- strikePowerRate > rate/2
		-- blockPowerRate > rate/2


		-- local _strikeRate = math.max((strikeRate/(strikeRate + blockRate + rate)* record.strikePowerRate),0)
		-- local _blockRate = math.max((blockRate/(strikeRate + blockRate + rate)* record.blockPowerRate),0)
		-- local sum = ymrand.random(ConstSaltNumbers.one,math.ceil((record.rate + _strikeRate + _blockRate) * magn))

		local _blockRate = blockRate
		local _strikeRate = strikeRate
		if _blockRate + _strikeRate > record.rate then
			_blockRate = blockRate/(strikeRate + blockRate) * record.rate
			_strikeRate = strikeRate/(strikeRate + blockRate) * record.rate
		end

		_blockRate = _blockRate * record.blockPowerRate
		_strikeRate = _strikeRate * record.strikePowerRate

		local indicator = ymrand.random() * math.max(1, _strikeRate + _blockRate)
		if indicator < _strikeRate then
			record.args.strike = true
		elseif indicator < (_strikeRate + _blockRate) then
			record.args.block = true
		end
		-- local rate = 1 - _blockRate - _strikeRate
		-- local sum = ymrand.random(ConstSaltNumbers.one,math.ceil((rate + _strikeRate + _blockRate) * magn))
		-- local delta = ConstSaltNumbers.one
		-- for k,v in ipairs({_strikeRate,_blockRate,rate}) do
		-- 	sum = sum - v * magn
		-- 	if sum < 0 then
		-- 		if k == 1 then
		-- 			delta = math.max(record:strikeDamage() - record:strikeDamageSub(), ConstSaltNumbers.dot01)
		-- 			record.args.strike = true
		-- 		elseif k == 2 then
		-- 			delta = math.max(ConstSaltNumbers.one - record:blockPower(), ConstSaltNumbers.dot01)
		-- 			record.args.block = true
		-- 		end
		-- 		break
		-- 	end
		-- end

		-- if delta < ymrand.random() then
		-- 	delta = nil
		-- else
		-- 	delta = math.max(record:strikeDamage() - record:strikeDamageSub(), 0.01)
		-- 	record.args.strike = true
		-- end
	end,
	[processState.result] = function(record,attacker,target,sign)
		local delta = ConstSaltNumbers.one
		if record.args.strike then
			delta = math.max(record:strikeDamage() - record:strikeDamageSub(), ConstSaltNumbers.dot01)
		elseif record.args.block then
			delta = math.max(ConstSaltNumbers.one - record:blockPower(), ConstSaltNumbers.dot01)
		end
		battleEasy.updDamageFormula(sign,record,delta)
		return true
	end,
}
-- 格挡
-- function battleEasy.blockProcess(record,attacker,target,sign,isFillEnv)
-- 	if isFillEnv then
-- 		battleEasy.fillDamageEnv(attacker,target,record,{
-- 			block = target:block(),
-- 			breakBlock = attacker:breakBlock(),
-- 			blockPower = target:blockPower(),
-- 		})
-- 		return battleEasy.blockProcess(record,attacker,target,sign)
-- 	end
-- 	local delta = record:block() - record:breakBlock()
-- 	if delta < ymrand.random() then
-- 		delta = nil
-- 	else
-- 		delta = math.max(1 - record:blockPower(), 0.01)
-- 		record.args.block = true
-- 	end
-- 	battleEasy.updDamageFormula(sign,record,delta)
-- 	return true
-- end
-- 额外加成
function battleEasy.extraAddProcess(record,attacker,target,sign)
	local extraAdd = 0
	battleEasy.updDamageFormula(sign,record,extraAdd)
	return true
end

function battleEasy.fatalProcess(record,attacker,target,sign)
	if attacker.fatalBuff and (target:hp() / target:hpMax()) > attacker.fatalBuff.limit then
		battleEasy.updDamageFormula(sign,record,attacker.fatalBuff.val)
	end
	return true
end

function battleEasy.beheadProcess(record,attacker,target,sign)
	if attacker.beheadBuff and (target:hp() / target:hpMax()) < attacker.beheadBuff.limit then
		battleEasy.updDamageFormula(sign,record,attacker.beheadBuff.val)
	end
	return true
end

function battleEasy.damageByHpRateProcess(record,attacker,target,sign)
	if attacker.damageByHpRateBuff then
		battleEasy.updDamageFormula(sign,record,(attacker.damageByHpRateBuff:rateFunc(attacker,1) + attacker.damageByHpRateBuff:rateFunc(target,2)))
	end
	return true
end

function battleEasy.finalSkillAddProcess(record,attacker,target,sign)
	battleEasy.updDamageFormula(sign,record,attacker:finalSkillAddRate())
	return true
end

function battleEasy.ultimateAddProcess(record,attacker,target,sign)
	if not record.args.skillType2 then return true end
	if record.args.skillType2 == battle.MainSkillType.BigSkill or record.args.skillType == battle.SkillType.PassiveCombine then
		local ultimateAdd = 1 + attacker:ultimateAdd() - target:ultimateSub()
		ultimateAdd = math.max(ultimateAdd, ConstSaltNumbers.dot05)
		battleEasy.updDamageFormula(sign,record,ultimateAdd)
	end
	return true
end

function battleEasy.skillPowerProcess(record,attacker,target,sign)
	if record.args.skillPower then
		local skillPower = record.args.skillPower / ConstSaltNumbers.wan
		skillPower = math.max(skillPower, ConstSaltNumbers.dot05)
		battleEasy.updDamageFormula(sign,record,skillPower)
	end
	return true
end

function battleEasy.buffAddProcess(record,attacker,target,sign,isFillEnv)
	if isFillEnv then
		battleEasy.fillDamageEnv(attacker,target,record,{
			damageRateAdd = attacker:damageRateAdd(),
		})
		return battleEasy.buffAddProcess(record,attacker,target,sign)
	end
	battleEasy.updDamageFormula(sign,record,(1 + record:damageRateAdd()))
	return true
end

function battleEasy.randFixProcess(record,attacker,target,sign)
	local randFix= target.scene.closeRandFix and 1 or ymrand.random(9000, ConstSaltNumbers.wan) / ConstSaltNumbers.wan
	battleEasy.updDamageFormula(sign,record,randFix)
	return true
end

function battleEasy.limitProcess(record,attacker,target,sign)
	local limitDamage = battleEasy.runDamageProcess(record.valueBase,attacker,target,sign,record.args)
	record.valueF = string.format("max(%s,%s)",record.valueF,limitDamage)
	return true
end

function battleEasy.calcInternalDamageFinishProcess(record,attacker,target,sign,isFillEnv)
	local value = tonumber(record.valueF)
	-- printDebug("[DamageProcess] <%s> Formula:  %s",record.id,record.valueF)

	if not value then
		value = battleCsv.doFormula(record.valueF, {
			min = math.min,max = math.max,
			sum = function(default,...)
				local args = {...}
				local sum = default
				for _,v in ipairs(args) do
					sum = sum + ((v and (type(v) == "number")) and v or 0)
				end
				return sum
			end,
			mutex = function(default,...)
				local args = {...}
				for _,v in ipairs(args) do
					if v and (type(v) == "number") then return v end
				end
				return default
			end,
		})
	end
	record.valueF = math.floor(value)
	if isFillEnv then
		battleEasy.fillDamageEnv(attacker,target,record,{
			calFinalDamage = value,
		})
		--print("calcInternalDamageFinishProcess",value,record.calFinalDamage)
		record.valueF = record.calFinalDamage
		return true
	end
	return true
end

-- 原object beAttack
-- 无视战斗回合伤害
function battleEasy.ignoreRoundDamageProcess(record,attacker,target,sign)
	if target.ignoreDamageInBattleRound then
		record.valueF = 0
		record:showTargetHeadNumber(target)
		return false
	end
	return true
end
-- 隐身
-- function battleEasy.stealthProcess(record,attacker,target,sign)
-- 	if target:checkOverlaySpecBuffExit("stealth") then
-- 		-- record:showTargetHeadNumber(target)
-- 		-- record.valueF = 0
-- 		-- return false
-- 	end
-- 	return true
-- end
-- 离场
function battleEasy.leaveProcess(record,attacker,target,sign)
	if target:checkOverlaySpecBuffExit("leave") then
		record:showTargetHeadNumber(target)
		-- 离场精灵自身buff产生的伤害不能忽视, 并且处于离场状态 onBuffEffectedHolder
		if record.args.from ~= battle.DamageFrom.buff then
			record.valueF = 0
		end
		return false
	end
	return true
end
-- 免疫伤害
function battleEasy.immuneDamageProcess(record,attacker,target,sign)
	for _, data in target:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.immuneDamage) do
		for power, time in data:powerTimeOrderPairs() do
			local result, showHeadNum = data.funcMap[power](data, record, attacker)
			if result then
				record.valueF = 0
				local buff = target:getBuff(data.cfgId)
				target:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffTrigger, {
					buffId = buff.id,
					easyEffectFunc = buff.csvCfg.easyEffectFunc,
					triggerTime = data.damageMap.count,
				})
				if data.allTime == 0 then
					buff:over()
				end
				record.args.immune = result
				if showHeadNum then
					record:showTargetHeadNumber(target)
				end
				return false
			end
		end
	end
	return true
end
-- 免疫所有伤害
function battleEasy.immuneAllDamageProcess(record,attacker,target,sign)
	if target.beInImmuneAllDamageState and target.beInImmuneAllDamageState > 0 then
		record.valueF = 0
		record.args.immune = "all"
		record:showTargetHeadNumber(target)
		return false
	end
	return true
end
-- 免疫物理
function battleEasy.immunePhysicalDamageProcess(record,attacker,target,sign)
	if record.damageType == battle.SkillDamageType.Physical and target.beInImmunePhysicalDamageState
		and target.beInImmunePhysicalDamageState > 0 then
		record.valueF = 0
		record.args.immune = "physical"
		record:showTargetHeadNumber(target)
		return false
	end
	return true
end
-- 免疫特殊伤害
function battleEasy.immuneSpecialDamageProcess(record,attacker,target,sign)
	if record.damageType == battle.SkillDamageType.Special and target.beInImmuneSpecialDamageState
		and target.beInImmuneSpecialDamageState > 0 then
		record.valueF = 0
		record.args.immune = "special"
		record:showTargetHeadNumber(target)
		return false
	end
	return true
end
-- 免疫致死伤害
function battleEasy.keepHpUnChangedProcess(record,attacker,target,sign)
	if target:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.keepHp) then
        local groupShieldHp = target.scene:excuteGroupObjFunc(target.force,battle.SpecialObjectId.teamShiled,"getShieldHp") or 0
        local shieldHp = target:shieldHp()
		local allHp = target:hp() + shieldHp + groupShieldHp
		local damage = record.valueF
		-- 不能存在伤害副类型 即分摊等
		if record.args.from == battle.DamageFrom.skill and attacker.curSkill and not record:damageFromExtraExit()  then
			damage = record.args.leftDamage or damage
		end
		if damage > allHp then
			local idx
			for k,data in target:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.keepHp) do
				if ymrand.random() <= data.prob then
					idx = k
					break
				end
			end
			-- local idx = itertools.first(target:getOverlaySpecBuffList(battle.OverlaySpecBuff.keepHp),function(v)
			-- 	return ymrand.random() <= v.prob
			-- end)
			if idx then
				local buffData = target:getOverlaySpecBuffByIdx(battle.OverlaySpecBuff.keepHp,idx)
				record.valueF = 0
				buffData.triggerTime = buffData.triggerTime - 1
				target.ignoreDamageInBattleRound = true
				local buff = target:getBuff(buffData.cfgId)
				-- 表现相关
				record:showTargetHeadNumber(target)
				buff:playTriggerPointEffect()
				local triggerState = buff:getEventByKey(battle.ExRecordEvent.keepHpUnChangedTriggerState)
				target:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffTrigger, {
					buffId = buff.id,
					buffCfgId = buff.cfgId,
					easyEffectFunc = buff.csvCfg.easyEffectFunc,
					checkEffectFunc = "lockHpAndKeepHpUnChanged",
					isFirstTrigger = not triggerState,
				})
				buff:addExRecord(battle.ExRecordEvent.keepHpUnChangedTriggerState, true)
				if buffData.triggerTime <= 0 then
					buff:over()
				end
				return false
			end
		end
	end
	return true
end

function battleEasy.damageAllocateProcess(record,attacker,target,sign)
	local fromAllocate = record:damageFromExtraExit(battle.DamageFromExtra.allocate)
	for k,data in target:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.allocate, function(data)
		-- 伤害来源是rebound只复制fromExtra 判断allocatePriority为nil不继续分摊了
		return fromAllocate and (not record.args.allocatePriority or data.priority >= record.args.allocatePriority)
	end) do
		local rate = data.rate
		local buffCfgId = data.cfgId
		local buffCsv = target:getBuff(buffCfgId).csvCfg
		local targetIds = data.targetIds
		if buffCsv.specialVal and buffCsv.specialVal[3] == 1 then
			local damageId = record.args.skillDamageId or record.args.damageId
			if not data.targetIdsList[damageId] then
				data.targetIdsList[damageId] = data.getNewTargetIds()
			end
			targetIds = data.targetIdsList[damageId]
			if record.args.isLastDamageSeg then
				data.targetIdsList[damageId] = nil
			end
		end
		local targets = {}
		for _,id in ipairs(targetIds) do
			if id ~= target.id then
				local obj = target.scene:getObject(id)
				if obj and not obj:isDeath() and not battleEasy.isCompleteLeave(obj) then
					table.insert(targets,obj)
				end
			end
		end
		local allocateID = data.damageMode
		if table.length(targets) > 0 then
			local function fillAlloArgs(args)
				args.fromExtra[battle.DamageFromExtra.allocate] = true
				args.allocatePriority = data.priority
			end
			if rate == -1 then --所有人均分
				--根据配置判断是否分摊溢出伤害
				record.valueF = math.floor(record.valueF/(table.length(targets)+1))
				local damageAllocated = record.valueF
				if damageAllocated > target:hp() and buffCsv.specialVal and buffCsv.specialVal[1] > 0 then	--buffCsv.specialVal[1] 1:有效伤害 0:正常伤害
					damageAllocated = target:hp()
				end

				for _,obj in ipairs(targets) do
					local dmgArgsAllo = deepcopy_args(record.args)
					fillAlloArgs(dmgArgsAllo)
					target.scene:deferBeAttack(target.id,attacker,obj,damageAllocated,allocateID,dmgArgsAllo,
						buffCsv.specialVal and buffCsv.specialVal[2])
				end
			else --主目标固定比例 剩下目标所有人分
				--根据配置判断是否分摊溢出伤害
				local dmgAllocated = record.valueF*rate
				record.valueF = math.floor(record.valueF*(1-rate))
				if record.valueF > target:hp() and buffCsv.specialVal and buffCsv.specialVal[1] > 0 then --buffCsv.specialVal[1] 1:有效伤害 0:正常伤害
					--如果主目标伤害溢出，其余目标的有效伤害需要根据主目标有效伤害与正常伤害的比率来计算
					dmgAllocated = dmgAllocated * (target:hp() / record.valueF)
				end
				dmgAllocated = math.floor(dmgAllocated/table.length(targets))

				for _,obj in ipairs(targets) do
					local dmgArgsAllo = deepcopy_args(record.args)
					fillAlloArgs(dmgArgsAllo)
					target.scene:deferBeAttack(target.id,attacker,obj,dmgAllocated,allocateID,dmgArgsAllo,
						buffCsv.specialVal and buffCsv.specialVal[2])
				end
			end
		end
	end
	return true
end

function battleEasy.damageLinkProcess(record,attacker,target,sign)
	if target.damageLinkBuff and not record:damageFromExtraExit(battle.DamageFromExtra.link) then
		local globalBuffMgr = target.scene.buffGlobalManager
		for _,cfgId in ipairs(target.damageLinkBuff) do
			local objIDs = globalBuffMgr:getDamageLinkObjs(target.id,cfgId)
			for k,v in ipairs(objIDs) do
				local obj = target.scene:getObject(v)
				if obj and not obj:isDeath() and not obj:isLogicStateExit(battle.ObjectLogicState.cantBeAttack,{fromObj = attacker}) then
					local damageRatio = globalBuffMgr:getDamageLinkValue(v,cfgId)
					local targetBuff = target:getBuff(cfgId)
					local buffCsv = targetBuff.csvCfg
					--根据配置判断是否链接溢出伤害
					local newDamage = record.valueF
					--先判断伤害是否溢出
					if newDamage > target:hp() and buffCsv.specialVal and buffCsv.specialVal[1] > 0 then --buffCsv.specialVal[1] 1:有效伤害 0:正常伤害
						newDamage = math.max(target:hp(),0)
					end
					--再计算伤害率
					newDamage = math.floor(newDamage*damageRatio)
					local newDamageArgs = deepcopy_args(record.args)
					newDamageArgs.fromExtra[battle.DamageFromExtra.link] = true
					local newAttacker = attacker
					if buffCsv.specialVal and buffCsv.specialVal[2] == 1 then  --buffCsv.specialVal[2] 1.bufflink 的buffcaster 2.原伤害来源
						if not targetBuff.caster or targetBuff.caster:isDeath() then
							-- 没有caster或者caster死了不造成伤害
							newAttacker = nil
						else
							newAttacker = targetBuff.caster
						end
					end
					if newAttacker then
						target.scene:deferBeAttack(target.id,newAttacker,obj,newDamage,record.id,newDamageArgs,
							buffCsv.specialVal and buffCsv.specialVal[2])
					end
				end
			end
		end
	end
	return true
end

function battleEasy.protectionProcess(record,attacker,target,sign)
	local fromSkill = record.args.from == battle.DamageFrom.skill
	local isBeginSeg = record.args.isBeginDamageSeg

	local filter = function(protectData)
		if not protectData or not protectData.protectObj then return true end
		local protectMeObj = protectData.protectObj

		if record:damageFromExtraExit(battle.DamageFromExtra.protect) then return true end

		if protectData.type == 1 then
			if record.args.from == battle.DamageFrom.rebound then return true end
			local event = protectMeObj:getEventByKey(battle.ExRecordEvent.protectTarget)
			if event and event.protectingObj then
				return event.protectingObj.id ~= target.id
			end
		end

		if protectMeObj:isAlreadyDead() then return true end
		if protectMeObj:isNotReSelect(true) then return true end
		if protectMeObj:isSelfControled() then return true end
		return not protectData:checkCondition()
	end

	local triggerProtected, allDamage
	for _, protectData in target:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.protection, filter) do
		local protectObj = protectData.protectObj
		-- type区分
		triggerProtected = true

		if isBeginSeg and fromSkill then
			if protectData.type == 1 then	-- 根据伤害与血量比例判定类型
				-- TODO:判定的伤害类型上过于粗略(buff伤害)
				allDamage = record.args.leftDamage or record.valueF
				if allDamage < target:hp() * protectData.extraArgs[1] then
					triggerProtected = false
				end
			end

			protectData.triggerProtected = triggerProtected
			if triggerProtected then
				target:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffTrigger, {
					buffId = protectData.id,
					easyEffectFunc = protectData.buff.csvCfg.easyEffectFunc,
					obj = protectObj,
				})
				-- 保护者添加标记，只保护这个目标
				protectObj:addExRecord(battle.ExRecordEvent.protectTarget, {protectingObj = target})
				-- 用于表现的标记，只有技能去触发
				target:addExRecord(battle.ExRecordEvent.protectTarget, {obj = protectObj, showProcess = protectData.type ~= 1})
			end
		end

		-- 来自技能的伤害第一次没有触发后续也不会触发
		if fromSkill then
			triggerProtected = protectData.triggerProtected
		end

		if triggerProtected then
			local newDamage = math.floor(record.valueF * protectData.ratio)
			local newDamageArgs = deepcopy_args(record.args)
			newDamageArgs.fromExtra[battle.DamageFromExtra.protect] = true

			if fromSkill and protectData.type == 1 then -- 需要完整走一遍保护者的受击流程
				attacker.curSkill:onProtectTarget(protectObj, newDamage, allDamage, newDamageArgs, protectData.extraArgs[2])
			else
				protectObj:beAttack(attacker, newDamage,protectData.extraArgs and protectData.extraArgs[2] or record.id, newDamageArgs)
			end

			record.valueF = math.floor(record.valueF*(1 - protectData.ratio))
			record.args.extraShowValueF = newDamage -- 打到保护者身上的伤害只作为显示伤害
			record.args.hideHeadNumber = protectData.type == 1
			break
		end
	end

	return true
end
-- 全体护盾
function battleEasy.groupShieldProcess(record,attacker,target,sign)
	local costShield = target.scene:excuteGroupObjFunc(target.force,battle.SpecialObjectId.teamShiled,"beAttack",attacker,target,record)
	if not costShield then return true end
	record.valueF = record.valueF - costShield
	if record.valueF == 0 then return false end
	return true
end
-- 延迟伤害
function battleEasy.delayDamageProcess(record,attacker,target,sign)
	if record.id == 201 then
		-- if target:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.delayDamage) then
		-- 	local totalDamage = 0
		-- 	for k,data in target:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.delayDamage) do
		-- 		for i=table.length(data.damageTb),1,-1 do
		-- 			totalDamage = totalDamage + data.damageTb[i].val
		-- 			data.damageTb[i].time = data.damageTb[i].time - 1
		-- 			if data.damageTb[i].time<= 0 then
		-- 				table.remove(data.damageTb, i)
		-- 			end
		-- 		end
		-- 	end
		-- 	record.valueF = record.valueF + totalDamage
		-- end
	else
		if target:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.delayDamage) then
			local tempDamage = record.valueF
			for k,data in target:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.delayDamage) do
				local delayVal = math.min(record.valueF * data.delayPer, tempDamage)
				local perVal = math.floor(delayVal/data.time)
				local oneRecord = {}
				for _=1, data.time do
					table.insert(oneRecord, perVal)
				end
				table.insert(data.damageTb, oneRecord)
				tempDamage = tempDamage - perVal*data.time
				if tempDamage <= 0 then break end
			end
			record.valueF = math.max(tempDamage, 0)
		end
	end
	return true
end

function battleEasy.shieldProcess(record,attacker,target,sign,isFillEnv)
	local calcShieldList = record.buffExtraArgs.data and record.buffExtraArgs.data.calcList
	if isFillEnv then
		battleEasy.fillDamageEnv(attacker,target,record,{
			shieldHp = target:shieldHp(calcShieldList),
			totalShieldHp = target:shieldHp()
		})
		return battleEasy.shieldProcess(record,attacker,target,sign)
	end
	if record.shieldHp and (record.shieldHp > 0) then
		local off = record.shieldHp - record.valueF
		--刷新护盾buff
		-- local tempDamage = record.valueF
		target:addShieldHp(-record.valueF, calcShieldList)
		-- local delBuffList = {}
		-- for _,data in target:ipairsOverlaySpecBuff("shield") do
		-- 	tempDamage = tempDamage - data.shieldHp
		-- 	if tempDamage > 0 then
		-- 		data.shieldHp = 0
		-- 	end
		-- end
		-- target:shieldHp(-tempDamage)

		-- 特殊护盾没了还存留普通护盾的情况,不走破盾流程
		local breakHasNormalShield = off <= 0 and record.totalShieldHp > record.shieldHp
		if off > 0 or breakHasNormalShield then
			-- 这里要显示个外的数字表现吗？？
			record:showTargetHeadNumber(target)
			target:refreshShield()
			local value = breakHasNormalShield and record.shieldHp or record.valueF
			target.scene.play:recordScoreStats(attacker, math.floor(value/2))
			record.args.extraValueF = value
			if breakHasNormalShield then
				-- 只是特殊护盾没了,要继续接下来的流程
				record.valueF = -off
				return true
			end
			record.valueF = 0	-- 护盾没有打破时不触发下面那些逻辑
			return false
		else
			-- 护盾破了
			target.scene.play:recordScoreStats(attacker, math.floor(record.shieldHp/2))
			record.args.extraValueF = record.shieldHp
			record.valueF = -off 	-- 剩余的伤害值
			target:clearBuff(nil,
				target:getBuffQuery():group("easyEffectFunc", "shield"))
			target:refreshShield()
			target:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderShieldBreak, target)
		end
	end
    return true
end
-- 锁一滴血
function battleEasy.lockHpProcess(record,attacker,target,sign)
	if target:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.lockHp) then
		-- local skillDamage = record.valueF
		-- if record.args.from == battle.DamageFrom.skill and attacker.curSkill then
		-- 	skillDamage = attacker.curSkill:getTargetDamage(target) or skillDamage
		-- end
		local isTrigger
		local damageId = record.args.skillDamageId or record.args.damageId
		local operateList = {}

		-- TODO: 修正反伤使用, reboundFix
		record.lockHpOriginValue = record.valueF

		local function dealSkillDamage(lockData, afterDamage, compareVal)
			if record.valueF > compareVal and not lockData.damageMap[damageId] then
				lockData.damageMap[damageId] = afterDamage -- 触发锁血
			end

			if lockData.damageMap[damageId] then
				if isTrigger then
					-- 如果是最后一段 设置锁的血量 修正伤害
					record.valueF = math.min(lockData.damageMap[damageId], afterDamage)
					lockData.damageMap[damageId] = nil
					return true
				else
					record.valueF = 0
				end
			end
			return false
		end
		local filter = function(curLockBuffData)
			return not curLockBuffData:checkCondition(attacker)
		end
		for _, curLockBuffData in target:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.lockHp, filter) do
			isTrigger = record.args.isLastDamageSeg
			local buff = curLockBuffData.buff
			-- 记录锁血期间的血量
			buff:addExRecord(battle.ExRecordEvent.lockHpDamage, record.valueF)
			-- mode: 0 锁定到x点血
			-- mode: 1 直接锁血
			-- mode: 2 盾白线锁血
			if curLockBuffData.mode == 0 then
				-- 要锁定的血量，未指定则锁1滴血
				-- extraArg参数分别对应BhpMax和hpMax
				local lockHpTo = type(curLockBuffData.extraArg) == "table" and (target:getBaseAttr("hpMax") * curLockBuffData.extraArg[1] + target:hpMax() * curLockBuffData.extraArg[2]) or 1
				if target:hp() < lockHpTo then
					-- 当前血量低于要锁血的血量
					record.valueF = 0
				else
					isTrigger = dealSkillDamage(curLockBuffData, math.max(target:hp()-lockHpTo, 0), target:hp()-lockHpTo) and isTrigger
				end
			elseif curLockBuffData.mode == 1 then
				record.valueF = 0
			elseif curLockBuffData.mode == 2 then
				if record.args.isBeginDamageSeg or not curLockBuffData.recordDamage then
					-- 重置buff中的记录伤害
					curLockBuffData.recordDamage = target:hpMax() * curLockBuffData.extraArg
				end
				-- 伤害超过剩下的记录伤害时，只保留这部分伤害
				isTrigger = dealSkillDamage(curLockBuffData, curLockBuffData.recordDamage, curLockBuffData.recordDamage) and isTrigger
				curLockBuffData.recordDamage = math.max(curLockBuffData.recordDamage - record.valueF, 0)
			end

			if ((curLockBuffData.mode == 0 or curLockBuffData.mode == 2) and curLockBuffData.isAlreadyTrigger == true)
				or curLockBuffData.mode == 1 then
				target.scene:deleteBeAttackDefer(target.id, battle.DamageFromExtra.allocate, record.args.damageId)
			end

			if isTrigger then
				curLockBuffData.isAlreadyTrigger = true

				-- local isDelete = false
				curLockBuffData.triggerTime = curLockBuffData.triggerTime - 1
				buff:playTriggerPointEffect()
				-- 如果免死已经触发，触发还未结束并在该触发节点产生了新的伤害
				if curLockBuffData.isPreDelete then
					if curLockBuffData.mode == 0 or curLockBuffData.mode == 1 then
						record.valueF = 0
						break
					end
				else
					if curLockBuffData.triggerTime <= 0 then
						if curLockBuffData.triggerEndRound ~= 0 then
							curLockBuffData.triggerTime = 99
							buff.lifeRound = curLockBuffData.triggerEndRound
							buff.nowRound = target:getBattleRoundAllWave(buff.csvCfg.skillTimePos)
						else
							curLockBuffData.isPreDelete =  true
						end
					end
					buff:addExRecord(battle.ExRecordEvent.lockHpTriggerTime, curLockBuffData.triggerTime)
					table.insert(operateList, {buff = buff, isDelete = curLockBuffData.isPreDelete})
				end
			end

			-- 锁血2类型与其他类型共存条件
			-- curLockBuffData.mode ~= 2
			-- curLockBuffData.mode == 2 但是伤害不致死
			if (curLockBuffData.mode == 0 or curLockBuffData.mode == 1)
				or (curLockBuffData.mode == 2 and record.valueF < target:hp()) then
				break
			end
		end
		-- 不能在遍历的时候删除
		for _, data in ipairs(operateList) do
			local triggerState = data.buff:getEventByKey(battle.ExRecordEvent.lockHpTriggerState)
			data.buff:addExRecord(battle.ExRecordEvent.lockHpTriggerState, true)
			target:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffTrigger, {
				buffId = data.buff.id,
				buffCfgId = data.buff.cfgId,
				easyEffectFunc = data.buff.csvCfg.easyEffectFunc,
				checkEffectFunc = "lockHpAndKeepHpUnChanged",
				isFirstTrigger = not triggerState,
			})
			if data.isDelete then data.buff:over() end
		end

	end
	return true
end

function battleEasy.freezeProcess(record,attacker,target,sign)
	if target.freezeHp and target.freezeHp > 0 and record.valueF >= 1 then
		local off = target.freezeHp - record.valueF
		local tempDamage = record.valueF
		local delBuffList = {}
		for _, data in target:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.freeze) do
			if tempDamage <= 0 then break end
			if tempDamage > data.freezeHp then
				data.freezeHp = 0
				tempDamage = tempDamage - data.freezeHp
				delBuffList[data.id] = true
			else
				data.freezeHp = data.freezeHp - tempDamage
				tempDamage = 0
			end
		end
		target:delBuff(delBuffList,true)
		if off > 0 then
			target.freezeHp = off
			target:refreshShield()
		end
	end
	return true
end

function battleEasy.suckbloodProcess(record,attacker,target,sign)
	if attacker and record.args.from == battle.DamageFrom.skill and record.args.skillType ~= battle.SkillType.PassiveCombine then
		local attackerSuckBloodVal = attacker:suckBlood()
		-- if attackerSuckBloodVal > 0 then
		-- 	attackerSuckBloodVal = attackerSuckBloodVal + (attacker.suckBloodRate / ConstSaltNumbers.wan)
		-- end
		if attackerSuckBloodVal > 0 then
			local suckHp = math.floor(attackerSuckBloodVal * record.valueF)
			log.battle.object.suckHp(" 吸血计算: attacker suckBloodVal=", attackerSuckBloodVal, "吸收血量: suckHp=", suckHp)
			attacker:resumeHp(attacker,suckHp,
				{
					from = battle.ResumeHpFrom.suckblood,
					ignoreBeHealAddRate = true,
					ignoreLockResume = true
				})
		end
	end
	return true
end

function battleEasy.reboundProcess(record,attacker,target,sign)
	if attacker and attacker.force ~= target.force and record.args.from == battle.DamageFrom.skill and record.args.skillType ~= battle.SkillType.PassiveCombine then
		local selfReboundVal = target:rebound()
		if selfReboundVal > 0 then
			local limitHp = math.max(attacker:hp(),1)
			local damage = record.valueF
			-- TODO: 系数为0时公式删除
			if record.lockHpOriginValue then
				damage = damage + (record.lockHpOriginValue - damage) * gCommonConfigCsv.reboundFix
			end
			local reboundDmg = math.min(math.floor(selfReboundVal * damage),limitHp-1)
			--lockhp之后再造成连锁伤害导致lockhp失效 反弹伤害延后
			target.scene:deferBeAttack(target.id,target,attacker,reboundDmg,2,{
				from = battle.DamageFrom.rebound,
				fromExtra = record.args.fromExtra or {},
				isLastDamageSeg = true,
				isBeginDamageSeg = true,
				beAttackZOrder = record.args.beAttackZOrder,
			})
			-- attacker:beAttack(target, reboundDmg, 2, {
			-- 	from = battle.DamageFrom.rebound,
			-- 	fromExtra = record.args.fromExtra,
			-- 	isLastDamageSeg = true,
			-- 	isBeginDamageSeg = true
			-- })
		end
	end
	return true
end

function battleEasy.finalRateProcess(record,attacker,target,sign,isFillEnv)
	if isFillEnv then
		battleEasy.fillDamageEnv(attacker,target,record,{
			finalDamageAdd = attacker:finalDamageAdd(),
			finalDamageReduce = attacker:finalDamageReduce(),
			finalDamageSub = target:finalDamageSub(),
			finalDamageDeepen = target:finalDamageDeepen()
		})
		return battleEasy.finalRateProcess(record,attacker,target,sign)
	end
	-- 最终伤害比例 = 攻击者的伤害加成-攻击者的伤害降低-防御者的伤害减免+防御者的伤害加深
	local finalRate = math.max((record:finalDamageAdd() - record:finalDamageReduce()
	-record:finalDamageSub()+ record:finalDamageDeepen() + ConstSaltNumbers.one),ConstSaltNumbers.dot05)

	 record.valueF = record.valueF * finalRate

	 return true
end

function battleEasy.resultProcess(record,attacker,target,sign,isFillEnv)
	if isFillEnv then
		battleEasy.fillDamageEnv(attacker,target,record,{
			-- 直死 无视复活
			ignoreFakeDeath = record.args.ignoreFakeDeath or 0,
		})
		return battleEasy.resultProcess(record,attacker,target,sign)
	end

	-- 只存在主类型是才会生效
	if not record:damageFromExtraExit() then
		record.args.ignoreFakeDeath = battleEasy.ifElse(record.ignoreFakeDeath == 0,false,true)
	end
	record:showTargetHeadNumber(target)
    return false
end

-- function battleEasy.preBehaviourProcess(record,attacker,target,sign)

-- end

-- 添加battle.ValueType类型
function battleEasy.valueTypeTable()
	-- local _type = type(default)
	local tb = {}
	tb = {
		value = table.salttable({}),
		__tostring = function()
			if device.platform == "windows" then
				return string.format("%s/%s/%s",tb:get(ValueType.normal),tb:get(ValueType.overFlow),tb:get(ValueType.valid))
			end
		end,
		__valueTypeTable = true,
	}

	tb.get = function(self,key)
		key = key or ValueType.normal
		return self.value[key]
	end
	tb.set = function(self,key,value)
		key = key or ValueType.normal
		self.value[key] = math.floor(value)
	end
	tb.add = function(self,data,key)
		if type(data) == "table" then
			for _,v in pairs(ValueType) do
				self:set(v,self:get(v) + (data.__valueTypeTable and data:get(v) or data[v]))
			end
		else
			key = key or ValueType.normal
			self:set(key,self:get(key) + data)
		end
	end
	tb.addTable = function(self, data, ...)
		if type(data) ~= "table" or not data.__valueTypeTable then
			errorInWindows("valueTypeTable addTable type error, data is %s, need __valueTypeTable", data)
		end
		local keys = {...}
		keys = table.length(keys) > 0 and keys or ValueType
		for _,key in pairs(keys) do
			self:set(key,self:get(key) + data:get(key))
		end
	end

	for _,v in pairs(ValueType) do
		tb.value[v] = 0
	end

	return tb
end