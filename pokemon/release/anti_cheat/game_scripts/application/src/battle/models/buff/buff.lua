--
-- buff
--


local BuffModel = class("BuffModel")
globals.BuffModel = BuffModel

--buff从0开始计数
BuffModel.IDCounter = 0

local SpecBuff = {
	reborn = true,
	copyCasterBuffsToHolder = true,
	transferBuffToOther = true,
	copyForceBuffsToOther = true,
}

local SpecialOnBuffTrigger = {
	lockHp = true,
	keepHpUnChanged = true,
}

local ExtraAttackCheckPointsMap = {
	[battle.BuffTriggerPoint.onHolderBattleTurnStart] = true,
	[battle.BuffTriggerPoint.onHolderBattleTurnEnd] = true,
	[battle.BuffTriggerPoint.onHolderAttackBefore] = true,
	[battle.BuffTriggerPoint.onHolderAttackEnd] = true,
	[battle.BuffTriggerPoint.onHolderFinallyBeHit] = true,
	[battle.BuffTriggerPoint.onHolderBeforeBeHit] = true,
	[battle.BuffTriggerPoint.onHolderKillHandleChooseTarget] = true,
	[battle.BuffTriggerPoint.onHolderBeForeSkillSpellTo] = true,
	[battle.BuffTriggerPoint.onHolderToAttack] = true,
	[battle.BuffTriggerPoint.onHolderBeForeSkillSpellTo] = true,
	[battle.BuffTriggerPoint.onHolderCalcDamageProb] = true,
}

local IterAllPointsMap = {
	[battle.BuffTriggerPoint.onHolderBattleTurnStart] = true,
	[battle.BuffTriggerPoint.onHolderBattleTurnEnd] = true,
	[battle.BuffTriggerPoint.onRoundStart] = true,
	[battle.BuffTriggerPoint.onRoundEnd] = true,

	[battle.BuffTriggerPoint.onBuffTrigger] = true,
}
table.merge(IterAllPointsMap, ExtraAttackCheckPointsMap)

BuffModel.IterAllPointsMap = IterAllPointsMap

function BuffModel.BuffCmp(buff1, buff2)
	if buff1.triggerPriority ~= buff2.triggerPriority then
		return buff1.triggerPriority < buff2.triggerPriority
	end
	return buff1.id < buff2.id
end


function BuffModel:ctor(cfgId, holder, caster, args)
	BuffModel.IDCounter = BuffModel.IDCounter + 1

	self.id = BuffModel.IDCounter 		-- 表示buff的创建序号
	self.scene = holder.scene
	self.cfgId = cfgId
	self.csvCfg = csv.buff[cfgId]
	self.csvPower = csv.buff_group_power[self.csvCfg.groupPower]
	self.caster = caster	--施放buff的对象(换个名字，因为owner在 buff和skill/skillProcess里表示的含义不一样，所以这里改了下)
	self.holder = holder   -- buff持有者，表示这个buff将被添加到这个目标身上后,目标将一直持有它
	self.extraTargets = {
		[battle.BuffExtraTargetType.lastProcessTargets] = args.lastProcessTargets or {},
		[battle.BuffExtraTargetType.holderBeAttackFrom] = {},
		[battle.BuffExtraTargetType.skillAllDamageTargets] = args.currentAttackTarget or {},
		[battle.BuffExtraTargetType.overLayBuffCaster] = {},
		[battle.BuffExtraTargetType.segProcessTargets] = {},
	}
	self.startRound = 0 -- 创建时的round
	self.nowRound = 0	-- 当前回合
	self:setRound()     -- startRound nowRound

	self.nowWave = self.scene.play.curWave		-- 当前波次
	self.args = args
	self.lifeRound = args.lifeRound -- 生命周期, 以大回合计算
	self.source = args.source 	--记录来源,用的是self.id来记录的
	self.fromSkillLevel = args.skillLevel
	self.isInited = false
	self.isOver = false
	self.isEffect = false -- 是否生效 当buff添加即触发的时候立马被删除 初始化流程被中断导致参数缺失

	self.buffValue = nil 	-- 这个值一般来自 skill_process 中的 buffValue 要先处理下原始数据后再保存,这个值保存buff的原始值
	self.value = nil		-- 实时value值,可以被外部修改
	self.doEffectValue = nil -- 只有在doEffect时才能被修改的值,不可以外界被修改
	self.isNumberType = true

	self.triggerPriority = self.csvCfg.triggerPriority or 10	-- 同时刻一起触发的buff，用优先级来区分执行顺序上的先后
	self.isAuraType = args.isAuraType	-- 光环类buff，不通过配置而是通过skill决定参数
	self.lifeRounds = {}	--有叠加上限的多个buff的生命周期，每当新的替换掉旧的时，需要把旧的身上记录的lifeRounds数据都保存起来
	self.overlayType = self.csvCfg.overlayType		-- 叠加类型
	self.overlayCount = args.overlayCount or 1 --叠加次数，主要用于数值属性叠加
	self.objThatTriggeringMeNow = nil -- 记录当buff效果被触发时,是谁触发的
	self.triggerEnv = {}
	self.bondChildBuffsTb = {} --如果自身创建的子buff能绑定时,自己是主buff,控制子buff的生命周期,要记录起来,over时一起删除
	self.bondToOtherBuffsTb = {} --如果自身创建的子buff与自己是同级绑定时,同级绑定时生命周期和存活状态会同步,记录下

	self.triggerAddAttrTb = {} 	-- 记录由节点(不包括0号节点)触发增加到目标身上的属性,这类属性需要在over时单独清理

	self.nodeManager = BuffNodeManager.new(self)

	self.exRecordNameTb = {}    -- 保存buff产生的exrecord事件名, over的时候释放

	-- 公式解析
	self.protectedEnv = battleCsv.makeProtectedEnv(self.caster, nil, self)

	-- 用于castBuff中self2和target2
	self.castBuffEnvAdded = false
	self.castBuffGroup = CList.new()  --记录castBuff子buff之间的绑定关系
	self.buffInitEnhanceVal = nil --buff初始化附加的系数

	self.isShow = self.csvCfg.isShow
	-- 一次性特效是否已经显示过了 onceEffectResPath
	self.isOnceEffectPlayed = not self.isShow
	self.isFieldBuff = self.csvCfg.easyEffectFunc == "fieldBuff"  -- 场地buff
	self.isFieldSubBuff = args.fieldSub -- 场地buff的子buff(包括多代)
	self.gateLimit = self:cfg2Value(self.csvCfg.gateLimit)
end

function BuffModel:setRound()
	if self.csvCfg.lifeRoundType == battle.lifeRoundType.battleTurn then
		self.startRound = self.holder:getBattleRoundAllWave(self.csvCfg.skillTimePos) -- 创建时的round
		self.nowRound =  self.holder:getBattleRoundAllWave(self.csvCfg.skillTimePos)	-- 当前回合
	elseif self.csvCfg.lifeRoundType == battle.lifeRoundType.round then
		self.startRound = self.scene.play.totalRound -- 创建时的round
		self.nowRound =  self.scene.play.totalRound	-- 当前回合
	elseif self.csvCfg.lifeRoundType == battle.lifeRoundType.pureBattleTurn then
		self.startRound = self.holder:getBattleRoundAllWave(self.csvCfg.skillTimePos, true) -- 创建时的round
		self.nowRound =  self.holder:getBattleRoundAllWave(self.csvCfg.skillTimePos, true)	-- 当前回合
	end
end

--检查是否可以驱散 特殊的不可驱散的buff组
function BuffModel:checkCanDispelBuff(buff)
	if buff.holder.cantDispelTb and next(buff.holder.cantDispelTb) then
		local buffGroupTb = buff.holder.cantDispelTb.buffGroupTb
		local buffRound = buff.holder.cantDispelTb.buffRound
		if buffGroupTb[buff:group()] then
			local curRound = self.nowRound
			buff.cantDispelBuffRound = {curRound, buffRound} --记录buff开始回合
		end
	end
	if buff.cantDispelBuffRound and next(buff.cantDispelBuffRound) then
		local startRound = buff.cantDispelBuffRound[1]
		local continueRound = buff.cantDispelBuffRound[2]
		if self.nowRound < startRound + continueRound then
			return false
		else
			buff.cantDispelBuffRound = nil
		end
	end
	return true
