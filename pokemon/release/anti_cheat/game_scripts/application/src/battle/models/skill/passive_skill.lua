--
-- 被动技能
-- skillType 3
--

local PassiveSkillTypes = battle.PassiveSkillTypes
local TriggerTypeMap

local PassiveSkillModel = class("PassiveSkillModel", battleSkill.SkillModel)
battleSkill.PassiveSkillModel = PassiveSkillModel
local triggerWithOutDeathCheck = { -- 不需要走owner是否死亡检测的触发点
	[PassiveSkillTypes.beDeathAttack] = true,
	[PassiveSkillTypes.realDead] = true,
	[PassiveSkillTypes.create] = true,
}

function PassiveSkillModel:ctor(scene, owner, cfg, level)
	battleSkill.SkillModel.ctor(self, scene, owner, cfg, level)

	-- for csv easy
	self.type = cfg.passiveTriggerType
	-- 跟主动含义不同，不存在蓄力阶段
	self.startRound = cfg.passiveStartRound
	-- 同技能互斥次数
	self.skillMuteTimeCheck = nil
end

-- 被动和主动处理不同，被动是每次实时判断
function PassiveSkillModel:canSpell()
	if self.owner:isDeath() and not triggerWithOutDeathCheck[self.type] then	-- todo 可能以后某些buff是在死亡时触发的,需要再加上判断
		return false
	end
	-- 消耗mp1 测试
	if self.costMp1 and (self.costMp1 > 0) then
		return self.owner:mp1() >= self.costMp1
	end

	-- 无法使用该技能  alwaysEffective:true 被动技能不受禁用影响
	-- if self.owner:isSKillType2Close(self.skillType2) then
	if not self.cfg.alwaysEffective and self.owner:isLogicStateExit(battle.ObjectLogicState.cantUseSkill, {skillType2 = self.skillType2}) then
		return false
	end

	self:updateSkillMuteTimeCheck()
	if self.skillMuteTimeCheck == false then
		return false
	end

	-- 主动蓄力的回合数
	-- if round < self.startRound then
	-- 	return false
	-- end

	return 1 > self:getLeftCDRound()
end

function PassiveSkillModel:updateSkillMuteTimeCheck()
	if self.skillMuteTimeCheck ~= nil then return end
	-- 只会校验一次
	if self.cfg.allEffectTime and table.length(self.cfg.allEffectTime) > 0 then
		local eventIds = self.scene:getEventByKey(battle.ExRecordEvent.skillEffectLimit, self.id, self.owner.force)
		local time = self.cfg.allEffectTime[1]
		local data
		for i=2, table.length(self.cfg.allEffectTime) do
			data = self.cfg.allEffectTime[i]
			if self.scene.gateType == data[1] then
				time = data[2]
				break
			end
		end

		if not eventIds or table.length(eventIds) < time then
			if not itertools.include(eventIds, self.owner.id) then
				self.scene:addExRecord(battle.ExRecordEvent.skillEffectLimit, self.owner.id, self.id, self.owner.force)
			end
		else
			self.skillMuteTimeCheck = false
			return
		end
	end
	self.skillMuteTimeCheck = true
end

function PassiveSkillModel:isAttackSkill()
	return false
end

-- @param: target为nil为自动选择
function PassiveSkillModel:_spellTo(target, args)
	-- TODO: 是否有特殊spell逻辑需要args？比如beAttack
	log.battle.skill.passiveSkill("trigger", self.owner.seat, self.id, 'target', target and target.seat, 'args', dumps(args))
	if self:trigger(target, args) then
		log.battle.skill.passiveSkill("spellTo", self.owner.seat, self.id, 'target', target and target.seat)
		battleSkill.SkillModel._spellTo(self, target)
	end
end

function PassiveSkillModel:trigger(target, args)
	local f = TriggerTypeMap[self.type]
	args = args or {}
	args.passiveTriggerArg = self.cfg.passiveTriggerArg
	return f(self, target, args)
end

function PassiveSkillModel:onTrigger(typ, target, args)
	if self.type > 0 and typ ~= self.type then
		return
	end

	if not self.owner:effectPowerControl(battle.EffectPowerType.passiveSkill, typ) then
		return
	end

	if self:canSpell() then
		self:spellTo(target, args)
	end
end

-- 触发被动导致owner死亡,飘字和血条变化会丢失
function PassiveSkillModel:processBefore(skillBB)
	skillBB.isDeath = self.owner:isDeath()
	battleSkill.SkillModel.processBefore(self, skillBB)
