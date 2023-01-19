--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
--
-- 战斗逻辑对象
--

local abs = math.abs
local _max = math.max
local _min = math.min

local PassiveSkillTypes = battle.PassiveSkillTypes

globals.GroupObjectModel = class("GroupObjectModel", ObjectModel)

for attr, _ in pairs(ObjectAttrs.AttrsTable) do
	GroupObjectModel[attr] = function(self)
		return self.attrs:getFinalAttr(attr)
	end
end


local IDTotalDamage = 0
local IDCounterTag = 200
local hideSelfEffectEventArgFields = {
	sound = {'sound'},
	shaker = {'shaker','segInterval'},
	music = {'music'},
	move = {'move'},
	hpSeg = {'hpSeg', 'segInterval'},
	effect = {'effectType', 'effectRes', 'effectArgs'},
	zOrder = {'zOrder'},
	follow = {'follow'},
	jump = {'jumpFlag'},
	control = {'control'},
}

local hideTargetEffectEventArgFields = {
	damageSeg = {'damageSeg', 'segInterval'}
}
-- 200000
function GroupObjectModel:ctor(scene,force)
	self.scene = scene
	self.view = nil -- view object proxy

	ObjectModel.IDCounter = ObjectModel.IDCounter + 1
	self.id = ObjectModel.IDCounter
	self.seat = battle.SpecialObjectId.teamShiled + force - 1 -- 1:13 2:14
	self.force = force
	self.faceTo = (self.force == 1) and 1 or -1
	self.attrs = ObjectAttrs.new() -- 属性
	self.hpTable = {0, 0, 0}  -- 全局护盾血量 [1]:血量 [3]:上限
	self.buffs = {}
	self.recordBuffDataTb = {} -- buff数据记录
	self.viewAniList = CVector.new()
	-- 保证逻辑正常的变量
	self.overlayCount = 1
end

-- 初始化界面
-- function GroupObjectModel:initView()
-- --    if not self.view then
-- --        self.view = gRootViewProxy:getProxy('onSceneAddObj', tostring(self), readOnlyProxy(self, {}))
-- --        self.view:proxy():updateLifeBarState(false)
-- --    else

-- --    end

--     battleEasy.deferNotify(self.view,'reloadUnit',"effectLayer")
-- end

function GroupObjectModel:init()
	self.unitID = 200000
	self.state = battle.ObjectState.none
	-- unit.csv
	self.unitCfg = csvClone(csv.unit[self.unitID])
	self.cardID = self.unitCfg.cardID
	self.hpTable = {0, 0, 0}
	-- self.state = battle.ObjectState.normal -- 初始化单位状态
	-- self.attackerCurSkill = {}

	if not self.unitCfg then
		error(string.format("no unit config id = %s", self.unitID))
	end

	self.stackPos = 0
	self.totalDamage = {}
	self.targetTotalDamage = {}
	self.targetRateDamage = {}
	self.attackerCurSkill = {}
	self.processIdList = CVector.new()

	self.scene.deadObjsToBeDeleted[self.id] = nil
	-- battleEasy.queueNotifyFor(self.view,'reloadUnit',"effectLayer")
end

function GroupObjectModel:initView()
    -- if self.view then
    --     -- self.view:proxy():setVisible(false)
    --     -- self.view:proxy():setVisibleEnable(false)
    --     battleEasy.queueEffect(function()
    --         self.view:proxy():setVisible(false)
    --         self.view:proxy():setVisibleEnable(false)
    --     end)
    --     return
    -- end
    local objViewArgs = {type = battle.SpriteType.Normal}
    self.view = gRootViewProxy:getProxy('onSceneAddObj', tostring(self), readOnlyProxy(self), objViewArgs)
    self.view:proxy():updateLifeBarState(false)
    self.view:proxy():setVisible(false)
    self.view:proxy():setVisibleEnable(false)
    -- battleEasy.queueNotifyFor(self.view,'reloadUnit',"effectLayer")
end