end

--检查是否可以驱散 特殊的不可驱散的buff组
function BuffModel:getTobeDispeledBuffs(hasDispelBuff, tobeDispeledBuffs)
	if table.length(tobeDispeledBuffs) > 0 then
		table.sort(tobeDispeledBuffs,function(a,b)
			return a.id < b.id
		end)
		-- dispelAll: 是否完整驱散 默认全部驱散 1:只驱散单层
		local dispelAll = self.csvCfg.dispelType[3] or 0
		for _, buff in ipairs(tobeDispeledBuffs) do
			if self:checkCanDispelBuff(buff) then
				self:addExRecord(battle.ExRecordEvent.dispelBuffCount, 1)
				logf.battle.buff.dispel("buff %s dispel buff %s bufftype=%s",self.cfgId,buff.cfgId,buff.csvCfg.easyEffectFunc)
				buff:BeDispel(dispelAll == 0)
			end
		end
		-- 转移触发
		self:triggerByMoment(battle.BuffTriggerPoint.onBuffTrigger)
		-- if table.length(tobeDispeledBuffs) > 0 then
		-- 	hasDispelBuff = true
		-- end
		hasDispelBuff = true
		tobeDispeledBuffs = {} -- 清理掉
	end
	return hasDispelBuff, tobeDispeledBuffs
end

function BuffModel:setDispeledBuffs(tobeDispeledBuffs, groupRelation)
	local array = self.csvCfg.dispelType
	-- dispelAll: 是否完整驱散 默认全部驱散 1:只驱散单层
	local dispelType, dispelNum, dispelAll = array[1] or 0, array[2] or 0, array[3] or 0
	local dispeledBuffs = {}
	local priorityOrder = {}
	local priorityNum = {}
	local addBuffToTable = function(_buff,_priority)
		if not dispeledBuffs[_priority] then
			dispeledBuffs[_priority] = CMap.new(function(buff1, buff2)
				return buff1.id < buff2.id
			end)
			table.insert(priorityOrder, _priority)
		end

		priorityNum[_priority] = priorityNum[_priority] + 1
		dispeledBuffs[_priority]:insert(_buff.id, _buff)
	end
	local deleteCheck = function(_priority)
		local isDelete = false
		if dispelNum >= priorityNum[_priority] then
			isDelete = true
		elseif dispelNum > 0 then
			local rate = ymrand.random(0,1)
			if rate == 1 then
				isDelete = true
			end
		end
		priorityNum[_priority] = priorityNum[_priority] - 1
		if isDelete then
			dispelNum = dispelNum - 1
		end
		return isDelete
	end

	if dispelType ~= nil then
		-- if dispelType == 1 then -- <dispelType;num>
		if dispelType == 2 then -- <dispelType;groupNum>
			addBuffToTable = function(_buff,_priority)
				if not dispeledBuffs[_priority] then
					dispeledBuffs[_priority] = CMap.new()
					table.insert(priorityOrder, _priority)
				end

				local holderBuffGroup = _buff:group()
				if not dispeledBuffs[_priority]:find(holderBuffGroup) then
					dispeledBuffs[_priority]:insert(holderBuffGroup, CMap.new())
					priorityNum[_priority] = priorityNum[_priority] + 1
				end

				dispeledBuffs[_priority]:find(holderBuffGroup):insert(_buff.id, _buff)
			end
		elseif dispelType == 0 then
			deleteCheck = function(_priority)
				return true
			end
		end
	end



	local targets = ( (self.csvCfg.specialTarget and self.csvCfg.specialTarget[1])
		and self:getObjectsByCfg(self.csvCfg.specialTarget[1]) ) or {self.holder}
	for _,holder in ipairs(targets) do
		for _, holderBuff in holder:iterBuffs() do
			local isExit,priority = battleCsv.hasBuffGroup(groupRelation.dispelGroup,holderBuff:group())
			if holderBuff.csvPower.beDispel == 1 and holderBuff.id ~= self.id and isExit then
				priorityNum[priority] = priorityNum[priority] or 0
				addBuffToTable(holderBuff,priority)
			end
		end
	end
	-- 如果是驱散全部buff 则把buff加入驱散队列,如果是单层,2,7类型在被驱散的时候处理,共存的buff则限制添加个数
	local dispelBuffsMap = {}
	local addDispleBuff = function(buff)
		if not dispelBuffsMap[buff.cfgId] then
			dispelBuffsMap[buff.cfgId] = 0
		end
		dispelBuffsMap[buff.cfgId] = dispelBuffsMap[buff.cfgId] + 1
		if dispelAll == 0 or (dispelAll > 0 and dispelBuffsMap[buff.cfgId] <= dispelAll) then
			table.insert(tobeDispeledBuffs,buff)
		end
	end
	-- 驱散GROUP
	--优先级排序
	for _, priority in ipairs(priorityOrder) do
		local data = dispeledBuffs[priority]
		if data then
			-- _buffData = dispelType 1:{buff} 2:{[group] = {buff}}
			for _, _buffData in data:order_pairs() do
				if deleteCheck(priority) then
					if dispelType and dispelType == 2 then
						for _,_buff in _buffData:order_pairs() do
							addDispleBuff(_buff)
						end
					else
						addDispleBuff(_buffData)
					end
				end
			end
		end
	end

end

function BuffModel:dispelGroupBuff()
	if not self.isInited then return end
	self.dispelCount = 0
	-- dispelType
	-- 0 : 驱散当前buff所属组下的所有buff
	-- 1 : 驱散当前buff所属组下的dispelNum个buff
	-- 2 : 驱散当前buff所属组下的dispelNum组buff
	-- 驱散ID
	local dispelBuff = self.csvCfg.dispelBuff
	local tobeDispeledBuffs = {}
	local hasDispelBuff = false
	local groupRelation = gBuffGroupRelationCsv[self:group()]

	--dispelBuff存在值时,先剔除dispelBuff里存在的值
	if csvSize(dispelBuff) > 0 then
		for _, holderBuff in self.holder:iterBuffs() do
			if holderBuff.csvPower.beDispel == 1 and holderBuff.id ~= self.id and itertools.include(dispelBuff, holderBuff.cfgId) then
				table.insert(tobeDispeledBuffs, holderBuff)
			end
		end
	end
	hasDispelBuff, tobeDispeledBuffs = self:getTobeDispeledBuffs(hasDispelBuff, tobeDispeledBuffs)

	-- 当前buff组不为0并且驱散表存在
	if self:group() ~= 0 and groupRelation and groupRelation.dispelGroup then
		self:setDispeledBuffs(tobeDispeledBuffs, groupRelation)
	end

	hasDispelBuff, tobeDispeledBuffs = self:getTobeDispeledBuffs(hasDispelBuff, tobeDispeledBuffs)
	if hasDispelBuff and self.caster and not self.caster:isDeath() then
		-- 驱散次数累加
		self.caster:addExRecord(battle.ExRecordEvent.dispelSuccessCount, 1)
		self:addExRecord(battle.ExRecordEvent.dispelSuccess, true)
	end

	return hasDispelBuff
end

function BuffModel:initTriggerEvents()
	for triggerPoint, _ in pairs(self.nodeManager.points) do
		-- exclude IterAllPointsMap
		if not IterAllPointsMap[triggerPoint] then
			self:subscribeEvent(self.holder, triggerPoint, "onTriggerEvent")
		end
	end
end

