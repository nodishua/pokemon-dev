--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
-- ObjectModel导出Csv公式用
--

local CsvObjectExport = {
	getBuffOverlayCount = 0,
	getSameBuffCount = 0,
	isSelfInCharging = 0,
	isSelfChargeOK = 0
}

local CsvObject = battleCsv.newCsvCls("CsvObject")
CsvObject.ignoreModelCheck = {
	selectCsvTarget = true,
	curSkill = true,
	attackerSkill = true,
	getBuff = true,

}
battleCsv.CsvObject = CsvObject


-- 获取主动和被动技能等级
-- @comment skillLv(1) -> level or 1
-- @comment skillLv(1, 2, 3) -> level or 1
function CsvObject:skillLv(...)
	for _, id in ipairs({...}) do
		local skill = self.model.skills[id] or self.model.passiveSkills[id]
		if skill then
			return skill:getLevel()
		end
	end
	return 1
end

-- 获取技能选中的目标
-- @return 获取技能选中的目标
function CsvObject:selectCsvTarget()
	local targetModel = self.model and self.model:getCurTarget()
	if targetModel then
		if targetModel:getCsvObject() == nil then
			battleCsv.CsvObject.new(targetModel)
			assert(targetModel:getCsvObject(), "object csv object was nil")
		end
		return targetModel:getCsvObject()
	end
	return battleCsv.NilObject
end

-- 获取附身目标
-- @return 获取附身目标
function CsvObject:getPossessTarget()
	local target = self.model and self.model:getEventByKey(battle.ExRecordEvent.possessTarget)
	if target then
		return battleCsv.CsvObject.new(target)
	end
	return battleCsv.CsvObject.new()
end

-- 是否被控制
-- @return true:控制状态
function CsvObject:isBeControlled()
	return self.model:isSelfControled() or self.model:isSelfForceConfusionAndNoTarget()
end

-- 技能是否可以使用,只要其中一个不能使用,则返回false
-- @link app\defines\game_defines.lua battle.MainSkillType
-- @param key int 数值类型(MainSkillType)
-- @return true:可以使用
function CsvObject:skillCanUse(key)
	local data = key and {[key] = true} or {
		[battle.MainSkillType.SmallSkill] = true,
		[battle.MainSkillType.BigSkill] = true,
		[battle.MainSkillType.NormalSkill] = true,
	}
	local switch = true
	for k,v in pairs(data) do
		if v then
			switch = switch and (not self.model:isLogicStateExit(battle.ObjectLogicState.cantUseSkill, {skillType2 = k}))
		end
	end
	return switch
end

-- 获取自然属性
-- @param id int 自然属性类型,默认1
-- @return 自然属性
function CsvObject:nature(id)
	return self.model:getNatureType(id or 1)
end

-- 获取单位id,策划的单位id就是座位号
-- @return 单位位置
function CsvObject:id()
	return self.model.seat
end

-- 获取单位cardID
-- @return 单位unitCfg.cardID
function CsvObject:cardID()
	return self.model.cardID
end

-- 获取单位unitID
-- @return 单位的unitID
function CsvObject:unitID()
	return self.model.unitID
end

-- 获取单位markID
-- @return 单位unitCfg.markID
function CsvObject:markID()
	return self.model.markID
end

-- 获取单位星级
-- @return 单位星级
function CsvObject:star()
	return self.model:getStar()
end

-- 获取单位稀有度
-- @return 单位稀有度
function CsvObject:rarity()
	return self.model.rarity
end
-- 判断battleFlag是否存在
-- @param flag int 战斗内标记
-- @return 默认返回false
function CsvObject:flag(flag)
	return self.model.battleFlag[flag] or false
end

-- 获取等级
-- @return 单位等级
function CsvObject:level()
	return self.model.level
end

-- 获取阵营
-- @return 单位阵营
function CsvObject:force()
	return self.model.force
end

-- 真正死亡判断
-- @return isRealDead
function CsvObject:isRealDeath()
	return self.model:isRealDeath()
end

-- 浅死亡判断
-- @return hp < 0 or self.isRealDead or self.isDead
function CsvObject:isAlreadyDead()
	return self.model:isAlreadyDead()
end

-- 获取hp
-- @comment BhpMax = attrs.base.hpMax B:基础属性
-- @comment AhpMax = attrs.buff.hpMax A:buff属性
-- @comment hpMax = attrs.final.hpMax 最终属性
-- @return 单位hp
function CsvObject:hp()
	return self.model:hp()
end

-- 损失血量
-- @return 损失血量
function CsvObject:lostHp()
	return math.max(0,self.model:hpMax() - self.model:hp())
