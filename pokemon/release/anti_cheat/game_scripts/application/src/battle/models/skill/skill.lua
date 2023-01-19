--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
--
-- 常规技能
-- skillType = 0  用技能表字段 skillType2区分: battle.MainSkillType
--


local _max = math.max
local _min = math.min
local _insert = table.insert

local PassiveSkillTypes = battle.PassiveSkillTypes

local SkillModel = class("Skill")
battleSkill.SkillModel = SkillModel

function SkillModel:ctor(scene, owner, cfg, level, source)
	self.scene = scene
	self.owner = owner
	self.id = cfg.id
	self.level = level or 1
	self.cfg = cfg
	self.chargeArgs = cfg.chargeArgs        -- 蓄力参数
	self.source = source
	self.checkRoundAttackTime = -1 -- 每回合判定一次 (初始为-1,刚初始化时,play中的round也是0,大家回合都相同会导致无法进行第一次判断)
	self.chargeRound = nil -- 开始蓄力大回合（轮到自己才算回合）
	self.spellRound = -99 -- 真正释放战斗回合
	self.isSpellable = false
	self.targetsFormulaResult = {} -- {targetID: {key: val}} 对target的公式一次计算, {}表示被选中过
	self.allTargets = {}	-- {[seat]=obj} 存储每个本次技能攻击到的目标
	self.allDamageTargets = {} --实际受伤害的
	self.protecterObjs = {} -- 由于保护别人而受伤害的
	self.allProcessesTargets = {} --存储每个过程段的目标
	self.stateInfoTb = {} 		-- 技能状态 {canSpell=true, leftCd=cd}

	self.targetsFinalResult = {}		--存储每个目标受到的最终伤害值或者加血值，格式: {[targetId]={key,val},{}} 这个只是技能配表中算出来的值
	self.targetsProcessResult = {}       	--存储分段的数据

	self.skillType = cfg.skillType		-- 技能大类区分 0:常规技能1:增加属性2:光环buff类3:被动技能条件触发（1，2暂时不用）
	self.skillType2 = cfg.skillType2 	-- 技能细分类型: battle.MainSkillType
	self.skillFormulaType = nil			-- 技能是伤害还是治疗

	self.killedTargetsTb = {}			-- 记录技能中击杀的目标
	self.canjumpBigSkill = false

	-- self.realFinalDmgData = {}				--存储技能对目标造成真实的最终伤害值,是经过各种加成减免后的
	self.disposeDatasOnSkillStart = {}		-- 技能前数据清空
	self.disposeDatasOnSkillEnd = {}		-- 技能后数据清空
	self.disposeDatasAfterComeBack = {}			-- 返回后数据清空

	self.skillCalDamageProcessId = self.cfg.skillCalDamageProcessId

	-- for easy
	self.processes = {} -- 存储的过程段数据
	self.realProcess = {} -- 真实的过程段
	self.processEventCsv = {} -- gProcessEventCsv
	self.actionSegArgs = {}
	self.isSpellTo = false -- 技能是否在释放
	self.counterAttackForView = false -- 本次攻击是否为反击 表现用
	-- local lastDmgProcessIdx
	local hasJumpSeg = false
	local function otherEventHasJumpSeg(cfg)
		local otherEventIDs = cfg.otherEventIDs
		if otherEventIDs then
			for _, eventID in ipairs(otherEventIDs) do
				local cfg2 = csv.effect_event[gEffectByEventCsv[eventID]]
				if cfg2.jumpFlag then
					return true
				end
			end
		end
		return false
	end

	local effectCfg,processCfg
	for _, processID in ipairs(cfg.skillProcess) do
		processCfg = csvClone(csv.skill_process[processID])
		if processCfg == nil then
			printDebug("技能id: %d 过程段id: %d 缺失!!!!!!", self.id, processID)
		end
		_insert(self.processes, processCfg)
		effectCfg = gProcessEventCsv and gProcessEventCsv[processID] or nil
		-- if effectCfg and effectCfg.damageSeg then
		-- 	lastDmgProcessIdx = i
		-- end
		if effectCfg and (effectCfg.jumpFlag or otherEventHasJumpSeg(effectCfg)) then
			hasJumpSeg = true
		end

		processCfg.isSegProcess = (effectCfg and effectCfg.segInterval) and true or false
		processCfg.segType = battle.SkillSegType.buff
		if processCfg.isSegProcess then
			processCfg.segType = effectCfg.damageSeg and battle.SkillSegType.damage or battle.SkillSegType.resumeHp
		end

		self.processEventCsv[processID] = effectCfg
	end
	-- if lastDmgProcessIdx then
	-- 	self.processes[lastDmgProcessIdx].isLastDmgProcess = true
	-- end
	self.canJump = hasJumpSeg

	-- SkillAttrsInCsv
	for _, attrName in ipairs(battle.SkillAttrsInCsv) do
		self[attrName] = self.cfg[attrName] or 0
	end
	self.costMp1 = self.cfg.costMp1 / 1000

	self:initSkillType()
	-- env,公式计算用
	self.protectedEnv = battleCsv.makeProtectedEnv(self.owner, self)

	-- 初始化技能属性参数
	self:initSkillAttrValue()
end

function SkillModel:updateStateInfoTb()
	local precent = self.owner:mp1()/self.owner:mp1Max()*self.costMp1
	local leftStartRound =  math.max(self.startRound - self.owner:getBattleRound(2), 0)
	self.stateInfoTb = {
		canSpell = self:canSpell(),
		leftCd = self:getLeftCDRound(),
		leftStartRound = leftStartRound,
		precent = self.costMp1 == 0 and 1 or math.min(precent,1),
		level = self:getLevel()
	}
end

-- @deprecated
function SkillModel:initSkillAttrValue()
	for _, attrName in ipairs(battle.SkillAttrsInCsv) do
		self[attrName.."Attr"] = function (self)
			error(string.format('%s Attr in SkillModel was deprecated', attrName))
			return self.cfg[attrName]
		end
	end
end

function SkillModel:getLevel()
	return _max(self.owner:dealOpenValueByKey("skillLevel"..self.skillType2, self.level), 1)
end

function SkillModel:resetOnNewRound()
	self.counterAttackForView = false
	self.checkRoundAttackTime = -1
	self.isSpellable = false
end

function SkillModel:resetOnNewWave()
	-- 如果在蓄力要打断蓄力
	if self.chargeRound then
		battleEasy.queueNotifyFor(self.owner.view, 'playCharge', {},true)
	end
	self.checkRoundAttackTime = -1
	self.chargeRound = nil
	self.spellRound = -99
	self.isSpellable = false
end

function SkillModel:_canSpell()
	logf.battle.skill.canSpellSkillId(' canSpell skillId = %d, ownerId = %d', self.id, self.owner.seat)
	local curRound = self.owner:getBattleRound(2)

	-- 连击无视mp消耗和cd 反击、协战邀战根据参数无视mp消耗和cd
	local ignoreMpAndCd = (self.owner.exAttackMode == battle.ExtraAttackMode.combo and self.owner.exAttackSkillID == self.id)
	ignoreMpAndCd = ignoreMpAndCd or (self.owner.exAttackArgs and self.owner.exAttackArgs.costType == 1)

	-- 无法使用该技能
	if self.owner:isLogicStateExit(battle.ObjectLogicState.cantUseSkill, {skillType2 = self.skillType2, skillId = self.id}) then
	-- if self.owner:isSKillType2Close(self.skillType2) then
		return false,1
	end

	-- if self.owner:isLogicStateExit(battle.ObjectLogicState.cantUseSkill, {}) then
	-- if self.owner:isSKillType2Close(self.skillType2) then
	-- 	return false,2
	-- end

	-- 初次释放需要的回合数
	if curRound < self.startRound and not (self.scene:beInExtraAttack() and self:isNormalSkillType()) then
		return false, 3
	end

	-- 技能指示器选中的目标大于0
	if self:isNormalSkillType() then
		local tar = self:getTargetsHint()
		local sneerAtMeObj = self.owner:getSneerObj()
		if sneerAtMeObj and sneerAtMeObj:isLogicStateExit(battle.ObjectLogicState.cantBeSelect,{fromObj = self.owner}) then
			if self.owner:isBeInDuel() then
				return false, 4
			else
				tar = self.owner:getCanAttackObjs(sneerAtMeObj.force)
			end
		end

		if table.length(tar) == 0 and self.cfg.damageFormula and self.owner:isBeInConfusion() and
		not (self.owner.exAttackArgs and self.owner.exAttackArgs.isFixedForce) then
			local selfSideObjs, enemySideObjs, needSelfForce = self.owner:getConfusionCheckInfos()
			if needSelfForce then
				tar = selfSideObjs
			else
				tar = table.length(selfSideObjs) > 0  and selfSideObjs or enemySideObjs
			end
		end

		if table.length(tar) == 0 then return false, 4 end
	end

	-- 充能(充能时也不能使用其它技能)(充能好了立即释放,不要重复判断其它条件)
	if self:isChargeSkill() and self:isChargeOK() then
		return true, 5
	end

	-- skillType2为1 是大招 需要只要mp满了就能用
	if self.skillType2 == battle.MainSkillType.BigSkill then
		if ignoreMpAndCd then
			return true, 6
		end
		logf.battle.skill.costMp1(' mp1Max=%s, curMp1=%s', self.owner:mp1Max(), self.owner:mp1())
		--变身敌方后可以免费获得一次大招 self.owner.changedAndCanUseMainSkillOnce == 1 这个先注掉 以后不用就删了
		local ret = (self.owner:mp1() / self.owner:mp1Max()) >= self.costMp1
		-- 没有cd时 返回怒气百分比
		if self.cdRound == 0 then
			return ret, 7
		-- 存在cd且怒气不足时 直接返回怒气百分比
		elseif not ret then
			return false, 8
		end
	end

	-- -- 如果需要消耗MP 则判断MP是否符合需求
	-- if self.costMp1 and self.costMp1 > 0 then
	-- 	logf.battle.skill.costMp1(' costMp1=%s, curMp1=%s', self.costMp1, self.owner:mp1())
	-- 	return self.owner:mp1() >= self.costMp1, 6
	-- end

	return ignoreMpAndCd or 1 > self:getLeftCDRound(), 9
end

function SkillModel:canSpell()
	-- 当前环境无技能的权重
	if self.owner.exAttackArgs then
		if self.owner.exAttackArgs.skillPowerMap and self.owner.exAttackArgs.skillPowerMap[self.skillType2 + 1] == 0 then
			return false
		end
	end

	local round = self.owner:getEventByKey(battle.ExRecordEvent.roundAttackTime)
	-- 防止一个战斗回合内多次判定mp
	if round == self.checkRoundAttackTime and self.skillType2 == battle.MainSkillType.BigSkill then
		return self.isSpellable
	end

	self.checkRoundAttackTime = round

	local judgeNum = 0
	self.isSpellable, judgeNum = self:_canSpell()

	-- 冷却回合数
	logf.battle.skill.skillCD(' skillCD: 当前round= %d, 使用时spellRound= %d, cd= %d spellType= %d', round, self.spellRound, self.cdRound, judgeNum)

	return self.isSpellable
end

-- 是否是蓄力技能
function SkillModel:isChargeSkill()
	return self.chargeArgs and self.chargeArgs.round > 0
end

-- 蓄力阶段
function SkillModel:isCharging()
	local breakChargingData = self.owner:getOverlaySpecBuffByIdx("breakCharging")

	if self.chargeRound and not breakChargingData then
		return self.owner:getBattleRound(2) - self.chargeRound < self.chargeArgs.round
	end
	return false
end

-- 蓄力完成
function SkillModel:isChargeOK()
	local breakChargingData = self.owner:getOverlaySpecBuffByIdx("breakCharging")

	if self.chargeRound then
		-- mode == 2 相当于蓄力提前完成
		if breakChargingData then return breakChargingData.mode == 2
		else return self.owner:getBattleRound(2) - self.chargeRound >= self.chargeArgs.round end
	end
	return false
end

