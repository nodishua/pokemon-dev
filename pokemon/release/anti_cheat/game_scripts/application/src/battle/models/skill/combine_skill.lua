--
-- 合体技能
-- skillType 5
-- 立刻生效
--
local PassiveSkillTypes = battle.PassiveSkillTypes
local CombineSkillModel = class("CombineSkillModel", battleSkill.SkillModel)
battleSkill.CombineSkillModel = CombineSkillModel

local combineType = {
	[PassiveSkillTypes.roundStartAttack] = battle.CombineSkillType.smallRoundStart,
	[PassiveSkillTypes.roundEnd] = battle.CombineSkillType.smallRoundEnd,
	[PassiveSkillTypes.roundStart] = battle.CombineSkillType.bigRoundStart
}

function CombineSkillModel:ctor(scene, owner, cfg, level)
	battleSkill.SkillModel.ctor(self, scene, owner, cfg, level)

end


function CombineSkillModel:onTrigger(typ, target, args)
 	if self:isCanUseCombineSkill(combineType[typ]) then
		self.scene.play.curHero = self.owner

		target = self.scene.play:autoChoose(self.id)

		self.owner.curSkill = self
		self.owner.curTargetId = target.id

		if self:canSpell() then
			self.isPassiveRelease = true
			self.combineType = combineType[typ]
			self:spellTo(target)
		end
	end
end

local function checkCanUseSkill( obj )
	return not obj:isDeath() and not obj:isSelfControled() and not obj:isLogicStateExit(battle.ObjectLogicState.cantUseSkill, {skillType2 = battle.MainSkillType.BigSkill})
end

-- 合体技能 能否使用合体技能
function CombineSkillModel:isCanUseCombineSkill(combineSkillType)
	local conditionValue = self.cfg.conditionValue
	if not conditionValue then return false end

	if conditionValue[1] ~= combineSkillType then
		return false
	end

	local hasCombineObj = false
	local combineObjId

	local heros = self.scene:getHerosMap(self.owner.force)
	for _, obj in heros:order_pairs() do
		if obj and obj.cardID and checkCanUseSkill(obj) then
			local markId = obj.markID
			if markId == self.owner.unitCfg.combinationObjCardId then
				hasCombineObj = true
				combineObjId = obj.id
				self.owner.combineObj = obj 	-- 记录当前自己的合体目标
				-- obj.combineObj = self	-- 合体目标的合体目标也记录下
				break
			end
		end
	end

	if not hasCombineObj then return false end

	-- 是否超过可释放的最大值
	if not self.owner.useCombineSkillCount then self.owner.useCombineSkillCount = 0 end
	if not self.owner.combineObj.useCombineSkillCount then self.owner.combineObj.useCombineSkillCount = 0 end

	-- 取本身和合体目标配置中的最大使用次数的较小者来比较
	local combineObjSkillCfg = csv.skill[self.owner.combineObj.unitCfg.combinationSkillId]
	local maxSkillCount = math.min(conditionValue[3],combineObjSkillCfg.conditionValue[3])
	if self.owner.useCombineSkillCount + self.owner.combineObj.useCombineSkillCount >= maxSkillCount then return false end

	-- 是否满足条件
	self.protectedEnv:resetEnv()
	local env = battleCsv.fillFuncEnv(self.protectedEnv, {})
	local prob = battleCsv.doFormula(conditionValue[2],env)

	if prob < 1 then return false end

	return true
end

function CombineSkillModel:canSpell()
	if not checkCanUseSkill(self.owner) then
		return false
	end

	-- 技能指示器选中的目标大于0
	local tar = self:getTargetsHint()
	local sneerAtMeObj = self.owner:getSneerObj()
	if sneerAtMeObj and sneerAtMeObj:isLogicStateExit(battle.ObjectLogicState.cantBeSelect,{fromObj = self.owner}) then
		if self.owner:isBeInDuel() then
			return false
		else
			tar = self.owner:getCanAttackObjs(sneerAtMeObj.force)
		end
	end
	if table.length(tar) == 0 then return false end

	return self:getLeftCDRound() < 1
end

function CombineSkillModel:isJumpBigSkill()
	return self.canJump and userDefault.getForeverLocalKey("mainSkillPass", false)
end

function CombineSkillModel:updateRecord()
	self.owner:addExRecord(self.skillType2, 1)
end

function CombineSkillModel:spellToOver(skillBB)
	-- 合体技属性加成还原
	self:averageSelfDamageAttributesWithCombineObj(true)

	self.isPassiveRelease = nil

	return battleSkill.SkillModel.spellToOver(self, skillBB)
end

