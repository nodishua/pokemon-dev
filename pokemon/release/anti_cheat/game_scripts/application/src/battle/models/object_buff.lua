--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
--
-- 一些与逻辑相关的buff的增删改查的逻辑 在此封装
-- TODO: 待完成
-- 先把嘲讽和沉默转移过来
--

-- 被嘲讽
function ObjectModel:isBeInSneer()
	return self:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.sneer)
end

-- 决斗中
function ObjectModel:isBeInDuel()
	if not self:isBeInSneer() then return end
	local curBuffData = self:getOverlaySpecBuffByIdx(battle.OverlaySpecBuff.sneer)
	return curBuffData.mode == battle.SneerType.Duel
end

-- 获取被嘲讽的目标
function ObjectModel:getSneerObj()
	if self:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.sneer) then
		local curSneerData = self:getOverlaySpecBuffByIdx(battle.OverlaySpecBuff.sneer)
		local sneerAtMeObj = curSneerData.obj
		-- 嘲讽目标处于隐身时 嘲讽暂时失效
		if sneerAtMeObj:checkOverlaySpecBuffExit('stealth') then
			for _,data in sneerAtMeObj:ipairsOverlaySpecBuffTo("stealth", self) do
				return nil
			end
			return sneerAtMeObj
		end
		return sneerAtMeObj
	end

	return nil
end

function ObjectModel:getSneerExtraArgs(isSameForce)
	if not self:isBeInSneer() then return nil end
	local curSneerData = self:getOverlaySpecBuffByIdx(battle.OverlaySpecBuff.sneer)
	return isSameForce and curSneerData.extraArg.spreadArg2 or curSneerData.extraArg.spreadArg1
end


function ObjectModel:setProtectObj(obj)
	if self.force ~= obj.force then
		return nil
	end

	if obj:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.protection) then
		return nil
	end

	return obj
end

function ObjectModel:selectTextImmuneInfo(skillID)
	local skillDamageType = csv.skill[skillID].skillDamageType
	-- TODO: 旧代码
	local allImmnue = self:hasTypeBuff("immuneAllDamage")
	if allImmnue then
		return 'allimmune'
	end
	if skillDamageType == battle.SkillDamageType.Physical then
		local hasPhysicalImmune = self:hasTypeBuff("immunePhysicalDamage")
		if hasPhysicalImmune then
			return "physical"
		end
	elseif skillDamageType == battle.SkillDamageType.Special then
		local hasSpecialImmune = self:hasTypeBuff("immuneSpecialDamage")
		if hasSpecialImmune then
			return "special"
		end
	end

	local immuneText
	for _,data in self:ipairsOverlaySpecBuffTo(battle.OverlaySpecBuff.immuneDamage) do
		immuneText = data:getImmuneInfo(immuneText, skillDamageType)
		if immuneText == "allimmune" then break end
	end

	return immuneText
end

function ObjectModel:processBeHitWakeUp(attacker)
	for _,data in self:ipairsOverlaySpecBuffTo(battle.OverlaySpecBuff.sleepy, attacker) do
		--判断是否能够更新睡眠状态
		data.time = data.time - 1
		if data.time == 0 then self:delBuff(data.id,true) end
	end
end

function ObjectModel:canReborn()
	return self:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.reborn)
end

function ObjectModel:processReborn()
	if self:canReborn() and self:isFakeDeath() and not self:isRebornState() then
		self.state = battle.ObjectState.reborn
		local ret = true
		local deferKey = gRootViewProxy:proxy():pushDeferList(self.id)

		for k,v in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.reborn) do
			if v.isFastReborn then
				-- self.isDead = false
				-- self:setHP(1) -- 恢复一点血
				self:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffTrigger, {
					buffId = v.buff.id
				})
				-- 立即删除 由后续castBuff执行其他效果
				self:delBuff(v.buff.id)
				ret = false
				break
			end
		end
		if ret then
			logf.battle.object.reborn(" seat:%d 复活",self.seat)
			local data = self:getOverlaySpecBuffByIdx(battle.OverlaySpecBuff.reborn)
			data.buff.lifeRound = data.lifeRound
			-- 普通复活, buff结束后恢复
			self:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffTrigger, {
				buffId = data.buff.id
			})
		end
		self.scene:addListViewToBattleTurn(self, gRootViewProxy:proxy():popDeferList(deferKey))
	end
end

function ObjectModel:resetRebornState(hp,mp)
	self.state = battle.ObjectState.normal
	self:resetHp(hp)
	self:setMP1(mp)
	self.scene.extraRecord:cleanEventByKey(battle.ExRecordEvent.rebornRound, self.id)
	-- print("resetRebornState",self.id)
end

-- 被混乱
function ObjectModel:isBeInConfusion()
	return self:checkOverlaySpecBuffExit("confusion")
end
-- 是否需要自动攻击的 buff
function ObjectModel:isNeedAutoFightByBuff()
	return (self:isBeInSneer() or self:isBeInConfusion() or self.scene:beInExtraAttack() or self.scene.play:getExtraBattleRoundData("targetId"))
end

