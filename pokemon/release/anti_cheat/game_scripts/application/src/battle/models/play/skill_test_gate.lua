local SkillTestGate = class("SkillTestGate", battlePlay.Gate)
battlePlay.SkillTestGate = SkillTestGate

-- 战斗模式设置 全手动
SkillTestGate.OperatorArgs = {
	isAuto 			= false,
	isFullManual 	= false,
	canHandle 		= false,
	canPause 		= false, -- 用内网测试按钮
	canSpeedAni 	= true,
	canSkip 		= true,
}

function SkillTestGate:ctor(scene)
	battlePlay.Gate.ctor(self, scene)
	self.usedSkillList = {}
	self.allTested = false
	self.skillCount = 0
end

function SkillTestGate:init(data)
	-- 先获取下场景配表中的星数条件
	self:initStarConditions()
	print("!!!!!!!!!! 自动技能测试开始")
	battlePlay.Gate.init(self, data)
end

function SkillTestGate:newWaveAddObjsStrategy()
	self:addCardRoles(1)
	self:addCardRoles(2)
	self:doObjsAttrsCorrect(true, true)
	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

function SkillTestGate:autoAttack()
	gRootViewProxy:notify('selectedHero')

	local enemyForce = self:isMyTurn() and 2 or 1
	--自动攻击时,先判断技能,根据技能再选择目标
	-- 先大招,再各种加特殊buff的技能, 再常规技能, 再普攻(目前暂时是有大招放大招没有大招随机一个能用的)
	local skillID = 0
	local mainSkill = "main"		-- 大招
	local midSkill = "mid"			-- 二技能
	local normalAttack = "normal"	-- 普攻

	for id, skill in self.curHero:iterSkills() do
		if skill:canSpell() and not self.usedSkillList[id] then
			skillID = id
		end
	end
	if skillID == 0 then
		self.allTested = true
		skillID = 11
	else
		self.usedSkillList[skillID] = true
		self.skillCount = self.skillCount +1
		print("# 使用过主动技能的数量",self.skillCount)
	end
	-- 获得技能目标
	local target = self:autoChoose(skillID)

	printDebug("# autoAttack, choose skillId= %d, attackId= %d", skillID or 999999, target and target.id or 999999)
	return {skill=skillID}, target
end

function SkillTestGate:checkBattleEnd()
	-- 1.先判断己方死光了没
	if self.allTested then
		print("!!!!!!!!!! 自动技能测试通过")
		return true, "fail"
	end
	if self:checkForceAllRealDead(1) then
		print("!!!!!!!!!! 己方死光 测试中止")
		return true, "fail"
	end
	if self:checkForceAllRealDead(2) then
		print("!!!!!!!!!! 对方死光 测试中止")
		return true, "fail"
	end
	return false
end

function SkillTestGate:onRoundEndSupply()
	for i = 1, battlePlay.Gate.ObjectNumber do
		local obj = self.scene:getObjectBySeatExcludeDead(i)
		if obj then
			obj:setHP(obj:hpMax())
			if self.curRound %99 == 0 then
				obj:clearBuff()
			end
		end

	end

end