-- 数据清理
function SkillModel:cleanData()
	self.targetsFormulaResult = {}
	self.targetsFinalResult = {}
	self.targetsProcessResult = {}
	self.allTargets = {}	-- {[id]=obj} 存储每个本次技能攻击到的目标
	self.allDamageTargets = {}
	self.protecterObjs = {}
	self.allProcessesTargets = {}
	-- 技能记录数据清空  只清空当前将要使用的技能的,可能角色身上此时有多个技能的记录
	self.disposeDatasOnSkillStart = {}		 	-- 技能前数据清空
	self.disposeDatasOnSkillEnd = {}			-- 技能后数据清空
	self.disposeDatasAfterComeBack = {}			-- 返回后数据清空
	self.killedTargetsTb = {}					-- 清理死亡记录数据
	-- self.realFinalDmgData = {}					-- 对技能每个目标的真正的伤害数据记录清空
	self.actionSegArgs = {}
	self.realProcess = {}
end

-- 开始蓄力 蓄力时 cd 和 怒气 都开始计算, 被打断时返还
function SkillModel:startCharge()
	self.chargeRound = self.owner:getBattleRound(2)
	self.lastSpellRound = self.spellRound		-- 记录上一次的冷却回合,给充能被打断时恢复用
	self.spellRound = self.owner:getBattleRound(2)		-- 充能时就开始冷却
	-- 扣除怒气 消耗的mp的显示在技能开始时就立即扣除
	self:startDeductMp()
	self.hadDeductedMp = true
	-- 播放蓄力动画
	battleEasy.queueNotifyFor(self.owner.view, 'playCharge', self.chargeArgs.action,false)
end
-- 蓄力结束
function SkillModel:endCharge()
	self.chargeRound = nil
	battleEasy.queueNotifyFor(self.owner.view, 'playCharge', self.chargeArgs.action,true)
end

function SkillModel:updateSkillDamageProcessId()
	-- 额外攻击模式
	local dmgProcessIdMap = self.cfg.diffSkillCalDmgProcessId
	if dmgProcessIdMap.exAttackMode then
		self.skillCalDamageProcessId = dmgProcessIdMap.exAttackMode[self.owner.exAttackMode] or self.cfg.skillCalDamageProcessId
	end
end

-- 开始施法 -- 冷却记录
function SkillModel:startSpell()
	self.isSpellable = false
	self.isSpellTo = true
	if self.chargeRound then	-- 有充能回合时,不需要重新记录冷却回合
		self:endCharge()
	elseif self.owner.exAttackArgs and self.owner.exAttackArgs.costType == 1 then
		if self.spellRound < 1 then self.spellRound = -self.cfg.cdRound end
	elseif not (self.owner.exAttackSkillID == self.id) then
		self.spellRound = self.owner:getBattleRound(2)
	end
	self:updateSkillDamageProcessId()
end

function SkillModel:isJumpBigSkill()
	return self.skillType2 == battle.MainSkillType.BigSkill and self.canJump and userDefault.getForeverLocalKey("mainSkillPass", false)
end

-- 技能开始时扣除 mp
function SkillModel:startDeductMp(isBack)
	if self.hadDeductedMp then	-- 如果已经扣除过mp就不再重复扣了
		self.hadDeductedMp = false
		return
	end
	-- 不消耗怒气
	if self.owner.exAttackArgs and self.owner.exAttackArgs.costType == 1 then return end
	if self.skillType2 == battle.MainSkillType.BigSkill then
		--有变身buff时,可以免费放一次大招,且不消耗怒气 策划想用配置
		-- if self.changedAndCanUseMainSkillOnce == 1 then
		-- 	self.changedAndCanUseMainSkillOnce = 0 --0 表示已经放过1次了，当前回合不会再触发免费大招
		-- else
		-- 	self.owner:setMP1(0, 0)			-- 释放大招 固定将怒气值降为0
		-- end

		local prob, fix = 1, 1
		if self.cfg.costMp1Args then
			self.protectedEnv:resetEnv()
			local env = battleCsv.fillFuncEnv(self.protectedEnv, {})
			local data = battleCsv.doFormula(self.cfg.costMp1Args,env)
			prob, fix = data[1] or prob, data[2] or fix
		end

		local randret = ymrand.random()
		local cost = self.owner:mp1Max() * self.costMp1
		if prob > randret then
			cost = cost * fix
		end
		local mpleft = self.owner:mp1() - cost
		self.owner:setMP1(mpleft, mpleft)
		return
	end

	-- TODO: costMp1 暂时无用 但这段代码保留
	-- if self.costMp1 and self.costMp1 > 0 then
	-- 	local mp = self.owner:mp1() - self.costMp1
	-- 	self.owner:setMP1(mp, mp)
	-- end
end

function SkillModel:ipairsProcess()
	local idx = 1
	return function()
		local ret,retIdx = self.realProcess[idx]
		if ret then
			retIdx = idx
			idx = idx + 1
			return retIdx,self.processes[ret]
		end
		return nil
	end
end

function SkillModel:isLastProcess(idx)
	return table.length(self.realProcess) == idx
end

function SkillModel:sortRealProcess()
	local _random = ymrand.random
	local effectCfg,lastDmgProcessIdx,prob,processCfg
	self.protectedEnv:resetEnv()
	local env = battleCsv.fillFuncEnv(self.protectedEnv, {
		target = self.owner:getCurTarget(),
	})
	for i, ret in ipairs(self.processes) do
		processCfg = self.processes[i]
		effectCfg = self.processEventCsv[ret.id]

		local probArgExit = ret.extraArgs
		prob = probArgExit and battleCsv.doFormula(probArgExit.prob,env) or 1
		if prob > _random() then
			if probArgExit then
				self.owner:addExRecord(battle.ExRecordEvent.comboProcessTotalNum, 1)
			end

			if effectCfg and effectCfg.damageSeg then
				if lastDmgProcessIdx then
					self.processes[lastDmgProcessIdx].isLastDmgProcess = false
				end
				ret.isLastDmgProcess = true
				lastDmgProcessIdx = i
			end
			table.insert(self.realProcess,i)
			ret.isLastProcess = (table.length(self.processes) == i)
		else
			-- if effectCfg.eventID ~= 1 then
			-- 	print("sortRealProcess",effectCfg.eventID)
			-- end
			self.owner.view:proxy():saveIgnoreEffect(processCfg.id,processCfg.effectEventID)
		end
	end
end

function SkillModel:getProcessArg(index)
	if self.realProcess[index] then
		return self.processes[self.realProcess[index]]
	end
end

function SkillModel:initSkillType()
	-- 两者公式都存在时,按照特定规则去区分
	if self.cfg.damageFormula and self.cfg.hpFormula then
		self.skillFormulaType = battle.SkillFormulaType.fix
		return
	end

	if self.cfg.damageFormula then
		self.skillFormulaType = battle.SkillFormulaType.damage
	elseif self.cfg.hpFormula then
		self.skillFormulaType = battle.SkillFormulaType.resumeHp
	end
end

local csvSegType = {
	[battle.SkillSegType.damage] = battle.SkillFormulaType.damage,
	[battle.SkillSegType.resumeHp] = battle.SkillFormulaType.resumeHp,
	[battle.SkillSegType.buff] = battle.SkillFormulaType.fix,
}

--临时记录未死亡的目标
local function filterNoDeadObjectsToMap(objects)
	-- 临时记录
	local notDeadHash = {}
	for _, obj in ipairs(objects) do
		if obj:hp() > 0 then
			notDeadHash[obj.id] = true
		end
	end
	return notDeadHash
end

function SkillModel:processBefore(skillBB)
	-- 1.0 设置当前使用的收集函数记录表
	local play01 = gRootViewProxy:proxy():pushDeferList(self.id, 'play01')
	-- 1.消耗mp1 --消耗的mp的显示在技能开始时就立即扣除 充能时已经扣除过一次mp了,这里就不再重复扣了
	self:startDeductMp()
	-- 筛选真实的过程段 有些过程段有添加概率 会被去除
	self:sortRealProcess()
	-- 2. 处理过程段, 选择目标, 加技能的buff, 伤害处理
	local skillCfg = skillBB.skillCfg
	local skillDamageType = skillCfg.skillDamageType
	local firstSpine = true
	local effectCfg

	skillBB.processArgs = {}

	for i, processCfg in self:ipairsProcess() do
		local args = self:onProcess(processCfg, skillBB.target)		-- 格式: {process=processCfg, targets=targets}
		args.skillId = self.id
		-- args.skill = skillCfg
		-- args.skillDamageType = skillDamageType
		args.values = {} -- {[target.id] = values}	-- 修改成下面的 segValues 了
		args.index = i

		skillBB.processArgs[i] = args

		self.allProcessesTargets[processCfg.id] = args.targets -- array
		local extraTarget
		local lastProcessArg = self:getProcessArg(i-1)
		if i > 1 and lastProcessArg and self.allProcessesTargets[lastProcessArg.id] then
			extraTarget = self.allProcessesTargets[lastProcessArg.id]
		end

		local actionArg = {}
		-- 记录effectEventID
		if processCfg.effectEventID then
			actionArg.lifeTime = self.cfg.actionTime
			actionArg.processId = processCfg.id
			effectCfg = self.processEventCsv[processCfg.id]

			local isAction = false
			if effectCfg then
				-- 额外动作
				if effectCfg.effectType == 0 and effectCfg.effectRes then
					self.owner.view:proxy():saveEffectInfo(effectCfg.effectRes, processCfg.id, processCfg.effectEventID)
					actionArg.spine = effectCfg.effectRes
					isAction = true
				else
					if firstSpine then
						actionArg.spine = self.cfg.spineAction
						firstSpine = false
						isAction = true
					end
					self.owner.view:proxy():saveEffectInfo(self.cfg.spineAction, processCfg.id, processCfg.effectEventID)
				end
			end
			-- 要播放的动作
			if isAction then
				table.insert( self.actionSegArgs, actionArg)
			end
		end

		-- for _,buff in self.owner:iterBuffs() do 暂时不用这个节点 先注掉
		-- 	buff:refreshExtraTargets(battle.BuffExtraTargetType.lastProcessTargets,extraTarget)
		-- end
		-- add buff: 在技能前加  (先所有过程段都加完了后,才处理的伤害)
		-- 因为把角色位移的选择计算省略了, 直接用了这一步的目标, 所以这里会加的buff会立即显示,
		-- 后续处理播放效果, 把效果放到等到大招前置动画后, 技能开始了时再显示buff特效
		self:processAddBuff(processCfg, args.targets, extraTarget, battle.SkillAddBuffType.Before)
	end

	-- 2.0 保存一下所有的目标,后面用
	-- local noMissTargets = self:saveAllTargets()
	skillBB.noMissTargetsArray = self:saveAllTargets()
	self:saveAllDamageTargets()
	skillBB.allDamagedOrder = self:targetsMap2Array(self.allDamageTargets)
	-- for i = 1, self.scene.play.ObjectNumber do
	-- 	local obj = self.allDamageTargets[i]
	-- 	-- 加血的目标可能自己
	-- 	if obj then
	-- 		table.insert(allDamagedOrder,obj)
	-- 	end
	-- end
	if next(skillBB.allDamagedOrder) then
		for _,buff in self.owner:iterBuffs() do
			buff:refreshExtraTargets(battle.BuffExtraTargetType.skillAllDamageTargets, skillBB.allDamagedOrder)
		end
	end
	-- 2.1 技能前的添加的一些buff啥的表现函数收集
	self.disposeDatasOnSkillStart['skillStartAddBuffsPlayFuncs'] = gRootViewProxy:proxy():popDeferList(play01)
end

function SkillModel:updateRecord()
	if self.skillType2 == battle.MainSkillType.NormalSkill or
		self.skillType2 == battle.MainSkillType.SmallSkill then
		self.owner:addExRecord(battle.ExRecordEvent.spellSkillTotal, 1)
	end

	if self:isNormalSkillType() then
		if self.owner:beInExtraAttack() then
			if self.owner.exAttackMode == battle.ExtraAttackMode.syncAttack then
				-- 成功出手了才能累计协战次数
				self.owner:addExRecord(battle.ExRecordEvent.roundSyncAttackTime, 1)
			end
		end
	end

	self.owner:addExRecord(self.skillType2, 1)