function ObjectModel:addBuffEnhance(buffGroupID,buffCfgID,value,type)
	if not self.buffGroupEnchance[type][buffGroupID] then
		self.buffGroupEnchance[type][buffGroupID] = {}
	end
	self.buffGroupEnchance[type][buffGroupID][buffCfgID] = value
end

function ObjectModel:delBuffEnhance(buffGroupID,buffCfgID,type)
	if not self.buffGroupEnchance[type][buffGroupID] then
		return
	end
	self.buffGroupEnchance[type][buffGroupID][buffCfgID] = nil
end

function ObjectModel:getBuffEnhance(buffGroupID,type)
	local ret = 0
	if buffGroupID == 0 or not self.buffGroupEnchance[type][buffGroupID] then
		return ret
	end
	for _,v in pairs(self.buffGroupEnchance[type][buffGroupID]) do
		ret = ret + v
	end
	return ret
end

function ObjectModel:isNotReSelect(isProtect)
	if isProtect and self:checkOverlaySpecBuffExit('depart') then
		for _,data in self:ipairsOverlaySpecBuffTo("depart", self) do
			if not data.canProtect then
				return true
			end
		end
	end
	return self:isAlreadyDead() or self:checkOverlaySpecBuffExit('leave')
end

-- 禁止适用部分技能快捷方法
-- @param tag string 唯一标签
-- @param data table {[battle.MainSkillType.SmallSkill] = bool ,[battle.MainSkillType.BigSkill] = bool ...}
-- self.closeSkillType2 = {
-- 		{tag = string,data = {}}
-- }
function ObjectModel:addSkillType2Data(tag,data)
	for _,v in ipairs(self.closeSkillType2) do
		if v.tag == tag then
			v.data = data
			return
		end
	end
	table.insert(self.closeSkillType2,{tag = tag,data = data})
end

function ObjectModel:removeSkillType2Data(tag)
	for k,v in ipairs(self.closeSkillType2) do
		if v.tag == tag then
			table.remove(self.closeSkillType2,k)
			return
		end
	end
end

-- 查看技能开关 优先关闭
function ObjectModel:isSKillType2Close(skillType2)
	local switch = false
	for i = table.length(self.closeSkillType2),1,-1 do
		if self.closeSkillType2[i].data[skillType2] then
			switch = switch or self.closeSkillType2[i].data[skillType2]
		end
	end
	return switch
end

function ObjectModel:setExtraAttackMode(mode)
	if not self.exAttackMode then
		self.exAttackMode = mode
	end
end

function ObjectModel:beInExtraAttack()
	if self.exAttackBattleTriggerRound == self.scene.play.curBattleRound then
		return false
	end
	return self.exAttackMode
end

function ObjectModel:nextExtraAttack()
	if self.extraRoundData:empty() then
		return false
	end
	local nextData = self.extraRoundData:back()
	-- if nextData.exAttackBattleTriggerRound == self.scene.play.curBattleRound then
	-- 	return false
	-- end
	return nextData.mode
end

local function getExSkillWeightFixArgs(obj)
	local fixArgs = nil
	for _, weightFixData in obj:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.extraSkillWeightValueFix) do
		if weightFixData.fixType == 0 then
			fixArgs = {fixWeightValue = weightFixData.fixValue, fixCostType = weightFixData.fixCostType}
		end
	end
	return fixArgs
end

local function getBanExAttackArgs(obj, mode)
	local args = {
		canResponseSelf = true,   -- 响应自身
		canTriggerOthers = true,  -- 触发其他人
		canResponseOthers = true, -- 响应其他人
	}
	for _, data in obj:ipairsOverlaySpecBuff("banExtraAttack") do
		local id = data.banModeTb[mode]
		for k, v in pairs(data.banModeType[id]) do
			args[k] = battleEasy.ifElse(not v, v, args[k])
		end
	end
	return args
end

local function checkExAttackTrigger(trigger, responder, mode)
	local banArgs1 = getBanExAttackArgs(trigger, mode)
	local banArgs2 = getBanExAttackArgs(responder, mode)
	if trigger.id == responder.id and not banArgs2.canResponseSelf then return false end
	if trigger.id ~= responder.id then
		if not banArgs1.canTriggerOthers then return false end
		if not banArgs2.canResponseOthers then return false end
	end
	return true
end

function ObjectModel:onComboAttack(skill,target,skillOwner)
	if not skill:isNormalSkillType() then
		return false
	end
	if self.id ~= skillOwner.id then
		return false
	end
	local targetID = target.id
	if target:isAlreadyDead() then
		targetID = nil
	end
	if target:isLogicStateExit(battle.ObjectLogicState.cantBeSelect, {fromObj = skill.owner}) then
		return false
	end
	if not self.comboAttackInfo then
		return false
	end
	if self:beInExtraAttack() then
		return false
	end
	if ymrand.random() > self.comboAttackInfo.rate then
		return false
	end
	self:addExtraBattleData(targetID,skill.id,battle.ExtraAttackMode.combo)
	return true
end

