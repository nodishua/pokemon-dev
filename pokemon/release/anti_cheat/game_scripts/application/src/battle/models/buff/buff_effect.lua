--
-- buff 的具体效果
--

-- specialVal 填的应该是辅助性质的内容
-- args 里是决定性质的内容


local BuffEffectFuncTb

local recordOpMap = {
	[1] = function(target)
		return target:getTakeDamageRecord(battle.ValueType.normal)
	end,
}

local opMap = {
	[1] = function(oldValue, value) -- 返回修改后的值
		return value
	end,
	[2] = function(oldValue, value) -- 返回修改后的值
		return oldValue + value
	end,
}

local function argsCheck(args,buff)
	if args < 0 then
		errorInWindows("buff(%s) args(%s) < 0",buff.cfgId,args)
		return 0
	end
	return args
end

local function argsArray(args)
	if type(args[1]) ~= 'table' then
		return {args}
	end
	return args
end

function BuffModel:getBuffEffectFunc(effectName)
	return BuffEffectFuncTb[effectName]
end

-- effectName:buff的具体作用效果函数, args:可能是数值,也可能是table类型的 , isOver: 标记是在结束时调用的
function BuffModel:doEffect(effectName, args, isOver)
	logf.battle.buff.doEffect("doEffect %s args=%s isOver=%s", effectName, args and lazydumps(args), isOver)
	if isOver == nil then isOver = false end
	local f = self:getBuffEffectFunc(effectName)
	--如果只是加单项属性的类型： 格式: easyEffectFunc 填属性名 strike , buffValue 中填数值 {5000} / {0.6}
	if not f and ObjectAttrs.AttrsTable[effectName] then
		args = {{attr=effectName, val=args}}
		f = self:getBuffEffectFunc("addAttr")
	end
	if f then
		return f(self, args, isOver)
	end
end

local function adjustSkillType2Data(default,specialVal)
	if specialVal then
        default = {
            [battle.MainSkillType.SmallSkill] = true,
			[battle.MainSkillType.BigSkill] = true,
			[battle.MainSkillType.NormalSkill] = true,
        }
		for _,v in ipairs(specialVal) do
			default[v] = false
		end
	end
	return default
end

-- 变身unitID的处理函数
-- 变身buff用到的检测, obj身上有多个变身buff同时存在时
-- a --> b --> c --> d 变身顺序, 保证当前存在的形象是最新的, 且按变身的顺序逆序变回去
-- value: 变身之前的unitID, 记录在buff.value中
local getChangeUnitIdFunc = function(buff, value)
	local oldUnitID = buff.holder.orginUnitId-- 变身前的unitID
	local needReloadUnit = true		-- 是否需要重新加载unit
	local unitIdTb = buff.holder.changeUnitIDTb	-- 记录变身数据的tb,格式: {{buffCntId, 变身后的unitID, 是否改变技能}}
	for k,v in ipairs(unitIdTb) do
		if v[1] == buff.id then
			table.remove(unitIdTb,k)
			break
		end
	end
	local backPos = table.length(unitIdTb)
	oldUnitID = unitIdTb[backPos] and unitIdTb[backPos][2] or oldUnitID
	needReloadUnit = oldUnitID ~= buff.holder.unitID

	local oldSkillUnitID = buff.holder.orginUnitId
	local needReloadSkill = true    -- 是否需要重新加载skill
	for k = backPos, 1, -1 do
		if unitIdTb[k][3] then
			oldSkillUnitID = unitIdTb[k] and unitIdTb[k][2] or oldSkillUnitID
			break
		end
	end
	needReloadSkill = oldSkillUnitID ~= buff.holder.unitID

	return needReloadUnit, oldUnitID, needReloadSkill
end

--变身unitID的处理函数
local function initChangeUnitFunc(buff, args, isBuffOver,enemySkillInfo,buffValue)
	buff.holder.unitID = args
	buff.holder.unitCfg =csvClone(csv.unit[args])
	local unitCfg = buff.holder.unitCfg
	--unit的属性也要替换成新的unit
	buff.holder.natureType = unitCfg.natureType
	buff.holder.natureType2 = unitCfg.natureType2
	buff.holder.battleFlag = unitCfg.battleFlag
end

local function initChangeSkillFunc(buff, args, isBuffOver,enemySkillInfo,buffValue)
	local preSkillLeveltb = {}
	local skillCfg = {}
	local preSkillInfo = {}  -- 记录变身前的skillInfo

	--这里保存下技能对应的技能等级 key是技能对应的技能类型skillType2
	if next(buff.holder.skillInfo) then
		for skillId, skillLevel in pairs(buff.holder.skillInfo) do
			skillCfg = csv.skill[skillId]
			-- tagSkill不计算
			if skillCfg then
				if skillCfg.skillType2 ~= battle.MainSkillType.PassiveSkill or skillCfg.changeUnitTrigger then
					-- 继承tagSkill
					if skillCfg.skillType2 == battle.MainSkillType.TagSkill then
						preSkillInfo[skillId] = skillLevel
					else
						preSkillLeveltb[skillCfg.skillType2] = skillLevel
					end

				end
			else
				errorInWindows("skillID = %d is not in csv",skillId)
			end
		end
	end
	--保存之前unit的技能状态
	-- for skillID, skill in buff.holder:iterSkills() do
	-- 	canSpell = skill:canSpell()
	-- 	leftCd = skill:getLeftCDRound()
	-- end

	if not isBuffOver then
		local skills = battleEasy.getSkillTab(args)
		--变身先清除旧数据
		-- local preSkillInfo = {}  -- 记录变身前的skillInfo
		--技能的等级还用原来unit的
		local replaceStr = ""
		for skillId,_ in pairs(skills) do
			skillCfg = csv.skill[skillId]
			if skillCfg then
				if skillCfg.changeUnitTrigger then
					preSkillInfo[skillId] = preSkillLeveltb[skillCfg.skillType2] or 1
				end
			else
				errorInWindows("skillID = %d is not in csv",skillId)
			end
			replaceStr = replaceStr..skillId.." "
		end
		logf.battle.object.replaceSkill("changeUnit replace skill:%s",replaceStr)
		-- specialVal 为 <TRUE> 即继承额外被动技能
		if buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] then
			for skillId, skillLevel in pairs(buff.holder.passiveSkillInfo) do
				preSkillInfo[skillId] = skillLevel
			end
		end

		if buffValue and buffValue[2] < ymrand.random() then
			local data = adjustSkillType2Data({
				[battle.MainSkillType.PassiveSkill] = true,
			})
			buff.holder:addSkillType2Data(buff.cfgId,data)
		end

		if enemySkillInfo then
			for skillID,skillLevel in pairs(enemySkillInfo) do
				if not preSkillInfo[skillID] then
					skillCfg = csv.skill[skillID]
					if skillCfg then
						if skillCfg.changeUnitTrigger then
							preSkillInfo[skillID] = preSkillLeveltb[skillCfg.skillType2] or 1
						end
					else
						errorInWindows("skillID = %d is not in csv",skillID)
					end
				end
			end
		end
		buff.holder:onInitSkills(preSkillInfo or {} , {})
		-- for skillID, skill in self:iterSkills() do
		-- 	skill.stateInfo.canSpell = canSpell
		-- 	skill.stateInfo.leftCd = leftCd
		-- end
	else
		buff.holder:onInitSkills(buff.holder.skillInfo, buff.holder.passiveSkillInfo)
		buff.holder:removeSkillType2Data(buff.cfgId)
	end
	if buff.overType and buff.overType ==  battle.BuffOverType.clean then return end
	--被动技能 触发入场
	buff.holder:initedTriggerPassiveSkill()
end

--添加一个不能回复mp的标记 这里在buff表新增一个 specialVal字段 用来存指定不能回复mp的buffId
local function canNotRecoverMp(buff)
	for _, otherBuff in buff.holder:iterBuffs() do
		if otherBuff.csvCfg.easyEffectFunc == "cantRecoverMp" then
			local judgeBuffs = otherBuff.csvCfg.specialVal --某一个或者多个特定的不能回复MP1的buff
			if not judgeBuffs then
				buff.holder.cantRecoverMp = true
				break
			end
			for _, buffCfgId in ipairs(judgeBuffs) do
				if buffCfgId == buff.cfgId then
					buff.holder.cantRecoverMp = true
					break
				else
					buff.holder.cantRecoverMp = false
				end
			end
		end
	end
end
--复制或转移buff
local function copyOrTransferBuff(buff, args, isTransferBuff,isCopyGroup)
	local curObject = buff.holder
	local curObjectForce = curObject.force
	local limit = args[3] --复制或转移buff的个数限制
	local delayRound = args[4] or 0 -- 延迟转换
	local prob = args[5] or 1
	local once = true

	local data = {
		triggerRound = buff.lifeRound - delayRound,
		buffTab = {},
		prob = prob,
		isTransferBuff = isTransferBuff
		-- isDelay = delayRound > 0
	}
	buff:addExRecord(battle.ExRecordEvent.copyOrTransferBuff, data)

	--查询caster身上是否有可复制或转移的对应组buff
	local buffGroupIdTb = arraytools.hash(args[1])		--记录buff组id
	local function checkBuff(curBuff)
		if curBuff:group() and buffGroupIdTb[curBuff:group()] then
			if isCopyGroup and curBuff.holder.force ~= curObjectForce then
				return false
			end
			if isTransferBuff and curBuff.csvPower.beTransfer == 0 then
				return false
			end
			if not isTransferBuff and curBuff.csvPower.beCopy == 0 then
				return false
			end
			return true
		end
		return false
	end
	local function makeBuffTab()
		local array = isCopyGroup and curObject.scene.allBuffs or curObject.buffs
		for _, curBuff in array:order_pairs() do
			if checkBuff(curBuff) then
				local newArgs = BuffArgs.fromCopyOrTransfer1(curBuff)
				table.insert(data.buffTab, newArgs)
			end
		end
	end
	makeBuffTab()

	local recordTbl = buff:getEventByKey(battle.ExRecordEvent.copyOrTransferBuff) or {}
	for i=table.length(recordTbl),1,-1 do
		local _data = recordTbl[i]
		if _data.triggerRound >= buff.lifeRound then
			local buffTb = _data.buffTab
			if _data.prob > ymrand.random() then
				local holders = {}
				local buffRound = buff.csvCfg.specialVal[1] --这里回合数暂时不需要支持公式 buff:cfg2Value(buff.csvCfg.specialVal)

				--buff的holder选择类型 目前情况紧急先写死7类型的目标选择 过完年回来优化
				if args[2] == 7 and curObject.curAttackMeObj then
					table.insert(holders, curObject.curAttackMeObj)
				-- 特殊类型 每个buff加给自己的caster
				elseif args[2] == battle.copyOrTransferSpecType.eachCaster then
					holders = {battle.copyOrTransferSpecType.eachCaster}
				else
					holders = buff:getObjectsByCfg(args[2])
				end

				table.sort(buffTb, function(buff1, buff2)
					return buff1.id < buff2.id
				end)
				if next(buffTb) then
					-- 随机选择一个或者多个转移或复制buff
					-- local buffTb = battleEasy.randomGetByArray(buffTb,limit)
					buffTb = random.sample(buffTb, limit, ymrand.random)
					local isSuccess = false
					for _, holder in ipairs(holders) do
						for _, vbuff in ipairs(buffTb) do
							if holder == battle.copyOrTransferSpecType.eachCaster then
								holder = buff.scene:getObject(vbuff.casterID)
							end
							local curBuff,takeEffect
							if holder then
								local newArgs = BuffArgs.fromCopyOrTransfer2(vbuff, buffRound, curObject.curSkill)
								curBuff,takeEffect = addBuffToHero(vbuff.cfgId, holder, curObject, newArgs)
							end
							-- 表示复制或转移buff成功
							if takeEffect then
								if once then
									buff:playTriggerPointEffect()
									once = false
								end
								if _data.isTransferBuff then
									buff.holder:addExRecord(battle.ExRecordEvent.transferSucessCount, 1)
									buff:addExRecord(battle.ExRecordEvent.transferState, true)
								else
									buff.holder:addExRecord(battle.ExRecordEvent.copySucessCount, 1)
									buff:addExRecord(battle.ExRecordEvent.copyState, true)
								end
								-- 单次转移或复制成功的个数
								buff:addExRecord(battle.ExRecordEvent.sucessCount, 1)
								isSuccess = true
							end
						end
					end
					_data.buffTab = buffTb
					if isSuccess then
						-- 转移触发
						buff:triggerByMoment(battle.BuffTriggerPoint.onBuffTrigger)
					end
				end

				--清理自身对应的转移buff,转移成功之后再清理所以放在最后
			end
			table.remove(recordTbl,i)
			local function endBuffFromCurObject()
				for _, buff in ipairs(_data.buffTab) do
					local buff = curObject:getBuff(buff.cfgId)
					if buff then buff:over() end
				end
			end
			local function endBuffFromForce()
				for _, buff in ipairs(_data.buffTab) do
					local obj = buff.scene:getObject(buff.holderID)
					if obj then
						local buff = curObject:getBuff(buff.cfgId)
						if buff then buff:over() end
					end
				end
			end
			if _data.isTransferBuff then
				if isCopyGroup then
					endBuffFromForce()
				else
					endBuffFromCurObject()
				end
			end
		end
	end
end



local function endAllSameTypeBuff(buff)
	for _, otherBuff in buff.holder:iterBuffs() do
		if otherBuff.id ~= buff.id then
			if otherBuff.csvCfg.easyEffectFunc == buff.csvCfg.easyEffectFunc then
				otherBuff:over({endType = battle.BuffOverType.overlay})
			end
		end
	end
end

local function controlOrImmuneBuff(buff, args, isOver)
	local holder = buff.holder
	if not isOver then
		local func = functools.partial(function(checkGroups,value,prob,group)
			if not checkGroups then return prob end
			local groupRelation
			for k,v in ipairs(checkGroups) do
				groupRelation = gBuffGroupRelationCsv[v]
				if groupRelation and battleCsv.hasBuffGroup(groupRelation.immuneGroup,group) then
					return prob + value,groupRelation.immuneEffect and v or nil
				end
			end
			return prob
		end,buff.csvCfg.specialVal or {999999},args)
		holder:addOverlaySpecBuff(
			buff,
			function(old)
				old.refreshProb = func
			end
		)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

local function getTransformCfgId(args, cfgId, group)
	local safeGet = function(cfgId)
		if csv.buff[cfgId] then
			return csv.buff[cfgId].easyEffectFunc
		end
		errorInWindows("getTransformCfgId getEasyEffectFunc %d is not in csv",cfgId)
		return "buff1"
	end

	for _, data in ipairs(args) do
		local idx = itertools.first(data[1],group)
		if idx then
			-- 1: 1对1模式
			-- 2: 随机模式
			local rateIdx
			local toBuffCfgId
			local out = data[2]
			local otherArgs = data[3]
			if otherArgs[1] == 1 then
				toBuffCfgId = out[idx] or cfgId
				rateIdx = idx
			elseif otherArgs[1] == 2 then
				rateIdx = ymrand.random(1, table.length(out))
				toBuffCfgId = out[rateIdx]
			end
			local rate
			local rateType = type(otherArgs[2])
			if rateType == "number" then
				rate = otherArgs[2] or 1
				local effectFunc1,effectFunc2 = safeGet(cfgId),safeGet(toBuffCfgId)
				rate = string.format("((%s/%s)*%s)",getAttrTransformRate(effectFunc2),getAttrTransformRate(effectFunc1),rate)
			else
				rate = otherArgs[2][rateIdx] or 1
			end
			local exArg = {
				limit = data[4],
				targetType = data[5],
			}
			return toBuffCfgId, rate, rateType, exArg
		end
	end
	return cfgId