end

function SkillModel:processPlay(skillBB)
	local processArgs, noMissTargetsArray, allDamagedOrder = skillBB.processArgs, skillBB.noMissTargetsArray, skillBB.allDamagedOrder

	-- 2.2 加延后显示的BUFF，表现收集处理
	for i, processCfg in self:ipairsProcess() do
		local processTargets = self.allProcessesTargets[processCfg.id]
		local extraTarget
		local lastProcessArg = self:getProcessArg(i-1)
		if i > 1 and lastProcessArg and self.allProcessesTargets[lastProcessArg.id] then
			extraTarget = self.allProcessesTargets[lastProcessArg.id]
		end
		processArgs[i].buffTb = self:processAddBuff(processCfg, processTargets, extraTarget, battle.SkillAddBuffType.InPlay)
	end

	-- 3.0 设置当前的表现收集函数记录表
	local play02 = gRootViewProxy:proxy():pushDeferList(self.id, 'play02')
	-- 反击触发
	if self.scene:beInExtraAttack() and self.owner.exAttackMode == battle.ExtraAttackMode.counter
		and self.skillType2 ~= battle.MainSkillType.PassiveSkill then
		self.owner:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderCounterAttack, self)
	end

	-- 3. 触发攻击前的buff效果(这样能够让buff的效果参与到后面的计算,比如护盾\加攻..)
	if self:isNormalSkillType() then
		self.owner:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderAttackBefore, self)
	end

	-- 3.5 此刻的死亡目标记录 有可能是因为buff触发了导致目标死亡
	for _, obj in ipairs(noMissTargetsArray) do
		if obj:hp() <= 0 then	-- 血量低于 0 的/或者直接用死亡标记来判断也可以
			self:addObjectToKillTab(obj)
		end
	end
	--技能前加buff后未死亡目标的统计
	skillBB.noDeadObjectTb = filterNoDeadObjectsToMap(noMissTargetsArray)

	-- 4.攻击目标
	-- 以小段为遍历顺序,去每个计算,主要是让每个小段中的表现能一致的有序显示
	-- 仍然可以先对这一过程段的所有目标先进行基本的公式伤害演算,将数据保存下来
	-- 然后每一小分段去按实际伤害比例计算,然后把该段要表现的动画记录下来
	if self:isSameType(battle.SkillFormulaType.damage) then
		for _,obj in ipairs(allDamagedOrder) do
			if (self:isNormalSkillType()) then
				obj:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderBeforeBeHit, self)
			end
		end
		-- for i = 1, self.scene.play.ObjectNumber do
		-- 	local obj = self.allDamageTargets[i]
		-- 	-- 加血的目标可能自己
		-- 	if obj and (self:isNormalSkillType()) and not self.scene:beInExtraAttack() then
		-- 		obj:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderBeforeBeHit, self)
		-- 	end
		-- end
	end

	-- 3.1 技能前触发的buff效果 啥的表现函数收集
	self.disposeDatasOnSkillStart['skillStartTriggerBuffsPlayFuncs'] = gRootViewProxy:proxy():popDeferList(play02)
end
-- 技能造成伤害段
function SkillModel:processTarget(skillBB)
	local processArgs = skillBB.processArgs
	local effectCfg

	-- self.scene:excuteGroupObjFunc(1,battle.SpecialObjectId.teamShiled,"pushRecordData",self.owner.id,self.id)
	-- self.scene:excuteGroupObjFunc(2,battle.SpecialObjectId.teamShiled,"pushRecordData",self.owner.id,self.id)
	if self:isNormalSkillType() then
		self.scene:updateBeAttackZOrder()
	end

	for i, processCfg in self:ipairsProcess() do
		local args = processArgs[i]	-- 每一过程段的 基本数据
		-- 攻击中的表现
		local attackInSkill = gRootViewProxy:proxy():pushDeferList(self.id, processCfg.id)
		--self.targetsProcessResult[i] = {}
		local isLastDmgProcess = args.process and args.process.isLastDmgProcess
		log.battle.skill.spellTo('processCfg.id=', processCfg.id)
		effectCfg = self.processEventCsv[processCfg.id]	-- 每个小的分段数据
		self:updateTarget(processCfg, skillBB.target, args)

		if processCfg.isSegProcess then
			-- 决斗
			if self.owner:isBeInSneer() then
				local isDamageType = args.process.segType == battle.SkillSegType.damage
				-- damage用敌对阵营配置，resume用同阵营
				local spreadArg = self.owner:getSneerExtraArgs(not isDamageType)
				if spreadArg == battle.SneerArgType.NoSpread or spreadArg == battle.SneerArgType.BuffSpread then
					local sneerObj = isDamageType and (self.owner:getSneerObj()) or self.owner
					if sneerObj then
						for i = table.length(args.targets), 1, -1 do
							if sneerObj.id ~= args.targets[i].id then
								table.remove(args.targets, i)
							end
						end
					end
				end
			end
			if self:isNormalSkillType() and not self.scene:beInExtraAttack() then
				-- for _, obj in ipairs(args.targets) do
				-- 	-- 加血的目标可能自己
				-- 	if obj then
				-- 		self.owner:refreshExtraTargets(battle.BuffExtraTargetType.segProcessTargets,args.targets)
				-- 		self.owner:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderAfterRefreshTargets, self)
				-- 		print(" battle.BuffTriggerPoint.onHolderAfterRefreshTargets effect ",self.id,obj.id)
				-- 	end
				-- end

				if self:isSameType(battle.SkillFormulaType.damage) then
					for _,buff in self.owner:iterBuffs() do
						buff:refreshExtraTargets(battle.BuffExtraTargetType.segProcessTargets,args.targets)
					end
				end

				self.owner:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderAfterRefreshTargets, {
					skill = self,
					segType = csvSegType[args.process.segType]
				})
			end
			for _, obj in ipairs(args.targets) do
				self:preCalcDamageProb(obj, args)
			end
			for segId, _ in ipairs(effectCfg.segInterval) do
				-- 作用到每个 obj
				local isLastSeg = isLastDmgProcess and (segId == table.length(effectCfg.segInterval))
				for id, obj in ipairs(args.targets) do
					local oriObj
					if args.oriTargets[id] then
						oriObj = args.oriTargets[id]
					end
					self:onProcessLittleSeg(obj, args, segId, isLastSeg, oriObj)
				end
			end
		end

		local otherTargets = table.shallowcopy(self.allTargets) -- 这个过程段目标以外的其他目标
		for _, obj in ipairs(args.targets) do
			otherTargets[obj.id] = nil
		end
		otherTargets[self.owner.id] = nil -- 排除自己
		args.otherTargets = otherTargets

		self.scene:excuteGroupObjFunc(1,battle.SpecialObjectId.teamShiled,"syncView",self,args,processCfg.isSegProcess)
		self.scene:excuteGroupObjFunc(2,battle.SpecialObjectId.teamShiled,"syncView",self,args,processCfg.isSegProcess)

		if processCfg.isSegProcess and self:isNormalSkillType() and self:isSameType(battle.SkillFormulaType.damage) then
			for _, obj in ipairs(args.targets) do
				obj:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderAfterBeHit, self)
			end

			self.owner:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderAfterHit, self)
		end
		args.deferList = args.deferList or {}
		args.deferList[processCfg.id] = args.deferList[processCfg.id] or {}
		args.deferList[processCfg.id] = gRootViewProxy:proxy():popDeferList(attackInSkill)
		-- 存在分段时  分段目标和伤害目标要同步
		-- 发数据给显示中用
		battleEasy.queueNotifyFor(self.owner.view, 'processArgs', processCfg.id, args)
	end

	-- 数据由第一次创建的人释放
	self.scene:excuteGroupObjFunc(1,battle.SpecialObjectId.teamShiled,"popRecordData",self.owner.id,self.id)
	self.scene:excuteGroupObjFunc(2,battle.SpecialObjectId.teamShiled,"popRecordData",self.owner.id,self.id)
end

function SkillModel:processAfter(skillBB)
	local processArgs = skillBB.processArgs
	-- 刷新命中单位
	skillBB.noMissTargetsArray = self:saveAllTargets()
	-- 5.0 设置当前的表现收集函数记录表
	local play03 = gRootViewProxy:proxy():pushDeferList(self.id, 'play03')

	for _, obj in ipairs(skillBB.noMissTargetsArray) do
		if obj and obj:hp() <= 0 then
			obj:setDead(self.owner)
			self:addObjectToKillTab(obj)
		end
	end
	--self.scene:setDeathRecordPoint(battle.DeathRecordPoint.onBattleTurnEnd)
	local mainNumShowType = self:isMainNumShowType() == battle.SkillFormulaType.damage and battle.SkillSegType.damage or battle.SkillSegType.resumeHp
	-- 5. add buff: 技能后加buff
	-- (这里用的目标是最开始保存的,如果某些buff需要用获得了最新的状态目标,则到时候再增加一个字段用来区分过程段需不需要重新计算目标)
	for i, processCfg in self:ipairsProcess() do
		local processTargets = self.allProcessesTargets[processCfg.id]
		local extraTarget
		local lastProcessArg = self:getProcessArg(i-1)
		if i > 1 and lastProcessArg and self.allProcessesTargets[lastProcessArg.id] then
			extraTarget = self.allProcessesTargets[lastProcessArg.id]
		end
		self:processAddBuff(processCfg, processTargets, extraTarget,battle.SkillAddBuffType.After)
		-- 复合类型需要显示总伤害或总治疗
		local args = processArgs[i]
		if processCfg.isSegProcess then
			args.showType = mainNumShowType
		end

		local recordTargets = ""
		for _,v in ipairs(processTargets) do
			recordTargets = recordTargets..tonumber(v.seat).." "
		end
		logf.battle.skill.processTargets("skill %d process %d targets:%s",self.id,processCfg.id,recordTargets)

		-- 技能后删除表现预留数据
		battleEasy.deferNotifyCantJump(self.owner.view,"processDel",processCfg.id)
	end

	-- -- 临时记录
	-- local notDeadHash = {}
	-- for _, obj in ipairs(noMissTargetsArray) do
	-- 	if obj:hp() > 0 then
	-- 		notDeadHash[obj.id] = true
	-- 	end
	-- end

	-- 5.1 技能后添加的一些buff啥的表现函数收集
	self:pushDefreListToSkillEnd('skillEndAddBuffsPlayFuncs',gRootViewProxy:proxy():popDeferList(play03))

	--技能后添加buff后的未死亡目标统计
	skillBB.noDeadObjectTb = filterNoDeadObjectsToMap(skillBB.noMissTargetsArray)
end