-- 反击 在指定友方(counterAttackInfo中设定的第三个参数决定友方单位)被攻击的时候 具有反击buff的精灵发起反击
function ObjectModel:onCounterAttack(skill,target,skillOwner)
	if not skill:isNormalSkillType() then
		return false
	end

	if self.id == skillOwner.id or skillOwner:isAlreadyDead() then
		return false
	end

	--判断攻击的人是否是同阵营，同时自己不是混乱状态
	if self.force == skillOwner.force and not self:isBeInConfusion() then
		return false
	end

	-- 额外回合中只能同时存在一个反击
	for _, data in self.extraRoundData:pairs() do
		if data.mode == battle.ExtraAttackMode.counter then return false end
	end

	local isCounterAttack = false
	local counterFixArgs = getExSkillWeightFixArgs(skillOwner)

	for _, counterAttackData in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.counterAttack) do
		-- 设置一个flag：指定友方是否被攻击
		local assignFriendlyBeAttack = false

		if not (counterAttackData.mustEnemy and (self.force == skillOwner.force or self:isBeInConfusion())) then
			local counterAttackObjs = counterAttackData.find() or {}
			for _, v in ipairs(counterAttackObjs) do
				if (skill.allDamageTargets[v.id] or skill.protecterObjs[v.id]) and checkExAttackTrigger(v, self, battle.ExtraAttackMode.counter) then
					assignFriendlyBeAttack = true break
				end
			end
		end

		if ymrand.random() <= counterAttackData.rate and assignFriendlyBeAttack then
			isCounterAttack = true
			if counterAttackData.triggerSkillType == "table" then
				self:addExtraBattleData(skillOwner.id,nil,battle.ExtraAttackMode.counter,{
					skillPowerMap = (counterFixArgs and counterFixArgs.fixWeightValue) or counterAttackData.triggerSkillType2,
					costType = (counterFixArgs and counterFixArgs.fixCostType) or counterAttackData.costType
				})
			else
				local skill = self:getSkillByType2(counterAttackData.triggerSkillType2)
				self:addExtraBattleData(skillOwner.id,skill.id,battle.ExtraAttackMode.counter)
			end
		end
		if isCounterAttack then break end
	end
	-- -- 获取指定友方 并判断指定友方是否被攻击 存在多次反击的可能, 遍历反击消息
	-- for i = 1, table.length(self.counterAttackInfo) do
	-- 	-- 设置一个flag：指定友方是否被攻击
	-- 	local assignFriendlyBeAttack = false
	-- 	-- 设置一个flag：反击概率
	-- 	local counterAttackRate = true
	-- 	local assignFriendly = self.counterAttackInfo[i].buffExtraTarget()

	-- 	if assignFriendly then
	-- 		for _, assignTarget in ipairs(assignFriendly) do
	-- 			if skill.allDamageTargets[assignTarget.id] then assignFriendlyBeAttack = true break end
	-- 		end
	-- 	end
	-- 	if ymrand.random() > self.counterAttackInfo[i].rate then
	-- 		counterAttackRate = false
	-- 	end

	-- 	if counterAttackRate and assignFriendlyBeAttack then
	-- 		isCounterAttack = true
	-- 		local data = {
	-- 			[battle.MainSkillType.SmallSkill] = true,
	-- 			[battle.MainSkillType.BigSkill] = true,
	-- 			[battle.MainSkillType.NormalSkill] = false,
	-- 		}
	-- 		if self.counterAttackInfo[i].mode == battle.CounterAttackMode.onlyAttack then
	-- 			self:addSkillType2Data('counterAttack',data)
	-- 		elseif self.counterAttackInfo[i].mode == battle.CounterAttackMode.smallSkill then
	-- 			data[battle.MainSkillType.SmallSkill] = false
	-- 			self:addSkillType2Data('counterAttack',data)
	-- 		end
	-- 		self:addExtraBattleData(skillOwner.id,nil,battle.ExtraAttackMode.counter)
	-- 		-- self:onBuffEffectedLogicState("counterAttack",{
	-- 		-- 	isOver = false
	-- 		-- })
	-- 		if isCounterAttack then
	-- 			break
	-- 		end
	-- 	end
	-- end
	return isCounterAttack
end