function GroupObjectModel:reloadUnit(buff)
	local isNeedInitView = self:isDeath()

	self.unitRes = (buff and buff.csvCfg.effectResPath) and buff.csvCfg.effectResPath or self.unitCfg.unitRes --优先调用buff的资源地址
	self.state = battle.ObjectState.normal -- 初始化单位状态
	self.attackerCurSkill = {}

	if buff then
		if buff.csvCfg.buffActionEffect then
			self.view:proxy():resetActionTab()
			for action,replaceAct in csvMapPairs(buff.csvCfg.buffActionEffect) do
				self.view:proxy():onPushAction(battle.SpriteActionTable[action],replaceAct)
			end
		end
		if self.cfgId == nil or self.cfgId ~= buff.cfgId then
			self:hpMax(buff.buffValue)
			isNeedInitView = true
		else
			self:hpMax(math.max(self:hp(),0) + buff.buffValue)
		end

		self.cfgId = buff.cfgId
		local specailValArgs = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or {}
		self.buffs = specailValArgs.buffs or {}
		self.addBuffsForce = specailValArgs.force
		self.addBuffsNums = specailValArgs.nums
		self.caster = buff.caster
	end

	if isNeedInitView then
		-- {normal,dead} 添加一个normal时要将前一个dead pop
		-- 防止pop push 轴对不上
		if self.scene.deadObjsToBeDeleted[self.id] then
			self.scene.deadObjsToBeDeleted[self.id] = nil
			self.viewAniList:pop_back()
		end
		-- self.scene.deadObjsToBeDeleted[self.id] = nil
		-- battleEasy.queueEffect(function()
		--     self.view:proxy():onEventEffectQueue('callback', {func = function()
		--         self.view:proxy():onReloadUnit("effectLayer")
		--         self.view:proxy():setVisibleEnable(true)
		--         self.view:proxy():setVisible(true)
		--         self.viewState = battle.ObjectState.normal
		--      end, delay = 0})
		-- end)
		self.viewAniList:push_back(battle.ObjectState.normal)
		self.scene:addCallBackToBattleTurn(function()
			self:playStateView()
		end)
		-- self.scene:addObjViewToBattleTurn(self,'reloadUnit',"effectLayer")
		-- battleEasy.queueNotifyFor(self.view,'reloadUnit',"effectLayer")
	end
end

function GroupObjectModel:hp(show)
	if not show then
		return self.hpTable[1]
	end
	return
end

function GroupObjectModel:setHP(val)
	if val then
		self.hpTable[1] = val + self:hp()
	end
	return self.hpTable[1]
end

function GroupObjectModel:hpMax(val)
	if val then
		self.hpTable[2] = val
		self.hpTable[1] = val
	end
	return self.hpTable[2]
end

function GroupObjectModel:isHit(target,cfg)
	return true
end

function GroupObjectModel:getBattleRound(skillTimePos)
	return self.scene.play.curRound
end

function GroupObjectModel:getBattleRoundAllWave(skillTimePos)
	return self.scene.play.totalRound
end

--记录 开启全局护盾的人id 与技能id
function GroupObjectModel:pushRecordData(objId,skillId)
	self.stackPos = self.stackPos + 1
	self.targetTotalDamage[self.stackPos] = {}
	self.totalDamage[self.stackPos] = {}
	self.targetRateDamage[self.stackPos] = {}
end

function GroupObjectModel:popRecordData(objId,skillId)
	self.processIdList:pop_back()
	if self.stackPos > 0 then
		self.targetTotalDamage[self.stackPos] = nil
		self.totalDamage[self.stackPos] = nil
		self.targetRateDamage[self.stackPos] = nil
		self.stackPos = self.stackPos - 1
	end
end