function SkillModel:processAfterObjTrigger(skillBB)
	local skillCfg = self.cfg
	local target, allDamagedOrder, noMissTargetsArray, noDeadObjectTb = skillBB.target, skillBB.allDamagedOrder, skillBB.noMissTargetsArray, skillBB.noDeadObjectTb

	-- 5.2.0 设置当前的表现收集函数记录表
	local play04 = gRootViewProxy:proxy():pushDeferList(self.id, 'play04')
	if self:isNormalSkillType() then
		-- 5.2 目标受到最后的伤害时触发的buff效果
		if self:isSameType(battle.SkillFormulaType.damage) then
			for _,obj in ipairs(allDamagedOrder) do
				if not self.protecterObjs[obj.id] then
					obj:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderFinallyBeHit, self)
				end
			end
			-- 保护者也要触发节点
			for _,obj in pairs(self.protecterObjs) do
				obj:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderFinallyBeHit, self)
				obj:updAttackerCurSkillTab(self, true)
			end
			-- for i = 1, self.scene.play.ObjectNumber do
			-- 	local obj = self.allDamageTargets[i]
			-- 	if obj then

			-- 	end
			-- end
		end
		-- 6. owner自身在技能后触发的buff效果
		self.owner:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderAttackEnd, self)
	end
	-- 当击杀选中的目标时
	if target and target:isRealDeath() then
		self.owner:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderKillHandleChooseTarget, self)
	end

	-- 当本次攻击中有目标死亡时, 触发宽泛的击杀判断
	if next(self.killedTargetsTb) then
		self.owner:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderKillTarget, self)
		self.scene.play.battleTurnInfoTb["hasDeadObj"] = true
	end

	-- 6.1 技能后触发的buff效果 啥的表现函数收集
	self:pushDefreListToSkillEnd('skillEndTriggerBuffsPlayFuncs',gRootViewProxy:proxy():popDeferList(play04))


	-- 6.2 此刻的死亡目标记录 有可能是因为buff触发了导致目标死亡

	for _, obj in ipairs(noMissTargetsArray) do
		if noDeadObjectTb[obj.id] and obj:hp() <= 0 then	-- 如果之前没死, 加buff后血量低于0了/或者直接用死亡标记来判断也可以
			self:addObjectToKillTab(obj)
		end
	end
	-- 目标的阵营伙伴被技能击杀时, 目标触发buff效果
	for _, obj in ipairs(noMissTargetsArray) do
		if noDeadObjectTb[obj.id] and obj:hp() <= 0 then	-- 如果技能攻击前没死, 技能后加buff 血量低于0了
			if obj.force == target.force then
				target:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderMateKilledBySkill, self)
			end
		end
	end

	-- 6.3 一些特殊用途的数据记录,在主动技能结束时
	-- 目前这里是 日常活动本 打boss进度掉落相关的
	if (self:isNormalSkillType()) and self.scene.play.gateDoOnSkillEnd then
		self:pushDefreListToSkillEnd('skillEndDrops',self.scene.play:gateDoOnSkillEnd())
	end

	-- 主动给别人恢复血量时，触发被动技能
	local clickTarget = target and {target} or self.allProcessesTargets[self:getProcessArg(1).id]
	for _, obj in maptools.order_pairs(self.allTargets,'id') do
		-- 加血的目标可能自己, 定义不明
		if (clickTarget[1] and clickTarget[1].id == obj.id) or obj.id ~= self.owner.id then
			self.owner:onPassive(PassiveSkillTypes.recoverHp, obj, {skillType = self.skillType, hpFormula = skillCfg.hpFormula})
		end

		-- if obj.id ~= self.owner.id then
		-- 	self.owner:onPassive(PassiveSkillTypes.recoverHp, obj, {skillType = self.skillType, hpFormula = skillCfg.hpFormula})
		-- end

		obj:updAttackerCurSkillTab(self,true)
	end

	-- 技能结束后立刻删除的buff
	for _, buff in self.scene.allBuffs:order_pairs() do
		-- (1)技能攻击 -> 触发(2)被动,攻击(1) -> 触发(1)被动攻击(2)
		if (buff.args.fromSkillId == self.id and buff.caster.id == self.owner.id) then
			local nodes = buff.nodeManager.nodes
			local times = buff.nodeManager.times
			for nodeId, node in buff.nodeManager:ipairsNodes() do
				if node.delSelfWhenTriggered == 2 and not(times[nodeId] and times[nodeId] > 0) then
					buff:over()
				end
			end
		end
	end
end

function SkillModel:processAfterDelObj()
	-- 6.5.0 设置当前的表现收集函数记录表
	local play05 = gRootViewProxy:proxy():pushDeferList(self.id, 'play05')

	-- 6.5 技能后删除死亡目标, 先触发上面的buff后,可能某些buff会对目标产生伤害,造成有极限死亡的情况
	-- 分假死目标 和 真死的目标两类
	-- self.disposeDatasOnSkillEnd['skillEndDeleteDeadObjs'] = {}
	for _, obj in ipairs(self.killedTargetsTb) do
		if obj then
			if obj:isRealDeath() then	-- 真死
				self.scene:addObjToBeDeleted(obj)
			-- else			-- 假死
			-- 	battleEasy.deferNotify(obj.view, "fakeDeathPlayAni",{buffID = obj.rebornBuffId})	--变蛋动画
			end
		end
	end
	self:pushDefreListToSkillEnd('skillEndDeleteDeadObjs',gRootViewProxy:proxy():popDeferList(play05))
end
-- 攻击类型的技能
function SkillModel:isAttackSkill()
	return true
end

function SkillModel:processAfterRefresh(skillBB)
	-- self.scene.deadObjsToBeDeleted = {}		--清空记录
	--在大招释放完之后回复mp1之前 重置怒气点

	local skillCfg = skillBB.skillCfg

	local mp1PointData = self.owner:getOverlaySpecBuffByIdx("mp1OverFlow")
	if mp1PointData and mp1PointData.mode == 1 and self.skillType2 == battle.MainSkillType.BigSkill then
		local mpOverflow = self.owner:mpOverflow()
		-- 换算point
		local costMp1Point = cc.clampf(math.floor(mpOverflow/mp1PointData.rate), 0, mp1PointData.cost or math.floor(mp1PointData.limit/mp1PointData.rate))
		local costMp = costMp1Point * mp1PointData.rate

		self.owner.mp1Table[3] = cc.clampf(mpOverflow - costMp, 0, mp1PointData.limit)
	end
	-- 7. 释放回复mp1 --这个mp可以放到技能完成时再显示回复

	local play06 = gRootViewProxy:proxy():pushDeferList(self.id, 'play06')
	local totalSkillUseTimes = self.owner:getEventByKey(battle.ExRecordEvent.spellSkillTotal) or 0
	-- 只有出手才能回activeSkillMp1怒气
	if self:isAttackSkill() and totalSkillUseTimes <= self.scene.play.recoverMp2RoundLimit and not self.scene:beInExtraAttack() then
		local cfg = self.scene:getSceneAttrCorrect(self.owner:serverForce())
		if cfg and cfg.activeSkillMp1 then
			self.owner:setMP1(self.owner:mp1() + cfg.activeSkillMp1)
		end
	end

	if not self.owner.cantRecoverSkillMp and not self.scene:beInExtraAttack() then
		if skillCfg.recoverMp1 and skillCfg.recoverMp1 > 0 then
			logf.battle.skill.skillEndRecoerMp1(' 释放回复mp: cur mp1= %f, skillId= %d, cfg.recoverMp1= %f',
					self.owner:mp1(), self.id, skillCfg.recoverMp1)
			local mp1Correct = skillCfg.recoverMp1 * (1.0 + self.owner:mp1Recover()) --mp1修正值
			self.owner:setMP1(self.owner:mp1() + mp1Correct)

		end
	end

	self:pushDefreListAfterComeBack('afterComeBackRecoverMp',gRootViewProxy:proxy():popDeferList(play06))
end

function SkillModel:processAfterRefreshExtra(skillBB)
	local target = skillBB.target
	-- 7.5 额外回合的目标,均为主动技能触发

	local function delExtraAttack(obj)
		if not obj then return end
		if not obj:isAlreadyDead() then
			if self:isSameType(battle.SkillFormulaType.damage) then
				-- 反击
				if obj:onCounterAttack(self, target, self.owner) then
					self.scene:addObjToExtraRound(obj)
				end
				-- 协战/邀战
				obj:onSyncAttack(self, target, self.owner)
			end
		end
	end

	if not self.scene:beInExtraAttack() and self:isNormalSkillType() then
		for _, obj in self.scene:ipairsHeros() do
			local exObj = self.scene:getObjectBySeatExcludeDead(obj.seat, battle.ObjectType.SummonFollow)
			delExtraAttack(obj)
			delExtraAttack(exObj)
		end
		-- 连击, 对象只能是技能拥有者, 小回合只能存在一个单位触发连击
		if not self.owner:isAlreadyDead() and self.owner:onComboAttack(self,target,self.owner) then
			self.scene:addObjToExtraRound(self.owner,1)
		end
	end

	if self.scene:beInExtraAttack() and self:isNormalSkillType() and self.owner.exAttackMode == battle.ExtraAttackMode.counter then
		self.counterAttackForView = true
	end
end

function SkillModel:spellTo(target,args)
	self:_spellTo(target,args)
end

-- @param: 玩家选中的target
function SkillModel:_spellTo(target)
	log.battle.skill.spellTo('curSkillId=', self.id, 'owner.id=', self.owner.seat, 'target.id=', target and target.seat,'skillType2=',self.skillType2)
	-- 0. 数据清理, 记录施法回合
	self:cleanData()
	self:startSpell()
	--self.scene:setDeathRecordPoint(battle.DeathRecordPoint.onBattleTurnStart)
	self.canjumpBigSkill = self:isJumpBigSkill()
	self:updateRecord()

	local skillBB = {skillCfg = self.cfg, target = target}
	self:processBefore(skillBB)

	self:processPlay(skillBB)

	self:processTarget(skillBB)

	self:processAfter(skillBB)

	self:processAfterObjTrigger(skillBB)

	self:processAfterDelObj()
	-- 技能恢复， 击杀奖励
	self:processAfterRefresh(skillBB)
	-- 额外回合相关逻辑
	self:processAfterRefreshExtra(skillBB)

	-- 8 连击触发
	-- 死亡12和击杀11判定要放在每一次结束都要判定 5，7，6，8，10，14，17节点就判定一次

	self:spellToOver(skillBB)

	-- 9. 播放动作，包括一个完整的技能动画表现: 大招前置动画 集中显示目标 位移 技能动作 buff效果 被动技能效果 技能结束处理 返回
	-- TODO: 可能有没可攻击目标，先不考虑没有目标的可能
	self:onSpellView(skillBB)
end

function SkillModel:spellToOver(skillBB)
	local target, processArgs = skillBB.target, skillBB.processArgs
	-- 清除连击状态
	-- 伤害计算完毕 ↑↑ 下面开始显示
	-- 播放位置 (放到一个函数里面) -- handleTarget 存在时,表示是玩家手动选择的目标
	-- 直接用第一过程段的目标作为移动依据
	local targets,lastPosIdx = {}
	for k,actionArg in ipairs(self.actionSegArgs) do
		targets = self.allProcessesTargets[actionArg.processId]
		local curArg = processArgs[k]
		local viewTargets = {}
		for id, obj in ipairs(targets) do
			if curArg.oriTargets[id] then
				table.insert(viewTargets, curArg.oriTargets[id])
			else
				table.insert(viewTargets, obj)
			end
		end
		actionArg.posIdx = self.owner.view:proxy():getMoveToTargetPos(self.cfg, viewTargets)
		actionArg.target = viewTargets[1] or self.owner:getCurTarget()
		lastPosIdx = actionArg.posIdx
	end

	-- 被动 not lastPosIdx
	if not lastPosIdx then
		targets = {}
		local targetsAdd = {} -- 去重
		table.insert(targets, target)
		targetsAdd[target.id] = true
		for __,tgs in maptools.order_pairs(self.allProcessesTargets) do
			for _,obj in ipairs(tgs) do
				if obj.id ~= self.owner.id and not targetsAdd[obj.id] then
					table.insert(targets, obj)
					targetsAdd[obj.id] = true
					obj:updAttackerCurSkillTab(self,true)
				end
			end
		end
		lastPosIdx = self.owner.view:proxy():getMoveToTargetPos(self.cfg, targets)
	end

	-- 技能结束,逻辑意义上的
	self.isSpellTo = false
	self.interruptBuffId = nil
	-- 部分表现不需要被播放
	self:sortViewProcess()

	battleEasy.logHerosInfo(self.scene)

	skillBB.lastPosIdx = lastPosIdx
end


function SkillModel:sortViewProcess()
	local _random = ymrand.random
	self.protectedEnv:resetEnv()
	local env = battleCsv.fillFuncEnv(self.protectedEnv, {
		target = self.owner:getCurTarget(),
	})
	for i, processCfg in self:ipairsProcess() do
		if processCfg.extraArgs and processCfg.extraArgs.effectProb then
			local prob = battleCsv.doFormula(processCfg.extraArgs.effectProb,env)
			if prob < _random() then
				self.owner.view:proxy():saveIgnoreEffect(processCfg.id,processCfg.effectEventID)
			end
		end
	end
end

