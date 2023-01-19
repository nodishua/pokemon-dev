--
-- 作用在战斗物体上的 buff
--


require "battle.models.buff.buff_node"
require "battle.models.buff.buff_global"
require "battle.models.buff.buff"
require "battle.models.buff.buff_effect"
require "battle.models.buff.buff_args"

require "battle.models.buff.spec.aura_buff"


local immuneControlGroupId = 999999 -- 控制组

-- return needBreak canAdd canTakeEffect
local BREAK_MARK = true
local blackBoard = {}
local overlayTypeConditions
overlayTypeConditions = {
	-- overlayType = 0 不能叠加
	[battle.BuffOverlayType.Normal] = function(holderBuff, buffCfg)
		return BREAK_MARK, false
	end,
	-- overlayType = 1 直接覆盖, 这里修改为over掉之前的buff从新创建新的形式,
	-- 因为还有非属性类型的buff效果的覆盖
	[battle.BuffOverlayType.Cover] = function(holderBuff, buffCfg)
		-- 光环类型 叠加1类型 会不可添加 但是可以生效
		if holderBuff.isAuraType then
			return BREAK_MARK, false, true
		end
		return BREAK_MARK, true, true
	end,
	-- overlayType = 2 多个叠加, 有层数上限, 效果叠加, 但刷新生命周期 叠加到上限后 刷新生命周期
	[battle.BuffOverlayType.Overlay] = function(holderBuff, buffCfg)
		if holderBuff:getOverLayCount() < buffCfg.overlayLimit then
			return BREAK_MARK, false ,true
		end
		return BREAK_MARK, false, true
	end,
	-- overlayType = 7 同2 叠加到上限后 直接丢弃
	[battle.BuffOverlayType.OverlayDrop] = function(holderBuff, buffCfg)
		if holderBuff:getOverLayCount() < buffCfg.overlayLimit then
			return BREAK_MARK, false ,true
		end
		return BREAK_MARK, false, false
	end,
	-- overlayType = 3 覆盖, 数值大的覆盖小的, 否则不做操作 (需要重新创建新 buff,涉及到初始数据的修改)
	[battle.BuffOverlayType.CoverValue] = function(holderBuff, buffCfg)
		local args = blackBoard.args
		local value = args.value
		local oldVal = holderBuff.args.value
		if (type(value) == 'number') and (type(oldVal) == 'number') then
			if math.abs(value) <= math.abs(oldVal) then
				return BREAK_MARK, false
			end
			return BREAK_MARK, true, true
		else
			errorInWindows("buff check overlay %d, old %s, new %s", buffCfg.overlayType, value, oldVal)
		end
	end,
	-- overlayType = 4 覆盖, 周期长的覆盖段的 (需要重新创建新 buff)
	[battle.BuffOverlayType.CoverLifeRound] = function(holderBuff, buffCfg)
		local args = blackBoard.args
		local round = args.lifeRound
		local oldRound = holderBuff.args.lifeRound
		if (type(round) == 'number') and (type(oldRound) == 'number') then
			if round <= oldRound then
				return BREAK_MARK, false
			end
			return BREAK_MARK, true, true
		else
			errorInWindows("buff check overlay %d, old %s, new %s", buffCfg.overlayType, round, oldRound)
		end
	end,
	-- overlayType = 5 多个叠加, 有层数上限, 需额外记录每层的生命周期, 叠加效果按当前的层数来确定
	[battle.BuffOverlayType.IndeLifeRound] = function(holderBuff, buffCfg)
		if holderBuff:getOverLayCount() < buffCfg.overlayLimit then
			return BREAK_MARK, false,true
		end
		return BREAK_MARK, false
	end,
	[battle.BuffOverlayType.Coexist] = function(holderBuff, buffCfg)
		if overlayTypeConditions["CoexistLessCheck"](buffCfg) then
			return BREAK_MARK, true, true
		end
		return BREAK_MARK, false
	end,
	-- overlayType = 8, 需要生效去触发buff刷新, 改变lifeRound
	[battle.BuffOverlayType.CoexistLifeRound] = function(holderBuff, buffCfg)
		if overlayTypeConditions["CoexistLessCheck"](buffCfg) then
			return BREAK_MARK, true, true
		end
		return BREAK_MARK, false, true
	end,

	--=================toolFuncs=================
	CoexistLessCheck = function(buffCfg)
		local cfgId = blackBoard.cfgId
		local holder = blackBoard.holder
		if holder.buffOverlayCount[cfgId] < buffCfg.overlayLimit then
			return true
		end
	end,
}