end

-- 具体的效果触发函数
-- 注意:所有的buff效果函数，都需要有 true/false 返回值 .当然，有些可能本身并没有什么鸟用.
BuffEffectFuncTb = {
	--无论条件怎样,执行结果都是 ture / 下同, 结果是 false
	['alwaysTrue'] = function ()
		return true
	end,
	['alwaysFalse'] = function ()
		return false
	end,
	-- 特殊触发功能, 重置节点的某个属性: 目前就只有重置节点的 triggerTimes
	['resetNode'] = function(buff, args, isOver)
		local nodeId = args.nodeId
		local resetKey = args.key
		if resetKey == "triggerTimes" then
			buff.nodeManager:resetNode(nodeId)
		end
	end,
	-- 常规加属性, 由buff管理删除,(注意, 该方法只给 holder 自身加 )
	['addAttr'] = function (buff, args, isOver)		-- value格式: 1层嵌套的:{attr='strike', val=2333} or 2层嵌套的加多条属性: {{}, {}, {}}
		for _, t in ipairs(argsArray(args)) do
			local attrName = t.attr
			local value = t.val
			if not isOver then
				--print(' ---- add attr:', attrName, value)
				--print(' addAttr1111' , buff.holder.attrs.final[attrName])
				-- print("addAttr",buff.cfgId,attrName,value)
				buff.holder:objAddBuffAttr(attrName, value)		-- 这个增加了对能力弱化属性的判断
				buff.triggerAddAttrTb[attrName] = buff.triggerAddAttrTb[attrName] and (buff.triggerAddAttrTb[attrName] + value) or value
				--print(' addAttr1111' , buff.holder.attrs.final[attrName])
				logf.battle.buff.value("buff value !!! csv=%s buffValue=%s attr[%s]=%s",
					buff.args.value, buff.value, attrName, buff.holder.attrs.final[attrName])
			else
				buff.holder.attrs:addBuffAttr(attrName, -(buff.triggerAddAttrTb[attrName] or 0))	-- over时的计算,不需要考虑能力弱化的影响
				buff.triggerAddAttrTb[attrName] = nil
			end
		end
		return true
	end,
	-- 由节点触发 addAttr 为 holder加的属性, 这类属性需要汇总, 在 buff over()时统一恢复
	-- 在节点内就不能填 addAttr了,需要使用 addAttrNode 关键字, 不然无法记录加成属性
	-- ['addAttrNode'] = function (buff, args)
		-- args = argsArray(args)
		-- BuffEffectFuncTb['addAttr'](buff, args)
		-- for _, t in ipairs(args) do
		-- 	local attrName = t.attr
		-- 	local value = t.val
		-- 	--需要buff自己记录已经加成的值, 会在over删除时使用
		-- 	buff.triggerAddAttrTb[attrName] = buff.triggerAddAttrTb[attrName] and (buff.triggerAddAttrTb[attrName] + value) or value
		-- end
	-- end,
	-- {caster=xxx, skillId=xxxx} --使用target的目标参数
	-- 注意, 这里的放技能, 要使用被动技能,最好是没有动画的那种,不然可能会影响正常动画的表现
	-- 技能暂定是只放一个技能, 貌似没有必要放多个技能,确实有需要时,再增加
	['castSkill'] = function (buff, args, isOver)
		if isOver then return true end
		local skillId = args.skillId
		-- 处理 caster 和 holder 的特殊筛选
		local casters = buff:getObjectsByCfg(args.caster)
		for _, obj in ipairs(casters) do
			if obj then
				local skill = newSkillModel(obj.scene, obj, skillId, 1, tostring(buff))
				if skill.onTrigger then
					skill:onTrigger(skill.type, obj, args)		--默认就是3类型,填3类型
				end
			end
		end
		return true
	end,
	-- {{cfgId=xxx, caster=1, holder=2, prob=xxxx, lifeRound=xxx, value=xxx, bond=1}, {}}
	-- 参数说明：bond: 1-将新buff绑定到主buff上,接受主buff管理  2- 新buff与主buff同级绑定, 同生共死
	-- caster/holder: 可以直接填 主buff的 caster或者holder,也可以填公式去获取
	-- prob: 值默认为 1,可以不填
	['castBuff'] = function (buff, args, isOver)
		if isOver then return true end
		for k, t in ipairs(args) do
			local cfgId = t.cfgId
			local casters = buff:getObjectsByCfg(t.caster)
			local holders = buff:getObjectsByCfg(t.holder)
			if itertools.isempty(casters) or itertools.isempty(holders) then
				return true
			end
			local bond = t.bond
			local childBind = t.childBind
			local castBuffGroup = buff.castBuffGroup:back()
			local function doCastBuff(caster,holder)
				buff.protectedEnv = battleCsv.fillFuncEnv(buff.protectedEnv, {
					self2 = caster,
					target2 = holder,
					trigger = buff.triggerEnv, -- 当前的触发对象 由父buff进行配置
				})
				buff.castBuffEnvAdded = true
				local lifeRound = buff:cfg2Value(t.lifeRound)
				local value = buff:cfg2Value(t.value)
				local prob = buff:cfg2Value(t.prob) or 1
				buff.protectedEnv:resetEnv()
				buff.castBuffEnvAdded = false
				local bondMaster = (bond == 1) and buff
				local isBondOther = (bond == 2)
				local buffArgs = {
					skillCfg = buff.args.skillCfg,
					skillLevel = buff.fromSkillLevel,
					lifeRound = lifeRound,
					fromSkillId = buff.args.fromSkillId,
					value= value,
					buffValueFormula = args.originArgs[k].value,
					buffValueFormulaEnv = buff.protectedEnv,
					prob = prob,
					-- bondedToMaster = bondMaster,		-- 主次绑定
					-- bondedToOther = isBondOther,		-- 同级绑定类型
					source = tostring(buff), 			-- ★★★★★  castBuff产生的子buff,需要记录buff的来源
					fieldSub = buff.isFieldBuff or buff.isFieldSubBuff --场地buff标记
				}
				local newBuff = addBuffToHero(cfgId, holder, caster, buffArgs)
				if newBuff then
					if bond == 1 then	--主次绑定
						table.insert(buff.bondChildBuffsTb, newBuff)
					elseif bond == 2 then	-- 同级绑定
						-- for ___, otherBuff in ipairs(buff.bondToOtherBuffsTb) do
						-- 	table.insert(otherBuff.bondToOtherBuffsTb, newBuff)
						-- 	table.insert(newBuff.bondToOtherBuffsTb, otherBuff)
						-- end
						table.insert(buff.bondToOtherBuffsTb, newBuff)
						table.insert(newBuff.bondToOtherBuffsTb, buff)
					end

					if childBind and childBind[1] and childBind[2] then
						castBuffGroup[childBind[2]] = castBuffGroup[childBind[2]] or {}
						table.insert(castBuffGroup[childBind[2]], {pro=childBind[1], buff=newBuff})
					end
				end
			end
			for __, caster in ipairs(casters) do
				for _, holder in ipairs(holders) do
					doCastBuff(caster,holder)
				end
			end
		end
		return true
	end,
	-- 修改角色技能属性
	-- 常规加属性, 由buff管理删除,(注意, 该方法只给 holder 自身加 )
	-- value格式: 1层嵌套的:{attr='skillPower', val=66666} or 2层嵌套的加多条属性: {{}, {}, {}}
	-- skillNatureType 的value只能做替换
	['skillAttr'] = function (buff, args, isOver)
		itertools.each(argsArray(args), function (_, attrInfo)
			local attrName = attrInfo.attr
			local value = attrInfo.val
			buff.holder.curSkill:addAttr(attrName, value, isOver)
		end)
		return true
	end,
	-- buff伤害
	-- @params args number 伤害数值
	-- @params specialVal table damageType,processId,buffNatureType
	['buffDamage'] = function (buff, args, isOver)
		if isOver then return true end
		local attacker = buff.caster
		local specialArgs = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or {}
		local processId = specialArgs.processId or 2 -- 伤害段id damage_process表
		local holders = {buff.holder}
		local damage,damageArgs
		local buffDamageArgs = {
			from = battle.DamageFrom.buff,	--表示是来自buff的直接伤害,非技能类型,可能后续用来判断是否触发其它效果
			buffCfgId = buff.cfgId,
			damageType = specialArgs.damageType,
			natureType = specialArgs.natureType,
			isLastDamageSeg = true,
			isBeginDamageSeg = true,
			noDamageRecord = specialArgs.noDamageRecord,
		}
		canNotRecoverMp(buff)
		if buff.csvCfg.specialTarget then
			buff.scene:updateBeAttackZOrder()
			buffDamageArgs.processId = buff.id -- 代表的是系列伤害
			buffDamageArgs.beAttackZOrder = buff.scene.beAttackZOrder
			holders = buff:getObjectsByCfg(buff.csvCfg.specialTarget[1])
		end

		-- crash web 4155
		args = math.max(args, 0)
		args = argsCheck(args,buff)
		-- if args < 0 then
		-- 	errorInWindows("buffDamage(%s) < 0",buff.cfgId)
		-- 	args = 0
		-- end
		for k,holder in ipairs(holders) do
			if buffDamageArgs.processId then
				buffDamageArgs.isProcessState = {
					isStart = k == 1,
					isEnd = k == table.length(holders)
				}
			end
		 	damage,damageArgs = holder:beAttack(attacker, args, processId, buffDamageArgs)
			local normalDamage = damage:get(battle.ValueType.normal)
			holder:addExRecord(battle.ExRecordEvent.momentBuffDamage, normalDamage, buff.cfgId)
			local curHero = holder.scene.play.curHero
			if attacker.curSkill and
				((attacker.curSkill:isNormalSkillType() and attacker.curSkill.isSpellTo and attacker.curSkill.owner.id ~= buff.holder.id)
					or (specialArgs.showNumber and curHero.id == attacker.id)) then
				battleEasy.deferNotifyCantJump(nil, 'showNumber', {delta = math.floor(normalDamage), skillId = attacker.curSkill.id, typ = "damage"})
			end
		end
	end,
	-- 直接加血类buff,不计算防御和减免的   格式: args: 填增加的血量数值,负值表示扣血
	['addHP'] = function (buff, args, isOver)
		if isOver then return true end
		local attacker = buff.caster
		local addHpVal = args
		local specialArgs = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]
		local resumeArgs = {
			from = battle.ResumeHpFrom.buff,
			ignoreBeHealAddRate = false,
			fromKey = buff.cfgId,
		}

		if buff.caster and addHpVal > 0 and not (specialArgs and specialArgs.ignoreHealAddRate) then	-- 治疗效果加成(这里可能会有些延迟,后面改到加buff时处理)
			addHpVal = addHpVal * (1 + buff.caster:cure() + buff.caster:healAdd())
		end

		if specialArgs then
			resumeArgs.ignoreLockResume = battleEasy.ifElse(specialArgs.ignoreLockResume,specialArgs.ignoreLockResume,resumeArgs.ignoreLockResume)
			resumeArgs.ignoreBeHealAddRate = battleEasy.ifElse(specialArgs.ignoreBeHealAddRate,specialArgs.ignoreBeHealAddRate,resumeArgs.ignoreBeHealAddRate)
		end

		local holder = buff.holder
		if addHpVal < 0 then
			errorInWindows("addHP(%s) is old,please use buffDamage",buff.cfgId)
		elseif not (specialArgs and specialArgs.ignoreToDamage) and holder:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.healTodamage) then
			holder:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.healTodamage, "doBuffDamage", attacker, holder, addHpVal, buff.cfgId)
		else
			holder:resumeHp(attacker,math.floor(addHpVal),resumeArgs)
		end

		return true
	end,
	-- 增加 hpmax 值, 可正可负
	['addHpMax'] = function (buff, args, isOver)
		local specialArgs = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or {}
		local holder = buff.holder

		-- local beforeHp,beforeHpMax = buff.holder:hp(), buff.holder:hpMax()

		-- 是否影响当前血量,扣除时只返还实际扣除的血量 80/100 -> 70/70 -返还-> 70/100
		local effectHp = battleEasy.ifElse(specialArgs.effectHp ~= nil,specialArgs.effectHp,true) 						-- 同步变动血量/根据血上限变动血量
		local effectBackNone = true--battleEasy.ifElse(specialArgs.effectBackNone ~= nil,specialArgs.effectBackNone,false) 	-- 不返还/返回实际变动

		-- 修改的血上限
		local recordHpMax = buff:getEventByKey(battle.ExRecordEvent.effectHpMax) or 0
		-- 修改的当前血量
		local recordHp = buff:getEventByKey(battle.ExRecordEvent.effectHp) or 0

		local setHolderHp = function(val)
			local hp = holder:hp()
			local damage = battleEasy.valueTypeTable()

			holder:setHP(hp + val)

			if holder:hp() <= 0 then
				damage:add(math.abs(val))
				damage:add(hp,battle.ValueType.valid)
				damage:add(math.abs(val + hp),battle.ValueType.overFlow)
				holder:setDead(buff.caster,damage)
			end
		end

		local hpMaxValue = isOver and -recordHpMax or args
		local hpValue = isOver and -recordHp or args

		-- 影响归还的当前血量
		-- if effectBackNone and isOver then
		-- 	hpValue = 0
		-- end

		-- 同步当前血量
		if hpMaxValue >= 0 then
			holder.attrs:addBuffAttr("hpMax", hpMaxValue)
			-- 1. effectBackNone: False and isOver
			-- 2. effectHp: True and not isOver
			if (effectHp and not isOver) or (not effectBackNone and isOver) then
				setHolderHp(hpValue)
			else
				hpValue = 0
			end
		else
			--血上限扣除不能致死
			if (hpMaxValue + holder:hpMax()) <= 1 then
				hpMaxValue = -holder:hpMax() + 1
				buff:setValue(hpMaxValue)
			end

			-- 当前血量大于血上限,计算实际造成的血量扣除
			if not isOver then
				hpValue = 0
				if effectHp then
					-- 血上限扣除量 负
					hpValue = hpMaxValue
				end
			else
				if effectBackNone then hpValue = 0 end
			end

			-- hp和hpmax判断
			if holder:hp() + hpValue > (hpMaxValue + holder:hpMax()) then
				hpValue = hpMaxValue + holder:hpMax() - holder:hp()
			end

			holder.attrs:addBuffAttr("hpMax", hpMaxValue)

			-- 扣除多余的部分
			if hpValue ~= 0 then
				-- 先加上限再减上限 setHp扣血(这种情况正常下不会造成死亡)
				-- 先减上限再加上限 beAttack扣血(如果死亡需要走判断免死之类的流程)
				if isOver then
					setHolderHp(hpValue)
				else
					local buffDamageArgs = {
						from = battle.DamageFrom.buff,
						isLastDamageSeg = true,
						isBeginDamageSeg = true
					}
					holder:beAttack(buff.caster, math.abs(hpValue), 13, buffDamageArgs)
				end
				-- effectHp 记录真实扣除血量
			end
		end

		if not isOver then
			buff:addExRecord(battle.ExRecordEvent.effectHpMax, hpMaxValue)
			buff:addExRecord(battle.ExRecordEvent.effectHp, hpValue)
		end
		-- 刷新血条显示
		holder:refreshLifeBar()
		-- if buff.holder.force == 2 then
		-- 	print(string.format("init effectHp:%d, effectBackNone:%d", effectHp and 1 or 0, effectBackNone and 1 or 0))
		-- 	print(string.format("addHpMax %d, before (%d/%d) => after (%d/%d), buff state isOver:%d", buff.cfgId, beforeHp,beforeHpMax, buff.holder:hp(), buff.holder:hpMax(), isOver and 1 or 0))
		-- 	print(string.format("lerp hp:%d, hpMax:%d", buff.holder:hp() - beforeHp, buff.holder:hpMax() - beforeHpMax ))
		-- end

		return true
	end,
	-- 设置血量到指定百分比
	['setHpPer'] = function (buff, args, isOver)
		if not isOver then
			local hpMaxVal = buff.holder:hpMax()
			local differ = hpMaxVal * args - buff.holder:hp()
			buff.holder:setHP(hpMaxVal * args)
			battleEasy.deferNotify(buff.holder.view, "showHeadNumber", {typ=differ >= 0 and 1 or 0, num=math.abs(differ), args={}})
		end
	end,
	-- 加怒气		格式: args: 填增加的怒气数值,负值表示扣怒气
	['addMp1'] = function (buff, args, isOver)
		if isOver then return true end
		local mp1Args = {
			ignoreMp1Recover = false, -- 无视修正
			ignoreLockMp1Add = false, -- 无视锁怒
			changeMpOverflow = false  -- 优先改变额外怒气
		}
		local specialArgs = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or {}
		if specialArgs then
			mp1Args.ignoreMp1Recover = battleEasy.ifElse(specialArgs.ignoreMp1Recover,specialArgs.ignoreMp1Recover,mp1Args.ignoreMp1Recover)
			mp1Args.ignoreLockMp1Add = battleEasy.ifElse(specialArgs.ignoreLockMp1Add,specialArgs.ignoreLockMp1Add,mp1Args.ignoreLockMp1Add)
			mp1Args.changeMpOverflow = battleEasy.ifElse(specialArgs.changeMpOverflow,specialArgs.changeMpOverflow,mp1Args.changeMpOverflow)
		end
		local addMpVal = args
		local mp1Correct = addMpVal --mp1的修正值
		if not mp1Args.ignoreMp1Recover then
			mp1Correct = addMpVal * (1.0 + buff.holder:mp1Recover())
		end
		buff.holder:setMP1(buff.holder:mp1() + mp1Correct, nil, mp1Args)
		return true
	end,
	['addMp1Max'] = function (buff, args, isOver)
		local value = args
		if not isOver then
			if (value + buff.holder:mp1Max()) <= 1 then
				value = -buff.holder:mp1Max() + 1