-- 释放时显示相关
function SkillModel:onSpellView(skillBB)
	local target, posIdx = skillBB.target, skillBB.lastPosIdx
	local scene = self.scene
	local view = self.owner.view
	local skillCfg = self.cfg
	local targets = self:targetsMap2Array(self.allTargets)	-- { [id]=obj }
	local lastTarget

	log.battle.skill.onSpellView('skill onSpellView target.id=', target and target.seat, 'move pos=', posIdx)

	self.owner.flashBack = skillCfg.flashBack
	-- local isPauseMusic = false

	view:proxy():setSkillJumpSwitch(self.canjumpBigSkill)
	-- if self.skillType2 == battle.MainSkillType.BigSkill and not self.canJump then
	-- 	battleEasy.queueNotify("setUltAccEnable",true)
	-- end
	-- if isPauseMusic then
	-- 	battleEasy.queueEffect('music', {music={op = 'pause'}})
	-- end
	for i, processCfg in self:ipairsProcess() do
		if processCfg.effectEventID then
			local effectCfg = self.processEventCsv[processCfg.id]
			if effectCfg and effectCfg.control then
				battleEasy.queueEffect('control', effectCfg.control)
			end
		end
	end

	-- 0.大招前置动画  如果是大招时
	if self.skillType2 == battle.MainSkillType.BigSkill then  -- skillType2 大招是 2
		local hideHero = {}
		--隐藏不在本次攻击中的目标
		for i = 1, self.scene.play.ObjectNumber do
			local obj = self.scene:getObjectBySeat(i)
			local exObj = self.scene:getObjectBySeat(i, battle.ObjectType.SummonFollow)
			if obj and (not self.allTargets[obj.id]) and (obj.id ~= self.owner.id) then
				hideHero[i] = tostring(obj)
			end
			if exObj and (not self.allTargets[exObj.id]) and (exObj.id ~= self.owner.id) then
				hideHero[i + self.scene.play.ObjectNumber] = tostring(exObj)
			end
		end
		if not skillCfg.notShowProcedure.beforeMainSkill then
		--对应音效
		battleEasy.queueEffect('sound', {delay = 0,sound = {res = "skill2_effect.mp3", loop = 0}})
		battleEasy.queueEffect(function()
			gRootViewProxy:notify('ultSkillPreAni1')
			--if not self.canJump then
			gRootViewProxy:notify('ultSkillPreAni2', tostring(self.owner), skillCfg , hideHero)
			--end
			gRootViewProxy:notify('objMainSkill')
		end)

		battleEasy.queueEffect('delay', {lifetime=2000})
	end
	end

	-- 有些技能自带背景会遮挡其它目标,所以统一设置下posZ
	-- 1.分两步设置,先设置攻击者自身,等移动过去后再统一设置
	-- 如果是被动技能，并且没有目标位置的移动，可以直接忽略相关的位移和动画表现的设置！
	battleEasy.queueEffect(function()
		local tpz = target.view:proxy():getMovePosZ()
		local spz = self.owner.view:proxy():getMovePosZ()
		local pz = math.min(tpz, spz)	--取自身和目标z轴的最小值,避免斜向移动时遮住其它目标
		view:proxy():setLocalZOrder(pz+1)	--自己在最上方
	end)

	-- 3. 攻击时显示的层级
	battleEasy.queueEffect(function()
		local tpz = target.view:proxy():getMovePosZ()
		for id, obj in ipairs(targets) do
			tpz = math.max(tpz, obj.view:proxy():getMovePosZ())
		end
		battleEasy.queueEffect(function()
			view:proxy():setLocalZOrder(tpz+1)	--自己在最上方
		end)
	end)

	-- 4. 技能前的buff们
	if self.counterAttackForView then
		battleEasy.queueNotifyFor(view, "showCounterAttackText",tostring(self.owner)) --反击飘字跟buff飘字类似
		self.counterAttackForView = false
	end

	battleEasy.queueNotifyFor(view, 'skillBefore', self.disposeDatasOnSkillStart, self.skillType, false, self:getSkillSceneTag())

	-- 4.1 技能前 按照配表隐藏需要隐藏的buff
	battleEasy.queueNotifyFor(view, 'attacting', true)

	-- 5.0 播放音效
	if skillCfg.sound and not self.canjumpBigSkill then
		battleEasy.queueEffect('sound', {delay = skillCfg.sound.delay,sound = {res = skillCfg.sound.res, loop = skillCfg.sound.loop}})
	end

	-- 5.动作
	--if not self.canJump then
	local protectorIDList = {}
	for k,v in ipairs(self.actionSegArgs) do
		if v.target and not lastTarget or (lastTarget and lastTarget.id ~= v.target.id) then
			-- 2.移动到目标位置
			-- local lethalProtectObj = v.target:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.lethalProtect, "getProtectObj")
			-- if lethalProtectObj and self:isSameType(battle.SkillFormulaType.damage) then
			-- 	if not itertools.include(protectorIDList,lethalProtectObj.view) then
			-- 		table.insert(protectorIDList,lethalProtectObj.view)
			-- 	end
			-- 	protectorTb = {
			-- 		view = lethalProtectObj.view,
			-- 		targetID = v.target.seat,
			-- 	}
			-- elseif v.target:getProtectInfo() and self:isSameType(battle.SkillFormulaType.damage) then
			-- 	local protector,_ = v.target:getProtectInfo()
			-- 	if not itertools.include(protectorIDList,protector.view) then
			-- 		table.insert(protectorIDList,protector.view)
			-- 	end
			-- 	protectorTb = {
			-- 		view = protector.view,
			-- 		targetID = v.target.seat,
			-- 	}
			-- end
			battleEasy.queueNotifyFor(view, 'moveToTarget', v.posIdx, {
				delayBeforeMove = skillCfg.moveTime[1],
				moveCostTime = skillCfg.moveTime[2],
				timeScale = self.scene:beInExtraAttack() and 0.51,
				cameraNear = skillCfg.cameraNear,
				cameraNear_posC = skillCfg.cameraNear_posC,
				posC = skillCfg.posC,
				attackFriend = self.owner:needAlterForce(),
			}, false, tostring(v.target), self:filterProtectorView(v.target, protectorIDList))
		end
		lastTarget = v.target

		battleEasy.queueNotifyFor(view, 'playAction', v.spine, v.lifeTime or false, false)
	end

	if self.canjumpBigSkill then
		local totalDmg,totalResumeHp = self:getTargetsFinalValue()
		local dmg, typ = totalDmg, battle.SkillSegType.damage
		if totalDmg == 0 and self:isSameType(battle.SkillFormulaType.resumeHp) then
			dmg, typ = totalResumeHp, battle.SkillSegType.resumeHp
		end
		local params = {delta = dmg, skillId = skillCfg.id, typ = typ}

		battleEasy.queueNotifyFor(view, 'ultJumpShowNum', params)
	end

	-- 根据技能目标战场上存活的数量，自适应增加相应数量的固定特效
	-- TODO: effect_event改版，后面再改
	-- if skillCfg.specEventID and next(skillCfg.specEventID) then
	-- 	for i = 1, self.scene.play.ObjectNumber do
	-- 		local obj = targets[i]
	-- 		if obj and obj.view then
	-- 			local view2 = obj.view
	-- 			for k,v in ipairs(skillCfg.specEventID) do
	-- 				local effectCfg = csv.effect_event[v]
	-- 				battleEasy.queueNotifyFor(view2, 'addEffectsByCsv',nil,v,effectCfg)
	-- 			end
	-- 		end
	-- 	end
	-- end

	-- 6.结束 策划希望在有多个技能连续施放时(主要是被动技能),可以在不完全回去后再施放被动技能,所以把移动回去放到回合结束时了
	battleEasy.queueNotifyFor(view, 'objSkillEnd', self.disposeDatasOnSkillEnd, self.skillType)

	-- 7.返回 配置了flashBack时才提前返回, 正常情况下因为被动技能也能移动的设定, 是需要等到battleTurn结束时才返回的
	-- 如果当前回合不是自己的攻击回合/是自己的回合,但是自己还没有开始行动(手动情况下)时,这类被动技能需要能自己返回位置
	battleEasy.queueNotifyFor(view, 'comeBack', posIdx, false, {
		delayBeforeBack = skillCfg.moveTime[3],
		backCostTime = skillCfg.moveTime[4],
		timeScale = self.scene:beInExtraAttack() and 0.51,
		flashBack = skillCfg.flashBack,
		attackFriend = self.owner:needAlterForce(),
	},false,protectorIDList)

	--8.返回后 有回复mp之类的需要等待返回之后进行
	battleEasy.queueNotifyFor(view,'afterComeBack',self.disposeDatasAfterComeBack)
	-- 如果有保护那要一起回去
	-- for k,v in ipairs(protectorIDList) do
	-- 	local protectObj = self.scene:getObjectBySeatExcludeDead(v)
	-- 	battleEasy.queueNotifyFor(protectObj.view, 'comeBack', posIdx, false, skillCfg.flashBack and true or false)
	-- end
	-- 技能后 恢复所有buff的显示
	battleEasy.queueNotifyFor(view, 'attacting', false)

	-- 技能后 恢复standby_loop
	battleEasy.queueNotifyFor(view, 'resetPos')

	battleEasy.queueNotifyFor(view, 'objSkillOver')

	-- if isPauseMusic then
	-- 	battleEasy.queueEffect('music', {music={op = 'resume'}})
	-- end
	-- 8. 延迟处理 为死亡目标预留的时间 -- 这里去掉, 不然角色攻击完时会等待一会
	-- -- 是否真的需要延迟,后面再考虑计算,目前先强制加上再说
	-- 修改： 当有角色死亡时，先计算死亡动画的时间, 然后以delay的形式放到本次动画队列的最后, 放在目标返回原位的后面吧。
end

function SkillModel:getTargetsFinalValue()
	local totalDmg,totalResumeHp = 0,0
	for _,v in pairs(self.targetsFinalResult) do
		totalDmg = totalDmg + v.damage.real:get(battle.ValueType.normal)
		totalResumeHp = totalResumeHp + v.resumeHp.real:get(battle.ValueType.normal)
	end
	return totalDmg, totalResumeHp
end

-- @return: 返回target数组
-- friendOrEnemy:目标阵营(0友方1敌方),不是实际阵营, chooseType: 具体选择类型, specialChoose:特殊选择
-- selectedObj: 当前选择目标, cfg: {input=xxx, process=xxx} 配表中手填的技能选择参数
-- 修改：合并下几个特殊选择的辅助参数,  叫 exArgs 吧
-- exArgs = {specialChoose=xxx, targetLimit=xxx}
function SkillModel:getTargets(friendOrEnemy, chooseType, selectedObj, exArgs, inputCfg)
	local params = {
		friendOrEnemy = friendOrEnemy,
		specialChoose = exArgs.specialChoose,
		targetLimit = exArgs.targetLimit,
		allProcessesTargets = exArgs.excludeTarget,
		inputExtraStr = exArgs.inputExtraStr,
		skillType = self.skillType,
		skillSegType = exArgs.segType,
		skillFixType = exArgs.fixType,
		-- ignoreStealth = exArgs.ignoreStealth,
		-- ignoreStealthHint = exArgs.ignoreStealthHint
	}

	local targets = newTargetFinder(self.owner, selectedObj, chooseType, params, inputCfg)


	---打印选出来的每个单位id
	-- print_r_deep(targets, 2)

	return targets
end

--获取溅射目标
function SkillModel:getSpurtTargets(target,allTargets,isColSpurt,oriTargets)

	local function isIdxInAllTargets( idx )
		for _,v in ipairs(allTargets) do
			if idx == v.seat then
				return true
			end
		end
		for _,v in ipairs(oriTargets) do
			if v and v.seat == idx then
				return true
			end
		end
		return false
	end

	local retT = {}
	local search = {{2,4},{1,3,5},{2,6},{1,5},{2,4,6},{3,5}}
	local tarSeat = target.seat > 6 and target.seat-6 or target.seat
	for _, idx in ipairs(search[tarSeat]) do
		if target.force == 2 then idx = idx + 6 end
		local obj = self.scene:getObjectBySeatExcludeDead(idx)
		local temp = false

		if obj and obj:isLogicStateExit(battle.ObjectLogicState.cantBeAttack,{fromObj = self.owner}) then
			temp = true
		end

		if obj and (obj:isAlreadyDead() == false) and not temp then
			table.insert(retT, obj)
		end
	end

	retT = self:replaceLethalTargets(retT)
	local newRetT = {}
	for _, obj in ipairs(retT) do
		if not isIdxInAllTargets(obj.seat) then
			table.insert(newRetT, obj)
		end
	end
	retT = newRetT

	table.sort(retT, function(aObj, bObj)
		return aObj.id < bObj.id
	end)
	return retT