local buffConditions = {
	[1] = function(holder, buffCfg)
		-- 1、基础判断条件
		-- 目标死亡判断
		if not holder or holder:isRealDeath() then return BREAK_MARK, false end
	end,
	[2] = function(holder, buffCfg)
		-- 如果是光环buff,但caster死亡时,buff也无法创建
		local caster = blackBoard.caster
		local args = blackBoard.args
		if args.isAuraType and (not caster or caster:isDeath()) then return BREAK_MARK, false end	--目前这个字段并没有加到配表中
	end,
	[3] = function(holder, buffCfg)
		-- 不能加buff的隐身
		local caster = blackBoard.caster
		local casterID = caster and caster.id or 0
		if not holder:checkBuffCanBeAdd(casterID, buffCfg.ignoreCaster, buffCfg.ignoreHolder) then return BREAK_MARK, false end
	end,
	[4] = function(holder, buffCfg)
		local cfgId = blackBoard.cfgId
		if not holder.scene.buffGlobalManager:checkBuffCanAdd({csvCfg = buffCfg,cfgId = cfgId},holder) then
			return BREAK_MARK, false
		end
	end,
	[5] = function(holder, buffCfg)
		-- 2、概率判断
		local caster = blackBoard.caster
		local args = blackBoard.args
		local prob = args.prob -- BuffModel.cfg2ValueWithEnv(args.prob, checkEnv)

		-- -- 部分buff影响对应的buff组概率 updateControlRate
		-- local immuneProb = prob
		-- local updateControlRateProb,updateControlRateGroup,_group = 0
		-- for _,data in holder:ipairsOverlaySpecBuff("updateControlRate") do
		-- 	updateControlRateProb,_group = data.refreshProb(updateControlRateProb,buffCfg.group)
		-- 	if not updateControlRateGroup and _group then
		-- 		updateControlRateGroup = _group
		-- 	end
		-- end
		-- updateControlRateProb = (1 - math.min(updateControlRateProb,1))
		-- if updateControlRateProb > 0 then
		-- 	immuneProb = immuneProb * updateControlRateProb
		-- end
		-- if gControlPerType[buffCfg.easyEffectFunc] and battleEasy.groupReltaionInclude(gBuffGroupRelationCsv[immuneControlGroupId].immuneGroup,buffCfg.group) then
		-- 	if caster then
		-- 		immuneProb = immuneProb + caster:controlPer()
		-- 	end
		-- 	prob = immuneProb - holder:immuneControl()
		-- end

		local immuneRate = 0      -- 免疫百分比 holder
		local immuneVal = 0       -- 免疫值     holder
		local controlRate = 0     -- 控制百分比 caster
		local controlVal = 0      -- 控制值     caster
		local updateControlRateGroup  --展示用 免疫类型

		local function getControlOverlayVal(type, startVal, obj)
			local val, _group = startVal
			if buffCfg.ignoreControlVal == 1 then
				return val
			end
			for _,data in obj:ipairsOverlaySpecBuff(type) do
				val,_group = data.refreshProb(val,buffCfg.group)
				updateControlRateGroup = updateControlRateGroup or _group
			end
			return val
		end

		--holder 相关控制数值
		local isControlType = battleEasy.groupReltaionInclude(gBuffGroupRelationCsv[immuneControlGroupId].immuneGroup,buffCfg.group)
		if isControlType then
			immuneVal = immuneVal + holder:immuneControl()
		end
		immuneVal = getControlOverlayVal("immuneControlVal", immuneVal, holder)
		immuneRate = getControlOverlayVal("immuneControlAdd", immuneRate, holder)
		--caster 相关控制数值
		if caster then
			if isControlType then
				controlVal = controlVal + caster:controlPer()
			end
			controlVal = getControlOverlayVal("controlPerVal", controlVal, caster)
			controlRate = getControlOverlayVal("controlPerAdd", controlRate, caster)
		end

		prob = prob > 0 and (prob + controlVal - immuneVal) * (1 + controlRate - immuneRate) or 0
		prob = math.max(math.min(prob, 1), 0)

		if prob < 1 then --概率基本配的都是1
			local randret = ymrand.random()
			if randret > prob then
				if updateControlRateGroup then
					battleEasy.deferNotifyCantJump(holder.view, "showBuffImmuneEffect",updateControlRateGroup)
				end
				return BREAK_MARK, false
			end
		end
	end,
	[6] = function(holder, buffCfg)
		local cfgId = blackBoard.cfgId
		local scene = holder.scene
		local play = scene.play
		if scene:isCraftGateType() then
			local addTimes = play.craftBuffAddTimes[cfgId] and play.craftBuffAddTimes[cfgId][holder.force] or 0
			local limitType, limitTimes = scene.gateType
			-- craftTriggerLimit里填number, 表示原有逻辑 默认石英, 跨服石英, 跨服竞技场这三个场景生效
			-- 填table表示仅在某个或某几个场景生效固定的次数
			if buffCfg.craftTriggerLimit then
				for _, limitArg in ipairs(buffCfg.craftTriggerLimit) do
					if type(limitArg) == "number" then limitTimes = limitArg
					else limitType, limitTimes = limitArg[1], limitArg[2] end
					if limitType == scene.gateType and addTimes and addTimes >= (limitTimes or math.huge) then
						return BREAK_MARK, false
					end
				end
			end
		end
		-- 3、叠加/免疫 判断
		-- 针对overlayType == 8 定义计数器, 使所有holderBuff.cfgId == cfgId的buff能够被刷新生命周期, 并在最后一个返回true/false判断
		-- local cnt = 0
	end,
	[7] = function(holder,  buffCfg)
		local cfgId = blackBoard.cfgId
		local args = blackBoard.args
		local buffGroupPower = csv.buff_group_power[buffCfg.groupPower]
		args.effectBuffs = {}
		if not holder:checkBuffCanAdd(cfgId,buffCfg.group,buffGroupPower) then
			return BREAK_MARK, false
		end
		for _, buff in holder:iterBuffs() do
			-- if not buff:checkBuffCanAdd(cfgId,buffCfg.group,buffGroupPower) then
			-- 	return BREAK_MARK, false
			-- end
			-- 叠加: 分组叠加 和 个体叠加
			-- 组叠加: 默认不同组id的可以同时存在, 有组限定的才判断 (暂时没有这种,未定规则)
			-- 个体叠加: 有相同id的buff时, 目前暂定不同id的buff可以同时存在
			if buff.cfgId == cfgId then
				-- 第一个buff  常规buff使用
				blackBoard.holderBuff = blackBoard.holderBuff or buff
				table.insert(args.effectBuffs,buff)
			end
		end
	end,
	[8] = function(holder, buffCfg)
		if blackBoard.holderBuff then
			return overlayTypeConditions[buffCfg.overlayType](blackBoard.holderBuff, buffCfg)
		end
	end,
}

