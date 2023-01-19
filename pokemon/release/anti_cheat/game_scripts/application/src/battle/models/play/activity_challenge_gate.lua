
local ActivityChallengeGate = class("ActivityChallengeGate", battlePlay.Gate)
battlePlay.ActivityChallengeGate = ActivityChallengeGate

-- 战斗模式设置 手动
ActivityChallengeGate.OperatorArgs = {
	isAuto 			= false,
	isFullManual 	= false,
	canHandle 		= true,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= false,
	lockAuto 		= false,	 -- 入场锁定操作类型
}

ActivityChallengeGate.CommonArgs = {
	AntiMode = battle.GateAntiMode.Operate,
}

ActivityChallengeGate.SpecEndRuleCheck = {
	battle.EndSpecialCheck.BothDead,
	battle.EndSpecialCheck.DirectWin,
}

local EmptyGate = setmetatable({}, {
	__index = function()
		return function() end
	end
})

local NullFunc = function() end
local EmptyCall = function() return EmptyGate end
local SelfCall = function(self) return self end

local GateLocalConfigDefault = {
	guideChoice = false,				-- 引导选项
	specInit = NullFunc,				-- 自定义初始化
	-- startCondition = false,				-- 星级展示
}

local GateLocalConfig = {
	[game.GATE_TYPE.summerChallenge] = { -- 夏日挑战
		guideChoice = true,
		specInit = function(self, data)
			local config = csv.summer_challenge.gates
			self.roundLimit = config[data.gateID].roundLimit
		end,
		endData = {
			url = "/game/yy/summer_challenge/battle/end",
		},
	}
}

function ActivityChallengeGate:init(data)
	self.config = GateLocalConfig[self.scene.gateType] or {}

	for var_name, _ in pairs(GateLocalConfigDefault) do
		local exit = self.config[var_name]
		local call = EmptyCall

		if exit ~= nil then
			if GateLocalConfigDefault[var_name] == NullFunc then
				call = exit
			else
				call = SelfCall
			end
		end

		self[var_name] = call
	end

	if self:guideChoice():configCheck() then
		self.sendSkills = {} -- 发送的技能
		self.choices = {}
		self.guideIndex = nil -- 当前引导的索引

		-- 注册引导按钮回调
		gRootViewProxy:proxy():setGuideClickCall(functools.handler(self, self.onGuideClickCall))
	end

	self:specInit(data)

	battlePlay.Gate.init(self, data)
end

function ActivityChallengeGate:sendParams()
	-- gateID 二级key
	local base = {self.scene.battleID, self.data.gateID, self.result}
	if self.CommonArgs.AntiMode == battle.GateAntiMode.Operate then
		table.insert(base, battlePlay.Gate.sendActionParams(self))

		if self:guideChoice():configCheck() then
			table.insert(base, self.sendSkills)
			table.insert(base, self.choices)
		end
	end
	return unpack(base)
end

function ActivityChallengeGate:configCheck()
	return true
end

function ActivityChallengeGate:needExtraRound()
	if self.curRound > self.roundLimit then
		return false
	end
	for _, obj in self.scene:ipairsHeros() do
		if obj:isFakeDeath() then return true end
	end
	return false
end

function ActivityChallengeGate:checkBattleEnd()
	if self:needExtraRound() then
		return false
	end
	return battlePlay.Gate.checkBattleEnd(self)
end

function ActivityChallengeGate:postEndResultToServer(cb)
	local endInfos = self:makeEndViewInfos({
		gateStar = true
	})

	gRootViewProxy:raw():postEndResultToServer(self.config.endData.url, function(tb)
		cb(endInfos, tb)
	end, self:sendParams())
end

function ActivityChallengeGate:getEnemyRoleOutT(waveId)
	-- local roleOut = {}
	-- for i = 1, self.ForceNumber do
	-- 	local index = waveId * self.ForceNumber + i
	-- 	roleOut[self.ForceNumber+i] = self.data.roleOut[index]
	-- end
	return self.data.roleOut[2][waveId]
end