end
--获取穿透目标, 攻击可以穿透前排目标打到后排, 即目标身后的目标, 因为最多只能有一个目标, 所以没有时返回空nil
function SkillModel:getPenetrateTarget(target)
	local backObj
	local rowNum = (math.floor((target.seat+2)/3)-1)%2+1
	if rowNum == 1 then --第一排的目标才有后排
		local obj = self.scene:getObjectBySeatExcludeDead(target.seat+3) -- 后排目标和前排目标id差3
		if obj and (obj:isAlreadyDead() == false)
			and not obj:isLogicStateExit(battle.ObjectLogicState.cantBeAttack,{fromObj = self.owner}) then
			backObj = obj
		end
	end
	local retT = self:replaceLethalTargets({backObj})
	return retT[1]
end

-- ----只取第一个process作为目标提示 for view
-- 存在公式时 替换公式本身目标
function SkillModel:getTargetsHint(hitFormula)
	local skillCfg = self.cfg
	-- 目标是敌方时,若有嘲讽目标时,只能点击嘲讽的那个目标
	-- 如果是有嘲讽目标时,提示类型退化为单体选择,只能点击选择嘲讽的那一个
	local sneerAtOwnerObj = self.owner:getSneerObj()
	local cfg = {
		hintChoose = self:getSkillCfgByKey("hintChoose"),
		hintTargetType = skillCfg.hintTargetType
	}

	hitFormula = hitFormula or skillCfg.hitFormula
	-- 通过公式选择目标
	local targetCfg = {}
	if hitFormula and csvSize(hitFormula) > 0 then
		self.protectedEnv:resetEnv()
		local env = battleCsv.fillFuncEnv(self.protectedEnv, {})
		local result
		for arg,data in csvMapPairs(hitFormula) do
			result = battleCsv.doFormula(data.key, env) and 1 or 2
			targetCfg[arg] = data.value[result] or targetCfg[arg]
		end
	end

	if (cfg.hintTargetType == 1) and sneerAtOwnerObj and not sneerAtOwnerObj:isAlreadyDead() then
		cfg.hintChoose = 1		-- 嘲讽类型 变为1
	end

	local args = {
		specialChoose = skillCfg.specialHintChoose,
		inputExtraStr = string.format("nobeskillselectedhint({skillFormulaType=%s})",self.skillFormulaType)
	}

	if self:isSameType(battle.SkillFormulaType.fix) and cfg.hintChoose > 100 then
		local tmpHintChoose = cfg.hintChoose
		args.fixType = battle.SkillFormulaType.resumeHp
		local healthChoose = math.floor(tmpHintChoose / 100)
		local healthTargets = self:getTargets(cfg.hintTargetType == 1 and 0 or 1, healthChoose, sneerAtOwnerObj, args, targetCfg)
		local damageChoose = cfg.hintChoose - healthChoose * 100
		args.fixType = battle.SkillFormulaType.damage
		local damageTargets = self:getTargets(cfg.hintTargetType, damageChoose, sneerAtOwnerObj, args, targetCfg)
		return arraytools.merge({healthTargets, damageTargets})
	end

	return self:getTargets(cfg.hintTargetType, cfg.hintChoose, sneerAtOwnerObj,args, targetCfg)
end

function SkillModel:autoChoose()
	return self:getTargetsHint(self.cfg.autoHintChoose)
end

function SkillModel:getSkillCfgByKey(key)
	return self.owner:dealOpenValueByKey(key, self.cfg[key])
end

function SkillModel:onProcessGetTargets(processCfg, target)
	-- 针对不同的skill_process会计算不同的targets
	local allTarget = self.allProcessesTargets

	if processCfg.targetFormula and csvSize(processCfg.targetFormula) > 0 then
		self.protectedEnv:resetEnv()
		local env = battleCsv.fillFuncEnv(self.protectedEnv, {
			target = target,
		})
		local result
		for arg,data in csvMapPairs(processCfg.targetFormula) do
			result = battleCsv.doFormula(data.key, env) and 1 or 2
			processCfg[arg] = data.value[result] or processCfg[arg]
		end
	end
	local cfg = processCfg.input and {input=processCfg.input, process=processCfg.process}  -- 字段未加

	local inputExtraStr = "nobeskillselected"
	local targets = self:getTargets(processCfg.targetType, processCfg.skillTarget, target, {
		specialChoose = processCfg.specialChoose,
		targetLimit = processCfg.targetLimit,
		excludeTarget = allTarget,
		inputExtraStr = inputExtraStr,
		segType = csvSegType[processCfg.segType],
		-- ignoreStealth = ignoreStealth
	}, cfg)
	--TODO: 临时处理,后期通过策划配表去实现
	if not (processCfg.extraArgs and processCfg.extraArgs.targetCanBeEmpty) then
		if table.length(targets) == 0 and processCfg.isSegProcess then targets = {self.owner:getCurTarget()} end
	end
	-- if not self.owner:canBeSelected() and self.owner.id == target.id then targets = {target} end

	local sneerAtMeObj = self.owner:getSneerObj()
	-- 嘲讽的目标必须要被带上
	-- 当前目标必须涵盖敌方单位目标
	local tmpSneerObjId --回合强制目标用
	if sneerAtMeObj and not sneerAtMeObj:isNotReSelect()
	and not sneerAtMeObj:isLogicStateExit(battle.ObjectLogicState.cantBeSelect,{fromObj = self.owner}) then
		tmpSneerObjId = sneerAtMeObj.id
		local isHasEnemyForceObj = false
		for _, target in ipairs(targets) do
			if target.force ~= self.owner.force then
				isHasEnemyForceObj = true
			end
			if target.id == sneerAtMeObj.id then
				sneerAtMeObj = nil
				break
			end
		end

		if isHasEnemyForceObj then
			targets[1] = sneerAtMeObj or targets[1]
		end
	end

	-- 回合强制包含目标
	local exTurnMustHitIds = self.owner.scene.play:getExtraBattleRoundData("mustHit")
	local processCfgId = self.owner.scene.play:getExtraBattleRoundData("processCfgId")

	if processCfg.id == processCfgId and exTurnMustHitIds and table.length(exTurnMustHitIds) > 0 then
		local objHash = arraytools.hash(exTurnMustHitIds)
		local canReplacePos = {}
		for idx, obj in ipairs(targets) do
			if objHash[obj.id] then
				objHash[obj.id] = nil
			elseif obj.id ~= tmpSneerObjId then
				table.insert(canReplacePos, idx)
			end
		end

		local head = 1
		for _, objId in ipairs(exTurnMustHitIds) do
			if not canReplacePos[head] then
				break
			end
			local curObj = self.owner.scene:getObject(objId)
			if objHash[objId] and curObj and not curObj:isLogicStateExit(battle.ObjectLogicState.cantBeSelect,{fromObj = self.owner}) then
				targets[canReplacePos[head]] = curObj
				head = head + 1
			end
		end
	end

	return targets
end

function SkillModel:onProcess(processCfg, target)
	log.battle.skill.process('onProcess', self.owner.id, lazydumps(processCfg))

	local targets = self:onProcessGetTargets(processCfg, target)
	local newTargets, oriTargets = self:replaceLethalTargets(targets, true)

	for _, target in ipairs(newTargets) do
		if self:isSameType(battle.SkillFormulaType.damage) then	-- 伤害类型的技能,需要先判断目标的命中
			local final = self:getTargetsFinalResult(target.id)
			if not final.value and not self.owner:isHit(target, self.cfg) then
				final.value = 0
				-- skillMiss 技能未命中
				final.args.skillMiss = true
			end
		end
		target:updAttackerCurSkillTab(self,false)
	end

	return {process=processCfg, targets=newTargets, oriTargets=oriTargets}
end

-- 先判断是否找到目标
-- 目标是随逻辑更新
function SkillModel:updateTarget(processCfg, target, args)
	if processCfg.extraArgs and processCfg.extraArgs.needUpdateTarget then
		local newArgs = self:onProcess(processCfg, target)
		-- 公式无法找到更新目标时用旧目标代替
		args.targets = newArgs.targets
		args.oriTargets = newArgs.oriTargets
		self.allProcessesTargets[args.process.id] = args.targets
	end
end

function SkillModel:onProcessLittleSeg(target, args, segId, isLastSeg, oriObj)
	--提前计算公式数据伤害/加血, 保存起来
	self:calcFormulaFinal(target, args)
	-- 计算该分段对目标的影响
	self:onTarget(target, args, segId, isLastSeg, oriObj)
end

local preCalProbNames = {
	"miss",
	"block",
	"strike",
	"natureFlag",
	"nature",
	"hasCalcDamageProb",
}

--
-- 专门用来演算100%公式比例伤害的, 保存数据, 具体的分段可以使用这个函数中保存的值
function SkillModel:calcFormulaFinal(target, args)
	local skillCfg = self.cfg

	-- 最终数据存储(指的是单次100%的数据,不是每个小分段的,分段另外再计算)
	-- 下面这个和上面的那个,也可以合并为一个记录,一般不会在此刻出现多种状态变化的情况,从而导致最终记录的值不一样的
	local final = self:getTargetsFinalResult(target.id, args.process.segType)
	-- 加血
	if args.process.segType == battle.SkillSegType.resumeHp then
		if not final.value then
			-- 最后治疗效果 = 技能治疗数值 * 治疗效果
			local formHp = self:calcFormula("hp", skillCfg.hpFormula, target)
			log.battle.skill.formula(" 技能表公式配置:hpFormula owner.id=%s, cfg.hpFormula=%s, hpFormula=%s, target.id=%s", self.owner.seat, skillCfg.hpFormula, formHp, target and target.id)
			local skillNatureType = self:getSkillNatureType() or 1
			local objNatureName = game.NATURE_TABLE[skillNatureType]
			formHp = formHp * (1 + self.owner:cure() + self.owner[objNatureName..'Cure'](self.owner) + self.owner:healAdd())

			final.value = formHp
			final.args = {
				casterId = self.owner.id,
				-- real = battleEasy.valueTypeTable()
			}
		end
	end

	-- 伤害
	if args.process.segType == battle.SkillSegType.damage then
		-- 保存已经计算出来的伤害,可能会有多个分段对已经计算过的目标再次造成伤害
		if not final.value then
			-- 公式数据
			local formDamage = self:calcFormula("damage", skillCfg.damageFormula, target)
			local randFix= self.scene.closeRandFix and 1 or ymrand.random(9000, ConstSaltNumbers.wan) / ConstSaltNumbers.wan
			formDamage = formDamage * randFix
			logf.battle.skill.damageFormula(' 技能表公式配置:damageFormula  ownerId= %s, formula damge= %s, cfg.damageFormula= %s', self.owner.seat, formDamage, skillCfg.damageFormula)
			-- 伤害增幅数据
			local exArgs = {
				skillId = skillCfg.id,
				natureType = self:getSkillNatureType() or 1,
				damageType = skillCfg.skillDamageType or battle.SkillDamageType.Physical,
				skillType2 = skillCfg.skillType2,
				skillPower = skillCfg.skillPower,
			}
			if final.args then
				for _, name in ipairs(preCalProbNames) do
					exArgs[name] = final.args[name]
				end
			end
			local damage, damageArgs = target:calcInternalDamage(self.owner,formDamage,self.skillCalDamageProcessId, exArgs)
			final.value = damage
			final.args = damageArgs
		end
	end
end