function BuffModel:init()
	if self.isOver then return end
	if self.isInited then return end
	if self.holder:isRealDeath() then return end

	self.isInited = true
	self.scene:checkCowWithBuff(self)
	logf.battle.buff.init(' buff init() id=%s cfgId=%s buffType=%s groupId=%s lifeRound=%s prob=%s caster=%s holder=%s', self.id, self.cfgId,  self.csvCfg.easyEffectFunc, self.csvCfg.group,self.lifeRound, self.args.prob,self.caster and self.caster.seat, self.holder.seat)

	-- 处理值
	-- 公式解析 (先解析出来, 主要是为了方便在做buff叠加时使用)
	self.buffValue = clone(self:cfg2Value(self.args.value))
	self.isNumberType = type(self.buffValue) == "number"
	if self.isNumberType then
		-- 永久生效 对于后续添加的buff
		-- 删除后value不会还原
		self.buffInitEnhanceVal = self.holder:getBuffEnhance(self:group(), 1)
	end
	self:setValue(self.buffValue)

	-- 初始化触发节点和Event组件
	battleComponents.bind(self, "Event")
	self.nodeManager:init(self.csvCfg.triggerBehaviors)
	self:initTriggerEvents()


	if self.overlayType == battle.BuffOverlayType.Coexist or self.overlayType == battle.BuffOverlayType.CoexistLifeRound then
		-- 不存在记录及0层以下都默认初始化为1层
		if not self.holder.buffOverlayCount[self.cfgId] then
			self.holder.buffOverlayCount[self.cfgId] = 0
		end

		self.holder.buffOverlayCount[self.cfgId] = self.holder.buffOverlayCount[self.cfgId] > 0 and self.holder.buffOverlayCount[self.cfgId] or 1
	end

	logf.battle.buff.overlay('overlay buff id=%s cfgId=%s type:%d,overlay count:%d', self.id, self.cfgId, self.overlayType,self.overlayCount)

	-- 处理对已有buff的影响，主要是驱散其它buff
	local showDispelEffect = self:dispelGroupBuff()
	-- 限时PVP记录触发次数
	if self.scene:isCraftGateType() then
		if not self.scene.play.craftBuffAddTimes[self.cfgId] then
			self.scene.play.craftBuffAddTimes[self.cfgId] = {0,0}
		end
		self.scene.play.craftBuffAddTimes[self.cfgId][self.holder.force] = self.scene.play.craftBuffAddTimes[self.cfgId][self.holder.force] +1
	end


	-- 添加buff免疫
	self.holder:onBuffImmuneChange(self)

	-- buff创建时的触发回调点  默认常规buff添加后就立即触发, 除非0号节点的配置修改了触发时刻
	self:triggerByMoment(battle.BuffTriggerPoint.onBuffCreate)
	if self.isFieldBuff then
		self.scene:tirggerFieldBuffs(nil, self)
	end
	if self.isShow then
		-- 播放默认特效 (因为播放延迟的缘故, 技能前 技能后加buff的类型, 播放特效放到了额外的函数内由外部来控制)
		-- -- 每回合固定播放的则由自己来控制
		-- 添加buff后的播放特效的表现函数

		-- 在初始化buff数据部分同时也要初始化显示部分的数据
		-- 这里先初始化图标部分的数据 在同一回合删除时避免资源还未初始化
		self.holder.view:proxy():onDealBuffEffectsMap(self.csvCfg.iconResPath,self.cfgId,self.csvCfg.isIconFrame)

		local aniArgs = self:getBuffEffectAniArgs()
		aniArgs.dispel = showDispelEffect
		self.isOnceEffectPlayed = true

		battleEasy.deferNotifyCantJump(self.holder.view, "playBuffAniEffect", aniArgs)

		if self.csvCfg.buffshader and csvSize(self.csvCfg.buffshader) > 0 then
			battleEasy.deferNotifyCantJump(self.holder.view, "playBuffShader", {
				buffshader = self.csvCfg.buffshader,
				buffId = self.cfgId
			})
		end
		if self.csvCfg.stageArgs then
			self.scene:recordSceneAlterBuff(self.id, self.cfgId)
			-- 触发buff时更换战斗场景
			local stageArgs = self.csvCfg.stageArgs
			local bkCsv = getCsv(stageArgs[1].bkCsv)
			-- 将相关参数提取, 直接传bkCsv[1]好像会有问题
			battleEasy.deferNotifyCantJump(self.holder.view, "alterBattleScene", {
				buffId = self.id,
				restore = false,
				aniName = bkCsv[1].aniName,
				resPath = bkCsv[1].res,
				x = bkCsv[1].x,
				y = bkCsv[1].y,
				delay = stageArgs[1].delay
			})
		end
		if self.weatherCfgId then
			battleEasy.deferNotifyCantJump(self.holder.view, "weatherRefresh", self)
		end
		self:playBuffProcessView()
	end

end

-- 默认参数格式：单个的数值 或者 字符串  如：10000/0.05/'owner:damage()'
-- 当有多个参数时, 参数格式改为需要写变量名的格式, 这样能区分值的含义而不需要关注值的顺序,避免出错 {attr='damage', val=5000} {attr='defenc', val=3000}
-- 不写key,因为参数需要顺序
function BuffModel.cfg2ValueWithEnv(sOrT, env, castBuffEnvAdded)
	if not sOrT then return end
	if type(sOrT) == 'table' then
		local ret = {}
		for k, v in csvMapPairs(sOrT) do
			if (k == "input") or (k == "process") then
				ret[k] = v
			else
				ret[k] = BuffModel.cfg2ValueWithEnv(v, env)
			end
		end
		return ret
	end

	-- 可能是属性名,直接返回原字符串
	if ObjectAttrs.AttrsTable[sOrT] then return sOrT end

	-- 先特殊处理
	if sOrT == 'lastMp1' then return sOrT end
	if (string.find(sOrT, "target2") or string.find(sOrT, "self2")) and not castBuffEnvAdded then
		return sOrT
	end

	return battleCsv.doFormula(sOrT, env)
end

function BuffModel:cfg2ValueWithTrigger(sOrT)
	self.protectedEnv = battleCsv.fillFuncEnv(self.protectedEnv, { trigger = self.triggerEnv })
	local value = self:cfg2Value(sOrT)
	self.protectedEnv:resetEnv()
	return value
end

function BuffModel:cfg2Value(sOrT)
	return self.cfg2ValueWithEnv(sOrT, self.protectedEnv, self.castBuffEnvAdded)
end

function BuffModel:overClean(params)
	params = params or {}
	params.endType = battle.BuffOverType.clean
	self:over(params)
end

-- 结束一个表中的所有buff
function BuffModel:overBuffsInTable(tb, params, sortFunc)
	if table.length(tb) <= 0 then return end

	if sortFunc then
		table.sort(tb,sortFunc)
	end

	for _, buff in ipairs(tb) do
		if buff then
			buff:over(params)
		end
	end
end

