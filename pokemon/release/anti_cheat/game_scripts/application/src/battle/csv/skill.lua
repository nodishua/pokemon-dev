--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
-- SkillModel导出Csv公式用
--

local CsvSkillExport = {
	interruptBuffId = 0,
}

local CsvSkill = battleCsv.newCsvCls("CsvSkill")
CsvSkill.ignoreModelCheck = {
	owner = true,
}
battleCsv.CsvSkill = CsvSkill


-- 获取技能等级
-- @return 获取技能等级
function CsvSkill:level()
	return self.model:getLevel()
end

-- 获取技能Id
-- @return 获取技能Id
function CsvSkill:getId()
	return self.model.id
end

-- 获取技能击杀目标(宽泛击杀，不限真死假死)
-- @return 获取技能击杀目标
function CsvSkill:getKilledTargets()
	return self.model.killedTargetsTb or {}
end

-- 获取技能对target的伤害状态,类似数码CSkillManager:getSKillTargetState
-- @param target obejct 单位
-- @param key string 伤害过程段中的信息 类strike:是否暴击,block:是否格挡等 (natureFlag,nature,natureType,type,miss)
function CsvSkill:getDamageStateByTarget(target, key)
	return table.get(self.model.targetsFinalResult, target.model.id, 'args', key)
end

-- 获取过程段的人数
-- @param processId int 过程段id
-- @return 获取过程段的人数
function CsvSkill:getProcessTargetsCount(processId)
    return table.length(self.model.allProcessesTargets[processId])
end

-- 检查过程段的目标是否全部死亡
-- @param processId int 过程段id
-- @param state string 预制方法
-- @return 检查过程段的目标是否全部死亡
function CsvSkill:checkProcessTargetsState(processId,state)
	local checkFunc = {}
	if state == "nodead" then
		checkFunc = function(targets)
			for _,obj in ipairs(targets) do
				if obj:isAlreadyDead() then
					return false
				end
			end
			return true
		end
	end

	return checkFunc(self.model.allProcessesTargets[processId])
end

-- 获取第一个技能伤害状态,实现原本的skill.record.strikeStatus(注释)
-- @param key string 伤害过程段中的信息 类strike:是否暴击,block:是否格挡等 (natureFlag,nature,natureType,type,miss)
-- @return 获取技能伤害状态
function CsvSkill:getDamageState(key)
	for _, info in pairs(self.model.targetsFinalResult) do
		local v = table.get(info, 'args', key)
		if v then
			return v
		end
	end
end

-- 获取技能总伤害
-- @link battle\battle_defines.lua battle.ValueType
-- @param key int(ValueType) 数值类型
-- @param isResumeHp 0/1 0:伤害 1:治疗(默认伤害)
-- @return 获取技能总伤害 (混合分开计算)
function CsvSkill:getTotalDamage(key,isResumeHp)
	if not self.model.cfg then return 0 end
	key = key or battle.ValueType.normal
	local mapKey = (isResumeHp or 0) == 0 and battle.SkillSegType.damage or battle.SkillSegType.resumeHp

	local totalDamage = 0
	for _, args in self.model:pairsTargetsFinalResult(mapKey) do
		totalDamage = totalDamage + args.real:get(key)
	end
	return totalDamage
end

-- 获取对象受到的技能总伤害
-- @link battle\battle_defines.lua battle.ValueType
-- @param target obejct 单位
-- @param key int(ValueType) 数值类型
-- @param isResumeHp 0/1 0:伤害 1:治疗(默认伤害)
-- @return 获取对象受到的技能总伤害 (混合 = 治疗 + 伤害)
function CsvSkill:getTargetTotalDamage(target,key,isResumeHp)
	if not self.model:chcekTargetInFinalResult(target.model.id) then return 0 end
	if not self.model.cfg then return 0 end
	key = key or battle.ValueType.normal
	isResumeHp = isResumeHp or 0
	local totalDamage,real = 0

	if isResumeHp == 0 and self.model:isSameType(battle.SkillFormulaType.damage) then
		real = self.model.targetsFinalResult[target.model.id].damage.real
		totalDamage = totalDamage + real:get(key)
	end

	if isResumeHp == 1 and self.model:isSameType(battle.SkillFormulaType.resumeHp) then
		real = self.model.targetsFinalResult[target.model.id].resumeHp.real
		totalDamage = totalDamage + real:get(key)
	end

	return totalDamage
end

-- 获取技能伤害类型
-- @return 获取技能伤害类型
function CsvSkill:getSkillDamageType()
	return self.model.cfg.skillDamageType
end

-- 获取技能自然属性
-- @return 获取技能自然属性
function CsvSkill:getNatureType()
	return self.model:getSkillNatureType()
end

-- 获取技能大类
-- @return 获取技能大类 默认0
function CsvSkill:getSkillType()
	return self.model.cfg.skillType or 0
end

-- 获取技能细分类型
-- @return 获取技能细分类型 默认0
function CsvSkill:getSkillType2()
	return self.model.cfg.skillType2 or 0
end

-- 技能的拥有者
-- @return CsvObejct
function CsvSkill:owner()
	if self.model and self.model.owner then
		local objectModel = self.model.owner
		if objectModel:getCsvObject() == nil then
			battleCsv.CsvObject.new(objectModel)
			assert(objectModel:getCsvObject(), "object csv object was nil")
		end
		return objectModel:getCsvObject()
	end
	return battleCsv.NilObject
end

-- 提前计算技能是否会伤害目标,粗计算
-- @param csvTarget CsvObject 判断目标
-- @param csvSelectTarget CsvObject 技能选中目标
-- @return true/false
function CsvSkill:preCalSkillDamageCsvTarget(csvTarget,csvSelectTarget)
	local target = csvTarget.model
	local curSkill = self.model
	local selectTarget = csvSelectTarget.model
	local result = false
	if target and curSkill and selectTarget then
		curSkill.allProcessesTargets = {}
		for i=1,table.length(curSkill.processes) do
			local processCfg = curSkill.processes[i]
			local args = curSkill:onProcess(processCfg, selectTarget)
            curSkill.allProcessesTargets[processCfg.id] = args.targets
			result = result or itertools.include(args.targets,function(obj)
				return obj.id == target.id
			end)
			if result then
				break
			end
		end
	end
	return result
end

-- 获取理论上的技能目标类型
-- @return single-单体 all-全体 row-横排 column-列排 other-其他
function CsvSkill:targetType()
	return self.model.cfg.targetChooseType or 'other'
end

-- 获取触发回合冷却
-- @return 触发回合冷却 默认0
function CsvSkill:getCdRound()
	return self.model.cfg.cdRound
end

-- 是否正在释放技能
-- @return 是否正在释放技能
function CsvSkill:isSpellTo()
	return self.model.isSpellTo
end

battleCsv.exportToCsvCls(CsvSkill, CsvSkillExport)