-- 提前计算暴击、格挡、命中
-- preCalProbNames, damage流程也需要修改
function SkillModel:preCalcDamageProb(target, args)
	if args.process.segType ~= battle.SkillSegType.damage then
		return
	end
	local final = self:getTargetsFinalResult(target.id, args.process.segType)
	if final.args and final.args.hasCalcDamageProb then
		return
	end
	local _, damageArgs = battleEasy.runDamageProcess(0, self.owner, target, self.skillCalDamageProcessId, {
		exProcessId = battle.DamageProbProcessId,
		skillId = self.cfg.id,
		natureType = self:getSkillNatureType() or 1,
	})
	final.args = damageArgs
	final.args.hasCalcDamageProb = true
	target:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderCalcDamageProb, self)
end
--溅射目标
function SkillModel:onSputterTarget(target, args, final, damageArgs, skillDamageBB)
	local data = target:getEventByKey(battle.ExRecordEvent.sputtering)
	if data then
		local spurtPer = data.rate
		if damageArgs.segId == 1 then
			--根据目标不同，获取到的溅射目标也不同，分开保存
			if not args.sputObjs then
				args.sputObjs = {}
			end
			args.sputObjs[target.id] = self:getSpurtTargets(target,args.targets,table.length(args.targets) > 1, args.oriTargets)
			-- 溅射和穿刺伤害没有记录final.value,已确定在damage的lockHp,keepHp流程,计算killMeDamageValues时有影响
			-- 在这里记录一个value值, 发现其它问题或新增函数涉及到final.value时需要注意
			for _, obj in ipairs(args.sputObjs[target.id]) do
				local _final = self:getTargetsFinalResult(obj.id, battle.SkillSegType.damage)
				_final.value = _final.value or final.value * spurtPer
			end
		end

		for _, obj in ipairs(args.sputObjs[target.id]) do
			local spurtDamage = skillDamageBB.damage * spurtPer
			damageArgs.beHitNotWakeUp = true

			local _damage,_damageArgs = obj:beAttack(self.owner, spurtDamage, skillDamageBB.damageProcessAfterCal, damageArgs)
			local _final = self:getTargetsFinalResult(obj.id, battle.SkillSegType.damage)
			_final.real:add(_damage)
			_final.args = _damageArgs
			if _damageArgs.beAttackToDeath then
				self:addObjectToKillTab(obj)
			end
			-- 跳过大招获取到的伤害已经计算过溅射和穿透
			if not self.canjumpBigSkill then
				battleEasy.deferNotifyCantJump(nil, 'showNumber', {delta = math.floor(_damage:get(battle.ValueType.normal)), skillId = self.id, typ = battle.SkillSegType.damage})
			end
		end

		if skillDamageBB.isLastSeg then
			for _, obj in ipairs(args.sputObjs[target.id]) do
				if obj and obj:hp() <= 0 then
					obj:setDead(self.owner)
				end
			end
			target:cleanEventByKey(battle.ExRecordEvent.sputtering)
			args.sputObjs[target.id] = nil
		end
	end
end
--穿透目标
function SkillModel:onPenetrateTarget(target, args, final, damageArgs, skillDamageBB)
	local data = target:getEventByKey(battle.ExRecordEvent.penetrate)
	if data then
		local penetratePer = data.rate
		if damageArgs.segId == 1 then
			args.penetrateObj = self:getPenetrateTarget(target)
			if args.penetrateObj then
				local _final = self:getTargetsFinalResult(args.penetrateObj.id, battle.SkillSegType.damage)
				_final.value = _final.value or final.value * penetratePer
			end
		end
		if args.penetrateObj then
			local penetrateDamage = skillDamageBB.damage * penetratePer
			damageArgs.beHitNotWakeUp = true
			local _damage,_damageArgs = args.penetrateObj:beAttack(self.owner, penetrateDamage,skillDamageBB.damageProcessAfterCal, damageArgs)
			local _final = self:getTargetsFinalResult(args.penetrateObj.id, battle.SkillSegType.damage)
			_final.real:add(_damage)
			_final.args = _damageArgs
			--穿透目标死亡
			if _damageArgs.beAttackToDeath then
				self:addObjectToKillTab(args.penetrateObj)
			end
			if not self.canjumpBigSkill then
				battleEasy.deferNotifyCantJump(nil, 'showNumber', {delta = math.floor(_damage:get(battle.ValueType.normal)), skillId = self.id, typ = battle.SkillSegType.damage})
			end
		end
		if skillDamageBB.isLastSeg then
			if args.penetrateObj and args.penetrateObj:hp() <= 0 then
				args.penetrateObj:setDead(self.owner)
			end
			target:cleanEventByKey(battle.ExRecordEvent.penetrate)
			args.penetrateObj = nil
		end
	end
end

function SkillModel:onHealToDamageTarget(target, processCfg, final, effectCfg, segId)
	if target:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.healTodamage) then
		local damageFinal = self:getTargetsFinalResult(target.id, battle.SkillSegType.damage)
		if segId == 1 then
			local toDamageData = target:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.healTodamage, "getDamage", final.value)
			local allDamage = 0
			for _,v in ipairs(toDamageData) do
				allDamage = allDamage + v.damage
			end
			damageFinal.value = allDamage
			battleEasy.IDCounter = battleEasy.IDCounter + 1
			damageFinal.args = {
				skillId = self.cfg.id,
				damageId = battleEasy.IDCounter,
			}
			damageFinal.healToDamageData = toDamageData
		end

		local segPer = effectCfg.hpSeg[segId]
		if not damageFinal.attackedDamage or segId == 1 then
			damageFinal.attackedDamage = 0
		end

		for k, data in ipairs(damageFinal.healToDamageData) do
			local damage = math.floor(data.damage*segPer)
			local damageArgs = table.deepcopy(damageFinal.args)
			local leftDamage = damageFinal.value - damageFinal.attackedDamage
			damageFinal.attackedDamage = damageFinal.attackedDamage + damage
			damageArgs.processId = processCfg.id
			damageArgs.from = battle.DamageFrom.skill
			damageArgs.segId = segId
			damageArgs.skillDamageId = damageFinal.args.damageId
			damageArgs.isLastDamageSeg = (table.length(effectCfg.hpSeg) == segId and table.length(damageFinal.healToDamageData) == k)
			damageArgs.isBeginDamageSeg = (segId == 1 and k == 1)
			damageArgs.leftDamage = leftDamage
			-- segValue = battleEasy.valueTypeTable()
			local newSegValue,newDamageArgs = target:beAttack(self.owner, damage, data.processId, damageArgs)
			damageFinal.real:add(newSegValue)
		end
		return false
	end
	return true
end

function SkillModel:onProtectTarget(protecter, damage, allDamage, oldDamageArgs, processId)

	local damageFinal = self:getTargetsFinalResult(protecter.id, battle.SkillSegType.damage)
	local segId = oldDamageArgs.segId
	if segId == 1 then
		local tempProcessArgs = {
			process = {
				segType = battle.SkillSegType.damage
			}
		}
		damageFinal.args = {}
		self:preCalcDamageProb(protecter, tempProcessArgs) -- 重新计算保护的暴击、格挡、命中

		damageFinal.value = allDamage
		-- 保护者加入特定的伤害目标
		self.protecterObjs[protecter.id] = protecter
		protecter:updAttackerCurSkillTab(self, false)
	end

	if not damageFinal.attackedDamage or segId == 1 then
		damageFinal.attackedDamage = 0
	end

	local damageArgs = table.deepcopy(damageFinal.args)
	damageFinal.attackedDamage = damageFinal.attackedDamage + damage
	damageArgs.processId = oldDamageArgs.processId
	damageArgs.from = battle.DamageFrom.skill
	damageArgs.segId = segId
	damageArgs.skillDamageId = damageFinal.args.damageId
	damageArgs.isLastDamageSeg = oldDamageArgs.isLastDamageSeg
	damageArgs.isBeginDamageSeg = oldDamageArgs.isBeginDamageSeg
	damageArgs.leftDamage = damageFinal.value - damageFinal.attackedDamage
	damageArgs.fromExtra = oldDamageArgs.fromExtra
	local newSegValue,newDamageArgs = protecter:beAttack(self.owner, damage, processId, damageArgs)
	damageFinal.real:add(newSegValue)
end

function SkillModel:onTarget(target, args, segId, isLastSeg, oriObj)
	local processCfg = args.process
	local effectCfg = self.processEventCsv[processCfg.id]
	-- local processFinal = self.targetsProcessResult[target.id] or {}
	-- self.targetsProcessResult[target.id] = processFinal

	local final = self:getTargetsFinalResult(target.id, args.process.segType)

	-- 表现用的 SegShow
	local segValue

	args.values[target.id] = args.values[target.id] or {}

	-- 设置当前的表现收集函数
	local deferKey = gRootViewProxy:proxy():pushDeferList(self.id, processCfg.id)

	-- 伤害
	if args.process.segType == battle.SkillSegType.damage then
		local damageProcessAfterCal = self.skillCalDamageProcessId == 1 and 9999 or self.skillCalDamageProcessId + 1

		local segPer = effectCfg.damageSeg[segId]	-- 伤害分段 比例
		local damage = math.floor(final.value*segPer)
		local damageArgs = table.deepcopy(final.args, true)
		if not final.attackedDamage or segId == 1 then
			final.attackedDamage = 0
		end
		local leftDamage = final.value - final.attackedDamage
		final.attackedDamage = final.attackedDamage + damage

		damageArgs.processId = processCfg.id
		damageArgs.from = battle.DamageFrom.skill
		damageArgs.segId = segId
		damageArgs.skillDamageId = final.args.damageId
		damageArgs.isLastDamageSeg = (table.length(effectCfg.damageSeg) == segId)
		damageArgs.isBeginDamageSeg = (segId == 1)
		damageArgs.leftDamage = leftDamage

		damage = self.protecterObjs[target.id] and 0 or damage -- 触发保护后保护者不受本来伤害
		local newDamageArgs
		segValue,newDamageArgs = target:beAttack(self.owner, damage, damageProcessAfterCal, damageArgs)
		final.real:add(segValue)

		--溅射穿刺使用致死保护替换前的单位
		if not oriObj then
			oriObj = target
		end


		local skillDamageBB = {
			isLastSeg = isLastSeg,
			damage = damage,
			damageProcessAfterCal = damageProcessAfterCal,
		}
		--溅射目标
		self:onSputterTarget(oriObj, args, final, damageArgs, skillDamageBB)

		--穿透目标
		self:onPenetrateTarget(oriObj, args, final, damageArgs, skillDamageBB)

		if newDamageArgs.extraShowValueF then
			segValue:add(newDamageArgs.extraShowValueF) -- 只是用于接下来显示
		end

		if newDamageArgs.beAttackToDeath then
			self:addObjectToKillTab(target)
		end

		-- 子弹时间
		if isLastSeg then
			self.scene.play:checkBulletTimeShow()
		end
	end

	-- 加血
	if args.process.segType == battle.SkillSegType.resumeHp then
		if self:onHealToDamageTarget(target, processCfg, final, effectCfg, segId) then
			local hpArgs = table.deepcopy(final.args)
			hpArgs.from = battle.ResumeHpFrom.skill
			hpArgs.ignoreBeHealAddRate = false
			-- hpArgs.isLastDamageSeg = table.length(effectCfg.hpSeg) == segId

			local segPer = effectCfg.hpSeg[segId]		-- 加血分段 比例
			segValue = target:resumeHp(self.owner, math.floor(final.value*segPer),hpArgs)
			final.real:add(segValue)
		end
	end

	-- 每个小段收集一次表现函数的数据 (这些会根据segshow中的每小段来分别播放,当前不会立即播放)
	-- 这个地方因为涉及到被动触发或者buff触发,所以可能会有多层的记录产生,后续会分层收集下

	args.values[target.id][segId] = args.values[target.id][segId] or {}
	args.values[target.id][segId].value = segValue
	if not args.values[target.id][segId].deferList then
		args.values[target.id][segId].deferList = gRootViewProxy:proxy():popDeferList(deferKey)
	else
		local list = gRootViewProxy:proxy():popDeferList(deferKey)
		for _,v in ipairs(list) do
			args.values[target.id][segId].deferList:push_back(v)
		end
	end
end

function SkillModel:addObjectToKillTab(obj)
	if not itertools.include(self.killedTargetsTb, obj) then
		table.insert(self.killedTargetsTb, obj)
	end