end

-- 获取mp1
-- @return 单位mp1
function CsvObject:mp1()
	return self.model:mp1()
end

--获取怒气点
function CsvObject:mp1PointOrValue()
	local mp1PointData = self.model:getOverlaySpecBuffByIdx("mp1OverFlow")
	if mp1PointData then
		local mpOverflow = self.model:mpOverflow()
		if mp1PointData.mode == 1 then
			return math.floor(mpOverflow / mp1PointData.rate)
		else
			return mpOverflow
		end
	end
	return 0
end

-- 获取当前攻击技能(主动)
-- @return CsvSkill
function CsvObject:curSkill()
	if self.model and self.model.curSkill then
		local skillModel = self.model.curSkill
		if skillModel:getCsvObject() == nil then
			battleCsv.CsvSkill.new(skillModel)
			assert(skillModel:getCsvObject(), "skill csv object was nil")
		end
		return skillModel:getCsvObject()
	end
	return battleCsv.NilSkill
end

-- 获取当前攻击自身的对象技能(主动)
-- @return CsvSkill
function CsvObject:attackerSkill()
	if self.model and self.model.attackerCurSkill then
		local index = table.length(self.model.attackerCurSkill)
		local skillModel = self.model.attackerCurSkill[index]
		if skillModel then
			if skillModel:getCsvObject() == nil then
				battleCsv.CsvSkill.new(skillModel)
				assert(skillModel:getCsvObject(), "skill csv object was nil")
			end
			return skillModel:getCsvObject()
		end
	end
	return battleCsv.NilSkill
end

-- 获取当前攻击技能的对target伤害状态
-- @comment self:getDamageStateByTarget(target, 'strike') = self:curSkill():getDamageStateByTarget(target, 'strike')
-- @param target Obejct 技能伤害治疗过程段对象
-- @param key string 伤害过程段中的信息 类strike:是否暴击,block:是否格挡等 (natureFlag,nature,natureType,type,miss)
function CsvObject:getDamageStateByTarget(target, key)
	return self:curSkill():getDamageStateByTarget(target, key)
end

-- @return 获取第一个target技能伤害状态(注释)
function CsvObject:getDamageState(key)
	for targetID, info in pairs(self.model.curSkill.targetsFinalResult) do
		local v = table.get(info, 'args', key)
		if v then
			return v
		end
	end
end

-- 获取攻击者对self的伤害状态
-- @comment 类似数码配置 self.curAttackMeObj and self.curAttackMeObj.skills[1] and self.curAttackMeObj.skills[1]:getSKillTargetState(self, 'strike')
-- @comment getDamageStateToMe('strike')
function CsvObject:getDamageStateToMe(key)
	local index = table.length(self.model.attackerCurSkill)
	return table.get(self.model.attackerCurSkill, index, 'targetsFinalResult', self.model.id, 'args', key)
end

-- 获取成功驱散次数
-- @return 默认返回0
function CsvObject:getDispelSuccessCount()
	return self.model:getEventByKey(battle.ExRecordEvent.dispelSuccessCount) or 0
end

-- 是否存在skill
-- @comment hasSkill(1) -> true or false
-- @comment hasSkill(1, 2, 3) -> true or false
-- @param ... int skillID 列表
-- @return true存在 false不存在
function CsvObject:hasSkill(...)
	for _, id in ipairs({...}) do
		local skill = self.model.skills[id] or self.model.passiveSkills[id]
		if skill then
			return true
		end
	end
	return false
end

-- 是否存在buff
-- @param ... int buff表的id
-- @return 返回buff是否存在
function CsvObject:hasBuff(...)
	for _, id in ipairs({...}) do
		local buff = self.model:hasBuff(id)
		if buff then
			return true
		end
	end
	return false
end

-- 指定buff的存在数量
-- @param ... int buff表的id
-- @return 返回buff存在的数量
function CsvObject:countBuff(...)
	local ret = 0
	for _, id in ipairs({...}) do
		local buff = self.model:hasBuff(id)
		if buff then
			ret = ret + 1
		end
	end
	return ret
end

-- 是否存在buff group
-- @param ... array group列表
-- @return 返回buff组是否存在
function CsvObject:hasBuffGroup(...)
	for _, group in ipairs({...}) do
		if self.model:hasBuffGroup(group) then
			return true
		end
	end
	return false
end