function GroupObjectModel:syncView(skill,args,isSegProcess)
	local processId = args.process.id
	local effectCfg = skill.processEventCsv[processId]   -- 每个小的分段数据

	args.ignoreEvenet = args.ignoreEvenet or {}
	args.ignoreEvenet[self.id] = hideSelfEffectEventArgFields
	args.otherTargets[self.id] = self

	if self.totalDamage[self.stackPos] and next(self.totalDamage[self.stackPos]) then
		args.viewTargets = {}
		for k,v in ipairs(args.targets) do
			table.insert(args.viewTargets,v)
		end
		args.otherTargets[self.id] = nil
		-- 伤害表现
		if isSegProcess then
			if ( args.process.segType == battle.SkillSegType.damage and self.totalDamage[self.stackPos]
				and self.totalDamage[self.stackPos][processId]
				and self.totalDamage[self.stackPos][processId] > 0) then
				args.ignoreEvenet = args.ignoreEvenet or {}
				self:switchToRealDamage(processId) -- 转换为真实伤害
				for segId, _ in ipairs(effectCfg.segInterval) do
					local isLastSeg = (segId == table.length(effectCfg.segInterval))
					self:dealGroupObjectSeg(skill,processId,args,segId,isLastSeg)
					for _,obj in ipairs(args.targets) do
						args.ignoreEvenet[obj.id] = hideTargetEffectEventArgFields
					end
				end

				table.insert(args.viewTargets,self)
			end
		else
			table.insert(args.viewTargets,self)
		end
	end

	if not self:isDeath() then
		if self:hp() <= 0 then
			self:setDead(skill.owner)
		end
		-- 其他表现
		-- if effectCfg and effectCfg.show then
		--     battleEasy.queueNotifyFor(self.view, 'processArgs', processId, args)
		-- end
	end
end

function GroupObjectModel:dealGroupObjectSeg(skill,processId,args,segId,isLastSeg)

	-- local damage = self.totalDamage[self.stackPos][processId]

	-- self.totalDamage[self.stackPos][IDTotalDamage] = self.totalDamage[self.stackPos][IDTotalDamage] or 0
	-- self.totalDamage[self.stackPos][IDTotalDamage] = self.totalDamage[self.stackPos][IDTotalDamage] + damage

	-- if self:hp() < 0 and self.totalDamage[self.stackPos][IDTotalDamage] + self:hp() > 0 then
	--     damage = self.totalDamage[self.stackPos][IDTotalDamage] + self:hp()
	-- end
	-- if damage < 0 then return end

	local damage = self.targetTotalDamage[self.stackPos][processId][self.id]
	local segValue = battleEasy.valueTypeTable()
	local final = skill:getTargetsFinalResult(self.id, battle.SkillSegType.damage)

	if not args.values[self.id] then
		args.values[self.id] = {}
	end

	local effectCfg = gProcessEventCsv and gProcessEventCsv[processId]
	local segPer = effectCfg.damageSeg[segId]
	local deferKey = gRootViewProxy:proxy():pushDeferList(skill.id, processId,"groupObjectModel")

	local damageNumInfo = {
		segId = segId,
		isLastSeg = isLastSeg,
	}
	segValue:add(math.floor(segPer*damage))
	battleEasy.deferNotify(self.view, "showHeadNumber", {typ=0, num=segValue:get(), args=damageNumInfo})

	args.ignoreEvenet[self.id] = hideSelfEffectEventArgFields
	args.values[self.id][segId] = args.values[self.id][segId] or {}
	args.values[self.id][segId].value = segValue
	args.values[self.id][segId].deferList = gRootViewProxy:proxy():popDeferList(deferKey)
	final.real:add(segValue)
end

function GroupObjectModel:switchToRealDamage(processId)
	local totalDamage = self.totalDamage[self.stackPos][IDTotalDamage] -- 总伤害
	local shieldbeAttackDamage = totalDamage - (self:hp() < 0 and math.abs(self:hp()) or 0) -- 护盾受到的伤害

	if self:hp() < 0 then
		for objId,damage in pairs(self.targetTotalDamage[self.stackPos][processId]) do
			self.targetTotalDamage[self.stackPos][processId][objId] = damage / totalDamage * (totalDamage - shieldbeAttackDamage)
		end
	else
		self.targetTotalDamage[self.stackPos][processId] = {}
	end

	 -- 护盾所受伤害
	 self.targetTotalDamage[self.stackPos][processId][self.id] = self.totalDamage[self.stackPos][processId] / totalDamage * shieldbeAttackDamage