end

function SkillModel:getTargetsFinalResult(targetId,segType)
	local final = self.targetsFinalResult[targetId]
	if not final then
		final = {
			[battle.SkillSegType.damage] = {
				real = battleEasy.valueTypeTable()
			},
			[battle.SkillSegType.resumeHp] = {
				real = battleEasy.valueTypeTable()
			},
		}
		local mt
		mt = {
			skillMiss = false,
			__index = function(_, k)
				if final.damage.args then
					return final.damage.args[k]
				elseif final.resumeHp.args then
					return final.resumeHp.args[k]
				end
				return mt[k]
			end
		}
		final.args = setmetatable({}, mt)

		self.targetsFinalResult[targetId] = final
	end

	if segType then
		return final[segType]
	end

	return final
end

function SkillModel:pairsTargetsFinalResult(segType)
	return function(_, k)
		local v
		k, v = next(self.targetsFinalResult, k)
		return k, v and v[segType]
	end, self.targetsFinalResult, nil
end

function SkillModel:getTargetDamage(target)
	if target.ignoreDamageInBattleRound then return 0 end
	return table.get(self.targetsFinalResult,target.id,battle.SkillSegType.damage,"value") or 0
end

function SkillModel:chcekTargetInFinalResult(id)
	return battleEasy.ifElse(self.targetsFinalResult[id],true,false)
end

-- 计算伤害公式数据
function SkillModel:calcFormula(key, formula, target)
	-- 已经计算过总值
	local v = table.get(self.targetsFormulaResult, target.id, key)
	if v then return v end

	-- 用公式做key
	self.protectedEnv:resetEnv()
	local env = battleCsv.fillFuncEnv(self.protectedEnv, {
		target = target,
	})
	local ret = battleCsv.doFormula(formula, env)
	table.set(self.targetsFormulaResult, target.id, key, ret)
	return ret
end

-- 过程段加buff
function SkillModel:processAddBuff(processCfg, targets, extraTarget, timePoint)
	log.battle.skill('processAddBuff', self.owner.seat, targets and table.length(targets), timePoint)

	if itertools.isempty(processCfg.buffList) then
		return
	end

	local buffTb = {}
	local noMissTargetsArray = {}
	for _, obj in ipairs(targets) do
		if obj then
			local skillMiss = table.get(self.targetsFinalResult, obj.id, 'args', 'skillMiss')
			if not skillMiss then
				table.insert(noMissTargetsArray, obj)
			end
		end
	end
	for i, id in ipairs(processCfg.buffList) do
		local buffCfg = csv.buff[id]
		if not buffCfg then
			printError(string.format("id(%s) not in csv.buff", id))
		end
		if buffCfg.skillTimePos == timePoint then
			for _, obj in ipairs(noMissTargetsArray) do
				local deferKey
				if timePoint == battle.SkillAddBuffType.InPlay then
					deferKey = gRootViewProxy:proxy():pushDeferList(self.id, processCfg.id, 'buffDelay')
				end
				self:addProcessBuffBefore(id,obj,self.owner,buffCfg)
				local newArgs = BuffArgs.fromSkill(self, extraTarget, obj, processCfg, buffCfg, i)
				local newBuff = self:addProcessBuff(id,obj,self.owner,buffCfg,newArgs)

				-- 技能成功并且附加了指定buff的时候触发的被动技能
				if newBuff then
					obj:onPassive(PassiveSkillTypes.additional, obj, {buffCfgId = newBuff.cfgId})
				end

				if timePoint == battle.SkillAddBuffType.InPlay then
					buffTb[obj.id] = gRootViewProxy:proxy():popDeferList(deferKey)
				end
			end
		end
	end

	if itertools.isempty(buffTb) then
		return
	end
	return buffTb
end

function SkillModel:addProcessBuffBefore(id, holder, caster, buffCfg)
end

function SkillModel:addProcessBuff(id,holder,caster,buffCfg,args)
	local isGlobal = self.scene:getGroupBuffId(buffCfg.easyEffectFunc)

	local addBuffFunc = isGlobal and addBuffToScene or addBuffToHero
	return addBuffFunc(id, holder, caster, args)
end

-- 获取当前冷却剩余时间
function SkillModel:getLeftCDRound()
	-- 包括被动技能
    if self.cdRound == 0 then
		return 0
	end
	local curRound = self.owner:getBattleRound(2)
	return self.cdRound - (curRound - self.spellRound - 1)
end

--获取当前已经充能的回合
function SkillModel:getCurChargingRound()
	return _min(self.owner:getBattleRound(2) - self.chargeRound, 3)
end

-- 保存本次攻击的目标,给显示用 (也可能给其它用)
function SkillModel:saveAllTargets()
	local noMissTargets = {}
	for __,targets in maptools.order_pairs(self.allProcessesTargets) do
		for _, obj in ipairs(targets) do
			if obj then
				self.allTargets[obj.id] = obj
				local miss = table.get(self.targetsFinalResult, obj.id, 'args', 'skillMiss')
				if not miss then
					noMissTargets[obj.id] = obj
				end
			end
		end
	end
	return self:targetsMap2Array(noMissTargets)
end

--所有实际造成伤害不是加BUFF的目标,含有伤害公式的才是伤害目标
function SkillModel:saveAllDamageTargets()
	local allProcessesDamageTargets = {}
	for k,v in pairs(self.allProcessesTargets) do
		local _effectEventID = csv.skill_process[k].effectEventID
		local cfg = csv.effect_event[_effectEventID]
		if cfg and cfg.damageSeg then
			allProcessesDamageTargets[k] = v
		end
	end
	for __,targets in maptools.order_pairs(allProcessesDamageTargets) do
		for _, obj in ipairs(targets) do
			if obj then
				self.allDamageTargets[obj.id] = obj
			end
		end
	end
	-- 决斗处理damageTargets
	if self.owner:isBeInSneer() then
		local spreadArg = self.owner:getSneerExtraArgs(false)
		if spreadArg == battle.SneerArgType.NoSpread or spreadArg == battle.SneerArgType.BuffSpread then
			local sneerObj = self.owner:getSneerObj()
			for k, v in pairs(self.allDamageTargets) do
				if sneerObj and sneerObj ~= v then
					self.allDamageTargets[k] = nil
				end
			end
		end
	end
end

-- 本次的所有攻击目标
function SkillModel:targetsMap2Array(mapTargets)
	local ret = {}
	for _,obj in maptools.order_pairs(mapTargets,"id") do
		table.insert(ret,obj)
	end
	-- for i = 1, self.scene.play.ObjectNumber do
	-- 	if mapTargets[i] then
	-- 		table.insert(ret, mapTargets[i])
	-- 	end
	-- end
	return ret
end

function SkillModel:interrupt(type, buffId)
	if type == battle.SkillInterruptType.charge then
		self:chargingBeInterrupted()
	end
	self.interruptBuffId = buffId
end

function SkillModel:interruptBuffId()
	return self.interruptBuffId
end

-- 技能充能中被打断时,修改一些状态
function SkillModel:chargingBeInterrupted()
	-- 有充能回合时,中断充能
	if self.chargeRound then
		battleEasy.deferNotifyCantJump(self.owner.view,'playCharge',self.chargeArgs.action,true)
	end
	-- 清除充能回合的记录
	self.chargeRound = nil
	-- 技能冷却恢复
	self.spellRound = self.lastSpellRound
	-- 怒气返还
	self:startDeductMp(true)
	self.owner:triggerBuffOnPoint(battle.BuffTriggerPoint.onChargeBeInterrupted)
end

-- buff修改技能属性值
function SkillModel:addAttr(attrName, value, reverse)
	if attrName == 'skillNatureType' then
		self[attrName] = reverse and self.cfg[attrName] or value
	else
		self[attrName] = self[attrName] + (reverse and -value or value)
	end
end

-- 混合动画用 , 技能结束后的动画表
function SkillModel:pushDefreListToSkillEnd(event,t)
	if self.disposeDatasOnSkillEnd[event] and t then
		-- 只有表现需要 反作弊不需要
		battleEasy.effect(nil,function()
			for _,func in t:ipairs() do
				self.disposeDatasOnSkillEnd[event]:push_back(func)
			end
		end)
	else
		self.disposeDatasOnSkillEnd[event] = t
	end
end

--返回结束后的动画表
function SkillModel:pushDefreListAfterComeBack(event,t)
	if self.disposeDatasAfterComeBack[event] and t then
		battleEasy.effect(nil,function()
			for _,func in t:ipairs() do
				self.disposeDatasAfterComeBack[event]:push_back(func)
			end
		end)
	else
		self.disposeDatasAfterComeBack[event] = t
	end
end

function SkillModel:isSameType(checkType)
	return battleEasy.isSameSkillType(self.skillFormulaType, checkType)
end

function SkillModel:isMainNumShowType()
	if self.skillFormulaType == battle.SkillFormulaType.fix then
		local totalDmg = self:getTargetsFinalValue()
		return totalDmg ~= 0 and battle.SkillFormulaType.damage or battle.SkillFormulaType.resumeHp
	end
	return self.skillFormulaType
end

function SkillModel:isNormalSkillType()
	return self.skillType == battle.SkillType.NormalSkill
end

-- 同阵营 或者不带有伤害的技能不进行替换
function SkillModel:replaceLethalTargets(targets, needObjsBack)
	if not self:isSameType(battle.SkillFormulaType.damage) then
		return targets, targets
	end
	local uniqueTargetId = {}
	local ret = {}
	local oriRet = {}
	for _, target in ipairs(targets) do
		local toObj, aoeTwice
		if target.force ~= self.owner.force then
			toObj, aoeTwice = target:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.lethalProtect, "tryProtect")
		end
		if toObj then
			table.insert(ret, toObj)
			table.insert(oriRet, target)
			if not aoeTwice then
				uniqueTargetId[toObj.id] = true
			end
		else
			if not self.protecterObjs[target.id] then
				table.insert(ret, target)
				table.insert(oriRet, false)
			end
		end
	end

	for i = table.length(ret),1,-1 do
		if ret[i] and not oriRet[i] and uniqueTargetId[ret[i].id] then
			table.remove(ret, i)
			table.remove(oriRet, i)
		end
	end

	if needObjsBack then
		-- 把螺丝放到整个targets的后面
		local backTargets = {}
		for i = table.length(ret),1,-1 do
			if ret[i] and ret[i].markID == 4171 then -- 临时使用markID特殊处理
				table.insert(backTargets, ret[i])
				table.remove(ret, i)
			end
		end
		for _, v in ipairs(backTargets) do
			table.insert(ret, v)
		end
	end
	return ret, oriRet
end
-- 保护目标表现
function SkillModel:filterProtectorView(target, protectorIDList)
	if self:isSameType(battle.SkillFormulaType.damage) then
		local obj = target:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.lethalProtect, "getProtectObj")
		local protectData = target:getEventByKey(battle.ExRecordEvent.protectTarget)
		obj = obj or (protectData and protectData.obj)

		if not obj then return end

		if not itertools.include(protectorIDList,obj.view) then
			table.insert(protectorIDList,obj.view)
		end

		return {
			view = obj.view,
			targetID = target.seat,
		}
	end
end

function SkillModel:getSkillNatureType()
	local buffData = self.owner:getOverlaySpecBuffData(battle.OverlaySpecBuff.changeSkillNature)
	local type = buffData.skillNatures and buffData.skillNatures[self.id]
	if type then
		return type
	end

	local skillCfg = self.cfg
	type = skillCfg and skillCfg.skillNatureType
	return type
end

function SkillModel:getSkillSceneTag()
	local obj = self.scene.play.curHero
	return {
		isPossessAttack = self.owner:isPossessAttack(self.skillType),
		isPlaySkill = obj and (obj.curSkill == self),
		isBigSkill = self.skillType2 == battle.MainSkillType.BigSkill
	}
end

function SkillModel:setCsvObject(obj)
	self.csvObject = obj
end

function SkillModel:getCsvObject()
	return self.csvObject

end

function SkillModel:toHumanString()
	return string.format("SkillModel: %s", self.id)
end