-- 检查buff的各种添加条件
-- 免疫飘字只跟 updateControlRate,immuneBuff,immuneGroup 有关
-- caster 有可能不存在, holder一定是得存在的  目标 攻击方
local function checkBuffAddConditions(cfgId, holder, caster, args)
	-- local checkEnv = {}
	local buffCfg = csv.buff[cfgId]
	-- buffID正确性验证  buff表里面有没有对应数据
	if not buffCfg then return false end
	--如果是场景buff 就直接加上
	if args.isSceneBuff then return true end

	blackBoard = {
		cfgId = cfgId,
		holder = holder,
		caster = caster,
		args = args,
	}

	for id, func in ipairs(buffConditions) do
		local needBreak, canAdd, canTakeEffect = func(holder, buffCfg)
		if needBreak then
			return canAdd, canTakeEffect
		end
	end

	return true, true
end

local function refreshHolderBuff(cfgId, holder, caster, args)
	local effectBuffs = args.effectBuffs
	if not effectBuffs then return end
	local buffCfg = csv.buff[cfgId]
	local isFirst = true

	for _,buff in ipairs(effectBuffs) do
		if buffCfg.overlayType == battle.BuffOverlayType.Cover then
			if buff.isAuraType then
				return
			end
			buff:over({endType = battle.BuffOverType.overlay})
		elseif buffCfg.overlayType == battle.BuffOverlayType.Overlay
			or buffCfg.overlayType == battle.BuffOverlayType.OverlayDrop then

			if buff:getOverLayCount() < buffCfg.overlayLimit then
				buff:refresh(args,1)
			elseif buff:getOverLayCount() == buffCfg.overlayLimit and buffCfg.overlayType == battle.BuffOverlayType.Overlay then
				buff:refresh(args)
			end
		elseif buffCfg.overlayType == battle.BuffOverlayType.CoverValue then
			local value = args.value
			local oldVal = buff.args.value
			if (type(value) == 'number') and buff.isNumberType then
				if math.abs(value) > math.abs(oldVal) then
					buff:over({endType = battle.BuffOverType.overlay})		-- 原buffover掉,重新创建个大的
				end
			end
		-- overlayType = 4 覆盖, 周期长的覆盖段的 (需要重新创建新 buff)
		elseif buffCfg.overlayType == battle.BuffOverlayType.CoverLifeRound then
			local round = args.lifeRound
			local oldRound = buff.args.lifeRound
			if (type(round) == 'number') and (type(oldRound) == 'number') then
				if round > oldRound then
					buff:over({endType = battle.BuffOverType.overlay})		-- 原buffover掉,重新创建个长的
				end
			end
		elseif buffCfg.overlayType == battle.BuffOverlayType.IndeLifeRound then
			buff:refresh(args,1)
		elseif buffCfg.overlayType == battle.BuffOverlayType.Coexist then
			if holder.buffOverlayCount[cfgId] < buffCfg.overlayLimit and isFirst then
				holder.buffOverlayCount[cfgId] = holder.buffOverlayCount[cfgId] + 1
			end
		elseif buffCfg.overlayType == battle.BuffOverlayType.CoexistLifeRound then
			if holder.buffOverlayCount[cfgId] < buffCfg.overlayLimit and isFirst then
				holder.buffOverlayCount[cfgId] = holder.buffOverlayCount[cfgId] + 1
			end
			buff:refresh(args, 1)
		end
		isFirst = false
	end