end

function GroupObjectModel:beAttack(attacker,target,record)
	-- if self:IsGateClose() then return end
	local damage = record.valueF
	local damageArgs = record.args
	logf.battle.object.groupShield("全护盾  %d 攻击 当前hp %f - damage %f => 最终hp %f",attacker and attacker.seat,self:hp(),damage,self:hp() - damage)
	if damage > 0 and not self:isDeath() and not damageArgs.ignoreGroupShiled then
		self:setHP(-damage)

		if damageArgs.processId then
			if damageArgs.processId ~= self.processIdList:back() then
				self:pushRecordData()
				self.processIdList:push_back(damageArgs.processId)
			end
			self:saveTargetDamage(target.id,damage,damageArgs.processId)
			self:saveProcessDamage(damage,damageArgs.processId)
		end

		if damageArgs.from == battle.DamageFrom.skill then
			return damage
		elseif damageArgs.processId then
			if damageArgs.isProcessState.isEnd then
				local targetTotalDamage = self.targetTotalDamage[self.stackPos][IDTotalDamage]
				-- 血量小于0 受到的伤害为全护盾的绝对值
				local totalDamage = self.totalDamage[self.stackPos][damageArgs.processId]
				local realTotalDamage = self:hp() < 0 and math.abs(self:hp()) or totalDamage
				local groupShieldDamageArgs = clone(damageArgs)
				local obj

				groupShieldDamageArgs.ignoreGroupShiled = true
				for _, obj in self.scene:ipairsHeros() do
					if obj and not obj:isAlreadyDead() and targetTotalDamage[obj.id] then
						obj:beAttack(attacker, realTotalDamage*(targetTotalDamage[obj.id]/totalDamage), record.id, groupShieldDamageArgs)
					end
				end
				-- for i=1,self.scene.play.ObjectNumber do
				--     obj = self.scene:getObjectBySeatExcludeDead(i)
				--     if obj and targetTotalDamage[obj.id] then
				--         obj:beAttack(attacker, realTotalDamage*(targetTotalDamage[obj.id]/totalDamage), record.id, groupShieldDamageArgs)
				--     end
				-- end
				-- 先计算伤害 后计算回血
				if self:hp() < 0 then
					self:setDead(attacker)
				end
				self:popRecordData()
				-- return damage - realTotalDamage*(targetTotalDamage[target.id]/totalDamage)
			end
			return damage
		elseif self:hp() + damage > 0 then
			if self:hp() < 0 then
				self:setDead(attacker)
				return damage + self:hp()
			else
				battleEasy.queueNotifyFor(self.view, "showHeadNumber", {typ=0, num=damage, args=damageArgs})
				battleEasy.queueNotifyFor(self.view, "eventEffect","callback",{func = function()
					self.view:proxy():beHit(0, 600)
					self.view:proxy():addActionCompleteListener(function()
						self.view:proxy():onPlayState(battle.SpriteActionTable.standby)
					end)
				end})
				return damage
			end
		end
	end
end

function GroupObjectModel:saveTargetDamage(targetId,damage,processId)
	local skillTargetDamages = self.targetTotalDamage[self.stackPos][processId] or {}
	skillTargetDamages[targetId] = skillTargetDamages[targetId] or 0
	skillTargetDamages[targetId] = skillTargetDamages[targetId] + damage
	self.targetTotalDamage[self.stackPos][processId] = skillTargetDamages
	self.targetTotalDamage[self.stackPos][IDTotalDamage] = self.targetTotalDamage[self.stackPos][IDTotalDamage] or {}
	self.targetTotalDamage[self.stackPos][IDTotalDamage][targetId] = self.targetTotalDamage[self.stackPos][IDTotalDamage][targetId] or 0
	self.targetTotalDamage[self.stackPos][IDTotalDamage][targetId] = self.targetTotalDamage[self.stackPos][IDTotalDamage][targetId] + damage
