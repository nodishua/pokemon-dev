--
-- 被动召唤技能
-- skillType 4
-- 立刻生效
--
local PassiveSkillTypes = battle.PassiveSkillTypes
local SummonSkillModel = class("SummonSkillModel", battleSkill.SkillModel)
battleSkill.SummonSkillModel = SummonSkillModel

function SummonSkillModel:ctor(scene, owner, cfg, level)
	battleSkill.PassiveSkillModel.ctor(self, scene, owner, cfg, level)

	-- self.skillArgs = cfg.skillArgs
	self.summonNum = cfg.skillArgs[5] or 1 -- 召唤单位个数
	self.summonUnitId = cfg.skillArgs[1] -- 召唤单位
	self.summonPos = battleEasy.ifElse(cfg.skillArgs[2] ~= -1 and self.summonNum > 1, 0, cfg.skillArgs[2]) -- 0类型 空位召唤  -1:场外
	self.summonLevel = battleEasy.ifElse(cfg.skillArgs[3] > 0,cfg.skillArgs[3],owner:getSummonerLevel()) -- 召唤单位等级
	self.summonAttrRate = cfg.skillArgs[4] -- 召唤单位属性转换
	self.summonBackStage = self.summonPos == -1 --召唤单位到场外
	--特殊属性继承比例 优先级高于args[4] specialDefault对应除六维外的属性默认值 {'specialDefault'= 默认比例; '属性名'= 比例; ...}
	self.summonSpecialRate = cfg.skillArgs[6] or {}
	self.isFollowMode = cfg.skillArgs[7] == 1 and true or false -- 是否为跟随模式
	self.followArgs = cfg.skillArgs[8] or {}

	self.summonUnitData = csv.unit[self.summonUnitId]
end

function SummonSkillModel:canSpell()
	if self.owner:isDeath() then	-- todo 可能以后某些buff是在死亡时触发的,需要再加上判断
		return false
	end

	if self.summonBackStage then
		return true
	end

	-- 满人数
	if self.scene:getForceNumIncludeDead(self.owner.force) == 6 then
		return false
	end
	-- 存在单位无法召唤
	if self.summonPos ~= 0 and self.scene:getObjectBySeat(self.summonPos) and self.summonNum == 1 then
		return false
	end

	return true
end

function SummonSkillModel:onTrigger(typ, target, args)
	if self.skillType ~= battle.SkillType.PassiveSummon then
		return
	end

	if self:canSpell() and battleSkill.PassiveSkillModel.trigger(self,target,args) then
		self:spellTo(target, args)
	end
end

function SummonSkillModel:processPlay(skillBB)
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

end

function SummonSkillModel:processTarget(skillBB)
	local processArgs = skillBB.processArgs
	-- 开始召唤
	local summonTargets = {}
	local summonPos = self.summonPos
	local owner = self.owner
	local stepNum = (owner.force == 1) and 0 or self.scene.play.ForceNumber
	local obj,roleOut,newTarget

	local summonGroupId = owner.summonGroup
	local ownerForce
	if self.summonBackStage then
		ownerForce = owner.force
	end
	if not summonGroupId then
		ObjectModel.IDCounter = ObjectModel.IDCounter + 1
		summonGroupId = ObjectModel.IDCounter
		owner.summonGroup = summonGroupId
	end
	for i=1,self.summonNum do
		if summonPos == 0 then
			for seat=1+stepNum, self.scene.play.ForceNumber+stepNum do
				obj = self.scene:getObjectBySeatExcludeDead(seat)
				if not obj then
					summonPos = seat
					break
				end
			end
		end
		if summonPos ~= 0 then
			roleOut = self:getSummonRoleOut()
			newTarget = self.scene.play:addCardRole(summonPos, roleOut, false, ownerForce)
			if self.summonBackStage then
				newTarget.summonGroup = summonGroupId
			else
				-- 加入出手队列
				table.insert(self.scene.play.roundLeftHeros,{obj=newTarget})
				-- 触发入场被动
				newTarget:initedTriggerPassiveSkill()
				self.scene:tirggerFieldBuffs(newTarget)
			end
			table.insert(summonTargets,newTarget)
			if not self.summonBackStage then summonPos = 0 end
		end
	end

	for i, processCfg in self:ipairsProcess() do
		local args = processArgs[i]	-- 每一过程段的 基本数据
		if i == 1 and self.isFollowMode then
			summonTargets = self:getFollowTargets(processCfg, skillBB.target)
		end
		-- 特殊目标为召唤出的单位组 24映射target\include.lua
		if processCfg.skillTarget == 24 then
			args.targets = summonTargets
			self.allProcessesTargets[processCfg.id] = args.targets
		end
		-- 发数据给显示中用
		battleEasy.queueNotifyFor(self.owner.view, 'processArgs', processCfg.id, args)
	end

	skillBB.summonTargets = summonTargets