end
-- add buff
-- @param: cfgId -buff配表中的id, holder-将要成为这个新创建buff的持有者(一定是战斗单位), caster-施法者,表示由它来促成生成这个buff(caster可以是非战斗单位)
-- @param: args -buff的一部分参数
--  local args = {
--					prob = buffProb,
--					lifeRound = lifeRound,--
--					curSkillCfg = curSkillCfg,
--					value = value,
--					processCfg = processCfg,
--					--processTargets = curSkill and curSkill.nowProcessTargets or {},
--
--	}
local function checkBuffLinkCond(holder, cfgId, group)
	local allBuffLinkVal = holder.scene.buffGlobalManager:getAllBuffLinkValue(holder.id)
	if not allBuffLinkVal or not next(allBuffLinkVal) then
		return {}
	end
	local sortedBuffLinkVal = {}
	for k,v in pairs(allBuffLinkVal) do
		if v.cfgId == cfgId and (type(v.groups) == 'number' or itertools.include(v.groups, group)) then
			table.insert(sortedBuffLinkVal,{key = k,val = v})
		end
	end
	table.sort(sortedBuffLinkVal,function(a,b)
		return a.key < b.key
	end)
	return sortedBuffLinkVal
end
-- 转化buff
local function changeBuffModel(cfgId, holder, caster, args)
	local mark = {}
	local buffCfg = csv.buff[cfgId]
	local buffGroupPower = csv.buff_group_power[buffCfg.groupPower]
	local _cfgId,rate,rateType = cfgId

	local canAdd,transformSuc = false,false

	while (true) do
		-- 会存在转化前 转化后都是同一buff？
		transformSuc = false
		if buffGroupPower.beChange == 1 and holder:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.transformAttrBuff) then
			for _,data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.transformAttrBuff) do
				-- 存在转换buffId, 并且该转换buff没有被使用过, 使用过mark标记成1
				if not mark[data.cfgId] then
					_cfgId,rate,rateType = data.refreshCfgId(_cfgId,buffCfg.group)
					-- 变换成功
					if _cfgId ~= cfgId and rate then
						if rateType == "number" then
							args.value = string.format("(%s)*%s",args.value,rate)
						else
							args.value = string.format("%s", rate)
						end
						mark[data.cfgId] = true
						transformSuc = true
						break
					end
				end
			end
		end

		if transformSuc then
			-- 转化后的buff要进行一次检测
			canAdd = checkBuffAddConditions(_cfgId, holder, caster, args)
			if not canAdd then return nil end
		else
			break
		end
		-- 刷新转化后buff的相关数据
		cfgId = _cfgId
		buffCfg = csv.buff[cfgId]
		buffGroupPower = csv.buff_group_power[buffCfg.groupPower]
	end

	return cfgId