--				buff.doEffectValue = value
--                buff.value = value
                buff:setValue(value)
			end
			buff.holder.attrs:addBuffAttr("mp1Max", value)
		else
			buff.holder.attrs:addBuffAttr("mp1Max", -value)
		end

		if buff.holder:mp1() >= buff.holder:mp1Max() then
			buff.holder:setMP1(buff.holder:mp1Max())
		end

		return true
	end,
	--封锁怒气  只能减少 不能增加  目前是只加了功能，表现还没加
	['lockMp1Add'] = function (buff, args, isOver)
		if not isOver then
			buff.holder.lockMp1Add = true
		else
			buff.holder.lockMp1Add = false
		end
	end,
	-- 禁疗
	['lockResumeHp'] = function (buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			holder:addOverlaySpecBuff(buff,function(old) end)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
	end,
	--受到负的addHP或者directDamge降低目标血量时，不恢复怒气
	['cantRecoverMp'] = function (buff, args, isOver)
		if not isOver then
			buff.holder.cantRecoverMp = true
		else
			buff.holder.cantRecoverMp = false
		end
		return true
	end,
	--无法通过常规技能恢复怒气  受到buff影响的目标，释放技能时，不会回复skill表上的recoverMp1字段上的恢复的怒气
	['cantRecoverSkillMp'] = function (buff, args, isOver)
		if not isOver then
			buff.holder.cantRecoverSkillMp = true
		else
			buff.holder.cantRecoverSkillMp = false
		end
		return true
	end,
	--吸收怒气 suckMp1，吸取目标身上的怒气， <目标降低怒气值;自身增加的比例值>，若目标不足降低怒气值，则吸收剩余怒气
	-- 自身增加的怒气值 = 目标降低的怒气值 * 自身增加的比例值
	['suckMp'] = function (buff, args, isOver)
		if not isOver then
			local subMpValue = args[1]  --目标降低的怒气值
			local addMpRate = args[2]  --自身增加的比例值
			local beSuckMpValue = buff.holder:mp1() > subMpValue and subMpValue or buff.holder:mp1()
			local subValue =  buff.holder:mp1() - beSuckMpValue
			local suckMpValueCorrect = beSuckMpValue * addMpRate * (1.0 + buff.caster:mp1Recover())--自身吸取到的值 加一个修正
			buff.holder:setMP1(subValue)
			buff.caster:setMP1(buff.caster:mp1() + suckMpValueCorrect)
		end
		return true
	end,
	-- 护盾 算作额外hp,不需要计算免伤之类的,最先计算 (护盾应该是不能叠加的, 直接替换掉)
	-- 可能存在这种情况,自己能加护盾,队友也能加护盾, 目标自己加一个,队友也给目标加了一个,这两种护盾都同时存在的情况
	-- 所以护盾修改成table记录的格式
	['shield'] = function (buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			-- 护盾的显示,用通用显示的方式来显示
			-- 护盾触发的受伤效果 护盾破裂的效果,在表现时额外去做
			buff.value = math.floor(argsCheck(buff.value,buff))
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					if not old.shieldMaxTotal then old:setG("shieldMaxTotal", 0) end
					if not old.shieldTotal then old:setG("shieldTotal", 0) end

					local _shieldHpMax = old.shieldHpMax or 0
					local _shieldHp = old.shieldHp or 0
					old.shieldHpMax = buff.value -- 上限
					old.shieldHp = buff.value  -- 当前值
					-- 护盾总上限
					old.shieldMaxTotal = old.shieldMaxTotal + old.shieldHpMax - _shieldHpMax
					-- 护盾总量
					old.shieldTotal = old.shieldTotal + old.shieldHp - _shieldHp
					-- 优先级
					old.priority = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or 1000
					-- lifebar显示类型 0：普通白盾 1：特殊盾
					old.showType = buff.csvCfg.specialVal and buff.csvCfg.specialVal[2] or 0
				end, function(a, b)
					return a.priority > b.priority
				end
			)
		else
			holder:deleteOverlaySpecBuff(buff,function(old)
				old.shieldMaxTotal = old.shieldMaxTotal - old.shieldHpMax
				old.shieldTotal = old.shieldTotal - old.shieldHp
			end)
		end
		buff.holder:refreshShield()
		return true
	end,
	-- 冰冻  buff存在期间无法行动，将固定血量转化为冰冻血量（用特殊护盾来代替冰冻血量，要求与原普通护盾做区分）
	-- 冰冻解除的四种方式：1.直接驱散 ；2.受击直至，冰冻血量值为0；3.受治疗，直至冰冻血量为0; 4.持续回合结束
	-- buff结束时 将剩余冰冻血量转换为本体血量（加成？）
	-- 无视护盾无法无视冰冻护盾造成伤害，addhp（负值）同样无法越过冰冻护盾对血条直接造成伤害
	-- 当普通护盾、冰冻护盾同时存在时，扣除优先级：普通护盾>冰冻护盾
	-- 当前血量小于转化值。则做血量保底为1，其他血量转化为血量值。
	-- 若当前血量为1.则毫无作用，不会被冰冻
	-- 只有显示逻辑走护盾！
	['freeze'] = function (buff, args, isOver)
		local changeHpVal = args --将当前血量转换为冰冻状态的值
		local holder = buff.holder
		if not isOver then
			changeHpVal = math.min(changeHpVal,holder:hp() - (holder.freezeHp or 0))
			holder.freezeHp = (holder.freezeHp or 0) + changeHpVal
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.cfgId = buff.cfgId
					old.freezeHp = changeHpVal
				end, nil
			)
		else
			local delHp = 0
			for _, data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.freeze) do
				if data.cfgId == buff.cfgId then
					delHp = data.freezeHp
					break
				end
			end

			holder:deleteOverlaySpecBuff(buff)

			holder.freezeHp = holder.freezeHp - delHp
			if holder.freezeHp <= 0 or not holder:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.freeze) then
				holder.freezeHp = 0
			end
		end

		-- holder:onBuffEffectedLogicState(buff.csvCfg.easyEffectFunc,{
		-- 	isOver = isOver
		-- })

		return true
	end,
	-- 眩晕  无法行动，跳过本次战斗回合
	['stun'] = function (buff, args, isOver)
		-- if not isOver then
		-- 	buff.holder.beStunned = buff.holder.beStunned and (buff.holder.beStunned + 1) or 1
		-- -- 操作禁止, 在speedRank 上显示 禁用标记？
		-- --
		-- else
		-- 	buff.holder.beStunned = buff.holder.beStunned and (buff.holder.beStunned - 1) or 0
		-- 	buff.holder.beStunned = math.max(buff.holder.beStunned, 0)
		-- end

		local holder = buff.holder
		if not isOver then
			holder:addOverlaySpecBuff(buff,function(old) end,nil)
		else
			-- local data = holder:getOverlaySpecBuffByIdx(buff.csvCfg.easyEffectFunc)
			-- if data.ref > 1 then
			-- 	data.ref = data.ref - 1
			-- else
			-- 	holder:deleteOverlaySpecBuff(buff)
			-- end
			holder:deleteOverlaySpecBuff(buff)
		end

		-- holder:onBuffEffectedLogicState(buff.csvCfg.easyEffectFunc,{
		-- 	isOver = isOver
		-- })

		return true
	end,
	-- 跳过本次战斗回合，一旦受到伤害即可取消睡眠状态
	-- 可以再配置一个 被攻击时触发的 节点，触发后立即 结束buff, over
	['sleepy'] = function (buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			buff:setValue(args or 1)
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					-- old.time = args or 1
					old:bind("time","value")
				end,nil
			)
		else
			-- 可能由于被攻击身上的睡眠buff状态已经被清理掉了
			holder:deleteOverlaySpecBuff(buff)
		end
		return true
	end,
	-- 免疫物理攻击, 不受物理攻击技能和带有物理攻击伤害buff的影响
	['immunePhysicalDamage'] = function (buff, args, isOver)
		if not isOver then
			buff.holder.beInImmunePhysicalDamageState = buff.holder.beInImmunePhysicalDamageState and (buff.holder.beInImmunePhysicalDamageState + 1) or 1
		else
			buff.holder.beInImmunePhysicalDamageState = buff.holder.beInImmunePhysicalDamageState and (buff.holder.beInImmunePhysicalDamageState - 1) or 0
			buff.holder.beInImmunePhysicalDamageState = math.max(buff.holder.beInImmunePhysicalDamageState, 0)
		end
		return true
	end,
	-- 免疫伤害
	-- TODO: 整理immuneAllDamage, immuneSpecialDamage, immunePhysicalDamage
	['immuneDamage'] = function(buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			local immunePower = {
				all = 1,
				physical = 2,
				special = 4,
				skill = 8,
				buff = 16,
			}
			local easyEffectFunc = buff.csvCfg.easyEffectFunc
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					if not old.funcMap then
						old:setG("funcMap", {
							[immunePower.skill] = function(_self, record, attacker)
								if record.args.skillDamageId then
									if not _self:dealSpecialFlag(record, attacker) then
										return
									end
									if not _self:dealTime(record.args.skillDamageId, immunePower.skill, record.args.isLastDamageSeg) then
										return
									end
									return "skillImmune", false
								end
							end,
							[immunePower.buff] = function(_self, record, attacker)
								if record.args.from == battle.DamageFrom.buff then
									if not _self:dealSpecialFlag(record, attacker) then
										return
									end
									if not _self:dealTime(record.args.damageId, immunePower.buff, record.args.isLastDamageSeg) then
										return
									end
									return "buffImmune", false
								end
							end,
							[immunePower.physical] = function(_self, record)
								if record.args.damageType == battle.SkillDamageType.Physical then
									if not _self:dealTime(record.args.skillDamageId or record.args.damageId, immunePower.physical, record.args.isLastDamageSeg) then
										return
									end
									return "physical", true
								end
							end,
							[immunePower.all] = function(_self, record)
								if not _self:dealTime(record.args.skillDamageId or record.args.damageId, immunePower.all, record.args.isLastDamageSeg) then
									return
								end
								return "all", true
							end,
							[immunePower.special] = function(_self, record)
								if record.args.damageType == battle.SkillDamageType.Special then
									if not _self:dealTime(record.args.skillDamageId or record.args.damageId, immunePower.special, record.args.isLastDamageSeg) then
										return
									end
									return "special", true
								end
							end,
						})

						old:setG("dealTime", function(_self, damageId, powerType, isLastDamageSeg)
							if _self.isForever then
								if isLastDamageSeg then
									_self.damageMap.count = _self.damageMap.count + 1
								end
								return true
							end
							if not _self.damageMap.data[damageId] then
								-- 次数已经用完了
								if _self.powerTime[powerType] == 0 then return false end
								_self.damageMap.data[damageId] = true
								-- 不是永久类型要扣次数
								_self.powerTime[powerType] = _self.powerTime[powerType] - 1
							end

							if isLastDamageSeg then
								-- 记录伤害id 的最后一次伤害扣总次数
								_self.allTime = _self.allTime - 1
								_self.damageMap.count = _self.damageMap.count + 1
							end

							return true
						end)

						old:setG("dealSpecialFlag", function(_self, record, attacker)
							local buff = _self.buff
							local canTakeEffect = false
							if not buff.csvCfg.specialVal then
								canTakeEffect = true
							else
								buff.protectedEnv = battleCsv.fillFuncEnv(buff.protectedEnv, {
									attacker = attacker,
								})
								canTakeEffect = buff:cfg2Value(buff.csvCfg.specialVal[1])
								buff.protectedEnv:resetEnv()
							end
							return canTakeEffect
						end)

						old:setG("getImmuneInfo", function(_self, immuneText, damageType)
							if _self.powerTime[immunePower.all] and _self.powerTime[immunePower.all] > 0  then
								return "allimmune"
							elseif damageType == battle.SkillDamageType.Physical
								and _self.powerTime[immunePower.physical]
								and _self.powerTime[immunePower.physical] > 0 then
								return battleEasy.ifElse(immuneText == "special" ,"allimmune" ,"physical")
							elseif damageType == battle.SkillDamageType.Special
								and _self.powerTime[immunePower.special]
								and _self.powerTime[immunePower.special] > 0 then
								return battleEasy.ifElse(immuneText == "physical" ,"allimmune" ,"special")
							end
						end)

						old:setG("powerTimeOrderPairs", function(_self)
							local idx, i = 1, 1
							return function()
								while i <= immunePower.buff do
									local data = _self.powerTime[i]
									idx = i
									i = i * 2
									if data then
										return idx, data
									end
								end
								return nil
							end
						end)
					end

					old.buff = buff
					old.powerTime = {} 	-- 各权限的次数
					old.allTime = 0 	-- 总次数
                    old.damageMap = {count = 0, data = {}}

					local power = immunePower.buff
					local immuneValue = args[1]
					while immuneValue ~= 0 do
						if immuneValue - power >= 0 then
							immuneValue = immuneValue - power
							old.powerTime[power] = (old.powerTime[power] or 0) + (args[2] or 1)
							old.allTime = old.allTime + old.powerTime[power]
						end
						power = math.floor(power / 2)
					end
					old.isForever = (args[2] == nil)
				end
			)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
		return true
	end,
	-- 免疫特殊攻击, 不受特殊攻击技能和带有特殊攻击伤害buff的影响
	['immuneSpecialDamage'] = function (buff, args, isOver)
		if not isOver then
			buff.holder.beInImmuneSpecialDamageState = buff.holder.beInImmuneSpecialDamageState and (buff.holder.beInImmuneSpecialDamageState + 1) or 1
		else
			buff.holder.beInImmuneSpecialDamageState = buff.holder.beInImmuneSpecialDamageState and (buff.holder.beInImmuneSpecialDamageState - 1) or 0
			buff.holder.beInImmuneSpecialDamageState = math.max(buff.holder.beInImmuneSpecialDamageState, 0)
		end
		return true
	end,
	-- 免疫所有攻击,非无敌 不受伤害影响, 仍然会被控制 (相当于免伤盾)
	['immuneAllDamage'] = function (buff, args, isOver)
		if not isOver then
			buff.holder.beInImmuneAllDamageState = buff.holder.beInImmuneAllDamageState and (buff.holder.beInImmuneAllDamageState + 1) or 1
		else
			buff.holder.beInImmuneAllDamageState = buff.holder.beInImmuneAllDamageState and (buff.holder.beInImmuneAllDamageState - 1) or 0
			buff.holder.beInImmuneAllDamageState = math.max(buff.holder.beInImmuneAllDamageState, 0)
		end
		return true
	end,
	-- 免疫能力弱化 不受任何降低自身属性值效果的影响
	-- 能力弱化的判断,只对属性有效,而且目前只针对在触发时生效的buff,buff自身生命周期结束时的自动清理不会进行判断
	['immuneAllAttrsDown'] = function (buff, args, isOver)
		if not isOver then
			buff.holder.beInImmuneAllAttrsDownState = buff.holder.beInImmuneAllAttrsDownState and (buff.holder.beInImmuneAllAttrsDownState + 1) or 1
		else
			buff.holder.beInImmuneAllAttrsDownState = buff.holder.beInImmuneAllAttrsDownState and (buff.holder.beInImmuneAllAttrsDownState - 1) or 0
			buff.holder.beInImmuneAllAttrsDownState = math.max(buff.holder.beInImmuneAllAttrsDownState, 0)
		end
		return true
	end,
	-- ToDo 需要整合,所有无法使用技能通过沉默实现,需要区分不同效果时通过buff的group
	-- 什么都不填 默认沉默大技能
	-- 沉默类型  只能使用普攻 true:关闭 false:开启
	['silence'] = function (buff, args, isOver)
		if not isOver then
			-- 关闭buffId和关闭buff类型独立开
			local data = {}
			local closeSkill = {}
			if buff.csvCfg.specialVal == nil then
				if args then
					local argsType = type(args)
					if argsType == "table" then
						for _,silenceSkillId in ipairs(args or {}) do
							closeSkill[silenceSkillId] = true
						end
					elseif argsType == "number" then
						closeSkill[args] = true
					end
				end
			else
				data = adjustSkillType2Data({
	                [battle.MainSkillType.SmallSkill] = true,
					[battle.MainSkillType.BigSkill] = true,
					[battle.MainSkillType.NormalSkill] = false,
				},buff.csvCfg.specialVal)
			end

			buff.holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.closeSkill = closeSkill
					old.closeSkillType2 = data
				end
			)
			-- onBuffEffectedLogicState
			-- buff.holder:addSkillType2Data(buff.cfgId,data)
		else
			-- buff.holder:removeSkillType2Data(buff.cfgId)
			buff.holder:deleteOverlaySpecBuff(buff)
		end

		-- buff.holder:onBuffEffectedLogicState(buff.csvCfg.easyEffectFunc,{
		-- 	isOver = isOver
		-- })
		return true
	end,
	-- 嘲讽/决斗类型  只能攻击嘲讽者, 且只能使用普攻 ?
	-- 嘲讽/决斗目标暂定只同时存在一个,默认不能同时存在多个
	['sneer'] = function (buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			local sneerAtMeObj = buff.caster
			if sneerAtMeObj:isAlreadyDead() then
				buff:overClean()
			else
				if args and type(args) ~= "table" then
					-- 特殊处理
					-- TODO:配表中原嘲讽value修改后移除
					args = {0,3,3}
				end
				buff.mode = args[1]
				holder:addOverlaySpecBuff(
					buff,
					function(old)
						old.buffID = buff.id
						old.mode = args[1]
						old.obj = buff.caster
						old.extraArg = {
							-- 波及参数
							spreadArg1 = args[2], -- 敌方
							spreadArg2 = args[3]  -- 己方
						}

						-- 不填specialVal 大小技能都无法使用
						if args[1] == battle.SneerType.Duel or (args[1] == battle.SneerType.Normal and not holder:isBeInDuel()) then
							local data = adjustSkillType2Data({
								[battle.MainSkillType.SmallSkill] = true,
								[battle.MainSkillType.BigSkill] = true,
								[battle.MainSkillType.NormalSkill] = false,
							},buff.csvCfg.specialVal)
							-- 因为嘲讽只能存在一个 所以用easyEffectFunc当做tag
							holder:addSkillType2Data(buff.csvCfg.easyEffectFunc,data)
						end
					end,
					function(a,b)
						return a.mode > b.mode
					end
				)
			end
		else
			holder:deleteOverlaySpecBuff(buff, function(old)
				holder:removeSkillType2Data(buff.csvCfg.easyEffectFunc)
				if old.mode == battle.SneerType.Duel then
					local sneerBuffId
					for _, data in holder:ipairsOverlaySpecBuffTo("sneer") do
						if data.mode == battle.SneerType.Normal then
							sneerBuffId = data.id
							break
						end
					end
					if sneerBuffId then
						for _,holderBuff in holder:iterBuffs() do
							if holderBuff.id == sneerBuffId then
								-- 重新加上普通嘲讽的
								local data = adjustSkillType2Data({
									[battle.MainSkillType.SmallSkill] = true,
									[battle.MainSkillType.BigSkill] = true,
									[battle.MainSkillType.NormalSkill] = false,
								},holderBuff.csvCfg.specialVal)
								-- 因为嘲讽只能存在一个 所以用easyEffectFunc当做tag
								holder:addSkillType2Data(holderBuff.csvCfg.easyEffectFunc,data)
								break
							end
						end
					end
				end
			end)
		end

		-- buff.holder:onBuffEffectedLogicState(buff.csvCfg.easyEffectFunc,{
		-- 	isOver = isOver
		-- })

		return true
	end,
	--混乱 有1/3概率攻击己方单位, 只有自己时失效  1/3可以在buffValue中设置
	-- 混乱需不需要设置只能同时存在一个 ？
	['confusion'] = function (buff, args, isOver)
		local holder = buff.holder
		local baseProb, needSelfForce
		if not args or type(args) == "number" then
			baseProb = args
		else
			baseProb = args[1]
			needSelfForce = args[2] == 1
		end
		local confusionProb = math.min(math.max(0,baseProb or 0.5),1)  -- 混乱概率
		if not isOver then
			local data = adjustSkillType2Data({
                [battle.MainSkillType.SmallSkill] = true,
				[battle.MainSkillType.BigSkill] = true,
				[battle.MainSkillType.NormalSkill] = false,
			},buff.csvCfg.specialVal)
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.prob = confusionProb
					old.closeSkillType2 = data
					old.needSelfForce = needSelfForce
				end
			)
		else
			holder:deleteOverlaySpecBuff(buff)
		end

		-- buff.holder:onBuffEffectedLogicState(buff.csvCfg.easyEffectFunc,{
		-- 	isOver = isOver
		-- })

		return true
	end,
	-- 复活  从假死状态中复活  args格式: {[1] = hp,[2] = mp,[3] = prob,[4] = cd,[5] = limit}
	['reborn'] = function (buff, args, isOver)
		local lifeRound = args[1]
		local isFastReborn = (lifeRound == 0) and true or false
		local priority = args[4] or 0
		if not isOver then
			buff.holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.isFastReborn = isFastReborn -- 1:快速复活 即死复活
					old.lifeRound = lifeRound
					old.buff = buff
					old.priority = priority
				end,
				function(a, b)
					-- 立死即活 > 低优先级的立死即活 > 非立死即活 > 低优先级的非立死即活
					if a.isFastReborn == b.isFastReborn then
						if a.priority == b.priority then
							return a.buff.id < b.buff.id
						else
							return a.priority > b.priority
						end
					else
						return a.isFastReborn
					end
				end
			)
			-- if not isFastReborn then
			-- 	buff.lifeRound = lifeRound -- 复活的生命周期都是99回合 具体几回合复活由参数控制
			-- end
		else
			if buff.holder:isRebornState() then
				buff.holder:resetRebornState(args[2] or 1,args[3] or 0)
				-- print("!!! buff_effect reborn",buff.holder.id,buff.cfgId)
			end
			buff.holder:deleteOverlaySpecBuff(buff)
		end
		return true
	end,
	-- 移出战场 即直接将目标杀死
	['removeObj'] = function (buff, args, isOver)
		if not isOver then
			local attacker = buff.caster
			buff.holder:setDead(attacker)
		end
		return true
	end,
	-- 队伍共享护盾  args格式: 填护盾的生命值,即护盾能抵消的伤害值
	-- ['teamShield'] = function (buff, args, isOver)
	-- 	local holder = buff.holder
	-- 	-- 向全队相关的记录中增加
	-- 	if not isOver then
	-- 		buff.scene.forceRecordTb[holder.force]['teamShield'] = buff.scene.forceRecordTb[holder.force]['teamShield'] or {}
	-- 		buff.scene.forceRecordTb[holder.force]['teamShield'].from = buff 		-- 记录来源
	-- 		buff.scene.forceRecordTb[holder.force]['teamShield'].hp = args		-- 记录值
	-- 		buff.scene.forceRecordTb[holder.force]['maxShield'] = args
	-- 	else	-- buff结束时,直接清理掉这个记录,这里默认了这种记录就是只有一种的
	-- 		buff.scene.forceRecordTb[holder.force]['maxShield'] = nil
	-- 		buff.scene.forceRecordTb[holder.force]['teamShield'] = nil
	-- 	end
	-- 	buff.holder:refreshTeamShield(holder.force)
	-- 	return true
	-- end,
	-- 触发buff改变天气
	["weather"] = function (buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			buff.weatherCfgId = args
			holder:addOverlaySpecBuff(buff,function(old) end)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
		return true
	end,
	--致命
	["fatal"] = function (buff, args, isOver)
		if not isOver then
			buff.holder.fatalBuff = {limit = args[1], val = args[2]}
		else
			buff.holder.fatalBuff = nil
		end
		return true
	end,
	--斩杀
	["behead"] = function (buff, args, isOver)
		if not isOver then
			buff.holder.beheadBuff = {limit = args[1], val = args[2]}
		else
			buff.holder.beheadBuff = nil
		end
		return true
	end,
	--最终伤害受血量越低伤害越高buff
	["damageByHpRate"] = function (buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			--max(rate,maxRate)*rateAdd
			local _selectTargetTab = {false,false}
			_selectTargetTab[(args[1] or 1)] = true
			holder.damageByHpRateBuff = {
				rateMax = args[3] or 1,
				rateAdd = args[2] or 1,
				selectTargetTab = _selectTargetTab,
				rateFunc = function(self,target,index)
					if self.selectTargetTab[index] then
						local rate = (target:hpMax()-target:hp())/target:hpMax()
						return math.min(rate,self.rateMax)*self.rateAdd*100
					end
					return 0
				end
			}
		else
			holder.damageByHpRateBuff = nil
		end
		return true
	end,
	--免控概率百分比提升
	["immuneControlAdd"] = function (buff, args, isOver)
		controlOrImmuneBuff(buff, args, isOver)
		return true
	end,
	--控制概率百分比提升
	["controlPerAdd"] = function (buff, args, isOver)
		controlOrImmuneBuff(buff, args, isOver)
		return true
	end,
	--免控概率值提升
	["immuneControlVal"] = function (buff, args, isOver)
		if args and type(args) == "number" then
			args = args / ConstSaltNumbers.wan
		end
		controlOrImmuneBuff(buff, args, isOver)
		return true
	end,
	--控制概率值提升
	["controlPerVal"] = function (buff, args, isOver)
		if args and type(args) == "number" then
			args = args / ConstSaltNumbers.wan
		end
		controlOrImmuneBuff(buff, args, isOver)
		return true
	end,
	--溢出伤害 addHp逻辑
	["damageCapped"] = function (buff, args, isOver)
		local holder = buff.holder
		local attacker = buff.caster
		local skill = attacker.curSkill
		if isOver then
			local _buff = attacker.damageCappedBuff
			if attacker.damageCappedBuff then
				if holder:isDeath() == false then
					local damage = _buff.damage
					local rate = _buff.args[_buff.index]
					local damageArgs = {
						from = battle.DamageFrom.buff, --表示是来自buff的直接伤害,非技能类型,可能后续用来判断是否触发其它效果
						skillDamageType = battle.SkillDamageType.Special,
						isLastDamageSeg = true,
						isBeginDamageSeg = true
					}
					local switchToPlay05 = gRootViewProxy:proxy():pushDeferList(skill.id, 'switchToPlay05')
					buff.holder:beAttack(attacker, damage*rate, 5, damageArgs)--当做最后一个过程段处理
					--溢出伤害算入技能的总伤害中
                    if attacker and skill and skill.isSpellTo and skill.owner.id ~= holder.id then
                        battleEasy.deferNotify(nil, 'showNumber', {delta = math.floor(damage), skillId = skill.id, typ = "damage"})
					end
					local t = gRootViewProxy:proxy():popDeferList(switchToPlay05)
					if skill then
						skill:pushDefreListToSkillEnd('skillEndDeleteDeadObjs',t)
						if holder:isDeath() then
							table.insert(attacker.curSkill.killedTargetsTb, buff.holder)
						end
					end
					attacker.damageCappedBuff.index = attacker.damageCappedBuff.index + 1
				end
				if attacker.damageCappedBuff.index > table.length(_buff.args) then attacker.damageCappedBuff = nil end
			end
		else
			if holder:isDeath() then
				attacker.damageCappedBuff = { damage = math.abs(holder.hpTable[3]) ,index = 1,args = args }
			end
		end
		return true
	end,
	-- 伤害分摊
	-- args[1] 分摊比例 填-1全员平分  否则自己承受(1-rate)的伤害 剩余其他人平分
	-- args[2] 分摊单位
	-- args[3] damage_process id
	-- args[4] 触发优先级 默认值10 越大越先触发
	-- 两个分摊buff, A的优先级小于B(不包括相等), 则A可以继续分摊来自于B的伤害
	["damageAllocate"] = function (buff, args, isOver)
		local holder = buff.holder
		local cfgId = buff.cfgId
		if not isOver then

			--local map = buff.scene:getHerosMap(holder.force)
			local targets = buff:getObjectsByCfg(args[2])
			--这里用id而不是target 因为可能到时候有死人补人之类的逻辑 造成同个id的obj其实不是一个
			local targetIds = {}
			for _,obj in ipairs(targets) do
				table.insert(targetIds,obj.id)
			end
			holder:addOverlaySpecBuff(buff, function(old)
				old.rate = args[1]
				old.targetIds = targetIds
				old.damageMode = args[3] or 1
				old.priority = args[4] or 10
				old.getNewTargetIds = function()
					local objs = buff:getObjectsByCfg(args[2])
					local ret = {}
					for _,obj in ipairs(objs) do
						table.insert(ret,obj.id)
					end
					return ret
				end
				old.targetIdsList = {}
			end,
			function(a,b)
				if a.priority == b.priority then
					return a.id < b.id
				else
					return a.priority > b.priority
				end
			end)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
		return true
	end,
	-- 伤害链接
	["damageLink"] = function (buff, args, isOver)
		local holder = buff.holder
		local objId = holder.id
		local cfgId = buff.cfgId
		if not isOver then
			local value = buff:cfg2Value(args[1])
			--0:可以主动传递,可以被传递 1:不能主动传递,可以被传递 2:可以主动传递,不能被传递
			local oneWayKey = args[2]
			-- 1:只有相同caster的才能链接 其它:args[3] ~= 1都能链接
			local casterId = args[3] == 1 and buff.caster.id or nil
			buff.scene.buffGlobalManager:setDamageLinkRecord(objId,cfgId,value,oneWayKey,casterId)
			if not holder.damageLinkBuff then
				holder.damageLinkBuff = {}
			end
			if not itertools.include(holder.damageLinkBuff,cfgId) then
				table.insert(holder.damageLinkBuff,cfgId)
			end
		else
			buff.scene.buffGlobalManager:cleanDamageLinkRecord(objId,cfgId)
			local idx
			for k,v in ipairs(holder.damageLinkBuff) do
				if v == cfgId then
					idx = k
					break
				end
			end
			table.remove(holder.damageLinkBuff,idx)
		end
	end,
	--改变形象 单纯改变形象，不能攻击，类似眩晕
	["changeImage"] = function(buff, args, isOver)
		if not isOver then
			buff.holder.scene:addObjViewToBattleTurn(buff.holder,'addBuffHolderAction',buff.id,"changeImage",args)
			buff.holder:addOverlaySpecBuff(buff,function(old) end)
		else
			buff.holder.scene:addObjViewToBattleTurn(buff.holder,'delBuffHolderAction',buff.id,"changeImage")
			buff.holder:deleteOverlaySpecBuff(buff)
		end
		return true
	end,
	--转变为固定Unit 属性技能等级继承原来的，能攻击
	["changeUnit"] = function(buff, args, isOver)
		local needReloadUnit = true
		local needReloadSkill = true
		if not isOver then
			table.insert(buff.holder.changeUnitIDTb, {buff.id, args, true})
            buff:setValue(buff.holder.unitID)
			initChangeUnitFunc(buff, args)
			initChangeSkillFunc(buff, args)
			buff.holder.scene:addObjViewToBattleTurn(buff.holder,'SortReloadUnit', {buffId = buff.id, isRestore = isOver})
			logf.battle.object.changeImage(" seat:%d changeUnit 变身后unitid:%d",buff.holder.seat,buff.holder.unitID)
		else
			-- 检测并获得形象变回去需要的unitID
			local oldUnitId = type(buff.value) == "table" and buff.value[1] or buff.value
			needReloadUnit, oldUnitId, needReloadSkill = getChangeUnitIdFunc(buff, oldUnitId)
			if needReloadUnit then
				initChangeUnitFunc(buff, oldUnitId, true)
			end
			if needReloadSkill then
				if buff.holder.curSkill and not buff.holder.curSkill.isSpellTo then
					buff.holder.curSkill = nil
				end
				initChangeSkillFunc(buff, oldUnitId, true)
			end
			buff.holder.scene:addObjViewToBattleTurn(buff.holder,'SortReloadUnit', {buffId = buff.id, isRestore = isOver})
			-- buff.holder.changedAndCanUseMainSkillOnce = nil
		end
		return true
	end,
	--转变成敌方某个单位
	["changeToRandEnemyObj"] = function(buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			local targets = buff:getObjectsByCfg(args[1])
			local enemyObj
			if targets and next(targets) then
				local seat = ymrand.random(1, table.length(targets))
				enemyObj = targets[seat]
			else
				return true
			end
			table.insert(buff.holder.changeUnitIDTb, {buff.id, enemyObj.unitID, true})
			if enemyObj.unitID == buff.holder.unitID then
				return true
			end
			logf.battle.object.changeImage(" seat:%d changeToRandEnemyObj 变身后unitid:%d",buff.holder.seat,buff.holder.unitID)
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.changeUnitBuffs = {}
					old.oldUnitCfg = buff.holder.unitCfg
				end
			)
            buff:setValue({buff.holder.unitID,args[2]})
			initChangeUnitFunc(buff, enemyObj.unitID, false, enemyObj.skillInfo, args)
			initChangeSkillFunc(buff, enemyObj.unitID, false, enemyObj.skillInfo, args)
			buff.holder.scene:addObjViewToBattleTurn(buff.holder,'SortReloadUnit', {buffId = buff.id, isRestore = isOver})
			-- battleEasy.queueEffect(function()
			-- 	battleEasy.queueNotifyFor(buff.holder.view, 'reloadUnit')
			-- end)
		else
            -- 没找到目标 无法变身
            if next(buff.holder.changeUnitIDTb) then
				buff:setValue({buff.holder.unitID,args[2]})
				local isReborn = buff.holder.state == battle.ObjectState.dead and buff.holder:canReborn()
			    BuffEffectFuncTb["changeUnit"](buff, nil, true)
				local changeToEnemyData = holder:getOverlaySpecBuffByIdx("changeToRandEnemyObj")
				for _, buff2 in buff.holder:iterBuffs() do
					if changeToEnemyData and itertools.include(changeToEnemyData.changeUnitBuffs, buff2.id)
						and (not isReborn or buff2.csvCfg.easyEffectFunc ~= 'reborn') then
						-- buff2:over({endType = battle.BuffOverType.overlay})
						buff2:overClean()
				    end
			    end
				holder:deleteOverlaySpecBuff(buff)
            end
		end
		return true
	end,
	--转变为多形态卡牌的其他形态
	["changeShape"] = function(buff, args, isOver)
		-- 记录下当前形态小技能的cd
		local function getSmallSkill()
			for _, skill in buff.holder:iterSkills() do
				if skill.skillType2 == battle.MainSkillType.SmallSkill then
					return skill
				end
			end
		end

		if buff.holder.multiShapeTb then
			local multiShapeState = buff.holder.multiShapeTb[1]
			local smallSkill = getSmallSkill()
			if smallSkill and smallSkill:getLeftCDRound() > 0 then
				buff.holder.multiShapeTb[2][multiShapeState] = smallSkill:getLeftCDRound() - 1
			end
		end
		-- 变形态过程
		BuffEffectFuncTb["changeUnit"](buff, args, isOver)

		if buff.holder.multiShapeTb then
			buff.holder.multiShapeTb[1] = 3 - buff.holder.multiShapeTb[1]

			-- 调整属性状态开关
			if not isOver and buff.csvCfg.specialVal and buff.csvCfg.specialVal[2] then
				for _, attr in ipairs(buff.csvCfg.specialVal[2]) do
					buff.holder.multiShapeTb[3][attr] = true
				end
			end

			-- 给当前形态重置spellRound
			local smallSkill = getSmallSkill()
			if smallSkill then
				local curMultiShapeState = buff.holder.multiShapeTb[1]
				if buff.holder.multiShapeTb[2][curMultiShapeState] then
					-- 设置spellRound为当前回合数减去记录剩下的回合数
					smallSkill.spellRound = buff.holder:getBattleRound(2) - (smallSkill.cdRound - buff.holder.multiShapeTb[2][curMultiShapeState])
				end
			end
		end
	end,
	--伤害回血
	['selfDamageToHpRate'] = function(buff, args, isOver)
		if not isOver then
			local rate = args
			local holderSkill = buff.objThatTriggeringMeNow
			local holder = buff.holder
			local addHpVal = 0
			local specialArgs = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]
			local resumeArgs = {
				from = battle.ResumeHpFrom.buff,
				ignoreBeHealAddRate = true
			}

			holder.lastRealTotalDamage = holder.lastRealTotalDamage or 0
			if holderSkill:isNormalSkillType() then
				local totalDamage = 0
				for _,v in holderSkill:pairsTargetsFinalResult(battle.SkillSegType.damage) do
					totalDamage = totalDamage + v.real:get(battle.ValueType.normal)
				end
				holder.lastRealTotalDamage = totalDamage
			end

			if specialArgs then
				resumeArgs.ignoreLockResume = battleEasy.ifElse(specialArgs.ignoreLockResume,specialArgs.ignoreLockResume,resumeArgs.ignoreLockResume)
				resumeArgs.ignoreBeHealAddRate = battleEasy.ifElse(specialArgs.ignoreBeHealAddRate,specialArgs.ignoreBeHealAddRate,resumeArgs.ignoreBeHealAddRate)
			end

			addHpVal = holder.lastRealTotalDamage
			if rate then
				addHpVal = addHpVal * rate
			end

			if addHpVal ~= 0 then
				if not (specialArgs and specialArgs.ignoreToDamage) and holder:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.healTodamage) then
					holder:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.healTodamage, "doBuffDamage", attacker, holder, addHpVal, buff.cfgId)
				else
					holder:resumeHp(holder,math.floor(addHpVal),resumeArgs)
				end
			end
		end
		return true
	end,
	-- --无视免伤
	-- ['ignoreDamageSub'] = function(buff, args, isOver)
	-- 	local holder = buff.holder
	-- 	local rate = (not isOver) and 1 or -1
	-- 	args = args or 1
	-- 	holder.ignoreDamageSubBuff = holder.ignoreDamageSubBuff or { rate = 0 }
	-- 	holder.ignoreDamageSubBuff.rate = holder.ignoreDamageSubBuff.rate + rate*args
	-- 	return true
	-- end,
	-- --无视抗暴击
	-- ['ignoreStrikeResistance'] = function(buff, args, isOver)
	-- 	local holder = buff.holder
	-- 	local rate = (not isOver) and 1 or -1
	-- 	args = args or 1
	-- 	holder.ignoreStrikeResistanceBuff = holder.ignoreStrikeResistanceBuff or { rate = 0 }
	-- 	holder.ignoreStrikeResistanceBuff.rate = holder.ignoreStrikeResistanceBuff.rate + rate*args
	-- 	return true
	-- end,
	--其他buff效果增益/减益
	['otherBuffEnhance'] = function(buff, args, isOver)
		local group = args[1]
		local percent = args[2]
		local holder = buff.holder
		-- 第三个控制参数默认值为1
		args[3] = args[3] or 1
		if not isOver then
			if args[3] == 1 then
				for k,v in ipairs(group) do
					holder:addBuffEnhance(v,buff.cfgId,percent, args[3])
				end
			elseif args[3] == 2 then
				-- 对所有buff, 在takeeffect生效
				for k, v in ipairs(group) do
					holder:addBuffEnhance(v,buff.cfgId,percent, args[3])
					for _, haveBuff in holder:iterBuffs() do
						if haveBuff.isNumberType and haveBuff:group() == v then
							haveBuff:refreshLerpValue()
						end
					end
				end
			end
			-- 刷新一遍存在的buff的value
			-- for _, buff in holder:iterBuffs() do
			-- 	buff.value = buff:getValue()
			-- end
		else
			if args[3] == 1 or args[3] == 2 then
				for k,v in ipairs(group) do
					holder:delBuffEnhance(v,buff.cfgId, args[3])
					if args[3] == 2 then
						for _, haveBuff in holder:iterBuffs() do
							if haveBuff.isNumberType and haveBuff:group() == v then
								haveBuff:refreshLerpValue()
							end
						end
					end
				end
			end
		end
	end,
	--保持血量不变 即受到致命伤害时，有概率免疫本次伤害
	--@params args int 触发次数
	['keepHpUnChanged'] = function(buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.triggerTime = args[1]
					old.prob = args[2]
				end
			)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
		return true
	end,
	--更新技能冷却相关的buff
	['updSkillSpellRoundOnce'] = function(buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			for _, skill in holder:iterSkills() do
				if skill.skillType2 == battle.MainSkillType.SmallSkill then
					--可能有多个同类型技能
					local isSelfTurn = false
					local curHero = holder.scene.play.curHero
					if curHero then
						isSelfTurn = (curHero.id == holder.id)
					end
					local extraBattleRound = isSelfTurn and -1 or 0
					if skill.spellRound == -99 then
						skill.spellRound = holder:getBattleRound(2) - skill.cdRound + extraBattleRound
					end
					skill.spellRound = skill.spellRound - args
				end
			end
		end
		return true
	end,
	['lockHp'] = function(buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			buff.buffValue[1] = buff.buffValue[1] or 1
			buff:setValue(buff.buffValue)
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.buff = buff
					-- old.buffID = buff.id
					old:bind("triggerTime",1)
					-- old.triggerTime = args[1]
					old.triggerEndRound = args[2]
					--mode为0时只有伤害超过hp上限才触发 mode为1时忽略这一伤害的数值 直接触发
					--mode为2时每次伤害上限为一个固定的值
					old.mode = args[3]
					old.extraArg = args[4]
					old.priority = args[5] or 0
					-- TODO: 是否可以直接加上剩余次数的判断条件
					old.isPreDelete = false -- 代表即将要被删除, 防止连锁触发时锁血的状态还会生效
					if old.mode ~= 1 then
						-- 针对触发锁血时不是最后一段造成的影响
						-- 水龙+锁血时无法触发隐匿，锁血不是在最后表现分段触发
						old.damageMap = {}
					end
					-- 策划配置specialVal
					old.checkCondition = function(_self, attacker)
						local canTakeEffect = false
						if not buff.csvCfg.specialVal then
							canTakeEffect = true
						else
							buff.protectedEnv = battleCsv.fillFuncEnv(buff.protectedEnv, {
								attacker = attacker,
							})
							canTakeEffect = buff:cfg2Value(buff.csvCfg.specialVal[1])
							buff.protectedEnv:resetEnv()
						end
						return canTakeEffect
					end
				end,
				function(a,b)
					if a.priority == b.priority then
						if a.mode == b.mode then
							return a.buff.id < b.buff.id
						else
							return a.mode > b.mode
						end
					else
						return a.priority > b.priority
					end
				end
			)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
		return true
	end,
	--复制buff 将这个buff的holder身上的属于某些buff组的buff,复制给其他目标  buffvalue1:buffGroup填buff组s, holder填目标类型{{12,13,14},2}, specialval填复制buffs的共用回合数
	-- args[1]:表示buff组，args[2]:表示目标类型
	['copyCasterBuffsToHolder'] = function(buff, args, isOver)
		if not isOver then
			copyOrTransferBuff(buff, args, false,false)
		end
		return true
	end,
	--转移buff  将该buff的holder身上某些组类型的buff转移给其它目标(buff组类型填在buffValue1中,specialVal 填回合数) buffValue1:{{12,13,14},{1,2}}
	-- args[1]:表示buff组，args[2]:表示目标类型
	['transferBuffToOther'] = function(buff, args, isOver)
		if not isOver then
			copyOrTransferBuff(buff, args, true,false)
		end
		return true
	end,
	-- 全体单位当中的的随机若干个buff转移复制到确定目标 配置方式跟上面类似
	['copyForceBuffsToOther'] = function(buff, args, isOver)
		if not isOver then
			copyOrTransferBuff(buff, args, false,true)
		end
		return true
	end,
	--buff在几个回合不能被驱散 buffValue1填不能被驱散的buff组 <list(buffGroupId,buffGroupId,buffGroupId)> specialVal 填不能被驱散回合数 <2>
	['cantDispelBuffRound'] = function(buff, args, isOver)
		if not isOver then
			buff.holder.cantDispelTb = {buffGroupTb = arraytools.hash(args), buffRound = buff.csvCfg.specialVal[1]}
		else
			buff.holder.cantDispelTb = nil
		end
	end,
	-- 先手/后手
	-- @params args <bool(0,1), buff检测> 是否为先手
    -- @params specialVal int 阵营 <1> 同阵营 <2> 不同阵营 <3> 全阵营
	['changeSpeedPriority'] = function(buff, args, isOver)
        local isSameForce = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]
        local gate = buff.holder.scene.play
		if not isOver then
			if isSameForce == 1 then
				local buffCheck = function(buffid)
					if not args[2] then
						return true
					end
					return buffid == args[2]
				end
				table.insert(gate.speedSortRule,{
					id = buff.id,
					sort = function(tbForSort)
						local objId = buff.scene.play:getObjectBaseSpeedRankSortKey(buff.holder)
						local delId,insertId
						for k,v in ipairs(tbForSort) do
							if v.objId == objId and buffCheck(v.buffCfgId) then
								delId = delId or k
							elseif v.force == buff.holder.force then
								if args[1] == 1 then
									insertId = insertId or math.max(1, delId and k-1 or k)
								else
									insertId = math.min(table.length(tbForSort),delId and k or k+1)
								end
							end
						end
						if delId and insertId then
							local data = table.remove(tbForSort,delId)
							table.insert(tbForSort,insertId,data)
						end
					end,
				})
			else
				local func = function(force,arg,val)
					-- 需求敌方阵营时己方阵营不需要计算
					if buff.csvCfg.specialVal and (isSameForce == 2 and force == buff.holder.force) then
						return val
					end
					local objs = buff.scene:getHerosMap(force)
					local _val = val
					for _,obj in objs:order_pairs() do
						_val = _val or obj.speedPriority
						_val = arg == 1 and math.max(_val,obj.speedPriority) or math.min(_val,obj.speedPriority)
					end
					return _val
				end

				local priority = func(1,args[1],nil)
				priority = func(2,args[1],priority)

				buff.holder.speedPriority = priority + args[1]
            end
		else
			if isSameForce == 1 then
				for k,v in ipairs(gate.speedSortRule) do
					if v.id == buff.id then
						table.remove(gate.speedSortRule,k)
						return
					end
				end
			else
				buff.holder.speedPriority = 0
            end
		end
	end,
	-- 重置战斗回合
	['resetBattleRound'] = function(buff, args, isOver)
		if not isOver then
			local holder = buff.holder
			local data = {obj = holder, reset = buff.id, buffCfgId = buff.cfgId}
			data.mode = battle.ExtraBattleRoundMode.reset
			battleEasy.resetGateAttackRecord(holder, data)
		end
	end,
	-- 立即获得一个额外行动回合
	['atOnceBattleRound'] = function(buff,args,isOver)
		if not isOver then
			local holder = buff.holder
			local data = {obj = holder, atOnce = buff.id, buffCfgId = buff.cfgId}
			data.mode = battle.ExtraBattleRoundMode.atOnce
			battleEasy.resetGateAttackRecord(holder, data)
		end
	end,
	-- 双子额外行动回合
	['geminiBattleRound'] = function(buff, args, isOver)
		if not isOver then
			local holder = buff.holder
			local data = {obj = holder, buffCfgId = buff.cfgId, another = true}
			data.mode = battle.ExtraBattleRoundMode.gemini
			battleEasy.resetGateAttackRecord(holder, data)
		end
	end,
	-- 隐身：1.隐身状态下无法被技能选中  2.释放可添加buff可配置
	['stealth'] = function(buff,args,isOver)
		local holder = buff.holder
		if not isOver then
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.cantBeAttackSwitch = (args[1] == 0) -- 0: 无法被波及
					old.cantBeAddBuffSwitch = (args[2] == 0) --0: 无法加上buff
					old.cantBeHealHintSwitch = (args[3] == 0) -- 0: 无法被治疗指示器选中
					-- old.cantBeBuffSelectType = args[2] --1: 可以找到己方的隐身目标, 找不到敌方的隐身目标
				end,nil
			)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
	end,
	-- 无视buff
	['ignoreSpecBuff'] = function(buff,args,isOver)
		local holder = buff.holder
		if not isOver then
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.cfgIds = itertools.map( args or {},function(k,v) return v,true end)
					old.specBuffList = itertools.map( buff.csvCfg.specialVal or {},function(k,v) return v,true end)
				end,nil
			)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
	end,
	-- 离场 无法选择为目标 无法行动 无法被攻击
	['leave']  = function(buff,args,isOver)
		if type(args) == "number" then
			args = {args}
		end
		local holder = buff.holder
		if not isOver then
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.canAttack = args and (args[1] == 0) -- 0: 能出手
				end,nil
			)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
		holder:onFieldStateChange(isOver)
		-- 可以替换状态

		-- -- 隐性的状态 只有功能生效的 但是状态不生效
		-- buff.holder:onBuffEffectedLogicState(buff.csvCfg.easyEffectFunc,{
		-- 	isOver = isOver
		-- })
	end,
	-- 新离场
	['depart']  = function(buff,args,isOver)
		local holder = buff.holder
		if not isOver then
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.cantBeAttackSwitch = (args[1] == 0) -- 0: 无法被波及
					old.cantBeAddBuffSwitch = (args[2] == 0) --0: 无法加上buff
					old.cantBeHealHintSwitch = (args[3] == 0) -- 0: 无法被治疗指示器选中
					old.leaveSwitch = (args[4] == 0) -- 0: 不能给其他人加buff 不能被其他人加buff 光环不能生效
					old.canAttack = (args[5] == 0) -- 0: 能出手
					old.canProtect = (args[6] == 0) -- 0: 能保护
				end,nil
			)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
		if args[4] == 0 then
			holder:onFieldStateChange(isOver)
		end
	end,
	-- buff链接
	["bufflink"] = function(buff,args,isOver)
		local holder = buff.holder
		local fixValue = args[1]
		local groups = args[2]
		local targets = buff:getObjectsByCfg(args[3])
		local targetIds = {}
		for _,obj in ipairs(targets) do
			table.insert(targetIds,obj.id)
		end
		if not isOver then
			for _,v in ipairs(targetIds) do
				buff.scene.buffGlobalManager:setBuffLinkValue(holder.id,v,fixValue,groups,buff.cfgId)
			end
		else
			buff.scene.buffGlobalManager:onBuffLinkOver(buff.cfgId)
		end
		return true
	end,
	--重置buff的生命周期  刷新多个buff或者多个buff组内的buff的回合数  bufValue： <list(buffid, round, isGroup),list(...),list(...)>
	--buffTb[1]: buffId or buffGroup; buffTb[2]:替换回合数; buffTb[3]: 表示填1表示刷新buff组 不填就表示刷新buffid
	--目前buffGroup的lifeRound 策划不能用公式去配置 原因是因为doFormula 解析不出来 {num, tb , num}中的tb
	['refreshBuffLifeRound'] = function(buff, args, isOver)
		if not isOver then
			for _, buffTb in ipairs(args) do
				local buffRound = buffTb[2]
				local buffLifeRound
				if buffTb[3] then
					local buffGroupId = buffTb[1]		--记录buff组id
					for _, curBuff in buff.holder:iterBuffs() do
						if curBuff:group() == buffGroupId then
							buffLifeRound = type(buffRound) == "table" and buffRound[curBuff.cfgId] or buffRound
							curBuff.lifeRound = buffLifeRound
						end
					end
				else
					for _, targetBuff in buff.holder:iterBuffs() do
						if targetBuff.cfgId == buffTb[1] then
							targetBuff.lifeRound = buffRound
						end
					end
				end
			end
		end
		return true
	end,
	--增加buff生命周期 增加多个buff或者多个buff组内的存在的buff的生命周期 可以累加 1个buff只有1种类型
	--args[1]:list(id1,id2...)
	--args[2]:增加或减少回合数;
	--args[3]: 表示填1表示刷新buff组 不填就表示刷新buffid
	-- 对buff做一次性修改(不还原), 新增buff根据当前buff数据修改
	['changeBuffLifeRound'] = function(buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			local gourpTb = {}
			local buffIdTb = {}
			local buffRound = buff:cfg2Value(args[2]) --回合数支持公式配置
			local tmp = buffIdTb
			if args[3] then
				tmp = gourpTb
			end
			for _, id in ipairs(args[1]) do
				tmp[id] = buffRound
			end
			for _, curBuff in holder:iterBuffs() do
				local extraLifeRound = gourpTb[curBuff:group()] or buffIdTb[curBuff.cfgId]
				if extraLifeRound then
					curBuff.lifeRound = curBuff.lifeRound + extraLifeRound
					if curBuff.lifeRound <= 0 then
						curBuff:over()
					end
				end
			end
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.gourpTb = gourpTb
					old.buffIdTb = buffIdTb
					old.getExtraRound = function(groupId, cfgId)
						return old.gourpTb[groupId] or old.buffIdTb[cfgId] or 0
					end
				end, nil
			)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
		return true
	end,
	--溢出怒气保存 策划配置  1. 转换比例 2.怒气点个数上限 对应怒气条上的怒气点特效 3.大招放完重置 4.策划需要一个获取实时怒气点个数的公式配置
	-- 获取buff.holder 身上的怒气值 判断是否溢出, 溢出的部分按比例转换成怒气点 怒气点的上限由策划配置
	['mp1OverFlow'] = function(buff, args, isOver)
		local holder = buff.holder

		if not isOver then
			-- 已经溢出的怒气
			local mpOverflow = math.max(buff.holder:mp1() - buff.holder:mp1Max(), 0)
			local mode = args[1]
			local overFlowMax = args[3]
			if mode == 1 then
				-- 怒气点的上限通过计算得到
				overFlowMax = args[2] * overFlowMax
			end

			holder.mp1Table[3] = cc.clampf(mpOverflow, 0, overFlowMax)

			local extraArgs = {
				-- 蓄力时是否先改变溢出怒气
				changeMpOverflowInCharge = false,
				-- 蓄力时溢出怒气改变后是否影响普通怒气
				affectNormalMpInCharge = false,
				-- 通过buff修改溢出怒气是否影响普通怒气
				affectNormalMpFromBuff = false
			}
			local specialArgs = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or {}
			if specialArgs then
				extraArgs.changeMpOverflowInCharge = battleEasy.ifElse(specialArgs.changeMpOverflowInCharge,specialArgs.changeMpOverflowInCharge,extraArgs.changeMpOverflowInCharge)
				extraArgs.affectNormalMpInCharge = battleEasy.ifElse(specialArgs.affectNormalMpInCharge,specialArgs.affectNormalMpInCharge,extraArgs.affectNormalMpInCharge)
				extraArgs.affectNormalMpFromBuff = battleEasy.ifElse(specialArgs.affectNormalMpFromBuff,specialArgs.affectNormalMpFromBuff,extraArgs.affectNormalMpFromBuff)
			end

			holder:addOverlaySpecBuff(
				buff,
				function(old)
					-- 1:怒气点模式 2:怒气值(优先减少普通怒气) 3:怒气值(优先减少溢出怒气)
					old.mode = mode
					-- 转换怒气比例（怒气点模式下是转换成怒气点的比例，其他模式是一处怒气实际转化比例）
					old.rate = args[2]
					-- 怒气上限（怒气点模式下是怒气点的上限，其他模式是怒气值上限）
					old.limit = mode == 1 and args[2] * args[3] or args[3]
					-- 大招是否消耗怒气点数
					old.cost = args[4]
					old.extraArgs = extraArgs
				end,nil
			)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
		return true
	end,
	-- 伤害计算护甲取最小值 1:最低 2:最高
	['calDmgKeepDefence']  = function(buff,args,isOver)
		if not isOver then
            if args == 1 then
                buff.holder.calDmgKeepDefenceBuff = function(def1,def2)
                    return math.min(def1,def2)
                end
            else
                buff.holder.calDmgKeepDefenceBuff = function(def1,def2)
                    return math.max(def1,def2)
                end
            end
		else
			buff.holder.calDmgKeepDefenceBuff = nil
		end
	end,
	-- 致死
	['kill']  = function(buff,args,isOver)
		if not isOver then
			local specialVal = buff.csvCfg.specialVal
			local buffDamageArgs = {
				from = battle.DamageFrom.buff,	--表示是来自buff的直接伤害,非技能类型,可能后续用来判断是否触发其它效果
				isLastDamageSeg = true,
				isBeginDamageSeg = true,
				hideHeadNumber = specialVal and specialVal[1]
			}
			-- if buff.csvCfg.isShow then
			-- 	battleEasy.deferNotify(buff.holder.view, "showHeadNumber", {typ=0, num=buff.holder:hp(), args={}})
			-- end
			-- 9 秒杀特殊id
			buff.holder:beAttack(buff.caster, math.ceil(buff.holder:hp()), battle.JumpAllDamageProcessId, buffDamageArgs)
			buff:over()
		end
	end,
	-- 反击 此处为开关 不涉及实际逻辑
	['counterAttack'] = function(buff,args,isOver)
		local holder = buff.holder
		if not isOver then
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.triggerSkillType2 = args[1] -- 权重组, 普攻配置<1,0,0>
					old.triggerSkillType = type(args[1])
					old.rate = args[2]
					old.find = functools.partial(buff.getObjectsByCfg, buff, (buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1]) or 1)
					old.costType = args[3] or 0 -- 消耗类型 0: 正常 1: 忽略cd,mp
					old.mustEnemy = (args[4] == 1) -- 必须是敌方攻击 1:是
				end,nil
			)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
	end,
	-- 连击 同样是开关
	['comboAttack'] = function(buff,args,isOver)
		if not isOver then
			buff.holder.comboAttackInfo = {rate = args[1]}
		else
			buff.holder.comboAttackInfo = nil
		end
	end,
	-- 可以选择目标,但是出手无效
	['canelToAttack'] = function(buff,args,isOver)
		if not isOver then
			buff.holder.ignoreToAttack = true
		else
			buff.holder.ignoreToAttack = false
		end
	end,
	--协战/邀战 1:协战 2:邀战
	--触发条件都是在发动攻击时
	['syncAttack'] = function(buff,args,isOver)
		local holder = buff.holder
		local isSyncAttack = buff.csvCfg.easyEffectFunc == 'syncAttack'

		local checkFunc = function(checkSkillType2,skillType2)
			if checkSkillType2 then
				for k,v in ipairs(checkSkillType2) do
					if v == skillType2 then return true end
				end
			end
            return not checkSkillType2
        end
		if not isOver then
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.triggerSkillType2 = args[1] -- 权重组, 普攻配置<1,0,0>
					old.triggerSkillType = type(args[1])
					old.rate = args[2]
					old.isTrigger = functools.partial(checkFunc,buff.csvCfg.specialVal)
					old.find = functools.partial(buff.getObjectsByCfg,buff, buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1]) -- 获取邀请目标
					old.costType = args[3] or 0 -- 消耗类型 0: 正常 1: 忽略cd,mp
					old.isFixedForce = args[4] == 1 or false -- 是否固定目标阵营 1：固定目标阵营
				end,nil
			)

		else
			holder:deleteOverlaySpecBuff(buff)
		end
	end,
	-- 新协战
	['assistAttack'] = function(buff,args,isOver)
		if not isOver then
			local holder = buff.holder
			local targetCfg = buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1]
			local target = targetCfg and buff:getObjectsByCfg(targetCfg)
			local data = {
				triggerSkillType2 = args[1],  -- 权重组 普攻配置<1,0,0>
				triggerSkillType = type(args[1]),
				rate = args[2],
				costType = args[3] or 0  -- 消耗类型 0: 正常 1: 忽略cd,mp
			}
			holder:onAssistAttack(target and target[1], data)
		end
	end,
	['inviteAttack'] = function(buff,args,isOver)
		return BuffEffectFuncTb['syncAttack'](buff,args,isOver)
	end,
	-- 保护逻辑
	['protection'] = function(buff,args,isOver)
		local ratio = type(args) == "table" and args[1] or args -- 处理剑盾和新的光环保护参数
		local holder = buff.holder
		if buff.caster.id == buff.holder.id then
			return true
		end
		if not isOver then
			local protectObj = buff.caster
			if protectObj:isAlreadyDead() then
				buff:overClean()
			else
				holder:addOverlaySpecBuff(
					buff,
					function(old)
						old.buff = buff
						old.ratio = ratio
						old.type = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or 0
						old.priority = buff.csvCfg.specialVal and buff.csvCfg.specialVal[2] or 1000
						old.extraArgs = buff.csvCfg.specialVal and buff.csvCfg.specialVal[3]

						old.protectObj = buff.holder:setProtectObj(protectObj,ratio)

						-- 策划配置specialVal
						old.checkCondition = function(_self)
							local canTakeEffect = false
							if not buff.csvCfg.specialVal then
								canTakeEffect = true
							elseif _self.protectObj then
								buff.protectedEnv = battleCsv.fillFuncEnv(buff.protectedEnv, {
									protector = _self.protectObj,
								})
								canTakeEffect = buff:cfg2Value(_self.extraArgs[3])
								buff.protectedEnv:resetEnv()
							end
							return canTakeEffect
						end
					end,
					function(a, b)
						if a.priority == b.priority then
							return a.buff.id < b.buff.id
						else
							return a.priority > b.priority
						end
					end
				)
			end
		else
			holder:deleteOverlaySpecBuff(buff)
		end
		return true
	end,
	--换位 args == 1为后排向前移 args == 2为前排向后移
	["shiftPos"] = function(buff,args,isOver)
		if not isOver then
			local specTb = buff.csvCfg.specialVal or {}
			local isOneceBuff, effectCfgId = specTb[1], specTb[2]
			local mode, targetPos
			local function checkClean()
				if isOneceBuff and isOneceBuff == 1 then
					buff:overClean()
				end
			end

			if type(args) == 'table' then
				mode = args[1]
				targetPos = args[2] and buff:cfg2Value(args[2]) or nil
			else
				mode = args
			end
			--自动查找空位
			if mode and targetPos then
				local forceNumber = buff.holder.scene.play.ForceNumber
				local rowNumber = forceNumber/2
				local s, e = 1, forceNumber
				if buff.holder.force ~= 1 then
					s, e = s + forceNumber, e + forceNumber
				end

				if mode == 1 then
					e = e - rowNumber
				elseif mode == 2 then
					s = s + rowNumber
				else
					e = s - 1
				end
				local retT = {}
				local heros = buff.holder.scene:getHerosMap(buff.holder.force)
				for id, obj in heros:order_pairs() do
					if obj and not obj:isAlreadyDead() then
						retT[obj.seat] = 1
					end
				end
				for i = s, e do
					if not retT[i] then
						targetPos = i
						break
					end
				end
			end

			if targetPos and targetPos<0 then
				checkClean()
				return true
			end

			if mode == 1 and buff.holder:frontOrBack() == 2 then --自己在后排
				buff.holder.shiftPos = targetPos or buff.holder.seat - 3
				buff.holder.shiftPosMode = mode
			elseif mode == 2 and buff.holder:frontOrBack() == 1 then
				buff.holder.shiftPos = targetPos or buff.holder.seat + 3
				buff.holder.shiftPosMode = mode
			else
				checkClean()
				return true
			end

			if buff.holder:canShiftPos() then
				local effectCfg = csv.buff[effectCfgId]
				buff.holder:doShiftPos(effectCfg)
				buff:over()
			else
				checkClean()
			end
		end
	end,
	--禁用复活、免死、锁血
	--specialVal <> args: <<>,<>,<>,...	>
	["forbiddenSpecBuff"] = function(buff,args,isOver)
		local funcList = buff.csvCfg.specialVal or {}
		local holder = buff.holder
		local filter
		funcList = type(funcList[1]) == 'table' and funcList[1]["easyEffectFunc"] or {}
		-- buff.holder.forbiddenInfo = buff.holder.forbiddenInfo or {}
		-- print(" forbiddenSpecBuff ",buff.cfgId,holder.seat,isOver)
		buff.__temp = buff.__temp or {}
		for i, key in ipairs(funcList) do
			filter = nil
			if not isOver then
				if args and type(args) == "table" and table.length(args[1]) > 0 then
					-- 屏蔽固定id
					filter = function(data)
						if itertools.include(args[1],data.cfgId) then
							return true
						end
					end
				end
				buff.__temp[key] = holder:addOverlaySpecBuffFilter(key,filter)
			else
				holder:deleteOverlaySpecBuffFilter(key,buff.__temp[key])
			end
		end
	end,
	-- 禁用反击、协战、邀战... 在受击/攻击情况下某些触发和响应行为
	["banExtraAttack"] = function(buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			local banModeTb = {}
			local banModeType = {}
			if buff.csvCfg.specialVal then
				for k, v in ipairs(buff.csvCfg.specialVal) do
					banModeTb[v] = k
				end
			end
			if args then
				for k, v in ipairs(args) do
					banModeType[k] = {}
					banModeType[k].canResponseSelf = (v[1] == 1)   -- 响应自身
					banModeType[k].canTriggerOthers = (v[2] == 1)  -- 触发其他人
					banModeType[k].canResponseOthers = (v[3] == 1) -- 响应其他人
				end
			end
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.banModeTb = banModeTb     -- 禁用模式表
					old.banModeType = banModeType -- 每个禁用模式的禁用类型
				end
			)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
	end,
	-- 变换属性buff
	-- 将一个buff变为另一个buff 简单作用于属性
	-- args = <<<groupId,groupId,groupId...>;<buffId,buffId,buffId...>;<1;1>>>
	["transformAttrBuff"] = function(buff,args,isOver)
		local holder = buff.holder
		if not isOver then
			local refreshCfgId = functools.partial(getTransformCfgId, args)
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.refreshCfgId = refreshCfgId
				end,nil
			)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
	end,
	-- 增加延迟受伤状态
	-- over的时候清除伤害记录
	["delayDamage"] = function(buff,args,isOver)
		local holder = buff.holder
		if not isOver then
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.delayPer = args[1]
					old.time = args[2]
					old.damageTb = {}
				end
			)
			holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.delayDamage, "getRoundDamage", function()
				local totalDamage = 0
				if holder:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.delayDamage) then
					for k,data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.delayDamage) do
						for i=table.length(data.damageTb),1,-1 do
							totalDamage = totalDamage + data.damageTb[i][1]
							table.remove(data.damageTb[i], 1)
							if table.length(data.damageTb[i]) <= 0 then
								table.remove(data.damageTb, i)
							end
						end
					end
				end
				return totalDamage
			end)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
	end,
	-- 清除延迟伤害
	-- args 要清除的值
	-- 从前向后清除(优先清除最先生效的伤害) 伤害清空之后也要保存伤害为0的记录
	["reduceDelayDamage"] = function(buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			if holder:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.delayDamage) then
				local toReduceDamage = args
				local allClear = false
				local index = 1
				while toReduceDamage > 0  and not allClear do
					allClear = true
					for k,data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.delayDamage) do
						for _,oneRecord in ipairs(data.damageTb) do
							if oneRecord[index] then
								allClear = false
								if toReduceDamage > oneRecord[index] then
									toReduceDamage = toReduceDamage - oneRecord[index]
									oneRecord[index] = 0
								else
									oneRecord[index] = oneRecord[index] - toReduceDamage
									toReduceDamage = 0
								end
							end
						end
					end
					index = index + 1
				end
				holder:refreshLifeBar()
			end
		end
	end,
	-- 反击协战邀战权重值修正
	["extraSkillWeightValueFix"] = function(buff,args,isOver)
		local holder = buff.holder
		if not isOver then
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.fixType = args[1]
					old.fixValue = args[2]
					old.fixCostType = args[3]
				end
			)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
	end,
	-- 必中
	["damgeMustHit"] = function(buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			holder:addOverlaySpecBuff(buff,function(old) end,nil)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
	end,
	-- 更改伤害过程段是否生效和临时参数值
	["alterDmgRecordVal"] = function(buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.assignObject = args[1] -- attacker:1  target:2  all:3
					old.priority = args[2]
					old.typ = args[3] or 1 -- 1:修改过程中的伤害数值 2:修改过程sign,是否进入某个流程 3:额外参数，能够控制具体计算过程中的实现方式
					old.alterDmgRecordData =buff.csvCfg.specialVal[1]
				end
			)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
	end,
	-- 移出场外
	["backStage"] = function(buff, args, isOver)
		if isOver then return end
		local function delFromAttackArr(array, objId)
			for i = table.length(array), 1, -1 do
				local obj = array[i].obj or array[i]
				if obj.id == objId then
					table.remove(array, i)
				end
			end
		end

		local obj = buff.holder
		local objMap = buff.scene:getHerosMap(obj.force)
		objMap:erase(obj.id)
		buff.scene:addBackStageObj(obj)
		obj.seat = -1
		obj:onFieldStateChange(false)

		delFromAttackArr(buff.scene.play.roundLeftHeros, obj.id)
		delFromAttackArr(buff.scene.play.roundHasAttackedHeros, obj.id)
		battleEasy.deferNotifyCantJump(obj.view, "stageChange", false)
	end,
	-- 召唤至场内
	-- args[1] 召唤到的seat
	-- args[2] 被召唤精灵的unitID
	-- args[3] 继承召唤者的mp的比例
	-- args[4] 1:继承召唤者的出手顺序 0:否
	["frontStage"] = function(buff, args, isOver)
		if isOver then return end
		-- print("*********", buff.cfgId, buff.holder.seat)
		-- dump(args)
		local holder = buff.holder
		local seat, unitId = args[1], args[2]
		local transferMp = (args[3] or 0) * holder:mp1()
		local isSaveAttackOrder = args[4] == 1 and true or false
		if not seat or not unitId then
			return
		end
		local curGate = buff.scene.play
		for _, obj in buff.scene.backHeros:order_pairs() do
			-- print("///////////", obj.summonGroup, unitId, obj.orginUnitId, holder.summonGroup)
			if obj.summonGroup == holder.summonGroup and unitId == obj.orginUnitId then
				obj.frontStageTarget = seat
				if isSaveAttackOrder then
					obj.stageRound = curGate.curRound
					obj.stageAttacked = not itertools.include(curGate.roundLeftHeros,function(data) return data.obj.id == buff.holder.id end)
				end
				obj.transferMp = transferMp
				break
			end
		end
	end,
	-- 逃跑
	-- args[1] 移动之前的延时
	-- args[2] 移动用时(不包括延时)
	["escape"] = function(buff, args, isOver)
		if isOver then return end
		local holder = buff.holder
		battleEasy.deferNotifyCantJump(holder.view, "escape", {
			delayMove = args and args[1],
			costTime = args and args[2],
		})
		holder:setDead(holder, nil, {force = true})
	end,
	-- 一次性属性变换 类似 transformAttrBuff
	-- < <
	-- 		<groupId,groupId,groupId,groupId,...>,
	-- 		<buffId,buffId,buffId,buffId,...>,
	-- 		<
	-- 			transformType,    -- 1: 一对一 2: 随机
	-- 			<buffVal,buffVal,buffVal,buffVal,...>,
	-- 		>,
	--      limit, -- 转换个数
	--      targetType, -- 转换后加给谁
	-- > >
	-- specialVal <buffRound>  转换后buff生命周期
	["atOnceTransformAttrBuff"] = function(buff, args, isOver)
		if not isOver then
			local mainHolder = buff.holder
			local toBeTransformTb = {}
			local buffRound = buff.csvCfg.specialVal[1]
			local limit = 0

			for _, curBuff in mainHolder.buffs:order_pairs() do
				local _cfgId,rate,rateType,exArgs = getTransformCfgId(args, curBuff.cfgId, curBuff:group())
				if curBuff.csvPower.beChange == 1 and _cfgId ~= curBuff.cfgId and rate and exArgs and exArgs.limit and exArgs.targetType then
					local newValue
					if rateType == "number" then
						newValue = string.format("(%s)*%s",args.value,rate)
					else
						newValue = string.format("%s", rate)
					end
					local newArgs = BuffArgs.fromAtOnceTransform1(curBuff, _cfgId, newValue, exArgs.targetType)
					table.insert(toBeTransformTb, newArgs)
					limit = exArgs.limit
				end
			end

			toBeTransformTb = random.sample(toBeTransformTb, limit, ymrand.random)
			for _, data in ipairs(toBeTransformTb) do
				data.oldBuff:overClean()
			end

			local isSuccess = false
			for _, data in ipairs(toBeTransformTb) do
				local holders = buff:getObjectsByCfg(data.targetType)
				for _, holder in ipairs(holders) do
					local newArgs = BuffArgs.fromAtOnceTransform2(data, buffRound)
					local curBuff,takeEffect = addBuffToHero(data.cfgId, holder, data.oldHolder, newArgs)
					isSuccess = isSuccess or takeEffect
				end
			end

			if isSuccess then
				buff:triggerByMoment(battle.BuffTriggerPoint.onBuffTrigger)
			end
		end
	end,
	-- 特殊数据记录
	-- specialVal[1]  记录的类型  1:承伤量统计
	-- specialVal[2]  记录的单位 getObjectsByCfg公式
	-- specialVal[3]  记录值的计算规则  1:差值  default:累加
	["specialRecord"] = function(buff, args, isOver)
		if isOver then return end
		local specialVal = buff.csvCfg.specialVal

		if not buff.specialRecordFunc then
			buff.specialRecordFunc = functools.partial(function(targets, dataType, calcType)
				local resultValue = 0
				for _, target in ipairs(targets) do
					local curVal = recordOpMap[dataType] and recordOpMap[dataType](target)
					if type(curVal) == 'number' then
						resultValue = resultValue + curVal
					end
				end
				if calcType == 1 then
					buff.specialRecordDiffVal = buff.specialRecordDiffVal or resultValue -- 做差值计算的初始值
					resultValue = resultValue - buff.specialRecordDiffVal
				end
				return resultValue
			end, buff:getObjectsByCfg(specialVal[2]))
		end

		buff:setValue(buff.specialRecordFunc(specialVal[1], specialVal[3]))
	end,
	["directWin"] = function(buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			holder:addOverlaySpecBuff(buff, function(old)
				old.mode = args or 1  -- 1:胜利作为判定标准  2:失败作为判定标准
			end, nil)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
	end,
	-- 修改怒气点个数
	-- args 变化量
	["mp1Point"] = function(buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			local mp1PointData = holder:getOverlaySpecBuffByIdx("mp1OverFlow")
			if mp1PointData then
				local val = cc.clampf(mp1PointData.mp1Point + args, 0, mp1PointData.limit)
				mp1PointData.mp1Point = val
			end
		end
	end,
	-- 修改单位身上的数据
	["opGameData"] = function(buff, args, isOver)
		local holder = buff.holder
		-- TODO: 临时修改
		local indexToStrMap = {
			"hintChoose",
			"skillLevel0", -- 普攻
			"skillLevel1",	-- 小技能
			"skillLevel2",	-- 大招
			"skillLevel3",	-- 被动
		}
		if not isOver then
			holder:addOverlaySpecBuff(buff, function(old)
				old.key = indexToStrMap[args[1]] 		--字段
				old.op = opMap[args[2]] --操作
				old.value = args[3] 	-- 值
				old.checkFormula = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or true
			end, nil)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
	end,
	-- 按比例修改单位的全部属性
	["changeScaleAttrs"] = function( buff, args, isOver )
		local holder = buff.holder
		if not isOver then
			local specialVal = buff.csvCfg.specialVal
			local normalAttrRate = specialVal and buff:cfg2Value(specialVal[1]) or 1 -- 六维属性比率
			local otherAttrRate = specialVal and buff:cfg2Value(specialVal[2]) or 1 -- 其他属性比率
			local specialAttrTb = specialVal and specialVal[3] or {} -- 指定特殊属性比率

			local attrsRecordTb = {}
			for attr, _ in pairs(ObjectAttrs.AttrsTable) do
				local changeAttrValue = holder:getBaseAttr(attr) -- 获取基础属性
				if specialAttrTb[attr] then
					changeAttrValue = changeAttrValue * (1 - specialAttrTb[attr])
				elseif ObjectAttrs.SixDimensionAttrs[attr] then
					changeAttrValue = changeAttrValue * (1 - normalAttrRate)
				else
					changeAttrValue = changeAttrValue * (1 - otherAttrRate)
				end

				if changeAttrValue ~= 0 then
					holder.attrs:addBuffAttr(attr, -changeAttrValue)
					attrsRecordTb[attr] = changeAttrValue
				end
			end

			holder:addOverlaySpecBuff(buff, function(old)
				old.attrsRecordTb = attrsRecordTb
			end, nil)
		else
			holder:deleteOverlaySpecBuff(buff, function(old)
				for attr, value in pairs(old.attrsRecordTb) do
					holder.attrs:addBuffAttr(attr, value)
				end
			end)
		end
	end,
	-- 致死伤害触发保护
	-- args[1] 通过buffCfg获取转移目标
	-- args[2] 是否可以重复攻击(aoe) 1:可以
	-- args[3] 保护者控制状态是否可以保护 1:可以
	['lethalProtect'] = function(buff,args,isOver)
		local holder = buff.holder
		local play = holder.scene.play

		local getRoundMark = function()
			return string.format("%sw%sr", play.curWave, play.totalRoundBattleTurn)
		end

		if not isOver then
			holder:addOverlaySpecBuff(
				buff,
				function(old)
					old.transferTo = buff:getObjectsByCfg(args[1])[1] --functools.partial(buff.getObjectsByCfg, buff, args[1])
					old.aoeTwice = args[2] == 1
					old.ignoreControl = args[3] == 1

					-- 策划配置specialVal
					old.checkCondition = function(_self)
						local canTakeEffect = false
						if not buff.csvCfg.specialVal then
							canTakeEffect = true
						elseif _self.transferTo then
							buff.protectedEnv = battleCsv.fillFuncEnv(buff.protectedEnv, {
								lethalProtector = _self.transferTo,
							})
							canTakeEffect = buff:cfg2Value(buff.csvCfg.specialVal[1])
							buff.protectedEnv:resetEnv()
						end
						return canTakeEffect
					end

					-- 检测保护者的状态 args[3] 是否受控制影响
					old.checkToObj = function(_self)
						local toObj = _self.transferTo
						if not toObj then return false end
						if toObj:isAlreadyDead() then return false end
						if toObj:isNotReSelect(true) then return false end
						if toObj:isSelfControled() and not _self.ignoreControl then return false end
						return true
					end
				end,nil
			)

			-- 执行保护流程
			holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.lethalProtect, "tryProtect", function()
				-- 已有生效的保护者时 全程都使用同一个保护者
				local nowToObj, aoeTwice = holder:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.lethalProtect, "getProtectObj")
				if nowToObj then
					return nowToObj, aoeTwice
				end
				if play.lethalDatas[holder.id] then
					for _,data in holder:ipairsOverlaySpecBuffTo(battle.OverlaySpecBuff.lethalProtect) do
						if data:checkToObj() and data:checkCondition() then
							local toObj = data.transferTo
							local newData = {
								takeEffectRound = getRoundMark(),
								toObj = toObj,
								aoeTwice = data.aoeTwice,
							}
							if data.takeEffectData then
								data.takeEffectData = newData
							else
								data:setG("takeEffectData", newData)
							end
							holder:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffTrigger, {
								buffId = data.id,
								easyEffectFunc = buff.csvCfg.easyEffectFunc,
								obj = toObj,
							})
							return toObj, data.aoeTwice
						end
					end
				end
				return nil
			end)

			-- 获取已生效的保护单位
			holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.lethalProtect, "getProtectObj", function()
				local buffData = holder:getOverlaySpecBuffData(battle.OverlaySpecBuff.lethalProtect)
				if buffData and buffData.takeEffectData and buffData.takeEffectData.takeEffectRound == getRoundMark() then
					return buffData.takeEffectData.toObj, buffData.takeEffectData.aoeTwice
				end
				return nil
			end)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
	end,
	-- 治疗转化伤害
	-- args[1]: 伤害公式 额外传递healthNum
	-- args[2]: damage_processId 默认值15
	['healTodamage'] = function (buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			holder:addOverlaySpecBuff(buff,function(old)
				old.formula = args[1]
				old.processId = args[2] or 15
				old.calcDamage = function(healthNum)
					buff.protectedEnv = battleCsv.fillFuncEnv(buff.protectedEnv, {
						healthNum = healthNum
					})
					local damageNum = buff:cfg2Value(old.formula)
					buff.protectedEnv:resetEnv()
					return damageNum
				end
			end,nil)
			holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.healTodamage, "getDamage", function(healthNum)
				local ret,ids = {},{}
				for k,data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.healTodamage) do
					local processId = data.processId
					if not ret[processId] then
						ret[processId] = 0
						table.insert(ids, processId)
					end
					ret[processId] = ret[processId] + data.calcDamage(healthNum)
				end
				local data = {}
				for _, id in ipairs(ids) do
					table.insert(data,{
						processId = id,
						damage = ret[id],
					})
				end
				return data
			end)
			holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.healTodamage, "doBuffDamage", function(attacker, target, damage, cfgId)
				local toDamageData = target:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.healTodamage, "getDamage", damage)
				for k, data in ipairs(toDamageData) do
					local damage = math.floor(data.damage)
					local buffDamageArgs = {
						from = battle.DamageFrom.buff,
						buffCfgId = cfgId,
						isLastDamageSeg = true,
						isBeginDamageSeg = true,
						beAttackZOrder = buff.scene.beAttackZOrder,
						isProcessState = {
							isStart = k == 1,
							isEnd = k == table.length(toDamageData)
						},
					}
					-- 治疗转血量 触发节点
					buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
						buffId = buff.id,
						easyEffectFunc = buff.csvCfg.easyEffectFunc,
					})

					local damage,damageArgs = target:beAttack(attacker, damage, data.processId, buffDamageArgs)
				end
			end)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
		return true
	end,
	-- 替换技能
	-- args[1] [skillId1, skillId2, ...] 原始技能id
	-- args[2] [skillId1, skillId2, ...] 目标技能id
	["replaceSkill"] = function(buff, args, isOver)
		local holder = buff.holder

		if not isOver then
			holder:replaceSkill(args[1], args[2], buff.id)
		else
			holder:resumeSkill(buff.id)
		end
	end,
	["breakCharging"] = function(buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			holder:addOverlaySpecBuff(buff, function(old)
				old.mode = args[1] -- 1.行动取消 2.行动立即执行
			end)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
	end,
	-- 替换精灵自然属性
	-- args [type1, type2]  >0:对应属性 -1:不改变
	-- 只有最后添加的buff生效
	-- 例子: <-1, 2> 第一属性不改变 第二属性为火
	["changeObjNature"] = function(buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			holder:addOverlaySpecBuff(buff, function(old)
				if not old.typeList then old:setG("typeList", CVector.new()) end
				old:setG("getType", function(buffData, idx)
					idx = idx or 1
					local data = buffData.typeList and buffData.typeList:front()
					return data and data[idx]
				end)
				old.typeList:push_front(args)
			end)
		else
			holder:deleteOverlaySpecBuff(buff, function(old)
				old.typeList:pop_front(args)
			end)
		end
	end,
	-- 改变技能自然属性
	-- args[1]  0:按技顺序替换 1:按技能属性替换
	-- args[2]  0:<大招;小技能;普攻;额外技能> 填-1补位  1:{旧属性名字 = 新属性数字} 例 {fire=4} 火->草
	["changeSkillNature"] = function(buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			holder:addOverlaySpecBuff(buff, function(old)
				if not old.skillNatures then old:setG("skillNatures", {}) end --[skillId = natureType]

				old.mode = args[1]
				old.args = args[2] or {}
				old.refreshSkills = function(skillsOrder)
					old.skillNatures = {}
					if old.mode == 0 then
						-- 按顺序
						local hasEx = table.length(skillsOrder) > 3
						for i, skillID in ipairs(skillsOrder) do
							local idxInArgs = i
							if hasEx and i == 3 then idxInArgs = 4 end
							if hasEx and i == 4 then idxInArgs = 3 end
							local newType = old.args[idxInArgs]
							if newType and newType > 0 then
								old.skillNatures[skillID] = newType
							end
						end
					elseif old.mode == 1 then
						for i, skillID in ipairs(skillsOrder) do
							local cfg = csv.skill[skillID]
							local oldType = cfg and cfg.skillNatureType
							local name = game.NATURE_TABLE[oldType]
							local newType = old.args[name]
							if newType and newType > 0 then
								old.skillNatures[skillID] = newType
							end
						end
					end
				end

				old:setG("refreshAll", function()
					for _,data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.changeSkillNature) do
						data.refreshSkills(holder.skillsOrder)
						break
					end
				end)
			end)

			local buffData = holder:getOverlaySpecBuffData(battle.OverlaySpecBuff.changeSkillNature)
			buffData.refreshAll()
		else
			holder:deleteOverlaySpecBuff(buff, function(old)
				old.skillNatures = {}
			end)
		end
	end,
	['possess'] = function(buff,args,isOver)
		local holder = buff.holder
		if not isOver then
			local targetCfg = buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1]
			local target = targetCfg and buff:getObjectsByCfg(targetCfg)[1]
			local specialArgs = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or {}
			if not target then return end
			local possessArgs = {
				casterKey = tostring(holder),  -- 附身发起目标key
				targetKey = tostring(target),  -- 附身目标key
				targetSeat = target.seat,  -- 附身座位
				offsetPos = cc.p(specialArgs.x, specialArgs.y),  -- 附身者偏移
				res = specialArgs.res,      -- 附身spine资源
				type = battle.SpriteType.Possess
			}
			holder:addExRecord(battle.ExRecordEvent.possessTarget, target)
			-- holder.possessView = gRootViewProxy:getProxy('onSceneAddPossessObj', "possess" .. tostring(holder), readOnlyProxy(holder), possessArgs)
			holder.scene:addObjViewToBattleTurn(nil, 'SceneAddObj', "possess" .. tostring(holder), readOnlyProxy(holder), possessArgs)
		else
			holder:cleanEventByKey(battle.ExRecordEvent.possessTarget)
			-- gRootViewProxy:notify('onSceneDelObj', "possess" .. tostring(holder))
			holder.scene:addObjViewToBattleTurn(nil, 'SceneDelObj', "possess" .. tostring(holder))
		end
	end,
	-- 先知效果 打断本次出手
	-- 触发参数
	-- args[1] 概率(0,1]
	-- args[2] extra_round_trigger中的ID 是否触发一些功能
	-----------------------
	-- 反击参数
	-- args[3] 权重组 普攻配置<1,0,0>
	-- args[4] 消耗类型 0: 正常 1: 忽略cd,mp
	-- args[5] 必须敌方 1:只有敌方攻击触发
	-----------------------
	-- 补偿回合参数
	-- 在extra_round_trigger中添加对应当前cfgId的行 控制buff 被动技能 回合数
	['prophet'] = function (buff, args, isOver)
		local holder = buff.holder
		if not isOver then
			holder:addOverlaySpecBuff(buff,function(old)
				old.getProb = function(_self, attacker)
					buff.protectedEnv = battleCsv.fillFuncEnv(buff.protectedEnv, {
						attacker = attacker,
					})
					local prob = buff:cfg2Value(buff.args.buffValueFormula[1])
					buff.protectedEnv:resetEnv()
					return prob
				end
				old.triggerId = args[2]

				old.triggerSkillType2 = args[3]
				old.triggerSkillType = type(args[3])
				old.costType = args[4] or 0
				old.mustEnemy = args[5] == 1
			end,nil)
		else
			holder:deleteOverlaySpecBuff(buff)
		end
		return true
	end,
}


-- buff中增加的属性
-- 1.easyEffectFuncs 中: 增加的属性为由buff生命周期控制的属性, buff创建后立即增加, buff结束时删除。
-- 2.节点的effectFuncs中: 增加的属性为由节点控制触发的属性, 节点触发成功或者失败时才增加, 在buff最后结束时一并删除。
-- 3.给技能用的属性, 相当于技能专属的属性, 在技能开始时增加, 技能结束后清理掉, 其属性影响只对技能自身有效。
--   类型3的属性, 在数码中是通过buff加出来的。