function CombineSkillModel:onSpellView(skillBB)
	local function effectSpell(  )
		battleEasy.deferNotify(nil, 'hideAllObjsSkillTips')
		battleEasy.deferNotify(nil, 'showHero', {typ = "showAll", hideLife=true})

		gRootViewProxy:proxy():flushCurDeferList()

		self:_onSpellView(skillBB)
	end

	if self.combineType and self.combineType == battle.CombineSkillType.smallRoundEnd then
		battleEasy.queueEffect(function()
			effectSpell()
		end)
	else
		effectSpell()
	end
end

function CombineSkillModel:_onSpellView(skillBB)
	local target, posIdx = skillBB.target, skillBB.lastPosIdx
	local scene = self.scene
	local view = self.owner.view
	local combView = self.owner.combineObj.view
	local skillCfg = self.cfg
	local targets = self:targetsMap2Array(self.allTargets)	-- { [id]=obj }
	local lastTarget

	log.battle.skill('onSpellView target.id=', target and target.seat, 'move pos=', posIdx)

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

	-- 0.大招前置动画
	local hideHero = {}
	--隐藏不在本次攻击中的目标
	for i = 1, self.scene.play.ObjectNumber do
		local obj = self.scene:getObjectBySeat(i)
		local exObj = self.scene:getObjectBySeat(i, battle.ObjectType.SummonFollow)
		if obj and (not self.allTargets[obj.id]) and (obj.id ~= self.owner.id) and (obj.id ~= self.owner.combineObj.id) then
			hideHero[i] = tostring(obj)
		end
		if exObj and (not self.allTargets[exObj.id]) and (exObj.id ~= self.owner.id) and (exObj.id ~= self.owner.combineObj.id) then
			hideHero[i + self.scene.play.ObjectNumber] = tostring(exObj)
		end
	end
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

	-- 3. 攻击时显示的层级
	battleEasy.queueEffect(function()
		local tpz = target.view:proxy():getMovePosZ()
		for id, obj in ipairs(targets) do
			tpz = math.max(tpz, obj.view:proxy():getMovePosZ())
		end

		view:proxy():setLocalZOrder(tpz+1)	--自己在最上方
	end)

	-- 4. 技能前的buff们
	if self.counterAttackForView then
		view:proxy():onShowCounterAttackText(tostring(self.owner)) --反击飘字跟buff飘字类似
		self.counterAttackForView = false
	end

	view:proxy():onSkillBefore(self.disposeDatasOnSkillStart, self.skillType, false, self:getSkillSceneTag())

	-- 4.1 技能前 按照配表隐藏需要隐藏的buff
	view:proxy():onAttacting(true)

	-- 5.0 播放音效
	if skillCfg.sound and not self.canjumpBigSkill then
		battleEasy.queueEffect('sound', {delay = skillCfg.sound.delay,sound = {res = skillCfg.sound.res, loop = skillCfg.sound.loop}})
	end

	-- 5.动作
	--if not self.canJump then
	local protectorIDList = {}
	for k,v in ipairs(self.actionSegArgs) do
		if not lastTarget or (lastTarget and lastTarget.id ~= v.target.id) then
			-- 2.移动到目标位置
			view:proxy():onMoveToTarget(v.posIdx, {
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

		view:proxy():onPlayAction(v.spine, v.lifeTime)
	end

	if self.canjumpBigSkill then
		local totalDmg,totalResumeHp = self:getTargetsFinalValue()
		local dmg, typ = totalDmg, battle.SkillSegType.damage
		if totalDmg == 0 and self:isSameType(battle.SkillFormulaType.resumeHp) then
			dmg, typ = totalResumeHp, battle.SkillSegType.resumeHp
		end
		local params = {delta = dmg, skillId = skillCfg.id, typ = typ}

		view:proxy():onUltJumpShowNum(params)
	end


	-- 6.结束 策划希望在有多个技能连续施放时(主要是被动技能),可以在不完全回去后再施放被动技能,所以把移动回去放到回合结束时了
	view:proxy():onObjSkillEnd(self.disposeDatasOnSkillEnd, self.skillType)

	-- 7.返回 配置了flashBack时才提前返回, 正常情况下因为被动技能也能移动的设定, 是需要等到battleTurn结束时才返回的
	-- 如果当前回合不是自己的攻击回合/是自己的回合,但是自己还没有开始行动(手动情况下)时,这类被动技能需要能自己返回位置
	view:proxy():onComeBack(posIdx, false, {
		delayBeforeBack = skillCfg.moveTime[3],
		backCostTime = skillCfg.moveTime[4],
		timeScale = self.scene:beInExtraAttack() and 0.51,
		flashBack = skillCfg.flashBack,
		attackFriend = self.owner:needAlterForce(),
	},false, protectorIDList)

	--8.返回后 有回复mp之类的需要等待返回之后进行
	view:proxy():onAfterComeBack(self.disposeDatasAfterComeBack)
	-- 技能后 恢复所有buff的显示
	view:proxy():onAttacting(false)

	-- 技能后 恢复standby_loop
	view:proxy():onResetPos()

	view:proxy():onObjSkillOver()

	-- if isPauseMusic then
	-- 	battleEasy.queueEffect('music', {music={op = 'resume'}})
	-- end
	-- 8. 延迟处理 为死亡目标预留的时间 -- 这里去掉, 不然角色攻击完时会等待一会
	-- -- 是否真的需要延迟,后面再考虑计算,目前先强制加上再说
	-- 修改： 当有角色死亡时，先计算死亡动画的时间, 然后以delay的形式放到本次动画队列的最后, 放在目标返回原位的后面吧。
end

-- 技能开始时扣除 mp
function CombineSkillModel:startDeductMp(isBack)
	if self.hadDeductedMp then	-- 如果已经扣除过mp就不再重复扣了
		self.hadDeductedMp = false
		return
	end
	-- 不消耗怒气
	if self.owner.exAttackArgs and self.owner.exAttackArgs.costType == 1 then return end
	if self:isNormalSkillType() then
		--有变身buff时,可以免费放一次大招,且不消耗怒气 策划想用配置
		-- if self.changedAndCanUseMainSkillOnce == 1 then
		-- 	self.changedAndCanUseMainSkillOnce = 0 --0 表示已经放过1次了，当前回合不会再触发免费大招
		-- else
		-- 	self.owner:setMP1(0, 0)			-- 释放大招 固定将怒气值降为0
		-- end
		self.owner:setMP1(0, 0)
		if self.cfg.conditionValue[5] and self.cfg.conditionValue[5] > 0 then
			self.owner.combineObj:setMP1(0, 0)
		end
		return
	end

	-- TODO: costMp1 暂时无用 但这段代码保留
	-- if self.costMp1 and self.costMp1 > 0 then
	-- 	local mp = self.owner:mp1() - self.costMp1
	-- 	self.owner:setMP1(mp, mp)
	-- end
end

function CombineSkillModel:startSpell()
	self.owner.useCombineSkillCount = self.owner.useCombineSkillCount + 1
	self:averageSelfDamageAttributesWithCombineObj() --先把攻击属性平均下

	battleSkill.SkillModel.startSpell(self)
end

local averageAttributes = {
	-- Int:false	Float:true
	{'damage',false},{'specialDamage',false},{'strike',true},{'strikeDamage',true},
	{'defenceIgnore',true},{'specialDefenceIgnore',true},{'breakBlock',true},
	{'ultimateAdd',true},{'damageAdd',true},{'damageReduce',true},{'physicalDamageAdd',true},
	{'specialDamageAdd',true},{'pvpDamageAdd',true},{'normalDamageAdd',true},
	{'fireDamageAdd',true},{'waterDamageAdd',true},{'grassDamageAdd',true},
	{'electricityDamageAdd',true},{'iceDamageAdd',true},{'combatDamageAdd',true},
	{'poisonDamageAdd',true},{'groundDamageAdd',true},{'flyDamageAdd',true},
	{'superDamageAdd',true},{'wormDamageAdd',true},{'rockDamageAdd',true},
	{'ghostDamageAdd',true},{'dragonDamageAdd',true},{'evilDamageAdd',true},
	{'steelDamageAdd',true},{'fairyDamageAdd'}
}
-- 合体目标的属性修正,只修正放技能的目标即可,另一边的目标无需修正
function CombineSkillModel:averageSelfDamageAttributesWithCombineObj(isMinus)
	local combineNumber = (self.cfg.conditionValue and self.cfg.conditionValue[4]) or 0.5
	if not isMinus then
		local recordTb = {}
		for _,v in ipairs(averageAttributes) do
			local selfIntAttr = self.owner[v[1]](self.owner)
			local combIntAttr = self.owner.combineObj[v[1]](self.owner.combineObj)
			recordTb[v[1]] = (v[2] and 10000 or 1) *((selfIntAttr + combIntAttr) * combineNumber - selfIntAttr)
		end

		-- 命中修正
		recordTb["hit"] = 10000 - self.owner:hit() * 10000
		recordTb["damageHit"] = 10000 - self.owner:damageHit() * 10000

		self.combineDamageAttrsAddFixTb = recordTb
	end
	if not self.combineDamageAttrsAddFixTb then return end
	local n = isMinus and -1 or 1
	itertools.each(self.combineDamageAttrsAddFixTb, function(attribute, val)
		self.owner:objAddBuffAttr(attribute,n * val)
	end)
end

function CombineSkillModel:isNormalSkillType()
	return not self.isPassiveRelease
end