-- 协战/邀战触发逻辑
function ObjectModel:onSyncAttack(skill,target,skillOwner)
	local targetId = target:isAlreadyDead() and nil or target.id
	local function addExtraDataToHero(obj,data,mode,exFixarg)
		if not obj or (obj and obj:isAlreadyDead()) then return end
		--判断攻击的人是否是同阵营，同时自己不是混乱状态
		if target.force == obj.force and not obj:isBeInConfusion() and not data.isFixedForce then return end
		if targetId == obj.id then return end
		if target:isLogicStateExit(battle.ObjectLogicState.cantBeSelect, {fromObj = obj}) then return end
		if data.rate > ymrand.random() then
			if data.triggerSkillType == "table" then
				obj:addExtraBattleData(targetId,nil,mode,{
					skillPowerMap = (exFixarg and exFixarg.fixWeightValue) or data.triggerSkillType2,
					costType = (exFixarg and exFixarg.fixCostType) or data.costType,
					isFixedForce = data.isFixedForce,
					targetForce = (data.isFixedForce and targetId) and target.force
				})
			else
				local skill = obj:getSkillByType2(data.triggerSkillType2)
				obj:addExtraBattleData(targetId,skill.id,mode)
			end
			obj.scene:addObjToExtraRound(obj)
		end
	end
	-- local buffDataList = skillOwner:getOverlaySpecBuffList(battle.OverlaySpecBuff.inviteAttack)
	if self.id == skillOwner.id then
		local inviteFixArgs = getExSkillWeightFixArgs(skillOwner)
		-- 遍历所有邀战buff
		for _,inviteData in skillOwner:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.inviteAttack) do
			-- 邀战
			if inviteData.isTrigger(skill.skillType2) then
				local inviteObjs = inviteData.find() or {}
				for _, v in ipairs(inviteObjs) do
					if checkExAttackTrigger(skillOwner, v, battle.ExtraAttackMode.inviteAttack) then
						addExtraDataToHero(v,inviteData,battle.ExtraAttackMode.inviteAttack, inviteFixArgs)
					end
				end
			end
		end
	end

	-- 协战
	-- 同阵营才能协战
	if self.force ~= skillOwner.force then
		return
	end
	-- 协战目标不能为技能释放目标
	if self.id == skillOwner.id then
		return
	end

	--自己不能成为协战目标
	if self.id == target.id then
		return
	end

	local syncFixArgs = getExSkillWeightFixArgs(skillOwner)
	for _,syncData in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.syncAttack) do
		-- 协战
		if syncData.isTrigger(skill.skillType2) then
			if checkExAttackTrigger(skillOwner, self, battle.ExtraAttackMode.syncAttack) then
				addExtraDataToHero(self,syncData,battle.ExtraAttackMode.syncAttack, syncFixArgs)
			end
		end
	end
end

function ObjectModel:onAssistAttack(target, data)
	local targetId = nil
	if self:isAlreadyDead() then return end
	if target then
		targetId = target:isAlreadyDead() and nil or target.id
		--判断攻击的人是否是同阵营，同时自己不是混乱状态
		if target.force == self.force and not self:isBeInConfusion() then return end
		if target:isLogicStateExit(battle.ObjectLogicState.cantBeSelect, {fromObj = self}) then return end
	end
	if data.rate > ymrand.random() then
		if data.triggerSkillType == "table" then
			self:addExtraBattleData(targetId,nil,battle.ExtraAttackMode.assistAttack,{
				skillPowerMap = data.triggerSkillType2,
				costType = data.costType
			})
		else
			local skill = self:getSkillByType2(data.triggerSkillType2)
			self:addExtraBattleData(targetId,skill.id,battle.ExtraAttackMode.assistAttack)
		end
		self.scene:addObjToExtraRound(self)
	end
end

-- 先知反击
function ObjectModel:onProphetAttack(skill, skillOwner, prophetData)
	if not skill:isNormalSkillType() then
		return false
	end

	if self.id == skillOwner.id or skillOwner:isAlreadyDead() then
		return false
	end

	--判断攻击的人是否是同阵营，同时自己不是混乱状态
	if self.force == skillOwner.force and (prophetData.mustEnemy or not self:isBeInConfusion())then
		return false
	end

	local counterFixArgs = getExSkillWeightFixArgs(skillOwner)
	if prophetData.triggerSkillType == "table" then
		self:addExtraBattleData(skillOwner.id,nil,battle.ExtraAttackMode.counter,{
			skillPowerMap = (counterFixArgs and counterFixArgs.fixWeightValue) or prophetData.triggerSkillType2,
			costType = (counterFixArgs and counterFixArgs.fixCostType) or prophetData.costType
		})
	else
		local newSkill = self:getSkillByType2(prophetData.triggerSkillType2)
		self:addExtraBattleData(skillOwner.id,newSkill.id,battle.ExtraAttackMode.counter)
	end
	self.scene:addObjToExtraRound(self)
end

-- 先知影响不可被技能选中
function ObjectModel:extraBattleRoundCantAttack()
	local cantHit = self.scene.play:getExtraBattleRoundData("cantHit")
	if cantHit and cantHit[self.id] then
		return true
	end
	return false
end

--满足位移条件
function ObjectModel:canShiftPos()
	if self:isRealDeath() then
		return false
	end
	if not self.shiftPosMode then
		return false
	end
	local targetSeat = self.shiftPos
	local target = self.scene:getObjectBySeat(targetSeat)
	if target and not target:isRealDeath() then
		return false
	end
	return true
end

--执行位移过程
function ObjectModel:doShiftPos(effectCfg)
	local targetSeat = self.shiftPos
	local oldSeat = self.seat
	local target = self.scene:getObjectBySeat(targetSeat)
	--修改obj
	if target then
		target.seat, self.seat = oldSeat, targetSeat
	else
		self.seat = targetSeat
	end
	self.shiftPos = nil
	self.shiftPosMode = nil

	--表现(修改spr)
	-- battleEasy.queueNotifyFor(self.view, 'doShiftPos', targetSeat, effectCfg)
	self.view:notify('doShiftPos', targetSeat, effectCfg)
	gRootViewProxy:notify('doShiftPos', tostring(self))
	--对应单位位移
	if target then
		-- battleEasy.queueNotifyFor(target.view, 'doShiftPos', oldSeat)
		target.view:notify('doShiftPos', oldSeat)
		gRootViewProxy:notify('doShiftPos', tostring(target))
	end
end