end

-- 被动技能中的表现,改为使用无序的effect来处理,但是在加入effectManager时,每个表现都需要有明确的时间先后或delay时间,
-- 技能表现 主要是技能前触发 技能动画 技能后触发 技能结束处理几个部分
-- 另外,需要注意在技能结束后触发的被动和技能结束死亡目标的处理,
-- 这两类需要补充到正常动画队列后面,否则按现有的队列, 当前的回合会提前结束

-- 被动技能这里不直接使用序列化,而是无序的, 不抢占主动技能的队列顺序
-- 被动的动画需要设置延迟时间, 各步骤的时间是按先后顺序逐渐累加的
function PassiveSkillModel:onSpellView(skillBB)
	-- 单位死亡时 表现时序 与 死亡删除精灵时序不可控
	if skillBB.isDeath then return end

	local target, posIdx = skillBB.target, skillBB.lastPosIdx

	local disposeDatasOnSkillStart = self.disposeDatasOnSkillStart
	local disposeDatasOnSkillEnd = self.disposeDatasOnSkillEnd
	local disposeDatasAfterComeBack = self.disposeDatasAfterComeBack
	local beInExtraAttack = self.scene:beInExtraAttack()

	battleEasy.deferCallback(function()
		-- self:_onSpellView(target, posIdx)
		log.battle.skill.onSpellView(' PassiveSkill onSpellView target.id=', target and target.seat, 'move pos=', posIdx)

		local view = self.owner.view
		local skillCfg = self.cfg
		-- local targets = self:targetsMap2Array(self.allTargets)	-- { [id]=obj }

		-- 1.设置localZ
		-- 分两步设置,先设置攻击者自身, 等移动过去后再统一设置
		-- gRootViewProxy:proxy():onEventEffect(self.owner, 'callback', {func = function()
		-- 	assertInWindows(target.view:proxy():getMovePosZ(), "[PassiveSkill Error] No target PosZ ,id : %s", target.id)
		-- 	assertInWindows(view:proxy():getMovePosZ(), "[PassiveSkill Error] No self obj PosZ ,id : %s", self.id)
		-- 	local tpz = target.view:proxy():getMovePosZ()
		-- 	local spz = view:proxy():getMovePosZ()
		-- 	local pz = math.min(tpz, spz)	--取自身和目标z轴的最小值,避免斜向移动时遮住其它目标
		-- 	view:proxy():setLocalZOrder(pz+1)		-- 自己在最上方
		-- end, delay = 0})

		local moveTime = 0		-- todo待计算
		local actionTime = skillCfg.actionTime or 0
		local noQueue = true
		-- if self.type == PassiveSkillTypes.roundStartAttack or self.type == PassiveSkillTypes.cycleRound then
		-- 	noQueue = true
		-- end
		-- moveTime
		gRootViewProxy:proxy():onEventEffect(self.owner, 'callback', {func = function()
			-- 2.朝目标移动
			view:proxy():onMoveToTarget(posIdx, {
				moveTime = skillCfg.moveTime,
				timeScale = beInExtraAttack and 0.51,
				cameraNear = skillCfg.cameraNear,
				cameraNear_posC = skillCfg.cameraNear_posC,
				posC = skillCfg.posC
			}, noQueue)

			-- 3.攻击时显示的层级
			--local tpz = target.view:proxy():getMovePosZ()
			--view:proxy():setLocalZOrder(tpz+1)	--自己在最上方

			-- 4.技能前加的buff
			view:proxy():onSkillBefore(disposeDatasOnSkillStart, self.skillType, noQueue, self:getSkillSceneTag())

			-- 5.技能动作
			-- 前面移动占用的时间,在这段时间后开始技能动作	-- todo 待计算
			view:proxy():onPlayAction(skillCfg.spineAction, actionTime, noQueue)
		end, delay = moveTime})

		-- moveTime + actionTime
		gRootViewProxy:proxy():onEventEffect(self.owner, 'callback', {func = function()
			for i, processCfg in self:ipairsProcess() do
				view:proxy():onProcessDel(processCfg.id)
			end
			-- 6.技能结束处理
			view:proxy():onObjSkillEnd(disposeDatasOnSkillEnd,self.skillType, noQueue)
			-- 移动后才需要恢复对应坐标
			view:proxy():onComeBack(posIdx, false, {
				moveTime = skillCfg.moveTime,
				timeScale = beInExtraAttack and 0.51,
				flashBack = skillCfg.flashBack,
			})
			--8.返回后 有回复mp之类的需要等待返回之后进行
			view:proxy():onAfterComeBack(disposeDatasAfterComeBack, noQueue)

			view:proxy():onObjSkillOver(noQueue)
		end, delay = moveTime + actionTime})
	end)