end

local function newBuffModel(cfgId, holder, caster, args)
	if args.isAuraType then
		return AuraBuffModel.new(cfgId, holder, caster, args)
	end
	return BuffModel.new(cfgId, holder, caster, args)
end

local buffValueNames = {
	"value",
	"buffValueFormula",
}

-- 根据combat_power_correction调整buffArgs
local function alterBuffArgs(cfgId, holder, caster, args, isCheckAfter)
	-- temp disable
	do return end

	if not (args.skillCfg and args.skillCfg.isCombat) then
		return
	end

	local otherForce = 3 - caster.force -- caster的另一边阵营
	local casterForceTotalCP = holder.scene.forceRecordTb[caster.force]["totalFightPoint"]
	local otherForceTotalCP = holder.scene.forceRecordTb[otherForce]["totalFightPoint"]
	local fightPointRate = 1
	local maxTotalCP
	if casterForceTotalCP and otherForceTotalCP and otherForceTotalCP ~= 0 then
		fightPointRate = casterForceTotalCP / otherForceTotalCP
		maxTotalCP = math.max(casterForceTotalCP, otherForceTotalCP)
	end

	-- 低战力修正
	if fightPointRate >= 1 then return end

	local buffCfg = csv.buff[cfgId]
	local checkStatus = function(k, v)
		if fightPointRate >= v.fightPointRate[1] or fightPointRate < v.fightPointRate[2] then
			return false
		end
		if itertools.include(v.excludeBuffID, cfgId) then
			return false
		end
		local cpCorrectGroups = gCPCorrectionGroups[k]
		if not cpCorrectGroups[buffCfg.group] then
			return false
		end
		local combatPowerLimit = v.combatPowerLimit[holder.scene.gateType] or math.huge
		if maxTotalCP < combatPowerLimit then
			return false
		end
		return true
	end

	for k, v in orderCsvPairs(csv.combat_power_correction) do
		if checkStatus(k, v) then
			local buffValueCorrect = v.buffValueRate
			local buffProbCorrect = v.buffProbRate
			-- 概率修正
			args.prob = battleEasy.ifElse(args.prob < 1, buffProbCorrect, 0) + args.prob
			-- value修正 考虑到buff转换 在判断能生效后进行处理
			if isCheckAfter then
				for _, name in ipairs(buffValueNames) do
					-- 多个value不修正
					if args[name] and type(args[name]) ~= "table" then
						args[name] = string.format("(%s)*%s", args[name], buffValueCorrect)
					end
				end
			end
			break
		end
	end
end

-- 根据changeBuffLifeRound调整生命周期
-- return 是否不能添加 调整后生命周期小于1
local function updateLifeRoundArg(cfgId, holder, args)
	local extraLifeRound = 0
	local buffCfg = csv.buff[cfgId]
	for _,data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.changeBuffLifeRound) do
		extraLifeRound = extraLifeRound + data.getExtraRound(buffCfg.group, cfgId)
	end
	args.lifeRound = args.lifeRound + extraLifeRound
	return extraLifeRound ~= 0 and args.lifeRound <= 0
end

local buffLoopRecord = {}
local function checkBuffLoop(recordStr, cfgId, args)
	buffLoopRecord[recordStr] = buffLoopRecord[recordStr] or 0
	buffLoopRecord[recordStr] = buffLoopRecord[recordStr] + 1

	if buffLoopRecord[recordStr] > 50 then
		buffLoopRecord[recordStr] = nil
		errorInWindows("buff:%d cast stack overflow, from skill:%d, source:%s", cfgId, args.fromSkillId or 0, args.source or "")
		return true
	end

	return false
end