end

function SummonSkillModel:getFollowTargets(processCfg, target)
	local followTargets = {}
	local processArgs = self:onProcess(processCfg, target)
	local roleOut, newTarget
	for _, obj in ipairs(processArgs.targets) do
		if obj.seat >= 1 and obj.seat <= self.scene.play.ObjectNumber then
			roleOut = self:getSummonRoleOut()
			roleOut.type = battle.ObjectType.SummonFollow
			newTarget = self.scene.play:addCardRole(obj.seat, roleOut, false, obj.force)
			if newTarget then
				table.insert(followTargets, newTarget)
				-- 触发入场被动
				newTarget:initedTriggerPassiveSkill()
				self.scene:tirggerFieldBuffs(newTarget)
			end
		end
	end
	return followTargets
end

function SummonSkillModel:isAttackSkill()
	return false
end

function SummonSkillModel:_spellTo(target)
	local skillBB = {skillCfg = self.cfg, target = target}
	self:processBefore(skillBB)

	self:processPlay(skillBB)

	self:processTarget(skillBB)

	-- 召唤后
	self:processAfter(skillBB)

	self:onSpellView(skillBB)
end

function SummonSkillModel:getSummonRoleOut()
	local csvData = self.summonUnitData
	local data = {
		skills = {},
		passiveSkills = {},
		cardId = csvData.cardID,
		roleId = self.summonUnitId,
		level = self.summonLevel,
		skillLevel = self.summonLevel,
		fightPoint = self.owner.fightPoint,
		star = self.owner.star,
		starEffect = self.owner.starEffect,
		type = battle.ObjectType.Summon,
		isFollowMode = self.isFollowMode,
		followArgs = self.followArgs
	}
	-- 属性继承
	local ownerAttr = self.owner.attrs:cloneFinalAttr()
	for attr,v in pairs(ownerAttr) do
		data[attr] = v
		if self.summonSpecialRate[attr] then
			data[attr] = data[attr] * self.summonSpecialRate[attr]
		else
			if ObjectAttrs.SixDimensionAttrs[attr] then
				data[attr] = data[attr] * self.summonAttrRate
			elseif self.summonSpecialRate["specialDefault"] then
				data[attr] = data[attr] * self.summonSpecialRate["specialDefault"]
			end
		end
	end
	data.hp = data.hpMax
	data.mp1 = data.mp1Max

	for _,v in ipairs(csvData.skillList) do
		data.skills[v] = self.level
	end

	for _,v in ipairs(csvData.passiveSkillList) do
		data.passiveSkills[v] = self.level
	end
	return data
end

function SummonSkillModel:onSpellView(skillBB)
	-- 不存在召唤单位
	if table.length(skillBB.summonTargets) == 0 then return end

	local scene = self.scene
	local view = self.owner.view
	local skillCfg = self.cfg
	local targets = skillBB.summonTargets
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

	local view = self.owner.view
	local actionTime = skillCfg.actionTime

	-- target.view:proxy():setVisible(false)
	-- target.view:proxy():setVisible(false)

	-- 召唤时立即隐藏所有单位
	battleEasy.effect(nil,function()
		for _,tar in ipairs(targets) do
			tar.view:proxy():setVisible(false)
    		tar.view:proxy():setVisibleEnable(false)
		end
	end)
	-- -- 开始播放动作前 显示所有单位
	battleEasy.queueEffect(function()
		battleEasy.queueEffect(function()
			for _,tar in ipairs(targets) do
				tar.view:proxy():setVisibleEnable(true)
			end
		end)
	end)
	battleEasy.queueNotifyFor(view, 'skillBefore', self.disposeDatasOnSkillStart, self.skillType)

	battleEasy.queueNotifyFor(view, 'playAction', skillCfg.spineAction, actionTime)

	battleEasy.queueNotifyFor(view, 'objSkillEnd', self.disposeDatasOnSkillEnd, self.skillType)
	-- 还原本体单位的表现
	-- battleEasy.queueNotifyFor(view, 'resetPos')

	battleEasy.queueNotifyFor(view, 'objSkillOver')
	-- 还原召唤单位表现
	-- for _,tar in ipairs(targets) do
	-- 	battleEasy.queueNotifyFor(tar.view, 'resetPos')
	-- end
	-- battleEasy.queueEffect('delay', {lifetime=actionTime})
end