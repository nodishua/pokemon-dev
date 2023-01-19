

local TestGate = class("TestGate", battlePlay.Gate)
battlePlay.TestGate = TestGate

-- 战斗模式设置 全手动
TestGate.OperatorArgs = {
	isAuto 			= false,
	isFullManual 	= false,
	canHandle 		= true,
	canPause 		= false, -- 用内网测试按钮
	canSpeedAni 	= true,
	canSkip 		= true,
}

TestGate.SpecEndRuleCheck ={
	battle.EndSpecialCheck.AllHpRatioCheck
}

function TestGate:ctor(scene)
	battlePlay.Gate.ctor(self, scene)
end

function TestGate:init(data)
	-- 先获取下场景配表中的星数条件
	self:initStarConditions()

	self.myDeadHpMaxSum = 0
	self.enemyDeadHpMaxSum = 0
	battlePlay.Gate.init(self, data)
end

function TestGate:newWaveAddObjsStrategy()
	self:addCardRoles(1)
	self:addCardRoles(2)
	self:doObjsAttrsCorrect(true, true)
	battlePlay.Gate.newWaveAddObjsStrategy(self)
end