function globals.addBuffToHero(cfgId, holder, caster, args)
	-- release_print('addBuffToHero', ymrand.randCount, cfgId, holder, caster)

	holder = cow.proxyObject("holder", holder)
	caster = cow.proxyObject("caster", caster)

	-- 没有命中不加buff
	if args.miss then return _,false end
	alterBuffArgs(cfgId, holder, caster, args)
	-- 调整后生命周期小于1不能被加上
	if updateLifeRoundArg(cfgId, holder, args) then return _,false end
	-- 能被添加和能生效是两个概念
	local canAdd,canTakeEffect = checkBuffAddConditions(cfgId, holder, caster, args)

	if canTakeEffect then
		-- 光环buff无法被转化
		if not args.isAuraType and canAdd then
			cfgId = changeBuffModel(cfgId, holder, caster, args)
			-- 添加上了 但是被转化了 算生效了
			if not cfgId then return _,true end
		end
		alterBuffArgs(cfgId, holder, caster, args, true)
		-- check -> 转化 -> 刷新holder的buff逻辑 -> 添加新buff
		refreshHolderBuff(cfgId, holder, caster, args)
	end

	if args.isAuraType and holder:hasBuff(cfgId) then return _,canTakeEffect end

	if canAdd then --各种条件都满足时，才添加buff
		-- 检查buff调用次数
		local recordStr = string.format("%d_%d_%d", cfgId, holder and holder.seat or 0, caster and caster.seat or 0)
		if checkBuffLoop(recordStr, cfgId, args) then return _, canTakeEffect end

		local buff = newBuffModel(cfgId, holder, caster, args)
		-- 如果转换成功, 新buff需要走一遍check流程, 不能添加的话直接返回
		-- if buff.cfgId ~= cfgId then
		-- 	local newCanAdd, newCanTakeEffect = checkBuffAddConditions(buff.cfgId, holder, caster, buff.args)
		-- 	if not newCanAdd then return _, newCanTakeEffect end
		-- end
		-- 加入 scene 的记录中
		holder.scene.allBuffs:insert(buff.id, buff)
		if buff.isFieldBuff then
			holder.scene.fieldBuffs:insert(buff.id, buff)
		end
		-- 加入 holder 的记录中
		holder.buffs:insert(buff.id, buff)
		local changeToEnemyData = holder:getOverlaySpecBuffByIdx("changeToRandEnemyObj")
		if caster and changeToEnemyData and (caster.id == holder.id) and changeToEnemyData.changeUnitBuffs then
			table.insert(changeToEnemyData.changeUnitBuffs,buff.id)
		end
		buff:init()
		holder:onBuffEffectedHolder(buff)
		holder:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffBeAdd,buff)
		local buffLinkInfo = checkBuffLinkCond(holder, cfgId, buff:group())
		local valOrigin = args.value
		if next(buffLinkInfo) then
			for k,v in ipairs(buffLinkInfo) do
				local value = valOrigin*v.val.fixValue
				local objID = v.key
				local obj = holder.scene:getObjectExcludeDead(objID)
				if obj then
					args.value = value
					addBuffToHero(cfgId, obj, caster, args)
				end
			end
		end
		buffLoopRecord[recordStr] = nil
		return buff,canTakeEffect
	end
	return _,canTakeEffect
end

function globals.addAuraBuffToHero(cfgId, holder, caster, args)
	args.isAuraType = true
	local buff = addBuffToHero(cfgId, holder, caster, args)
	if buff then
		-- 如果是光环buff时, caster需要记录这些光环buff
		if caster and not caster:isDeath() then
			caster.auraBuffs:insert(buff.id, buff)
		end
	end
	return buff
end

function globals.addBuffToScene(cfgId, holder, caster, args)
	local prob = args.prob
	if prob < 1 then --概率基本配的都是1
		local randret = ymrand.random()
		if randret > prob then
			return
		end
	end
	local buff = newBuffModel(cfgId, holder, caster, args)
	if not holder.scene.buffGlobalManager:checkBuffCanAdd(buff,holder) then
		return
	end
    buff.isInited = true
    buff.buffValue = clone(buff:cfg2Value(buff.args.value))
    buff.showDispelEffect = false--buff:dispelGroupBuff()
	-- BuffModel.IDCounter = BuffModel.IDCounter - 1 -- 不算buff
	-- 场景buff的添加限制
	holder.scene.buffGlobalManager:refreshBuffLimit(holder.scene,buff)
	holder.scene:initGroupObj(buff)
    return
end


-- buff 考虑 不检测 caster的存在性, 另外对于一部分buff效果, 考虑把计算需要的数据独立出来,
-- 这样 buff 就也可以作为环境 buff 来用， 由一个系统环境去为目标加buff,这样就能简单的实现天气的效果了

-- obj_1 --> obj_2
-- sys --> obj
-- ?? obj_1 --> sys --> obj_2