function ObjectModel:checkBuffCanBeAdd(casterId, ignoreCaster, ignoreHolder)
	-- if self.stealthInfo and not self.stealthInfo.canAddBuff then
	-- 	return false
	-- end
	local caster = self.scene:getObject(casterId)
	-- 是否需要判断buff的caster的状态 0:是 1:否 (目前和caster有关的仅有离场)
	if ignoreCaster ~= 1 then
		if caster and caster:checkOverlaySpecBuffExit("leave") and caster.id ~= self.id then
			return false
		end

		-- 离场对象能不能够给其他人加buff 受参数leaveSwitch控制
		if caster and caster:checkOverlaySpecBuffExit("depart") and caster.id ~= self.id then
			for _, data in caster:ipairsOverlaySpecBuffTo("depart") do
				if data.leaveSwitch then return false end
			end
		end
	end

	local ignoreBuffGroup = battleEasy.ifElse(ignoreHolder, battleCsv.doFormula(ignoreHolder, self.protectedEnv), {})
	if ignoreBuffGroup ~= 1 then
		if self:isLogicStateExit(battle.ObjectLogicState.cantBeAddBuff, {
			fromObj = caster,
			ignoreBuffGroup = battleEasy.ifElse(type(ignoreBuffGroup) == "table", ignoreBuffGroup, {})
		}) then
			return false
		end
	end

	-- 决斗相关
	if caster and caster:isBeInSneer() then
		local isSameForce = caster.force == self.force
		if (caster:getSneerExtraArgs(isSameForce) == battle.SneerArgType.NoSpread or caster:getSneerExtraArgs(isSameForce) == battle.SneerArgType.DamageSpread) then
			local sneerObj = isSameForce and caster or caster:getSneerObj()
			if sneerObj and sneerObj ~= self then
				return false
			end
		end
	end
	return true
end

local function newReocrdBuffData()
	return {
		order = CVector.new(),
		list = CVector.new(),
		__bindKeys = cow.proxyObject("__bindKeys", {}),
		__globals = cow.proxyObject("__globals", {}),
		__filters = {},
	}
end

-- 特殊叠加类buff相关操作
-- 相同cfgId刷新数据,不同cfgId则添加
function ObjectModel:addOverlaySpecBuff(buff,refreshFunc,sortFunc)
	local key = buff.csvCfg.easyEffectFunc
	local buffEffetCfg = gBuffEffect[key]
	if not buffEffetCfg then
		return errorInWindows("please init %s in buff_effect.csv",key)
	end

	self.recordBuffDataTb[key] = self.recordBuffDataTb[key] or newReocrdBuffData()

	local buffData = self.recordBuffDataTb[key]
	if not refreshFunc then
		errorInWindows("addOverlaySpecBuff must need refresh")
	end

	local index = buffData.list:size() + 1
	for k,v in buffData.list:ipairs() do
		if v.id == buff.id then
			index = k
			break
		end
	end

	-- 同类型叠加,同id刷新
	if buffEffetCfg.overlayType == battle.BuffEffectOverlayType.Normal then
		if index > buffEffetCfg.overlayLimit then
			buff:overClean()
			return
		end

	-- 同buff效果刷新
	elseif buffEffetCfg.overlayType == battle.BuffEffectOverlayType.PopTop then
		if index > buffEffetCfg.overlayLimit then
			local frontData = buffData.list:pop_front()
			local buff = self.buffs:find(frontData.id)
			if buff then
				buff:overClean()
			end
			index = index - 1
		end
	-- 同mode刷新
	elseif buffEffetCfg.overlayType == battle.BuffEffectOverlayType.SameMode then
		local count = 0
		local lastBuffId
		for k,v in buffData.list:ipairs() do
			if v.mode == buff.mode then
				count = count + 1
				lastBuffId = v.id
			end
		end
		if count + 1 > buffEffetCfg.overlayLimit then
			local buff = self.buffs:find(lastBuffId)
			if buff then
				buff:overClean()
			end
			index = buffData.list:size() + 1
		end
	end

	if not buffData.list:at(index) then
		local mt = {}
		-- mt.__ref = buff.isNumberType and buff or buff:getValue()
		mt.__index = function(t, k)
			local k2 = buffData.__bindKeys[k]
			if k2 then return t.buffRef[k2] end
			if buffData.__globals[k] then return buffData.__globals[k] end
			-- if not k2 then
			-- 	return rawget(t,k)
			-- end
			return t.data[k]
		end
		mt.__newindex = function(t, k, v)
			local k2 = buffData.__bindKeys[k]
			if k2 then
				t.buffRef[k2] = v
			elseif buffData.__globals[k] then
				buffData.__globals[k] = v
			else
				t.data[k] = v
			end
			-- if not k2 then
			-- 	rawset(t,k,v)
			-- 	return
			-- end
			-- mt.__ref[k2] = v
		end

		local listData = setmetatable({
			-- __key = buff.id,
			cfgId = buff.cfgId,
			id = buff.id,
			group = buff:group(),
			buffRef = cow.proxyObject("listData_buffRef", buff.isNumberType and buff or buff:getValue()),
			data = cow.proxyObject("listData_data", {}),
			bind = function(t1,k1,k2)
				if not buffData.__bindKeys[k1] then
					buffData.__bindKeys[k1] = k2
				end
			end,
			setG = function(t1,k1,v1)
				if not buffData.__globals[k1] then
					buffData.__globals[k1] = v1
				end
			end
		},mt)
		buffData.list:push_back(listData)
	end

	refreshFunc(buffData.list:at(index))

	if sortFunc and index > 1 and buffData.list:size()==index then
		buffData.list:sort(sortFunc)
	end

	self:refreshOverlaySpecBuffOrder(key)