end

function GroupObjectModel:saveProcessDamage(damage,processId)
	local _totalDamage = self.totalDamage[self.stackPos][processId]
	_totalDamage = _totalDamage or 0
	_totalDamage = _totalDamage + damage
	self.totalDamage[self.stackPos][processId] = _totalDamage
	self.totalDamage[self.stackPos][IDTotalDamage] = self.totalDamage[self.stackPos][IDTotalDamage] or 0
	self.totalDamage[self.stackPos][IDTotalDamage] = self.totalDamage[self.stackPos][IDTotalDamage] + damage
end

function GroupObjectModel:setDead(attacker)
	if self:isDeath() then return end
	self.state = battle.ObjectState.realDead
	self.attackMeDeadObj = attacker
--    local skill = attacker.curSkill
--    gRootViewProxy:proxy():pushDeferList()
--    battleEasy.queueEffect(function()
----		battleEasy.queueNotify('sceneDeadObj', tostring(self), self, attacker)
----        self.view = nil

--	end)
	-- -- 加入移除记录中
	if not self.scene.deadObjsToBeDeleted[self.id] then
		self.viewAniList:push_back(battle.ObjectState.realDead)
	end
	self.scene:addObjToBeDeleted(self)


	-- battleEasy.queueNotifyFor(self.view, "dead", nil,function() end)
	self:dispatchBuffToHeros()
end

function GroupObjectModel:dispatchBuffToHeros()
	local args = {
		lifeRound = 1,
		prob = 1,
		value = {self.force,self.attackMeDeadObj and self.attackMeDeadObj.seat or 0},
		buffValue1 = 0,
		isSceneBuff = true,
	}
	local realDead = gRootViewProxy:proxy():pushDeferList(self.id, 'realDead')
	-- addBuffsNums   限制数量
	-- addBuffsForce  1:己方 2:敌方 3:全体
	for _, v in ipairs(self.buffs) do
		local count = 0
		for _, obj in self.scene:ipairsHeros() do
			if (obj.force == self.force and self.addBuffsForce ~= 2) -- 同阵营
				or (obj.force ~= self.force and self.addBuffsForce ~= 1) then  -- 不同阵营
				local buff = addBuffToHero(v, obj, self.caster, args)
				if buff then count = count + 1 end
			end
			if count == self.addBuffsNums then break end
		end
	end
	self.scene:addListViewToBattleTurn(self,gRootViewProxy:proxy():popDeferList(realDead))
end

function GroupObjectModel:isDeath()
	return self.state == battle.ObjectState.realDead or self.state == battle.ObjectState.none
end

function GroupObjectModel:isInStealth(ignoreParam)
	return false
end

function GroupObjectModel:isAttackableStealth()
	return false
end

-- 获得全体护盾值
function GroupObjectModel:getShieldHp()
	if self:isDeath() then return 0 end
	if self:hp() < 0 then return 0 end
	return self:hp()
end

function GroupObjectModel:playStateView()
	if self.viewAniList:size() == 0 then return end
	local topState = self.viewAniList:pop_front()
	if topState == battle.ObjectState.normal then
		self.view:proxy():onReloadUnit("effectLayer")
		self.view:proxy():setVisibleEnable(true)
		self.view:proxy():setVisible(true)
	elseif topState == battle.ObjectState.realDead and self.viewAniList:size() == 0 then
		battleEasy.effect(self, "effect",{action=battle.SpriteActionTable.death, onComplete = function()
			self.view:proxy():setVisible(false)
			self.view:proxy():setVisibleEnable(false)
		end})
	end
end

function GroupObjectModel:toHumanString()
	return string.format("GroupObjectModel: %s(%s)", self.id, self.seat)
end