-- 结束	 isBondToOtherOver:表示是由于自己的同级绑定buff触发的over,此时不会再次触发自己的同级绑定记录中的buff 重复over
function BuffModel:over(params)
	if self.isOver then return end
	self.isOver = true

	params = params or {}
	-- 0 清理结束
	-- 1 正常结束
	-- 2 驱散结束
	-- 3 叠加/覆盖
	params.endType = params.endType or battle.BuffOverType.normal
	logf.battle.buff.over(' buff over!!! id=%s cfgId=%s holder=%s', self.id, self.cfgId, self.holder.seat)
	-- 属性减去(默认easyEffectFunc中的属性会直接在over时减去)
	if self.csvCfg.easyEffectFunc and self.isEffect then
		-- 因为可以修改节点的触发时机,所以可能会出现时机未到未触发, 但是却被驱散覆盖over掉的情况, 所以此时的直接减貌似有可能不正确
		-- 所以用了一个值来保存实际加上的
		self.overType = params.endType
		self:doEffect(self.csvCfg.easyEffectFunc, self.doEffectValue, true)
	end
	if params.endType ~= battle.BuffOverType.clean then
		-- 结束时触发的回调效果
		-- 注意不要给自己直接加在结束时增加多少属性的buff,会被下面的清理给回收掉,可以通过castBuff形式间接加
		if params.triggerCtrlEnd then
			self:triggerByMoment(battle.BuffTriggerPoint.onBuffControlEnd)
		end
		local triggerTypeTb = {
			battle.BuffTriggerPoint.onBuffOverNormal,
			battle.BuffTriggerPoint.onBuffOverDispel,
			battle.BuffTriggerPoint.onBuffOverlay,
		}
		self:triggerByMoment(triggerTypeTb[params.endType])
		self:triggerByMoment(battle.BuffTriggerPoint.onBuffOver)
	end

	-- 清理由节点触发增加的属性
	-- for attr, value in pairs(self.triggerAddAttrTb) do
	-- 	self.holder.attrs:addBuffAttr(attr, -value)		-- 负值, 减去	-- 自身清理时,不需要考虑能力弱化的影响
	-- end
	self.triggerAddAttrTb = {}
	-- 绑定buff的over管理:
	-- 这里测试时发现当主buff和子buff绑定后,如果一起在同一个遍历中删除,先删除主buff,
	-- 就会导致后面遍历到的子buff为空而报错,所以加了个延迟处理
	-- 1-主次buff, 自身创建出来的绑定子buff一并over掉
	self:overBuffsInTable(self.bondChildBuffsTb, params, function(a, b) return a.id < b.id end)

	-- 2-同级绑定buff (同级绑定的buff,只需要其中的一个buff来触发over即可,不需要反复触发over,否则会出现属性清理计算错误)
	self:overBuffsInTable(self.bondToOtherBuffsTb, params, function(a, b) return a.id < b.id end)

	if params.endType ~= battle.BuffOverType.clean and self.csvCfg.easyEffectFunc == "reborn" then
		self:triggerByMoment(battle.BuffTriggerPoint.onHolderReborn)
	end

	-- 结束时清理特效
	if self.isShow then
		local overCsvCfg = self.csvCfg

		battleEasy.deferNotifyCantJump(self.holder.view, "deleteBuffEffect",
			{
				aniSelectId = self:getEffectAniSelectId(),
				id = self.id,
				cfgId = self.cfgId,
				cfg = overCsvCfg,
				tostrModel = tostring(self.holder)
			}
		)

		-- self.holder.view:proxy():delBuffHolderAction(self.id,self.csvCfg.holderActionType and self.csvCfg.holderActionType.typ)

		-- buff触发更换战斗场景 结束时还原战斗场景
		if self.csvCfg.stageArgs then
			self.scene:recordSceneAlterBuff(self.id, nil)
			battleEasy.deferNotifyCantJump(self.holder.view, "alterBattleScene", {
				buffId = self.id,
				restore = true,
			})
		end

		self:playBuffProcessView()

		-- self:playTriggerView()
		if self.weatherCfgId then
			self.isShow = false
			-- 如果场上其他精灵身上有天气buff存在就不隐藏天气
			for _, obj in self.scene:ipairsHeros() do
				if obj and obj:checkOverlaySpecBuffExit('weather') then
					self.isShow = true
					break
				end
			end
			battleEasy.deferNotifyCantJump(self.holder.view, "weatherRefresh", self)
		end
	end

	if self.overlayType == battle.BuffOverlayType.Coexist or self.overlayType == battle.BuffOverlayType.CoexistLifeRound then
		self.holder.buffOverlayCount[self.cfgId] = self.holder.buffOverlayCount[self.cfgId] - 1
		if self.holder.buffOverlayCount[self.cfgId] > 0 then
			if self.isShow then
				-- 刷新特效表现
				local aniArgs = self:getBuffEffectAniArgs()
				if self.overlayType == battle.BuffOverlayType.Coexist then
					battleEasy.deferNotifyCantJump(self.holder.view, "playBuffAniEffect", aniArgs, {"iconEffect", "mainEffect"})
				end
			end
		end
	end

	--清除buff临时记录
	for name, _ in pairs(self.exRecordNameTb) do
		self.scene.extraRecord:cleanEventByKey(name, self.id)
	end

	-- 删除buff免疫
	self.holder:onBuffImmuneChange(self, true)

	--这里不能有其他逻辑
	battleComponents.unbindAll(self)
	self.holder.buffs:erase(self.id)	-- 存储在自己身上的直接删掉
	self.scene:deleteBuff(self.id)		-- 在这里做延迟删除
	self.scene:checkCowWithBuff(self)
end

function BuffModel:judgeOver()
	-- 生命周期小于等于0时, 表示已结束
	return self:getLifeRound() <= 0
end

local function isNeedUpdateLifeRound(lifeRoundType,triggerPoint,lifeTimeEnd)
	local isStart = (lifeTimeEnd and lifeTimeEnd == 0)
	local isEnd = (not lifeTimeEnd or lifeTimeEnd == 1)

	local isBattleTurnType = (not lifeRoundType or lifeRoundType == battle.lifeRoundType.battleTurn
		or lifeRoundType == battle.lifeRoundType.pureBattleTurn)
	local isBattleTurnStart = (triggerPoint == battle.BuffTriggerPoint.onHolderBattleTurnStart and isStart)
	local isBattleTurnEnd = (triggerPoint == battle.BuffTriggerPoint.onHolderBattleTurnEnd and isEnd)
	if isBattleTurnType and (isBattleTurnStart or isBattleTurnEnd) then
		return true
	end

	local isRoundType = (lifeRoundType and lifeRoundType == battle.lifeRoundType.round)
	local isRoundStart = (triggerPoint == battle.BuffTriggerPoint.onRoundStart and isStart)
	local isRoundEnd = (triggerPoint == battle.BuffTriggerPoint.onRoundEnd and isEnd)
	if isRoundType and (isRoundStart or isRoundEnd) then
		return true
	end

	return false
end

local getCurRoundByLifeRoundType = {
	[1] = function(buff, triggerPoint)
		-- 小回合
		local index = battle.BuffTriggerPoint.onHolderBattleTurnEnd == triggerPoint and 1 or 2
		return buff.holder:getBattleRoundAllWave(index)
	end,
	[2] = function(buff, triggerPoint)
		--大回合: <策划描述>
		--回合结束是当前回合的结束
		--回合开始是下回合的回合开始
		local isAdd = battle.BuffTriggerPoint.onRoundEnd == triggerPoint and 1 or 0
		return buff.scene.play.totalRound + buff.csvCfg.lifeTimeEnd * isAdd
	end,
	[3] = function(buff, triggerPoint)
		--排除额外回合的小回合
		local index = battle.BuffTriggerPoint.onHolderBattleTurnEnd == triggerPoint and 1 or 2
		return buff.holder:getBattleRoundAllWave(index, true)
	end,
}

function BuffModel:setLeftRound(triggerPoint)
	local passRound = 0
	local lifeRoundType = self.csvCfg.lifeRoundType or battle.lifeRoundType.battleTurn

	-- lifeRoundType == 3 排除额外回合的小回合
	if lifeRoundType == battle.lifeRoundType.pureBattleTurn and self.scene:getExtraBattleRoundMode() ~= battle.ExtraBattleRoundMode.normal then
		return
	end

	local curRound = getCurRoundByLifeRoundType[lifeRoundType](self, triggerPoint)

	if curRound > self.nowRound then
		passRound = curRound - self.nowRound -- 防止出现没有更新到的情况
		self.lifeRound = self.lifeRound - passRound
		self.nowRound = curRound
		if self:getLifeRound() <= 0 then
			self:over()
			return
		end

		-- 叠加类型为5的 buff们的生命周期判断
		if self.overlayType == 5 then
			local lastOverlayCount = self.overlayCount
			for i,lifeR in maptools.order_pairs(self.lifeRounds) do  -- 记录的叠加层数buff，默认只有有基本属性值的才能叠加属性, 在配置时注意下
				if lifeR > 0 then		-- 变成负的,就不再更新它了, 也不做删除, 只当作记录用,一般很难出现叠加十几层甚至几十层的buff
					lifeR = lifeR - passRound
					if lifeR <= 0 then
						self.overlayCount = self.overlayCount - 1  --层数 -1
						self.overlayCount = math.max(0, self.overlayCount)
						table.remove(self.lifeRounds, i) --这里把无效的lifeRound移除掉
					end
				end
			end
			if lastOverlayCount - self.overlayCount > 0 then
				self:refreshLerpValue(true)
				-- 叠加层数修改
				-- battleEasy.deferEffect(tostring(self.holder), "BuffModel.updateIconState",
						-- {id = self.id, overlayCount = self.overlayCount})
				if self.isShow then
					local aniArgs = self:getBuffEffectAniArgs()
					battleEasy.deferNotifyCantJump(self.holder.view, "playBuffAniEffect", aniArgs)
				end
			end
		end

		-- buff效果触发后，当有配置触发后效果维持的最大持续回合时，会判断回合,超过时立即结束,
		-- 注意, 这里的触发后持续回合,不是某个节点能持续的回合,而是buff整体的持续回合
		self.nodeManager:update(passRound)
	end
	if self.weatherCfgId then
		battleEasy.deferNotifyCantJump(self.holder.view, "weatherRefresh", self)
	end