end

-- 行为触发，无需逻辑，直接返回true
local function defaultFuncTrue(skill, target, args)
	return true
end
-- 待添加 没有逻辑
local function defaultFuncNil(skill, target, args)
	return
end

TriggerTypeMap = {
	[PassiveSkillTypes.create] = defaultFuncTrue,

	[PassiveSkillTypes.round] = function (skill, target, args)
		return skill.scene.play.curRound == args.passiveTriggerArg
	end,
	[PassiveSkillTypes.cycleRound] = function (skill, target, args)
		local round = skill.scene.play.curRound
		return (round > 0) and ((round - 1) % (args.passiveTriggerArg + 1) == 0)
	end,

	[PassiveSkillTypes.realDead] = defaultFuncTrue,
	[PassiveSkillTypes.fakeDead] = defaultFuncTrue,
	[PassiveSkillTypes.beDeathAttack] = defaultFuncTrue,
	[PassiveSkillTypes.beAttack] = function (skill, target, args)
		return not args.miss
	end,
	[PassiveSkillTypes.enter] = defaultFuncTrue,
	[PassiveSkillTypes.attack] = defaultFuncTrue,

	[PassiveSkillTypes.roundEnd] = function (skill, target, args)
		if not args.passiveTriggerArg then return end
		return args.roundFlag == args.passiveTriggerArg
	end,

	[PassiveSkillTypes.kill] = defaultFuncTrue,

	[PassiveSkillTypes.beSpecialNatureDamage] = function (skill, target, args)
		-- natureType is skill.skillNatureType
		return args.natureType == args.passiveTriggerArg
	end,

	[PassiveSkillTypes.beStrike] = function (skill, target, args)
		return args.strike
	end,
	[PassiveSkillTypes.beNatureDamage] = function (skill, target, args)
		return args.natureFlag == 'strong'
	end,
	[PassiveSkillTypes.beNonNatureDamage] = function (skill, target, args)
		return args.natureFlag ~= 'strong'
	end,
	[PassiveSkillTypes.beDamageIfFullHp] = function (skill, target, args)
		return args.isFullHp
	end,
	[PassiveSkillTypes.beDamage] = function (skill, target, args)
		return args.type == 0
	end,
	[PassiveSkillTypes.beSpecialDamage] = function (skill, target, args)
		return args.type ~= 0
	end,

	[PassiveSkillTypes.hpLess] = function (skill, target, args)
		return skill.owner:hp() / skill.owner:hpMax() < args.passiveTriggerArg / ConstSaltNumbers.wan
	end,

	[PassiveSkillTypes.beSpeciaSelfForce] = defaultFuncNil,
	[PassiveSkillTypes.beWeather] = defaultFuncNil,
	[PassiveSkillTypes.beSpeciaBuff] = defaultFuncNil,
	[PassiveSkillTypes.beToolsComsumed] = defaultFuncNil,
	[PassiveSkillTypes.roundStartAttack] = defaultFuncTrue,	-- 到自身攻击回合的时候就是攻击回合开始时

	[PassiveSkillTypes.teamHpLess] = function (skill, target, args)
		for _, obj in args.objs:order_pairs() do
			if obj:hp() / obj:hpMax() < args.passiveTriggerArg / ConstSaltNumbers.wan then
				return true
			end
		end
		return false
	end,

	[PassiveSkillTypes.recoverHp] = function (skill, target, args)
		-- 目前只希望是主动技能触发的回血能触发这个被动，不希望buff能够触发
		return args.hpFormula and args.skillType == battle.SkillType.NormalSkill
	end,
	[PassiveSkillTypes.additional] = function (skill, target, args)
		return args.passiveTriggerArg == args.buffCfgId
	end,

    [PassiveSkillTypes.roundStart] = defaultFuncTrue,

	-- [PassiveSkillTypes.reAttack] = function (skill, target, args)
	-- 	return true
	-- end,
}

TriggerTypeMap[PassiveSkillTypes.dynamicHpLess] = TriggerTypeMap[PassiveSkillTypes.hpLess]
TriggerTypeMap[PassiveSkillTypes.dynamicTeamHpLess] = TriggerTypeMap[PassiveSkillTypes.teamHpLess]