end

function ObjectModel:getOverlaySpecBuffData(key)
	local buffData = self.recordBuffDataTb[key]
	return buffData and buffData.__globals or {}
end

function ObjectModel:refreshOverlaySpecBuffOrder(key)
	local keys = type(key) == "string" and {key} or key
	for _, i in ipairs(keys) do
		local buffData = self.recordBuffDataTb[i]
		local ret

		buffData.order:clear()
		for ii, data in buffData.list:ipairs() do
			ret = true
			for _,f in ipairs(buffData.__filters) do
				if f(data) then
					ret = false
					break
				end
			end
			if ret then buffData.order:push_back(ii) end
		end
	end
end

function ObjectModel:addOverlaySpecBuffFilter(key, dataFilter)
	self.recordBuffDataTb[key] = self.recordBuffDataTb[key] or newReocrdBuffData()

	local buffData = self.recordBuffDataTb[key]

	local filter = dataFilter or function()
		return true
	end
	table.insert(buffData.__filters, filter)

	self:refreshOverlaySpecBuffOrder(key)

	return tostring(filter)
end

function ObjectModel:deleteOverlaySpecBuffFilter(key, delFunc)
	local buffData = self.recordBuffDataTb[key]
	for i, f in ipairs(buffData.__filters) do
		if tostring(f) == delFunc then
			table.remove( buffData.__filters, i)
			break
		end
	end

	self:refreshOverlaySpecBuffOrder(key)
end

function ObjectModel:checkOverlaySpecBuffExit(key)
	local buffData = self.recordBuffDataTb[key]
	if not buffData then return false end
	if buffData.order:size() == 0 then
		return false
	end
	return true
end

local emptyIteration = function() return nil end

function ObjectModel:ipairsOverlaySpecBuff(key, filter)
	if not self:checkOverlaySpecBuffExit(key) then
		return emptyIteration
	end

	local buffData = self.recordBuffDataTb[key]
	local order, list = buffData.order, buffData.list
	local idx, i, len = 0, 1, order:size()
	filter = filter or function() return false end
	return function()
		idx = idx + 1
		while i <= len do
			local data = list:at(order:at(i))
			i = i + 1
			-- http://172.81.227.66:1104/crashinfo?ident=%5Bstring%22src%2Fbattle.models.object_buff%22%5Dattempttoindexlocal%27data%27(anilvalue)&type=1
			if data and filter(data) == false then
				return idx, data
			end
		end
		return nil
	end
end

-- @params key easyEffectFunc
-- @params obj:ignoreSpecBuff obj是否可以无视self的buff
-- @params env.ignoreBuffGroup 无视buff组
function ObjectModel:ipairsOverlaySpecBuffTo(key, obj, env)
	local filter
	filter = function(data)
		if obj then
			for i, ignoreData in obj:ipairsOverlaySpecBuff("ignoreSpecBuff") do
				if ignoreData.cfgIds[data.cfgId] or ignoreData.specBuffList[key] then
					return true
				end
			end
		end
		if env and env.ignoreBuffGroup then
			if itertools.include(env.ignoreBuffGroup,data.group) then
				return true
			end
		end
		return false
	end
	return self:ipairsOverlaySpecBuff(key, filter)
end

function ObjectModel:deleteOverlaySpecBuff(buff, deletFunc)
	local key = buff.csvCfg.easyEffectFunc
	local buffData = self.recordBuffDataTb[key]
	local len,data = buffData.list:size()
	local ii = 1
	local delIdx
	for i = 1,len do
		local curIdx = buffData.order:at(ii)
		if curIdx then
			if delIdx then
				if curIdx > delIdx then
					buffData.order:update(ii, curIdx - 1)
					ii = ii + 1
				end
			elseif i > curIdx then
				ii = ii + 1
			end
		end

		data = buffData.list:at(i)
		if not delIdx and data.id == buff.id then
			if deletFunc then deletFunc(data) end
			buffData.list:erase(i)
			if buffData.order:at(ii) and buffData.order:at(ii) == i then
				buffData.order:erase(ii)
			end
			delIdx = i
		end
	end
end

function ObjectModel:getOverlaySpecBuffByIdx(key,idx)
	if not self:checkOverlaySpecBuffExit(key) then return end
	local i = self.recordBuffDataTb[key].order:at(idx or 1)
	return self.recordBuffDataTb[key].list:at(i)
end

function ObjectModel:addOverlaySpecBuffFunc(key, funcName, func)
	if not self:checkOverlaySpecBuffExit(key) then return end
	self.recordBuffDataTb[key][funcName] = func
end

function ObjectModel:doOverlaySpecBuffFunc(key, funcName, ...)
	if not self:checkOverlaySpecBuffExit(key) then return end
	if not self.recordBuffDataTb[key][funcName] then return end
	return self.recordBuffDataTb[key][funcName](...)