--获取某个buff
-- @param buffCsvID int buff表的id
-- @example 获取某个buff的生命周期：self:getBuff(buffCsvID):getLifeRound()
function CsvObject:getBuff(buffCsvID)
	if self.model then
		local buffModel = self.model:getBuff(buffCsvID)
		if buffModel == nil then
			return battleCsv.NilBuff
		end

		if buffModel:getCsvObject() == nil then
			battleCsv.CsvBuff.new(buffModel)
			assert(buffModel:getCsvObject(), "buff csv object was nil")
		end
		return buffModel:getCsvObject()
	end
	return battleCsv.NilBuff
end


-- 对某些buff组的buff.overlayCount进行求和
-- @param ... int buff组Id集合
function CsvObject:sumBuffOverlayByGroup(...)
	local sum = 0
	for _, id in ipairs({...}) do
		sum = sum + self.model:getBuffGroupArgSum("overlayCount", id)
	end
	return sum
end

-- 对某些buff组的buff.lifeRound进行求和
-- @param ... int buff组Id集合
function CsvObject:sumBuffLifeRoundByGroup(...)
	local sum = 0
	for _, id in ipairs({...}) do
		sum = sum + self.model:getBuffGroupFuncSum("getLifeRound", id)
	end
	return sum
end

-- @return 1代表前排 2代表后排
function CsvObject:frontOrBack()
	return self.model:frontOrBack()
end

-- 返回单位护盾血量
-- @param ... int cfgId 需要统计的护盾cfgId, 不填默认所有
-- @return 默认返回0
function CsvObject:shieldHp(...)
	if ... then
		local mark = {}
		local hp = 0
		for _,cfgId in ipairs({...}) do
			mark[cfgId] = true
		end
		for _,data in self.model:ipairsOverlaySpecBuff("shield") do
			if mark[data.cfgId] then
				hp = hp + math.max(data.shieldHp, 0)
			end
		end
		return hp
	else
		return self.model:shieldHp()
		-- return self.model.shieldHp or 0
	end
end

--返回复制buff成功次数
--@return 默认返回0
function CsvObject:getCopyBuffCount()
	return self.model:getEventByKey(battle.ExRecordEvent.copySucessCount) or 0
end

--返回转移buff成功次数
--@return 默认返回0
function CsvObject:getTransferBuffCount()
	return self.model:getEventByKey(battle.ExRecordEvent.transferSucessCount) or 0
end

function CsvObject:chargeStateBeforeWave()
	return self.model:getEventByKey(battle.ExRecordEvent.chargeStateBeforeWave)
end

-- 返回致死伤害数据,适用于死亡触发的节点
-- PassiveSkillTypes: beDeathAttack,kill,fakeDead,realDead
-- BuffTriggerPoint: onHolderRealDeath,onHolderDeath
-- @link battle\battle_defines.lua battle.ValueType
-- @param valueKey int 数值类型(ValueType)
function CsvObject:getKillMeDamage(valueKey)
	if self.model.killMeDamageValues then
		return self.model.killMeDamageValues:get(valueKey)
	end
	return 0
end

--返回统计伤害量
-- @link battle\battle_defines.lua battle.ValueType
-- @link battle\battle_defines.lua battle.DamageFrom
-- @param valueKey int 数值类型(ValueType)
-- @param damageKey int 数值类型(DamageFrom),默认统计全部伤害
-- @return 默认返回0
function CsvObject:getRecordDamage(valueKey,damageKey)
	local total = 0
	for k,v in pairs(self.model.totalDamage) do
		if damageKey then
			if damageKey == v then
				total = total + v:get(valueKey)
			end
		else
			total = total + v:get(valueKey)
		end
	end
	return total
end

--返回统计治疗量
-- @link battle\battle_defines.lua battle.ValueType
-- @link battle\battle_defines.lua battle.ResumeHpFrom
-- @param valueKey int 数值类型(ValueType)
-- @param resumeKey int 数值类型(ResumeHpFrom),默认统计全部伤害
-- @return 默认返回0
function CsvObject:getRecordResumeHp(valueKey,resumeKey)
	local total = 0
	for k,v in pairs(self.model.totalResumeHp) do
		if resumeKey then
			if resumeKey == v then
				total = total + v:get(valueKey)
			end
		else
			total = total + v:get(valueKey)
		end
	end
	return total
end

--返回统计承受伤害量
-- @link battle\battle_defines.lua battle.ValueType
-- @param valueKey int 数值类型(ValueType)
-- @param needCurWave int 是否只需要当前波 (不填波次继承, 填1获取当前波次的承伤值)
-- @return 默认返回0
function CsvObject:getRecordTakeDamage(valueKey,needCurWave)
	return self.model:getTakeDamageRecord(valueKey, needCurWave)
end