function ActivityChallengeGate:newWaveAddObjsStrategy()
	if self.curWave == 1 then
		self:addCardRoles(1, nil , self.data.roleOut[1][1])
		self:addCardRoles(2, nil, self:getEnemyRoleOutT(1))
		self:doObjsAttrsCorrect(true, true)		-- 属性修正部分
	else
		self:addCardRoles(2, nil, self:getEnemyRoleOutT(self.curWave))
		self:doObjsAttrsCorrect(false, true)
	end
	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

function ActivityChallengeGate:checkGuide(func, data)
	if self:guideChoice():configCheck() then
		self.guideIndex = data.round or self.curRound
	end
	battlePlay.Gate.checkGuide(self, func, data)
end

function ActivityChallengeGate:getMonsterGuideCsv(sceneId, waveId)
	for k,v in csvPairs(csv.summer_challenge.monsters) do
		if v.gateID == self.data.gateID and v.sceneCount == waveId then
			return v
		end
	end
	return battlePlay.Gate.getMonsterGuideCsv(self, sceneId, waveId)
end

function ActivityChallengeGate:onGuideClickCall(guideCfg, choiceCfg)
	local skills = {}
	local switch = self:guideChoice():configCheck()
	for skillId, num in csvMapPairs(choiceCfg.skills) do
		skills[skillId] = 1
		-- 需要发给服务器记录
		if num > 1 and switch then
			self.sendSkills[skillId] = num
			printDebug("add skill to sendSkills skillId: %s, num: %s", skillId, num)
			-- table.insert(self.sendSkills, {[skillId] = num})
		end
	end

	if switch and self.CommonArgs.AntiMode == battle.GateAntiMode.Operate then
		printDebug("record choices index: %s, skills: %s", self.guideIndex, dumps(skills))
		if next(skills) then
			table.set(self.choices, self.guideIndex, skills)
		end
	end
	self:guideChoice():applyChoices(skills)
end

function ActivityChallengeGate:applyChoices(skills)
	for _, obj in self.scene:ipairsHeros() do
		if not obj:isRealDeath() and obj.force == 1 then
			obj:onAddSkills(skills)
		end
	end
end


-- 战报
local ActivityChallengeGateRecord = class("ActivityChallengeGateRecord", ActivityChallengeGate)
battlePlay.ActivityChallengeGateRecord = ActivityChallengeGateRecord


ActivityChallengeGateRecord.CommonArgs = {
	AntiMode = battle.GateAntiMode.Normal
}

-- 战斗模式设置 自动
ActivityChallengeGateRecord.OperatorArgs = {
	isAuto 			= true,
	isFullManual 	= false,
	canHandle 		= false,
	canPause 		= true,
	canSpeedAni 	= true,
	canSkip 		= false,
}

function ActivityChallengeGateRecord:init(data)
	battlePlay.ActivityChallengeGate.init(self, data)

	self.actionRecv = data.actions
	self.choices = data.choices or {}
end

function ActivityChallengeGateRecord:checkGuide(func, data)
	if self:guideChoice():configCheck() then
		local skills = table.get(self.choices, data.round  or self.curRound)
		if skills then
			self:applyChoices(skills)
		end
	end
	battlePlay.Gate.checkGuide(self, func, data)
end

-- function ActivityChallengeGateRecord:onNewBattleTurn()
-- 	-- 存在选项技能增益
-- 	if self:guideChoice():configCheck() then

-- 	end

-- 	battlePlay.Gate.onNewBattleTurn(self)
-- end

function ActivityChallengeGateRecord:getActionRecv(...)
	local action = table.get(self.actionRecv, ...)
	if action == nil then return end
	if action[1] == 0 then return end
	return unpack(action)
end

function ActivityChallengeGateRecord:onceBattle(targetId, skillId)
	local rCurId, rTargetId, rSkillId = self:getActionRecv(self.curRound, self.curBattleRound)

	if (rSkillId or 0) ~= 0 then
		self.scene.autoFight = false
		battlePlay.Gate.onceBattle(self, rTargetId, rSkillId)
		self.scene.autoFight = true
		if self.waitInput then
			error("why input be wait in record")
		end
		return
	end

	battlePlay.Gate.onceBattle(self, targetId, skillId)
end