end

-- 从场外召唤至场内
function ObjectModel:doFrontStage()
	self.seat = self.frontStageTarget
	self:setMP1(self:mp1() + self.transferMp)

	local play = self.scene.play
	if self.stageRound ~= play.curRound or not self.stageAttacked then
		table.insert(play.roundLeftHeros, {obj=self})
	end
	-- 重置标记
	self.stageRound = nil
	self.stageAttacked = nil
	self.frontStageTarget = nil
	self.transferMp = nil

	self:onInitPassData()

	self:initedTriggerPassiveSkill()
	self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderBackStage, self)
	self:onFieldStateChange(true)
	gRootViewProxy:getProxy('onAddUnitsInSeat', tostring(self))
	battleEasy.deferNotifyCantJump(self.view, "stageChange", true)
end

-- 清除所有场地buff
function ObjectModel:clearFieldBuffs()
	for _, buff in self:iterBuffs() do
		if buff.isFieldSubBuff then
			buff:overClean()
		end
	end
end

-- 场地状态发生变化 对应添加/删除场地buff
-- state true:入场 false:离场
-- self.preFieldState 1:在场 2:离场
function ObjectModel:onFieldStateChange(state)
	if self.preFieldState then
		if state and self.preFieldState == 1 then
			return
		elseif not state and self.preFieldState == 2 then
			return
		end
	end

	local isLeave = self:isLeaveField()
	if isLeave and not state then
		self:clearFieldBuffs()
		self.preFieldState = 2
		self:influenceAuraBuff(isLeave)
	elseif not isLeave and state then
		self.scene:tirggerFieldBuffs(self)
		self.preFieldState = 1
		self:influenceAuraBuff(isLeave)
	end
end

function ObjectModel:influenceAuraBuff(isLeave)
	-- 自己离场对给其他人加的光环buff影响
	for _, buff in self.auraBuffs:order_pairs() do
		buff:refreshAuraRef(isLeave and -1 or 1)
	end
	-- 自己离场对给自己的光环buff影响
	for _, buff in self.buffs:order_pairs() do
		if buff.isAuraType then buff:alterAuraBuffValue(0) end
	end
end

-- 是否是离场状态
function ObjectModel:isLeaveField()
	local isLeave = false
	if self:checkOverlaySpecBuffExit("leave") then
		isLeave = true
	end
	for _,data in self:ipairsOverlaySpecBuffTo("depart") do
		if data.leaveSwitch then
			isLeave = true
			break
		end
	end
	if self.seat < 0 then
		isLeave = true
	end
	return isLeave
end

function ObjectModel:dealOpenValueByKey(key, oldValue)
	for _, curBuffData in self:ipairsOverlaySpecBuffTo(battle.OverlaySpecBuff.opGameData) do
		if curBuffData and curBuffData.key == key then
			local isTrigger = curBuffData
			if isTrigger ~= true then
				self.protectedEnv:resetEnv()
				local env = battleCsv.fillFuncEnv(self.protectedEnv, {
					oldValue = oldValue
				})
				isTrigger = battleCsv.doFormula(isTrigger, env)
			end

			if isTrigger then
				return curBuffData.op(oldValue, curBuffData.value)
			end
		end
	end
	return oldValue
end

-- 添加替换技能记录
function ObjectModel:addReplaceSkillRecord(oldId, newId, buffId)
	if not self.skillIdToReplaceRecord[oldId] then
		local newIndex = table.length(self.skillReplaceReocrd) + 1
		self.skillReplaceReocrd[newIndex] = {}
		table.insert(self.skillReplaceReocrd[newIndex],{
			skillId = oldId
		})
		self.skillIdToReplaceRecord[oldId] = newIndex
	end
	self.skillIdToReplaceRecord[newId] = self.skillIdToReplaceRecord[oldId]
	table.insert(self.skillReplaceReocrd[self.skillIdToReplaceRecord[newId]],{
		skillId = newId,
		buffId = buffId,
	})
end

-- 删除替换技能记录
function ObjectModel:delReplaceSkillRecord(index, buffId)
	for id, data in ipairs(self.skillReplaceReocrd[index]) do
		if data.buffId == buffId then
			table.remove(self.skillReplaceReocrd[index], id)
			break
		end
	end
end

function ObjectModel:getLastSkillRecord(index)
	local lastId = table.length(self.skillReplaceReocrd[index])
	return self.skillReplaceReocrd[index][lastId].skillId
end

function ObjectModel:doReplaceSkill(oldId, newId)
	local oldSkill = self.skills[oldId]
	local oldSpellRound = oldSkill.spellRound
	local oldSkillLevel = oldSkill:getLevel()
	self.skills[oldId] = nil
	local skillCfg = csv.skill[newId]
	local newSkill = newSkillModel(self.scene, self, newId, oldSkillLevel)
	self.skills[newId] = newSkill
	newSkill.spellRound = oldSpellRound
end

-- 替换后刷新技能状态和顺序
function ObjectModel:afterReplaceSkill()
	self:updateSkillsOrder()
	self:checkSkillCheat()
	for skillID, skill in self:iterSkills() do
		skill:updateStateInfoTb()
	end