end

function BuffModel:update(triggerPoint) -- triggerPoint-触发时刻
	if self.isOver then return end
	local roundId = self.scene.play.battleRoundTriggerId
	if roundId and gExtraRoundTrigger[roundId] and gExtraRoundTrigger[roundId].forbiddenBuff[triggerPoint] then
		return
	end
	-- 判断是否需要刷新buffValue
	self:triggerBuffValueByNode(triggerPoint)
	self:fillTriggerEnv(triggerPoint)

	-- 需要判断是回合开始后移除还是回合结束后移除：
	-- if self.lifeRound <= 0 then	self:over()	end
	-- 判断承受者 holder的存在状态 (大多数buff当holder死亡时就会自动结束, 除非是标记为死后触发的类型,可以多存在一段时间)
	-- (注意:当角色死亡时,应该先进行一次死亡时刻点的触发, 然后才是把holder身上没有over的buff 手动over掉)
	if not self.holder then self:overClean() return end		-- 这种情况可能不会发生
	if self.holder:isDeath() and self.nodeManager:isNoDeathTrigger() and not self.csvCfg.noDelWhenFakeDeath then self:over() return end

	-- --护盾类buff
	-- if self.csvCfg.easyEffectFunc == 'shield' and (self.holder.buffShield and self.holder.buffShield <= 0) then
	-- 	self:over()
	-- end
	-- 绑定类buff,分为与主buff绑定,和互相绑定两类,与主buff绑定的要判断MasterBuff的存在状态,互相绑定的要判断彼此之间的关系
	-- if self.args.bondedToMaster and self.args.bondedToMaster:judgeOver() then self:over() return end
	-- if self.args.bondedToOther then
	-- 	local ret = itertools.include(self.bondToOtherBuffsTb, function(buff)
	-- 		return buff:judgeOver()
	-- 	end)
	-- 	if ret then self:over() return end
	-- end

	-- 光环类buff需要同步caster的生死状态 光环buff有两种配置实现方式：
	-- 1-光环提供者先给自己加一个buff,然后给其它目标加时, 通过 castBuff, bond=主次绑定类型 可配置出来
	-- 2-使用下面的 isAuraType 记录, 这样施法者需要记录自身的光环给哪些目标添加了,同时自身死亡时需要处理所有光环buff的删除(需要加配表字段)
	if self.isAuraType and self.caster:isDeath() then self:overClean() return end

	--生命周期更新，以大回合为基本周期 (在scene.lua中更新)
	-- todo: 注意这里暂时没有计算波数的变化,后续有需要时需要加上
	-- 需要区分回合更新 和 自己的行动turn中更新, 目前buff的生命周期计算, 是以从自己turn到下一次自己的turn为一次的
	-- 如果是别人给自己加的buff, 则到自己行动顺序时就开始计算第一次了(这里有可能是比自己早加的或者比自己晚加的, 时间有些长短不同的差别)
	-- 注意: 如果给自己加buff的目标较早, 则需要延续到下一次自己行动时才能算是buff结束

	local updateLifeRound = isNeedUpdateLifeRound(self.csvCfg.lifeRoundType,triggerPoint,self.csvCfg.lifeTimeEnd)

	-- 不同的波次 直接结束buff 光环类buff可以不用
	-- local waveInherit = self.csvCfg.waveInherit
	-- if not self.isAuraType and self.nowWave ~= self.scene.play.curWave and not waveInherit then
	-- 	self:overClean()
	-- end

	if updateLifeRound then
		self:setLeftRound(triggerPoint)
	end

	-- 特殊buff的触发记录在28节点
	-- 普通buff的触发记录在nodemanager:trigger()
	if self.nodeManager:isNode0TriggerPoint(triggerPoint) then
	    if not self.scene.buffGlobalManager:checkBuffCanAdd(self,self.holder) then
		    self:overClean()
		    return
	    end
    end

    if self:isSpecBuff() and triggerPoint == battle.BuffTriggerPoint.onBuffTrigger then
	    if not self.scene.buffGlobalManager:checkBuffCanAdd(self,self.holder) then
		    self:overClean()
		    return
	    end
	    self.scene.buffGlobalManager:refreshBuffLimit(self.scene,self)
    end

	-- 对当前 triggerPoint 类型的节点,进行触发前置判断(这些条件不是配置表中的node中的条件,是与buff相关的条件)
	self:triggerByMoment(triggerPoint)
end


function BuffModel:isTrigger(triggerPoint, trigger)
	-- ExtraAttackCheckPointsMap
	if ExtraAttackCheckPointsMap[triggerPoint] then
		-- (不填默认和1相同) 1.额外行动回合不触发 2.都会触发 3.只在额外行动回合触发
		local t = self.nodeManager:getExtraAttack(triggerPoint)
	local extraAttackCheck = true
		if self.scene:beInExtraAttack() then
			extraAttackCheck = t[2] or t[3]
		else
			extraAttackCheck = not t[3]
		end
		if not extraAttackCheck then return false end
	end

	if triggerPoint == battle.BuffTriggerPoint.onBuffTrigger then
		local flag = (self.id == trigger.buffId)
		if flag then
			self.scene.buffGlobalManager:recordBuffTriggerType(self.holder.id,self.csvCfg.easyEffectFunc)
		end

		if not flag and SpecialOnBuffTrigger[trigger.easyEffectFunc] then
			if self.nodeManager:isTriggerPointExist(triggerPoint) then
				if trigger.checkEffectFunc == self.csvCfg.easyEffectFunc and trigger.isFirstTrigger then
					return true
				end
			end
		end
		return flag

	elseif triggerPoint == battle.BuffTriggerPoint.onHolderBattleTurnStart
		or triggerPoint == battle.BuffTriggerPoint.onHolderBattleTurnEnd
		or triggerPoint == battle.BuffTriggerPoint.onRoundStart
		or triggerPoint == battle.BuffTriggerPoint.onRoundEnd then
		return true
	end

	return self.nodeManager:isTriggerPointExist(triggerPoint)
end

function BuffModel:isSpecBuff()
	return SpecBuff[self.csvCfg.easyEffectFunc] or false
end



-- 主要用来刷新生命周期，具有叠加效果的buff会用到这个。不创建新的，直接刷新旧的生命周期
-- 这里可能会有个问题, 在buff中的一些效果，有些可能已经触发了, 就不会再触发了,
-- 或许应该加一个 reset函数, 把一些状态给重置掉,但是这样会变得比较复杂一些,所以还是区分下
-- 就简单的分为, 覆盖的直接创建新的,叠加的叠加到已有的上,同时重置部分状态,
-- todo: 刷新时,是否需要重新播放一遍特效动画 ???
-- 2类型在达到上限后只重置生命周期和表现
-- 7类型在达到上限后直接丢弃
function BuffModel:refresh(buffArgs,delta)
	local overlayType = self.overlayType
	delta = buffArgs.overlayCount or delta or 0

	if overlayType == nil then return end
	-- 2,8类型 满层设置生命周期后跳出刷新
	if ((overlayType == battle.BuffOverlayType.Overlay
		or overlayType == battle.BuffOverlayType.CoexistLifeRound)
		and self:getOverLayCount() == self.csvCfg.overlayLimit and delta >= 0) then
		self.lifeRound = buffArgs.lifeRound
		return
	end

	-- 层数增加时 刷新生命周期
	if delta > 0 and ( overlayType == battle.BuffOverlayType.Overlay
		or overlayType == battle.BuffOverlayType.OverlayDrop
		or overlayType == battle.BuffOverlayType.CoexistLifeRound ) then
		self.lifeRound = buffArgs.lifeRound
	end

	-- 具有叠加层数的buff，需要记录叠加层数和改变buff效果
	if overlayType == battle.BuffOverlayType.Overlay
		or overlayType == battle.BuffOverlayType.OverlayDrop
		or overlayType == battle.BuffOverlayType.CoexistLifeRound
		or overlayType == battle.BuffOverlayType.IndeLifeRound then --多层叠加buff

		self.overlayCount = cc.clampf(self.overlayCount + delta,1,self.csvCfg.overlayLimit)
		if self.isNumberType then
			if overlayType == battle.BuffOverlayType.IndeLifeRound then
				-- 刷新时把当前的生命周期插入到表中存储
				table.insert(self.lifeRounds, self.lifeRound)
			elseif overlayType == battle.BuffOverlayType.Overlay then
				-- overlayType == 2时, value值需要累加下
				self.buffValue = clone(self:cfg2Value(buffArgs.value))
			end
			-- 属性层数补充修正
			self:refreshLerpValue()
		end

		if self.isShow then
			local aniArgs = self:getBuffEffectAniArgs()
			self.isOnceEffectPlayed = true

			-- 每次刷新的时候如果有叠加，叠加的一些表现也刷新下
			if overlayType == battle.BuffOverlayType.Overlay or overlayType == battle.BuffOverlayType.OverlayDrop then
				battleEasy.deferNotifyCantJump(self.holder.view, "playBuffAniEffect", aniArgs)
			end

		end
	end