-- 返回某个buff造成的伤害量, buff每次触发刷新
-- @param buffCsvID int buff表的id
-- @param index int 伤害量类型 1:不累计 2:累计 默认为1
-- @return 默认返回0
function CsvObject:getMomentBuffDamage(buffCsvID, index)
	index = index or 1
	local data = self.model:getEventByKey(battle.ExRecordEvent.momentBuffDamage, buffCsvID)
	return data and data[index] or 0
end

-- 返回自身部分数据记录
-- @comment lostHp:损失的血量
-- @param key string 记录数据的key
-- @return ExRecordEvent[key]
function CsvObject:getRecordData(key)
	return self.model:getEventByKey(battle.ExRecordEvent[key]) or 0
end

-- 返回自身位移后的位置
-- @return self.id or self.shiftPos
function CsvObject:getRealPos()
	return self.model:getRealPos()
end

-- 返回精灵小技能释放次数
-- @return battle.MainSkillType.SmallSkill
function CsvObject:getPlaySmallSkillCount()
	return self.model:getEventByKey(battle.MainSkillType.SmallSkill) or 0
end

-- 获取指定类型技能释放次数
-- @param skillType2 int battle.MainSkillType
-- @return 默认返回0
function CsvObject:getSkillSpellCountByType(skillType2)
	return self.model:getEventByKey(skillType2) or 0
end

-- 获取指定特殊buff中，指定字段的size
-- @param key 特殊buff的key battle.OverlaySpecBuff
-- @param subkey 指定的字段
-- @return 默认返回0
function CsvObject:getSpecBuffSubkeySize(key, subkey)
	local length = 0
	for _,v in self.model:ipairsOverlaySpecBuff(key) do
		if v[subkey] and type(v[subkey]) == "table" then
			length = length + table.length(v[subkey])
		end
	end
	return length
end

-- 获取指定特殊buff中函数的返回值
-- @param key 特殊buff的key battle.OverlaySpecBuff
-- @param funcName 函数名字
-- @return 默认返回0
function CsvObject:getSpecBuffFuncVal(key, funcName, ...)
	return self.model:doOverlaySpecBuffFunc(key, funcName, ...) or 0
end

-- 获取对象额外攻击模式
-- 1.反击 2.连击 3.协战 4.邀战
-- @return 默认返回0
function CsvObject:getExAttackMode()
	return self.model.exAttackMode or 0
end

-- 获取对象所在行的单位数量
-- @return 返回范围为1-3
function CsvObject:getRowNums()
	local row = self.model:frontOrBack()
	local nums = self.model.scene:getRowRemain(self.model.force, row)
	return nums
end

-- 获取对象所在列的单位数量
-- @return 返回范围为1-2
function CsvObject:getColumnNums( )
	local column = self.model.seat % 3
	column = column == 0 and 3 or column
	local nums = self.model.scene:getColumnRemain(self.model.force, column)
	return nums
end

-- 获取对象buff添加的免疫值
-- @return 默认返回0
function CsvObject:getImmuneVal( buffGroup )
	local immuneVal = 0
	for _,data in self.model:ipairsOverlaySpecBuff("immuneControlVal") do
		immuneVal = data.refreshProb(immuneVal,buffGroup)
	end
	return immuneVal
end

-- 获取对象战斗力
-- @return 返回战斗力
function CsvObject:getFightPoint()
	return self.model.fightPoint
end

local flagTypeList = {
	Z = {79001,79002,79003,79004}
}

for	typ, idList in pairs(flagTypeList) do
	for k, v in ipairs(idList) do
		CsvObject["flag"..typ..k] = functools.partial(function(id, self)
			return self.model.tagSkills[id]
		end, v)
	end
end

-- 获取对象buff添加的控制值
-- @return 默认返回0
function CsvObject:getControlPerVal( buffGroup )
	local controlPerVal = 0
	for _,data in self.model:ipairsOverlaySpecBuff("controlPerVal") do
		controlPerVal = data.refreshProb(controlPerVal,buffGroup)
	end
	return controlPerVal
end

for attr, _ in pairs(ObjectAttrs.AttrsTable) do
	CsvObject['B'..attr] = function(self)	-- 基础值
		return self.model:getBaseAttr(attr)
	end
	CsvObject['A'..attr] = function(self)	-- buff值
		return self.model.attrs.buff[attr]
	end
	CsvObject['BA'..attr] = function(self)  -- final值(除光环外的值) 属性变动使用改值
		return self.model:getRealFinalAttr(attr)
	end
	CsvObject[attr] = function(self)        -- final值
		return self.model[attr](self.model)
	end
end

battleCsv.exportToCsvCls(CsvObject, CsvObjectExport)