end

-- 替换技能 self.skills
function ObjectModel:replaceSkill(oldIdList, newIdList, buffId)
	for id, oldId in ipairs(oldIdList) do
		local newId = newIdList[id]
		if self.skills[oldId] then
			self:addReplaceSkillRecord(oldId, newId, buffId)
			self:doReplaceSkill(oldId, newId)
		end
	end
	self:afterReplaceSkill()
end

-- 还原技能
function ObjectModel:resumeSkill(buffId)
	for index, record in ipairs(self.skillReplaceReocrd) do
		local curSkillId = self:getLastSkillRecord(index)
		self:delReplaceSkillRecord(index, buffId)
		local newSkillId = self:getLastSkillRecord(index)
		if newSkillId and newSkillId ~= curSkillId then
			self:doReplaceSkill(curSkillId, newSkillId)
		end
	end
	self:afterReplaceSkill()
end

function ObjectModel:resetReplaceSkillRecord()
	self.skillIdToReplaceRecord = {}
	self.skillReplaceReocrd = {}
end

function ObjectModel:isSelfForceConfusionAndNoTarget()
	local beSelfForceConfusion = false
	for _, data in self:ipairsOverlaySpecBuff("confusion",function(data) return not data.needSelfForce end)do
		beSelfForceConfusion = true
		break
	end
	if not beSelfForceConfusion then
		return false
	end
	local selfSideObjs = self:getCanAttackObjs(self.force)
	return table.length(selfSideObjs) == 0
end

-- 记录免疫buff immuneBuff immuneGroup powerGroup
function ObjectModel:newBuffImmune()
	self.buffImmuneCache = {
		immuneBuff = CMap.new(),
		immuneGroup = CMap.new(),
		powerGroup = CMap.new(),
	}
	for _,buff in self:iterBuffs() do
		if buff.isInited and not buff.isOver then
			self:onBuffImmuneChange(buff)
		end
	end
end

-- 某个buff添加或删除对obj免疫的改变
function ObjectModel:onBuffImmuneChange(buff, isOver)
	if not self.buffImmuneCache then
		return
	end

	local changeData = function(map, key)
		local data = map:find(key)
		if not data then
			map:insert(key, {})
			data = map:find(key)
		end
		data[buff.id] = battleEasy.ifElse(isOver, nil, true)
		if not next(data) then
			map:erase(key)
		end
	end

	local groupRelation = gBuffGroupRelationCsv[buff:group()]
	if groupRelation then
		for _, tb in ipairs(groupRelation.immuneGroup) do
			for k, __ in pairs(tb) do
				changeData(self.buffImmuneCache.immuneGroup, k)
			end
		end

		for _, tb in ipairs(groupRelation.powerGroup) do
			for k, __ in pairs(tb) do
				changeData(self.buffImmuneCache.powerGroup, k)
			end
		end
	end

	local immuneBuffs = buff.csvCfg.immuneBuff
	for _, immuneBuffId in ipairs(immuneBuffs) do
		changeData(self.buffImmuneCache.immuneBuff, immuneBuffId)
	end
end

function ObjectModel:checkBuffCanAdd(cfgId, group, groupPower)
	if not self.buffImmuneCache then
		self:newBuffImmune()
	end

	local ret, sortIds = true, {}
	local immGroup = self.buffImmuneCache.immuneGroup:find(group)
	local immBuff = self.buffImmuneCache.immuneBuff:find(cfgId)

	if self.buffImmuneCache.powerGroup:size() > 0 and not self.buffImmuneCache.powerGroup:find(group) then
		return false
	end

	if groupPower.beImmune == 1 and immGroup and next(immGroup) then
		for k, _ in pairs(immGroup) do
			table.insert(sortIds, k)
		end
		ret = false
	end

	if groupPower.beImmune == 1 and immBuff and next(immBuff) then
		for k, _ in pairs(immBuff) do
			table.insert(sortIds, k)
		end
		ret = false
	end

	if not ret then
		table.sort(sortIds, function(id1, id2)
			local buff1 = self.scene.allBuffs:find(id1)
			local buff2 = self.scene.allBuffs:find(id2)
			if buff1.triggerPriority ~= buff2.triggerPriority then
				return buff1.triggerPriority < buff2.triggerPriority
			end
			return buff1.id < buff2.id
		end)
		local effectBuff = self.scene.allBuffs:find(sortIds[1])
		-- 显示被免疫buff的免疫飘字
		battleEasy.deferNotifyCantJump(self.view, "showBuffImmuneEffect",group)
		effectBuff:triggerByMoment(battle.BuffTriggerPoint.onBuffTrigger,{
			buffId = effectBuff.id
		})
	end

	return ret
end

function ObjectModel:clearBuffImmune()
	self.buffImmuneCache = nil
end

function ObjectModel:isPossessAttack(skillType)
	if self:getEventByKey(battle.ExRecordEvent.possessTarget)
		and self:beInExtraAttack() == battle.ExtraAttackMode.assistAttack then
			if skillType and skillType ~= battle.SkillType.NormalSkill
				and skillType ~= battle.SkillType.PassiveCombine then
				return false
			end
			return true
	end
	return false
end