end

function BuffModel:triggerPrecheck()
	if table.get(self, 'objThatTriggeringMeNow', 'source') == tostring(self) then
		return false
	end
	return true
end

--按节点触发
function BuffModel:triggerByNode(nodeId)
	-- 由buff触发效果创造出来的skill或子buff, 不能反过来触发主buff的行为, 避免循环触发
	-- 比如 buff的某个触发时刻点 创建了一个技能, 技能中的某些行为又引发了buff的这个时刻点的触发,这样会循环下去
	if self:triggerPrecheck() then
		if self.nodeManager:check(nodeId) then
			self:takeEffect(nodeId)
		end
	end
end

function BuffModel:triggerBuffValueByNode(triggerPoint)
	self.nodeManager:visitNodeByPoint(triggerPoint, function(nodeId, node)
		if node.buffValueUpdatePoint and node.buffValueUpdatePoint == triggerPoint then
			if self.args.buffValueFormulaEnv then
				self.buffValue = clone(battleCsv.doFormula(self.args.buffValueFormula, self.args.buffValueFormulaEnv)) or self.buffValue
			else
				self.buffValue = clone(self:cfg2Value(self.args.buffValueFormula)) or self.buffValue
			end
		end
	end)
end

--按触发时刻触发,需转为节点
function BuffModel:triggerByMoment(triggerPoint)
	if not self:triggerPrecheck() then
		return
	end

	self.nodeManager:visitNodeByPoint(triggerPoint, function(nodeId, node)
		self:triggerByNode(nodeId)
	end)
end

-- BuffModel:over实际删除时会对bondToOtherBuffsTb进行排序
local function dealWithCastBonds(buffs)
	table.sort(buffs, function(a,b)
		return a.pro > b.pro
	end)

	local n = table.length(buffs)
	for pre = 1, n do
		for next = pre+1, n do
			if buffs[pre].pro == buffs[next].pro then
				table.insert(buffs[pre].buff.bondToOtherBuffsTb, buffs[next].buff)
				table.insert(buffs[next].buff.bondToOtherBuffsTb, buffs[pre].buff)
			end
			if math.floor(buffs[pre].pro) - math.floor(buffs[next].pro) == 1 then
				table.insert(buffs[pre].buff.bondChildBuffsTb, buffs[next].buff)
			end
		end
	end
end

-- buff效果生效, 属性和生效次数是基本的，其它的通过 buffType类型调用之前的逻辑
function BuffModel:takeEffect(nodeId)
	-- print('!!! BuffModel:takeEffect', self.id, nodeId)

	local triggerArgs = self.nodeManager:trigger(nodeId)

	-- effectFuncs funcArgs (补充:如果是0号节点,则忽略这两个字段,改为使用 easyEffectFunc 字段的函数调用)
	local makeit
	if nodeId == battle.BuffTriggerPoint.onNodeCall then		-- easyEffectFunc 0号节点的触发效果 (默认是只能加单属性的, 因为涉及到buff的叠加操作)
		if self.csvCfg.easyEffectFunc then
			self.value = self:getValue()
			self.doEffectValue = clone(self.value)
			makeit = self:doEffect(self.csvCfg.easyEffectFunc, self.value)
		end
	else
		self.castBuffGroup:push_back({})
		for i, funcStr in ipairs(triggerArgs.effectFuncs or {}) do
			local args = self:cfg2ValueWithTrigger(triggerArgs.funcArgs[i])
			local funstr = (funcStr == 'addAttr') and 'addAttrNode' or funcStr
			-- if type(args) == "number" then
			-- 	args = args*self.holder:getBuffEnhance(self:group())
			-- end
			args.originArgs = triggerArgs.funcArgs[i]
			makeit = self:doEffect(funstr, args)
		end

		for _, buffList in pairs(self.castBuffGroup:back()) do
			dealWithCastBonds(buffList)
		end
		self.castBuffGroup:pop_back()
	end

	logf.battle.buff.takeEffect("buff takeEffect !!! id=%s cfgId=%s groupid=%s holder=%s originValue=%s value=%s",
		self.id, self.cfgId, self.csvCfg.group,self.holder.seat, self.buffValue, self.value)

	logf.battle.buff.value("buff value !!! csv=%s buffValue=%s ",
		self.args.value, self.value)

	--在triggerend之前,buff在onTriggerEnd里面over
	self.isEffect = true
	self.nodeManager:onTriggerEnd(nodeId, makeit)
	-- 探险器动画展示
	if self.csvCfg.showExplorer then
		local explorerID = self.csvCfg.explorerID
		local explorerRes = csv.explorer.explorer[explorerID].simpleIcon
		battleEasy.queueNotify("queueExplorer", self.caster.faceTo, explorerRes)
	end
	-- 携带道具动画展示
	if self.csvCfg.showHeldItem then
		local heldItemID = self.csvCfg.heldItemID
		battleEasy.deferNotifyCantJump(self.caster.view, "showHeldItemEffect", heldItemID)
	end
end


-- 下面是几个常用的触发条件类型函数

-- 技能类型条件
function BuffModel:onSkillType(typeNum)
	local obj = (typeNum > 0) and self.holder or self.caster
	local curSkill = obj.curSkill
	typeNum = math.abs(typeNum)
	-- 没有放技能不生效
	if not curSkill then
		errorInWindows("onSkillType in %s curSkill is nil", self:toHumanString())
		return false
	end
	if curSkill.skillType == battle.SkillType.NormalSkill then		-- 只判断主动技能
		if typeNum == 1 and curSkill.skillType2 == battle.MainSkillType.BigSkill then		-- 当前技能是大招
			return true
		elseif typeNum == 2 and curSkill.skillType2 == battle.MainSkillType.SmallSkill then	-- 是小技能
			return true
		elseif typeNum == 3 and curSkill.skillType2 == battle.MainSkillType.NormalSkill then 	-- 普攻
			return true
		elseif typeNum == 4 then								-- 只要是主动攻击就行
			return true
		elseif typeNum == 5 and curSkill.skillType2 ~= battle.MainSkillType.BigSkill then
			return true
		end
	end
	return false
end

--生命值条件，当前剩余生命值/比例值检测  (不再比较小数点的值,只比较整数部分)
function BuffModel:onCurHP(valueType, val, compOpt) -- @compOpt,比较类型: 1- >, 2- <  相等时默认也是true
	local ret = false
	local curHp = math.floor(self.holder:hp())
	if valueType == 1 then	-- 比例值
		local perHp = math.floor(self.holder:hpMax()*val)
		if curHp == perHp then return true end
		if curHp < perHp then ret = true end
	elseif valueType == 2 then	-- 具体值
		if curHp == val then return true end
		if curHp < val then ret = true end
	end
	if compOpt == 1 then
		ret = not ret
	end
	return ret
end
-- 技能伤害条件, 当前技能总伤害与最大生命值的比例  (不再比较小数点的值,只比较整数部分)
function BuffModel:onSkillDamage(valueType, val, compOpt)
	local ret = false
	local damageValue
	local curAttackMeObj = self.holder.curAttackMeObj
	if curAttackMeObj and curAttackMeObj.curSkill then
		local final = curAttackMeObj.curSkill:getTargetsFinalResult(self.holder.id)
		damageValue =  final.damage.real:get(battle.ValueType.normal) - final.resumeHp.real:get(battle.ValueType.normal)
	end
	if not damageValue then return ret end
	damageValue = math.floor(math.abs(damageValue))
	if valueType == 1 then
		local perHp = math.floor(self.holder:hpMax()*val)
		if damageValue == perHp then return true end
		if damageValue < perHp then ret = true end
	elseif valueType == 2 then
		if damageValue == val then return true end
		if damageValue < val then ret = true end
	end
	if compOpt == 1 then
		ret = not ret
	end
	return ret
end

function BuffModel:onSomeFlag(valTb)
	local ret = true
	for i, str in ipairs(valTb) do
		ret = ret and self:cfg2ValueWithTrigger(str)
	end
	return ret
end

--辅助函数 获取buff相关目标
function BuffModel:getObjectsByCfg(nOrStr)
	local posMap= {
		left = {
			[1] = {x=2, y=1},
			[2] = {x=2, y=2},
			[3] = {x=2, y=3},
			[4] = {x=1, y=1},
			[5] = {x=1, y=2},
			[6] = {x=1, y=3},
		},
		right = {
			[7] = {x=1, y=1},
			[8] = {x=1, y=2},
			[9] = {x=1, y=3},
			[10] = {x=2, y=1},
			[11] = {x=2, y=2},
			[12] = {x=2, y=3},
		},
	}
	local pos = {
		left = {{4,5,6},{1,2,3}},
		right = {{7,8,9},{10,11,12}},
	}
	local NeighbourXY = {{0, 1}, {1, 0}, {0, -1}, {-1, 0}}
	local function getObjSideAllTarget(obj)
		local heros = self.scene:getHerosMap(obj.force)
		local ret = {}
		for _, v in heros:order_pairs() do
			if v and not v:isDeath() then
				table.insert(ret, v)
			end
		end
		return ret
	end
	local function getObjOtherSideAllTarget(obj)
		local heros = self.scene:getHerosMap(3-obj.force)
		local ret = {}
		for _, v in heros:order_pairs() do
			if v and not v:isDeath() then
				table.insert(ret, v)
			end
		end
		return ret
	end
	local function getObjNear(obj,targets)
		local positionMap = obj.force == 1 and posMap.left or posMap.right
		local position = obj.force == 1 and pos.left or pos.right
		local selfIdx = positionMap[obj.seat]
		local seatMap = {}
		-- 不包括主目标自身
		--seatMap[position[selfIdx.x][selfIdx.y]] = true
		for _, xy in ipairs(NeighbourXY) do
			local x = xy[1] + selfIdx.x
			local y = xy[2] + selfIdx.y
			if (x>0 and x<=2) and (y>0 and y<=3) then
				seatMap[position[x][y]] = true
			end
		end
		return arraytools.filter(targets, function(_, o)
			return seatMap[o.seat]
		end)
	end
	local function getRandomIdx(ret)
		if table.length(ret) > 0 then
			return ymrand.random(1, table.length(ret))
		end
	end
	local nOrStrType = type(nOrStr)
	if nOrStrType == 'number' then
		if nOrStr == battle.BuffExtraTargetType.holder then
			return {self.holder}
		elseif nOrStr == battle.BuffExtraTargetType.caster then
			return {self.caster}
		elseif nOrStr == battle.BuffExtraTargetType.holderForceNoDeathRandom then
			local all = getObjSideAllTarget(self.holder)
			local seat = getRandomIdx(all)
			return {all[seat]}
		elseif nOrStr == battle.BuffExtraTargetType.surroundHolderNoDath then
			return getObjNear(self.holder,getObjSideAllTarget(self.holder))
		elseif nOrStr == battle.BuffExtraTargetType.holderForce then
			return getObjSideAllTarget(self.holder)
		elseif nOrStr == battle.BuffExtraTargetType.casterForceNoDeathRandom then
			local all = getObjSideAllTarget(self.caster)
			local seat = getRandomIdx(all)
			return {all[seat]}
		elseif nOrStr == battle.BuffExtraTargetType.surroundCasterNoDath then
			return getObjNear(self.caster,getObjSideAllTarget(self.caster))
		elseif nOrStr == battle.BuffExtraTargetType.casterForce then
			return getObjSideAllTarget(self.caster)
		elseif nOrStr == battle.BuffExtraTargetType.holderEnemyForce then
			return getObjOtherSideAllTarget(self.holder)
		elseif nOrStr == battle.BuffExtraTargetType.casterEnemyForce then
			return getObjOtherSideAllTarget(self.caster)
		elseif nOrStr == battle.BuffExtraTargetType.skillOwner then
			return {self.objThatTriggeringMeNow.owner}
		elseif nOrStr == battle.BuffExtraTargetType.killHolder then
			return {self.holder.attackMeDeadObj}
		elseif nOrStr == battle.BuffExtraTargetType.casterEnemyForceRandom then
			local all = getObjOtherSideAllTarget(self.caster)
			local seat = getRandomIdx(all)
			return {all[seat]}
		elseif nOrStr == battle.BuffExtraTargetType.surroundHolderKill then
			return getObjNear(self.objThatTriggeringMeNow,getObjSideAllTarget(self.objThatTriggeringMeNow))
		elseif nOrStr == battle.BuffExtraTargetType.triggerObject then
			return {self.objThatTriggeringMeNow.obj}
		else
			return self.extraTargets[nOrStr]
		end

	elseif nOrStrType == 'table' then
		if (nOrStr.input and nOrStr.process) then
			-- 处理 caster 和 holder以 input 和 process为形式的筛选
			local targets = newTargetFinder(self.caster, self.holder, nil, nil, nOrStr)
			return targets
		end
	else
		-- 处理 caster 和 holder 的特殊筛选
		-- 字符串表示要手动选择目标,需要使用对应的目标选择函数
		return self:cfg2ValueWithTrigger(nOrStr)
	end
end


function BuffModel:refreshExtraTargets(idx,targets)
	self.extraTargets[idx] = targets
end

local fromSkillTriggerPoint = {
    [battle.BuffTriggerPoint.onHolderAttackBefore] = true,
    [battle.BuffTriggerPoint.onHolderBeforeBeHit] = true,
    [battle.BuffTriggerPoint.onHolderAfterBeHit] = true,
    [battle.BuffTriggerPoint.onHolderFinallyBeHit] = true,
    [battle.BuffTriggerPoint.onHolderAttackEnd] = true,
    [battle.BuffTriggerPoint.onHolderKillHandleChooseTarget] = true,
    [battle.BuffTriggerPoint.onHolderKillTarget] = true,
    [battle.BuffTriggerPoint.onHolderMateKilledBySkill] = true,
}

function BuffModel:fillTriggerEnv(triggerPoint)
	self.triggerEnv = {}
	if fromSkillTriggerPoint[triggerPoint] then
		self.triggerEnv.skill = battleCsv.CsvSkill.new(self.objThatTriggeringMeNow)
	elseif triggerPoint == battle.BuffTriggerPoint.onBuffBeAdd then
		self.triggerEnv.beAddBuff = battleCsv.CsvBuff.new(self.objThatTriggeringMeNow)
	else
		self.triggerEnv = self.objThatTriggeringMeNow or self.triggerEnv
	end
end

function BuffModel:playTriggerPointEffect()
	if self.isOver then return end
	if self.csvCfg and not self.csvCfg.buffActionEffect then return end
	if self.csvCfg.buffActionEffect and not self.csvCfg.buffActionEffect.triggerEffect then return end
	local effect = csvClone(self.csvCfg.buffActionEffect.triggerEffect)
	if effect.onceEffectResPath then
		effect.onceEffectPos = effect.onceEffectPos or 0
		effect.onceEffectOffsetPos = effect.onceEffectOffsetPos or cc.p(0,0)
	end
	local aniArgs = self:getBuffEffectAniArgs()
	aniArgs.csvCfg = effect
	battleEasy.deferNotifyCantJump(self.holder.view, "playBuffAniEffect", aniArgs)

	if effect.showHeldItem then
		local heldItemID = effect.heldItemID
		battleEasy.deferNotifyCantJump(self.holder.view, "showHeldItemEffect", heldItemID)
	end
end

--获取buff的生命周期
function BuffModel:getLifeRound()
	return self.lifeRound
end

function BuffModel:getValue()
	-- buffValue 可能不存在
	if not self.buffValue then return end
	if self.isNumberType then
		local enhance1 = self.buffInitEnhanceVal or 0
		local enhance2 = self.holder:getBuffEnhance(self:group(), 2)
		local value = self.buffValue * math.max(enhance1 + enhance2 + 1, 0)

		if self.overlayType == battle.BuffOverlayType.Overlay
			or self.overlayType == battle.BuffOverlayType.OverlayDrop then
            value = value * self:getOverLayCount()


		elseif self.overlayType == battle.BuffOverlayType.IndeLifeRound then
			local ret = itertools.filter(self.lifeRounds, function(i, lifeR)
				return lifeR > 0
			end)
			value = value * (1 + table.length(ret))	-- 自己的+叠加的buff们的
		end

		return value
	end
	return self.value or clone(self.buffValue)
end
-- 使用该方法需要保证 self.value 是可以被替换的
function BuffModel:setValue(value)
	self.buffValue = value
    self.value = self:getValue()
	self.isNumberType = type(self.buffValue) == "number"
end

-- 插值刷新 用于添加即触发value发生改变时补偿
-- 存在nodeId == 0 并且 触发节点为 1节点
function BuffModel:refreshLerpValue(isOver)
	if not self.isNumberType then return end
	if self.csvCfg.easyEffectFunc and self.nodeManager:isNode0TriggerPoint(battle.BuffTriggerPoint.onBuffCreate) then

		local oldValue = self.doEffectValue
		self.value = self:getValue()
		local lerpValue = self.value - oldValue
		-- TODO 不是属性类的buff可能不需要补偿？
		-- otherBuffEnhance 对value修正的时候可能将修正值修成小于当前值
		-- 导致buff的value会是负数
		-- if self.csvCfg.easyEffectFunc ~= "addAttr" then
		-- 	if lerpValue < 0 then
		-- 		errorInWindows("tip buff(%s) easyEffectFunc(%s) when lerpValue < 0", self.cfgId, self.csvCfg.easyEffectFunc)
		-- 		lerpValue = 0
		-- 	end
		-- end
		self.doEffectValue = self.value
		self:doEffect(self.csvCfg.easyEffectFunc, lerpValue, isOver)
	end
end

function BuffModel:playBuffProcessView()
	local isOver = self.isOver
	if self.csvCfg.buffActionEffect then
		for action,replaceAct in csvMapPairs(self.csvCfg.buffActionEffect) do
			if isOver then
				self.holder.scene:addObjViewToBattleTurn(self.holder,'PopAction',battle.SpriteActionTable[action] or action,self.id)
			else
				self.holder.scene:addObjViewToBattleTurn(self.holder,'PushAction',battle.SpriteActionTable[action] or action,replaceAct,self.id)
			end
		end
		self.holder.scene:addObjViewToBattleTurn(self.holder,'PlayState',battle.SpriteActionTable.standby)
	end
end

function BuffModel:checkBuffCanAdd(cfgId,group,groupPower)
	if not self.isInited then return true end
	local ret = true
	-- 免疫: 已存在buff会挡掉某些将要加上来的buff, 组免疫
	local groupRelation = gBuffGroupRelationCsv[self:group()]
	if groupRelation then
		if battleCsv.hasBuffGroup(groupRelation.immuneGroup,group) and groupPower.beImmune == 1 then
			ret = false
		end
		-- 当权限组存在时,只允许部分buff组被添加
		if csvSize(groupRelation.powerGroup) > 0 and not battleCsv.hasBuffGroup(groupRelation.powerGroup,group) then
			return false
		end
	end

	-- 免疫：免疫buffid
	local immuneBuffs = self.csvCfg.immuneBuff
	if immuneBuffs and groupPower.beImmune == 1 then
		for _, immuneBuffId in ipairs(immuneBuffs) do
			if cfgId == immuneBuffId then
				ret = false
				break
			end
		end
	end

	if not ret then
		-- 显示被免疫buff的免疫飘字
		battleEasy.deferNotifyCantJump(self.holder.view, "showBuffImmuneEffect",group)
		self:triggerByMoment(battle.BuffTriggerPoint.onBuffTrigger,{
			buffId = self.id
		})
	end

	return ret
end

function BuffModel:group()
	local group = self.csvCfg.group
	local cache = self.scene:getConvertGroupCache()
	if cache and cache.assignGroup[group] then
		return cache.convertGroup
	end
	return group

	-- -- 场景更换buff效果: 1. 更换场景 2.将属于指定buff组的buff更换组别
	-- local buffCfgId, cache = self.scene:getExistLastSceneAlterBuff()
	-- if buffCfgId ~= -1 and cache and cache.assignGroup[self.csvCfg.group] then
	-- 	return cache.convertGroup
	-- end
	-- return self.csvCfg.group
end

function BuffModel:addExRecord(eventName, args)
	self.scene.extraRecord:addExRecord(eventName, args, self.id)
	self.exRecordNameTb[eventName] = true
end

function BuffModel:getEventByKey(eventName)
	return self.scene.extraRecord:getEventByKey(eventName, self.id)
end

function BuffModel:getOverLayCount()
	if self.overlayType == battle.BuffOverlayType.Coexist or self.overlayType == battle.BuffOverlayType.CoexistLifeRound then
		return self.holder.buffOverlayCount[self.cfgId]
	end
	return self.overlayCount
end

function BuffModel:BeDispel(all)
	if all then return self:over({endType = battle.BuffOverType.dispel}) end
	if self.overlayType == battle.BuffOverlayType.Overlay
		or self.overlayType == battle.BuffOverlayType.OverlayDrop then
		if self.overlayCount == 1 then return self:over({endType = battle.BuffOverType.dispel}) end
		self:refresh(self.args,-1)
	end
end

function BuffModel:getEffectAniSelectId()
	local cfg = self.csvCfg
	if cfg.effectAniChoose.type == battle.BuffEffectAniType.OverlayCount then
		return cfg.effectAniChoose.mapping[self:getOverLayCount()]
	end
	return 1
end

function BuffModel:getBuffEffectAniArgs()
	local isSelfTurn = false
	local curHero = self.holder.scene.play.curHero
	if curHero then
		isSelfTurn = (curHero.id == self.holder.id)
	end
	local aniArgs = {
		aniSelectId = self:getEffectAniSelectId(),
		id = self.id,
		cfgId = self.cfgId,
		overlayCount = self:getOverLayCount(),
		csvCfg = self.csvCfg,
		tostrModel = tostring(self.holder),
		tostrCaster = tostring(self.caster),
		isSelfTurn = isSelfTurn,
		isOnceEffectPlayed = self.isOnceEffectPlayed,
		args = self.args,
	}
	return aniArgs
end

function BuffModel:updateWithTrigger(triggerPoint, trigger)
	self.objThatTriggeringMeNow = trigger
	self:update(triggerPoint)
end

function BuffModel:onTriggerEvent(event)
	local triggerPoint, trigger = event.name, event.args
	if self:isTrigger(triggerPoint, trigger) then
		self:updateWithTrigger(triggerPoint, trigger)
	end
end
function BuffModel:setCsvObject(obj)
	self.csvObject = obj
end

function BuffModel:getCsvObject()
	return self.csvObject
end

function BuffModel:toHumanString()
	return string.format("BuffModel: %s(%s)", self.id, self.cfgId)
end
